import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/business_logic/auth/auth_state.dart';
import 'package:rememberme/core/utils/invitation_handler.dart';
import 'package:rememberme/core/utils/qr_claiming_handler.dart';
import 'package:rememberme/data/repositories/memorial_repository.dart';
import 'package:rememberme/data/repositories/qr_code_repository.dart';
import 'package:rememberme/presentation/screens/home_screen.dart';
import 'package:rememberme/presentation/screens/visual_builder/visual_builder_screen.dart';
import 'dart:io';

import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/app_strings.dart';

// Models
import 'data/models/memorial_model.dart';

// Bloc
import 'business_logic/auth/auth_bloc.dart';

// Screens
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/forgot_password_screen.dart';
import 'presentation/screens/memorial/memorial_screen.dart';
import 'presentation/screens/memorial/memorial_create_screen.dart';
import 'presentation/screens/memorial/memorial_edit_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/profile/about_screen.dart';
import 'presentation/screens/auth/register_screen.dart';

class RememberMeApp extends StatefulWidget {
  const RememberMeApp({super.key});

  @override
  State<RememberMeApp> createState() => _RememberMeAppState();
}

class _RememberMeAppState extends State<RememberMeApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_navigatorKey.currentContext != null) {
            invitationHandler.initialize(
              context: _navigatorKey.currentContext!,
              userId: state.user?.id,
            );

            qrClaimingHandler.initialize(
              context: _navigatorKey.currentContext!,
              qrCodeRepository: context.read<QrCodeRepository>(),
              memorialRepository: context.read<MemorialRepository>(),
              userId: state.user?.id,
            );
          }
        });
      },
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: _onGenerateRoute,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultCupertinoLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    debugPrint(
        '🚀 Navigate to: ${settings.name} with args: ${settings.arguments}');

    final routeName = settings.name ?? '';

    // ==================== DEEP LINK ROUTES ====================
    // Diese werden vom DeepLinkHandler / QrClaimingHandler verarbeitet
    if (_isDeepLinkRoute(routeName)) {
      debugPrint(
          '⚠️ Blocking deep link route: $routeName (handled by DeepLinkHandler)');

      // Route die sich sofort wieder schließt
      return PageRouteBuilder(
        settings: settings,
        opaque: false,
        pageBuilder: (context, _, __) {
          // Sofort wieder zurück navigieren
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
          // Transparenter Container (unsichtbar)
          return const SizedBox.shrink();
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
    }

    Widget page;

    switch (settings.name) {
      // ==================== Auth Routes ====================
      case AppRoutes.splash:
        page = const SplashScreen();
        break;

      case AppRoutes.login:
        page = const LoginScreen();
        break;

      case AppRoutes.register:
        page = const RegisterScreen();
        break;

      case AppRoutes.forgotPassword:
        page = const ForgotPasswordScreen();
        break;

      // ==================== Main Route (Tab Navigation) ====================
      case AppRoutes.home:
        page = const HomeScreen();
        break;

      // ==================== Memorial Routes ====================
      case AppRoutes.memorialDetail:
        final memorial = settings.arguments as MemorialModel?;
        page = MemorialDetailScreen(memorial: memorial);
        break;

      case AppRoutes.memorialCreate:
        page = const MemorialCreateScreen();
        break;

      case AppRoutes.memorialEdit:
        final memorial = settings.arguments as MemorialModel?;
        if (memorial == null) {
          debugPrint('❌ Kein Memorial übergeben an MemorialEdit!');
          return _buildErrorRoute(settings, 'Memorial nicht gefunden');
        }
        page = MemorialEditScreen(memorial: memorial);
        break;

      // ==================== Page Builder Route ====================
      case AppRoutes.pageBuilder:
        final memorial = settings.arguments as MemorialModel?;
        if (memorial == null) {
          debugPrint('❌ Kein Memorial übergeben an PageBuilder!');
          return _buildErrorRoute(settings, 'Memorial nicht gefunden');
        }
        page = IntuitivePageBuilderScreen(memorial: memorial);
        break;

      // ==================== Profile Routes ====================
      case AppRoutes.profile:
        page = const ProfileScreen();
        break;

      case AppRoutes.about:
        page = const AboutScreen();
        break;

      case AppRoutes.settings:
        page =
            _buildPlaceholderScreen('Einstellungen', 'Wird noch implementiert');
        break;

      // ==================== Invitation Route ====================
      case AppRoutes.inviteRedeem:
        final token = settings.arguments as String?;
        if (token == null) {
          debugPrint('❌ Kein Token für Invite Redeem!');
          return _buildErrorRoute(settings, 'Einladungslink ungültig');
        }
        page = _buildPlaceholderScreen('Einladung', 'Token: $token');
        break;

      // ==================== 404 Route ====================
      case AppRoutes.notFound:
      default:
        debugPrint('❌ Route nicht gefunden: ${settings.name}');
        return _buildErrorRoute(settings, 'Seite nicht gefunden');
    }

    // Platform-spezifische Navigation
    if (Platform.isIOS) {
      return CupertinoPageRoute(
        builder: (_) => page,
        settings: settings,
      );
    }

    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }

  /// Prüft ob eine Route ein Deep Link ist (wird von Handlers verarbeitet)
  bool _isDeepLinkRoute(String routeName) {
    // Ignoriere leere Routes
    if (routeName.isEmpty || routeName == '/') {
      return false;
    }

    // Entferne führenden Slash
    final name = routeName.startsWith('/') ? routeName.substring(1) : routeName;

    // /memorial/{qrCodeId} - QR-Code Deep Link
    if (routeName.startsWith('/memorial/') || name.startsWith('memorial/')) {
      return true;
    }

    // /m/{qrCodeId} - Kurze QR-Code URL
    if (routeName.startsWith('/m/') || name.startsWith('m/')) {
      return true;
    }

    // /invite/{token} - Einladungs-Link
    if (routeName.contains('invite/')) {
      return true;
    }

    // HTTPS URLs (Universal Links)
    if (routeName.startsWith('https://') || routeName.startsWith('http://')) {
      return true;
    }

    // Token ist 16 alphanumerische Zeichen
    if (name.length == 16 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(name)) {
      return true;
    }

    return false;
  }

  Route<dynamic> _buildErrorRoute(RouteSettings settings, String message) {
    return MaterialPageRoute(
      builder: (_) => _buildErrorScreen(message),
      settings: settings,
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fehler'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Platform.isIOS
                    ? CupertinoIcons.exclamationmark_triangle
                    : Icons.error_outline,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (Platform.isIOS)
                CupertinoButton.filled(
                  onPressed: () {},
                  child: const Text('Zurück'),
                )
              else
                FilledButton(
                  onPressed: () {},
                  child: const Text('Zurück'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderScreen(String title, String subtitle) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Platform.isIOS ? CupertinoIcons.hammer : Icons.construction,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

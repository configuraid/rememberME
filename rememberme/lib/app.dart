import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:rememberme/core/constants/app_strings.dart';
import 'package:rememberme/data/models/auth/organization_model.dart';
import 'package:rememberme/presentation/screens/auth/user_selection_screen.dart';
import 'package:rememberme/presentation/screens/auth/profile_creation_screen.dart';
import 'package:rememberme/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:rememberme/presentation/screens/memorial/memorial_create_screen.dart';
import 'package:rememberme/presentation/screens/visual_builder/visual_builder_screen.dart';
import 'package:rememberme/data/models/memorial_page_model.dart';
import 'dart:io';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/memorial/memorial_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';

class MemorialApp extends StatelessWidget {
  const MemorialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    print('🚀 Navigate to: ${settings.name} with args: ${settings.arguments}');

    Widget page;

    switch (settings.name) {
      case AppRoutes.splash:
        page = const SplashScreen();
        break;

      case AppRoutes.login:
        page = const LoginScreen();
        break;

      case AppRoutes.userSelection:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          print('❌ Keine Arguments für UserSelection!');
          return null;
        }
        page = UserSelectionScreen(
          organization: args['organization'] as OrganizationModel,
          membersWithData:
              args['membersWithData'] as List<Map<String, dynamic>>,
        );
        break;

      case AppRoutes.profileCreation:
        final organization = settings.arguments as OrganizationModel?;
        if (organization == null) {
          print('❌ Keine Organization für ProfileCreation!');
          return null;
        }
        page = ProfileCreationScreen(organization: organization);
        break;

      case AppRoutes.dashboard:
        page = const DashboardScreen();
        break;

      case AppRoutes.memorialDetail:
        final memorial = settings.arguments as MemorialPageModel?;
        page = MemorialDetailScreen(memorial: memorial);
        break;

      case AppRoutes.memorialCreate:
        page = const MemorialCreateScreen();
        break;

      case AppRoutes.pageBuilder:
        final memorial = settings.arguments as MemorialPageModel?;
        if (memorial == null) {
          print('❌ Kein Memorial übergeben an PageBuilder!');
          return null;
        }
        page = IntuitivePageBuilderScreen(memorial: memorial);
        break;

      case AppRoutes.profile:
        page = const ProfileScreen();
        break;

      default:
        print('❌ Route nicht gefunden: ${settings.name}');
        return null;
    }

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
}

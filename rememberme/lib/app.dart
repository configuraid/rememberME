import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:rememberme/presentation/screens/memorial/memorial_create_screen.dart';
import 'package:rememberme/presentation/screens/visual_builder/visual_builder_screen.dart';
import 'dart:io';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/qr_scanner_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/memorial/memorial_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/profile/license_screen.dart';

class MemorialApp extends StatelessWidget {
  const MemorialApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Plattform-spezifische App
    if (Platform.isIOS) {
      return CupertinoApp(
        title: 'Digital Memorial',
        theme: AppTheme.cupertinoTheme,
        initialRoute: AppRoutes.splash,
        routes: _buildRoutes(),
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultCupertinoLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
      );
    }

    return MaterialApp(
      title: 'Digital Memorial',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      routes: _buildRoutes(),
      debugShowCheckedModeBanner: false,
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      AppRoutes.splash: (context) => const SplashScreen(),
      AppRoutes.login: (context) => const LoginScreen(),
      AppRoutes.qrScanner: (context) => const QRScannerScreen(),
      AppRoutes.dashboard: (context) => const DashboardScreen(),
      AppRoutes.memorialDetail: (context) => const MemorialDetailScreen(),
      AppRoutes.memorialCreate: (context) => const MemorialCreateScreen(),
      AppRoutes.pageBuilder: (context) => const IntuitivePageBuilderScreen(
            memorialName: 'Hurensohn',
          ),
      AppRoutes.profile: (context) => const ProfileScreen(),
      AppRoutes.license: (context) => const LicenseScreen(),
    };
  }
}

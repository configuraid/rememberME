import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business_logic/auth/auth_bloc.dart';
import '../../business_logic/auth/auth_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      final authState = context.read<AuthBloc>().state;

      if (authState.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
      } else if (authState.status == AuthStatus.unauthenticated) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isAuthenticated ||
            state.status == AuthStatus.unauthenticated) {
          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;

            if (state.isAuthenticated) {
              Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
            } else if (state.status == AuthStatus.unauthenticated) {
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Container
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.accent
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? AppColors.accent.withOpacity(0.3)
                            : AppColors.primary.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Platform.isIOS
                        ? CupertinoIcons.heart_fill
                        : Icons.favorite_rounded,
                    size: 60,
                    color: isDark ? AppColors.background : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),

                // App Name
                Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    fontFamily: Platform.isIOS ? '.SF Pro Display' : null,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                Text(
                  AppStrings.appTagline,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.grey,
                    fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
                  ),
                ),
                const SizedBox(height: 48),

                // Loading Indicator
                if (Platform.isIOS)
                  CupertinoActivityIndicator(
                    color: isDark ? AppColors.accent : AppColors.primary,
                    radius: 14,
                  )
                else
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? AppColors.accent : AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

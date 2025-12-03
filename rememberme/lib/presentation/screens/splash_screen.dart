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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        isDarkMode ? AppColors.surfaceDark : AppColors.primary;
    final containerColor = isDarkMode ? AppColors.primaryDark : Colors.white;
    final iconColor = isDarkMode ? AppColors.accentLight : AppColors.accent;
    final titleColor = isDarkMode ? AppColors.textLight : Colors.white;
    final taglineColor = isDarkMode
        ? AppColors.textLight.withOpacity(0.7)
        : Colors.white.withOpacity(0.9);
    final loaderColor = isDarkMode ? AppColors.accent : Colors.white;

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
        backgroundColor: backgroundColor,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.favorite,
                    size: 60,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.appTagline,
                  style: TextStyle(
                    fontSize: 16,
                    color: taglineColor,
                  ),
                ),
                const SizedBox(height: 48),
                if (Platform.isIOS)
                  CupertinoActivityIndicator(
                    color: loaderColor,
                    radius: 16,
                  )
                else
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(loaderColor),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

    // Animation Setup
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
      // Falls noch loading, wartet der BlocListener
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Nur navigieren wenn Animation fertig ist (nach 2 Sekunden)
        if (state.isAuthenticated ||
            state.status == AuthStatus.unauthenticated) {
          // Warte bis Animation fertig ist
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
        backgroundColor: AppColors.primary,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon/Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 60,
                    color: AppColors.accent,
                  ),
                ),

                const SizedBox(height: 32),

                // App Name
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline
                Text(
                  AppStrings.appTagline,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),

                const SizedBox(height: 48),

                // Loading Indicator
                if (Platform.isIOS)
                  const CupertinoActivityIndicator(
                    color: Colors.white,
                    radius: 16,
                  )
                else
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

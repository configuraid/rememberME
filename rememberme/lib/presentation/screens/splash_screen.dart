import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/core/utils/deep_link_handler.dart';
import 'dart:io';

import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/auth/auth_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/services/invitation_redeem_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final InvitationRedeemService _invitationService = InvitationRedeemService();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Handle navigation after auth state is determined
  Future<void> _handleNavigation(BuildContext context, AuthState state) async {
    // Wait for animation
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    if (state.isAuthenticated && state.user != null) {
      // ✅ User is logged in
      debugPrint('✅ User authenticated: ${state.user!.id}');

      // Check for pending invitation from deep link
      final redeemResult = await _invitationService
          .checkAndRedeemPendingInvitation(state.user!.id);

      if (!mounted) return;

      if (redeemResult != null && redeemResult.success) {
        // Show success message and navigate to the shared memorial
        _showInvitationSuccess(context, redeemResult);
      } else {
        // Normal navigation to home
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      }
    } else {
      // ❌ User not logged in
      debugPrint('❌ User not authenticated');

      // Check if there's a pending invitation
      final hasPending = await deepLinkHandler.hasPendingInvitation();

      if (!mounted) return;

      if (hasPending) {
        // Show login with hint about pending invitation
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.login,
          arguments: {'hasPendingInvitation': true},
        );
      } else {
        // Normal login
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    }
  }

  /// Show success dialog after redeeming invitation
  void _showInvitationSuccess(BuildContext context, RedeemResult result) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final memorialName = result.memorial?.name ?? 'Gedenkseite';

    HapticFeedback.heavyImpact();

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => CupertinoAlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: AppColors.success,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('Einladung angenommen'),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              result.alreadyHadAccess
                  ? 'Du hast bereits Zugang zu "$memorialName".'
                  : 'Du hast jetzt Zugang zu "$memorialName".',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                // Navigate to home (memorial will be in list)
                Navigator.of(context).pushReplacementNamed(AppRoutes.home);
              },
              child: const Text('Gedenkseite öffnen'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('Einladung angenommen'),
            ],
          ),
          content: Text(
            result.alreadyHadAccess
                ? 'Du hast bereits Zugang zu "$memorialName".'
                : 'Du hast jetzt Zugang zu "$memorialName".',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacementNamed(AppRoutes.home);
              },
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? AppColors.accent : AppColors.primary,
              ),
              child: const Text('Gedenkseite öffnen'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (!state.isLoading) {
          _handleNavigation(context, state);
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                AppColors.accent.withOpacity(0.2),
                                AppColors.accent.withOpacity(0.05),
                              ]
                            : [
                                AppColors.primary.withOpacity(0.15),
                                AppColors.primary.withOpacity(0.05),
                              ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Platform.isIOS
                          ? CupertinoIcons.heart_fill
                          : Icons.favorite_rounded,
                      size: 56,
                      color: isDark ? AppColors.accent : AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Name
                  Text(
                    'RememberMe',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    'Erinnerungen für die Ewigkeit',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.grey,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Loading indicator
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Platform.isIOS
                        ? CupertinoActivityIndicator(
                            color:
                                isDark ? AppColors.accent : AppColors.primary,
                          )
                        : CircularProgressIndicator(
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
      ),
    );
  }
}

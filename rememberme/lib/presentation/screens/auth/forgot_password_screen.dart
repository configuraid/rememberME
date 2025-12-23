import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';

import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/auth/auth_event.dart';
import '../../../business_logic/auth/auth_state.dart';
import '../../../core/constants/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _emailError;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    if (email.isEmpty) {
      setState(() => _emailError = 'Bitte E-Mail-Adresse eingeben');
      return false;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Ungültige E-Mail-Adresse');
      return false;
    }
    setState(() => _emailError = null);
    return true;
  }

  void _resetPassword() {
    FocusScope.of(context).unfocus();

    if (!_validateEmail(_emailController.text.trim())) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    context.read<AuthBloc>().add(
          AuthPasswordResetRequested(_emailController.text.trim()),
        );
  }

  void _showError(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Fehler'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              isDefaultAction: true,
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        setState(() => _isLoading = false);

        if (state.hasSuccess) {
          setState(() => _emailSent = true);
          HapticFeedback.heavyImpact();
          _animationController.reset();
          _animationController.forward();
        } else if (state.hasError) {
          _showError(state.errorMessage ?? 'Ein Fehler ist aufgetreten');
        }
      },
      child: Platform.isIOS
          ? _buildIOSScaffold(isDark)
          : _buildAndroidScaffold(isDark),
    );
  }

  // ============================================================
  // Android Scaffold
  // ============================================================
  Widget _buildAndroidScaffold(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _emailSent
                        ? _buildSuccessContent(isDark)
                        : _buildFormContent(isDark),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // iOS Scaffold
  // ============================================================
  Widget _buildIOSScaffold(bool isDark) {
    return CupertinoPageScaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(
            CupertinoIcons.back,
            color: isDark ? AppColors.accent : AppColors.primary,
          ),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _emailSent
                    ? _buildSuccessContent(isDark)
                    : _buildFormContent(isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Form Content (Shared)
  // ============================================================
  Widget _buildFormContent(bool isDark) {
    final isIOS = Platform.isIOS;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        // Hero Illustration
        Center(
          child: Container(
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
              isIOS ? CupertinoIcons.lock_shield : Icons.lock_reset_rounded,
              size: 56,
              color: isDark ? AppColors.accent : AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Title
        Center(
          child: Text(
            'Passwort vergessen?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              letterSpacing: -0.5,
              fontFamily: isIOS ? '.SF Pro Display' : null,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Description
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Kein Problem! Gib deine E-Mail-Adresse ein und wir senden dir einen Link zum Zurücksetzen.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.grey,
                height: 1.5,
                fontFamily: isIOS ? '.SF Pro Text' : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Email Field
        _buildEmailField(isDark, isIOS),

        const SizedBox(height: 32),

        // Submit Button
        _buildSubmitButton(isDark, isIOS),

        const SizedBox(height: 24),

        // Back Link
        Center(
          child: isIOS
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.arrow_left,
                        size: 16,
                        color: isDark ? AppColors.accent : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Zurück zur Anmeldung',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? AppColors.accent : AppColors.primary,
                          fontWeight: FontWeight.w500,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ],
                  ),
                )
              : TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: isDark ? AppColors.accent : AppColors.primary,
                  ),
                  label: Text(
                    'Zurück zur Anmeldung',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppColors.accent : AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildEmailField(bool isDark, bool isIOS) {
    if (isIOS) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoTextField(
            controller: _emailController,
            focusNode: _focusNode,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            placeholder: 'E-Mail-Adresse',
            prefix: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(
                CupertinoIcons.mail,
                color: _emailError != null
                    ? AppColors.error
                    : (_focusNode.hasFocus ? AppColors.accent : AppColors.grey),
                size: 20,
              ),
            ),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _emailError != null
                    ? AppColors.error
                    : (isDark ? AppColors.borderDark : AppColors.greyLighter),
                width: 1.5,
              ),
            ),
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
            placeholderStyle: TextStyle(
              fontSize: 16,
              color: AppColors.grey.withOpacity(0.6),
              fontFamily: '.SF Pro Text',
            ),
            onSubmitted: (_) => _resetPassword(),
            onChanged: (_) {
              if (_emailError != null) {
                _validateEmail(_emailController.text.trim());
              }
            },
          ),
          if (_emailError != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_circle,
                    size: 14,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _emailError!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    // Android TextField
    return TextField(
      controller: _emailController,
      focusNode: _focusNode,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _resetPassword(),
      style: TextStyle(
        fontSize: 16,
        color: isDark ? AppColors.textLight : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'E-Mail-Adresse',
        errorText: _emailError,
        prefixIcon: Icon(
          Icons.email_outlined,
          color: _emailError != null ? AppColors.error : AppColors.grey,
        ),
        filled: true,
        fillColor:
            isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.greyLighter,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.accent : AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: (_) {
        if (_emailError != null) {
          _validateEmail(_emailController.text.trim());
        }
      },
    );
  }

  Widget _buildSubmitButton(bool isDark, bool isIOS) {
    if (isIOS) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          color: isDark ? AppColors.accent : AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          onPressed: _isLoading ? null : _resetPassword,
          child: _isLoading
              ? CupertinoActivityIndicator(
                  color: isDark ? AppColors.primary : AppColors.textLight,
                )
              : Text(
                  'Link senden',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.primary : AppColors.textLight,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _isLoading ? null : _resetPassword,
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? AppColors.accent : AppColors.primary,
          foregroundColor: isDark ? AppColors.primary : AppColors.textLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.primary : AppColors.textLight,
                  ),
                ),
              )
            : const Text(
                'Link senden',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  // ============================================================
  // Success Content (Shared)
  // ============================================================
  Widget _buildSuccessContent(bool isDark) {
    final isIOS = Platform.isIOS;

    return Column(
      children: [
        const SizedBox(height: 60),

        // Success Animation Container
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.success.withOpacity(0.2),
                AppColors.success.withOpacity(0.05),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIOS
                    ? CupertinoIcons.checkmark_circle_fill
                    : Icons.check_circle_rounded,
                size: 64,
                color: AppColors.success,
              ),
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Title
        Text(
          'E-Mail gesendet!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
            letterSpacing: -0.5,
            fontFamily: isIOS ? '.SF Pro Display' : null,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 15,
                color: AppColors.grey,
                height: 1.6,
                fontFamily: isIOS ? '.SF Pro Text' : null,
              ),
              children: [
                const TextSpan(text: 'Wir haben einen Link an '),
                TextSpan(
                  text: _emailController.text.trim(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                ),
                const TextSpan(text: ' gesendet.'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Spam hint
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.warning.withOpacity(0.1)
                : AppColors.warning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.warning.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isIOS ? CupertinoIcons.info_circle : Icons.info_outline_rounded,
                size: 20,
                color: AppColors.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Prüfe auch deinen Spam-Ordner',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    fontFamily: isIOS ? '.SF Pro Text' : null,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),

        // Back to Login Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: isIOS
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    color: isDark ? AppColors.accent : AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Zurück zur Anmeldung',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.primary : AppColors.textLight,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  )
                : FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.accent : AppColors.primary,
                      foregroundColor:
                          isDark ? AppColors.primary : AppColors.textLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Zurück zur Anmeldung',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Resend Link
        Center(
          child: isIOS
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() => _emailSent = false);
                    _animationController.reset();
                    _animationController.forward();
                  },
                  child: Text(
                    'Erneut senden',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppColors.accent : AppColors.primary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                )
              : TextButton(
                  onPressed: () {
                    setState(() => _emailSent = false);
                    _animationController.reset();
                    _animationController.forward();
                  },
                  child: Text(
                    'Erneut senden',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppColors.accent : AppColors.primary,
                    ),
                  ),
                ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}

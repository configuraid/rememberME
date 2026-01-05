import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';

import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/auth/auth_event.dart';
import '../../../business_logic/auth/auth_state.dart';
import '../../../business_logic/memorial/memorial_bloc.dart';
import '../../../business_logic/memorial/memorial_event.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    if (email.isEmpty) {
      setState(() => _emailError = 'E-Mail-Adresse eingeben');
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

  bool _validatePassword(String password) {
    if (password.isEmpty) {
      setState(() => _passwordError = 'Passwort eingeben');
      return false;
    }
    if (password.length < 6) {
      setState(() => _passwordError = 'Mindestens 6 Zeichen');
      return false;
    }
    setState(() => _passwordError = null);
    return true;
  }

  void _login() {
    FocusScope.of(context).unfocus();

    final emailValid = _validateEmail(_emailController.text.trim());
    final passwordValid = _validatePassword(_passwordController.text);

    if (!emailValid || !passwordValid) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    context.read<AuthBloc>().add(
          AuthLoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  void _showError(String message) {
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

        if (state.isAuthenticated && state.user != null) {
          HapticFeedback.heavyImpact();

          // ✅ FIX: MemorialBloc zurücksetzen und neue Memorials laden
          context.read<MemorialBloc>().add(const MemorialsClearRequested());
          context.read<MemorialBloc>().add(
                MemorialLoadRequested(userId: state.user!.id),
              );

          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        } else if (state.hasError) {
          _showError(state.errorMessage ?? 'Login fehlgeschlagen');
        }
      },
      child: Platform.isIOS
          ? _buildIOSScaffold(isDark)
          : _buildAndroidScaffold(isDark),
    );
  }

  Widget _buildAndroidScaffold(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildContent(isDark, false),
        ),
      ),
    );
  }

  Widget _buildIOSScaffold(bool isDark) {
    return CupertinoPageScaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      child: SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildContent(isDark, true),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, bool isIOS) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 60),

        // Logo
        Center(
          child: Container(
            width: 100,
            height: 100,
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
              isIOS ? CupertinoIcons.heart_fill : Icons.favorite_rounded,
              size: 48,
              color: isDark ? AppColors.accent : AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Title
        Center(
          child: Text(
            'Willkommen zurück',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Center(
          child: Text(
            'Melde dich an, um fortzufahren',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.grey,
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Email Field
        _buildEmailField(isDark, isIOS),

        const SizedBox(height: 16),

        // Password Field
        _buildPasswordField(isDark, isIOS),

        const SizedBox(height: 12),

        // Forgot Password
        Align(
          alignment: Alignment.centerRight,
          child: isIOS
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
                  child: Text(
                    'Passwort vergessen?',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.accent : AppColors.primary,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
                  child: Text(
                    'Passwort vergessen?',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.accent : AppColors.primary,
                    ),
                  ),
                ),
        ),

        const SizedBox(height: 24),

        // Login Button
        _buildLoginButton(isDark, isIOS),

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
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _passwordFocusNode.requestFocus(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            placeholder: 'E-Mail-Adresse',
            prefix: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(
                CupertinoIcons.mail,
                color: _emailError != null ? AppColors.error : AppColors.grey,
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
              ),
            ),
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
            onChanged: (_) {
              if (_emailError != null)
                _validateEmail(_emailController.text.trim());
            },
          ),
          if (_emailError != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(_emailError!,
                  style: const TextStyle(fontSize: 12, color: AppColors.error)),
            ),
          ],
        ],
      );
    }

    return TextField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => _passwordFocusNode.requestFocus(),
      style: TextStyle(
        fontSize: 16,
        color: isDark ? AppColors.textLight : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'E-Mail-Adresse',
        errorText: _emailError,
        prefixIcon: Icon(Icons.email_outlined,
            color: _emailError != null ? AppColors.error : AppColors.grey),
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
              color: isDark ? AppColors.borderDark : AppColors.greyLighter),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? AppColors.accent : AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      onChanged: (_) {
        if (_emailError != null) _validateEmail(_emailController.text.trim());
      },
    );
  }

  Widget _buildPasswordField(bool isDark, bool isIOS) {
    if (isIOS) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoTextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            placeholder: 'Passwort',
            prefix: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(
                CupertinoIcons.lock,
                color:
                    _passwordError != null ? AppColors.error : AppColors.grey,
                size: 20,
              ),
            ),
            suffix: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword
                      ? CupertinoIcons.eye
                      : CupertinoIcons.eye_slash,
                  color: AppColors.grey,
                  size: 20,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _passwordError != null
                    ? AppColors.error
                    : (isDark ? AppColors.borderDark : AppColors.greyLighter),
              ),
            ),
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
            onChanged: (_) {
              if (_passwordError != null)
                _validatePassword(_passwordController.text);
            },
          ),
          if (_passwordError != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(_passwordError!,
                  style: const TextStyle(fontSize: 12, color: AppColors.error)),
            ),
          ],
        ],
      );
    }

    return TextField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _login(),
      style: TextStyle(
        fontSize: 16,
        color: isDark ? AppColors.textLight : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Passwort',
        errorText: _passwordError,
        prefixIcon: Icon(Icons.lock_outline,
            color: _passwordError != null ? AppColors.error : AppColors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: AppColors.grey,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
              color: isDark ? AppColors.borderDark : AppColors.greyLighter),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? AppColors.accent : AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      onChanged: (_) {
        if (_passwordError != null) _validatePassword(_passwordController.text);
      },
    );
  }

  Widget _buildLoginButton(bool isDark, bool isIOS) {
    if (isIOS) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          color: isDark ? AppColors.accent : AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          onPressed: _isLoading ? null : _login,
          child: _isLoading
              ? CupertinoActivityIndicator(
                  color: isDark ? AppColors.primary : AppColors.textLight)
              : Text(
                  'Anmelden',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.primary : AppColors.textLight,
                  ),
                ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _isLoading ? null : _login,
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? AppColors.accent : AppColors.primary,
          foregroundColor: isDark ? AppColors.primary : AppColors.textLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppColors.primary : AppColors.textLight),
                ),
              )
            : const Text('Anmelden',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

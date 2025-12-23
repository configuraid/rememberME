import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';

import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/auth/auth_event.dart';
import '../../../business_logic/auth/auth_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  bool _validateName(String name) {
    if (name.isEmpty) {
      setState(() => _nameError = 'Name eingeben');
      return false;
    }
    if (name.length < 2) {
      setState(() => _nameError = 'Mindestens 2 Zeichen');
      return false;
    }
    setState(() => _nameError = null);
    return true;
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

  bool _validateConfirmPassword(String confirmPassword) {
    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'Passwort bestätigen');
      return false;
    }
    if (confirmPassword != _passwordController.text) {
      setState(
          () => _confirmPasswordError = 'Passwörter stimmen nicht überein');
      return false;
    }
    setState(() => _confirmPasswordError = null);
    return true;
  }

  bool _validateAll() {
    final nameValid = _validateName(_nameController.text.trim());
    final emailValid = _validateEmail(_emailController.text.trim());
    final passwordValid = _validatePassword(_passwordController.text);
    final confirmValid =
        _validateConfirmPassword(_confirmPasswordController.text);

    return nameValid && emailValid && passwordValid && confirmValid;
  }

  // ============================================================
  // REGISTER
  // ============================================================

  void _register() {
    FocusScope.of(context).unfocus();

    if (!_validateAll()) return;

    if (!_acceptedTerms) {
      _showError('Bitte akzeptiere die Nutzungsbedingungen');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    context.read<AuthBloc>().add(AuthRegisterRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        ));
  }

  // ============================================================
  // ERROR DIALOG
  // ============================================================

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
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSView();
    }
    return _buildAndroidView();
  }

  // ============================================================
  // Android View
  // ============================================================

  Widget _buildAndroidView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isAuthenticated) {
          setState(() => _isLoading = false);
          Navigator.of(context).pushReplacementNamed(AppRoutes.memorialDetail);
        } else if (state.hasError) {
          setState(() => _isLoading = false);
          _showError(state.errorMessage ?? 'Ein Fehler ist aufgetreten');
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Title
                Text(
                  'Konto erstellen',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Erstelle dein persönliches Konto um Gedenkseiten zu verwalten.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.grey,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 32),

                // Form
                _buildRegisterForm(isDark),

                const SizedBox(height: 24),

                // Terms Checkbox
                _buildTermsCheckbox(isDark),

                const SizedBox(height: 24),

                // Register Button
                _buildRegisterButton(isDark),

                const SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Bereits ein Konto? ',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.grey,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Anmelden',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // iOS View
  // ============================================================

  Widget _buildIOSView() {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isAuthenticated) {
          setState(() => _isLoading = false);
          Navigator.of(context).pushReplacementNamed(AppRoutes.memorialDetail);
        } else if (state.hasError) {
          setState(() => _isLoading = false);
          _showError(state.errorMessage ?? 'Ein Fehler ist aufgetreten');
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: Colors.transparent,
          border: null,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: Icon(
              CupertinoIcons.back,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'Konto erstellen',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                      fontFamily: '.SF Pro Display',
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Erstelle dein persönliches Konto um Gedenkseiten zu verwalten.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.grey,
                      height: 1.4,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Form
                  _buildRegisterFormIOS(isDark),

                  const SizedBox(height: 24),

                  // Terms Checkbox
                  _buildTermsCheckboxIOS(isDark),

                  const SizedBox(height: 24),

                  // Register Button
                  _buildRegisterButtonIOS(isDark),

                  const SizedBox(height: 24),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Bereits ein Konto? ',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.grey,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Anmelden',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.primaryLight
                                : AppColors.primary,
                            fontFamily: '.SF Pro Text',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Android Form
  // ============================================================

  Widget _buildRegisterForm(bool isDark) {
    return Column(
      children: [
        // Name Field
        _buildTextField(
          controller: _nameController,
          label: 'Name',
          error: _nameError,
          icon: Icons.person_outline,
          isDark: isDark,
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_nameError != null) _validateName(_nameController.text.trim());
          },
        ),

        const SizedBox(height: 16),

        // Email Field
        _buildTextField(
          controller: _emailController,
          label: 'E-Mail-Adresse',
          error: _emailError,
          icon: Icons.email_outlined,
          isDark: isDark,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_emailError != null)
              _validateEmail(_emailController.text.trim());
          },
        ),

        const SizedBox(height: 16),

        // Password Field
        _buildTextField(
          controller: _passwordController,
          label: 'Passwort',
          error: _passwordError,
          icon: Icons.lock_outline,
          isDark: isDark,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.grey,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          onChanged: (_) {
            if (_passwordError != null)
              _validatePassword(_passwordController.text);
          },
        ),

        const SizedBox(height: 16),

        // Confirm Password Field
        _buildTextField(
          controller: _confirmPasswordController,
          label: 'Passwort bestätigen',
          error: _confirmPasswordError,
          icon: Icons.lock_outline,
          isDark: isDark,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.grey,
            ),
            onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          onSubmitted: (_) => _register(),
          onChanged: (_) {
            if (_confirmPasswordError != null) {
              _validateConfirmPassword(_confirmPasswordController.text);
            }
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String? error,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      autocorrect: false,
      style: TextStyle(
        fontSize: 16,
        color: isDark ? AppColors.textLight : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        prefixIcon:
            Icon(icon, color: error != null ? AppColors.error : AppColors.grey),
        suffixIcon: suffixIcon,
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
            color: error != null
                ? AppColors.error
                : AppColors.grey.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryLight : AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }

  Widget _buildTermsCheckbox(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _acceptedTerms,
            onChanged: (value) =>
                setState(() => _acceptedTerms = value ?? false),
            activeColor: isDark ? AppColors.primaryLight : AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
            child: Text.rich(
              TextSpan(
                text: 'Ich akzeptiere die ',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
                children: [
                  TextSpan(
                    text: 'Nutzungsbedingungen',
                    style: TextStyle(
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(text: ' und '),
                  TextSpan(
                    text: 'Datenschutzerklärung',
                    style: TextStyle(
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _isLoading ? null : _register,
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? AppColors.accent : AppColors.primary,
          foregroundColor: isDark ? AppColors.primary : AppColors.textLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                'Konto erstellen',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  // ============================================================
  // iOS Form
  // ============================================================

  Widget _buildRegisterFormIOS(bool isDark) {
    return Column(
      children: [
        _buildCupertinoTextField(
          controller: _nameController,
          label: 'Name',
          placeholder: 'Max Mustermann',
          error: _nameError,
          icon: CupertinoIcons.person,
          isDark: isDark,
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_nameError != null) _validateName(_nameController.text.trim());
          },
        ),
        const SizedBox(height: 20),
        _buildCupertinoTextField(
          controller: _emailController,
          label: 'E-Mail-Adresse',
          placeholder: 'name@beispiel.de',
          error: _emailError,
          icon: CupertinoIcons.mail,
          isDark: isDark,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_emailError != null)
              _validateEmail(_emailController.text.trim());
          },
        ),
        const SizedBox(height: 20),
        _buildCupertinoTextField(
          controller: _passwordController,
          label: 'Passwort',
          placeholder: '••••••••',
          error: _passwordError,
          icon: CupertinoIcons.lock,
          isDark: isDark,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          suffix: CupertinoButton(
            padding: const EdgeInsets.only(right: 8),
            minSize: 0,
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
              color: AppColors.grey,
              size: 20,
            ),
          ),
          onChanged: (_) {
            if (_passwordError != null)
              _validatePassword(_passwordController.text);
          },
        ),
        const SizedBox(height: 20),
        _buildCupertinoTextField(
          controller: _confirmPasswordController,
          label: 'Passwort bestätigen',
          placeholder: '••••••••',
          error: _confirmPasswordError,
          icon: CupertinoIcons.lock,
          isDark: isDark,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          suffix: CupertinoButton(
            padding: const EdgeInsets.only(right: 8),
            minSize: 0,
            onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword),
            child: Icon(
              _obscureConfirmPassword
                  ? CupertinoIcons.eye_slash
                  : CupertinoIcons.eye,
              color: AppColors.grey,
              size: 20,
            ),
          ),
          onSubmitted: (_) => _register(),
          onChanged: (_) {
            if (_confirmPasswordError != null) {
              _validateConfirmPassword(_confirmPasswordController.text);
            }
          },
        ),
      ],
    );
  }

  Widget _buildCupertinoTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required String? error,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffix,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: error != null ? AppColors.error : AppColors.grey,
            fontFamily: '.SF Pro Text',
          ),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          autocorrect: false,
          padding: const EdgeInsets.all(16),
          placeholder: placeholder,
          prefix: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Icon(icon,
                color: error != null ? AppColors.error : AppColors.grey,
                size: 20),
          ),
          suffix: suffix,
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: error != null
                  ? AppColors.error
                  : AppColors.grey.withOpacity(0.2),
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
          onChanged: onChanged,
          onSubmitted: onSubmitted,
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.error,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTermsCheckboxIOS(bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _acceptedTerms
                  ? (isDark ? AppColors.primaryLight : AppColors.primary)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _acceptedTerms
                    ? (isDark ? AppColors.primaryLight : AppColors.primary)
                    : AppColors.grey.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: _acceptedTerms
                ? Icon(
                    CupertinoIcons.checkmark,
                    size: 16,
                    color: isDark ? AppColors.primary : AppColors.textLight,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Ich akzeptiere die ',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey,
                  fontFamily: '.SF Pro Text',
                ),
                children: [
                  TextSpan(
                    text: 'Nutzungsbedingungen',
                    style: TextStyle(
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(text: ' und '),
                  TextSpan(
                    text: 'Datenschutzerklärung',
                    style: TextStyle(
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButtonIOS(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        color: isDark ? AppColors.accent : AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        onPressed: _isLoading ? null : _register,
        child: _isLoading
            ? CupertinoActivityIndicator(
                color: isDark ? AppColors.primary : AppColors.textLight,
              )
            : Text(
                'Konto erstellen',
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
}

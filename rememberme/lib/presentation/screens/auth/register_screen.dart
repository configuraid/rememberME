import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/data/services/biometric_service.dart';
import 'dart:io';

import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/auth/auth_event.dart';
import '../../../business_logic/auth/auth_state.dart';
import '../../../business_logic/memorial/memorial_bloc.dart';
import '../../../business_logic/memorial/memorial_event.dart';
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

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  final _biometricService = BiometricService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

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

  void _register() {
    FocusScope.of(context).unfocus();

    final nameValid = _validateName(_nameController.text.trim());
    final emailValid = _validateEmail(_emailController.text.trim());
    final passwordValid = _validatePassword(_passwordController.text);
    final confirmValid =
        _validateConfirmPassword(_confirmPasswordController.text);

    if (!nameValid || !emailValid || !passwordValid || !confirmValid) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
          ),
        );
  }

  Future<void> _enableBiometricLogin() async {
    // Biometrie einmal durchführen um Berechtigung zu bestätigen
    final authenticated = await _biometricService.authenticate(
      reason: 'Bestätige deine Identität für die Einrichtung',
    );

    if (authenticated) {
      await _biometricService.saveCredentials(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      debugPrint('✅ Biometric Login eingerichtet');
    }
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

  // ========================================
  // NEU: Biometric Setup Dialog
  // ========================================

  Future<void> _offerBiometricSetup(AuthState state) async {
    // Prüfe ob Gerät Biometrie unterstützt
    final isSupported = await _biometricService.isDeviceSupported();
    if (!isSupported || !mounted) {
      _navigateToHome(state);
      return;
    }

    final biometricName = await _biometricService.getBiometricTypeName();

    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      await showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => CupertinoAlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.person_crop_circle,
                color: isDark ? AppColors.accent : AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(biometricName),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Möchtest du dich nächstes Mal schneller mit $biometricName anmelden?',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                _navigateToHome(state);
              },
              child: const Text('Später'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _enableBiometricLogin();
                if (mounted) _navigateToHome(state);
              },
              child: Text('$biometricName aktivieren'),
            ),
          ],
        ),
      );
    } else {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor:
              isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.toastBackgroundDark
                  : AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fingerprint_rounded,
              size: 32,
              color: isDark ? AppColors.accent : AppColors.primary,
            ),
          ),
          title: Text(
            '$biometricName einrichten',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Möchtest du dich nächstes Mal schneller mit $biometricName anmelden?',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.grey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _navigateToHome(state);
              },
              child: Text(
                'Später',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.grey,
                ),
              ),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _enableBiometricLogin();
                if (mounted) _navigateToHome(state);
              },
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? AppColors.accent : AppColors.primary,
                foregroundColor:
                    isDark ? AppColors.primary : AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Aktivieren',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _navigateToHome(AuthState state) {
    if (!mounted) return;

    context.read<MemorialBloc>().add(const MemorialsClearRequested());
    context.read<MemorialBloc>().add(
          MemorialLoadRequested(userId: state.user!.id),
        );

    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (!state.isLoading) {
          setState(() => _isLoading = false);
        }

        if (state.isAuthenticated && state.user != null) {
          HapticFeedback.heavyImpact();
          _offerBiometricSetup(state);
        } else if (state.hasError) {
          _showError(state.errorMessage ?? 'Registrierung fehlgeschlagen');
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
        const SizedBox(height: 20),

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
              isIOS
                  ? CupertinoIcons.person_add_solid
                  : Icons.person_add_rounded,
              size: 48,
              color: isDark ? AppColors.accent : AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 32),

        Center(
          child: Text(
            'Account erstellen',
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
            'Registriere dich, um Gedenkseiten zu erstellen',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 40),

        _buildNameField(isDark, isIOS),
        const SizedBox(height: 16),
        _buildEmailField(isDark, isIOS),
        const SizedBox(height: 16),
        _buildPasswordField(isDark, isIOS),
        const SizedBox(height: 16),
        _buildConfirmPasswordField(isDark, isIOS),
        const SizedBox(height: 32),
        _buildRegisterButton(isDark, isIOS),

        const SizedBox(height: 24),

        // Login Link
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bereits ein Account? ',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
              isIOS
                  ? CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Anmelden',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.accent : AppColors.primary,
                        ),
                      ),
                    )
                  : TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Anmelden',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.accent : AppColors.primary,
                        ),
                      ),
                    ),
            ],
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  // ========================================
  // FIELD BUILDERS
  // ========================================

  Widget _buildNameField(bool isDark, bool isIOS) {
    if (isIOS) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoTextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _emailFocusNode.requestFocus(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            placeholder: 'Dein Name',
            prefix: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(
                CupertinoIcons.person,
                color: _nameError != null ? AppColors.error : AppColors.grey,
                size: 20,
              ),
            ),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _nameError != null
                    ? AppColors.error
                    : (isDark ? AppColors.borderDark : AppColors.greyLighter),
              ),
            ),
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
            onChanged: (_) {
              if (_nameError != null)
                _validateName(_nameController.text.trim());
            },
          ),
          if (_nameError != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(_nameError!,
                  style: const TextStyle(fontSize: 12, color: AppColors.error)),
            ),
          ],
        ],
      );
    }

    return TextField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => _emailFocusNode.requestFocus(),
      style: TextStyle(
        fontSize: 16,
        color: isDark ? AppColors.textLight : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Dein Name',
        errorText: _nameError,
        prefixIcon: Icon(Icons.person_outline,
            color: _nameError != null ? AppColors.error : AppColors.grey),
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
        if (_nameError != null) _validateName(_nameController.text.trim());
      },
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
              child: Icon(CupertinoIcons.mail,
                  color: _emailError != null ? AppColors.error : AppColors.grey,
                  size: 20),
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
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            placeholder: 'Passwort',
            prefix: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(CupertinoIcons.lock,
                  color:
                      _passwordError != null ? AppColors.error : AppColors.grey,
                  size: 20),
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
                    size: 20),
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
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
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
              color: AppColors.grey),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor:
            isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
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

  Widget _buildConfirmPasswordField(bool isDark, bool isIOS) {
    if (isIOS) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoTextField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _register(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            placeholder: 'Passwort bestätigen',
            prefix: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(CupertinoIcons.lock_shield,
                  color: _confirmPasswordError != null
                      ? AppColors.error
                      : AppColors.grey,
                  size: 20),
            ),
            suffix: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
                child: Icon(
                    _obscureConfirmPassword
                        ? CupertinoIcons.eye
                        : CupertinoIcons.eye_slash,
                    color: AppColors.grey,
                    size: 20),
              ),
            ),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _confirmPasswordError != null
                    ? AppColors.error
                    : (isDark ? AppColors.borderDark : AppColors.greyLighter),
              ),
            ),
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
            onChanged: (_) {
              if (_confirmPasswordError != null) {
                _validateConfirmPassword(_confirmPasswordController.text);
              }
            },
          ),
          if (_confirmPasswordError != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(_confirmPasswordError!,
                  style: const TextStyle(fontSize: 12, color: AppColors.error)),
            ),
          ],
        ],
      );
    }

    return TextField(
      controller: _confirmPasswordController,
      focusNode: _confirmPasswordFocusNode,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _register(),
      style: TextStyle(
        fontSize: 16,
        color: isDark ? AppColors.textLight : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Passwort bestätigen',
        errorText: _confirmPasswordError,
        prefixIcon: Icon(Icons.lock_outline,
            color: _confirmPasswordError != null
                ? AppColors.error
                : AppColors.grey),
        suffixIcon: IconButton(
          icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.grey),
          onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
        filled: true,
        fillColor:
            isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
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
        if (_confirmPasswordError != null) {
          _validateConfirmPassword(_confirmPasswordController.text);
        }
      },
    );
  }

  Widget _buildRegisterButton(bool isDark, bool isIOS) {
    if (isIOS) {
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
                  color: isDark ? AppColors.primary : AppColors.textLight)
              : Text(
                  'Registrieren',
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
        onPressed: _isLoading ? null : _register,
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
            : const Text('Registrieren',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

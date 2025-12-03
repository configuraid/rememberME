import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/business_logic/auth/auth_bloc.dart';
import 'package:rememberme/business_logic/auth/auth_event.dart';
import 'package:rememberme/business_logic/auth/auth_state.dart';
import 'package:rememberme/data/models/auth/organization_model.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class ProfileCreationScreen extends StatefulWidget {
  final OrganizationModel organization;

  const ProfileCreationScreen({
    super.key,
    required this.organization,
  });

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _usePin = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_usePin && _pinController.text != _confirmPinController.text) {
      _showError(AppStrings.pinsDontMatch);
      return;
    }

    setState(() => _isLoading = true);

    try {
      context.read<AuthBloc>().add(
            AuthNewProfileCreationRequested(
              organizationId: widget.organization.id,
              name: _nameController.text,
              email: _emailController.text,
              pin: _usePin ? _pinController.text : null,
            ),
          );
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(
            AppStrings.errorTitle,
            style: TextStyle(
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: AppColors.grey,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                AppStrings.ok,
                style: TextStyle(
                  color: AppColors.interactive,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: AppColors.textLight),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  // ============================================================
  // Helper: InputDecoration mit TextDecoration.none
  // ============================================================
  InputDecoration _buildInputDecoration({
    required String labelText,
    String? hintText,
    required Widget prefixIcon,
    required bool isDark,
    EdgeInsetsGeometry? contentPadding,
    String? counterText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      counterText: counterText,
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
      // FIX: Alle TextStyles mit decoration: TextDecoration.none
      labelStyle: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 15,
        decoration: TextDecoration.none,
      ),
      floatingLabelStyle: TextStyle(
        color: isDark ? AppColors.primaryLight : AppColors.primary,
        fontSize: 14,
        decoration: TextDecoration.none,
      ),
      hintStyle: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 15,
        decoration: TextDecoration.none,
      ),
      errorStyle: const TextStyle(
        color: AppColors.error,
        fontSize: 12,
        decoration: TextDecoration.none,
      ),
      // Alle Borders explizit setzen
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSView();
    }
    return _buildAndroidView();
  }

  // ===== ANDROID VIEW =====
  Widget _buildAndroidView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardVisible = mediaQuery.viewInsets.bottom > 0;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isAuthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.dashboard,
            (route) => false,
          );
        } else if (state.hasError) {
          setState(() => _isLoading = false);
          _showError(state.errorMessage ?? AppStrings.errorOccurred);
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDarkSecondary : AppColors.background,
        appBar: AppBar(
          title: Text(AppStrings.createProfile),
          elevation: 0,
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
          foregroundColor: AppColors.textLight,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: keyboardVisible ? 12 : 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header - kompakter wenn Keyboard offen
                          if (!keyboardVisible) ...[
                            SizedBox(height: screenHeight > 700 ? 16 : 8),

                            // Icon mit Background
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.primaryLight.withOpacity(0.2)
                                      : AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_add_rounded,
                                  size: 48,
                                  color: isDark
                                      ? AppColors.primaryLight
                                      : AppColors.primary,
                                ),
                              ),
                            ),

                            SizedBox(height: screenHeight > 700 ? 16 : 12),

                            // Titel
                            Text(
                              AppStrings.newProfile,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textLight
                                    : AppColors.textPrimary,
                                decoration: TextDecoration.none,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 4),

                            // Untertitel
                            Text(
                              widget.organization.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AppColors.textDarkSecondary
                                    : AppColors.textSecondary,
                                decoration: TextDecoration.none,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            SizedBox(height: screenHeight > 700 ? 20 : 16),
                          ] else ...[
                            const SizedBox(height: 8),
                          ],

                          // Formular Card
                          Card(
                            elevation: isDark ? 2 : 1,
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.surface,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Name Field
                                  TextFormField(
                                    controller: _nameController,
                                    validator: Validators.validateName,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: isDark
                                          ? AppColors.textLight
                                          : AppColors.textPrimary,
                                      decoration: TextDecoration.none,
                                    ),
                                    decoration: _buildInputDecoration(
                                      labelText: AppStrings.name,
                                      hintText: AppStrings.yourFullName,
                                      prefixIcon: Icon(
                                        Icons.person_outline_rounded,
                                        color: isDark
                                            ? AppColors.primaryLight
                                            : AppColors.primary,
                                      ),
                                      isDark: isDark,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Email Field
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: isDark
                                          ? AppColors.textLight
                                          : AppColors.textPrimary,
                                      decoration: TextDecoration.none,
                                    ),
                                    decoration: _buildInputDecoration(
                                      labelText: AppStrings.emailOptional,
                                      hintText: AppStrings.emailExample,
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                        color: isDark
                                            ? AppColors.primaryLight
                                            : AppColors.primary,
                                      ),
                                      isDark: isDark,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // PIN Switch - kompakt
                                  InkWell(
                                    onTap: () =>
                                        setState(() => _usePin = !_usePin),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.surfaceDark
                                            : AppColors.primary
                                                .withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.borderDarkSubtle
                                              : AppColors.primary
                                                  .withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.shield_outlined,
                                            size: 20,
                                            color: isDark
                                                ? AppColors.primaryLight
                                                : AppColors.primary,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  AppStrings.pinProtection,
                                                  style: theme
                                                      .textTheme.bodyMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark
                                                        ? AppColors.textLight
                                                        : AppColors.textPrimary,
                                                    decoration:
                                                        TextDecoration.none,
                                                  ),
                                                ),
                                                Text(
                                                  AppStrings.fourDigitPin,
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: isDark
                                                        ? AppColors
                                                            .textDarkSecondary
                                                        : AppColors
                                                            .textSecondary,
                                                    fontSize: 12,
                                                    decoration:
                                                        TextDecoration.none,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Switch(
                                            value: _usePin,
                                            onChanged: (value) =>
                                                setState(() => _usePin = value),
                                            activeColor: isDark
                                                ? AppColors.primaryLight
                                                : AppColors.primary,
                                            activeTrackColor: isDark
                                                ? AppColors.primaryLight
                                                    .withOpacity(0.3)
                                                : AppColors.primary
                                                    .withOpacity(0.3),
                                            inactiveThumbColor: isDark
                                                ? AppColors.greyDark
                                                : AppColors.grey,
                                            inactiveTrackColor: isDark
                                                ? AppColors.cardBorderDark
                                                : AppColors.greyLight,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // PIN Fields (conditional)
                                  if (_usePin) ...[
                                    const SizedBox(height: 16),

                                    // PIN Row - zwei Felder nebeneinander
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _pinController,
                                            validator: _usePin
                                                ? Validators.validatePin
                                                : null,
                                            obscureText: true,
                                            keyboardType: TextInputType.number,
                                            maxLength: 4,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              color: isDark
                                                  ? AppColors.textLight
                                                  : AppColors.textPrimary,
                                              decoration: TextDecoration.none,
                                            ),
                                            decoration: _buildInputDecoration(
                                              labelText: AppStrings.pin,
                                              hintText: '••••',
                                              prefixIcon: Icon(
                                                Icons.lock_outline_rounded,
                                                size: 20,
                                                color: isDark
                                                    ? AppColors.primaryLight
                                                    : AppColors.primary,
                                              ),
                                              isDark: isDark,
                                              counterText: '',
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _confirmPinController,
                                            validator: _usePin
                                                ? Validators.validatePin
                                                : null,
                                            obscureText: true,
                                            keyboardType: TextInputType.number,
                                            maxLength: 4,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              color: isDark
                                                  ? AppColors.textLight
                                                  : AppColors.textPrimary,
                                              decoration: TextDecoration.none,
                                            ),
                                            decoration: _buildInputDecoration(
                                              labelText: AppStrings.confirm,
                                              hintText: '••••',
                                              prefixIcon: Icon(
                                                Icons.lock_outline_rounded,
                                                size: 20,
                                                color: isDark
                                                    ? AppColors.primaryLight
                                                    : AppColors.primary,
                                              ),
                                              isDark: isDark,
                                              counterText: '',
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  const SizedBox(height: 20),

                                  // Create Button
                                  FilledButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleCreateProfile,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: isDark
                                          ? AppColors.primaryLight
                                          : AppColors.primary,
                                      foregroundColor: AppColors.textLight,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                AppColors.textLight,
                                              ),
                                            ),
                                          )
                                        : Text(
                                            AppStrings.createProfile,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              color: AppColors.textLight,
                                              fontWeight: FontWeight.w600,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Info Box - kompakt
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.info
                                  .withOpacity(isDark ? 0.15 : 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.info
                                    .withOpacity(isDark ? 0.4 : 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.info,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    AppStrings.profileEditableLater,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? AppColors.info.withOpacity(0.9)
                                          : AppColors.info,
                                      fontSize: 12,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ===== iOS VIEW =====
  Widget _buildIOSView() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isAuthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.dashboard,
            (route) => false,
          );
        } else if (state.hasError) {
          setState(() => _isLoading = false);
          _showError(state.errorMessage ?? AppStrings.errorOccurred);
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            AppStrings.createProfile,
            style: TextStyle(
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          backgroundColor: isDark
              ? AppColors.backgroundDarkElevated.withOpacity(0.94)
              : AppColors.surface.withOpacity(0.94),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    CupertinoIcons.person_add,
                    size: 80,
                    color: isDark ? AppColors.accent : AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.newProfile,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppStrings.createYourPersonalProfile}\n${widget.organization.name}',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.grey,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Name
                  _buildIOSTextField(
                    controller: _nameController,
                    placeholder: AppStrings.yourFullName,
                    prefix: Icon(
                      CupertinoIcons.person,
                      color: AppColors.grey,
                    ),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  _buildIOSTextField(
                    controller: _emailController,
                    placeholder: '${AppStrings.emailExample} (optional)',
                    prefix: Icon(
                      CupertinoIcons.mail,
                      color: AppColors.grey,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  // PIN Schutz
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.backgroundDarkElevated
                          : AppColors.greyLighter,
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.activatePinProtection,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.textLight
                                      : AppColors.textPrimary,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.protectProfileWithPin,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.grey,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CupertinoSwitch(
                          value: _usePin,
                          onChanged: (value) => setState(() => _usePin = value),
                          activeTrackColor:
                              isDark ? AppColors.accent : AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                  if (_usePin) ...[
                    const SizedBox(height: 16),
                    _buildIOSTextField(
                      controller: _pinController,
                      placeholder: AppStrings.fourDigitPin,
                      prefix: Icon(
                        CupertinoIcons.lock,
                        color: AppColors.grey,
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildIOSTextField(
                      controller: _confirmPinController,
                      placeholder: AppStrings.enterPinAgain,
                      prefix: Icon(
                        CupertinoIcons.lock,
                        color: AppColors.grey,
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Erstellen Button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: _isLoading ? null : _handleCreateProfile,
                      child: _isLoading
                          ? CupertinoActivityIndicator(
                              color: AppColors.textLight,
                            )
                          : Text(
                              AppStrings.createProfile,
                              style: const TextStyle(
                                color: AppColors.textLight,
                                decoration: TextDecoration.none,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.info.withOpacity(isDark ? 0.4 : 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.info_circle,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppStrings.canEditProfileLater,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.info.withOpacity(0.9)
                                  : AppColors.info,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildIOSTextField({
    required TextEditingController controller,
    required String placeholder,
    required bool isDark,
    Widget? prefix,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.backgroundDarkElevated : AppColors.greyLighter,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        obscureText: obscureText,
        keyboardType: keyboardType,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefix: prefix != null
            ? Padding(
                padding: const EdgeInsets.only(left: 8, right: 12),
                child: prefix,
              )
            : null,
        decoration: const BoxDecoration(),
        style: TextStyle(
          color: isDark ? AppColors.textLight : AppColors.textPrimary,
          decoration: TextDecoration.none,
        ),
        placeholderStyle: TextStyle(
          color: AppColors.grey,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

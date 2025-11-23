import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/business_logic/auth/auth_bloc.dart';
import 'package:rememberme/business_logic/auth/auth_event.dart';
import 'package:rememberme/business_logic/auth/auth_state.dart';
import 'package:rememberme/presentation/widgets/common/custom_text_field.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authKeyController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _authKeyController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      context.read<AuthBloc>().add(
            AuthLoginWithKeyRequested(_authKeyController.text),
          );
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleQRCodeScan() async {
    _showError(AppStrings.qrScannerNotImplemented);
  }

  void _showError(String message) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(
            AppStrings.errorTitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                AppStrings.ok,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSView();
    }
    return _buildAndroidView();
  }

  Widget _buildAndroidView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state.status == AuthStatus.unauthenticated && !state.hasError) {
          final authRepo = context.read<AuthBloc>().authRepository;
          final organization = authRepo.currentOrganization;

          if (organization != null) {
            setState(() => _isLoading = false);

            final membersWithData =
                await authRepo.getUsersForOrganization(organization.id);

            if (mounted) {
              Navigator.of(context).pushNamed(
                AppRoutes.userSelection,
                arguments: {
                  'organization': organization,
                  'membersWithData': membersWithData,
                },
              );
            }
          }
        } else if (state.hasError) {
          setState(() => _isLoading = false);
          _showError(state.errorMessage ?? AppStrings.errorOccurred);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Logo Container mit Gradient und Schatten
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.primaryGradient,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // App-Name
                    Text(
                      AppStrings.appNameRememberMe,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Untertitel
                    Text(
                      AppStrings.digitalMemorials,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? const Color(0xFFB0B0B0)
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // Haupt-Card mit Input und Button
                    Card(
                      elevation: isDark ? 4 : 2,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Auth-Key Input
                            TextFormField(
                              controller: _authKeyController,
                              validator: Validators.validateAuthKey,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(),
                              style: theme.textTheme.bodyLarge,
                              decoration: InputDecoration(
                                labelText: AppStrings.authKey,
                                hintText: AppStrings.enterYourAuthKey,
                                prefixIcon: Icon(
                                  Icons.key_rounded,
                                  color: isDark
                                      ? AppColors.primaryLight
                                      : AppColors.primary,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Login Button
                            FilledButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: FilledButton.styleFrom(
                                backgroundColor: isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                                foregroundColor: AppColors.textLight,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
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
                                      AppStrings.login,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: AppColors.textLight,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider mit "oder"
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            AppStrings.or,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? const Color(0xFFB0B0B0)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // QR-Code Button
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleQRCodeScan,
                      icon: Icon(
                        Icons.qr_code_scanner_rounded,
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                      label: Text(
                        AppStrings.scanQrCode,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Info-Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.info.withOpacity(isDark ? 0.4 : 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.info,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppStrings.noAuthKey,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AppColors.info.withOpacity(0.9)
                                    : AppColors.info,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIOSView() {
    // Dark Mode Detection
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state.status == AuthStatus.unauthenticated && !state.hasError) {
          final authRepo = context.read<AuthBloc>().authRepository;
          final organization = authRepo.currentOrganization;

          if (organization != null) {
            setState(() => _isLoading = false);

            final membersWithData =
                await authRepo.getUsersForOrganization(organization.id);

            if (mounted) {
              Navigator.of(context).pushNamed(
                AppRoutes.userSelection,
                arguments: {
                  'organization': organization,
                  'membersWithData': membersWithData,
                },
              );
            }
          }
        } else if (state.hasError) {
          setState(() => _isLoading = false);
          _showError(state.errorMessage ?? AppStrings.errorOccurred);
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor:
            isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        child: SafeArea(
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 17,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              fontFamily: '.SF Pro Text',
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),

                    // Logo mit Gradient
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: AppColors.primaryGradient,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary
                                  .withOpacity(isDark ? 0.4 : 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.heart_fill,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // App-Name
                    Text(
                      AppStrings.appNameRememberMe,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                        letterSpacing: -0.5,
                        fontFamily: '.SF Pro Display',
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Untertitel
                    Text(
                      AppStrings.digitalMemorials,
                      style: TextStyle(
                        fontSize: 17,
                        color: CupertinoColors.systemGrey,
                        fontWeight: FontWeight.w400,
                        fontFamily: '.SF Pro Text',
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 60),

                    // Input Card Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1C1C1E)
                            : CupertinoColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.08),
                            blurRadius: isDark ? 12 : 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Auth-Key Input
                          CustomTextField(
                            controller: _authKeyController,
                            label: AppStrings.authKey,
                            hint: AppStrings.enterYourAuthKey,
                            validator: Validators.validateAuthKey,
                            prefixIcon: Icons.key_outlined,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                          ),

                          const SizedBox(height: 20),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              disabledColor: isDark
                                  ? AppColors.primary.withOpacity(0.5)
                                  : AppColors.primary.withOpacity(0.5),
                              color: isDark
                                  ? AppColors.primaryLight
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? const CupertinoActivityIndicator(
                                      color: CupertinoColors.white,
                                    )
                                  : Text(
                                      AppStrings.login,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: CupertinoColors.white,
                                        fontFamily: '.SF Pro Text',
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Divider mit "oder"
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: isDark
                                ? CupertinoColors.systemGrey3.darkColor
                                : CupertinoColors.systemGrey4,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            AppStrings.or,
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.systemGrey,
                              fontWeight: FontWeight.w500,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: isDark
                                ? CupertinoColors.systemGrey3.darkColor
                                : CupertinoColors.systemGrey4,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // QR-Code Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        disabledColor: isDark
                            ? const Color(0xFF2C2C2E)
                            : CupertinoColors.systemGrey6,
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: _isLoading ? null : _handleQRCodeScan,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.qrcode_viewfinder,
                              size: 24,
                              color: isDark
                                  ? AppColors.primaryLight
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              AppStrings.scanQrCode,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                                fontFamily: '.SF Pro Text',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Info-Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.info.withOpacity(0.15)
                            : AppColors.info.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.info.withOpacity(0.4)
                              : AppColors.info.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            CupertinoIcons.info_circle,
                            color: isDark
                                ? AppColors.info.withOpacity(0.9)
                                : AppColors.info,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppStrings.noAuthKey,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.info.withOpacity(0.9)
                                    : AppColors.info,
                                height: 1.4,
                                fontFamily: '.SF Pro Text',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

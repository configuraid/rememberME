import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/business_logic/auth/auth_bloc.dart';
import 'package:rememberme/business_logic/auth/auth_event.dart';
import 'package:rememberme/business_logic/auth/auth_state.dart';
import 'package:rememberme/presentation/widgets/common/custom_text_field.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
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
      print('🔐 LoginScreen - Login mit Auth-Key: ${_authKeyController.text}');

      context.read<AuthBloc>().add(
            AuthLoginWithKeyRequested(_authKeyController.text),
          );
    } catch (e) {
      print('❌ LoginScreen - Fehler: $e');
      if (mounted) {
        _showError(e.toString());
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleQRCodeScan() async {
    _showError('QR-Code Scanner noch nicht implementiert');
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
              child: const Text('OK'),
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
        print('👂 LoginScreen Listener - Status: ${state.status}');

        if (state.status == AuthStatus.unauthenticated && !state.hasError) {
          final authRepo = context.read<AuthBloc>().authRepository;
          final organization = authRepo.currentOrganization;

          if (organization != null) {
            print(
                '✅ LoginScreen - Organisation gefunden: ${organization.name}');
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
          print('❌ LoginScreen - Fehler: ${state.errorMessage}');
          setState(() => _isLoading = false);
          _showError(state.errorMessage ?? 'Ein Fehler ist aufgetreten');
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
                      'rememberME',
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
                      'Digitale Gedenkseiten',
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
                                labelText: 'Auth-Key',
                                hintText: 'Gib deinen Auth-Key ein',
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
                                      'Anmelden',
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
                            'oder',
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
                        'QR-Code scannen',
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
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.info,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Keinen Auth-Key? Kontaktiere deinen Administrator',
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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        print('👂 LoginScreen iOS Listener - Status: ${state.status}');

        if (state.status == AuthStatus.unauthenticated && !state.hasError) {
          final authRepo = context.read<AuthBloc>().authRepository;
          final organization = authRepo.currentOrganization;

          if (organization != null) {
            print(
                '✅ LoginScreen iOS - Organisation gefunden: ${organization.name}');
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
          print('❌ LoginScreen iOS - Fehler: ${state.errorMessage}');
          setState(() => _isLoading = false);
          _showError(state.errorMessage ?? 'Ein Fehler ist aufgetreten');
        }
      },
      child: CupertinoPageScaffold(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  // Logo mit Gradient
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
                      CupertinoIcons.heart_fill,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'rememberME',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Digitale Gedenkseiten',
                    style: TextStyle(
                      fontSize: 17,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  CustomTextField(
                    controller: _authKeyController,
                    label: 'Auth-Key',
                    hint: 'Gib deinen Auth-Key ein',
                    validator: Validators.validateAuthKey,
                    prefixIcon: Icons.key_outlined,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : const Text(
                              'Anmelden',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'oder',
                          style: TextStyle(
                            fontSize: 15,
                            color: CupertinoColors.secondaryLabel
                                .resolveFrom(context),
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      onPressed: _isLoading ? null : _handleQRCodeScan,
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.qrcode_viewfinder,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'QR-Code scannen',
                            style: TextStyle(
                              fontSize: 16,
                              color: CupertinoColors.label.resolveFrom(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.info.withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          CupertinoIcons.info_circle,
                          color: AppColors.info,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Keinen Auth-Key? Kontaktiere deinen Administrator',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.info,
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
}

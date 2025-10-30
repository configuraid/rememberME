import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/auth/auth_event.dart';
import '../../../business_logic/auth/auth_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_indicator.dart';

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

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context
          .read<AuthBloc>()
          .add(AuthLoginWithKeyRequested(_authKeyController.text));
    }
  }

  void _handleQRScan() {
    Navigator.of(context).pushNamed(AppRoutes.qrScanner);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        setState(() => _isLoading = state.isLoading);

        if (state.isAuthenticated) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
        } else if (state.hasError) {
          _showError(context, state.errorMessage ?? AppStrings.error);
        }
      },
      child: Scaffold(
        backgroundColor:
            Platform.isIOS ? CupertinoColors.systemBackground : null,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo/Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        size: 50,
                        color: AppColors.accent,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Titel
                    Text(
                      AppStrings.welcome,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Untertitel
                    Text(
                      AppStrings.welcomeMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // Auth-Key Input
                    CustomTextField(
                      controller: _authKeyController,
                      label: AppStrings.authKeyLabel,
                      hint: AppStrings.authKeyHint,
                      validator: Validators.validateAuthKey,
                      prefixIcon: Icons.vpn_key,
                    ),

                    const SizedBox(height: 24),

                    // Login Button
                    CustomButton(
                      text: AppStrings.login,
                      onPressed: _isLoading ? null : _handleLogin,
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: 16),

                    // Oder-Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            AppStrings.or,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // QR-Code Scan Button
                    CustomButton(
                      text: AppStrings.scanQRCode,
                      onPressed: _isLoading ? null : _handleQRScan,
                      variant: ButtonVariant.outlined,
                      icon: Icons.qr_code_scanner,
                    ),

                    const SizedBox(height: 32),

                    // Hinweis (Demo-Key)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.info.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Demo-Key: DEMO-AUTH-KEY-12345',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
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
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text(AppStrings.error),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

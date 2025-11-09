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
      _showError('PINs stimmen nicht überein');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print(
          '➕ ProfileCreationScreen - Erstelle Profil: ${_nameController.text}');
      print('📍 Organisation: ${widget.organization.id}');
      if (_usePin) print('🔒 Mit PIN');

      context.read<AuthBloc>().add(
            AuthNewProfileCreationRequested(
              organizationId: widget.organization.id,
              name: _nameController.text,
              email: _emailController.text,
              pin: _usePin ? _pinController.text : null,
            ),
          );

      print('⏳ Warte auf Auth-State Änderung...');
    } catch (e) {
      print('❌ ProfileCreationScreen - Fehler: $e');
      if (mounted) {
        _showError(e.toString());
        setState(() => _isLoading = false);
      }
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

  // ===== ANDROID VIEW =====
  Widget _buildAndroidView() {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        print('👂 ProfileCreationScreen Listener - Status: ${state.status}');

        if (state.isAuthenticated) {
          print('✅ ProfileCreationScreen - User authentifiziert');
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.dashboard,
            (route) => false,
          );
        } else if (state.hasError) {
          print('❌ ProfileCreationScreen - Fehler: ${state.errorMessage}');
          setState(() => _isLoading = false);
          _showError(state.errorMessage ?? 'Ein Fehler ist aufgetreten');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profil erstellen'),
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.person_add_outlined,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Neues Profil',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Erstelle dein persönliches Profil für\n${widget.organization.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  CustomTextField(
                    controller: _nameController,
                    label: 'Name',
                    hint: 'Dein vollständiger Name',
                    validator: Validators.validateName,
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _emailController,
                    label: 'E-Mail (optional)',
                    hint: 'beispiel@email.de',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: const Text('PIN-Schutz aktivieren'),
                    subtitle: const Text(
                      'Schütze dein Profil mit einer 4-stelligen PIN',
                    ),
                    value: _usePin,
                    onChanged: (value) => setState(() => _usePin = value),
                    activeColor: AppColors.primary,
                  ),
                  if (_usePin) ...[
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _pinController,
                      label: 'PIN',
                      hint: '4-stellige PIN',
                      validator: _usePin ? Validators.validatePin : null,
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _confirmPinController,
                      label: 'PIN bestätigen',
                      hint: 'PIN erneut eingeben',
                      validator: _usePin ? Validators.validatePin : null,
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Profil erstellen',
                    onPressed: _isLoading ? null : _handleCreateProfile,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
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
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Du kannst dein Profil später jederzeit bearbeiten',
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

  // ===== iOS VIEW =====
  Widget _buildIOSView() {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        print(
            '👂 ProfileCreationScreen iOS Listener - Status: ${state.status}');

        if (state.isAuthenticated) {
          print('✅ ProfileCreationScreen iOS - User authentifiziert');
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.dashboard,
            (route) => false,
          );
        } else if (state.hasError) {
          print('❌ ProfileCreationScreen iOS - Fehler: ${state.errorMessage}');
          setState(() => _isLoading = false);
          _showError(state.errorMessage ?? 'Ein Fehler ist aufgetreten');
        }
      },
      child: CupertinoPageScaffold(
        // ✅ KRITISCH: Keine benutzerdefinierten Styles in NavigationBar
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Profil erstellen'),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    CupertinoIcons.person_add,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Neues Profil',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Erstelle dein persönliches Profil für\n${widget.organization.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.systemGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Name
                  _buildIOSTextField(
                    controller: _nameController,
                    placeholder: 'Dein vollständiger Name',
                    prefix: const Icon(
                      CupertinoIcons.person,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  _buildIOSTextField(
                    controller: _emailController,
                    placeholder: 'beispiel@email.de (optional)',
                    prefix: const Icon(
                      CupertinoIcons.mail,
                      color: CupertinoColors.systemGrey,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),

                  // PIN Schutz
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PIN-Schutz aktivieren',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Schütze dein Profil mit einer 4-stelligen PIN',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CupertinoSwitch(
                          value: _usePin,
                          onChanged: (value) => setState(() => _usePin = value),
                        ),
                      ],
                    ),
                  ),

                  if (_usePin) ...[
                    const SizedBox(height: 16),
                    _buildIOSTextField(
                      controller: _pinController,
                      placeholder: '4-stellige PIN',
                      prefix: const Icon(
                        CupertinoIcons.lock,
                        color: CupertinoColors.systemGrey,
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildIOSTextField(
                      controller: _confirmPinController,
                      placeholder: 'PIN erneut eingeben',
                      prefix: const Icon(
                        CupertinoIcons.lock,
                        color: CupertinoColors.systemGrey,
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Erstellen Button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: _isLoading ? null : _handleCreateProfile,
                      child: _isLoading
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : const Text('Profil erstellen'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info Box
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
                            'Du kannst dein Profil später jederzeit bearbeiten',
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

  // Helper Widget für iOS TextFields
  Widget _buildIOSTextField({
    required TextEditingController controller,
    required String placeholder,
    Widget? prefix,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.all(Radius.circular(10)),
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
      ),
    );
  }
}

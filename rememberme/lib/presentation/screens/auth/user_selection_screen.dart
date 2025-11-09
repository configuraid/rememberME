import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/business_logic/auth/auth_bloc.dart';
import 'package:rememberme/business_logic/auth/auth_event.dart';
import 'package:rememberme/business_logic/auth/auth_state.dart';
import 'package:rememberme/data/models/auth/organization_member_model.dart';
import 'package:rememberme/data/models/auth/organization_model.dart';
import 'package:rememberme/data/models/auth/user_model.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';

class UserSelectionScreen extends StatefulWidget {
  final OrganizationModel organization;
  final List<Map<String, dynamic>> membersWithData;

  const UserSelectionScreen({
    super.key,
    required this.organization,
    required this.membersWithData,
  });

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  String? _selectedUserId;
  final _pinController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _handleUserSelection(String userId, bool hasPin) {
    setState(() => _selectedUserId = userId);

    if (hasPin) {
      _showPinDialog(userId);
    } else {
      _proceedWithLogin(userId, null);
    }
  }

  void _showPinDialog(String userId) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('PIN eingeben'),
          content: Column(
            children: [
              const SizedBox(height: 12),
              const Text('Dieses Profil ist mit einer PIN geschützt'),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _pinController,
                placeholder: 'PIN',
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _selectedUserId = null);
              },
              child: const Text('Abbrechen'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                _proceedWithLogin(userId, _pinController.text);
              },
              isDefaultAction: true,
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('PIN eingeben'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Dieses Profil ist mit einer PIN geschützt'),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _selectedUserId = null);
              },
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _proceedWithLogin(userId, _pinController.text);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _proceedWithLogin(String userId, String? pin) async {
    setState(() => _isLoading = true);

    try {
      print('🔐 UserSelectionScreen - Login mit User: $userId');

      context.read<AuthBloc>().add(
            AuthUserSelectionRequested(
              organizationId: widget.organization.id,
              userId: userId,
              pin: pin,
            ),
          );
    } catch (e) {
      print('❌ UserSelectionScreen - Fehler: $e');
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

  void _createNewProfile() {
    print('➕ UserSelectionScreen - Navigiere zu ProfileCreationScreen');

    // ✅ Named Route Navigation
    Navigator.of(context).pushNamed(
      AppRoutes.profileCreation,
      arguments: widget.organization,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSView();
    }
    return _buildAndroidView();
  }

  Widget _buildAndroidView() {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isAuthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.dashboard,
            (route) => false,
          );
        } else if (state.hasError) {
          setState(() => _isLoading = false);
          _showError(state.errorMessage ?? 'Ein Fehler ist aufgetreten');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profil auswählen'),
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 60,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.organization.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            inherit: true,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Wähle dein Profil oder erstelle ein neues',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.membersWithData.length,
                      itemBuilder: (context, index) {
                        final data = widget.membersWithData[index];
                        final user = data['user'] as UserModel;
                        final member =
                            data['member'] as OrganizationMemberModel;
                        return _buildUserCard(user, member);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _createNewProfile,
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'Neues Profil erstellen',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildIOSView() {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isAuthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.dashboard,
            (route) => false,
          );
        } else if (state.hasError) {
          setState(() => _isLoading = false);
          _showError(state.errorMessage ?? 'Ein Fehler ist aufgetreten');
        }
      },
      child: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Profil auswählen'),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator(radius: 20))
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(
                            CupertinoIcons.person_2,
                            size: 60,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.organization.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Wähle dein Profil oder erstelle ein neues',
                            style: TextStyle(
                              fontSize: 16,
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: widget.membersWithData.length,
                        itemBuilder: (context, index) {
                          final data = widget.membersWithData[index];
                          final user = data['user'] as UserModel;
                          final member =
                              data['member'] as OrganizationMemberModel;
                          return _buildUserCard(user, member);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          onPressed: _createNewProfile,
                          color:
                              CupertinoColors.systemGrey6.resolveFrom(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.add,
                                color:
                                    CupertinoColors.label.resolveFrom(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Neues Profil erstellen',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: CupertinoColors.label
                                      .resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user, OrganizationMemberModel member) {
    final bool isSelected = _selectedUserId == user.id;

    return GestureDetector(
      onTap: () => _handleUserSelection(user.id, member.hasPin),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Platform.isIOS
                  ? CupertinoColors.systemBackground.resolveFrom(context)
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Platform.isIOS
                    ? CupertinoColors.separator.resolveFrom(context)
                    : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        member.hasPin
                            ? Icons.lock_outline
                            : Icons.lock_open_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        member.roleText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Platform.isIOS
                  ? CupertinoIcons.chevron_right
                  : Icons.chevron_right,
              color: isSelected ? AppColors.primary : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

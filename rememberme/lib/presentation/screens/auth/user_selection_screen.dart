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
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
              const SizedBox(width: 12),
              const Text('PIN eingeben'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dieses Profil ist mit einer PIN geschützt',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? const Color(0xFFB0B0B0)
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: 'PIN',
                  hintText: '4-stellige PIN',
                  prefixIcon: Icon(
                    Icons.pin_outlined,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _selectedUserId = null);
                _pinController.clear();
              },
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _proceedWithLogin(userId, _pinController.text);
                _pinController.clear();
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.primaryLight : AppColors.primary,
              ),
              child: const Text('Anmelden'),
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
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _createNewProfile() {
    print('➕ UserSelectionScreen - Navigiere zu ProfileCreationScreen');

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
          foregroundColor: AppColors.textLight,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Header mit Organisation
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark
                            ? [
                                AppColors.primaryLight.withOpacity(0.15),
                                Colors.transparent,
                              ]
                            : [
                                AppColors.primary.withOpacity(0.1),
                                Colors.transparent,
                              ],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Organisation Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primaryLight.withOpacity(0.2)
                                : AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.business_rounded,
                            size: 48,
                            color: isDark
                                ? AppColors.primaryLight
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Organisation Name
                        Text(
                          widget.organization.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Untertitel
                        Text(
                          'Wähle dein Profil oder erstelle ein neues',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? const Color(0xFFB0B0B0)
                                : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // User Liste
                  Expanded(
                    child: widget.membersWithData.isEmpty
                        ? _buildEmptyState(isDark)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: widget.membersWithData.length,
                            itemBuilder: (context, index) {
                              final data = widget.membersWithData[index];
                              final user = data['user'] as UserModel;
                              final member =
                                  data['member'] as OrganizationMemberModel;
                              return _buildUserCard(user, member, isDark);
                            },
                          ),
                  ),

                  // Neues Profil Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          isDark ? const Color(0xFF2A2A2A) : AppColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _createNewProfile,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text(
                            'Neues Profil erstellen',
                            style: TextStyle(
                              fontSize: 16,
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
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_rounded,
              size: 80,
              color: isDark
                  ? AppColors.primaryLight.withOpacity(0.5)
                  : AppColors.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Noch keine Profile',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Erstelle dein erstes Profil, um zu beginnen',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
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
                          return _buildUserCard(user, member, false);
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

  Widget _buildUserCard(
      UserModel user, OrganizationMemberModel member, bool isDark) {
    final theme = Theme.of(context);
    final bool isSelected = _selectedUserId == user.id;

    return GestureDetector(
      onTap: () => _handleUserSelection(user.id, member.hasPin),
      child: Card(
        elevation: isSelected ? 4 : (isDark ? 2 : 1),
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? (isDark ? AppColors.primaryLight : AppColors.primary)
                : (isDark ? const Color(0xFF404040) : AppColors.border),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppColors.primaryLight.withOpacity(0.15),
                            AppColors.primaryLight.withOpacity(0.05),
                          ]
                        : [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.primary.withOpacity(0.05),
                          ],
                  )
                : null,
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: isDark
                                ? AppColors.primaryLight.withOpacity(0.3)
                                : AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: isDark
                      ? AppColors.primaryLight.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.2),
                  backgroundImage: user.profileImageUrl != null
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl == null
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.primaryLight
                                : AppColors.primary,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          member.hasPin
                              ? Icons.lock_rounded
                              : Icons.lock_open_rounded,
                          size: 16,
                          color: isDark
                              ? const Color(0xFFB0B0B0)
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          member.roleText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? const Color(0xFFB0B0B0)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 20,
                color: isSelected
                    ? (isDark ? AppColors.primaryLight : AppColors.primary)
                    : (isDark
                        ? const Color(0xFF707070)
                        : AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

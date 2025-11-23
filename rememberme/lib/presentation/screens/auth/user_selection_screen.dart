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
import '../../../core/constants/app_strings.dart';
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
      final brightness = CupertinoTheme.brightnessOf(context);
      final isDark = brightness == Brightness.dark;

      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(
            AppStrings.enterPin,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                AppStrings.profileProtectedWithPin,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.systemGrey2,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _pinController,
                placeholder: AppStrings.pin,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                autofocus: true,
                style: TextStyle(
                  fontSize: 17,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  fontFamily: '.SF Pro Text',
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _selectedUserId = null);
                _pinController.clear();
              },
              child: Text(
                AppStrings.cancel,
                style: const TextStyle(
                  fontSize: 17,
                  color: CupertinoColors.systemRed,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                _proceedWithLogin(userId, _pinController.text);
                _pinController.clear();
              },
              isDefaultAction: true,
              child: Text(
                AppStrings.login,
                style: TextStyle(
                  fontSize: 17,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      showDialog(
        context: context,
        barrierDismissible: false,
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
              Text(AppStrings.enterPin),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.profileProtectedWithPin,
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
                  labelText: AppStrings.pin,
                  hintText: AppStrings.fourDigitPin,
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
              child: Text(AppStrings.cancel),
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
              child: Text(AppStrings.login),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _proceedWithLogin(String userId, String? pin) async {
    setState(() => _isLoading = true);

    try {
      context.read<AuthBloc>().add(
            AuthUserSelectionRequested(
              organizationId: widget.organization.id,
              userId: userId,
              pin: pin,
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
    if (Platform.isIOS) {
      final brightness = CupertinoTheme.brightnessOf(context);
      final isDark = brightness == Brightness.dark;

      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(
            AppStrings.errorTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.systemGrey2,
              fontFamily: '.SF Pro Text',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              isDefaultAction: true,
              child: Text(
                AppStrings.ok,
                style: TextStyle(
                  fontSize: 17,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontFamily: '.SF Pro Text',
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

  void _createNewProfile() {
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

  // ==================== ANDROID VIEW ====================
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
          _showError(state.errorMessage ?? AppStrings.errorOccurred);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.selectProfile),
          elevation: 0,
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
          foregroundColor: AppColors.textLight,
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              )
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
                          AppStrings.chooseYourProfile,
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
                        ? _buildEmptyStateAndroid(isDark)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: widget.membersWithData.length,
                            itemBuilder: (context, index) {
                              final data = widget.membersWithData[index];
                              final user = data['user'] as UserModel;
                              final member =
                                  data['member'] as OrganizationMemberModel;
                              return _buildUserCardAndroid(
                                  user, member, isDark);
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
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
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
                          label: Text(
                            AppStrings.createNewProfile,
                            style: const TextStyle(
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

  Widget _buildEmptyStateAndroid(bool isDark) {
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
              AppStrings.noProfilesYet,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.createFirstProfile,
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

  Widget _buildUserCardAndroid(
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

  // ==================== IOS VIEW ====================
  Widget _buildIOSView() {
    // Dark Mode Detection
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

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
            isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        navigationBar: CupertinoNavigationBar(
          backgroundColor:
              isDark ? const Color(0xFF1C1C1E).withOpacity(0.8) : null,
          middle: Text(
            AppStrings.selectProfile,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
        child: SafeArea(
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 17,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              fontFamily: '.SF Pro Text',
            ),
            child: _isLoading
                ? Center(
                    child: CupertinoActivityIndicator(
                      radius: 20,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  )
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
                                    AppColors.primary.withOpacity(0.08),
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
                                CupertinoIcons.person_2_fill,
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
                              style: TextStyle(
                                fontSize: 28,
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
                              AppStrings.chooseYourProfile,
                              style: TextStyle(
                                fontSize: 17,
                                color: CupertinoColors.systemGrey,
                                fontWeight: FontWeight.w400,
                                fontFamily: '.SF Pro Text',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      // User Liste
                      Expanded(
                        child: widget.membersWithData.isEmpty
                            ? _buildEmptyStateIOS(isDark)
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                itemCount: widget.membersWithData.length,
                                itemBuilder: (context, index) {
                                  final data = widget.membersWithData[index];
                                  final user = data['user'] as UserModel;
                                  final member =
                                      data['member'] as OrganizationMemberModel;
                                  return _buildUserCardIOS(
                                      user, member, isDark);
                                },
                              ),
                      ),

                      // Neues Profil Button
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C1C1E)
                              : CupertinoColors.white,
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? CupertinoColors.systemGrey3.darkColor
                                  : CupertinoColors.systemGrey4,
                              width: 0.5,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(12),
                              onPressed: _createNewProfile,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.add,
                                    size: 22,
                                    color: isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    AppStrings.createNewProfile,
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
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateIOS(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_add,
              size: 80,
              color: isDark
                  ? AppColors.primaryLight.withOpacity(0.5)
                  : AppColors.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.noProfilesYet,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                fontFamily: '.SF Pro Display',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.createFirstProfile,
              style: TextStyle(
                fontSize: 17,
                color: CupertinoColors.systemGrey,
                fontFamily: '.SF Pro Text',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCardIOS(
      UserModel user, OrganizationMemberModel member, bool isDark) {
    final bool isSelected = _selectedUserId == user.id;

    return GestureDetector(
      onTap: () => _handleUserSelection(user.id, member.hasPin),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.primaryLight : AppColors.primary)
                : (isDark
                    ? CupertinoColors.systemGrey3.darkColor
                    : CupertinoColors.systemGrey5),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? (isDark
                      ? AppColors.primaryLight.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.2))
                  : (isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05)),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                              ? AppColors.primaryLight.withOpacity(0.4)
                              : AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: isDark
                    ? AppColors.primaryLight.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.15),
                backgroundImage: user.profileImageUrl != null
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                          fontFamily: '.SF Pro Display',
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
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        member.hasPin
                            ? CupertinoIcons.lock_fill
                            : CupertinoIcons.lock_open_fill,
                        size: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        member.roleText,
                        style: TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.systemGrey,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron Icon
            Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: isSelected
                  ? (isDark ? AppColors.primaryLight : AppColors.primary)
                  : CupertinoColors.systemGrey,
            ),
          ],
        ),
      ),
    );
  }
}

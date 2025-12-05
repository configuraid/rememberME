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
      final isDark = Theme.of(context).brightness == Brightness.dark;

      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(
            AppStrings.enterPin,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
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
                  color: AppColors.grey,
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
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  fontFamily: '.SF Pro Text',
                ),
                placeholderStyle: TextStyle(
                  color: AppColors.grey,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.toastBackgroundDark
                      : AppColors.greyLighter,
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
                style: TextStyle(
                  fontSize: 17,
                  color: AppColors.error,
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
      final isDark = Theme.of(context).brightness == Brightness.dark;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor:
              isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.enterPin,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.profileProtectedWithPin,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _pinController,
                style: TextStyle(
                  fontSize: 17,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: AppStrings.pin,
                  hintText: AppStrings.fourDigitPin,
                  labelStyle: TextStyle(color: AppColors.grey),
                  hintStyle: TextStyle(color: AppColors.grey),
                  prefixIcon: Icon(
                    Icons.pin_outlined,
                    color: isDark ? AppColors.accent : AppColors.primary,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.toastBackgroundDark
                      : AppColors.greyLighter,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.accent : AppColors.primary,
                      width: 2,
                    ),
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
              child: Text(
                AppStrings.cancel,
                style: TextStyle(
                  fontSize: 17,
                  color: AppColors.error,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _proceedWithLogin(userId, _pinController.text);
                _pinController.clear();
              },
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? AppColors.accent : AppColors.primary,
                foregroundColor:
                    isDark ? AppColors.primary : AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                AppStrings.login,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(
            AppStrings.errorTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppBar(
          title: Text(
            AppStrings.selectProfile,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          elevation: 0,
          scrolledUnderElevation: 0.5,
          backgroundColor: isDark
              ? AppColors.backgroundDarkElevated.withOpacity(0.8)
              : AppColors.surface.withOpacity(0.94),
          foregroundColor: isDark ? AppColors.textLight : AppColors.textPrimary,
          surfaceTintColor: Colors.transparent,
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: isDark ? AppColors.accent : AppColors.primary,
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
                                ? AppColors.accent
                                : AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.people_rounded,
                            size: 48,
                            color: isDark
                                ? AppColors.background
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
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Untertitel
                        Text(
                          AppStrings.chooseYourProfile,
                          style: TextStyle(
                            fontSize: 17,
                            color: AppColors.grey,
                            fontWeight: FontWeight.w400,
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
                              return _buildUserCardAndroid(
                                  user, member, isDark);
                            },
                          ),
                  ),

                  // Neues Profil Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.backgroundDarkElevated
                          : AppColors.surface,
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.greyLight,
                          width: 0.5,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              isDark ? AppColors.shadowDark : AppColors.shadow,
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
                        child: FilledButton(
                          onPressed: _createNewProfile,
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                isDark ? AppColors.accent : AppColors.primary,
                            foregroundColor: isDark
                                ? AppColors.primary
                                : AppColors.background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 22,
                                color: isDark
                                    ? AppColors.primary
                                    : AppColors.background,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                AppStrings.createNewProfile,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.primary
                                      : AppColors.background,
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
    );
  }

  Widget _buildEmptyStateAndroid(bool isDark) {
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
                  ? AppColors.accent
                  : AppColors.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.noProfilesYet,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.createFirstProfile,
              style: TextStyle(
                fontSize: 17,
                color: AppColors.grey,
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
    final bool isSelected = _selectedUserId == user.id;

    return GestureDetector(
      onTap: () => _handleUserSelection(user.id, member.hasPin),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.primaryLight : AppColors.primary)
                : (isDark ? AppColors.borderDark : AppColors.greyLighter),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? (isDark
                      ? AppColors.primaryLight.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.2))
                  : (isDark ? AppColors.shadowDark : AppColors.shadow),
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
                    ? AppColors.accent
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
                          color:
                              isDark ? AppColors.background : AppColors.primary,
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
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        member.hasPin
                            ? Icons.lock_rounded
                            : Icons.lock_open_rounded,
                        size: 14,
                        color: AppColors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        member.roleText,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.grey,
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
                  : AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== IOS VIEW ====================
  Widget _buildIOSView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          backgroundColor: isDark
              ? AppColors.backgroundDarkElevated.withOpacity(0.8)
              : AppColors.surface.withOpacity(0.94),
          middle: Text(
            AppStrings.selectProfile,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
        child: SafeArea(
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 17,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
            child: _isLoading
                ? Center(
                    child: CupertinoActivityIndicator(
                      radius: 20,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
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
                                    ? AppColors.accent
                                    : AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CupertinoIcons.person_2_fill,
                                size: 48,
                                color: isDark
                                    ? AppColors.background
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
                                    ? AppColors.textLight
                                    : AppColors.textPrimary,
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
                                color: AppColors.grey,
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
                              ? AppColors.backgroundDarkElevated
                              : AppColors.surface,
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.greyLight,
                              width: 0.5,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? AppColors.shadowDark
                                  : AppColors.shadow,
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
                              color:
                                  isDark ? AppColors.accent : AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              onPressed: _createNewProfile,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.add,
                                    size: 22,
                                    color: isDark
                                        ? AppColors.primary
                                        : AppColors.background,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    AppStrings.createNewProfile,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.primary
                                          : AppColors.background,
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
                  ? AppColors.accent
                  : AppColors.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.noProfilesYet,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                fontFamily: '.SF Pro Display',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.createFirstProfile,
              style: TextStyle(
                fontSize: 17,
                color: AppColors.grey,
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
          color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.primaryLight : AppColors.primary)
                : (isDark ? AppColors.borderDark : AppColors.greyLighter),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? (isDark
                      ? AppColors.primaryLight.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.2))
                  : (isDark ? AppColors.shadowDark : AppColors.shadow),
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
                    ? AppColors.accent
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
                          color:
                              isDark ? AppColors.background : AppColors.primary,
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
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
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
                        color: AppColors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        member.roleText,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.grey,
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
                  : AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

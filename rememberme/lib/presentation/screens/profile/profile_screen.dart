import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/data/models/user_model.dart';
import 'package:rememberme/presentation/widgets/profile/delete_account_sheet.dart';
import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/auth/auth_event.dart';
import '../../../business_logic/auth/auth_state.dart';
import '../../../business_logic/profile/profile_bloc.dart';
import '../../../business_logic/profile/profile_event.dart';
import '../../../business_logic/profile/profile_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';
import 'edit_profile_screen.dart';
import 'about_screen.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<ProfileBloc>().add(ProfileLoadRequested(userId));
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'U';
    }

    final trimmedName = name.trim();
    final parts = trimmedName.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return trimmedName[0].toUpperCase();
  }

  void _showErrorMessage(BuildContext context, String message) {
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
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.grey,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                AppStrings.ok,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: AppColors.textLight),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: AppColors.textLight),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _handleAccountDeleted(BuildContext context) {
    // 1. Auth-State zurücksetzen
    context.read<AuthBloc>().add(const AuthLogoutRequested());

    // 2. Zum Login navigieren
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false, // Entfernt alle vorherigen Routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.isDeleted) {
          _handleAccountDeleted(context);
          return;
        }

        if (state.hasError && state.errorMessage != null) {
          _showErrorMessage(context, state.errorMessage!);
        }
      },
      builder: (context, profileState) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final user = authState.user;

            if (Platform.isIOS) {
              return _buildIOSView(context, user, profileState);
            }
            return _buildAndroidView(context, user, profileState);
          },
        );
      },
    );
  }

  // ===== iOS VIEW =====
  Widget _buildIOSView(
      BuildContext context, UserModel? user, ProfileState profileState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          AppStrings.profile,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
            fontFamily: '.SF Pro Text',
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => const EditProfileScreen(),
            ),
          ),
          child: Icon(
            CupertinoIcons.pencil,
            color: isDark ? AppColors.accent : AppColors.primary,
            size: 32,
          ),
        ),
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.8)
            : AppColors.surface.withOpacity(0.94),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async => _loadProfile(),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildIOSProfileHeader(user, profileState, isDark),
                  const SizedBox(height: 16),
                  _buildIOSMenuSection(context, user, isDark),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== ANDROID VIEW =====
  Widget _buildAndroidView(
      BuildContext context, UserModel? user, ProfileState profileState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.profile,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.8)
            : AppColors.surface.withOpacity(0.94),
        foregroundColor: isDark ? AppColors.textLight : AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditProfileScreen(),
              ),
            ),
            icon: Icon(
              Icons.edit_rounded,
              color: isDark ? AppColors.accent : AppColors.primary,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadProfile(),
        color: isDark ? AppColors.accent : AppColors.primary,
        child: ListView(
          children: [
            _buildAndroidProfileHeader(user, profileState, isDark),
            const SizedBox(height: 16),
            _buildAndroidMenuSection(context, user, isDark),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ===== ANDROID HEADER =====
  Widget _buildAndroidProfileHeader(
      UserModel? user, ProfileState profileState, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.background,
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent,
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.accent.withOpacity(0.4),
                  backgroundImage: profileState.profileImageUrl != null
                      ? NetworkImage(profileState.profileImageUrl!)
                      : null,
                  child: profileState.profileImageUrl == null
                      ? Text(
                          _getInitials(user?.displayName),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppColors.backgroundDark
                          : AppColors.background,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: isDark ? AppColors.primary : AppColors.background,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profileState.displayName ?? user?.displayName ?? AppStrings.unknown,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profileState.email ?? user?.email ?? '',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ===== iOS HEADER =====
  Widget _buildIOSProfileHeader(
      UserModel? user, ProfileState profileState, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.background,
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent,
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.accent.withOpacity(0.4),
                  backgroundImage: profileState.profileImageUrl != null
                      ? NetworkImage(profileState.profileImageUrl!)
                      : null,
                  child: profileState.profileImageUrl == null
                      ? Text(
                          _getInitials(user?.displayName),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                            fontFamily: '.SF Pro Display',
                            decoration: TextDecoration.none,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppColors.backgroundDark
                          : AppColors.background,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.camera_fill,
                    size: 16,
                    color: isDark ? AppColors.primary : AppColors.background,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profileState.displayName ?? user?.displayName ?? AppStrings.unknown,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Display',
              decoration: TextDecoration.none,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profileState.email ?? user?.email ?? '',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.grey,
              fontFamily: '.SF Pro Text',
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  // ===== iOS MENU SECTION =====
  Widget _buildIOSMenuSection(
      BuildContext context, UserModel? user, bool isDark) {
    return Column(
      children: [
        _buildIOSMenuHeader(AppStrings.accountSection, isDark),
        _buildIOSMenuCard(
          context: context,
          isDark: isDark,
          children: [
            _buildIOSMenuItem(
              icon: CupertinoIcons.person,
              title: AppStrings.editProfile,
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ),
            ),
          ],
        ),
        _buildIOSMenuHeader(AppStrings.support, isDark),
        _buildIOSMenuCard(
          context: context,
          isDark: isDark,
          children: [
            _buildIOSMenuItem(
              icon: CupertinoIcons.question_circle,
              title: AppStrings.helpAndFaq,
              isDark: isDark,
              onTap: () {},
            ),
            _buildIOSDivider(isDark),
            _buildIOSMenuItem(
              icon: CupertinoIcons.info_circle,
              title: AppStrings.about,
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              ),
            ),
            _buildIOSDivider(isDark),
            _buildIOSMenuItem(
              icon: CupertinoIcons.chat_bubble_text,
              title: AppStrings.sendFeedback,
              isDark: isDark,
              onTap: () {},
            ),
          ],
        ),
        _buildIOSMenuHeader(AppStrings.dangerZone, isDark),
        _buildIOSMenuCard(
          context: context,
          isDark: isDark,
          children: [
            _buildIOSMenuItem(
              icon: CupertinoIcons.square_arrow_right,
              title: AppStrings.logout,
              isDark: isDark,
              isDestructive: true,
              onTap: () => _showLogoutDialog(context, isDark),
            ),
            _buildIOSDivider(isDark),
            _buildIOSMenuItem(
              icon: CupertinoIcons.trash,
              title: AppStrings.deleteAccount,
              isDark: isDark,
              isDestructive: true,
              onTap: () => _showDeleteAccountDialog(context, isDark),
            ),
          ],
        ),
      ],
    );
  }

  // ===== iOS MENU HEADER =====
  Widget _buildIOSMenuHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.grey,
            letterSpacing: 0.5,
            fontFamily: '.SF Pro Text',
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  // ===== iOS MENU ITEM =====
  Widget _buildIOSMenuItem({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final iconColor = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.accent : AppColors.primary);
    final textColor = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.textLight : AppColors.textPrimary);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.error.withOpacity(isDark ? 0.2 : 0.1)
                    : (isDark
                        ? AppColors.toastBackgroundDark
                        : AppColors.primary.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                  fontFamily: '.SF Pro Text',
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSMenuCard({
    required BuildContext context,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLighter,
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildIOSDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Divider(
        height: 1,
        color: isDark ? AppColors.borderDark : AppColors.divider,
      ),
    );
  }

  // ===== ANDROID MENU SECTION =====
  Widget _buildAndroidMenuSection(
      BuildContext context, UserModel? user, bool isDark) {
    return Column(
      children: [
        _buildAndroidMenuHeader(AppStrings.accountSection, isDark),
        _buildAndroidMenuCard(
          context: context,
          isDark: isDark,
          children: [
            _buildAndroidMenuItem(
              context: context,
              icon: Icons.person_rounded,
              title: AppStrings.editProfile,
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ),
            ),
          ],
        ),
        _buildAndroidMenuHeader(AppStrings.support, isDark),
        _buildAndroidMenuCard(
          context: context,
          isDark: isDark,
          children: [
            _buildAndroidMenuItem(
              context: context,
              icon: Icons.help_outline_rounded,
              title: AppStrings.helpAndFaq,
              isDark: isDark,
              onTap: () {},
            ),
            _buildAndroidDivider(isDark),
            _buildAndroidMenuItem(
              context: context,
              icon: Icons.info_outline_rounded,
              title: AppStrings.about,
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              ),
            ),
            _buildAndroidDivider(isDark),
            _buildAndroidMenuItem(
              context: context,
              icon: Icons.feedback_outlined,
              title: AppStrings.sendFeedback,
              isDark: isDark,
              onTap: () {},
            ),
          ],
        ),
        _buildAndroidMenuHeader(AppStrings.dangerZone, isDark),
        _buildAndroidMenuCard(
          context: context,
          isDark: isDark,
          children: [
            _buildAndroidMenuItem(
              context: context,
              icon: Icons.logout_rounded,
              title: AppStrings.logout,
              isDark: isDark,
              isDestructive: true,
              onTap: () => _showLogoutDialog(context, isDark),
            ),
            _buildAndroidDivider(isDark),
            _buildAndroidMenuItem(
              context: context,
              icon: Icons.delete_forever_rounded,
              title: AppStrings.deleteAccount,
              isDark: isDark,
              isDestructive: true,
              onTap: () => _showDeleteAccountDialog(context, isDark),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAndroidMenuHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.grey,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildAndroidMenuCard({
    required BuildContext context,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLighter,
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildAndroidDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Divider(
        height: 1,
        color: isDark ? AppColors.borderDark : AppColors.divider,
      ),
    );
  }

  Widget _buildAndroidMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final iconColor = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.accent : AppColors.primary);

    final textColor = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.textLight : AppColors.textPrimary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: iconColor.withOpacity(0.1),
        highlightColor: iconColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? AppColors.error.withOpacity(isDark ? 0.2 : 0.1)
                      : (isDark
                          ? AppColors.toastBackgroundDark
                          : AppColors.primary.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== LOGOUT DIALOG =====
  void _showLogoutDialog(BuildContext context, bool isDark) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(
            AppStrings.logout,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Text(
            AppStrings.logoutConfirmMessage,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey,
              fontFamily: '.SF Pro Text',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                AppStrings.cancel,
                style: TextStyle(
                  fontSize: 17,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
                Navigator.of(ctx).pop();
                Navigator.of(context, rootNavigator: true)
                    .pushReplacementNamed(AppRoutes.login);
              },
              child: Text(
                AppStrings.logout,
                style: const TextStyle(
                  fontSize: 17,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor:
              isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.toastBackgroundDark
                  : AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.logout_rounded,
              size: 24,
              color: isDark ? AppColors.accent : AppColors.primary,
            ),
          ),
          title: Text(
            AppStrings.logout,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          content: Text(
            AppStrings.logoutConfirmMessage,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.grey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                AppStrings.cancel,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.grey,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
                Navigator.of(ctx).pop();
                Navigator.of(context, rootNavigator: true)
                    .pushReplacementNamed(AppRoutes.login);
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
                AppStrings.logout,
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

  // ===== DELETE ACCOUNT DIALOG =====
  void _showDeleteAccountDialog(BuildContext context, bool isDark) {
    if (Platform.isIOS) {
      // iOS: Schönes Bottom Sheet
      DeleteAccountConfirmationFlow.show(
        context,
        isDark: isDark,
        userId: context.read<AuthBloc>().state.user?.id,
        onDeleteAccount: (userId) {
          // Nur Event dispatchen - Navigation erfolgt im BlocConsumer listener!
          context.read<ProfileBloc>().add(
                ProfileDeleteAccountRequested(userId: userId, password: ''),
              );
        },
      );
    } else {
      // Android: Standard Dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor:
              isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_rounded,
              size: 24,
              color: isDark ? AppColors.errorLight : AppColors.error,
            ),
          ),
          title: Text(
            AppStrings.deleteAccount,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          content: Text(
            AppStrings.deleteAccountWarning,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.grey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                AppStrings.cancel,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.grey,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                final userId = context.read<AuthBloc>().state.user?.id;
                if (userId != null) {
                  context.read<ProfileBloc>().add(
                        ProfileDeleteAccountRequested(
                          userId: userId,
                          password: '',
                        ),
                      );
                }
                Navigator.of(ctx).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.errorLight : AppColors.error,
                foregroundColor: AppColors.textLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                AppStrings.deleteAccount,
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
}

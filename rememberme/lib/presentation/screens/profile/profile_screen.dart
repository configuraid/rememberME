import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/data/models/auth/user_model.dart';
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

  // ============================================================
  // NEU: Navigation nach Account-Löschung
  // ============================================================
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
        // ============================================================
        // NEU: Auf deleted Status reagieren
        // ============================================================
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
            fontSize: 17,
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
          ),
        ),
        backgroundColor:
            isDark ? AppColors.backgroundDarkElevated.withOpacity(0.8) : null,
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
      backgroundColor:
          isDark ? AppColors.backgroundDarkSecondary : AppColors.background,
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
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primaryDark,
                  AppColors.primary,
                ]
              : [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowDark : AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.textLight.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.surface,
                    backgroundImage: profileState.profileImageUrl != null
                        ? NetworkImage(profileState.profileImageUrl!)
                        : null,
                    child: profileState.profileImageUrl == null
                        ? Text(
                            _getInitials(user?.name),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.primaryLight
                                  : AppColors.primary,
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
                      color: isDark ? AppColors.accentLight : AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surface,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 18,
                      color:
                          isDark ? AppColors.primaryDark : AppColors.textLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              profileState.name ?? user?.name ?? AppStrings.unknown,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
                letterSpacing: 0.15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profileState.email ?? user?.email ?? '',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight.withOpacity(0.9),
              ),
            ),
            if (profileState.bio != null && profileState.bio!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  profileState.bio!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight.withOpacity(0.9),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
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
                          _getInitials(user?.name),
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
                    color: isDark ? AppColors.accentLight : AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.accentLight : AppColors.accent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.camera_fill,
                    size: 16,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profileState.name ?? user?.name ?? AppStrings.unknown,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Display',
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profileState.email ?? user?.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textLight.withOpacity(0.8)
                  : AppColors.textSecondary,
              fontFamily: '.SF Pro Text',
              decoration: TextDecoration.none,
            ),
          ),
          if (profileState.bio != null && profileState.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark.withOpacity(0.5)
                    : AppColors.greyLighter,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                profileState.bio!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textLight.withOpacity(0.9)
                      : AppColors.textSecondary,
                  height: 1.4,
                  fontFamily: '.SF Pro Text',
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
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
        : (isDark ? AppColors.textLight : AppColors.textPrimary);
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
                color: iconColor.withOpacity(isDark ? 0.2 : 0.1),
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
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.greyLighter,
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
        color: isDark ? AppColors.borderDarkSubtle : AppColors.divider,
      ),
    );
  }

  // ===== ANDROID MENU SECTION =====
  Widget _buildAndroidMenuSection(
      BuildContext context, UserModel? user, bool isDark) {
    return Column(
      children: [
        _buildAndroidMenuHeader(AppStrings.accountSection, isDark),
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
        Divider(
          height: 1,
          color: isDark ? AppColors.borderDark : AppColors.divider,
        ),
        _buildAndroidMenuHeader(AppStrings.support, isDark),
        _buildAndroidMenuItem(
          context: context,
          icon: Icons.help_outline_rounded,
          title: AppStrings.helpAndFaq,
          isDark: isDark,
          onTap: () {},
        ),
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
        _buildAndroidMenuItem(
          context: context,
          icon: Icons.feedback_outlined,
          title: AppStrings.sendFeedback,
          isDark: isDark,
          onTap: () {},
        ),
        Divider(
          height: 1,
          color: isDark ? AppColors.borderDark : AppColors.divider,
        ),
        _buildAndroidMenuHeader(AppStrings.dangerZone, isDark),
        _buildAndroidMenuItem(
          context: context,
          icon: Icons.logout_rounded,
          title: AppStrings.logout,
          isDark: isDark,
          isDestructive: true,
          onTap: () => _showLogoutDialog(context, isDark),
        ),
        _buildAndroidMenuItem(
          context: context,
          icon: Icons.delete_forever_rounded,
          title: AppStrings.deleteAccount,
          isDark: isDark,
          isDestructive: true,
          onTap: () => _showDeleteAccountDialog(context, isDark),
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.grey : AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
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
        ? (isDark ? AppColors.errorLight : AppColors.error)
        : (isDark ? AppColors.accentLight : AppColors.primary);

    final textColor = isDestructive
        ? (isDark ? AppColors.errorLight : AppColors.error)
        : (isDark ? AppColors.textLight : AppColors.textPrimary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: iconColor.withOpacity(0.1),
        highlightColor: iconColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    letterSpacing: 0.15,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? AppColors.grey : AppColors.textSecondary,
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
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          icon: Icon(
            Icons.logout_rounded,
            size: 32,
            color: isDark ? AppColors.accentLight : AppColors.primary,
          ),
          title: Text(
            AppStrings.logout,
            style: TextStyle(
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          content: Text(
            AppStrings.logoutConfirmMessage,
            style: TextStyle(
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                AppStrings.cancel,
                style: TextStyle(
                  color: isDark ? AppColors.grey : AppColors.textSecondary,
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
                backgroundColor:
                    isDark ? AppColors.accentLight : AppColors.primary,
                foregroundColor:
                    isDark ? AppColors.primaryDark : AppColors.textLight,
              ),
              child: const Text(AppStrings.logout),
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
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          icon: Icon(
            Icons.warning_rounded,
            size: 32,
            color: isDark ? AppColors.errorLight : AppColors.error,
          ),
          title: Text(
            AppStrings.deleteAccount,
            style: TextStyle(
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          content: Text(
            AppStrings.deleteAccountWarning,
            style: TextStyle(
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                AppStrings.cancel,
                style: TextStyle(
                  color: isDark ? AppColors.grey : AppColors.textSecondary,
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
                foregroundColor:
                    isDark ? AppColors.errorDark : AppColors.textLight,
              ),
              child: Text(AppStrings.deleteAccount),
            ),
          ],
        ),
      );
    }
  }
}

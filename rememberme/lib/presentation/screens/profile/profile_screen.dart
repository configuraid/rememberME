import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/data/models/auth/user_model.dart';
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

    if (Platform.isAndroid) {
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
    } else {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Icon(
            Icons.error,
            color: AppColors.error,
            size: 48,
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                AppStrings.ok,
                style: TextStyle(color: AppColors.interactive),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.isSuccess && state.successMessage != null) {}

        if (state.hasError && state.errorMessage != null) {
          _showErrorMessage(context, state.errorMessage!);
        }
      },
      builder: (context, profileState) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final user = authState.user;

            return Scaffold(
              backgroundColor: isDark
                  ? AppColors.backgroundDarkSecondary
                  : AppColors.background,
              appBar: AppBar(
                title: const Text(AppStrings.profile),
                backgroundColor:
                    isDark ? AppColors.surfaceDark : AppColors.primary,
                foregroundColor: AppColors.textLight,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: () async => _loadProfile(),
                color: isDark ? AppColors.accent : AppColors.primary,
                child: ListView(
                  children: [
                    if (Platform.isAndroid)
                      _buildAndroidProfileHeader(user, profileState, isDark)
                    else
                      _buildIOSProfileHeader(user, profileState, isDark),
                    const SizedBox(height: 16),
                    _buildMenuSection(context, user, isDark),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          },
        );
      },
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
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
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
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.accentLight : AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: isDark ? AppColors.primaryDark : AppColors.textLight,
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
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profileState.email ?? user?.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight.withOpacity(0.7),
            ),
          ),
          if (profileState.bio != null && profileState.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profileState.bio!,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, UserModel? user, bool isDark) {
    return Column(
      children: [
        _buildMenuHeader(AppStrings.accountSection, isDark),
        if (Platform.isAndroid)
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
          )
        else
          _buildIOSMenuItem(
            icon: Icons.person,
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
        Divider(
          height: 1,
          color: isDark ? AppColors.borderDark : AppColors.divider,
        ),
        _buildMenuHeader(AppStrings.support, isDark),
        if (Platform.isAndroid) ...[
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
        ] else ...[
          _buildIOSMenuItem(
            icon: Icons.help_outline,
            title: AppStrings.helpAndFaq,
            isDark: isDark,
            onTap: () {},
          ),
          _buildIOSMenuItem(
            icon: Icons.info_outline,
            title: AppStrings.about,
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AboutScreen(),
              ),
            ),
          ),
          _buildIOSMenuItem(
            icon: Icons.feedback_outlined,
            title: AppStrings.sendFeedback,
            isDark: isDark,
            onTap: () {},
          ),
        ],
        Divider(
          height: 1,
          color: isDark ? AppColors.borderDark : AppColors.divider,
        ),
        _buildMenuHeader(AppStrings.dangerZone, isDark),
        if (Platform.isAndroid) ...[
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
        ] else ...[
          _buildIOSMenuItem(
            icon: Icons.logout,
            title: AppStrings.logout,
            isDark: isDark,
            textColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () => _showLogoutDialog(context, isDark),
          ),
          _buildIOSMenuItem(
            icon: Icons.delete_forever,
            title: AppStrings.deleteAccount,
            isDark: isDark,
            textColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () => _showDeleteAccountDialog(context, isDark),
          ),
        ],
      ],
    );
  }

  Widget _buildMenuHeader(String title, bool isDark) {
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

  // ===== ANDROID MENU ITEM =====
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

  // ===== iOS MENU ITEM =====
  Widget _buildIOSMenuItem({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
  }) {
    final defaultIconColor =
        iconColor ?? (isDark ? AppColors.accent : AppColors.interactive);
    final defaultTextColor =
        textColor ?? (isDark ? AppColors.textLight : AppColors.textPrimary);

    return ListTile(
      leading: Icon(icon, color: defaultIconColor),
      title: Text(
        title,
        style: TextStyle(color: defaultTextColor),
      ),
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isDark ? AppColors.grey : AppColors.textSecondary,
          ),
      onTap: onTap,
    );
  }

  // ===== LOGOUT DIALOG =====
  void _showLogoutDialog(BuildContext context, bool isDark) {
    if (Platform.isAndroid) {
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
    } else {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
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
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                AppStrings.cancel,
                style: TextStyle(color: AppColors.interactive),
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
              child: const Text(AppStrings.logout),
            ),
          ],
        ),
      );
    }
  }

  // ===== DELETE ACCOUNT DIALOG =====
  void _showDeleteAccountDialog(BuildContext context, bool isDark) {
    final passwordController = TextEditingController();

    if (Platform.isAndroid) {
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.deleteAccountWarning,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                style: TextStyle(
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: AppStrings.passwordConfirmation,
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: Icon(
                    Icons.lock_rounded,
                    color: isDark ? AppColors.accent : AppColors.primary,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? AppColors.accent : AppColors.primary,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
            ],
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
                          password: passwordController.text,
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
    } else {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(
            AppStrings.deleteAccount,
            style: TextStyle(
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                AppStrings.deleteAccountWarning,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: passwordController,
                placeholder: AppStrings.passwordConfirmation,
                placeholderStyle: TextStyle(color: AppColors.textSecondary),
                style: TextStyle(
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                ),
                obscureText: true,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                AppStrings.cancel,
                style: TextStyle(color: AppColors.interactive),
              ),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                final userId = context.read<AuthBloc>().state.user?.id;
                if (userId != null) {
                  context.read<ProfileBloc>().add(
                        ProfileDeleteAccountRequested(
                          userId: userId,
                          password: passwordController.text,
                        ),
                      );
                }
                Navigator.of(ctx).pop();
              },
              child: Text(AppStrings.deleteAccount),
            ),
          ],
        ),
      );
    }
  }
}

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
import 'notifications_settings_screen.dart';
import 'privacy_settings_screen.dart';
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

  void _showSuccessMessage(BuildContext context, String message) {
    if (Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
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
            Icons.check_circle,
            color: AppColors.success,
            size: 48,
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    }
  }

  void _showErrorMessage(BuildContext context, String message) {
    if (Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: const Color(0xFFE53935),
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
              child: const Text('OK'),
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
        if (state.isSuccess && state.successMessage != null) {
          _showSuccessMessage(context, state.successMessage!);
        }

        if (state.hasError && state.errorMessage != null) {
          _showErrorMessage(context, state.errorMessage!);
        }
      },
      builder: (context, profileState) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final user = authState.user;

            return Scaffold(
              appBar: AppBar(
                title: const Text(AppStrings.profile),
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
                child: ListView(
                  children: [
                    if (Platform.isAndroid)
                      _buildAndroidProfileHeader(user, profileState, isDark)
                    else
                      _buildIOSProfileHeader(user, profileState),
                    const SizedBox(height: 16),
                    _buildMenuSection(context, user, isDark),
                    const SizedBox(height: 80), // Navigation Bar Padding
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
                  const Color(0xFF004494),
                  const Color(0xFF0061A4),
                ]
              : [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
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
                      color: Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
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
                                  ? const Color(0xFF004494)
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
                      color:
                          isDark ? const Color(0xFFAAC7FF) : AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 18,
                      color: isDark ? const Color(0xFF003062) : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              profileState.name ?? user?.name ?? 'Unbekannt',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profileState.email ?? user?.email ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  profileState.bio!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
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
  Widget _buildIOSProfileHeader(UserModel? user, ProfileState profileState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
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
                backgroundColor: Colors.white,
                backgroundImage: profileState.profileImageUrl != null
                    ? NetworkImage(profileState.profileImageUrl!)
                    : null,
                child: profileState.profileImageUrl == null
                    ? Text(
                        _getInitials(user?.name),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profileState.name ?? user?.name ?? 'Unbekannt',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profileState.email ?? user?.email ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          if (profileState.bio != null && profileState.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profileState.bio!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
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
        _buildMenuHeader('Account', isDark),
        if (Platform.isAndroid)
          _buildAndroidMenuItem(
            context: context,
            icon: Icons.person_rounded,
            title: 'Profil bearbeiten',
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
            title: 'Profil bearbeiten',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditProfileScreen(),
              ),
            ),
          ),
        Divider(
          height: 1,
          color: isDark ? const Color(0xFF49454F) : const Color(0xFFCAC4D0),
        ),
        _buildMenuHeader('Einstellungen', isDark),
        if (Platform.isAndroid) ...[
          _buildAndroidMenuItem(
            context: context,
            icon: Icons.notifications_rounded,
            title: AppStrings.notifications,
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsSettingsScreen(),
              ),
            ),
          ),
          _buildAndroidMenuItem(
            context: context,
            icon: Icons.lock_rounded,
            title: AppStrings.privacy,
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrivacySettingsScreen(),
              ),
            ),
          ),
        ] else ...[
          _buildIOSMenuItem(
            icon: Icons.notifications,
            title: AppStrings.notifications,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsSettingsScreen(),
              ),
            ),
          ),
          _buildIOSMenuItem(
            icon: Icons.lock,
            title: AppStrings.privacy,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrivacySettingsScreen(),
              ),
            ),
          ),
        ],
        Divider(
          height: 1,
          color: isDark ? const Color(0xFF49454F) : const Color(0xFFCAC4D0),
        ),
        _buildMenuHeader('Support', isDark),
        if (Platform.isAndroid) ...[
          _buildAndroidMenuItem(
            context: context,
            icon: Icons.help_outline_rounded,
            title: 'Hilfe & FAQ',
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
            title: 'Feedback senden',
            isDark: isDark,
            onTap: () {},
          ),
        ] else ...[
          _buildIOSMenuItem(
            icon: Icons.help_outline,
            title: 'Hilfe & FAQ',
            onTap: () {},
          ),
          _buildIOSMenuItem(
            icon: Icons.info_outline,
            title: AppStrings.about,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AboutScreen(),
              ),
            ),
          ),
          _buildIOSMenuItem(
            icon: Icons.feedback_outlined,
            title: 'Feedback senden',
            onTap: () {},
          ),
        ],
        Divider(
          height: 1,
          color: isDark ? const Color(0xFF49454F) : const Color(0xFFCAC4D0),
        ),
        _buildMenuHeader('Gefahrenzone', isDark),
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
            title: 'Account löschen',
            isDark: isDark,
            isDestructive: true,
            onTap: () => _showDeleteAccountDialog(context, isDark),
          ),
        ] else ...[
          _buildIOSMenuItem(
            icon: Icons.logout,
            title: AppStrings.logout,
            textColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () => _showLogoutDialog(context, false),
          ),
          _buildIOSMenuItem(
            icon: Icons.delete_forever,
            title: 'Account löschen',
            textColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () => _showDeleteAccountDialog(context, false),
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
            color: isDark ? const Color(0xFF938F94) : const Color(0xFF79747E),
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
    final theme = Theme.of(context);
    final iconColor = isDestructive
        ? (isDark ? const Color(0xFFFFB4AB) : const Color(0xFFE53935))
        : (isDark ? const Color(0xFFAAC7FF) : AppColors.primary);

    final textColor = isDestructive
        ? (isDark ? const Color(0xFFFFB4AB) : const Color(0xFFE53935))
        : (isDark ? const Color(0xFFE6E1E5) : const Color(0xFF1C1B1F));

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
                color:
                    isDark ? const Color(0xFF938F94) : const Color(0xFF79747E),
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
    required VoidCallback onTap,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // ===== LOGOUT DIALOG =====
  void _showLogoutDialog(BuildContext context, bool isDark) {
    if (Platform.isAndroid) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(
            Icons.logout_rounded,
            size: 32,
            color: isDark ? const Color(0xFFAAC7FF) : AppColors.primary,
          ),
          title: const Text(AppStrings.logout),
          content: const Text('Möchten Sie sich wirklich abmelden?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(AppStrings.cancel),
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
                    isDark ? const Color(0xFFAAC7FF) : AppColors.primary,
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
          title: const Text(AppStrings.logout),
          content: const Text('Möchten Sie sich wirklich abmelden?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(AppStrings.cancel),
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
          icon: Icon(
            Icons.warning_rounded,
            size: 32,
            color: isDark ? const Color(0xFFFFB4AB) : const Color(0xFFE53935),
          ),
          title: const Text('Account löschen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dieser Vorgang kann nicht rückgängig gemacht werden. Alle Ihre Daten werden dauerhaft gelöscht.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Passwort zur Bestätigung',
                  prefixIcon: Icon(Icons.lock_rounded),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(AppStrings.cancel),
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
                    isDark ? const Color(0xFFFFB4AB) : const Color(0xFFE53935),
                foregroundColor:
                    isDark ? const Color(0xFF690005) : Colors.white,
              ),
              child: const Text('Account löschen'),
            ),
          ],
        ),
      );
    } else {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Account löschen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Dieser Vorgang kann nicht rückgängig gemacht werden. Alle Ihre Daten werden dauerhaft gelöscht.',
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: passwordController,
                placeholder: 'Passwort zur Bestätigung',
                obscureText: true,
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(AppStrings.cancel),
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
              child: const Text('Account löschen'),
            ),
          ],
        ),
      );
    }
  }
}

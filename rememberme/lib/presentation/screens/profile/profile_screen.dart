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
import 'statistics_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    // ✅ BlocConsumer mit CupertinoAlertDialog
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.isSuccess && state.successMessage != null) {
          // ✅ Cupertino Dialog statt SnackBar
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
                child: Text(state.successMessage!),
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

        if (state.hasError && state.errorMessage != null) {
          // ✅ Cupertino Dialog für Fehler
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
                child: Text(state.errorMessage!),
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
                    icon: const Icon(Icons.edit),
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
                    _buildProfileHeader(user, profileState),
                    const SizedBox(height: 16),
                    _buildMenuSection(context, user),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileHeader(UserModel? user, ProfileState profileState) {
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

  Widget _buildMenuSection(BuildContext context, UserModel? user) {
    return Column(
      children: [
        _buildMenuHeader('Account'),
        _buildMenuItem(
          icon: Icons.person,
          title: 'Profil bearbeiten',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditProfileScreen(),
            ),
          ),
        ),
        const Divider(height: 1),
        _buildMenuHeader('Einstellungen'),
        _buildMenuItem(
          icon: Icons.notifications,
          title: AppStrings.notifications,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsSettingsScreen(),
            ),
          ),
        ),
        _buildMenuItem(
          icon: Icons.lock,
          title: AppStrings.privacy,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PrivacySettingsScreen(),
            ),
          ),
        ),
        const Divider(height: 1),
        _buildMenuHeader('Support'),
        _buildMenuItem(
          icon: Icons.help_outline,
          title: 'Hilfe & FAQ',
          onTap: () {},
        ),
        _buildMenuItem(
          icon: Icons.info_outline,
          title: AppStrings.about,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AboutScreen(),
            ),
          ),
        ),
        _buildMenuItem(
          icon: Icons.feedback_outlined,
          title: 'Feedback senden',
          onTap: () {},
        ),
        const Divider(height: 1),
        _buildMenuHeader('Gefahrenzone'),
        _buildMenuItem(
          icon: Icons.logout,
          title: AppStrings.logout,
          textColor: AppColors.error,
          iconColor: AppColors.error,
          onTap: () => _showLogoutDialog(context),
        ),
        _buildMenuItem(
          icon: Icons.delete_forever,
          title: 'Account löschen',
          textColor: AppColors.error,
          iconColor: AppColors.error,
          onTap: () => _showDeleteAccountDialog(context),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMenuHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
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

  void _showLogoutDialog(BuildContext context) {
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

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();

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

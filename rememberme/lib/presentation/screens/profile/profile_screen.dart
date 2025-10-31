import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/data/models/user_model.dart';
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
import 'settings_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.isSuccess && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
            ),
          );
        }
        if (state.hasError && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
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
                    // Profil Header
                    _buildProfileHeader(user, profileState),

                    const SizedBox(height: 16),

                    // Statistiken
                    if (profileState.statistics != null)
                      _buildStatisticsSection(profileState.statistics!),

                    const SizedBox(height: 8),

                    // Menu Items
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
                        user?.name.substring(0, 1).toUpperCase() ?? 'U',
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
            profileState.name ?? user?.name ?? '',
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

  Widget _buildStatisticsSection(ProfileStatistics stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StatisticsScreen(),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Statistiken',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Gedenkseiten',
                        '${stats.totalMemorials}',
                        Icons.favorite,
                        AppColors.accent,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Besucher',
                        '${stats.totalViews}',
                        Icons.visibility,
                        AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Beileidsbekundungen',
                        '${stats.totalCondolences}',
                        Icons.message,
                        AppColors.success,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Gruppen',
                        '${stats.groupMemberships}',
                        Icons.group,
                        AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
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
        _buildMenuItem(
          icon: Icons.workspace_premium,
          title: AppStrings.license,
          trailing: _buildPremiumBadge(),
          onTap: () => Navigator.of(context, rootNavigator: true)
              .pushNamed(AppRoutes.license),
        ),
        _buildMenuItem(
          icon: Icons.security,
          title: 'Passwort ändern',
          onTap: () => _showChangePasswordDialog(context),
        ),
        const Divider(height: 1),
        _buildMenuHeader('Einstellungen'),
        _buildMenuItem(
          icon: Icons.settings,
          title: AppStrings.settings,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsScreen(),
            ),
          ),
        ),
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

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text('Möchten Sie sich wirklich abmelden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              Navigator.of(ctx).pop();
              Navigator.of(context, rootNavigator: true)
                  .pushReplacementNamed(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Passwort ändern'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Aktuelles Passwort',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'Neues Passwort',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Passwort bestätigen',
                border: OutlineInputBorder(),
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
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text ==
                  confirmPasswordController.text) {
                final userId = context.read<AuthBloc>().state.user?.id;
                if (userId != null) {
                  context.read<ProfileBloc>().add(
                        ProfilePasswordChangeRequested(
                          userId: userId,
                          currentPassword: currentPasswordController.text,
                          newPassword: newPasswordController.text,
                        ),
                      );
                }
                Navigator.of(ctx).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwörter stimmen nicht überein'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Ändern'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Account löschen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Dieser Vorgang kann nicht rückgängig gemacht werden. Alle Ihre Daten werden dauerhaft gelöscht.',
              style: TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Passwort zur Bestätigung',
                border: OutlineInputBorder(),
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
          ElevatedButton(
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Account löschen'),
          ),
        ],
      ),
    );
  }
}

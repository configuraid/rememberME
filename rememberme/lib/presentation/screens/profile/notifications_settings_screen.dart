import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/profile/profile_bloc.dart';
import '../../../business_logic/profile/profile_event.dart';
import '../../../business_logic/profile/profile_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : null,
      appBar: AppBar(
        title: const Text(AppStrings.notifications),
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              // Push-Benachrichtigungen Section
              _buildSectionHeader(AppStrings.pushNotifications, isDark),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSettingCard(
                  isDark: isDark,
                  children: [
                    _buildSwitchTile(
                      context: context,
                      icon: Icons.notifications_active_rounded,
                      title: AppStrings.pushNotifications,
                      subtitle: AppStrings.pushNotificationsSubtitle,
                      value: state.settings.pushNotifications,
                      isDark: isDark,
                      onChanged: (value) => _updateNotifications(
                        context,
                        pushEnabled: value,
                        emailEnabled: state.settings.emailNotifications,
                        memorialUpdates: state.settings.memorialUpdates,
                        groupInvites: state.settings.groupInvites,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // E-Mail-Benachrichtigungen Section
              _buildSectionHeader(AppStrings.emailNotifications, isDark),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSettingCard(
                  isDark: isDark,
                  children: [
                    _buildSwitchTile(
                      context: context,
                      icon: Icons.email_rounded,
                      title: AppStrings.emailNotifications,
                      subtitle: AppStrings.emailNotificationsSubtitle,
                      value: state.settings.emailNotifications,
                      isDark: isDark,
                      onChanged: (value) => _updateNotifications(
                        context,
                        pushEnabled: state.settings.pushNotifications,
                        emailEnabled: value,
                        memorialUpdates: state.settings.memorialUpdates,
                        groupInvites: state.settings.groupInvites,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Benachrichtigungstypen Section
              _buildSectionHeader(AppStrings.notificationTypes, isDark),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSettingCard(
                  isDark: isDark,
                  children: [
                    _buildSwitchTile(
                      context: context,
                      icon: Icons.favorite_rounded,
                      title: AppStrings.memorialUpdates,
                      subtitle: AppStrings.memorialUpdatesSubtitle,
                      value: state.settings.memorialUpdates,
                      isDark: isDark,
                      onChanged: (value) => _updateNotifications(
                        context,
                        pushEnabled: state.settings.pushNotifications,
                        emailEnabled: state.settings.emailNotifications,
                        memorialUpdates: value,
                        groupInvites: state.settings.groupInvites,
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 84,
                      endIndent: 20,
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey.shade200,
                    ),
                    _buildSwitchTile(
                      context: context,
                      icon: Icons.group_add_rounded,
                      title: AppStrings.groupInvites,
                      subtitle: AppStrings.groupInvitesSubtitle,
                      value: state.settings.groupInvites,
                      isDark: isDark,
                      onChanged: (value) => _updateNotifications(
                        context,
                        pushEnabled: state.settings.pushNotifications,
                        emailEnabled: state.settings.emailNotifications,
                        memorialUpdates: state.settings.memorialUpdates,
                        groupInvites: value,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Nicht stören Section
              _buildSectionHeader(AppStrings.doNotDisturb, isDark),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSettingCard(
                  isDark: isDark,
                  children: [
                    _buildSwitchTile(
                      context: context,
                      icon: Icons.bedtime_rounded,
                      title: AppStrings.quietHours,
                      subtitle: AppStrings.quietHoursSubtitle,
                      value: false,
                      isDark: isDark,
                      onChanged: (value) {
                        // TODO: Implementieren
                      },
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 84,
                      endIndent: 20,
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey.shade200,
                    ),
                    _buildActionTile(
                      context: context,
                      icon: Icons.schedule_rounded,
                      title: AppStrings.schedule,
                      subtitle: AppStrings.scheduleTime,
                      isDark: isDark,
                      onTap: () {
                        // TODO: Zeitplan-Picker öffnen
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFF808080) : Colors.grey.shade600,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.primaryLight.withOpacity(0.25),
                        AppColors.primaryLight.withOpacity(0.15),
                      ]
                    : [
                        AppColors.primary.withOpacity(0.15),
                        AppColors.primary.withOpacity(0.08),
                      ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? AppColors.primaryLight.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? AppColors.primaryLight.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    letterSpacing: 0.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? const Color(0xFFA0A0A0)
                        : AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Custom Switch
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: isDark ? AppColors.primaryLight : AppColors.primary,
              activeTrackColor: isDark
                  ? AppColors.primaryLight.withOpacity(0.5)
                  : AppColors.primary.withOpacity(0.5),
              inactiveThumbColor:
                  isDark ? const Color(0xFF404040) : Colors.grey.shade400,
              inactiveTrackColor:
                  isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: isDark
            ? AppColors.primaryLight.withOpacity(0.1)
            : AppColors.primary.withOpacity(0.08),
        highlightColor: isDark
            ? AppColors.primaryLight.withOpacity(0.05)
            : AppColors.primary.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppColors.primaryLight.withOpacity(0.25),
                            AppColors.primaryLight.withOpacity(0.15),
                          ]
                        : [
                            AppColors.primary.withOpacity(0.15),
                            AppColors.primary.withOpacity(0.08),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.primaryLight.withOpacity(0.3)
                        : AppColors.primary.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? AppColors.primaryLight.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                        letterSpacing: 0.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? const Color(0xFFA0A0A0)
                            : AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Arrow Icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color:
                      isDark ? const Color(0xFF909090) : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateNotifications(
    BuildContext context, {
    required bool pushEnabled,
    required bool emailEnabled,
    required bool memorialUpdates,
    required bool groupInvites,
  }) {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<ProfileBloc>().add(
            ProfileNotificationsUpdateRequested(
              userId: userId,
              pushEnabled: pushEnabled,
              emailEnabled: emailEnabled,
              memorialUpdates: memorialUpdates,
              groupInvites: groupInvites,
            ),
          );
    }
  }
}

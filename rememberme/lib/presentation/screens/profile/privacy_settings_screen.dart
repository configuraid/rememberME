import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/profile/profile_bloc.dart';
import '../../../business_logic/profile/profile_event.dart';
import '../../../business_logic/profile/profile_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : null,
      appBar: AppBar(
        title: const Text(AppStrings.privacyAndSecurity),
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              // Profil-Sichtbarkeit Section
              _buildSectionHeader(AppStrings.profileVisibility, isDark),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSettingCard(
                  isDark: isDark,
                  children: [
                    _buildSwitchTile(
                      context: context,
                      icon: Icons.public_rounded,
                      title: AppStrings.publicProfile,
                      subtitle: AppStrings.publicProfileSubtitle,
                      value: state.settings.profilePublic,
                      isDark: isDark,
                      onChanged: (value) => _updatePrivacy(
                        context,
                        profilePublic: value,
                        showEmail: state.settings.showEmail,
                        allowSearchEngines: state.settings.allowSearchEngines,
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
                      icon: Icons.email_rounded,
                      title: AppStrings.showEmailAddress,
                      subtitle: AppStrings.showEmailSubtitle,
                      value: state.settings.showEmail,
                      isDark: isDark,
                      onChanged: (value) => _updatePrivacy(
                        context,
                        profilePublic: state.settings.profilePublic,
                        showEmail: value,
                        allowSearchEngines: state.settings.allowSearchEngines,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Suchmaschinen Section
              _buildSectionHeader(AppStrings.searchEngines, isDark),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSettingCard(
                  isDark: isDark,
                  children: [
                    _buildSwitchTile(
                      context: context,
                      icon: Icons.search_rounded,
                      title: AppStrings.searchableInEngines,
                      subtitle: AppStrings.searchableSubtitle,
                      value: state.settings.allowSearchEngines,
                      isDark: isDark,
                      onChanged: (value) => _updatePrivacy(
                        context,
                        profilePublic: state.settings.profilePublic,
                        showEmail: state.settings.showEmail,
                        allowSearchEngines: value,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Daten & Downloads Section
              _buildSectionHeader(AppStrings.dataAndDownloads, isDark),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSettingCard(
                  isDark: isDark,
                  children: [
                    _buildActionTile(
                      context: context,
                      icon: Icons.download_rounded,
                      title: AppStrings.downloadMyData,
                      subtitle: AppStrings.downloadDataSubtitle,
                      isDark: isDark,
                      onTap: () => _showDownloadDataDialog(context, isDark),
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
                      icon: Icons.history_rounded,
                      title: AppStrings.activityLog,
                      subtitle: AppStrings.activityLogSubtitle,
                      isDark: isDark,
                      onTap: () {
                        // TODO: Implementieren
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sicherheit Section
              _buildSectionHeader(AppStrings.security, isDark),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSettingCard(
                  isDark: isDark,
                  children: [
                    _buildActionTile(
                      context: context,
                      icon: Icons.security_rounded,
                      title: AppStrings.twoFactorAuth,
                      subtitle: AppStrings.notActivated,
                      isDark: isDark,
                      onTap: () {
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
                      icon: Icons.devices_rounded,
                      title: AppStrings.activeDevices,
                      subtitle: AppStrings.manageDevices,
                      isDark: isDark,
                      onTap: () {
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
                      icon: Icons.vpn_key_rounded,
                      title: AppStrings.appPermissions,
                      subtitle: AppStrings.permissionsSubtitle,
                      isDark: isDark,
                      onTap: () {
                        // TODO: Implementieren
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

  void _updatePrivacy(
    BuildContext context, {
    required bool profilePublic,
    required bool showEmail,
    required bool allowSearchEngines,
  }) {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<ProfileBloc>().add(
            ProfilePrivacyUpdateRequested(
              userId: userId,
              profilePublic: profilePublic,
              showEmail: showEmail,
              allowSearchEngines: allowSearchEngines,
            ),
          );
    }
  }

  void _showDownloadDataDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? AppColors.primaryLight.withOpacity(0.2)
                  : Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.5)
                    : Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 32),

              // Icon
              Container(
                padding: const EdgeInsets.all(16),
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
                            AppColors.primary.withOpacity(0.2),
                            AppColors.primary.withOpacity(0.1),
                          ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? AppColors.primaryLight.withOpacity(0.4)
                        : AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.download_rounded,
                  size: 56,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  AppStrings.downloadData,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 12),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  AppStrings.downloadDataMessage,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? const Color(0xFFB0B0B0)
                            : AppColors.textSecondary,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),

              // Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF404040)
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppStrings.cancel,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Daten-Export initiieren
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppStrings.dataExportStarted),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppStrings.download,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

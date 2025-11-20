import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : null,
      appBar: AppBar(
        title: const Text(AppStrings.aboutTheApp),
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // App Logo & Name Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        AppColors.primaryLight.withOpacity(0.2),
                        const Color(0xFF121212),
                      ]
                    : [
                        AppColors.primary.withOpacity(0.1),
                        Colors.transparent,
                      ],
              ),
            ),
            child: Column(
              children: [
                // Logo mit Gradient und Glow
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              AppColors.primaryLight.withOpacity(0.4),
                              AppColors.accent.withOpacity(0.3),
                            ]
                          : [
                              AppColors.primary.withOpacity(0.15),
                              AppColors.accent.withOpacity(0.1),
                            ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? AppColors.primaryLight.withOpacity(0.4)
                            : AppColors.primary.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 64,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.appNameRememberMe,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppColors.primaryLight.withOpacity(0.3)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    '${AppStrings.version}$_version',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.primaryLight.withOpacity(0.9)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Info Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildListTile(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: AppStrings.whatIsRememberMe,
                    subtitle: AppStrings.dignifiedPlatform,
                    isDark: isDark,
                    onTap: () => _showInfoDialog(
                      context,
                      AppStrings.aboutRememberMe,
                      AppStrings.aboutRememberMeDescription,
                      isDark,
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 84,
                    endIndent: 20,
                    color:
                        isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.article_outlined,
                    title: AppStrings.termsOfService,
                    trailing: Icons.open_in_new_rounded,
                    isDark: isDark,
                    onTap: () => _launchUrl('https://example.com/terms'),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 84,
                    endIndent: 20,
                    color:
                        isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.privacy_tip_outlined,
                    title: AppStrings.privacyPolicy,
                    trailing: Icons.open_in_new_rounded,
                    isDark: isDark,
                    onTap: () => _launchUrl('https://example.com/privacy'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Kontakt Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildListTile(
                    context,
                    icon: Icons.language_rounded,
                    title: AppStrings.website,
                    subtitle: AppStrings.websiteUrl,
                    trailing: Icons.open_in_new_rounded,
                    isDark: isDark,
                    onTap: () => _launchUrl('https://www.digital-memorial.com'),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 84,
                    endIndent: 20,
                    color:
                        isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.email_outlined,
                    title: AppStrings.contact,
                    subtitle: AppStrings.supportEmail,
                    trailing: Icons.open_in_new_rounded,
                    isDark: isDark,
                    onTap: () =>
                        _launchUrl('mailto:${AppStrings.supportEmail}'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Social Media Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text(
                  AppStrings.followUs,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                      Icons.facebook_rounded,
                      isDark,
                      () => _launchUrl('https://facebook.com'),
                    ),
                    const SizedBox(width: 16),
                    _buildSocialButton(
                      Icons.public_rounded,
                      isDark,
                      () => _launchUrl('https://twitter.com'),
                    ),
                    const SizedBox(width: 16),
                    _buildSocialButton(
                      Icons.camera_alt_rounded,
                      isDark,
                      () => _launchUrl('https://instagram.com'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Copyright
          Center(
            child: Column(
              children: [
                Text(
                  AppStrings.copyright,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        isDark ? const Color(0xFF808080) : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.madeWith,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? const Color(0xFF808080)
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.favorite_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.accent.withOpacity(0.9)
                          : AppColors.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.inGermany,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? const Color(0xFF808080)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    IconData? trailing,
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
              // Icon Container mit Gradient
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
                    if (subtitle != null) ...[
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
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color:
                        isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    trailing,
                    size: 16,
                    color:
                        isDark ? const Color(0xFF909090) : Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    IconData icon,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E1E1E)
              : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.primaryLight.withOpacity(0.3)
                : AppColors.primary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: isDark ? AppColors.primaryLight : AppColors.primary,
          size: 28,
        ),
      ),
    );
  }

  void _showInfoDialog(
    BuildContext context,
    String title,
    String content,
    bool isDark,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
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
              // Header mit Icon und Titel
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppColors.primaryLight.withOpacity(0.15),
                            AppColors.primaryLight.withOpacity(0.08),
                          ]
                        : [
                            AppColors.primary.withOpacity(0.08),
                            AppColors.primary.withOpacity(0.04),
                          ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  AppColors.primaryLight.withOpacity(0.3),
                                  AppColors.primaryLight.withOpacity(0.2),
                                ]
                              : [
                                  AppColors.primary.withOpacity(0.15),
                                  AppColors.primary.withOpacity(0.1),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.primaryLight.withOpacity(0.4)
                              : AppColors.primary.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? AppColors.primaryLight.withOpacity(0.15)
                                : AppColors.primary.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textLight
                                  : AppColors.textPrimary,
                              letterSpacing: 0.15,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        color: isDark
                            ? const Color(0xFFB0B0B0)
                            : AppColors.textSecondary,
                        letterSpacing: 0.25,
                      ),
                ),
              ),

              // Action Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                      foregroundColor: AppColors.textLight,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppStrings.close,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLight,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppStrings.couldNotOpen}$urlString${AppStrings.notOpen}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}

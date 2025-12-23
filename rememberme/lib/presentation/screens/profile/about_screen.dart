import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      return _buildIOSView(isDark);
    }
    return _buildAndroidView(isDark);
  }

  // ==================== iOS VIEW ====================
  Widget _buildIOSView(bool isDark) {
    return CupertinoPageScaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          AppStrings.aboutTheApp,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
            fontFamily: '.SF Pro Text',
          ),
        ),
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.8)
            : AppColors.surface.withOpacity(0.94),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: _buildContent(isDark, isIOS: true),
      ),
    );
  }

  // ==================== ANDROID VIEW ====================
  Widget _buildAndroidView(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.aboutTheApp,
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
      ),
      body: SafeArea(
        child: _buildContent(isDark, isIOS: false),
      ),
    );
  }

  Widget _buildContent(bool isDark, {required bool isIOS}) {
    final topPadding = isIOS ? MediaQuery.of(context).padding.top + 44 : 0.0;

    return ListView(
      padding: EdgeInsets.only(top: topPadding, bottom: 32),
      children: [
        _buildHeader(isDark),
        const SizedBox(height: 24),
        _buildInfoSection(isDark),
        const SizedBox(height: 16),
        _buildContactSection(isDark),
        const SizedBox(height: 40),
        _buildSocialSection(isDark),
        const SizedBox(height: 32),
        _buildCopyright(isDark),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.accent
                  : AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? AppColors.accent.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Platform.isIOS
                  ? CupertinoIcons.heart_fill
                  : Icons.favorite_rounded,
              size: 64,
              color: isDark ? AppColors.background : AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.appNameRememberMe,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: Platform.isIOS ? '.SF Pro Display' : null,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.toastBackgroundDark
                  : AppColors.greyLighter,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.greyLighter,
              ),
            ),
            child: Text(
              '${AppStrings.version}$_version',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey,
                fontWeight: FontWeight.w600,
                fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.greyLighter,
          ),
        ),
        child: Column(
          children: [
            _buildListTile(
              icon: Platform.isIOS
                  ? CupertinoIcons.info_circle
                  : Icons.info_outline_rounded,
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
            _buildDivider(isDark),
            _buildListTile(
              icon: Platform.isIOS
                  ? CupertinoIcons.doc_text
                  : Icons.article_outlined,
              title: AppStrings.termsOfService,
              showExternalIcon: true,
              isDark: isDark,
              onTap: () => _launchUrl('https://example.com/terms'),
            ),
            _buildDivider(isDark),
            _buildListTile(
              icon: Platform.isIOS
                  ? CupertinoIcons.shield
                  : Icons.privacy_tip_outlined,
              title: AppStrings.privacyPolicy,
              showExternalIcon: true,
              isDark: isDark,
              onTap: () => _launchUrl('https://example.com/privacy'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.greyLighter,
          ),
        ),
        child: Column(
          children: [
            _buildListTile(
              icon: Platform.isIOS
                  ? CupertinoIcons.globe
                  : Icons.language_rounded,
              title: AppStrings.website,
              subtitle: AppStrings.websiteUrl,
              showExternalIcon: true,
              isDark: isDark,
              onTap: () => _launchUrl('https://www.digital-memorial.com'),
            ),
            _buildDivider(isDark),
            _buildListTile(
              icon: Platform.isIOS ? CupertinoIcons.mail : Icons.email_outlined,
              title: AppStrings.contact,
              subtitle: AppStrings.supportEmail,
              showExternalIcon: true,
              isDark: isDark,
              onTap: () => _launchUrl('mailto:${AppStrings.supportEmail}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 64),
      child: Divider(
        height: 1,
        color: isDark ? AppColors.borderDark : AppColors.divider,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    bool showExternalIcon = false,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.toastBackgroundDark
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                        fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey,
                          fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showExternalIcon)
                Icon(
                  Platform.isIOS
                      ? CupertinoIcons.arrow_up_right
                      : Icons.open_in_new_rounded,
                  size: 18,
                  color: AppColors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            AppStrings.followUs,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
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
                Platform.isIOS
                    ? CupertinoIcons.camera
                    : Icons.camera_alt_rounded,
                isDark,
                () => _launchUrl('https://instagram.com'),
              ),
            ],
          ),
        ],
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.toastBackgroundDark
              : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.greyLighter,
          ),
        ),
        child: Icon(
          icon,
          color: isDark ? AppColors.accent : AppColors.primary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildCopyright(bool isDark) {
    return Center(
      child: Column(
        children: [
          Text(
            AppStrings.copyright,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey,
              fontWeight: FontWeight.w500,
              fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.madeWith,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey,
                  fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Platform.isIOS
                    ? CupertinoIcons.heart_fill
                    : Icons.favorite_rounded,
                size: 16,
                color: AppColors.accent,
              ),
              const SizedBox(width: 6),
              Text(
                AppStrings.inGermany,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey,
                  fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(
    BuildContext context,
    String title,
    String content,
    bool isDark,
  ) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.grey,
                fontFamily: '.SF Pro Text',
                height: 1.5,
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                AppStrings.close,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
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
              Icons.info_outline_rounded,
              size: 24,
              color: isDark ? AppColors.accent : AppColors.primary,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          content: Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.grey,
              height: 1.5,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.accent : AppColors.primary,
                  foregroundColor:
                      isDark ? AppColors.primary : AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  AppStrings.close,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.couldNotOpen}$urlString${AppStrings.notOpen}',
              style: const TextStyle(color: AppColors.textLight),
            ),
            backgroundColor: AppColors.error,
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

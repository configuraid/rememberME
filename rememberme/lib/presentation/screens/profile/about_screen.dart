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

  // ============================================================
  // iOS VIEW
  // ============================================================
  Widget _buildIOSView(bool isDark) {
    return CupertinoPageScaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFF2F2F7),
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

  // ============================================================
  // Android VIEW
  // ============================================================
  Widget _buildAndroidView(bool isDark) {
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFF5F5F5),
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
      body: _buildContent(isDark, isIOS: false),
    );
  }

  // ============================================================
  // Content
  // ============================================================
  Widget _buildContent(bool isDark, {required bool isIOS}) {
    final topPadding = isIOS ? MediaQuery.of(context).padding.top + 44 : 0.0;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 32;

    return ListView(
      padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      children: [
        _buildHeader(isDark),
        const SizedBox(height: 24),
        _buildSectionHeader('Rechtliches', isDark),
        _buildInfoSection(isDark),
        const SizedBox(height: 24),
        _buildSectionHeader('Kontakt', isDark),
        _buildContactSection(isDark),
        const SizedBox(height: 32),
        _buildSocialSection(isDark),
        const SizedBox(height: 32),
        _buildCopyright(isDark),
      ],
    );
  }

  // ============================================================
  // Header (App-Icon + Name + Version)
  // ============================================================
  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
      child: Column(
        children: [
          // App Icon – schlicht, rund
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.accent.withOpacity(0.15)
                  : AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Platform.isIOS
                  ? CupertinoIcons.heart_fill
                  : Icons.favorite_rounded,
              size: 48,
              color: isDark ? AppColors.accent : AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),

          // App Name
          Text(
            AppStrings.appNameRememberMe,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: Platform.isIOS ? '.SF Pro Display' : null,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Version – dezent
          Text(
            '${AppStrings.version}$_version',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey,
              fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Section Header
  // ============================================================
  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.grey,
          fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
        ),
      ),
    );
  }

  // ============================================================
  // Card Container (WhatsApp-Style: kein Border)
  // ============================================================
  Widget _buildCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  // ============================================================
  // Rechtliches (AGB, Datenschutz)
  // ============================================================
  Widget _buildInfoSection(bool isDark) {
    return _buildCard(
      isDark: isDark,
      children: [
        _buildListTile(
          icon:
              Platform.isIOS ? CupertinoIcons.doc_text : Icons.article_outlined,
          title: AppStrings.termsOfService,
          isDark: isDark,
          onTap: () => _launchUrl('https://example.com/terms'),
        ),
        _buildDivider(isDark),
        _buildListTile(
          icon: Platform.isIOS
              ? CupertinoIcons.shield
              : Icons.privacy_tip_outlined,
          title: AppStrings.privacyPolicy,
          isDark: isDark,
          onTap: () => _launchUrl('https://example.com/privacy'),
        ),
      ],
    );
  }

  // ============================================================
  // Kontakt (Website, E-Mail)
  // ============================================================
  Widget _buildContactSection(bool isDark) {
    return _buildCard(
      isDark: isDark,
      children: [
        _buildListTile(
          icon: Platform.isIOS ? CupertinoIcons.globe : Icons.language_rounded,
          title: AppStrings.website,
          subtitle: AppStrings.websiteUrl,
          isDark: isDark,
          onTap: () => _launchUrl('https://www.digital-memorial.com'),
        ),
        _buildDivider(isDark),
        _buildListTile(
          icon: Platform.isIOS ? CupertinoIcons.mail : Icons.email_outlined,
          title: AppStrings.contact,
          subtitle: AppStrings.supportEmail,
          isDark: isDark,
          onTap: () => _launchUrl('mailto:${AppStrings.supportEmail}'),
        ),
      ],
    );
  }

  // ============================================================
  // List Tile (WhatsApp-Style: flaches Icon, kein farbiger BG)
  // ============================================================
  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final Widget tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon,
              size: 22,
              color: isDark ? AppColors.textLight : AppColors.textPrimary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey,
                      fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Platform.isIOS
                ? CupertinoIcons.chevron_right
                : Icons.arrow_forward_ios_rounded,
            size: 20,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ],
      ),
    );

    if (Platform.isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: tile,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: tile,
      ),
    );
  }

  // ============================================================
  // Divider (eingerückt ab Icon-Ende)
  // ============================================================
  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 54),
      child: Divider(
        height: 1,
        color: isDark ? AppColors.borderDark : AppColors.divider,
      ),
    );
  }

  // ============================================================
  // Social Section
  // ============================================================
  Widget _buildSocialSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            AppStrings.followUs,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.grey,
              fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
            ),
          ),
          const SizedBox(height: 16),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDark ? AppColors.accent : AppColors.primary,
          size: 22,
        ),
      ),
    );
  }

  // ============================================================
  // Copyright
  // ============================================================
  Widget _buildCopyright(bool isDark) {
    return Center(
      child: Column(
        children: [
          Text(
            AppStrings.copyright,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey.withOpacity(0.7),
              fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.madeWith,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.grey.withOpacity(0.7),
                  fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Platform.isIOS
                    ? CupertinoIcons.heart_fill
                    : Icons.favorite_rounded,
                size: 14,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                AppStrings.inGermany,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.grey.withOpacity(0.7),
                  fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // URL Launcher
  // ============================================================
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

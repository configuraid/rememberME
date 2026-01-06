import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../data/models/memorial_model.dart';
import '../../../core/constants/app_colors.dart';

/// Screen der angezeigt wird wenn ein User ein PRIVATES Memorial
class MemorialPrivateScreen extends StatelessWidget {
  final MemorialModel memorial;

  const MemorialPrivateScreen({
    super.key,
    required this.memorial,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSView(context);
    }
    return _buildAndroidView(context);
  }

  // ============================================================
  // Android View
  // ============================================================
  Widget _buildAndroidView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.textLight : AppColors.primary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Gedenkseite',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.8)
            : AppColors.surface.withOpacity(0.94),
        foregroundColor: isDark ? AppColors.textLight : AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildPrivateIcon(isDark, false),
                const SizedBox(height: 40),
                _buildPrivateMessage(isDark, false),
                const SizedBox(height: 40),
                _buildBackButton(context, isDark, false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // iOS View
  // ============================================================
  Widget _buildIOSView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoNavigationBarBackButton(
          color: isDark ? AppColors.primaryLight : AppColors.primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        middle: Text(
          'Gedenkseite',
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
      child: SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildPrivateIcon(isDark, true),
                  const SizedBox(height: 40),
                  _buildPrivateMessage(isDark, true),
                  const SizedBox(height: 40),
                  _buildBackButton(context, isDark, true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Private Icon mit Lock
  // ============================================================
  Widget _buildPrivateIcon(bool isDark, bool isIOS) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.backgroundDarkElevated,
                  AppColors.backgroundDark,
                ]
              : [
                  AppColors.greyLighter,
                  AppColors.surface,
                ],
        ),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLight,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        isIOS ? CupertinoIcons.lock_shield_fill : Icons.lock_rounded,
        size: 48,
        color: isDark ? AppColors.grey : AppColors.greyDark,
      ),
    );
  }

  // ============================================================
  // Private Nachricht
  // ============================================================
  Widget _buildPrivateMessage(bool isDark, bool isIOS) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.5)
            : AppColors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.borderDarkSubtle.withOpacity(0.5)
              : AppColors.greyLighter,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Private Gedenkseite',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: isIOS ? '.SF Pro Display' : null,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Beschreibung
          Text(
            'Diese Gedenkseite ist privat und nur für eingeladene Personen sichtbar.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.grey,
              fontFamily: isIOS ? '.SF Pro Text' : null,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Wenn du Zugang erhalten möchtest, wende dich bitte an die Familie oder den Ersteller der Seite.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.grey.withOpacity(0.8),
              fontFamily: isIOS ? '.SF Pro Text' : null,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Zurück Button
  // ============================================================
  Widget _buildBackButton(BuildContext context, bool isDark, bool isIOS) {
    if (isIOS) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          color: isDark ? AppColors.accent : AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Zurück',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.primary : AppColors.background,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? AppColors.accent : AppColors.primary,
          foregroundColor: isDark ? AppColors.primary : AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Zurück',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

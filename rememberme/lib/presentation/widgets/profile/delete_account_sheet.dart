import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:rememberme/core/constants/app_colors.dart';

// ============================================================
// DELETE ACCOUNT BOTTOM SHEET - iOS STYLE
// ============================================================

class DeleteAccountSheet extends StatelessWidget {
  final bool isDark;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const DeleteAccountSheet({
    super.key,
    required this.isDark,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            _buildHeader(),
            _buildWarningCard(),
            const SizedBox(height: 8),
            _buildActions(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 36,
      height: 5,
      decoration: BoxDecoration(
        color: isDark ? AppColors.borderDark : AppColors.greyLight,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(isDark ? 0.15 : 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: AppColors.error,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Account löschen',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Display',
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Diese Aktion kann nicht rückgängig gemacht werden.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.grey,
              fontFamily: '.SF Pro Text',
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            CupertinoIcons.info_circle_fill,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Alle deine Daten, Erinnerungen und Medien werden unwiderruflich gelöscht. '
              'Du verlierst den Zugang zu allen geteilten Inhalten.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.error.withOpacity(isDark ? 0.9 : 1.0),
                fontFamily: '.SF Pro Text',
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          // Delete Button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.error,
              onPressed: onConfirm,
              child: const Text(
                'Account unwiderruflich löschen',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Cancel Button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              borderRadius: BorderRadius.circular(12),
              color: isDark
                  ? AppColors.toastBackgroundDark
                  : AppColors.greyLighter,
              onPressed: onCancel,
              child: Text(
                'Abbrechen',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HELPER FUNCTION
// ============================================================

void showDeleteAccountBottomSheet(
  BuildContext context, {
  required bool isDark,
  required String? userId,
  required Function(String userId) onDeleteAccount,
}) {
  showCupertinoModalPopup(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => DeleteAccountSheet(
      isDark: isDark,
      onCancel: () => Navigator.of(ctx).pop(),
      onConfirm: () {
        if (userId != null) {
          onDeleteAccount(userId);
        }
        Navigator.of(ctx).pop();
      },
    ),
  );
}

// ============================================================
// ALTERNATIVE: Zwei-Stufen-Dialog für extra Sicherheit
// ============================================================

class DeleteAccountConfirmationFlow {
  static void show(
    BuildContext context, {
    required bool isDark,
    required String? userId,
    required Function(String userId) onDeleteAccount,
  }) {
    // Step 1: Warning Dialog
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Account löschen?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            'Bist du sicher? Alle Daten werden unwiderruflich gelöscht.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Abbrechen',
              style: TextStyle(
                fontSize: 17,
                color: isDark ? AppColors.accent : AppColors.primary,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              // Step 2: Confirmation Sheet
              showDeleteAccountBottomSheet(
                context,
                isDark: isDark,
                userId: userId,
                onDeleteAccount: onDeleteAccount,
              );
            },
            child: const Text(
              'Fortfahren',
              style: TextStyle(
                fontSize: 17,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:rememberme/core/constants/app_colors.dart';

class PreviewLoadingDialog extends StatelessWidget {
  final String message;

  const PreviewLoadingDialog({
    super.key,
    this.message = 'Vorschau wird vorbereitet...',
  });

  /// Shows the loading dialog
  static Future<void> show(BuildContext context, {String? message}) {
    if (Platform.isIOS) {
      return showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PreviewLoadingDialog(
          message: message ?? 'Vorschau wird vorbereitet...',
        ),
      );
    } else {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PreviewLoadingDialog(
          message: message ?? 'Vorschau wird vorbereitet...',
        ),
      );
    }
  }

  /// Hides the loading dialog
  static void hide(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSDialog(context);
    }
    return _buildAndroidDialog(context);
  }

  Widget _buildIOSDialog(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(radius: 14),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                fontFamily: '.SF Pro Text',
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a platform-native error dialog for preview failures
class PreviewErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const PreviewErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  /// Shows the error dialog
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    if (Platform.isIOS) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (context) => PreviewErrorDialog(
          title: title,
          message: message,
          onRetry: onRetry,
        ),
      );
    } else {
      return showDialog<bool>(
        context: context,
        builder: (context) => PreviewErrorDialog(
          title: title,
          message: message,
          onRetry: onRetry,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSDialog(context);
    }
    return _buildAndroidDialog(context);
  }

  Widget _buildIOSDialog(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;

    return CupertinoAlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: CupertinoColors.systemOrange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ],
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          message,
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.systemGrey,
            fontFamily: '.SF Pro Text',
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          child: Text(
            'Schließen',
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.activeBlue,
              fontFamily: '.SF Pro Text',
            ),
          ),
          onPressed: () => Navigator.pop(context, false),
        ),
        if (onRetry != null)
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(
              'Erneut versuchen',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.activeBlue,
                fontFamily: '.SF Pro Text',
              ),
            ),
            onPressed: () {
              Navigator.pop(context, true);
              onRetry?.call();
            },
          ),
      ],
    );
  }

  Widget _buildAndroidDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                isDark ? Colors.orange.withOpacity(0.3) : Colors.grey.shade200,
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange.withOpacity(0.2),
                    Colors.orange.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.orange.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.warning_rounded,
                size: 48,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
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
                        'Schließen',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                          onRetry?.call();
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
                        child: const Text(
                          'Erneut',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

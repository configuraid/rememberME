import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:io';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/memorial_model.dart';
import '../../../data/services/share_service.dart';

/// Shows a share bottom sheet for a memorial
Future<void> showMemorialShareSheet({
  required BuildContext context,
  required MemorialModel memorial,
  required String currentUserId,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  if (Platform.isIOS) {
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _ShareBottomSheetIOS(
        memorial: memorial,
        currentUserId: currentUserId,
        isDark: isDark,
      ),
    );
  } else {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ShareBottomSheetAndroid(
        memorial: memorial,
        currentUserId: currentUserId,
        isDark: isDark,
      ),
    );
  }
}

// ============================================================
// iOS Bottom Sheet
// ============================================================
class _ShareBottomSheetIOS extends StatefulWidget {
  final MemorialModel memorial;
  final String currentUserId;
  final bool isDark;

  const _ShareBottomSheetIOS({
    required this.memorial,
    required this.currentUserId,
    required this.isDark,
  });

  @override
  State<_ShareBottomSheetIOS> createState() => _ShareBottomSheetIOSState();
}

class _ShareBottomSheetIOSState extends State<_ShareBottomSheetIOS> {
  final ShareService _shareService = ShareService();
  bool _isSharing = false;

  Future<void> _shareMemorial() async {
    setState(() => _isSharing = true);
    HapticFeedback.mediumImpact();

    final result = await _shareService.shareMemorial(
      memorial: widget.memorial,
      inviterId: widget.currentUserId,
    );

    if (!mounted) return;
    setState(() => _isSharing = false);

    if (result.success) {
      Navigator.of(context).pop();
      HapticFeedback.heavyImpact();
    } else {
      _showError(result.errorMessage ?? 'Fehler beim Teilen');
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Fehler'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            isDefaultAction: true,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: widget.isDark
              ? AppColors.backgroundDarkElevated
              : CupertinoColors.systemBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              const SizedBox(height: 20),

              // Memorial Preview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: widget.isDark
                            ? AppColors.accent.withOpacity(0.2)
                            : AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: widget.memorial.profileImageUrl != null
                          ? ClipOval(
                              child: Image.network(
                                widget.memorial.profileImageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              CupertinoIcons.person_fill,
                              size: 28,
                              color: widget.isDark
                                  ? AppColors.accent
                                  : AppColors.primary,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.memorial.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark
                                  ? AppColors.textLight
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gedenkseite teilen',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Info Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? AppColors.backgroundDark
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.info_circle,
                        size: 20,
                        color: AppColors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Personen mit dem Link können die Gedenkseite ansehen.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Share Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    color: widget.isDark ? AppColors.accent : AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    onPressed: _isSharing ? null : _shareMemorial,
                    child: _isSharing
                        ? CupertinoActivityIndicator(
                            color: widget.isDark
                                ? AppColors.primary
                                : AppColors.textLight,
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.share,
                                size: 20,
                                color: widget.isDark
                                    ? AppColors.primary
                                    : AppColors.textLight,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Link teilen',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: widget.isDark
                                      ? AppColors.primary
                                      : AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Cancel Button
              CupertinoButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Abbrechen',
                  style: TextStyle(
                    fontSize: 17,
                    color: widget.isDark ? AppColors.accent : AppColors.primary,
                  ),
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

// ============================================================
// Android Bottom Sheet
// ============================================================
class _ShareBottomSheetAndroid extends StatefulWidget {
  final MemorialModel memorial;
  final String currentUserId;
  final bool isDark;

  const _ShareBottomSheetAndroid({
    required this.memorial,
    required this.currentUserId,
    required this.isDark,
  });

  @override
  State<_ShareBottomSheetAndroid> createState() =>
      _ShareBottomSheetAndroidState();
}

class _ShareBottomSheetAndroidState extends State<_ShareBottomSheetAndroid> {
  final ShareService _shareService = ShareService();
  bool _isSharing = false;

  Future<void> _shareMemorial() async {
    setState(() => _isSharing = true);
    HapticFeedback.mediumImpact();

    final result = await _shareService.shareMemorial(
      memorial: widget.memorial,
      inviterId: widget.currentUserId,
    );

    if (!mounted) return;
    setState(() => _isSharing = false);

    if (result.success) {
      Navigator.of(context).pop();
      HapticFeedback.heavyImpact();
    } else {
      _showError(result.errorMessage ?? 'Fehler beim Teilen');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark
            ? AppColors.backgroundDarkElevated
            : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),

            const SizedBox(height: 20),

            // Memorial Preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? AppColors.accent.withOpacity(0.2)
                          : AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: widget.memorial.profileImageUrl != null
                        ? ClipOval(
                            child: Image.network(
                              widget.memorial.profileImageUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: widget.isDark
                                ? AppColors.accent
                                : AppColors.primary,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.memorial.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gedenkseite teilen',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Info Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppColors.backgroundDark
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppColors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Personen mit dem Link können die Gedenkseite ansehen.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Share Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _isSharing ? null : _shareMemorial,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        widget.isDark ? AppColors.accent : AppColors.primary,
                    foregroundColor:
                        widget.isDark ? AppColors.primary : AppColors.textLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isSharing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.isDark
                                  ? AppColors.primary
                                  : AppColors.textLight,
                            ),
                          ),
                        )
                      : const Icon(Icons.share_rounded, size: 20),
                  label: Text(
                    _isSharing ? 'Wird geteilt...' : 'Link teilen',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Cancel Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Abbrechen',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          widget.isDark ? AppColors.accent : AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

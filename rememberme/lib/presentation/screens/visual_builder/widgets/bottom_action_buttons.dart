import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/core/constants/app_strings.dart';

class BottomActionButtons extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onCreate;
  final bool isValid;
  final String? confirmLabel;

  const BottomActionButtons({
    super.key,
    required this.onCancel,
    required this.onCreate,
    this.isValid = true,
    this.confirmLabel,
  });

  String get _label => confirmLabel ?? 'Block erstellen';

  bool get _isEditMode =>
      confirmLabel != null && confirmLabel != 'Block erstellen';

  IconData get _iosIcon =>
      _isEditMode ? CupertinoIcons.checkmark_alt : CupertinoIcons.checkmark_alt;

  IconData get _androidIcon =>
      _isEditMode ? Icons.check_rounded : Icons.add_rounded;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      return _buildIOSButtons(context, isDark);
    }
    return _buildAndroidButtons(context, isDark);
  }

  Widget _buildIOSButtons(BuildContext context, bool isDark) {
    final Color buttonColor = isDark ? AppColors.accent : AppColors.primary;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: isDark
                  ? AppColors.toastBackgroundDark
                  : AppColors.greyLighter,
              borderRadius: BorderRadius.circular(12),
              onPressed: onCancel,
              child: Text(
                AppStrings.cancel,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Opacity(
              opacity: isValid ? 1.0 : 0.5,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: buttonColor,
                borderRadius: BorderRadius.circular(12),
                onPressed: onCreate,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _iosIcon,
                      size: 20,
                      color: isDark ? AppColors.primary : AppColors.background,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? AppColors.primary : AppColors.background,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidButtons(BuildContext context, bool isDark) {
    final Color buttonColor = isDark ? AppColors.accent : AppColors.primary;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel Button
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.toastBackgroundDark
                    : AppColors.greyLighter.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.greyLight.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCancel,
                  borderRadius: BorderRadius.circular(16),
                  splashColor: AppColors.error.withOpacity(0.1),
                  highlightColor: AppColors.error.withOpacity(0.05),
                  child: Center(
                    child: Text(
                      AppStrings.cancel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textLight : AppColors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Confirm Button
          Expanded(
            flex: 2,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    buttonColor,
                    buttonColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: buttonColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCreate,
                  borderRadius: BorderRadius.circular(16),
                  splashColor: Colors.white.withOpacity(0.2),
                  highlightColor: Colors.white.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _androidIcon,
                          size: 20,
                          color:
                              isDark ? AppColors.primary : AppColors.background,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? AppColors.primary : AppColors.background,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

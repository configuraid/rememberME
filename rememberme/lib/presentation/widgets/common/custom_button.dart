import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';

enum ButtonVariant { filled, outlined, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final Color? color;
  final bool isDanger;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.filled,
    this.icon,
    this.isLoading = false,
    this.color,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildCupertinoButton(context);
    }
    return _buildMaterialButton(context);
  }

  Widget _buildMaterialButton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final buttonColor = isDanger
        ? AppColors.error
        : (color ?? (isDark ? AppColors.accent : AppColors.primary));
    final buttonTextColor = isDark ? AppColors.primary : AppColors.background;

    if (isLoading) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      );
    }

    switch (variant) {
      case ButtonVariant.outlined:
        return Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: onPressed != null
                ? [
                    BoxShadow(
                      color: isDark ? AppColors.shadowDark : AppColors.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              side: BorderSide(
                color: onPressed != null
                    ? buttonColor
                    : (isDark ? AppColors.borderDark : AppColors.greyLighter),
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 22,
                    color: onPressed != null
                        ? buttonColor
                        : (isDark ? AppColors.grey : AppColors.greyLight),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: onPressed != null
                        ? buttonColor
                        : (isDark ? AppColors.grey : AppColors.greyLight),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );

      case ButtonVariant.text:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 22,
                  color: onPressed != null
                      ? buttonColor
                      : (isDark ? AppColors.grey : AppColors.greyLight),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: onPressed != null
                      ? buttonColor
                      : (isDark ? AppColors.grey : AppColors.greyLight),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );

      case ButtonVariant.filled:
      default:
        return Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: onPressed != null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      buttonColor,
                      buttonColor.withOpacity(0.85),
                    ],
                  )
                : null,
            color: onPressed == null
                ? (isDark
                    ? AppColors.toastBackgroundDark
                    : AppColors.greyLighter)
                : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: onPressed != null
                ? [
                    BoxShadow(
                      color: buttonColor.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: buttonTextColor,
              disabledBackgroundColor: Colors.transparent,
              disabledForegroundColor: AppColors.grey,
              minimumSize: const Size(double.infinity, 56),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 22),
                  const SizedBox(width: 12),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: onPressed != null ? buttonTextColor : AppColors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildCupertinoButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isDanger
        ? AppColors.error
        : (color ?? (isDark ? AppColors.accent : AppColors.primary));
    final buttonTextColor = isDark ? AppColors.primary : AppColors.background;

    if (isLoading) {
      return Container(
        height: 50,
        alignment: Alignment.center,
        child: CupertinoActivityIndicator(
          color: isDark ? AppColors.accent : AppColors.primary,
        ),
      );
    }

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: onPressed != null
            ? buttonColor
            : (isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CupertinoButton(
        onPressed: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: onPressed != null ? buttonTextColor : AppColors.grey,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: onPressed != null ? buttonTextColor : AppColors.grey,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

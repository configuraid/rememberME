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
        : (color ?? (isDark ? AppColors.primaryLight : AppColors.primary));

    if (isLoading) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
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
                      color: isDark
                          ? Colors.black.withOpacity(0.2)
                          : Colors.black.withOpacity(0.04),
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
                    : (isDark ? const Color(0xFF404040) : Colors.grey.shade300),
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                        : (isDark
                            ? const Color(0xFF808080)
                            : Colors.grey.shade400),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  text,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: onPressed != null
                        ? buttonColor
                        : (isDark
                            ? const Color(0xFF808080)
                            : Colors.grey.shade400),
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
                      : (isDark
                          ? const Color(0xFF808080)
                          : Colors.grey.shade400),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                text,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: onPressed != null
                      ? buttonColor
                      : (isDark
                          ? const Color(0xFF808080)
                          : Colors.grey.shade400),
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
                ? (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300)
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
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.transparent,
              disabledForegroundColor:
                  isDark ? const Color(0xFF808080) : Colors.grey.shade500,
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: onPressed != null
                        ? Colors.white
                        : (isDark
                            ? const Color(0xFF808080)
                            : Colors.grey.shade500),
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
    if (isLoading) {
      return Container(
        height: 50,
        alignment: Alignment.center,
        child: const CupertinoActivityIndicator(),
      );
    }

    final buttonColor = isDanger ? CupertinoColors.systemRed : null;

    return CupertinoButton.filled(
      onPressed: onPressed,
      disabledColor: CupertinoColors.quaternarySystemFill,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

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

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.filled,
    this.icon,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildCupertinoButton(context);
    }
    return _buildMaterialButton(context);
  }

  Widget _buildMaterialButton(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;

    if (isLoading) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    switch (variant) {
      case ButtonVariant.outlined:
        return OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
          label: Text(text),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            side: BorderSide(color: buttonColor, width: 2),
          ),
        );
      case ButtonVariant.text:
        return TextButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
          label: Text(text),
        );
      case ButtonVariant.filled:
      default:
        return ElevatedButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
          label: Text(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            minimumSize: const Size(double.infinity, 50),
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

    return CupertinoButton.filled(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(text),
        ],
      ),
    );
  }
}

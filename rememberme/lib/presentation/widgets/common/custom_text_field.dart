import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final bool enabled;
  final FocusNode? focusNode;
  final void Function(String)? onChanged;
  final int? maxLength;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.textInputAction,
    this.onFieldSubmitted,
    this.enabled = true,
    this.focusNode,
    this.onChanged,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildCupertinoTextField(context);
    }
    return _buildMaterialTextField(context);
  }

  Widget _buildMaterialTextField(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        enabled: enabled,
        focusNode: focusNode,
        onChanged: onChanged,
        style: TextStyle(
          color: enabled
              ? (isDark ? AppColors.textLight : AppColors.textPrimary)
              : (isDark ? const Color(0xFF808080) : Colors.grey.shade400),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: isDark ? const Color(0xFF909090) : AppColors.textSecondary,
          ),
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFF707070) : Colors.grey.shade400,
          ),
          prefixIcon: prefixIcon != null
              ? Container(
                  margin: const EdgeInsets.only(right: 12, left: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              AppColors.primaryLight.withOpacity(0.2),
                              AppColors.primaryLight.withOpacity(0.1),
                            ]
                          : [
                              AppColors.primary.withOpacity(0.12),
                              AppColors.primary.withOpacity(0.06),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    prefixIcon,
                    color: enabled
                        ? (isDark ? AppColors.primaryLight : AppColors.primary)
                        : (isDark
                            ? const Color(0xFF404040)
                            : Colors.grey.shade400),
                    size: 22,
                  ),
                )
              : null,
          suffixIcon: suffixIcon != null
              ? IconButton(
                  icon: Icon(
                    suffixIcon,
                    color: enabled
                        ? (isDark ? AppColors.primaryLight : AppColors.primary)
                        : (isDark
                            ? const Color(0xFF404040)
                            : Colors.grey.shade400),
                    size: 22,
                  ),
                  onPressed: enabled ? onSuffixIconPressed : null,
                )
              : null,
          filled: true,
          fillColor: enabled
              ? (isDark ? const Color(0xFF1E1E1E) : Colors.white)
              : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? AppColors.primaryLight : AppColors.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          errorStyle: const TextStyle(
            color: AppColors.error,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          alignLabelWithHint: maxLines != null && maxLines! > 1,
        ),
      ),
    );
  }

  Widget _buildCupertinoTextField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: enabled
                ? CupertinoColors.label.resolveFrom(context)
                : CupertinoColors.inactiveGray.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          placeholder: hint,
          prefix: prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    prefixIcon,
                    size: 20,
                    color: enabled
                        ? CupertinoColors.systemGrey.resolveFrom(context)
                        : CupertinoColors.inactiveGray.resolveFrom(context),
                  ),
                )
              : null,
          suffix: suffixIcon != null
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: enabled ? onSuffixIconPressed : null,
                  child: Icon(
                    suffixIcon,
                    size: 20,
                    color: enabled
                        ? CupertinoColors.systemGrey.resolveFrom(context)
                        : CupertinoColors.inactiveGray.resolveFrom(context),
                  ),
                )
              : null,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          padding: const EdgeInsets.all(12),
          textInputAction: textInputAction,
          onSubmitted: onFieldSubmitted,
          enabled: enabled,
          focusNode: focusNode,
          onChanged: onChanged,
          decoration: BoxDecoration(
            color: enabled
                ? CupertinoColors.systemBackground.resolveFrom(context)
                : CupertinoColors.systemGrey6.resolveFrom(context),
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        // Validierungs-Fehler für iOS (da CupertinoTextField kein validator hat)
        if (!enabled || validator == null)
          const SizedBox.shrink()
        else
          Builder(
            builder: (context) {
              final errorText = validator?.call(controller.text);
              if (errorText == null) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(top: 8, left: 8),
                child: Text(
                  errorText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

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
            color: isDark ? AppColors.shadowDark : AppColors.shadow,
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
              : (isDark ? AppColors.grey : AppColors.greyLight),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: isDark ? AppColors.grey : AppColors.textSecondary,
          ),
          hintStyle: TextStyle(
            color: isDark ? AppColors.greyDark : AppColors.greyLight,
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
                            ? AppColors.borderDarkSubtle
                            : AppColors.greyLight),
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
                            ? AppColors.borderDarkSubtle
                            : AppColors.greyLight),
                    size: 22,
                  ),
                  onPressed: enabled ? onSuffixIconPressed : null,
                )
              : null,
          filled: true,
          fillColor: enabled
              ? (isDark ? AppColors.surfaceDark : AppColors.surface)
              : (isDark ? AppColors.cardBorderDark : AppColors.greyLighter),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? AppColors.cardBorderDark : AppColors.greyLight,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? AppColors.cardBorderDark : AppColors.greyLight,
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
            borderSide: BorderSide(
              color: isDark ? AppColors.errorLight : AppColors.error,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? AppColors.errorLight : AppColors.error,
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? AppColors.cardBorderDark : AppColors.greyLight,
              width: 1.5,
            ),
          ),
          errorStyle: TextStyle(
            color: isDark ? AppColors.errorLight : AppColors.error,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          alignLabelWithHint: maxLines != null && maxLines! > 1,
        ),
      ),
    );
  }

  Widget _buildCupertinoTextField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: enabled
                ? (isDark ? AppColors.textLight : AppColors.textPrimary)
                : AppColors.grey,
            fontFamily: '.SF Pro Text',
          ),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          placeholder: hint,
          placeholderStyle: TextStyle(
            color: AppColors.grey,
            fontFamily: '.SF Pro Text',
          ),
          style: TextStyle(
            color: enabled
                ? (isDark ? AppColors.textLight : AppColors.textPrimary)
                : AppColors.grey,
            fontFamily: '.SF Pro Text',
          ),
          prefix: prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    prefixIcon,
                    size: 20,
                    color: enabled ? AppColors.grey : AppColors.greyLight,
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
                    color: enabled ? AppColors.grey : AppColors.greyLight,
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
                ? (isDark ? AppColors.surfaceDark : AppColors.surface)
                : (isDark
                    ? AppColors.backgroundDarkElevated
                    : AppColors.greyLighter),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.divider,
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
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.errorLight : AppColors.error,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

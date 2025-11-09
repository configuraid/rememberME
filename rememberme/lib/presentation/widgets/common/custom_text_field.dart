import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

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
  final TextInputAction? textInputAction; // ✅ Hinzugefügt
  final void Function(String)? onFieldSubmitted; // ✅ Hinzugefügt
  final bool enabled;
  final FocusNode? focusNode;
  final void Function(String)? onChanged;

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
    this.textInputAction, // ✅ Hinzugefügt
    this.onFieldSubmitted, // ✅ Hinzugefügt
    this.enabled = true,
    this.focusNode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildCupertinoTextField(context);
    }
    return _buildMaterialTextField(context);
  }

  Widget _buildMaterialTextField(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(suffixIcon),
                onPressed: onSuffixIconPressed,
              )
            : null,
      ),
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textInputAction: textInputAction, // ✅ Hinzugefügt
      onFieldSubmitted: onFieldSubmitted, // ✅ Hinzugefügt
      enabled: enabled,
      focusNode: focusNode,
      onChanged: onChanged,
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
          padding: const EdgeInsets.all(12),
          textInputAction: textInputAction, // ✅ Hinzugefügt
          onSubmitted:
              onFieldSubmitted, // ✅ Hinzugefügt (CupertinoTextField verwendet onSubmitted statt onFieldSubmitted)
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

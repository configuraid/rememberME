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
    );
  }

  Widget _buildCupertinoTextField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          placeholder: hint,
          prefix: prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(prefixIcon, size: 20),
                )
              : null,
          suffix: suffixIcon != null
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onSuffixIconPressed,
                  child: Icon(suffixIcon, size: 20),
                )
              : null,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          padding: const EdgeInsets.all(12),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rememberme/core/constants/app_colors.dart';

class ConfigTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const ConfigTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  State<ConfigTextField> createState() => _ConfigTextFieldState();
}

class _ConfigTextFieldState extends State<ConfigTextField> {
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;

  bool get _isMultiline => widget.maxLines > 1;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS && _isMultiline) {
      _focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => _KeyboardToolbar(
        onDone: () => _focusNode.unfocus(),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      return _buildIOSTextField(context, isDark);
    }
    return _buildAndroidTextField(context, isDark);
  }

  Widget _buildIOSTextField(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.greyLight,
            ),
          ),
          child: CupertinoTextField(
            controller: widget.controller,
            focusNode: _focusNode,
            placeholder: widget.hint ?? widget.label,
            maxLines: widget.maxLines,
            textInputAction:
                _isMultiline ? TextInputAction.newline : TextInputAction.done,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            style: TextStyle(
              fontSize: 17,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
            placeholderStyle: TextStyle(fontSize: 17, color: AppColors.grey),
            decoration: const BoxDecoration(color: Colors.transparent),
            onChanged: widget.onChanged,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
          ),
        ),
      ],
    );
  }

  Widget _buildAndroidTextField(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          style: TextStyle(
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
            fontSize: 17,
          ),
          textInputAction:
              _isMultiline ? TextInputAction.newline : TextInputAction.done,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: AppColors.grey),
            filled: true,
            fillColor:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.greyLighter,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.greyLighter,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.accent : AppColors.primary,
                width: 2,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          maxLines: widget.maxLines,
          onChanged: widget.onChanged,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
      ],
    );
  }
}

// ============================================================
// iOS Keyboard Toolbar — "Fertig" Button über der Tastatur
// ============================================================
class _KeyboardToolbar extends StatelessWidget {
  final VoidCallback onDone;

  const _KeyboardToolbar({required this.onDone});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    if (keyboardHeight == 0) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      bottom: keyboardHeight,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.backgroundDarkElevated
              : const Color(0xFFD1D5DB),
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : const Color(0xFFB8BCC2),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: onDone,
              child: Text(
                'Fertig',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

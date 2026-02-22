import 'package:flutter/material.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/core/constants/app_strings.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/alignment_picker.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/config_slider.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/config_text_field.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/live_preview_container.dart';
import 'package:rememberme/presentation/widgets/page_builder/color_picker_card.dart';
import 'package:rememberme/presentation/widgets/common/custom_color_picker_dialog.dart';

class TextSettings extends StatefulWidget {
  final Map<String, dynamic> content;
  final ValueChanged<String> onValueChanged;

  const TextSettings({
    super.key,
    required this.content,
    required this.onValueChanged,
  });

  @override
  State<TextSettings> createState() => _TextSettingsState();
}

class _TextSettingsState extends State<TextSettings> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _getString('text'));
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ============================================================
  // TYPE-SAFE GETTERS
  // ============================================================

  String _getString(String key, [String defaultValue = '']) {
    final value = widget.content[key];
    if (value is String) return value;
    if (value != null) return value.toString();
    return defaultValue;
  }

  double _getDouble(String key, [double defaultValue = 0.0]) {
    final value = widget.content[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  String get _text => _getString('text');
  double get _fontSize => _getDouble('fontSize', 16.0);
  String get _align => _getString('align', 'left');
  String get _color => _getString('color', '#333333');

  void _updateValue(String key, dynamic value) {
    setState(() {
      widget.content[key] = value;
    });
    widget.onValueChanged('$key:${value.toString()}');
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // ===== STICKY: Live Preview oben fixiert =====
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: LivePreviewContainer(
            child: Text(
              _text.isEmpty
                  ? 'Text Vorschau - Bewege den Regler um die Schriftgröße zu ändern'
                  : _text,
              style: TextStyle(
                fontSize: _fontSize,
                color: _text.isEmpty ? AppColors.grey : _hexToColor(_color),
                height: 1.5,
              ),
              textAlign: _align == 'center'
                  ? TextAlign.center
                  : _align == 'right'
                      ? TextAlign.right
                      : TextAlign.left,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ===== SCROLLBAR: Einstellungen scrollen darunter =====
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text Field
                ConfigTextField(
                  label: AppStrings.text,
                  controller: _textController,
                  hint: 'Text eingeben...',
                  maxLines: 10,
                  onChanged: (value) => _updateValue('text', value),
                ),
                const SizedBox(height: 20),

                // Font Size Slider
                ConfigSlider(
                  label: AppStrings.fontSize,
                  value: _fontSize,
                  min: 12,
                  max: 24,
                  onChanged: (value) => _updateValue('fontSize', value),
                ),
                const SizedBox(height: 20),

                // Alignment
                AlignmentPicker(
                  currentAlignment: _align,
                  onChanged: (value) => _updateValue('align', value),
                ),
                const SizedBox(height: 20),

                // Color Picker
                ColorPickerCard(
                  label: 'Textfarbe',
                  currentColor: _color,
                  onColorChanged: (color) => _updateValue('color', color),
                  showColorPickerDialog: showColorPickerDialog,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

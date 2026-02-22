import 'package:flutter/material.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/core/constants/app_strings.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/alignment_picker.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/config_dropdown.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/config_text_field.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/live_preview_container.dart';
import 'package:rememberme/presentation/widgets/page_builder/color_picker_card.dart';
import 'package:rememberme/presentation/widgets/common/custom_color_picker_dialog.dart';

class HeaderSettings extends StatefulWidget {
  final Map<String, dynamic> content;
  final ValueChanged<String> onValueChanged;

  const HeaderSettings({
    super.key,
    required this.content,
    required this.onValueChanged,
  });

  @override
  State<HeaderSettings> createState() => _HeaderSettingsState();
}

class _HeaderSettingsState extends State<HeaderSettings> {
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

  int _getInt(String key, [int defaultValue = 1]) {
    final value = widget.content[key];
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  String get _text => _getString('text');
  int get _level => _getInt('level', 1);
  String get _align => _getString('align', 'left');
  String get _color => _getString('color', '#000000');

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
    final fontSizes = {1: 28.0, 2: 22.0, 3: 18.0};
    final fontSize = fontSizes[_level] ?? 28.0;

    return Column(
      children: [
        // ===== STICKY: Live Preview oben fixiert =====
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: LivePreviewContainer(
            child: Text(
              _text.isEmpty ? 'Überschrift Vorschau' : _text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: _text.isEmpty ? AppColors.grey : _hexToColor(_color),
                height: 1.3,
              ),
              textAlign: _align == 'center'
                  ? TextAlign.center
                  : _align == 'right'
                      ? TextAlign.right
                      : TextAlign.left,
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
                  label: AppStrings.headerPlaceholder,
                  controller: _textController,
                  hint: 'Überschrift eingeben',
                  maxLines: 2,
                  onChanged: (value) => _updateValue('text', value),
                ),
                const SizedBox(height: 20),

                // Size Dropdown
                ConfigDropdown<int>(
                  label: AppStrings.size,
                  value: _level,
                  items: {
                    1: AppStrings.sizeH1,
                    2: AppStrings.sizeH2,
                    3: AppStrings.sizeH3,
                  },
                  onChanged: (value) {
                    if (value != null) _updateValue('level', value);
                  },
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

import 'package:flutter/material.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/core/constants/app_strings.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/config_text_field.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/live_preview_container.dart';
import 'package:rememberme/presentation/widgets/page_builder/color_picker_card.dart';
import 'package:rememberme/presentation/widgets/common/custom_color_picker_dialog.dart';

class QuoteSettings extends StatefulWidget {
  final Map<String, dynamic> content;
  final ValueChanged<String> onValueChanged;

  const QuoteSettings({
    super.key,
    required this.content,
    required this.onValueChanged,
  });

  @override
  State<QuoteSettings> createState() => _QuoteSettingsState();
}

class _QuoteSettingsState extends State<QuoteSettings> {
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

  String get _text => _getString('text');
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Zitat-Strich links
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: _text.isEmpty
                            ? AppColors.grey
                            : _hexToColor(_color),
                        width: 3,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 14),
                  child: Text(
                    _text.isEmpty
                        ? '„Dein Zitat wird hier angezeigt..."'
                        : '„$_text"',
                    style: TextStyle(
                      fontSize: 17,
                      fontStyle: FontStyle.italic,
                      color:
                          _text.isEmpty ? AppColors.grey : _hexToColor(_color),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
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
                // Quote Text
                ConfigTextField(
                  label: AppStrings.quote,
                  controller: _textController,
                  hint: 'Zitat eingeben...',
                  maxLines: 4,
                  onChanged: (value) => _updateValue('text', value),
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

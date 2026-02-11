import 'package:flutter/material.dart';
import 'package:rememberme/core/constants/app_strings.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/config_text_field.dart';
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
  late TextEditingController _authorController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.content['text'] ?? '');
    _authorController =
        TextEditingController(text: widget.content['author'] ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  void _updateValue(String key, dynamic value) {
    widget.onValueChanged('$key:${value.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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

        // Author
        ConfigTextField(
          label: AppStrings.author,
          controller: _authorController,
          hint: 'Autor (optional)',
          onChanged: (value) => _updateValue('author', value),
        ),
        const SizedBox(height: 20),

        // Color Picker
        ColorPickerCard(
          label: 'Textfarbe',
          currentColor: widget.content['color'] ?? '#333333',
          onColorChanged: (color) => _updateValue('color', color),
          showColorPickerDialog: showColorPickerDialog,
        ),
      ],
    );
  }
}

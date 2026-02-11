import 'package:flutter/material.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/config_slider.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/config_text_field.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/layout_picker.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/upload_button.dart';
import 'package:rememberme/presentation/widgets/page_builder/color_picker_card.dart';
import 'package:rememberme/presentation/widgets/common/custom_color_picker_dialog.dart';

class ImageTextSettings extends StatefulWidget {
  final Map<String, dynamic> content;
  final ValueChanged<String> onValueChanged;
  final Future<String?> Function() onUploadImage;
  final bool isUploading;

  const ImageTextSettings({
    super.key,
    required this.content,
    required this.onValueChanged,
    required this.onUploadImage,
    required this.isUploading,
  });

  @override
  State<ImageTextSettings> createState() => _ImageTextSettingsState();
}

class _ImageTextSettingsState extends State<ImageTextSettings> {
  late TextEditingController _titleController;
  late TextEditingController _textController;
  late TextEditingController _captionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _getString('title'));
    _textController = TextEditingController(text: _getString('text'));
    _captionController =
        TextEditingController(text: _getString('imageCaption'));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _captionController.dispose();
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

  String get _imageUrl => _getString('imageUrl');
  String get _layout => _getString('layout', 'left');
  double get _imageSize => _getDouble('imageSize', 0.4);
  String get _color => _getString('color', '#333333');

  void _updateValue(String key, dynamic value) {
    widget.onValueChanged('$key:${value.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Preview
        if (_imageUrl.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              _imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.toastBackgroundDark
                      : AppColors.greyLighter,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.broken_image_rounded,
                    size: 64, color: AppColors.grey),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Upload Button
        UploadButton(
          onPressed: widget.isUploading ? null : widget.onUploadImage,
          isUploading: widget.isUploading,
          label: widget.isUploading
              ? 'Wird hochgeladen...'
              : _imageUrl.isEmpty
                  ? 'Bild hochladen'
                  : 'Bild ersetzen',
        ),
        const SizedBox(height: 24),

        // Title
        ConfigTextField(
          label: 'Titel (optional)',
          controller: _titleController,
          hint: 'z.B. "Eine besondere Erinnerung"',
          onChanged: (value) => _updateValue('title', value),
        ),
        const SizedBox(height: 20),

        // Text
        ConfigTextField(
          label: 'Text',
          controller: _textController,
          hint: 'Text eingeben...',
          maxLines: 6,
          onChanged: (value) => _updateValue('text', value),
        ),
        const SizedBox(height: 20),

        // Image Caption
        ConfigTextField(
          label: 'Bildunterschrift (optional)',
          controller: _captionController,
          hint: 'Kurze Beschreibung des Bildes',
          onChanged: (value) => _updateValue('imageCaption', value),
        ),
        const SizedBox(height: 24),

        // Color Picker
        ColorPickerCard(
          label: 'Textfarbe',
          currentColor: _color,
          onColorChanged: (color) => _updateValue('color', color),
          showColorPickerDialog: showColorPickerDialog,
        ),
        const SizedBox(height: 24),

        // Layout Picker
        LayoutPicker(
          currentLayout: _layout,
          onChanged: (layout) => _updateValue('layout', layout),
        ),
        const SizedBox(height: 24),

        // Image Size Slider (only for left/right layout)
        if (_layout == 'left' || _layout == 'right') ...[
          ConfigSlider(
            label: 'Bildbreite',
            value: _imageSize,
            min: 0.3,
            max: 0.7,
            onChanged: (value) => _updateValue('imageSize', value),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Bestimmt das Verhältnis zwischen Bild und Text (${(_imageSize * 100).round()}% Bild)',
              style: TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ),
        ],
      ],
    );
  }
}

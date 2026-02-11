import 'package:flutter/material.dart';
import 'package:rememberme/core/constants/app_strings.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/config_text_field.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/upload_button.dart';

class ImageSettings extends StatefulWidget {
  final Map<String, dynamic> content;
  final ValueChanged<String> onValueChanged;
  final Future<String?> Function() onUploadImage;
  final bool isUploading;

  const ImageSettings({
    super.key,
    required this.content,
    required this.onValueChanged,
    required this.onUploadImage,
    required this.isUploading,
  });

  @override
  State<ImageSettings> createState() => _ImageSettingsState();
}

class _ImageSettingsState extends State<ImageSettings> {
  late TextEditingController _captionController;

  @override
  void initState() {
    super.initState();
    _captionController =
        TextEditingController(text: widget.content['caption'] ?? '');
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  String get _url => widget.content['url'] ?? '';

  void _updateValue(String key, dynamic value) {
    widget.onValueChanged('$key:${value.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Preview
        if (_url.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              _url,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Upload Button
        UploadButton(
          onPressed: widget.isUploading ? null : widget.onUploadImage,
          isUploading: widget.isUploading,
          label: widget.isUploading
              ? AppStrings.uploading
              : AppStrings.uploadImage,
        ),
        const SizedBox(height: 20),

        // Caption Field
        ConfigTextField(
          label: AppStrings.imageCaption,
          controller: _captionController,
          hint: 'Bildunterschrift (optional)',
          maxLines: 2,
          onChanged: (value) => _updateValue('caption', value),
        ),
      ],
    );
  }
}

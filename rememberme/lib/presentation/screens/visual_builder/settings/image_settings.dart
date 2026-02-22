import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/core/constants/app_strings.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/config_text_field.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/info_text.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/live_preview_container.dart';
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
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _captionController =
        TextEditingController(text: widget.content['caption'] ?? '');
    _descriptionController =
        TextEditingController(text: widget.content['description'] ?? '');
  }

  @override
  void dispose() {
    _captionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String get _url => widget.content['url'] ?? '';

  void _updateValue(String key, dynamic value) {
    widget.onValueChanged('$key:${value.toString()}');
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // ===== STICKY: Live Preview oben fixiert =====
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: LivePreviewContainer(
            child: _url.isNotEmpty
                ? _buildImagePreview(isDark)
                : _buildEmptyPreview(isDark),
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
                // Upload Button
                UploadButton(
                  onPressed: widget.isUploading ? null : widget.onUploadImage,
                  isUploading: widget.isUploading,
                  label: widget.isUploading
                      ? AppStrings.uploading
                      : _url.isEmpty
                          ? AppStrings.uploadImage
                          : 'Bild ersetzen',
                ),
                const SizedBox(height: 20),

                ConfigTextField(
                  label: AppStrings.imageCaption,
                  controller: _captionController,
                  hint: 'z.B. "Sommer 2019 in Italien"',
                  onChanged: (value) {
                    _updateValue('caption', value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),

                // Beschreibung
                ConfigTextField(
                  label: 'Beschreibung (optional)',
                  controller: _descriptionController,
                  hint: 'z.B. "Ein unvergesslicher Tag am Strand"',
                  maxLines: 3,
                  onChanged: (value) {
                    _updateValue('description', value);
                    setState(() {});
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Live Preview – Leer
  // ============================================================

  Widget _buildEmptyPreview(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Platform.isIOS ? CupertinoIcons.photo : Icons.image_rounded,
            size: 36,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 10),
          Text(
            'Kein Bild',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey.withOpacity(0.7),
              fontWeight: FontWeight.w500,
              fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Live Preview – Bild mit Caption + Description
  // ============================================================

  Widget _buildImagePreview(bool isDark) {
    final caption = _captionController.text;
    final description = _descriptionController.text;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bild
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            _url,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 120,
                color: isDark
                    ? AppColors.toastBackgroundDark
                    : AppColors.greyLighter,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? AppColors.accent : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              height: 120,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.toastBackgroundDark
                    : AppColors.greyLighter,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  Icons.broken_image_rounded,
                  size: 32,
                  color: AppColors.grey,
                ),
              ),
            ),
          ),
        ),

        // Caption
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            caption,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],

        // Beschreibung
        if (description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.grey,
              fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

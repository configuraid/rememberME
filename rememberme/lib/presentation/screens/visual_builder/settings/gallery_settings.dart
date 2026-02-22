import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/core/constants/app_strings.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/config_dropdown.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/display_mode_picker.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/live_preview_container.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/upload_button.dart';

class GallerySettings extends StatefulWidget {
  final Map<String, dynamic> content;
  final ValueChanged<String> onValueChanged;
  final Future<List<String>?> Function() onUploadImages;
  final Function(int) onRemoveImage;
  final bool isUploading;

  const GallerySettings({
    super.key,
    required this.content,
    required this.onValueChanged,
    required this.onUploadImages,
    required this.onRemoveImage,
    required this.isUploading,
  });

  @override
  State<GallerySettings> createState() => _GallerySettingsState();
}

class _GallerySettingsState extends State<GallerySettings> {
  @override
  void dispose() {
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

  int _getInt(String key, [int defaultValue = 0]) {
    final value = widget.content[key];
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  List<String> _getStringList(String key) {
    final value = widget.content[key];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  List<String> get _images => _getStringList('images');
  String get _displayMode => _getString('displayMode', 'grid');
  int get _columns => _getInt('columns', 3);

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
            child: _buildGalleryPreview(isDark),
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
                  onPressed: widget.isUploading
                      ? null
                      : (_images.length < 6 ? widget.onUploadImages : null),
                  isUploading: widget.isUploading,
                  label: widget.isUploading
                      ? AppStrings.uploading
                      : _images.length < 6
                          ? '${AppStrings.addImages} (${6 - _images.length}${AppStrings.remaining})'
                          : AppStrings.maxReachedGallery,
                ),
                const SizedBox(height: 24),

                // Display Mode Picker
                DisplayModePicker(
                  currentMode: _displayMode,
                  onChanged: (mode) => _updateValue('displayMode', mode),
                ),
                const SizedBox(height: 20),

                // Columns dropdown (only for grid mode)
                if (_displayMode == 'grid')
                  ConfigDropdown<int>(
                    label: AppStrings.columns,
                    value: _columns,
                    items: {
                      2: AppStrings.columns2,
                      3: AppStrings.columns3,
                      4: AppStrings.columns4,
                    },
                    onChanged: (value) {
                      if (value != null) _updateValue('columns', value);
                    },
                  ),

                // Hochgeladene Bilder verwalten
                if (_images.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildImageManager(isDark),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Live Preview – Galerie (schematisch wie ImageTextSettings)
  // ============================================================

  Widget _buildGalleryPreview(bool isDark) {
    final accentColor = isDark ? AppColors.accent : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Modus-Label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _displayMode == 'grid'
                    ? (Platform.isIOS
                        ? CupertinoIcons.square_grid_2x2
                        : Icons.grid_view_rounded)
                    : (Platform.isIOS
                        ? CupertinoIcons.rectangle_on_rectangle
                        : Icons.view_carousel_rounded),
                size: 14,
                color: accentColor,
              ),
              const SizedBox(width: 6),
              Text(
                _displayMode == 'grid' ? 'Grid · $_columns Spalten' : 'Slider',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                  fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_images.length}/6 Bilder',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.grey,
                  fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Schematische Vorschau
          if (_displayMode == 'grid')
            _buildSchematicGrid(isDark, accentColor)
          else
            _buildSchematicSlider(isDark, accentColor),
        ],
      ),
    );
  }

  // ============================================================
  // Schematisches Grid (kleine zentrierte Kästchen)
  // ============================================================

  Widget _buildSchematicGrid(bool isDark, Color accentColor) {
    final count = _images.isNotEmpty ? _images.length : 6;
    final rows = (count / _columns).ceil();
    final cellSize = 18.0;
    final spacing = 3.0;

    return SizedBox(
      height: rows * cellSize + (rows - 1) * spacing,
      child: Center(
        child: SizedBox(
          width: _columns * cellSize + (_columns - 1) * spacing,
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: WrapAlignment.center,
            children: List.generate(count, (index) {
              final isFilled = index < _images.length;
              return Container(
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  color: isFilled
                      ? accentColor.withOpacity(0.15)
                      : (isDark
                          ? AppColors.backgroundDarkElevated
                          : AppColors.greyLighter.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: isFilled
                        ? accentColor.withOpacity(0.4)
                        : (isDark
                            ? AppColors.borderDark
                            : AppColors.greyLighter),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isFilled ? Icons.image_rounded : Icons.add_rounded,
                    size: 9,
                    color: isFilled
                        ? accentColor.withOpacity(0.7)
                        : AppColors.grey.withOpacity(0.3),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Schematischer Slider (kleine zentrierte Karten + Dots)
  // ============================================================

  Widget _buildSchematicSlider(bool isDark, Color accentColor) {
    final count = _images.isNotEmpty ? _images.length : 3;
    final cardWidth = 32.0;
    final cardHeight = 22.0;
    final spacing = 4.0;

    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(count, (index) {
                final isFilled = index < _images.length;
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : spacing,
                  ),
                  child: Container(
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      color: isFilled
                          ? accentColor.withOpacity(0.15)
                          : (isDark
                              ? AppColors.backgroundDarkElevated
                              : AppColors.greyLighter.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: isFilled
                            ? accentColor.withOpacity(0.4)
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.greyLighter),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isFilled ? Icons.image_rounded : Icons.add_rounded,
                        size: 10,
                        color: isFilled
                            ? accentColor.withOpacity(0.7)
                            : AppColors.grey.withOpacity(0.3),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            count,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: index == 0 ? 8 : 4,
              height: 4,
              decoration: BoxDecoration(
                color: index == 0 ? accentColor : accentColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Bildverwaltung (Löschen per Bild)
  // ============================================================

  Widget _buildImageManager(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hochgeladene Bilder (${_images.length}/6)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
            fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal scrollable image list with delete
        SizedBox(
          height: 88,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index < _images.length - 1 ? 10 : 0,
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        _images[index],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.toastBackgroundDark
                                  : AppColors.greyLighter,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isDark
                                        ? AppColors.accent
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.toastBackgroundDark
                                : AppColors.greyLighter,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: AppColors.grey,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    // Delete button
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => widget.onRemoveImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            Platform.isIOS
                                ? CupertinoIcons.xmark
                                : Icons.close_rounded,
                            size: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

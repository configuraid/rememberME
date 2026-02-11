import 'package:flutter/material.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/core/constants/app_strings.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/config_dropdown.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/display_mode_picker.dart';
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
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _sliderIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_images.isNotEmpty) ...[
          Text(
            '${AppStrings.galleryLabel} (${_images.length}/6)',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Preview based on display mode
          if (_displayMode == 'grid')
            _buildGridPreview(isDark)
          else
            _buildSliderPreview(isDark),

          const SizedBox(height: 20),
        ],

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
      ],
    );
  }

  Widget _buildGridPreview(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: isDark
                        ? AppColors.toastBackgroundDark
                        : AppColors.greyLighter,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? AppColors.accent : AppColors.primary,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: isDark
                      ? AppColors.toastBackgroundDark
                      : AppColors.greyLighter,
                  child:
                      Icon(Icons.broken_image_rounded, color: AppColors.grey),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => widget.onRemoveImage(index),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSliderPreview(bool isDark) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _sliderIndex = index;
              });
            },
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        _images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.toastBackgroundDark
                                  : AppColors.greyLighter,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? AppColors.accent : AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.toastBackgroundDark
                                : AppColors.greyLighter,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.broken_image_rounded,
                            size: 48,
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                    ),
                    // Delete Button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          final currentLength = _images.length;
                          widget.onRemoveImage(index);
                          if (_sliderIndex >= currentLength - 1 &&
                              _sliderIndex > 0) {
                            setState(() {
                              _sliderIndex--;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ),
                    // Image number badge
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${index + 1}/${_images.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
        const SizedBox(height: 12),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _images.length,
            (index) => GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _sliderIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _sliderIndex == index
                      ? (isDark ? AppColors.accent : AppColors.primary)
                      : (isDark
                          ? AppColors.accent.withOpacity(0.3)
                          : AppColors.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

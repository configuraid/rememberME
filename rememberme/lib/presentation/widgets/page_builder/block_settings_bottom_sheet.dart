import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rememberme/data/models/content_block_model.dart';
import 'package:rememberme/data/services/firebase_storage_service.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/core/constants/app_strings.dart';

class BlockSettingsBottomSheet extends StatefulWidget {
  final ContentBlock block;
  final String memorialId;
  final Function(String key, dynamic value) onUpdate;

  const BlockSettingsBottomSheet({
    super.key,
    required this.block,
    required this.memorialId,
    required this.onUpdate,
  });

  @override
  State<BlockSettingsBottomSheet> createState() =>
      _BlockSettingsBottomSheetState();
}

class _BlockSettingsBottomSheetState extends State<BlockSettingsBottomSheet> {
  late Map<String, TextEditingController> _controllers;
  late Map<String, dynamic> _localContent;

  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _localContent = Map.from(widget.block.content);
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  void didUpdateWidget(BlockSettingsBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.block != widget.block) {
      _localContent = Map.from(widget.block.content);

      _controllers.forEach((key, controller) {
        final newValue = _localContent[key];
        if (newValue != null && controller.text != newValue.toString()) {
          controller.text = newValue.toString();
        }
      });
    }
  }

  void _updateValue(String key, dynamic value) {
    setState(() {
      _localContent[key] = value;
    });
    widget.onUpdate(key, value);
  }

  T _getContent<T>(String key, T defaultValue) {
    return (_localContent[key] ?? defaultValue) as T;
  }

  TextEditingController _getController(String key, String defaultValue) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(
        text: _getContent(key, defaultValue),
      );
    }
    return _controllers[key]!;
  }

  Future<void> _handleImageUpload() async {
    if (_isUploading) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final String downloadUrl = await _storageService.uploadBlockImage(
        memorialId: widget.memorialId,
        blockId: widget.block.id,
        imageFile: File(image.path),
      );

      _updateValue('url', downloadUrl);

      if (mounted) {
        _showSuccessSnackBar(AppStrings.imageUploadSuccess);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(AppStrings.uploadError, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _handleGalleryImagesUpload() async {
    if (_isUploading) return;

    try {
      final List<String> currentImages = List<String>.from(
        _getContent<List>('images', []),
      );

      final int remaining = 6 - currentImages.length;

      if (remaining <= 0) {
        _showErrorDialog(
          AppStrings.maxReached,
          AppStrings.maxGalleryImages,
        );
        return;
      }

      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isEmpty) return;

      final imagesToUpload = images.take(remaining).toList();

      if (images.length > remaining) {
        _showErrorDialog(
          AppStrings.tooManyImages,
          'Du kannst nur noch $remaining ${remaining == 1 ? AppStrings.image : AppStrings.images} hinzufügen. Die ersten $remaining werden hochgeladen.',
        );
      }

      setState(() => _isUploading = true);

      final List<File> imageFiles =
          imagesToUpload.map((xfile) => File(xfile.path)).toList();

      final List<String> downloadUrls =
          await _storageService.uploadGalleryImages(
        memorialId: widget.memorialId,
        blockId: widget.block.id,
        imageFiles: imageFiles,
      );

      final updatedImages = [...currentImages, ...downloadUrls];
      _updateValue('images', updatedImages);

      if (mounted) {
        _showSuccessSnackBar(
          '${downloadUrls.length} ${downloadUrls.length == 1 ? AppStrings.image : AppStrings.images}${AppStrings.uploadedSuccessfully}',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(AppStrings.uploadError, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _removeGalleryImage(int index) {
    final List<String> currentImages = List<String>.from(
      _getContent<List>('images', []),
    );

    if (index >= 0 && index < currentImages.length) {
      currentImages.removeAt(index);
      _updateValue('images', currentImages);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (Platform.isIOS) {
      final brightness = MediaQuery.of(context).platformBrightness;
      final isDark = brightness == Brightness.dark;

      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => CupertinoAlertDialog(
          content: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              fontFamily: '.SF Pro Text',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                AppStrings.ok,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.5)
                      : Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.success.withOpacity(0.2),
                        AppColors.success.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 48,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  void _showErrorDialog(String title, String message) {
    if (Platform.isIOS) {
      final brightness = MediaQuery.of(context).platformBrightness;
      final isDark = brightness == Brightness.dark;

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
              fontFamily: '.SF Pro Text',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                AppStrings.ok,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? AppColors.error.withOpacity(0.3)
                    : Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.5)
                      : Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.error.withOpacity(0.2),
                        AppColors.error.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.error_rounded,
                    size: 56,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? const Color(0xFFB0B0B0)
                              : AppColors.textSecondary,
                          height: 1.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppStrings.ok,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark
                  ? AppColors.primaryLight.withOpacity(0.2)
                  : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF404040) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  AppColors.primaryLight.withOpacity(0.25),
                                  AppColors.primaryLight.withOpacity(0.15),
                                ]
                              : [
                                  AppColors.primary.withOpacity(0.15),
                                  AppColors.primary.withOpacity(0.08),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.primaryLight.withOpacity(0.3)
                              : AppColors.primary.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        BlockTypeInfo.getIcon(
                            widget.block.type), // ✅ NEUE METHODE
                        size: 24,
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${BlockTypeInfo.getTitle(widget.block.type)}${AppStrings.editBlock}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark
                              ? const Color(0xFF909090)
                              : Colors.grey.shade600,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: _buildSettings(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildSettings() {
    switch (widget.block.type) {
      case ContentBlockType.header:
        return _buildHeaderSettings();
      case ContentBlockType.text:
        return _buildTextSettings();
      case ContentBlockType.image:
        return _buildImageSettings();
      case ContentBlockType.gallery:
        return _buildGallerySettings();
      case ContentBlockType.quote:
        return _buildQuoteSettings();
      case ContentBlockType.divider:
        return _buildDividerSettings();
      case ContentBlockType.video:
        return _buildVideoSettings();
      case ContentBlockType.date:
        return _buildDateSettings();
    }
  }

  List<Widget> _buildHeaderSettings() {
    return [
      _buildTextField(
        label: AppStrings.headerPlaceholder,
        key: 'text',
        defaultValue: AppStrings.headerInput,
        maxLines: 2,
      ),
      const SizedBox(height: 20),
      _buildDropdown(
        label: AppStrings.size,
        key: 'level',
        value: _getContent('level', 1),
        items: {
          1: AppStrings.sizeH1,
          2: AppStrings.sizeH2,
          3: AppStrings.sizeH3,
        },
      ),
      const SizedBox(height: 20),
      _buildAlignmentPicker('align'),
      const SizedBox(height: 20),
      _buildColorPicker('color', AppStrings.textColor),
    ];
  }

  List<Widget> _buildTextSettings() {
    return [
      _buildTextField(
        label: AppStrings.text,
        key: 'text',
        defaultValue: AppStrings.textPlaceholder,
        maxLines: 10,
      ),
      const SizedBox(height: 20),
      _buildSlider(
        label: AppStrings.fontSize,
        key: 'fontSize',
        min: 12,
        max: 24,
        value: _getContent('fontSize', 16.0),
      ),
      const SizedBox(height: 20),
      _buildAlignmentPicker('align'),
      const SizedBox(height: 20),
      _buildColorPicker('color', AppStrings.textColor),
    ];
  }

  List<Widget> _buildImageSettings() {
    final currentUrl = _getContent('url', '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return [
      if (currentUrl.isNotEmpty) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            currentUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.broken_image_rounded,
                size: 64,
                color: isDark ? const Color(0xFF404040) : Colors.grey.shade400,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
      Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: _isUploading
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.primaryLight,
                          AppColors.primaryLight.withOpacity(0.85),
                        ]
                      : [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.9),
                        ],
                ),
          color: _isUploading
              ? (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300)
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isUploading
              ? []
              : [
                  BoxShadow(
                    color: isDark
                        ? AppColors.primaryLight.withOpacity(0.3)
                        : AppColors.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isUploading ? null : _handleImageUpload,
          icon: _isUploading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.upload_rounded, size: 22),
          label: Text(
            _isUploading ? AppStrings.uploading : AppStrings.uploadImage,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.transparent,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      _buildTextField(
        label: AppStrings.imageCaption,
        key: 'caption',
        defaultValue: '',
        maxLines: 2,
      ),
    ];
  }

  List<Widget> _buildGallerySettings() {
    final List<String> images = List<String>.from(
      _getContent<List>('images', []),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return [
      if (images.isNotEmpty) ...[
        Text(
          '${AppStrings.galleryLabel} (${images.length}/6)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey.shade200,
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: isDark
                              ? const Color(0xFF404040)
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeGalleryImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.error,
                            Color(0xFFD32F2F),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
      ],

      // Upload Button
      Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: _isUploading || images.length >= 6
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.primaryLight,
                          AppColors.primaryLight.withOpacity(0.85),
                        ]
                      : [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.9),
                        ],
                ),
          color: _isUploading || images.length >= 6
              ? (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300)
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isUploading || images.length >= 6
              ? []
              : [
                  BoxShadow(
                    color: isDark
                        ? AppColors.primaryLight.withOpacity(0.3)
                        : AppColors.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isUploading
              ? null
              : (images.length < 6 ? _handleGalleryImagesUpload : null),
          icon: _isUploading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.add_photo_alternate_rounded, size: 22),
          label: Text(
            _isUploading
                ? AppStrings.uploading
                : images.length < 6
                    ? '${AppStrings.addImages} (${6 - images.length}${AppStrings.remaining})'
                    : AppStrings.maxReachedGallery,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor:
                isDark ? const Color(0xFF808080) : Colors.grey.shade500,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),

      const SizedBox(height: 20),

      _buildDropdown(
        label: AppStrings.columns,
        key: 'columns',
        value: _getContent('columns', 3),
        items: {
          2: AppStrings.columns2,
          3: AppStrings.columns3,
          4: AppStrings.columns4,
        },
      ),
    ];
  }

  List<Widget> _buildQuoteSettings() {
    return [
      _buildTextField(
        label: AppStrings.quote,
        key: 'text',
        defaultValue: AppStrings.quotePlaceholder,
        maxLines: 4,
      ),
      const SizedBox(height: 20),
      _buildTextField(
        label: AppStrings.author,
        key: 'author',
        defaultValue: '',
      ),
      const SizedBox(height: 20),
      _buildColorPicker('color', AppStrings.color),
    ];
  }

  List<Widget> _buildDividerSettings() {
    return [
      _buildSlider(
        label: AppStrings.thickness,
        key: 'thickness',
        min: 1,
        max: 5,
        value: _getContent('thickness', 1.0),
      ),
      const SizedBox(height: 20),
      _buildColorPicker('color', AppStrings.color),
    ];
  }

  // ✅ NEU: Video-Upload Handler mit Fortschrittsanzeige
  double _videoUploadProgress = 0.0;

  Future<void> _handleVideoUpload() async {
    if (_isUploading) return;

    try {
      // Video-Picker (verwendet image_picker für Videos)
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 15), // Max 15 Sekunden
      );

      if (video == null) return;

      // Prüfe Video-Länge (falls verfügbar)
      final videoFile = File(video.path);
      final fileSize = await videoFile.length();

      // Größen-Check (ca. 50MB für 15 Sekunden)
      if (fileSize > 50 * 1024 * 1024) {
        _showErrorDialog(
          AppStrings.uploadError,
          'Das Video ist zu groß. Bitte wähle ein kürzeres Video (max. 15 Sekunden).',
        );
        return;
      }

      setState(() {
        _isUploading = true;
        _videoUploadProgress = 0.0;
      });

      // Upload mit Fortschrittsanzeige
      final String downloadUrl = await _storageService.uploadBlockVideo(
        memorialId: widget.memorialId,
        blockId: widget.block.id,
        videoFile: videoFile,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _videoUploadProgress = progress;
            });
          }
        },
      );

      _updateValue('url', downloadUrl);

      if (mounted) {
        _showSuccessSnackBar('Video erfolgreich hochgeladen!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(AppStrings.uploadError, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _videoUploadProgress = 0.0;
        });
      }
    }
  }

  List<Widget> _buildVideoSettings() {
    final currentUrl = _getContent('url', '');
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    if (Platform.isIOS) {
      // ✅ iOS NATIVE UI
      return [
        // Video-Vorschau mit iOS-Style
        if (currentUrl.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFE5E5EA),
                      child: Center(
                        child: Icon(
                          CupertinoIcons.video_camera_solid,
                          size: 48,
                          color: isDark
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.systemGrey2,
                        ),
                      ),
                    ),
                    // Play Button Overlay
                    Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.black.withOpacity(0.3),
                      ),
                      child: Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: CupertinoColors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.play_fill,
                            size: 32,
                            color: CupertinoColors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // iOS List-Style Upload Section
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Upload Button
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                onPressed: _isUploading ? null : _handleVideoUpload,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _isUploading
                            ? (isDark
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFF2F2F7))
                            : AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isUploading
                          ? Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2,
                                  value: _videoUploadProgress,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            )
                          : Icon(
                              CupertinoIcons.videocam_fill,
                              size: 18,
                              color: AppColors.primary,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isUploading
                                ? 'Video wird hochgeladen...'
                                : currentUrl.isEmpty
                                    ? 'Video hochladen'
                                    : 'Video ersetzen',
                            style: TextStyle(
                              fontSize: 17,
                              color: isDark
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                          if (_isUploading)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${(_videoUploadProgress * 100).toInt()}% abgeschlossen',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: CupertinoColors.systemGrey,
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!_isUploading)
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 20,
                        color: CupertinoColors.systemGrey3,
                      ),
                  ],
                ),
              ),

              // Progress Bar (wenn Upload läuft)
              if (_isUploading)
                Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _videoUploadProgress,
                      backgroundColor: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFE5E5EA),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),

              if (_isUploading) const SizedBox(height: 12),

              // Divider
              Container(
                height: 0.5,
                margin: const EdgeInsets.only(left: 60),
                color:
                    isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8),
              ),

              // Info Row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        CupertinoIcons.info,
                        size: 18,
                        color: CupertinoColors.systemBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Max. 15 Sekunden • Max. 50 MB',
                        style: TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.systemGrey,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Beschreibung mit iOS TextField
        Text(
          'Beschreibung',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.systemGrey,
            fontFamily: '.SF Pro Text',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: CupertinoTextField(
            controller: _getController('caption', ''),
            placeholder: 'Optional',
            maxLines: 3,
            padding: const EdgeInsets.all(16),
            style: TextStyle(
              fontSize: 17,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              fontFamily: '.SF Pro Text',
            ),
            placeholderStyle: TextStyle(
              fontSize: 17,
              color: CupertinoColors.systemGrey3,
              fontFamily: '.SF Pro Text',
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            onChanged: (value) => _updateValue('caption', value),
          ),
        ),

        // Video löschen (falls vorhanden)
        if (currentUrl.isNotEmpty) ...[
          const SizedBox(height: 24),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              showCupertinoDialog(
                context: context,
                builder: (ctx) => CupertinoAlertDialog(
                  title: Text(
                    'Video entfernen?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  content: Text(
                    'Das Video wird dauerhaft gelöscht.',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: Text(
                        'Abbrechen',
                        style: TextStyle(
                          fontSize: 17,
                          color: AppColors.primary,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      child: Text(
                        'Entfernen',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                      onPressed: () {
                        _updateValue('url', '');
                        _storageService.deleteBlockVideo(
                          memorialId: widget.memorialId,
                          blockId: widget.block.id,
                        );
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Video entfernen',
                  style: TextStyle(
                    fontSize: 17,
                    color: CupertinoColors.systemRed,
                    fontFamily: '.SF Pro Text',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ];
    } else {
      return [
        if (currentUrl.isNotEmpty) ...[
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF404040) : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_filled,
                    size: 64,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Video hochgeladen',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tippe zum Abspielen',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFF808080)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Upload-Button mit Fortschrittsanzeige
        Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: _isUploading
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppColors.primaryLight,
                            AppColors.primaryLight.withOpacity(0.85),
                          ]
                        : [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.9),
                          ],
                  ),
            color: _isUploading
                ? (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300)
                : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isUploading
                ? []
                : [
                    BoxShadow(
                      color: isDark
                          ? AppColors.primaryLight.withOpacity(0.3)
                          : AppColors.primary.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              if (_isUploading)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: LinearProgressIndicator(
                      value: _videoUploadProgress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark
                            ? AppColors.primaryLight.withOpacity(0.3)
                            : AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _handleVideoUpload,
                icon: _isUploading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          value: _videoUploadProgress,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.videocam_rounded, size: 22),
                label: Text(
                  _isUploading
                      ? 'Uploading... ${(_videoUploadProgress * 100).toInt()}%'
                      : currentUrl.isEmpty
                          ? 'Video hochladen (max. 15 Sek.)'
                          : 'Video ersetzen',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: isDark ? const Color(0xFF808080) : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Maximale Länge: 15 Sekunden • Max. Größe: 50MB',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? const Color(0xFF808080) : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        _buildTextField(
          label: AppStrings.description,
          key: 'caption',
          defaultValue: '',
          maxLines: 2,
        ),

        if (currentUrl.isNotEmpty) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              _updateValue('url', '');
              _storageService.deleteBlockVideo(
                memorialId: widget.memorialId,
                blockId: widget.block.id,
              );
            },
            icon: const Icon(Icons.delete_outline, size: 20),
            label: const Text('Video entfernen'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ];
    }
  }

  List<Widget> _buildDateSettings() {
    return [
      _buildTextField(
        label: AppStrings.birthDate,
        key: 'birthDate',
        defaultValue: '',
        hint: AppStrings.dateFormat,
      ),
      const SizedBox(height: 20),
      _buildTextField(
        label: AppStrings.deathDate,
        key: 'deathDate',
        defaultValue: '',
        hint: AppStrings.dateFormat,
      ),
    ];
  }

  Widget _buildTextField({
    required String label,
    required String key,
    required String defaultValue,
    int maxLines = 1,
    String? hint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                letterSpacing: 0.15,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _getController(key, defaultValue),
            style: TextStyle(
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? const Color(0xFF707070) : Colors.grey.shade400,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            maxLines: maxLines,
            onChanged: (value) => _updateValue(key, value),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String key,
    required dynamic value,
    required Map<dynamic, String> items,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                letterSpacing: 0.15,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField(
            value: value,
            dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            style: TextStyle(
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            items: items.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                _updateValue(key, newValue);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required String key,
    required double min,
    required double max,
    required double value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    letterSpacing: 0.15,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.primaryLight.withOpacity(0.2),
                          AppColors.primaryLight.withOpacity(0.1),
                        ]
                      : [
                          AppColors.primary.withOpacity(0.12),
                          AppColors.primary.withOpacity(0.06),
                        ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? AppColors.primaryLight.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                value.round().toString(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor:
                isDark ? AppColors.primaryLight : AppColors.primary,
            inactiveTrackColor: isDark
                ? AppColors.primaryLight.withOpacity(0.3)
                : AppColors.primary.withOpacity(0.3),
            thumbColor: isDark ? AppColors.primaryLight : AppColors.primary,
            overlayColor: isDark
                ? AppColors.primaryLight.withOpacity(0.2)
                : AppColors.primary.withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: (newValue) {
              _updateValue(key, newValue);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlignmentPicker(String key) {
    final currentAlign = _getContent(key, 'left');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.alignment,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                letterSpacing: 0.15,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildAlignButton('left', Icons.format_align_left_rounded,
                currentAlign, key, isDark),
            const SizedBox(width: 12),
            _buildAlignButton('center', Icons.format_align_center_rounded,
                currentAlign, key, isDark),
            const SizedBox(width: 12),
            _buildAlignButton('right', Icons.format_align_right_rounded,
                currentAlign, key, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildAlignButton(
    String value,
    IconData icon,
    String currentAlign,
    String key,
    bool isDark,
  ) {
    final isSelected = currentAlign == value;

    return Expanded(
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.primaryLight.withOpacity(0.25),
                          AppColors.primaryLight.withOpacity(0.15),
                        ]
                      : [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.08),
                        ],
                )
              : null,
          color: !isSelected
              ? (isDark ? const Color(0xFF1E1E1E) : Colors.white)
              : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.primaryLight : AppColors.primary)
                : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _updateValue(key, value),
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Icon(
                icon,
                color: isSelected
                    ? (isDark ? AppColors.primaryLight : AppColors.primary)
                    : (isDark ? const Color(0xFF808080) : Colors.grey.shade600),
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker(String key, String label) {
    final currentColor = _getContent(key, '#000000');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                letterSpacing: 0.15,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            '#000000',
            '#333333',
            '#666666',
            '#2C3E50',
            '#E74C3C',
            '#3498DB',
            '#2ECC71',
            '#F39C12',
          ].map((color) {
            return _buildColorOption(color, currentColor, key, isDark);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorOption(
      String color, String currentColor, String key, bool isDark) {
    final isSelected = color == currentColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: _hexToColor(color).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _updateValue(key, color),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _hexToColor(color),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? (isDark ? AppColors.primaryLight : AppColors.primary)
                    : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300),
                width: isSelected ? 3 : 1.5,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                : null,
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}

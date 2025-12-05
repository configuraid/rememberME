import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
  late Map<String, dynamic> _originalContent;

  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  bool _isUploading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _localContent = Map.from(widget.block.content);
    _originalContent = Map.from(widget.block.content);
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
      _originalContent = Map.from(widget.block.content);

      _controllers.forEach((key, controller) {
        final newValue = _localContent[key];
        if (newValue != null && controller.text != newValue.toString()) {
          controller.text = newValue.toString();
        }
      });
    }
  }

  void _updateLocalValue(String key, dynamic value) {
    setState(() {
      _localContent[key] = value;
      _hasChanges = true;
    });
  }

  void _confirmChanges() {
    if (Platform.isIOS) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    _localContent.forEach((key, value) {
      widget.onUpdate(key, value);
    });

    Navigator.pop(context);
  }

  void _discardChanges() {
    if (_hasChanges) {
      _showDiscardDialog();
    } else {
      Navigator.pop(context);
    }
  }

  void _showDiscardDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            AppStrings.unsavedChanges,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Text(
            AppStrings.unsavedChangesMessage,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey,
              fontFamily: '.SF Pro Text',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                AppStrings.cancel,
                style: TextStyle(
                  fontSize: 17,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(
                AppStrings.discardChanges,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? AppColors.error.withOpacity(0.3)
                    : AppColors.greyLighter,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? AppColors.shadowDark
                      : AppColors.shadow.withOpacity(0.15),
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
                    color: AppColors.error.withOpacity(isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    size: 56,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    AppStrings.unsavedChanges,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    AppStrings.unsavedChangesMessage,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.grey,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.greyLight,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppStrings.cancel,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textLight
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: AppColors.textLight,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppStrings.discardChanges,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    }
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

      _updateLocalValue('url', downloadUrl);

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
      _updateLocalValue('images', updatedImages);

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
      _updateLocalValue('images', currentImages);
    }
  }

  void _showSuccessSnackBar(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => CupertinoAlertDialog(
          content: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
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
                  color: isDark ? AppColors.accent : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? AppColors.shadowDark
                      : AppColors.shadow.withOpacity(0.15),
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
                    color: AppColors.success.withOpacity(isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
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
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey,
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
                  color: isDark ? AppColors.accent : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? AppColors.error.withOpacity(0.3)
                    : AppColors.greyLighter,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? AppColors.shadowDark
                      : AppColors.shadow.withOpacity(0.15),
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
                    color: AppColors.error.withOpacity(isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
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
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.grey,
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
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.textLight,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppStrings.ok,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textLight,
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
    if (Platform.isIOS) {
      return _buildIOSLayout(context);
    }
    return _buildAndroidLayout(context);
  }

  // ============================================================
  // iOS Layout
  // ============================================================
  Widget _buildIOSLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            children: [
              // iOS-Style Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.greyLight,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              // iOS Navigation Bar Style Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.greyLight,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Abbrechen Button (X Icon)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 36,
                      onPressed: _discardChanges,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.accent : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.xmark,
                          size: 18,
                          color:
                              isDark ? AppColors.primary : AppColors.background,
                        ),
                      ),
                    ),

                    // Titel in der Mitte
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            BlockTypeInfo.getIcon(widget.block.type),
                            size: 20,
                            color:
                                isDark ? AppColors.accent : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              BlockTypeInfo.getTitle(widget.block.type),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textLight
                                    : AppColors.textPrimary,
                                fontFamily: '.SF Pro Text',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 36,
                      onPressed: _confirmChanges,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.accent : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.checkmark,
                          size: 18,
                          color:
                              isDark ? AppColors.primary : AppColors.background,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: _buildSettings(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // Android Layout
  // ============================================================
  Widget _buildAndroidLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.greyLighter,
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
                  color: isDark ? AppColors.borderDark : AppColors.greyLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.toastBackgroundDark
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.primary.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        BlockTypeInfo.getIcon(widget.block.type),
                        size: 24,
                        color: isDark ? AppColors.accent : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${BlockTypeInfo.getTitle(widget.block.type)}${AppStrings.editBlock}',
                        style: TextStyle(
                          fontSize: 22,
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
                            ? AppColors.toastBackgroundDark
                            : AppColors.greyLighter,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.grey,
                        ),
                        onPressed: _discardChanges,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? AppColors.borderDark : AppColors.greyLighter,
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: _buildSettings(),
                ),
              ),

              // Bottom Action Bar mit Bestätigen-Button
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  16 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDarkElevated
                      : AppColors.surface,
                  border: Border(
                    top: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.greyLighter,
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? AppColors.shadowDark : AppColors.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Abbrechen Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _discardChanges,
                        icon: const Icon(Icons.close_rounded, size: 20),
                        label: Text(AppStrings.cancel),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.greyLight,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Übernehmen Button
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _confirmChanges,
                        icon: const Icon(Icons.check_rounded, size: 22),
                        label: Text(
                          AppStrings.apply,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.textLight,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                color: isDark
                    ? AppColors.toastBackgroundDark
                    : AppColors.greyLighter,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.broken_image_rounded,
                size: 64,
                color: AppColors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
      SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _isUploading ? null : _handleImageUpload,
          icon: _isUploading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.textLight),
                  ),
                )
              : Icon(
                  Platform.isIOS
                      ? CupertinoIcons.cloud_upload
                      : Icons.upload_rounded,
                  size: 22,
                ),
          label: Text(
            _isUploading ? AppStrings.uploading : AppStrings.uploadImage,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: isDark ? AppColors.accent : AppColors.primary,
            foregroundColor: isDark ? AppColors.primary : AppColors.background,
            disabledBackgroundColor:
                isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter,
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
          style: TextStyle(
            fontSize: 17,
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
                      color:
                          isDark ? AppColors.borderDark : AppColors.greyLighter,
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
                            ? AppColors.toastBackgroundDark
                            : AppColors.greyLighter,
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: AppColors.grey,
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
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowDark,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Platform.isIOS
                            ? CupertinoIcons.xmark
                            : Icons.close_rounded,
                        size: 16,
                        color: AppColors.textLight,
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
      SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _isUploading
              ? null
              : (images.length < 6 ? _handleGalleryImagesUpload : null),
          icon: _isUploading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.textLight),
                  ),
                )
              : Icon(
                  Platform.isIOS
                      ? CupertinoIcons.photo_on_rectangle
                      : Icons.add_photo_alternate_rounded,
                  size: 22,
                ),
          label: Text(
            _isUploading
                ? AppStrings.uploading
                : images.length < 6
                    ? '${AppStrings.addImages} (${6 - images.length}${AppStrings.remaining})'
                    : AppStrings.maxReachedGallery,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: isDark ? AppColors.accent : AppColors.primary,
            foregroundColor: isDark ? AppColors.primary : AppColors.background,
            disabledBackgroundColor:
                isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter,
            disabledForegroundColor: AppColors.grey,
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

  double _videoUploadProgress = 0.0;

  Future<void> _handleVideoUpload() async {
    if (_isUploading) return;

    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 15),
      );

      if (video == null) return;

      final videoFile = File(video.path);
      final fileSize = await videoFile.length();

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

      _updateLocalValue('url', downloadUrl);

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
    final autoplay = _getContent('autoplay', false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      return [
        if (currentUrl.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDarkElevated
                  : AppColors.background,
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
                          ? AppColors.toastBackgroundDark
                          : AppColors.greyLighter,
                      child: Center(
                        child: Icon(
                          CupertinoIcons.video_camera_solid,
                          size: 48,
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDark.withOpacity(0.3),
                      ),
                      child: Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.play_fill,
                            size: 32,
                            color: AppColors.textPrimary,
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
        Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
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
                                ? AppColors.toastBackgroundDark
                                : AppColors.background)
                            : (isDark
                                ? AppColors.toastBackgroundDark
                                : AppColors.primary.withOpacity(0.1)),
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
                                    isDark
                                        ? AppColors.accent
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            )
                          : Icon(
                              CupertinoIcons.videocam_fill,
                              size: 18,
                              color:
                                  isDark ? AppColors.accent : AppColors.primary,
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
                                  ? AppColors.textLight
                                  : AppColors.textPrimary,
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
                                  color: AppColors.grey,
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
                        color: AppColors.grey,
                      ),
                  ],
                ),
              ),
              if (_isUploading)
                Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _videoUploadProgress,
                      backgroundColor: isDark
                          ? AppColors.toastBackgroundDark
                          : AppColors.greyLighter,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? AppColors.accent : AppColors.primary),
                    ),
                  ),
                ),
              if (_isUploading) const SizedBox(height: 12),
              Container(
                height: 0.5,
                margin: const EdgeInsets.only(left: 60),
                color: isDark ? AppColors.borderDark : AppColors.greyLight,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        CupertinoIcons.info,
                        size: 18,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Max. 15 Sekunden • Max. 50 MB',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.grey,
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
        _buildIOSAutoplayToggle(isDark, autoplay),
        const SizedBox(height: 24),
        Text(
          'Beschreibung',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.grey,
            fontFamily: '.SF Pro Text',
            fontWeight: FontWeight.w600,
            letterSpacing: -0.08,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.greyLight,
              width: 1,
            ),
          ),
          child: CupertinoTextField(
            controller: _getController('caption', ''),
            placeholder: 'Optional',
            maxLines: 3,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            style: TextStyle(
              fontSize: 17,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
            placeholderStyle: TextStyle(
              fontSize: 17,
              color: AppColors.grey,
              fontFamily: '.SF Pro Text',
            ),
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            onChanged: (value) => _updateLocalValue('caption', value),
          ),
        ),
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
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  content: Text(
                    'Das Video wird dauerhaft gelöscht.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: Text(
                        'Abbrechen',
                        style: TextStyle(
                          fontSize: 17,
                          color: isDark ? AppColors.accent : AppColors.primary,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      child: const Text(
                        'Entfernen',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                      onPressed: () {
                        _updateLocalValue('url', '');
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
                color: isDark
                    ? AppColors.backgroundDarkElevated
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Video entfernen',
                  style: TextStyle(
                    fontSize: 17,
                    color: AppColors.error,
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
      // Android Video Settings
      return [
        if (currentUrl.isNotEmpty) ...[
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.toastBackgroundDark
                  : AppColors.greyLighter,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.greyLight,
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
                    color: isDark ? AppColors.accent : AppColors.primary,
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
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        SizedBox(
          height: 56,
          width: double.infinity,
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
                            ? AppColors.accent.withOpacity(0.3)
                            : AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isUploading ? null : _handleVideoUpload,
                  icon: _isUploading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            value: _videoUploadProgress,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.textLight),
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
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.accent : AppColors.primary,
                    foregroundColor:
                        isDark ? AppColors.primary : AppColors.background,
                    disabledBackgroundColor: isDark
                        ? AppColors.toastBackgroundDark
                        : AppColors.greyLighter,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                color: AppColors.grey,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Maximale Länge: 15 Sekunden • Max. Größe: 50MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildAndroidAutoplayToggle(isDark, autoplay),
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
              _updateLocalValue('url', '');
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

  Widget _buildIOSAutoplayToggle(bool isDark, bool autoplay) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: autoplay
                    ? AppColors.success.withOpacity(0.15)
                    : AppColors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                autoplay
                    ? CupertinoIcons.play_circle_fill
                    : CupertinoIcons.play_circle,
                size: 18,
                color: autoplay ? AppColors.success : AppColors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Autoplay',
                    style: TextStyle(
                      fontSize: 17,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  Text(
                    autoplay
                        ? 'Video startet automatisch'
                        : 'Video muss manuell gestartet werden',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: autoplay,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                _updateLocalValue('autoplay', value);
              },
              activeColor: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidAutoplayToggle(bool isDark, bool autoplay) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: autoplay
              ? AppColors.success.withOpacity(0.5)
              : (isDark ? AppColors.borderDark : AppColors.greyLighter),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowDark : AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            _updateLocalValue('autoplay', !autoplay);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: autoplay
                        ? AppColors.success.withOpacity(isDark ? 0.2 : 0.1)
                        : (isDark
                            ? AppColors.toastBackgroundDark
                            : AppColors.greyLighter),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: autoplay
                          ? AppColors.success.withOpacity(0.3)
                          : (isDark
                              ? AppColors.borderDark
                              : AppColors.greyLight),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    autoplay
                        ? Icons.play_circle_filled_rounded
                        : Icons.play_circle_outline_rounded,
                    size: 24,
                    color: autoplay ? AppColors.success : AppColors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Autoplay',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        autoplay
                            ? 'Video startet automatisch beim Laden'
                            : 'Video muss manuell gestartet werden',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: autoplay,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    _updateLocalValue('autoplay', value);
                  },
                  activeColor: AppColors.success,
                  activeTrackColor: AppColors.success.withOpacity(0.4),
                  inactiveThumbColor: AppColors.grey,
                  inactiveTrackColor: isDark
                      ? AppColors.toastBackgroundDark
                      : AppColors.greyLighter,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String key,
    required String defaultValue,
    int maxLines = 1,
    String? hint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey,
              fontFamily: '.SF Pro Text',
              fontWeight: FontWeight.w600,
              letterSpacing: -0.08,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.greyLight,
                width: 1,
              ),
            ),
            child: CupertinoTextField(
              controller: _getController(key, defaultValue),
              placeholder: hint ?? label,
              maxLines: maxLines,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              style: TextStyle(
                fontSize: 17,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                fontFamily: '.SF Pro Text',
              ),
              placeholderStyle: TextStyle(
                fontSize: 17,
                color: AppColors.grey,
                fontFamily: '.SF Pro Text',
              ),
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              onChanged: (value) => _updateLocalValue(key, value),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
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
                color: isDark ? AppColors.shadowDark : AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _getController(key, defaultValue),
            style: TextStyle(
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontSize: 17,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.grey,
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.greyLighter,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.greyLighter,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.accent : AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            maxLines: maxLines,
            onChanged: (value) => _updateLocalValue(key, value),
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
          style: Platform.isIOS
              ? TextStyle(
                  fontSize: 13,
                  color: AppColors.grey,
                  fontFamily: '.SF Pro Text',
                  fontWeight: FontWeight.w600,
                )
              : TextStyle(
                  fontSize: 13,
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
                color: isDark ? AppColors.shadowDark : AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField(
            value: value,
            dropdownColor:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            style: TextStyle(
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontSize: 17,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.greyLighter,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.greyLighter,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.accent : AppColors.primary,
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
                _updateLocalValue(key, newValue);
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
              style: Platform.isIOS
                  ? TextStyle(
                      fontSize: 13,
                      color: AppColors.grey,
                      fontFamily: '.SF Pro Text',
                      fontWeight: FontWeight.w600,
                    )
                  : TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                      letterSpacing: 0.15,
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.toastBackgroundDark
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                value.round().toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.accent : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: isDark ? AppColors.accent : AppColors.primary,
            inactiveTrackColor: isDark
                ? AppColors.accent.withOpacity(0.3)
                : AppColors.primary.withOpacity(0.3),
            thumbColor: isDark ? AppColors.accent : AppColors.primary,
            overlayColor: isDark
                ? AppColors.accent.withOpacity(0.2)
                : AppColors.primary.withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: (newValue) {
              _updateLocalValue(key, newValue);
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
          style: Platform.isIOS
              ? TextStyle(
                  fontSize: 13,
                  color: AppColors.grey,
                  fontFamily: '.SF Pro Text',
                  fontWeight: FontWeight.w600,
                )
              : TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  letterSpacing: 0.15,
                ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildAlignButton(
              'left',
              Platform.isIOS
                  ? CupertinoIcons.text_alignleft
                  : Icons.format_align_left_rounded,
              currentAlign,
              key,
              isDark,
            ),
            const SizedBox(width: 12),
            _buildAlignButton(
              'center',
              Platform.isIOS
                  ? CupertinoIcons.text_aligncenter
                  : Icons.format_align_center_rounded,
              currentAlign,
              key,
              isDark,
            ),
            const SizedBox(width: 12),
            _buildAlignButton(
              'right',
              Platform.isIOS
                  ? CupertinoIcons.text_alignright
                  : Icons.format_align_right_rounded,
              currentAlign,
              key,
              isDark,
            ),
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
          color: isSelected
              ? (isDark
                  ? AppColors.accent.withOpacity(0.2)
                  : AppColors.primary.withOpacity(0.1))
              : (isDark ? AppColors.backgroundDarkElevated : AppColors.surface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.accent : AppColors.primary)
                : (isDark ? AppColors.borderDark : AppColors.greyLighter),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _updateLocalValue(key, value),
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Icon(
                icon,
                color: isSelected
                    ? (isDark ? AppColors.accent : AppColors.primary)
                    : AppColors.grey,
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
          style: Platform.isIOS
              ? TextStyle(
                  fontSize: 13,
                  color: AppColors.grey,
                  fontFamily: '.SF Pro Text',
                  fontWeight: FontWeight.w600,
                )
              : TextStyle(
                  fontSize: 13,
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
                  color: isDark ? AppColors.shadowDark : AppColors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _updateLocalValue(key, color),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _hexToColor(color),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? (isDark ? AppColors.accent : AppColors.primary)
                    : (isDark ? AppColors.borderDark : AppColors.greyLighter),
                width: isSelected ? 3 : 1.5,
              ),
            ),
            child: isSelected
                ? Icon(
                    Platform.isIOS
                        ? CupertinoIcons.checkmark
                        : Icons.check_rounded,
                    color: AppColors.textLight,
                    size: 24,
                  )
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

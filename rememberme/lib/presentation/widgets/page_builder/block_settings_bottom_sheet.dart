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
  double _videoUploadProgress = 0.0;

  // Audio state
  bool _isRecording = false;
  int _recordingDuration = 0;
  double _audioUploadProgress = 0.0;
  List<double> _waveformData = [];
  String? _recordedAudioPath;

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
        builder: (ctx) => AlertDialog(
          title: Text(AppStrings.unsavedChanges),
          content: Text(AppStrings.unsavedChangesMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(AppStrings.discardChanges),
            ),
          ],
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: Text(AppStrings.ok),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.ok),
            ),
          ],
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
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.greyLight,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
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
              Expanded(
                child: Material(
                  type: MaterialType.transparency,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: _buildSettings(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.greyLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
                        '${BlockTypeInfo.getTitle(widget.block.type)} bearbeiten',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _discardChanges,
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.greyLighter,
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: _buildSettings(),
                ),
              ),
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
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _discardChanges,
                        child: Text(AppStrings.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _confirmChanges,
                        icon: const Icon(Icons.check_rounded),
                        label: Text(AppStrings.apply),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
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
      case ContentBlockType.video:
        return _buildVideoSettings();
      case ContentBlockType.audio:
        return _buildAudioSettings();
    }
  }

  List<Widget> _buildHeaderSettings() {
    return [
      _buildTextField(
        label: 'Überschrift',
        key: 'text',
        defaultValue: 'Überschrift eingeben',
        maxLines: 2,
      ),
      const SizedBox(height: 20),
      _buildDropdown(
        label: 'Größe',
        key: 'level',
        value: _getContent('level', 1),
        items: {1: 'Groß (H1)', 2: 'Mittel (H2)', 3: 'Klein (H3)'},
      ),
      const SizedBox(height: 20),
      _buildAlignmentPicker('align'),
      const SizedBox(height: 20),
      _buildColorPicker('color', 'Textfarbe'),
    ];
  }

  List<Widget> _buildTextSettings() {
    return [
      _buildTextField(
        label: 'Text',
        key: 'text',
        defaultValue: 'Text eingeben...',
        maxLines: 10,
      ),
      const SizedBox(height: 20),
      _buildSlider(
        label: 'Schriftgröße',
        key: 'fontSize',
        min: 12,
        max: 24,
        value: _getContent('fontSize', 16.0),
      ),
      const SizedBox(height: 20),
      _buildAlignmentPicker('align'),
      const SizedBox(height: 20),
      _buildColorPicker('color', 'Textfarbe'),
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
          ),
        ),
        const SizedBox(height: 20),
      ],
      FilledButton.icon(
        onPressed: _isUploading ? null : _handleImageUpload,
        icon: _isUploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.upload_rounded),
        label: Text(_isUploading ? 'Wird hochgeladen...' : 'Bild hochladen'),
      ),
      const SizedBox(height: 20),
      _buildTextField(
        label: 'Bildunterschrift',
        key: 'caption',
        defaultValue: '',
        maxLines: 2,
      ),
    ];
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
        _showSuccessSnackBar('Bild erfolgreich hochgeladen!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Fehler', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  List<Widget> _buildGallerySettings() {
    final List<String> images = List<String>.from(
      _getContent<List>('images', []),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return [
      if (images.isNotEmpty) ...[
        Text('Galerie (${images.length}/6)'),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
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
        ),
        const SizedBox(height: 20),
      ],
      FilledButton.icon(
        onPressed: _isUploading || images.length >= 6
            ? null
            : _handleGalleryImagesUpload,
        icon: _isUploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_photo_alternate_rounded),
        label: Text(
          _isUploading
              ? 'Wird hochgeladen...'
              : images.length >= 6
                  ? 'Maximum erreicht'
                  : 'Bilder hinzufügen (${6 - images.length} übrig)',
        ),
      ),
      const SizedBox(height: 20),
      _buildDropdown(
        label: 'Spalten',
        key: 'columns',
        value: _getContent('columns', 3),
        items: {2: '2 Spalten', 3: '3 Spalten', 4: '4 Spalten'},
      ),
    ];
  }

  Future<void> _handleGalleryImagesUpload() async {
    if (_isUploading) return;

    try {
      final List<String> currentImages = List<String>.from(
        _getContent<List>('images', []),
      );

      final int remaining = 6 - currentImages.length;
      if (remaining <= 0) return;

      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isEmpty) return;

      setState(() => _isUploading = true);

      final imagesToUpload = images.take(remaining).toList();
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
        _showSuccessSnackBar('${downloadUrls.length} Bilder hochgeladen!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Fehler', e.toString());
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

  List<Widget> _buildQuoteSettings() {
    return [
      _buildTextField(
        label: 'Zitat',
        key: 'text',
        defaultValue: 'Zitat eingeben...',
        maxLines: 4,
      ),
      const SizedBox(height: 20),
      _buildTextField(
        label: 'Autor',
        key: 'author',
        defaultValue: '',
      ),
      const SizedBox(height: 20),
      _buildColorPicker('color', 'Farbe'),
    ];
  }

  List<Widget> _buildVideoSettings() {
    final currentUrl = _getContent('url', '');
    final autoplay = _getContent('autoplay', false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return [
      if (currentUrl.isNotEmpty) ...[
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(
              Icons.play_circle_filled,
              size: 64,
              color: AppColors.textLight,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
      FilledButton.icon(
        onPressed: _isUploading ? null : _handleVideoUpload,
        icon: _isUploading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: _videoUploadProgress,
                ),
              )
            : const Icon(Icons.videocam_rounded),
        label: Text(_isUploading
            ? 'Upload... ${(_videoUploadProgress * 100).toInt()}%'
            : currentUrl.isEmpty
                ? 'Video hochladen (max. 15 Sek.)'
                : 'Video ersetzen'),
      ),
      const SizedBox(height: 20),
      _buildAutoplayToggle(isDark, autoplay),
      const SizedBox(height: 20),
      _buildTextField(
        label: 'Beschreibung',
        key: 'caption',
        defaultValue: '',
        maxLines: 2,
      ),
    ];
  }

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
        _showErrorDialog('Fehler', 'Video ist zu groß (max. 50MB)');
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
        _showErrorDialog('Fehler', e.toString());
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

  Widget _buildAutoplayToggle(bool isDark, bool autoplay) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: autoplay
              ? AppColors.success.withOpacity(0.5)
              : (isDark ? AppColors.borderDark : AppColors.greyLighter),
        ),
      ),
      child: Row(
        children: [
          Icon(
            autoplay ? Icons.play_circle_filled : Icons.play_circle_outline,
            color: autoplay ? AppColors.success : AppColors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Autoplay',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                ),
                Text(
                  autoplay ? 'Video startet automatisch' : 'Manuell starten',
                  style: TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
          ),
          Switch(
            value: autoplay,
            onChanged: (value) => _updateLocalValue('autoplay', value),
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Audio Settings
  // ============================================================
  List<Widget> _buildAudioSettings() {
    final currentUrl = _getContent('url', '');
    final title = _getContent('title', '');
    final duration = _getContent('duration', 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String formatDuration(int seconds) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }

    return [
      // Audio Preview
      if (currentUrl.isNotEmpty || _recordedAudioPath != null) ...[
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.accent.withOpacity(0.15),
                      AppColors.accent.withOpacity(0.05),
                    ]
                  : [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.03),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.accent.withOpacity(0.3)
                  : AppColors.primary.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Play button
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.accent : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Platform.isIOS
                          ? CupertinoIcons.play_fill
                          : Icons.play_arrow_rounded,
                      color: isDark ? AppColors.primary : AppColors.background,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Waveform
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(20, (index) {
                          final heights = [
                            0.3,
                            0.5,
                            0.8,
                            0.4,
                            0.9,
                            0.6,
                            0.7,
                            0.5,
                            0.8,
                            0.4,
                            0.6,
                            0.9,
                            0.5,
                            0.7,
                            0.3,
                            0.8,
                            0.6,
                            0.4,
                            0.7,
                            0.5
                          ];
                          final heightFactor = _waveformData.isNotEmpty &&
                                  index < _waveformData.length
                              ? _waveformData[index].clamp(0.2, 1.0)
                              : heights[index % heights.length];

                          return Container(
                            width: 3,
                            height: 36 * heightFactor,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.accent.withOpacity(0.8)
                                  : AppColors.primary.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatDuration(
                        _recordingDuration > 0 ? _recordingDuration : duration),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Platform.isIOS
                          ? CupertinoIcons.checkmark_circle_fill
                          : Icons.check_circle,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Sprachmemo bereit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],

      // Record Button
      SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _isUploading ? null : _toggleRecording,
          icon: Icon(
            _isRecording
                ? (Platform.isIOS
                    ? CupertinoIcons.stop_fill
                    : Icons.stop_rounded)
                : (Platform.isIOS
                    ? CupertinoIcons.mic_fill
                    : Icons.mic_rounded),
            size: 24,
          ),
          label: Text(
            _isRecording
                ? 'Aufnahme stoppen (${formatDuration(_recordingDuration)})'
                : currentUrl.isEmpty && _recordedAudioPath == null
                    ? 'Sprachmemo aufnehmen'
                    : 'Neu aufnehmen',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _isRecording
                ? AppColors.error
                : (isDark ? AppColors.accent : AppColors.primary),
            foregroundColor: _isRecording
                ? AppColors.textLight
                : (isDark ? AppColors.primary : AppColors.background),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),

      const SizedBox(height: 8),

      // Info
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: AppColors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Max. 2 Minuten • MP3, M4A, WAV',
                style: TextStyle(fontSize: 12, color: AppColors.grey),
              ),
            ),
          ],
        ),
      ),

      // Upload Progress
      if (_isUploading) ...[
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _audioUploadProgress,
            backgroundColor:
                isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter,
            valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppColors.accent : AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Wird hochgeladen... ${(_audioUploadProgress * 100).toInt()}%',
          style: TextStyle(fontSize: 13, color: AppColors.grey),
        ),
      ],

      const SizedBox(height: 24),

      // Title field
      _buildTextField(
        label: 'Titel (optional)',
        key: 'title',
        defaultValue: '',
        hint: 'z.B. "Persönliche Nachricht"',
      ),

      // Delete button if audio exists
      if (currentUrl.isNotEmpty) ...[
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            _updateLocalValue('url', '');
            _updateLocalValue('duration', 0);
            _updateLocalValue('waveformData', <double>[]);
          },
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          label: const Text(
            'Sprachmemo entfernen',
            style: TextStyle(color: AppColors.error),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.error.withOpacity(0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ];
  }

  void _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
      _waveformData = [];
    });

    if (Platform.isIOS) {
      HapticFeedback.mediumImpact();
    }

    // Simulate recording timer
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording || !mounted) return false;

      setState(() {
        _recordingDuration++;
        if (_waveformData.length < 24) {
          _waveformData.add(0.3 +
              (0.7 * (DateTime.now().millisecondsSinceEpoch % 100) / 100));
        }
      });

      if (_recordingDuration >= 120) {
        _stopRecording();
        return false;
      }

      return true;
    });
  }

  Future<void> _stopRecording() async {
    setState(() {
      _isRecording = false;
    });

    if (Platform.isIOS) {
      HapticFeedback.mediumImpact();
    }

    if (_recordingDuration > 0) {
      setState(() {
        _recordedAudioPath = '/simulated/path/audio.m4a';
        _hasChanges = true;
      });

      _updateLocalValue('duration', _recordingDuration);
      _updateLocalValue('waveformData', _waveformData);

      // Simulate upload
      await _uploadAudio();
    }
  }

  Future<void> _uploadAudio() async {
    if (_recordedAudioPath == null) return;

    setState(() {
      _isUploading = true;
      _audioUploadProgress = 0.0;
    });

    try {
      // Simulate upload
      for (var i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            _audioUploadProgress = i / 100;
          });
        }
      }

      // Simulated URL
      final downloadUrl =
          'https://firebasestorage.example.com/audio/${widget.block.id}.m4a';

      _updateLocalValue('url', downloadUrl);

      if (mounted) {
        _showSuccessSnackBar('Sprachmemo erfolgreich hochgeladen!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Upload fehlgeschlagen', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _audioUploadProgress = 0.0;
        });
      }
    }
  }

  // ============================================================
  // Common UI Builders
  // ============================================================
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _getController(key, defaultValue),
          maxLines: maxLines,
          style: TextStyle(
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.greyLighter,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.greyLighter,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.accent : AppColors.primary,
                width: 2,
              ),
            ),
          ),
          onChanged: (value) => _updateLocalValue(key, value),
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.grey,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField(
          value: value,
          dropdownColor:
              isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          decoration: InputDecoration(
            filled: true,
            fillColor:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.greyLighter,
              ),
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
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.toastBackgroundDark
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value.round().toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.accent : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          activeColor: isDark ? AppColors.accent : AppColors.primary,
          onChanged: (newValue) => _updateLocalValue(key, newValue),
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
          'Ausrichtung',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.grey,
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
      child: InkWell(
        onTap: () => _updateLocalValue(key, value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? AppColors.accent.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.1))
                : (isDark
                    ? AppColors.backgroundDarkElevated
                    : AppColors.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (isDark ? AppColors.accent : AppColors.primary)
                  : (isDark ? AppColors.borderDark : AppColors.greyLighter),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Icon(
            icon,
            color: isSelected
                ? (isDark ? AppColors.accent : AppColors.primary)
                : AppColors.grey,
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.grey,
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
            final isSelected = color == currentColor;
            return GestureDetector(
              onTap: () => _updateLocalValue(key, color),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _hexToColor(color),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? AppColors.accent : AppColors.primary)
                        : (isDark
                            ? AppColors.borderDark
                            : AppColors.greyLighter),
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.textLight)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
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

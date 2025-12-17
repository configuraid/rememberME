import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:rememberme/data/models/content_block_model.dart';
import 'package:rememberme/data/services/firebase_storage_service.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/core/constants/app_strings.dart';

/// Konfigurations-Screen für einen neuen Content Block
/// Wird als vollständige Seite mit Push-Navigation angezeigt
/// Gibt bei Bestätigung einen konfigurierten ContentBlock zurück, sonst null
class BlockConfigurationScreen extends StatefulWidget {
  final ContentBlockType blockType;
  final String memorialId;

  const BlockConfigurationScreen({
    super.key,
    required this.blockType,
    required this.memorialId,
  });

  @override
  State<BlockConfigurationScreen> createState() =>
      _BlockConfigurationScreenState();
}

class _BlockConfigurationScreenState extends State<BlockConfigurationScreen> {
  late ContentBlock _block;
  late Map<String, TextEditingController> _controllers;
  late Map<String, dynamic> _localContent;

  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  bool _isUploading = false;
  bool _hasChanges = false;
  double _videoUploadProgress = 0.0;
  Uint8List? _videoThumbnail;

  // Audio recording state
  bool _isRecording = false;
  String? _recordedAudioPath;
  int _recordingDuration = 0;
  double _audioUploadProgress = 0.0;
  List<double> _waveformData = [];

  @override
  void initState() {
    super.initState();
    _block = ContentBlock(type: widget.blockType);
    _controllers = {};
    _localContent = Map.from(_block.content);
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  void _updateLocalValue(String key, dynamic value) {
    setState(() {
      _localContent[key] = value;
      _hasChanges = true;
    });
  }

  void _confirmAndCreate() {
    if (Platform.isIOS) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    // Erstelle den finalen Block mit allen Einstellungen
    final configuredBlock = _block.copyWith(
      content: _localContent,
    );

    Navigator.pop(context, configuredBlock);
  }

  void _discardAndGoBack() {
    if (_hasChanges) {
      _showDiscardDialog();
    } else {
      Navigator.pop(context, null);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) {
      return true;
    }

    final result = await _showDiscardDialogWithResult();
    return result ?? false;
  }

  Future<bool?> _showDiscardDialogWithResult() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      return showCupertinoDialog<bool>(
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
            'Möchtest du die Konfiguration verwerfen?',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey,
              fontFamily: '.SF Pro Text',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                'Weiter bearbeiten',
                style: TextStyle(
                  fontSize: 17,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              onPressed: () => Navigator.pop(context, false),
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
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
    } else {
      return showDialog<bool>(
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
                    'Möchtest du die Konfiguration verwerfen?',
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
                          onPressed: () => Navigator.pop(ctx, false),
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
                            'Weiter bearbeiten',
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
                          onPressed: () => Navigator.pop(ctx, true),
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

  void _showDiscardDialog() async {
    final shouldDiscard = await _showDiscardDialogWithResult();
    if (shouldDiscard == true && mounted) {
      Navigator.pop(context, null);
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

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSLayout(context);
    }
    return _buildAndroidLayout(context);
  }

  // ============================================================
  // iOS Layout - Native Push Navigation Style
  // ============================================================
  Widget _buildIOSLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: CupertinoPageScaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        navigationBar: CupertinoNavigationBar(
          middle: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                BlockTypeInfo.getIcon(widget.blockType),
                size: 20,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${BlockTypeInfo.getTitle(widget.blockType)} erstellen',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    fontFamily: '.SF Pro Text',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: isDark
              ? AppColors.backgroundDarkElevated.withOpacity(0.8)
              : AppColors.surface.withOpacity(0.94),
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.divider,
              width: 0.5,
            ),
          ),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: _discardAndGoBack,
            child: Text(
              AppStrings.cancel,
              style: TextStyle(
                fontSize: 17,
                color: isDark ? AppColors.accent : AppColors.primary,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: _confirmAndCreate,
            child: Text(
              'Erstellen',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.accent : AppColors.primary,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ),
        // Material wrapper für DropdownButtonFormField und andere Material Widgets
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Column(
              children: [
                // Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Block Type Header Card
                      _buildBlockTypeHeader(isDark),
                      const SizedBox(height: 24),
                      // Settings
                      ..._buildSettings(),
                    ],
                  ),
                ),

                // Bottom Action Bar
                Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    12 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.backgroundDarkElevated
                        : AppColors.surface,
                    border: Border(
                      top: BorderSide(
                        color:
                            isDark ? AppColors.borderDark : AppColors.divider,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          color: isDark
                              ? AppColors.toastBackgroundDark
                              : AppColors.greyLighter,
                          borderRadius: BorderRadius.circular(12),
                          onPressed: _discardAndGoBack,
                          child: Text(
                            AppStrings.cancel,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textLight
                                  : AppColors.textPrimary,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          color: isDark ? AppColors.accent : AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          onPressed: _confirmAndCreate,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.checkmark_alt,
                                size: 20,
                                color: isDark
                                    ? AppColors.primary
                                    : AppColors.background,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Block erstellen',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.primary
                                      : AppColors.background,
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Android Layout
  // ============================================================
  Widget _buildAndroidLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                BlockTypeInfo.getIcon(widget.blockType),
                size: 24,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '${BlockTypeInfo.getTitle(widget.blockType)} erstellen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: isDark
              ? AppColors.backgroundDarkElevated.withOpacity(0.8)
              : AppColors.surface.withOpacity(0.94),
          foregroundColor: isDark ? AppColors.textLight : AppColors.textPrimary,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? AppColors.accent : AppColors.primary,
            ),
            onPressed: _discardAndGoBack,
          ),
        ),
        body: Column(
          children: [
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Block Type Header Card
                  _buildBlockTypeHeader(isDark),
                  const SizedBox(height: 24),
                  // Settings
                  ..._buildSettings(),
                ],
              ),
            ),

            // Bottom Action Bar
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
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _discardAndGoBack,
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
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _confirmAndCreate,
                      icon: const Icon(Icons.check_rounded, size: 22),
                      label: const Text(
                        'Block erstellen',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            isDark ? AppColors.accent : AppColors.primary,
                        foregroundColor:
                            isDark ? AppColors.primary : AppColors.background,
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
      ),
    );
  }

  Widget _buildBlockTypeHeader(bool isDark) {
    return Container(
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
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.accent.withOpacity(0.2)
                  : AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              BlockTypeInfo.getIcon(widget.blockType),
              size: 32,
              color: isDark ? AppColors.accent : AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  BlockTypeInfo.getTitle(widget.blockType),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  BlockTypeInfo.getDescription(widget.blockType),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Settings Builder (wiederverwendet von BlockSettingsBottomSheet)
  // ============================================================
  List<Widget> _buildSettings() {
    switch (widget.blockType) {
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
        label: AppStrings.headerPlaceholder,
        key: 'text',
        defaultValue: 'Überschrift eingeben',
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
        defaultValue: 'Text eingeben...',
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
        blockId: _block.id,
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
        blockId: _block.id,
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

  List<Widget> _buildQuoteSettings() {
    return [
      _buildTextField(
        label: AppStrings.quote,
        key: 'text',
        defaultValue: 'Zitat eingeben...',
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

  List<Widget> _buildVideoSettings() {
    final currentUrl = _getContent('url', '');
    final thumbnailUrl = _getContent('thumbnailUrl', '');
    final autoplay = _getContent('autoplay', false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      return [
        // Video Vorschau mit Thumbnail
        if (currentUrl.isNotEmpty || _videoThumbnail != null) ...[
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
                    // Thumbnail Bild
                    if (_videoThumbnail != null)
                      Image.memory(
                        _videoThumbnail!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    else if (thumbnailUrl.isNotEmpty)
                      Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
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
                      )
                    else
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
                    // Play Button Overlay
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
                                  value: _videoUploadProgress.isNaN
                                      ? null
                                      : _videoUploadProgress,
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
                                '${(_videoUploadProgress.isNaN ? 0 : (_videoUploadProgress * 100)).toInt()}% abgeschlossen',
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
                      value: _videoUploadProgress.isNaN
                          ? null
                          : _videoUploadProgress,
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
      ];
    } else {
      // Android Video Settings
      return [
        // Video Vorschau mit Thumbnail
        if (currentUrl.isNotEmpty || _videoThumbnail != null) ...[
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Thumbnail Bild
                  if (_videoThumbnail != null)
                    Image.memory(
                      _videoThumbnail!,
                      fit: BoxFit.cover,
                    )
                  else if (thumbnailUrl.isNotEmpty)
                    Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          Icons.videocam_rounded,
                          size: 64,
                          color: AppColors.grey,
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Icon(
                        Icons.videocam_rounded,
                        size: 64,
                        color: AppColors.grey,
                      ),
                    ),
                  // Play Button Overlay
                  Container(
                    color: AppColors.backgroundDark.withOpacity(0.3),
                    child: Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowDark,
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 40,
                          color: isDark ? AppColors.accent : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  // "Video hochgeladen" Badge
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.textLight,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Video bereit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
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
                      value: _videoUploadProgress.isNaN
                          ? null
                          : _videoUploadProgress,
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
                            value: _videoUploadProgress.isNaN
                                ? null
                                : _videoUploadProgress,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.textLight),
                          ),
                        )
                      : const Icon(Icons.videocam_rounded, size: 22),
                  label: Text(
                    _isUploading
                        ? 'Uploading... ${(_videoUploadProgress.isNaN ? 0 : (_videoUploadProgress * 100)).toInt()}%'
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
      ];
    }
  }

  List<Widget> _buildAudioSettings() {
    final currentUrl = _getContent('url', '');
    final title = _getContent('title', '');
    final duration = _getContent('duration', 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Format duration helper
    String formatDuration(int seconds) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }

    if (Platform.isIOS) {
      return [
        // Audio Preview (wenn aufgenommen oder hochgeladen)
        if (currentUrl.isNotEmpty || _recordedAudioPath != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDark
                      ? AppColors.accent.withOpacity(0.15)
                      : AppColors.primary.withOpacity(0.1),
                  isDark
                      ? AppColors.accent.withOpacity(0.05)
                      : AppColors.primary.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.accent.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Waveform visualization
                Row(
                  children: [
                    // Play button
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.accent : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isDark ? AppColors.accent : AppColors.primary)
                                    .withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        CupertinoIcons.play_fill,
                        color:
                            isDark ? AppColors.primary : AppColors.background,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Waveform bars
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: List.generate(
                            24,
                            (index) {
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
                                0.5,
                                0.9,
                                0.6,
                                0.4,
                                0.7
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
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Duration
                    Text(
                      formatDuration(_recordingDuration > 0
                          ? _recordingDuration
                          : duration),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Success badge
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
                      const Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sprachmemo bereit',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                          fontFamily: '.SF Pro Text',
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

        // Recording Section
        Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Record Button
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                onPressed: _isUploading ? null : _toggleRecording,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isRecording
                            ? AppColors.error.withOpacity(0.15)
                            : (isDark
                                ? AppColors.accent.withOpacity(0.15)
                                : AppColors.primary.withOpacity(0.1)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isRecording
                            ? CupertinoIcons.stop_fill
                            : CupertinoIcons.mic_fill,
                        size: 20,
                        color: _isRecording
                            ? AppColors.error
                            : (isDark ? AppColors.accent : AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isRecording
                                ? 'Aufnahme läuft...'
                                : currentUrl.isEmpty &&
                                        _recordedAudioPath == null
                                    ? 'Sprachmemo aufnehmen'
                                    : 'Neu aufnehmen',
                            style: TextStyle(
                              fontSize: 17,
                              color: _isRecording
                                  ? AppColors.error
                                  : (isDark
                                      ? AppColors.textLight
                                      : AppColors.textPrimary),
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                          if (_isRecording)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                formatDuration(_recordingDuration),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_isRecording)
                      _buildRecordingIndicator(isDark)
                    else
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 20,
                        color: AppColors.grey,
                      ),
                  ],
                ),
              ),
              Container(
                height: 0.5,
                margin: const EdgeInsets.only(left: 68),
                color: isDark ? AppColors.borderDark : AppColors.greyLight,
              ),
              // Upload from file
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                onPressed: _isUploading || _isRecording ? null : _pickAudioFile,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.toastBackgroundDark
                            : AppColors.greyLighter,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.folder_fill,
                        size: 20,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Audiodatei auswählen',
                        style: TextStyle(
                          fontSize: 17,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 20,
                      color: AppColors.grey,
                    ),
                  ],
                ),
              ),
              Container(
                height: 0.5,
                margin: const EdgeInsets.only(left: 68),
                color: isDark ? AppColors.borderDark : AppColors.greyLight,
              ),
              // Info
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.info,
                        size: 20,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Max. 2 Minuten • MP3, M4A, WAV',
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

        // Upload Progress
        if (_isUploading) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: 2.5,
                        value: _audioUploadProgress,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Wird hochgeladen... ${(_audioUploadProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _audioUploadProgress,
                    backgroundColor: isDark
                        ? AppColors.toastBackgroundDark
                        : AppColors.greyLighter,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? AppColors.accent : AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Title field
        Text(
          'Titel (optional)',
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
            controller: _getController('title', ''),
            placeholder: 'z.B. "Persönliche Nachricht"',
            maxLines: 1,
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
            onChanged: (value) => _updateLocalValue('title', value),
          ),
        ),
      ];
    } else {
      // Android Audio Settings
      return [
        // Audio Preview (wenn aufgenommen oder hochgeladen)
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
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Play button
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  AppColors.accent,
                                  AppColors.accent.withOpacity(0.8)
                                ]
                              : [
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0.9)
                                ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isDark ? AppColors.accent : AppColors.primary)
                                    .withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color:
                            isDark ? AppColors.primary : AppColors.background,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Waveform
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Waveform bars
                          SizedBox(
                            height: 40,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: List.generate(
                                20,
                                (index) {
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
                                  final heightFactor =
                                      _waveformData.isNotEmpty &&
                                              index < _waveformData.length
                                          ? _waveformData[index].clamp(0.2, 1.0)
                                          : heights[index % heights.length];

                                  return Container(
                                    width: 4,
                                    height: 36 * heightFactor,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.accent.withOpacity(0.8)
                                          : AppColors.primary.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Duration
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '00:00',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey,
                                ),
                              ),
                              Text(
                                formatDuration(_recordingDuration > 0
                                    ? _recordingDuration
                                    : duration),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Success badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sprachmemo bereit',
                        style: TextStyle(
                          fontSize: 14,
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
          height: 64,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isUploading ? null : _toggleRecording,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isRecording
                  ? const Icon(Icons.stop_rounded,
                      size: 28, key: ValueKey('stop'))
                  : const Icon(Icons.mic_rounded,
                      size: 28, key: ValueKey('mic')),
            ),
            label: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isRecording
                      ? 'Aufnahme stoppen'
                      : currentUrl.isEmpty && _recordedAudioPath == null
                          ? 'Sprachmemo aufnehmen'
                          : 'Neu aufnehmen',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isRecording)
                  Text(
                    formatDuration(_recordingDuration),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: (isDark ? AppColors.primary : AppColors.background)
                          .withOpacity(0.8),
                    ),
                  ),
              ],
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

        const SizedBox(height: 12),

        // Pick audio file button
        SizedBox(
          height: 56,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isUploading || _isRecording ? null : _pickAudioFile,
            icon: const Icon(Icons.folder_rounded, size: 22),
            label: const Text(
              'Audiodatei auswählen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  isDark ? AppColors.textLight : AppColors.textPrimary,
              side: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.greyLight,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Info row
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
                  'Max. 2 Minuten • Unterstützte Formate: MP3, M4A, WAV',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Upload Progress
        if (_isUploading) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.greyLighter,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        value: _audioUploadProgress,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? AppColors.accent : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Wird hochgeladen... ${(_audioUploadProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _audioUploadProgress,
                    backgroundColor: isDark
                        ? AppColors.toastBackgroundDark
                        : AppColors.greyLighter,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? AppColors.accent : AppColors.primary),
                  ),
                ),
              ],
            ),
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
      ];
    }
  }

  Widget _buildRecordingIndicator(bool isDark) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  // Audio recording methods
  void _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    // TODO: Implement with record package
    // For now, show placeholder behavior
    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });

    // Simulate recording timer
    _startRecordingTimer();

    if (Platform.isIOS) {
      HapticFeedback.mediumImpact();
    }
  }

  void _startRecordingTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording || !mounted) return false;

      setState(() {
        _recordingDuration++;
        // Generate random waveform data
        if (_waveformData.length < 24) {
          _waveformData.add(0.3 +
              (0.7 * (DateTime.now().millisecondsSinceEpoch % 100) / 100));
        }
      });

      // Stop at 2 minutes
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

    // TODO: Get actual recorded file path
    // For demo, we'll simulate having recorded something
    if (_recordingDuration > 0) {
      setState(() {
        _recordedAudioPath = '/simulated/path/audio.m4a';
        _hasChanges = true;
      });

      // Update content
      _updateLocalValue('duration', _recordingDuration);
      _updateLocalValue('waveformData', _waveformData);

      // Show upload dialog
      _showUploadAudioDialog();
    }
  }

  void _showUploadAudioDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            'Sprachmemo aufgenommen',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Text(
            'Möchtest du das Sprachmemo jetzt hochladen?',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey,
              fontFamily: '.SF Pro Text',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                'Später',
                style: TextStyle(
                  fontSize: 17,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(
                'Hochladen',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _uploadAudio();
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sprachmemo aufgenommen'),
          content: const Text('Möchtest du das Sprachmemo jetzt hochladen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Später'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _uploadAudio();
              },
              child: const Text('Hochladen'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _pickAudioFile() async {
    // TODO: Implement file picker for audio files
    // For now show a message
    _showErrorDialog(
      'Funktion folgt',
      'Die Audiodatei-Auswahl wird in einem zukünftigen Update verfügbar sein. Bitte nutze vorerst die Aufnahme-Funktion.',
    );
  }

  Future<void> _uploadAudio() async {
    if (_recordedAudioPath == null) return;

    setState(() {
      _isUploading = true;
      _audioUploadProgress = 0.0;
    });

    try {
      // Simulate upload progress
      for (var i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            _audioUploadProgress = i / 100;
          });
        }
      }

      // TODO: Actually upload to Firebase Storage
      // final downloadUrl = await _storageService.uploadBlockAudio(
      //   memorialId: widget.memorialId,
      //   blockId: _block.id,
      //   audioFile: File(_recordedAudioPath!),
      //   onProgress: (progress) {
      //     if (mounted) {
      //       setState(() {
      //         _audioUploadProgress = progress;
      //       });
      //     }
      //   },
      // );

      // Simulate URL for now
      final downloadUrl =
          'https://firebasestorage.example.com/audio/${_block.id}.m4a';

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

      // Thumbnail generieren
      await _generateVideoThumbnail(video.path);

      setState(() {
        _isUploading = true;
        _videoUploadProgress = 0.0;
      });

      final String downloadUrl = await _storageService.uploadBlockVideo(
        memorialId: widget.memorialId,
        blockId: _block.id,
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

      // Thumbnail auch hochladen und URL speichern
      if (_videoThumbnail != null) {
        try {
          final thumbnailUrl = await _storageService.uploadVideoThumbnail(
            memorialId: widget.memorialId,
            blockId: _block.id,
            thumbnailData: _videoThumbnail!,
          );
          _updateLocalValue('thumbnailUrl', thumbnailUrl);
        } catch (e) {
          debugPrint('⚠️ Thumbnail upload failed: $e');
          // Nicht kritisch, Video funktioniert auch ohne Thumbnail
        }
      }

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

  Future<void> _generateVideoThumbnail(String videoPath) async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        quality: 75,
      );

      if (thumbnail != null && mounted) {
        setState(() {
          _videoThumbnail = thumbnail;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Failed to generate thumbnail: $e');
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

  // ============================================================
  // Dialogs
  // ============================================================
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
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
}

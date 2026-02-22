import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rememberme/data/models/content_block_model.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/core/constants/app_strings.dart';
import 'package:rememberme/presentation/screens/visual_builder/mixins/audio_recording_mixin.dart';
import 'package:rememberme/presentation/screens/visual_builder/mixins/upload_mixin.dart';
import 'package:rememberme/presentation/screens/visual_builder/mixins/video_player_mixin.dart';
import 'package:rememberme/presentation/screens/visual_builder/settings/audio_settings.dart';
import 'package:rememberme/presentation/screens/visual_builder/settings/gallery_settings.dart';
import 'package:rememberme/presentation/screens/visual_builder/settings/header_settings.dart';
import 'package:rememberme/presentation/screens/visual_builder/settings/image_settings.dart';
import 'package:rememberme/presentation/screens/visual_builder/settings/image_text_settings.dart';
import 'package:rememberme/presentation/screens/visual_builder/settings/quote_settings.dart';
import 'package:rememberme/presentation/screens/visual_builder/settings/text_settings.dart';
import 'package:rememberme/presentation/screens/visual_builder/settings/timeline_settings.dart';
import 'package:rememberme/presentation/screens/visual_builder/settings/video_settings.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/bottom_action_buttons.dart';

class BlockConfigurationScreen extends StatefulWidget {
  final ContentBlockType? blockType;

  final ContentBlock? existingBlock;

  final String memorialId;

  const BlockConfigurationScreen({
    super.key,
    this.blockType,
    this.existingBlock,
    required this.memorialId,
  }) : assert(
          blockType != null || existingBlock != null,
          'Either blockType or existingBlock must be provided',
        );

  @override
  State<BlockConfigurationScreen> createState() =>
      _BlockConfigurationScreenState();
}

class _BlockConfigurationScreenState extends State<BlockConfigurationScreen>
    with UploadMixin, AudioRecordingMixin, VideoPlayerMixin {
  late ContentBlock _block;
  late Map<String, dynamic> _localContent;
  bool _hasChanges = false;

  bool get _isEditing => widget.existingBlock != null;

  ContentBlockType get _blockType =>
      widget.existingBlock?.type ?? widget.blockType!;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _block = widget.existingBlock!;
      _localContent = Map.from(_block.content);
    } else {
      _block = ContentBlock(type: _blockType);
      _localContent = Map.from(_block.content);
    }

    if (_blockType == ContentBlockType.audio) {
      initAudioPlayer();
    }
  }

  @override
  void dispose() {
    if (_blockType == ContentBlockType.audio) {
      disposeAudioResources();
    }
    if (_blockType == ContentBlockType.video) {
      disposeVideoPlayer();
    }
    super.dispose();
  }

  // ============================================
  // Value Update Handlers
  // ============================================

  void _updateValue(String key, dynamic value) {
    setState(() {
      _localContent[key] = value;
      _hasChanges = true;
    });
  }

  void _handleValueChange(String change) {
    final parts = change.split(':');
    if (parts.length >= 2) {
      final key = parts[0];
      final valueStr = parts.sublist(1).join(':');

      dynamic value;

      if (valueStr == 'true' || valueStr == 'false') {
        value = valueStr == 'true';
      } else if (int.tryParse(valueStr) != null && !valueStr.contains('.')) {
        value = int.parse(valueStr);
      } else if (double.tryParse(valueStr) != null) {
        value = double.parse(valueStr);
      } else {
        value = valueStr;
      }

      _updateValue(key, value);
    }
  }

  // ============================================
  // Validation
  // ============================================

  bool _isBlockValid() {
    switch (_blockType) {
      case ContentBlockType.imageText:
        return (_localContent['imageUrl'] ?? '').toString().isNotEmpty;
      case ContentBlockType.image:
        return (_localContent['url'] ?? '').toString().isNotEmpty;
      case ContentBlockType.video:
        return (_localContent['url'] ?? '').toString().isNotEmpty;
      case ContentBlockType.audio:
        return (_localContent['url'] ?? '').toString().isNotEmpty;
      case ContentBlockType.gallery:
        final images = _localContent['images'] as List? ?? [];
        return images.isNotEmpty;
      case ContentBlockType.timeline:
      case ContentBlockType.header:
      case ContentBlockType.text:
      case ContentBlockType.quote:
        return true;
    }
  }

  String _getValidationMessage() {
    switch (_blockType) {
      case ContentBlockType.imageText:
      case ContentBlockType.image:
        return 'Bitte lade zuerst ein Bild hoch.';
      case ContentBlockType.video:
        return 'Bitte lade zuerst ein Video hoch.';
      case ContentBlockType.audio:
        return 'Bitte wähle zuerst eine Audiodatei aus.';
      case ContentBlockType.gallery:
        return 'Bitte lade mindestens ein Bild hoch.';
      default:
        return 'Bitte fülle alle Pflichtfelder aus.';
    }
  }

  // ============================================
  // Actions
  // ============================================

  void _confirmAndSave() {
    if (!_isBlockValid()) {
      showValidationError(_getValidationMessage());
      return;
    }

    if (Platform.isIOS) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    final configuredBlock = _block.copyWith(content: _localContent);
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
    if (!_hasChanges) return true;
    final result = await _showDiscardDialogWithResult();
    return result ?? false;
  }

  Future<bool?> _showDiscardDialogWithResult() async {
    if (Platform.isIOS) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(AppStrings.unsavedChanges),
          content: Text(
            _isEditing
                ? 'Möchtest du die Änderungen verwerfen?'
                : 'Möchtest du die Konfiguration verwerfen?',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Weiter bearbeiten'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(AppStrings.discardChanges),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
    } else {
      return showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppStrings.unsavedChanges),
          content: Text(
            _isEditing
                ? 'Möchtest du die Änderungen verwerfen?'
                : 'Möchtest du die Konfiguration verwerfen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Weiter bearbeiten'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(AppStrings.discardChanges),
            ),
          ],
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

  // ============================================
  // Mixin Callbacks
  // ============================================

  @override
  void onRecordingComplete(String path, int duration, List<double> waveform) {
    _updateValue('duration', duration);
    _updateValue('waveformData', waveform);
    _hasChanges = true;
  }

  @override
  void onRecordingError(String title, String message) {
    showErrorDialog(title, message);
  }

  @override
  void onPlaybackError(String error) {
    String errorMessage;
    if (error.contains('NO_VALID_SOURCE')) {
      errorMessage =
          'Das Audio ist noch nicht verfügbar.\n\nBitte wähle eine Audiodatei aus.';
    } else {
      errorMessage = 'Audio konnte nicht abgespielt werden.\n\nFehler: $error';
    }
    showErrorDialog('Wiedergabefehler', errorMessage);
  }

  @override
  void onAudioFilePicked(String path, int duration, List<double> waveform) {
    _updateValue('duration', duration);
    _updateValue('waveformData', waveform);
    _updateValue('localPath', path);
    _hasChanges = true;
    // Auto-Upload nach File Pick (wie bei Images)
    _handleAudioUpload();
  }

  @override
  void onVideoError(String title, String message) {
    showErrorDialog(title, message);
  }

  @override
  void onVideoUploadSuccess(String videoUrl, String? thumbnailUrl) {
    _updateValue('url', videoUrl);
    if (thumbnailUrl != null) {
      _updateValue('thumbnailUrl', thumbnailUrl);
    }
    showSuccessSnackBar('Video erfolgreich hochgeladen!');
  }

  Future<void> _handleAudioUpload() async {
    final url = await uploadAudio(
      memorialId: widget.memorialId,
      blockId: _block.id,
    );
    if (url != null) {
      _updateValue('url', url);
      showSuccessSnackBar('Audiodatei erfolgreich hochgeladen!');
    }
  }

  String get _confirmButtonLabel => _isEditing ? AppStrings.apply : 'Erstellen';

  String get _navBarTitle {
    final typeName = BlockTypeInfo.getTitle(_blockType);
    return _isEditing ? '$typeName bearbeiten' : typeName;
  }

  // ============================================
  // Build Methods
  // ============================================

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSLayout(context);
    }
    return _buildAndroidLayout(context);
  }

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
                BlockTypeInfo.getIcon(_blockType),
                size: 20,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _navBarTitle,
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
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: _discardAndGoBack,
            child: Text(
              AppStrings.cancel,
              style: TextStyle(
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
            ),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: _confirmAndSave,
            child: Text(
              _confirmButtonLabel,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
            ),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildSettingsWidget(),
                  ),
                  // Buttons ausblenden wenn Tastatur offen
                  if (MediaQuery.of(context).viewInsets.bottom == 0)
                    BottomActionButtons(
                      onCancel: _discardAndGoBack,
                      onCreate: _confirmAndSave,
                      isValid: _isBlockValid(),
                      confirmLabel: _confirmButtonLabel,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
                BlockTypeInfo.getIcon(_blockType),
                size: 24,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  _navBarTitle,
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
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? AppColors.accent : AppColors.primary,
            ),
            onPressed: _discardAndGoBack,
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              const SizedBox(height: 16),
              Expanded(
                child: _buildSettingsWidget(),
              ),
              // Buttons ausblenden wenn Tastatur offen
              if (MediaQuery.of(context).viewInsets.bottom == 0)
                BottomActionButtons(
                  onCancel: _discardAndGoBack,
                  onCreate: _confirmAndSave,
                  isValid: _isBlockValid(),
                  confirmLabel: _confirmButtonLabel,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsWidget() {
    switch (_blockType) {
      case ContentBlockType.header:
        return HeaderSettings(
          content: _localContent,
          onValueChanged: _handleValueChange,
        );

      case ContentBlockType.text:
        return TextSettings(
          content: _localContent,
          onValueChanged: _handleValueChange,
        );

      case ContentBlockType.image:
        return ImageSettings(
          content: _localContent,
          onValueChanged: _handleValueChange,
          isUploading: isUploading,
          onUploadImage: () async {
            final url = await uploadImage(
              memorialId: widget.memorialId,
              blockId: _block.id,
            );
            if (url != null) {
              _updateValue('url', url);
            }
            return url;
          },
        );

      case ContentBlockType.gallery:
        return GallerySettings(
          content: _localContent,
          onValueChanged: _handleValueChange,
          isUploading: isUploading,
          onUploadImages: () async {
            final currentImages = List<String>.from(
              _localContent['images'] ?? [],
            );
            final urls = await uploadMultipleImages(
              memorialId: widget.memorialId,
              blockId: _block.id,
              maxImages: 6,
              currentCount: currentImages.length,
            );
            if (urls != null) {
              final updatedImages = [...currentImages, ...urls];
              _updateValue('images', updatedImages);
            }
            return urls;
          },
          onRemoveImage: (index) {
            final images = List<String>.from(_localContent['images'] ?? []);
            if (index >= 0 && index < images.length) {
              images.removeAt(index);
              _updateValue('images', images);
            }
          },
        );

      case ContentBlockType.quote:
        return QuoteSettings(
          content: _localContent,
          onValueChanged: _handleValueChange,
        );

      case ContentBlockType.video:
        return VideoSettings(
          content: _localContent,
          onValueChanged: _handleValueChange,
          isUploading: isVideoUploading,
          uploadProgress: videoUploadProgress,
          isVideoInitialized: isVideoInitialized,
          isVideoLoading: isVideoLoading,
          chewieController: chewieController,
          thumbnail: videoThumbnail,
          onUploadVideo: () async {
            await uploadVideo(
              memorialId: widget.memorialId,
              blockId: _block.id,
            );
          },
          onInitializePlayer: () {
            final url = _localContent['url'] ?? '';
            if (url.isNotEmpty) {
              initializeVideoPlayer(url);
            }
          },
        );

      case ContentBlockType.audio:
        return AudioSettings(
          content: _localContent,
          onValueChanged: _handleValueChange,
          isPlaying: isPlaying,
          isUploading: isAudioUploading,
          uploadProgress: audioUploadProgress,
          audioPosition: audioPosition,
          audioDuration: audioDuration,
          onPickAudioFile: pickAudioFile,
          onTogglePlayback: toggleAudioPlayback,
        );

      case ContentBlockType.imageText:
        return ImageTextSettings(
          content: _localContent,
          onValueChanged: _handleValueChange,
          isUploading: isUploading,
          onUploadImage: () async {
            final url = await uploadImage(
              memorialId: widget.memorialId,
              blockId: _block.id,
            );
            if (url != null) {
              _updateValue('imageUrl', url);
            }
            return url;
          },
        );

      case ContentBlockType.timeline:
        return TimelineSettings(
          content: _localContent,
          memorialId: widget.memorialId,
          blockId: _block.id,
          onEntriesChanged: (entries) {
            _updateValue('entries', entries);
          },
        );
    }
  }
}

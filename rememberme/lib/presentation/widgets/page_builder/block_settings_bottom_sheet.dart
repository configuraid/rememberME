import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rememberme/data/models/content_block_model.dart';
import 'package:rememberme/data/services/firebase_storage_service.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/core/constants/app_strings.dart';
import 'package:rememberme/presentation/widgets/common/custom_color_picker_dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';

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
  Uint8List? _videoThumbnail;
  int _gallerySliderIndex = 0;
  final PageController _galleryPageController =
      PageController(viewportFraction: 0.85);

  // Audio state
  bool _isRecording = false;
  int _recordingDuration = 0;
  double _audioUploadProgress = 0.0;
  List<double> _waveformData = [];
  String? _recordedAudioPath;

  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  // Audio Recorder
  final AudioRecorder _audioRecorder = AudioRecorder();

  // Video Player
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;
  bool _isVideoLoading = false;
  String? _currentVideoUrl;
  String? _localVideoPath;

  // Timeline state
  List<Map<String, dynamic>> _timelineEntries = [];

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _localContent = Map.from(widget.block.content);
    _originalContent = Map.from(widget.block.content);
    _initAudioPlayer();

    if (widget.block.type == ContentBlockType.timeline) {
      final entries = _localContent['entries'];
      if (entries != null && entries is List) {
        _timelineEntries = List<Map<String, dynamic>>.from(
          entries.map((e) => Map<String, dynamic>.from(e)),
        );
      }
    }
  }

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _audioPosition = position;
        });
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _audioDuration = duration;
        });
      }
    });

    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
      }
    });
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _galleryPageController.dispose();
    _disposeVideoPlayer();
    super.dispose();
  }

  void _disposeVideoPlayer() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;
    _isVideoInitialized = false;
  }

  Future<void> _initializeVideoPlayer(String videoSource,
      {bool isLocal = false}) async {
    if (_isVideoLoading) return;

    // Prüfe ob schon mit dieser URL initialisiert
    if (_isVideoInitialized && _currentVideoUrl == videoSource) return;

    setState(() {
      _isVideoLoading = true;
    });

    try {
      // Alten Player disposen
      _disposeVideoPlayer();

      // Neuen Controller erstellen
      if (isLocal) {
        _videoPlayerController = VideoPlayerController.file(File(videoSource));
      } else {
        _videoPlayerController =
            VideoPlayerController.networkUrl(Uri.parse(videoSource));
      }

      await _videoPlayerController!.initialize();

      final isDark = Theme.of(context).brightness == Brightness.dark;

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        showControls: true,
        allowFullScreen: true,
        allowMuting: true,
        showOptions: false,
        showControlsOnInitialize: true,
        hideControlsTimer: const Duration(seconds: 3),
        materialProgressColors: ChewieProgressColors(
          playedColor: isDark ? AppColors.accent : AppColors.primary,
          handleColor: isDark ? AppColors.accent : AppColors.primary,
          backgroundColor: AppColors.grey.withOpacity(0.3),
          bufferedColor: isDark
              ? AppColors.accent.withOpacity(0.5)
              : AppColors.primary.withOpacity(0.5),
        ),
        placeholder: Container(
          color: AppColors.backgroundDark,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: AppColors.backgroundDark,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 42),
                  const SizedBox(height: 12),
                  Text(
                    'Video konnte nicht geladen werden',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          );
        },
      );

      setState(() {
        _isVideoInitialized = true;
        _currentVideoUrl = videoSource;
        _isVideoLoading = false;
      });

      debugPrint('🎬 Video Player initialized: $videoSource');
    } catch (e) {
      debugPrint('❌ Error initializing video player: $e');
      setState(() {
        _isVideoLoading = false;
        _isVideoInitialized = false;
      });
      if (mounted) {
        _showErrorDialog(
            'Video-Fehler', 'Video konnte nicht geladen werden: $e');
      }
    }
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

      // Timeline entries aktualisieren
      if (widget.block.type == ContentBlockType.timeline) {
        final entries = _localContent['entries'];
        if (entries != null && entries is List) {
          _timelineEntries = List<Map<String, dynamic>>.from(
            entries.map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }
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
            color: isDark ? AppColors.backgroundDark : AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.grey.withOpacity(0.5)
                      : AppColors.greyLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header mit Gradient
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                padding: const EdgeInsets.all(16),
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
                            AppColors.primary.withOpacity(0.12),
                            AppColors.primary.withOpacity(0.04),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppColors.accent.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.15),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon mit Gradient
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  AppColors.accent,
                                  AppColors.accent.withOpacity(0.7)
                                ]
                              : [
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0.8)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isDark ? AppColors.accent : AppColors.primary)
                                    .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        BlockTypeInfo.getIcon(widget.block.type),
                        size: 24,
                        color:
                            isDark ? AppColors.primary : AppColors.background,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            BlockTypeInfo.getTitle(widget.block.type),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textLight
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Block bearbeiten',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Close Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _discardChanges,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.toastBackgroundDark
                                : AppColors.greyLighter.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: AppColors.grey,
                          ),
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
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: _buildSettings(),
                ),
              ),

              // Bottom Buttons
              _buildAndroidBottomButtons(isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAndroidBottomButtons(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Abbrechen Button
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.toastBackgroundDark
                    : AppColors.greyLighter.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.greyLight.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _discardChanges,
                  borderRadius: BorderRadius.circular(16),
                  splashColor: AppColors.error.withOpacity(0.1),
                  highlightColor: AppColors.error.withOpacity(0.05),
                  child: Center(
                    child: Text(
                      AppStrings.cancel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textLight : AppColors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Übernehmen Button
          Expanded(
            flex: 2,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.success,
                    AppColors.success.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _confirmChanges,
                  borderRadius: BorderRadius.circular(16),
                  splashColor: Colors.white.withOpacity(0.2),
                  highlightColor: Colors.white.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppStrings.apply,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
      case ContentBlockType.imageText:
        return _buildImageTextSettings();
      case ContentBlockType.timeline:
        return _buildTimelineSettings();
    }
  }

  // ============================================================
// TIMELINE SETTINGS - Füge diese Methoden VOR _buildTextField() ein
// ============================================================

  List<Widget> _buildTimelineSettings() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return [
      // Vorschau
      _buildTimelinePreview(isDark),
      const SizedBox(height: 24),

      // Einträge Liste
      if (_timelineEntries.isNotEmpty) ...[
        _buildTimelineEntriesList(isDark),
        const SizedBox(height: 16),
      ],

      // Eintrag hinzufügen Button
      _buildAddTimelineEntryButton(isDark),

      // Alle entfernen Button
      if (_timelineEntries.length > 1) ...[
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _timelineEntries.clear();
              _localContent['entries'] = [];
              _hasChanges = true;
            });
          },
          icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
          label: const Text(
            'Alle Ereignisse entfernen',
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

  Widget _buildTimelinePreview(bool isDark) {
    if (_timelineEntries.isEmpty) {
      return _buildEmptyTimelineState(isDark);
    }

    // Zeige maximal 3 Einträge in der Vorschau
    final previewEntries = _timelineEntries.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLighter,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_rounded,
                size: 14,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Vorschau',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '${_timelineEntries.length} Ereignis${_timelineEntries.length == 1 ? '' : 'se'}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...previewEntries.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == previewEntries.length - 1;
            return _buildTimelinePreviewEntry(item, isLast, isDark);
          }),
          if (_timelineEntries.length > 3)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 8),
              child: Text(
                '+ ${_timelineEntries.length - 3} weitere...',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelinePreviewEntry(
      Map<String, dynamic> entry, bool isLast, bool isDark) {
    final date = entry['date'] as String? ?? '';
    final label = entry['label'] as String? ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Dot + Line
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isDark ? AppColors.accent : AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isDark
                    ? AppColors.accent.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.accent : AppColors.primary,
                  ),
                ),
                if (label.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTimelineState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDarkElevated
            : AppColors.greyLighter.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLight,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Platform.isIOS ? CupertinoIcons.time : Icons.timeline_rounded,
            size: 48,
            color: AppColors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            'Noch keine Ereignisse',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Füge wichtige Lebensereignisse hinzu',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEntriesList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ereignisse (${_timelineEntries.length})',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_timelineEntries.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildTimelineEntryCard(index, isDark),
          );
        }),
      ],
    );
  }

  Widget _buildTimelineEntryCard(int index, bool isDark) {
    final entry = _timelineEntries[index];
    final date = entry['date'] as String? ?? '';
    final label = entry['label'] as String? ?? '';
    final imageUrl = entry['imageUrl'] as String? ?? '';
    final text = entry['text'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLighter,
        ),
      ),
      child: Row(
        children: [
          // Drag Handle (visuell)
          Icon(
            Icons.drag_indicator_rounded,
            color: AppColors.grey.withOpacity(0.5),
            size: 20,
          ),
          const SizedBox(width: 8),

          // Thumbnail
          if (imageUrl.isNotEmpty)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.greyLighter,
                    child: Icon(Icons.image, size: 20, color: AppColors.grey),
                  ),
                ),
              ),
            ),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.accent : AppColors.primary,
                  ),
                ),
                if (label.isNotEmpty)
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (text.isNotEmpty)
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Edit Button
          IconButton(
            onPressed: () => _editTimelineEntry(index),
            icon: Icon(
              Platform.isIOS ? CupertinoIcons.pencil : Icons.edit_rounded,
              size: 20,
            ),
            color: isDark ? AppColors.accent : AppColors.primary,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),

          // Delete Button
          IconButton(
            onPressed: () => _deleteTimelineEntry(index),
            icon: Icon(
              Platform.isIOS ? CupertinoIcons.trash : Icons.delete_outline,
              size: 20,
            ),
            color: AppColors.error,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildAddTimelineEntryButton(bool isDark) {
    return GestureDetector(
      onTap: _addTimelineEntry,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.accent : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                size: 20,
                color: isDark ? AppColors.primary : AppColors.background,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Ereignis hinzufügen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTimelineEntry() {
    _showTimelineEntryDialog(null, -1);
  }

  void _editTimelineEntry(int index) {
    _showTimelineEntryDialog(_timelineEntries[index], index);
  }

  void _deleteTimelineEntry(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _timelineEntries.removeAt(index);
      _localContent['entries'] = _timelineEntries;
      _hasChanges = true;
    });
  }

  void _showTimelineEntryDialog(Map<String, dynamic>? entry, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = entry != null;

    String date = entry?['date'] ?? '';
    String label = entry?['label'] ?? '';
    String imageUrl = entry?['imageUrl'] ?? '';
    String text = entry?['text'] ?? '';

    final dateController = TextEditingController(text: date);
    final labelController = TextEditingController(text: label);
    final textController = TextEditingController(text: text);

    bool isUploadingImage = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDarkElevated
                    : AppColors.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
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
                          isDark ? AppColors.borderDark : AppColors.greyLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Abbrechen',
                            style: TextStyle(color: AppColors.grey),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          isEditing ? 'Bearbeiten' : 'Ereignis',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            if (dateController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bitte Datum eingeben'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            final newEntry = {
                              'id': entry?['id'] ?? const Uuid().v4(),
                              'date': dateController.text.trim(),
                              'label': labelController.text.trim(),
                              'imageUrl': imageUrl,
                              'text': textController.text.trim(),
                            };

                            setState(() {
                              if (isEditing) {
                                _timelineEntries[index] = newEntry;
                              } else {
                                _timelineEntries.add(newEntry);
                              }
                              _localContent['entries'] = _timelineEntries;
                              _hasChanges = true;
                            });

                            Navigator.pop(context);
                          },
                          child: Text(
                            'Speichern',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? AppColors.accent : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(),

                  // Content
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Datum
                        Text(
                          'Datum *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: dateController,
                          decoration: InputDecoration(
                            hintText: 'z.B. 1985, März 1990, 15.06.2000',
                            filled: true,
                            fillColor: isDark
                                ? AppColors.backgroundDark
                                : AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Bezeichnung
                        Text(
                          'Bezeichnung',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: labelController,
                          decoration: InputDecoration(
                            hintText: 'z.B. Geburt, Hochzeit, Umzug',
                            filled: true,
                            fillColor: isDark
                                ? AppColors.backgroundDark
                                : AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Bild
                        Text(
                          'Bild',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: isUploadingImage
                              ? null
                              : () async {
                                  final XFile? image =
                                      await _imagePicker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 1920,
                                    maxHeight: 1920,
                                    imageQuality: 85,
                                  );
                                  if (image == null) return;

                                  setDialogState(() => isUploadingImage = true);

                                  try {
                                    final url =
                                        await _storageService.uploadBlockImage(
                                      memorialId: widget.memorialId,
                                      blockId:
                                          '${widget.block.id}_timeline_${DateTime.now().millisecondsSinceEpoch}',
                                      imageFile: File(image.path),
                                    );
                                    setDialogState(() {
                                      imageUrl = url;
                                      isUploadingImage = false;
                                    });
                                  } catch (e) {
                                    setDialogState(
                                        () => isUploadingImage = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Upload fehlgeschlagen: $e'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.backgroundDark
                                  : AppColors.greyLighter,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.greyLight,
                              ),
                            ),
                            child: isUploadingImage
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : imageUrl.isNotEmpty
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                      Icons.broken_image),
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () => setDialogState(
                                                  () => imageUrl = ''),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: AppColors.error,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: AppColors.textLight,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_rounded,
                                            size: 32,
                                            color: AppColors.grey,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Bild hinzufügen',
                                            style: TextStyle(
                                              color: AppColors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Beschreibung
                        Text(
                          'Beschreibung',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: textController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Optionale Beschreibung...',
                            filled: true,
                            fillColor: isDark
                                ? AppColors.backgroundDark
                                : AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
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
      },
    );
  }

  List<Widget> _buildHeaderSettings() {
    final text = _getContent('text', 'Überschrift');
    final level = _getContent('level', 1);
    final align = _getContent('align', 'left');
    final color = _getContent('color', '#000000');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Schriftgrößen basierend auf Level
    final fontSizes = {1: 28.0, 2: 22.0, 3: 18.0};
    final fontSize = fontSizes[level] ?? 28.0;

    return [
      // Live-Vorschau
      _buildLivePreviewContainer(
        isDark: isDark,
        child: Text(
          text.isEmpty ? 'Überschrift Vorschau' : text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: text.isEmpty ? AppColors.grey : _hexToColor(color),
            height: 1.3,
          ),
          textAlign: align == 'center'
              ? TextAlign.center
              : align == 'right'
                  ? TextAlign.right
                  : TextAlign.left,
        ),
      ),
      const SizedBox(height: 20),
      _buildTextField(
        label: 'Überschrift',
        key: 'text',
        hint: 'Überschrift eingeben',
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
    final text = _getContent('text', '');
    final fontSize = _getContent('fontSize', 16.0);
    final align = _getContent('align', 'left');
    final color = _getContent('color', '#333333');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return [
      // Live-Vorschau
      _buildLivePreviewContainer(
        isDark: isDark,
        child: Text(
          text.isEmpty
              ? 'Text Vorschau - Bewege den Regler um die Schriftgröße zu ändern'
              : text,
          style: TextStyle(
            fontSize: (fontSize is double ? fontSize : 16.0),
            color: text.isEmpty ? AppColors.grey : _hexToColor(color),
            height: 1.5,
          ),
          textAlign: align == 'center'
              ? TextAlign.center
              : align == 'right'
                  ? TextAlign.right
                  : TextAlign.left,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(height: 20),
      _buildTextField(
        label: 'Text',
        key: 'text',
        hint: 'Text eingeben...',
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

  /// Live-Vorschau Container für Text und Header
  Widget _buildLivePreviewContainer({
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLighter,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_rounded,
                size: 14,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Live-Vorschau',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
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
        hint: 'Bildunterschrift eingeben...',
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
    final List<String> images =
        List<String>.from(_getContent<List>('images', []));
    final displayMode = _getContent('displayMode', 'grid');
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

        // ========================================
        // LIVE-VORSCHAU: Grid ODER Slider
        // ========================================
        if (displayMode == 'grid')
          _buildGalleryGridPreview(images, isDark)
        else
          _buildGallerySliderPreview(images, isDark),

        const SizedBox(height: 20),
      ],

      _buildUploadButton(
        onPressed: _isUploading
            ? null
            : (images.length < 6 ? _handleGalleryImagesUpload : null),
        isUploading: _isUploading,
        label: _isUploading
            ? AppStrings.uploading
            : images.length < 6
                ? '${AppStrings.addImages} (${6 - images.length}${AppStrings.remaining})'
                : AppStrings.maxReachedGallery,
      ),
      const SizedBox(height: 24),

      // Display Mode Toggle (Grid / Slider)
      _buildDisplayModePicker(displayMode, isDark),

      const SizedBox(height: 20),

      // Spalten-Auswahl NUR bei Grid-Modus
      if (displayMode == 'grid') ...[
        _buildDropdown(
          label: AppStrings.columns,
          key: 'columns',
          value: _getContent('columns', 3),
          items: {
            2: AppStrings.columns2,
            3: AppStrings.columns3,
            4: AppStrings.columns4
          },
        ),
      ],
    ];
  }

  Widget _buildGalleryGridPreview(List<String> images, bool isDark) {
    return GridView.builder(
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
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: AppColors.grey,
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

// ============================================================
// SCHRITT 5: NEUE Methode _buildGallerySliderPreview() hinzufügen
// ============================================================
// Nach _buildGalleryGridPreview() einfügen:

  /// Slider/Carousel-Vorschau für Gallery
  Widget _buildGallerySliderPreview(List<String> images, bool isDark) {
    return Column(
      children: [
        // Slider Container
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _galleryPageController,
            onPageChanged: (index) {
              setState(() {
                _gallerySliderIndex = index;
              });
            },
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Stack(
                  children: [
                    // Bild
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        images[index],
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
                          final currentLength = images.length;
                          _removeGalleryImage(index);
                          // Nach dem Löschen: Index anpassen falls nötig
                          if (_gallerySliderIndex >= currentLength - 1 &&
                              _gallerySliderIndex > 0) {
                            setState(() {
                              _gallerySliderIndex--;
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
                    // Bild-Nummer Badge
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
                          '${index + 1}/${images.length}',
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

        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            images.length,
            (index) => GestureDetector(
              onTap: () {
                _galleryPageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _gallerySliderIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _gallerySliderIndex == index
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

  /// Display Mode Picker für Gallery (Grid vs Slider)
  Widget _buildDisplayModePicker(String currentMode, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anzeigemodus',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildDisplayModeOption(
              value: 'grid',
              label: 'Raster',
              icon: Platform.isIOS
                  ? CupertinoIcons.square_grid_2x2
                  : Icons.grid_view_rounded,
              currentMode: currentMode,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            _buildDisplayModeOption(
              value: 'slider',
              label: 'Slider',
              icon: Platform.isIOS
                  ? CupertinoIcons.rectangle_on_rectangle_angled
                  : Icons.view_carousel_rounded,
              currentMode: currentMode,
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisplayModeOption({
    required String value,
    required String label,
    required IconData icon,
    required String currentMode,
    required bool isDark,
  }) {
    final isSelected = currentMode == value;

    return Expanded(
      child: Container(
        height: 72,
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
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? AppColors.accent : AppColors.primary)
                        .withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              _updateLocalValue('displayMode', value);
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? (isDark ? AppColors.accent : AppColors.primary)
                      : AppColors.grey,
                  size: 26,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? AppColors.accent : AppColors.primary)
                        : AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        hint: 'Zitat eingeben...',
        maxLines: 4,
      ),
      const SizedBox(height: 20),
      _buildTextField(
        label: 'Autor',
        key: 'author',
        hint: 'Name des Autors',
      ),
      const SizedBox(height: 20),
      _buildColorPicker('color', 'Farbe'),
    ];
  }

  // ============================================================
  // VIDEO SETTINGS - MIT CHEWIE PLAYER
  // ============================================================
  List<Widget> _buildVideoSettings() {
    final currentUrl = _getContent('url', '');
    final autoplay = _getContent('autoplay', false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Video Player NUR initialisieren wenn URL vorhanden UND nicht am uploaden
    if (currentUrl.isNotEmpty &&
        !_isVideoInitialized &&
        !_isVideoLoading &&
        !_isUploading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeVideoPlayer(currentUrl);
      });
    }

    return [
      // Video Preview mit Chewie Player
      if (currentUrl.isNotEmpty || _videoThumbnail != null || _isUploading) ...[
        _buildVideoPreviewWithPlayer(isDark),
        const SizedBox(height: 20),
      ],
      _buildUploadButton(
        onPressed: _isUploading ? null : _handleVideoUpload,
        isUploading: _isUploading,
        label: _isUploading
            ? 'Uploading... ${(_videoUploadProgress * 100).toInt()}%'
            : currentUrl.isEmpty
                ? 'Video hochladen'
                : 'Video ersetzen',
      ),
      const SizedBox(height: 8),
      _buildInfoText('Max. 15 Sekunden • Max. 50MB'),
      const SizedBox(height: 20),
      _buildAutoplayToggle(isDark, autoplay),
      const SizedBox(height: 20),
      _buildTextField(
        label: 'Beschreibung',
        key: 'caption',
        hint: 'Beschreibung eingeben...',
        maxLines: 2,
      ),
      // Video entfernen Button
      if (currentUrl.isNotEmpty) ...[
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            _disposeVideoPlayer();
            _updateLocalValue('url', '');
            _updateLocalValue('thumbnailUrl', '');
            setState(() {
              _videoThumbnail = null;
              _localVideoPath = null;
            });
          },
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          label: const Text(
            'Video entfernen',
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

  Widget _buildVideoPreviewWithPlayer(bool isDark) {
    final thumbnailUrl = _getContent('thumbnailUrl', '');
    final currentUrl = _getContent('url', '');

    // Video ist nur abspielbar wenn Upload fertig (URL vorhanden) und nicht gerade uploading
    final bool canPlay = currentUrl.isNotEmpty && !_isUploading;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Video Player oder Thumbnail
            if (_isVideoInitialized && _chewieController != null && canPlay)
              LayoutBuilder(
                builder: (context, constraints) {
                  final aspectRatio =
                      _videoPlayerController!.value.aspectRatio > 0
                          ? _videoPlayerController!.value.aspectRatio
                          : 16 / 9;
                  // Berechne Höhe basierend auf verfügbarer Breite
                  final videoHeight =
                      (constraints.maxWidth / aspectRatio).clamp(120.0, 250.0);

                  return SizedBox(
                    width: constraints.maxWidth,
                    height: videoHeight,
                    child: Chewie(controller: _chewieController!),
                  );
                },
              )
            else if (_isVideoLoading || _isUploading)
              Container(
                height: 160,
                color: AppColors.backgroundDark,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isUploading) ...[
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            value: _videoUploadProgress > 0
                                ? _videoUploadProgress
                                : null,
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? AppColors.accent : AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Upload: ${(_videoUploadProgress * 100).toInt()}%',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else ...[
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? AppColors.accent : AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Video wird geladen...',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              // Fallback: Thumbnail oder Placeholder - Tap to play
              GestureDetector(
                onTap: canPlay
                    ? () {
                        _initializeVideoPlayer(currentUrl);
                      }
                    : null,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_videoThumbnail != null)
                        Image.memory(_videoThumbnail!, fit: BoxFit.cover)
                      else if (thumbnailUrl.isNotEmpty)
                        Image.network(thumbnailUrl, fit: BoxFit.cover)
                      else
                        Center(
                          child: Icon(
                            Icons.videocam_rounded,
                            size: 48,
                            color: AppColors.grey,
                          ),
                        ),
                      // Play Overlay - nur wenn abspielbar
                      if (canPlay)
                        Container(
                          color: AppColors.backgroundDark.withOpacity(0.3),
                          child: Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.surface.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                size: 32,
                                color: isDark
                                    ? AppColors.accent
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Status Badge
            if (currentUrl.isNotEmpty && !_isUploading && !_isVideoInitialized)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 14, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text(
                        'Tippen zum Abspielen',
                        style: TextStyle(
                          fontSize: 11,
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
    );
  }

  Widget _buildUploadButton({
    required VoidCallback? onPressed,
    required bool isUploading,
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: isUploading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.primary : AppColors.background,
                  ),
                ),
              )
            : Icon(
                Platform.isIOS
                    ? CupertinoIcons.cloud_upload
                    : Icons.upload_rounded,
                size: 22,
              ),
        label: Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? AppColors.accent : AppColors.primary,
          foregroundColor: isDark ? AppColors.primary : AppColors.background,
          disabledBackgroundColor:
              isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.grey),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, color: AppColors.grey)),
        ],
      ),
    );
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

      // Video Player zurücksetzen
      _disposeVideoPlayer();

      // Thumbnail generieren für Vorschau während Upload
      await _generateVideoThumbnail(video.path);

      setState(() {
        _isUploading = true;
        _videoUploadProgress = 0.0;
        _localVideoPath = null; // Kein lokales Playback während Upload
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

      if (_videoThumbnail != null) {
        try {
          final thumbnailUrl = await _storageService.uploadVideoThumbnail(
            memorialId: widget.memorialId,
            blockId: widget.block.id,
            thumbnailData: _videoThumbnail!,
          );
          _updateLocalValue('thumbnailUrl', thumbnailUrl);
        } catch (e) {
          debugPrint('Thumbnail upload failed: $e');
        }
      }

      setState(() {
        _isUploading = false;
        _videoUploadProgress = 0.0;
      });

      // ERST JETZT nach erfolgreichem Upload: Player initialisieren
      await _initializeVideoPlayer(downloadUrl);

      if (mounted) {
        _showSuccessSnackBar('Video erfolgreich hochgeladen!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Fehler', e.toString());
      }
      setState(() {
        _isUploading = false;
        _videoUploadProgress = 0.0;
      });
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
        setState(() => _videoThumbnail = thumbnail);
      }
    } catch (e) {
      debugPrint('Failed to generate thumbnail: $e');
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
  // Audio Settings - MIT AUDIODATEI AUSWÄHLEN BUTTON UND PLAYBACK
  // ============================================================
  List<Widget> _buildAudioSettings() {
    final currentUrl = _getContent('url', '');
    final title = _getContent('title', '');
    final duration = _getContent('duration', 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String formatDurationInt(int seconds) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }

    return [
      // Audio Preview
      if (currentUrl.isNotEmpty || _recordedAudioPath != null) ...[
        _buildAudioPreviewWithPlayback(isDark, duration, currentUrl),
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
                ? 'Aufnahme stoppen (${formatDurationInt(_recordingDuration)})'
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

      const SizedBox(height: 12),

      // Audiodatei auswählen Button
      SizedBox(
        height: 56,
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _isUploading || _isRecording ? null : _pickAudioFile,
          icon: Icon(
            Platform.isIOS ? CupertinoIcons.folder : Icons.folder_rounded,
            size: 22,
          ),
          label: const Text(
            'Audiodatei auswählen',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor:
                isDark ? AppColors.textLight : AppColors.textPrimary,
            side: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.greyLight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),

      const SizedBox(height: 8),

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

      if (_isUploading) ...[
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _audioUploadProgress.isNaN
                ? 0.0
                : _audioUploadProgress.clamp(0.0, 1.0),
            backgroundColor:
                isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter,
            valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppColors.accent : AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Wird hochgeladen... ${_audioUploadProgress.isNaN ? 0 : (_audioUploadProgress * 100).toInt()}%',
          style: TextStyle(fontSize: 13, color: AppColors.grey),
        ),
      ],

      const SizedBox(height: 24),

      _buildTextField(
        label: 'Titel (optional)',
        key: 'title',
        hint: 'z.B. "Persönliche Nachricht"',
      ),

      if (currentUrl.isNotEmpty) ...[
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            _audioPlayer.stop();
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

  Widget _buildAudioPreviewWithPlayback(
      bool isDark, int duration, String currentUrl) {
    String formatDuration(Duration d) {
      final minutes = d.inMinutes;
      final seconds = d.inSeconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    final totalDuration = _audioDuration.inSeconds > 0
        ? _audioDuration
        : Duration(seconds: duration);
    final progress = totalDuration.inMilliseconds > 0
        ? _audioPosition.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;

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
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Play/Pause Button
              GestureDetector(
                onTap: currentUrl.isNotEmpty
                    ? () => _toggleAudioPlayback(currentUrl)
                    : null,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.accent : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying
                        ? (Platform.isIOS
                            ? CupertinoIcons.pause_fill
                            : Icons.pause_rounded)
                        : (Platform.isIOS
                            ? CupertinoIcons.play_fill
                            : Icons.play_arrow_rounded),
                    color: isDark ? AppColors.primary : AppColors.background,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Waveform / Progress
              Expanded(
                child: Column(
                  children: [
                    // Waveform Visualization
                    SizedBox(
                      height: 32,
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

                          final barProgress = index / 20;
                          final isActive = barProgress <= progress;

                          return Container(
                            width: 3,
                            height: 36 * heightFactor,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? (isDark
                                      ? AppColors.accent
                                      : AppColors.primary)
                                  : (isDark
                                      ? AppColors.accent.withOpacity(0.3)
                                      : AppColors.primary.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor:
                            isDark ? AppColors.accent : AppColors.primary,
                        inactiveTrackColor: isDark
                            ? AppColors.accent.withOpacity(0.3)
                            : AppColors.primary.withOpacity(0.3),
                        thumbColor:
                            isDark ? AppColors.accent : AppColors.primary,
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: currentUrl.isNotEmpty
                            ? (value) {
                                final newPosition = Duration(
                                  milliseconds:
                                      (value * totalDuration.inMilliseconds)
                                          .round(),
                                );
                                _audioPlayer.seek(newPosition);
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Duration
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatDuration(_audioPosition),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    formatDuration(totalDuration),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    );
  }

  Future<void> _toggleAudioPlayback(String url) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        // Prüfe ob wir neu laden müssen
        final bool needsReload = _audioPlayer.audioSource == null;

        if (needsReload) {
          // PRIORITÄT 1: Echte Firebase URL verwenden (nicht example.com)
          if (url.isNotEmpty &&
              (url.startsWith('https://firebasestorage.googleapis.com') ||
                  (url.startsWith('http') && !url.contains('example.com')))) {
            await _audioPlayer.setUrl(url);
            debugPrint('🎵 Playing Firebase URL: $url');
          }
          // PRIORITÄT 2: Lokale Datei nur wenn KEINE echte URL existiert
          else if (_recordedAudioPath != null &&
              _recordedAudioPath!.isNotEmpty &&
              !_recordedAudioPath!.contains('simulated')) {
            final file = File(_recordedAudioPath!);
            if (await file.exists()) {
              await _audioPlayer.setFilePath(_recordedAudioPath!);
              debugPrint(
                  '🎵 Playing local file (no Firebase URL yet): $_recordedAudioPath');
            } else {
              throw Exception('Lokale Datei nicht gefunden');
            }
          } else {
            throw Exception('NO_VALID_SOURCE');
          }
        }

        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('❌ Audio playback error: $e');
      if (mounted) {
        String errorMessage;

        if (e.toString().contains('SIMULATED_URL') ||
            e.toString().contains('NO_VALID_SOURCE')) {
          errorMessage = 'Das Audio ist noch nicht verfügbar.\n\n'
              'Bitte nimm ein neues Sprachmemo auf oder wähle eine Audiodatei aus.';
        } else if (e.toString().contains('Lokale Datei nicht gefunden')) {
          errorMessage = 'Die lokale Audiodatei wurde nicht gefunden.';
        } else if (e.toString().contains('404') ||
            e.toString().contains('Not Found')) {
          errorMessage = 'Die Audiodatei wurde auf dem Server nicht gefunden.';
        } else if (e.toString().contains('Connection') ||
            e.toString().contains('SocketException')) {
          errorMessage = 'Keine Internetverbindung verfügbar.';
        } else {
          errorMessage =
              'Audio konnte nicht abgespielt werden.\n\nFehler: ${e.toString()}';
        }

        _showErrorDialog('Wiedergabefehler', errorMessage);
      }
    }
  }

  // ============================================================
  // NEU: _pickAudioFile Methode
  // ============================================================
  Future<void> _pickAudioFile() async {
    if (_isUploading || _isRecording) return;

    // Stop any playing audio first
    await _audioPlayer.stop();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'ogg', 'flac'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      if (file.path == null) {
        _showErrorDialog('Fehler', 'Datei konnte nicht geladen werden.');
        return;
      }

      final audioFile = File(file.path!);
      final fileSize = await audioFile.length();

      // Max 10 MB
      if (fileSize > 10 * 1024 * 1024) {
        _showErrorDialog('Datei zu groß', 'Max. 10 MB erlaubt.');
        return;
      }

      // Versuche die echte Dauer zu ermitteln
      int audioDuration;
      try {
        await _audioPlayer.setFilePath(file.path!);
        final duration = _audioPlayer.duration;
        audioDuration =
            duration?.inSeconds ?? (fileSize / 16000).round().clamp(1, 120);
        await _audioPlayer.stop();
      } catch (e) {
        // Fallback: Geschätzte Dauer basierend auf Dateigröße
        audioDuration = (fileSize / 16000).round().clamp(1, 120);
      }

      setState(() {
        _recordedAudioPath = file.path; // Echte lokale Datei!
        _recordingDuration = audioDuration;
        _hasChanges = true;
        _waveformData = List.generate(
            24, (index) => 0.3 + (0.7 * ((index * 7 + 3) % 10) / 10));
        // Reset audio player für neue Quelle
        _audioPosition = Duration.zero;
        _audioDuration = Duration(seconds: audioDuration);
      });

      _updateLocalValue('duration', _recordingDuration);
      _updateLocalValue('waveformData', _waveformData);
      // Setze eine Markierung dass wir eine lokale Datei haben
      _updateLocalValue('localPath', file.path);

      if (mounted) {
        _showSuccessSnackBar(
            'Audiodatei "${file.name}" geladen! Tippe auf Play zum Anhören.');
      }
    } catch (e) {
      _showErrorDialog('Fehler', e.toString());
    }
  }

  void _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    // Stop any playing audio first
    await _audioPlayer.stop();

    try {
      // Check microphone permission
      if (!await _audioRecorder.hasPermission()) {
        if (mounted) {
          _showErrorDialog(
            'Berechtigung erforderlich',
            'Bitte erlaube den Zugriff auf das Mikrofon in den Einstellungen.',
          );
        }
        return;
      }

      // Get temp directory for recording
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath =
          '${tempDir.path}/audio_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Configure recording
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      // Start recording
      await _audioRecorder.start(config, path: filePath);

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
        _waveformData = [];
        _recordedAudioPath = filePath;
      });

      if (Platform.isIOS) {
        HapticFeedback.mediumImpact();
      }

      debugPrint('🎤 Recording started: $filePath');

      // Start timer with amplitude tracking
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 1));
        if (!_isRecording || !mounted) return false;

        // Get amplitude for waveform visualization
        try {
          final amplitude = await _audioRecorder.getAmplitude();
          final normalizedAmplitude =
              ((amplitude.current + 60) / 60).clamp(0.1, 1.0);

          setState(() {
            _recordingDuration++;
            if (_waveformData.length < 24) {
              _waveformData.add(normalizedAmplitude);
            } else {
              _waveformData.removeAt(0);
              _waveformData.add(normalizedAmplitude);
            }
          });
        } catch (e) {
          setState(() {
            _recordingDuration++;
            if (_waveformData.length < 24) {
              _waveformData.add(0.3 +
                  (0.7 * (DateTime.now().millisecondsSinceEpoch % 100) / 100));
            }
          });
        }

        if (_recordingDuration >= 120) {
          _stopRecording();
          return false;
        }

        return true;
      });
    } catch (e) {
      debugPrint('❌ Error starting recording: $e');
      if (mounted) {
        _showErrorDialog(
            'Aufnahmefehler', 'Aufnahme konnte nicht gestartet werden: $e');
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      // Stop the recorder and get the file path
      final String? path = await _audioRecorder.stop();

      setState(() => _isRecording = false);

      if (Platform.isIOS) {
        HapticFeedback.mediumImpact();
      }

      if (path != null && _recordingDuration > 0) {
        final file = File(path);
        if (await file.exists()) {
          setState(() {
            _recordedAudioPath = path;
            _hasChanges = true;
          });

          _updateLocalValue('duration', _recordingDuration);
          _updateLocalValue('waveformData', _waveformData);

          debugPrint('🎤 Recording stopped: $path');

          // Show upload dialog
          _showUploadAudioDialog();
        } else {
          throw Exception('Aufnahmedatei nicht gefunden');
        }
      }
    } catch (e) {
      debugPrint('❌ Error stopping recording: $e');
      setState(() => _isRecording = false);
      if (mounted) {
        _showErrorDialog(
            'Aufnahmefehler', 'Aufnahme konnte nicht gespeichert werden: $e');
      }
    }
  }

  void _showUploadAudioDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Sprachmemo aufgenommen'),
          content: const Text('Möchtest du das Sprachmemo jetzt hochladen?'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Später'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Hochladen'),
              onPressed: () {
                Navigator.pop(ctx);
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

  Future<void> _uploadAudio() async {
    if (_recordedAudioPath == null) return;

    setState(() {
      _isUploading = true;
      _audioUploadProgress = 0.0;
    });

    try {
      final audioFile = File(_recordedAudioPath!);

      // Check if file exists
      if (!await audioFile.exists()) {
        throw Exception('Audio-Datei nicht gefunden');
      }

      final String downloadUrl = await _storageService.uploadBlockAudio(
        memorialId: widget.memorialId,
        blockId: widget.block.id,
        audioFile: audioFile,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _audioUploadProgress = progress;
            });
          }
        },
      );

      _updateLocalValue('url', downloadUrl);

      // Reset audio player completely for new Firebase URL
      await _audioPlayer.stop();

      // Clear local path so Firebase URL will be used
      setState(() {
        _recordedAudioPath = null;
      });

      // Force reload by disposing and recreating audio source
      try {
        await _audioPlayer.setUrl(downloadUrl);
        debugPrint('🎵 AudioPlayer loaded with Firebase URL: $downloadUrl');
      } catch (e) {
        debugPrint('⚠️ Could not preload audio: $e');
      }

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
  // IMAGE TEXT SETTINGS
  // ============================================================
  List<Widget> _buildImageTextSettings() {
    final currentImageUrl = _getContent('imageUrl', '');
    final currentLayout = _getContent('layout', 'left');
    final currentImageSize = _getContent('imageSize', 0.4);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return [
      // Bild-Vorschau
      if (currentImageUrl.isNotEmpty) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            currentImageUrl,
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
      SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _isUploading ? null : _handleImageTextUpload,
          icon: _isUploading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.textLight)),
                )
              : Icon(
                  Platform.isIOS
                      ? CupertinoIcons.cloud_upload
                      : Icons.upload_rounded,
                  size: 22),
          label: Text(
            _isUploading
                ? 'Wird hochgeladen...'
                : currentImageUrl.isEmpty
                    ? 'Bild hochladen'
                    : 'Bild ersetzen',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: isDark ? AppColors.accent : AppColors.primary,
            foregroundColor: isDark ? AppColors.primary : AppColors.background,
            disabledBackgroundColor:
                isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),

      const SizedBox(height: 24),

      // Titel
      _buildTextField(
        label: 'Titel (optional)',
        key: 'title',
        hint: 'z.B. "Eine besondere Erinnerung"',
      ),

      const SizedBox(height: 20),

      // Text
      _buildTextField(
        label: 'Text',
        key: 'text',
        hint: 'Text eingeben...',
        maxLines: 6,
      ),

      const SizedBox(height: 20),

      // Bildunterschrift
      _buildTextField(
        label: 'Bildunterschrift (optional)',
        key: 'imageCaption',
        hint: 'Kurze Beschreibung des Bildes',
      ),

      const SizedBox(height: 24),

      _buildColorPicker('color', 'Textfarbe'),

      const SizedBox(height: 24),

      // Layout-Auswahl
      _buildLayoutPicker(currentLayout, isDark),

      const SizedBox(height: 24),

      // Bildgröße (nur bei left/right Layout)
      if (currentLayout == 'left' || currentLayout == 'right') ...[
        _buildImageSizeSlider(currentImageSize, isDark),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Bestimmt das Verhältnis zwischen Bild und Text (${((currentImageSize is double ? currentImageSize : 0.4) * 100).round()}% Bild)',
            style: TextStyle(fontSize: 12, color: AppColors.grey),
          ),
        ),
      ],

      // Bild entfernen Button
      if (currentImageUrl.isNotEmpty) ...[
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            _updateLocalValue('imageUrl', '');
          },
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          label: const Text(
            'Bild entfernen',
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

  Widget _buildLayoutPicker(String currentLayout, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layout',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildLayoutOption('left', 'Bild links', Icons.border_left_rounded,
                currentLayout, isDark),
            const SizedBox(width: 8),
            _buildLayoutOption('right', 'Bild rechts',
                Icons.border_right_rounded, currentLayout, isDark),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildLayoutOption('top', 'Bild oben',
                Icons.vertical_align_top_rounded, currentLayout, isDark),
            const SizedBox(width: 8),
            _buildLayoutOption('bottom', 'Bild unten',
                Icons.vertical_align_bottom_rounded, currentLayout, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildLayoutOption(
    String value,
    String label,
    IconData icon,
    String currentLayout,
    bool isDark,
  ) {
    final isSelected = currentLayout == value;

    return Expanded(
      child: Container(
        height: 72,
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
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? AppColors.accent : AppColors.primary)
                        .withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              _updateLocalValue('layout', value);
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? (isDark ? AppColors.accent : AppColors.primary)
                      : AppColors.grey,
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? AppColors.accent : AppColors.primary)
                        : AppColors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSizeSlider(dynamic currentImageSize, bool isDark) {
    final value = currentImageSize is double ? currentImageSize : 0.4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bildbreite',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
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
                '${(value * 100).round()}%',
                style: TextStyle(
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
            trackHeight: 4,
          ),
          child: Slider(
            value: value.clamp(0.3, 0.7),
            min: 0.3,
            max: 0.7,
            divisions: 8,
            onChanged: (newValue) => _updateLocalValue('imageSize', newValue),
          ),
        ),
      ],
    );
  }

  Future<void> _handleImageTextUpload() async {
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

      _updateLocalValue('imageUrl', downloadUrl);

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

  // ============================================================
  // Common UI Builders
  // ============================================================
  Widget _buildTextField({
    required String label,
    required String key,
    String? hint,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _getController(key, ''),
          maxLines: maxLines,
          style: TextStyle(
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
            fontSize: 17,
          ),
          decoration: InputDecoration(
            hintText: hint ?? label,
            hintStyle: TextStyle(color: AppColors.grey),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) => _updateLocalValue(key, value),
        ),
      ],
    );
  }

  // ============================================================
  // KORRIGIERTES DROPDOWN - JETZT IDENTISCH MIT CONFIGURATION SCREEN
  // ============================================================
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
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField(
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
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.greyLighter,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    final isDecimal = (max - min) < 1;
    final displayValue =
        isDecimal ? '${(value * 100).round()}%' : value.round().toString();

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
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
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
                displayValue,
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
            trackHeight: 4,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: isDecimal ? 10 : (max - min).round(),
            onChanged: (newValue) => _updateLocalValue(key, newValue),
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
          'Ausrichtung',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
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

  // ============================================================
  // Color Picker mit Color Wheel
  // ============================================================
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
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Color Preview Button - öffnet den Color Picker
        GestureDetector(
          onTap: () async {
            final selectedColor = await showColorPickerDialog(
              context: context,
              currentColor: currentColor,
              title: label,
            );

            if (selectedColor != null) {
              _updateLocalValue(key, selectedColor);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.greyLighter,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Farbvorschau
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _hexToColor(currentColor),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark ? AppColors.borderDark : AppColors.greyLight,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _hexToColor(currentColor).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Hex Code
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ausgewählte Farbe',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentColor.toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: Platform.isIOS ? 'SF Mono' : 'monospace',
                          letterSpacing: 1.5,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Pfeil Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.accent.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Platform.isIOS
                        ? CupertinoIcons.color_filter
                        : Icons.palette_rounded,
                    size: 22,
                    color: isDark ? AppColors.accent : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
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

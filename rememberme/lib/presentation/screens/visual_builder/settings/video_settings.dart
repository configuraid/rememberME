import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chewie/chewie.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/core/constants/app_strings.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/config_text_field.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/info_text.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/live_preview_container.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/upload_button.dart';

class VideoSettings extends StatefulWidget {
  final Map<String, dynamic> content;
  final ValueChanged<String> onValueChanged;
  final Future<void> Function() onUploadVideo;
  final ChewieController? chewieController;
  final bool isVideoInitialized;
  final bool isVideoLoading;
  final bool isUploading;
  final double uploadProgress;
  final Uint8List? thumbnail;
  final VoidCallback? onInitializePlayer;

  const VideoSettings({
    super.key,
    required this.content,
    required this.onValueChanged,
    required this.onUploadVideo,
    this.chewieController,
    required this.isVideoInitialized,
    required this.isVideoLoading,
    required this.isUploading,
    required this.uploadProgress,
    this.thumbnail,
    this.onInitializePlayer,
  });

  @override
  State<VideoSettings> createState() => _VideoSettingsState();
}

class _VideoSettingsState extends State<VideoSettings> {
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
  String get _thumbnailUrl => widget.content['thumbnailUrl'] ?? '';
  bool get _autoplay => widget.content['autoplay'] ?? false;

  void _updateValue(String key, dynamic value) {
    widget.onValueChanged('$key:${value.toString()}');
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool canPlay = _url.isNotEmpty && !widget.isUploading;

    return Column(
      children: [
        // ===== STICKY: Live Preview oben fixiert =====
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: LivePreviewContainer(
            child: _url.isNotEmpty ||
                    widget.thumbnail != null ||
                    widget.isUploading
                ? _buildVideoPreviewWithCaption(isDark, canPlay)
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
                  onPressed: widget.isUploading ? null : widget.onUploadVideo,
                  isUploading: widget.isUploading,
                  label: widget.isUploading
                      ? 'Uploading... ${(widget.uploadProgress * 100).toInt()}%'
                      : _url.isEmpty
                          ? 'Video hochladen'
                          : 'Video ersetzen',
                ),
                const SizedBox(height: 20),

                // Autoplay Toggle
                _buildAutoplayToggle(isDark),
                const SizedBox(height: 20),

                // Caption
                ConfigTextField(
                  label: AppStrings.description,
                  controller: _captionController,
                  hint: 'Beschreibung (optional)',
                  maxLines: 2,
                  onChanged: (value) {
                    _updateValue('caption', value);
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
            Platform.isIOS ? CupertinoIcons.videocam : Icons.videocam_rounded,
            size: 36,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 10),
          Text(
            'Kein Video',
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
  // Live Preview – Video + Beschreibung
  // ============================================================

  Widget _buildVideoPreviewWithCaption(bool isDark, bool canPlay) {
    final caption = _captionController.text;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildVideoPreview(isDark, canPlay),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            caption,
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

  // ============================================================
  // Live Preview – Video Player
  // ============================================================

  Widget _buildVideoPreview(bool isDark, bool canPlay) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Chewie Player
          if (widget.isVideoInitialized &&
              widget.chewieController != null &&
              canPlay)
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Chewie(controller: widget.chewieController!),
            )
          // Loading / Uploading
          else if (widget.isVideoLoading || widget.isUploading)
            Container(
              height: 150,
              color: AppColors.backgroundDark,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isUploading) ...[
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          value: widget.uploadProgress > 0
                              ? widget.uploadProgress
                              : null,
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? AppColors.accent : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Upload: ${(widget.uploadProgress * 100).toInt()}%',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else ...[
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? AppColors.accent : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Video wird geladen...',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          // Thumbnail / Tap to Play
          else
            GestureDetector(
              onTap: canPlay ? widget.onInitializePlayer : null,
              child: Container(
                height: 150,
                decoration: const BoxDecoration(
                  color: AppColors.backgroundDark,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.thumbnail != null)
                      Image.memory(widget.thumbnail!, fit: BoxFit.cover)
                    else if (_thumbnailUrl.isNotEmpty)
                      Image.network(_thumbnailUrl, fit: BoxFit.cover)
                    else
                      Center(
                        child: Icon(
                          Platform.isIOS
                              ? CupertinoIcons.videocam
                              : Icons.videocam_rounded,
                          size: 40,
                          color: AppColors.grey,
                        ),
                      ),
                    if (canPlay)
                      Container(
                        color: AppColors.backgroundDark.withOpacity(0.3),
                        child: Center(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surface.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Platform.isIOS
                                  ? CupertinoIcons.play_fill
                                  : Icons.play_arrow_rounded,
                              size: 28,
                              color:
                                  isDark ? AppColors.accent : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // "Tippen zum Abspielen" Badge
          if (_url.isNotEmpty &&
              !widget.isUploading &&
              !widget.isVideoInitialized)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.accent : AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Platform.isIOS
                          ? CupertinoIcons.checkmark_circle_fill
                          : Icons.check_circle,
                      size: 14,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tippen zum Abspielen',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                        fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // Autoplay Toggle
  // ============================================================

  Widget _buildAutoplayToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLighter,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            _updateValue('autoplay', !_autoplay);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _autoplay
                        ? (isDark ? AppColors.accent : AppColors.primary)
                            .withOpacity(isDark ? 0.2 : 0.1)
                        : (isDark
                            ? AppColors.toastBackgroundDark
                            : AppColors.greyLighter),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _autoplay
                        ? (Platform.isIOS
                            ? CupertinoIcons.play_circle_fill
                            : Icons.play_circle_filled_rounded)
                        : (Platform.isIOS
                            ? CupertinoIcons.play_circle
                            : Icons.play_circle_outline_rounded),
                    size: 24,
                    color: _autoplay
                        ? (isDark ? AppColors.accent : AppColors.primary)
                        : AppColors.grey,
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
                      Text(
                        _autoplay
                            ? 'Video startet automatisch'
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
                  value: _autoplay,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    _updateValue('autoplay', value);
                  },
                  activeColor: isDark ? AppColors.accent : AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/config_text_field.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/info_text.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/live_preview_container.dart';

class AudioSettings extends StatefulWidget {
  final Map<String, dynamic> content;
  final ValueChanged<String> onValueChanged;
  final VoidCallback onPickAudioFile;
  final Future<void> Function(String url) onTogglePlayback;
  final bool isPlaying;
  final bool isUploading;
  final double uploadProgress;
  final Duration audioPosition;
  final Duration audioDuration;

  const AudioSettings({
    super.key,
    required this.content,
    required this.onValueChanged,
    required this.onPickAudioFile,
    required this.onTogglePlayback,
    required this.isPlaying,
    required this.isUploading,
    required this.uploadProgress,
    required this.audioPosition,
    required this.audioDuration,
  });

  @override
  State<AudioSettings> createState() => _AudioSettingsState();
}

class _AudioSettingsState extends State<AudioSettings> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _getString('title'));
    _descriptionController =
        TextEditingController(text: _getString('description'));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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

  String get _url => _getString('url');
  int get _duration => _getInt('duration', 0);

  void _updateValue(String key, dynamic value) {
    widget.onValueChanged('$key:${value.toString()}');
  }

  String _formatDurationObj(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
                ? _buildAudioPreview(isDark)
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
                // Audiodatei auswählen
                _buildPickAudioButton(isDark),
                const SizedBox(height: 8),

                const InfoText(text: 'Max. 2 Minuten • MP3, M4A, WAV'),

                if (widget.isUploading) ...[
                  const SizedBox(height: 20),
                  _buildUploadProgress(isDark),
                ],

                const SizedBox(height: 24),

                // Titel
                ConfigTextField(
                  label: 'Titel (optional)',
                  controller: _titleController,
                  hint: 'z.B. "Lieblingslied"',
                  onChanged: (value) => _updateValue('title', value),
                ),

                const SizedBox(height: 16),

                // Beschreibung
                ConfigTextField(
                  label: 'Beschreibung (optional)',
                  controller: _descriptionController,
                  hint: 'z.B. "Ein Lied, das uns immer begleitet hat"',
                  maxLines: 3,
                  onChanged: (value) => _updateValue('description', value),
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
            Platform.isIOS
                ? CupertinoIcons.music_note_2
                : Icons.audio_file_rounded,
            size: 36,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 10),
          Text(
            'Keine Audiodatei',
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
  // Live Preview – Audio Player
  // ============================================================

  Widget _buildAudioPreview(bool isDark) {
    final totalDuration = widget.audioDuration.inSeconds > 0
        ? widget.audioDuration
        : Duration(seconds: _duration);
    final progress = totalDuration.inMilliseconds > 0
        ? widget.audioPosition.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;
    final accentColor = isDark ? AppColors.accent : AppColors.primary;
    final title = _getString('title');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Play/Pause Button
              GestureDetector(
                onTap: _url.isNotEmpty
                    ? () => widget.onTogglePlayback(_url)
                    : null,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isPlaying
                        ? (Platform.isIOS
                            ? CupertinoIcons.pause_fill
                            : Icons.pause_rounded)
                        : (Platform.isIOS
                            ? CupertinoIcons.play_fill
                            : Icons.play_arrow_rounded),
                    color: isDark ? AppColors.primary : AppColors.background,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Waveform + Progress
              Expanded(
                child: Column(
                  children: [
                    // Waveform Bars
                    SizedBox(
                      height: 28,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(24, (index) {
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
                            0.8,
                            0.3,
                            0.6,
                            0.4,
                          ];
                          final barProgress = index / 24;
                          final isActive = barProgress <= progress;

                          return Container(
                            width: 2.5,
                            height: 28 * heights[index],
                            decoration: BoxDecoration(
                              color: isActive
                                  ? accentColor
                                  : accentColor.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Thin progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 3,
                        backgroundColor: accentColor.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
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
                    _formatDurationObj(widget.audioPosition),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
                    ),
                  ),
                  Text(
                    _formatDurationObj(totalDuration),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.grey,
                      fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Titel unter dem Player (wenn vorhanden)
          if (title.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              title,
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

          // Beschreibung unter dem Titel (wenn vorhanden)
          if (_getString('description').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _getString('description'),
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
      ),
    );
  }

  // ============================================================
  // Audiodatei auswählen
  // ============================================================

  Widget _buildPickAudioButton(bool isDark) {
    final hasAudio = _url.isNotEmpty;

    return SizedBox(
      height: 56,
      width: double.infinity,
      child: hasAudio
          ? OutlinedButton.icon(
              onPressed: widget.isUploading ? null : widget.onPickAudioFile,
              icon: Icon(
                Platform.isIOS ? CupertinoIcons.folder : Icons.folder_rounded,
                size: 22,
              ),
              label: const Text(
                'Andere Datei auswählen',
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
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : FilledButton.icon(
              onPressed: widget.isUploading ? null : widget.onPickAudioFile,
              icon: Icon(
                Platform.isIOS
                    ? CupertinoIcons.music_note_2
                    : Icons.audio_file_rounded,
                size: 24,
              ),
              label: const Text(
                'Audiodatei auswählen',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? AppColors.accent : AppColors.primary,
                foregroundColor:
                    isDark ? AppColors.primary : AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }

  // ============================================================
  // Upload Progress
  // ============================================================

  Widget _buildUploadProgress(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
                  value: widget.uploadProgress.isNaN
                      ? 0.0
                      : widget.uploadProgress.clamp(0.0, 1.0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.accent : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Wird hochgeladen... ${widget.uploadProgress.isNaN ? 0 : (widget.uploadProgress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: widget.uploadProgress.isNaN
                  ? 0.0
                  : widget.uploadProgress.clamp(0.0, 1.0),
              backgroundColor: isDark
                  ? AppColors.toastBackgroundDark
                  : AppColors.greyLighter,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppColors.accent : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

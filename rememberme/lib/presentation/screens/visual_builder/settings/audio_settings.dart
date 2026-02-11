import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/config_text_field.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/info_text.dart';

class AudioSettings extends StatefulWidget {
  final Map<String, dynamic> content;
  final ValueChanged<String> onValueChanged;
  final VoidCallback onToggleRecording;
  final VoidCallback onPickAudioFile;
  final Future<void> Function(String url) onTogglePlayback;
  final bool isRecording;
  final bool isPlaying;
  final bool isUploading;
  final double uploadProgress;
  final int recordingDuration;
  final Duration audioPosition;
  final Duration audioDuration;
  final String? recordedAudioPath;

  const AudioSettings({
    super.key,
    required this.content,
    required this.onValueChanged,
    required this.onToggleRecording,
    required this.onPickAudioFile,
    required this.onTogglePlayback,
    required this.isRecording,
    required this.isPlaying,
    required this.isUploading,
    required this.uploadProgress,
    required this.recordingDuration,
    required this.audioPosition,
    required this.audioDuration,
    this.recordedAudioPath,
  });

  @override
  State<AudioSettings> createState() => _AudioSettingsState();
}

class _AudioSettingsState extends State<AudioSettings> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _getString('title'));
  }

  @override
  void dispose() {
    _titleController.dispose();
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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDurationObj(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Audio Preview
        if (_url.isNotEmpty || widget.recordedAudioPath != null) ...[
          _buildAudioPreview(isDark),
          const SizedBox(height: 24),
        ],

        // Record Button
        _buildRecordButton(isDark),
        const SizedBox(height: 12),

        // Pick Audio File Button
        _buildPickAudioButton(isDark),
        const SizedBox(height: 8),

        const InfoText(text: 'Max. 2 Minuten • MP3, M4A, WAV'),

        if (widget.isUploading) ...[
          const SizedBox(height: 20),
          _buildUploadProgress(isDark),
        ],

        const SizedBox(height: 24),

        // Title Field
        ConfigTextField(
          label: 'Titel (optional)',
          controller: _titleController,
          hint: 'z.B. "Persönliche Nachricht"',
          onChanged: (value) => _updateValue('title', value),
        ),
      ],
    );
  }

  Widget _buildAudioPreview(bool isDark) {
    final totalDuration = widget.audioDuration.inSeconds > 0
        ? widget.audioDuration
        : Duration(seconds: _duration);
    final progress = totalDuration.inMilliseconds > 0
        ? widget.audioPosition.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.accent.withOpacity(0.15),
                  AppColors.accent.withOpacity(0.05)
                ]
              : [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.03)
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
                onTap: _url.isNotEmpty
                    ? () => widget.onTogglePlayback(_url)
                    : null,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.accent : AppColors.primary,
                    shape: BoxShape.circle,
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
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Waveform / Progress
              Expanded(
                child: Column(
                  children: [
                    // Waveform
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
                          final barProgress = index / 20;
                          final isActive = barProgress <= progress;

                          return Container(
                            width: 3,
                            height: 32 * heights[index],
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
                        onChanged: _url.isNotEmpty ? (value) {} : null,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _formatDurationObj(totalDuration),
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
                const Icon(Icons.check_circle,
                    size: 16, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
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

  Widget _buildRecordButton(bool isDark) {
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: widget.isUploading ? null : widget.onToggleRecording,
        icon: Icon(
          widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          size: 28,
        ),
        label: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isRecording
                  ? 'Aufnahme stoppen'
                  : _url.isEmpty && widget.recordedAudioPath == null
                      ? 'Sprachmemo aufnehmen'
                      : 'Neu aufnehmen',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            if (widget.isRecording)
              Text(
                _formatDuration(widget.recordingDuration),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textLight.withOpacity(0.8),
                ),
              ),
          ],
        ),
        style: FilledButton.styleFrom(
          backgroundColor: widget.isRecording
              ? AppColors.error
              : (isDark ? AppColors.accent : AppColors.primary),
          foregroundColor: widget.isRecording
              ? AppColors.textLight
              : (isDark ? AppColors.primary : AppColors.background),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildPickAudioButton(bool isDark) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: widget.isUploading || widget.isRecording
            ? null
            : widget.onPickAudioFile,
        icon: const Icon(Icons.folder_rounded, size: 22),
        label: const Text(
          'Audiodatei auswählen',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.textLight : AppColors.textPrimary,
          side: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.greyLight),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildUploadProgress(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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

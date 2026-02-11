import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:rememberme/data/services/firebase_storage_service.dart';

mixin AudioRecordingMixin<T extends StatefulWidget> on State<T> {
  final AudioPlayer audioPlayer = AudioPlayer();
  final AudioRecorder audioRecorder = AudioRecorder();
  final FirebaseStorageService audioStorageService = FirebaseStorageService();

  bool isRecording = false;
  bool isPlaying = false;
  bool isAudioUploading = false;

  String? recordedAudioPath;
  int recordingDuration = 0;
  double audioUploadProgress = 0.0;
  List<double> waveformData = [];

  Duration audioPosition = Duration.zero;
  Duration audioDuration = Duration.zero;

  void initAudioPlayer() {
    audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing;
        });
      }
    });

    audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          audioPosition = position;
        });
      }
    });

    audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          audioDuration = duration;
        });
      }
    });

    audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        audioPlayer.seek(Duration.zero);
        audioPlayer.pause();
      }
    });
  }

  void disposeAudioResources() {
    audioPlayer.dispose();
    audioRecorder.dispose();
  }

  Future<void> startRecording() async {
    await audioPlayer.stop();

    try {
      if (!await audioRecorder.hasPermission()) {
        onRecordingError('Berechtigung erforderlich',
            'Bitte erlaube den Zugriff auf das Mikrofon in den Einstellungen.');
        return;
      }

      final Directory tempDir = await getTemporaryDirectory();
      final String filePath =
          '${tempDir.path}/audio_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await audioRecorder.start(config, path: filePath);

      setState(() {
        isRecording = true;
        recordingDuration = 0;
        waveformData = [];
        recordedAudioPath = filePath;
      });

      _startRecordingTimer();

      if (Platform.isIOS) HapticFeedback.mediumImpact();

      debugPrint('🎤 Recording started: $filePath');
    } catch (e) {
      debugPrint('❌ Error starting recording: $e');
      onRecordingError(
          'Aufnahmefehler', 'Aufnahme konnte nicht gestartet werden: $e');
    }
  }

  void _startRecordingTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!isRecording || !mounted) return false;

      try {
        final amplitude = await audioRecorder.getAmplitude();
        final normalizedAmplitude =
            ((amplitude.current + 60) / 60).clamp(0.1, 1.0);

        setState(() {
          recordingDuration++;
          if (waveformData.length < 24) {
            waveformData.add(normalizedAmplitude);
          } else {
            waveformData.removeAt(0);
            waveformData.add(normalizedAmplitude);
          }
        });
      } catch (e) {
        setState(() {
          recordingDuration++;
          if (waveformData.length < 24) {
            waveformData.add(0.3 +
                (0.7 * (DateTime.now().millisecondsSinceEpoch % 100) / 100));
          }
        });
      }

      if (recordingDuration >= 120) {
        stopRecording();
        return false;
      }

      return true;
    });
  }

  Future<void> stopRecording() async {
    try {
      final String? path = await audioRecorder.stop();

      setState(() => isRecording = false);

      if (Platform.isIOS) HapticFeedback.mediumImpact();

      if (path != null && recordingDuration > 0) {
        final file = File(path);
        if (await file.exists()) {
          setState(() {
            recordedAudioPath = path;
          });
          onRecordingComplete(path, recordingDuration, waveformData);
          debugPrint('🎤 Recording stopped: $path');
        } else {
          throw Exception('Aufnahmedatei nicht gefunden');
        }
      }
    } catch (e) {
      debugPrint('❌ Error stopping recording: $e');
      setState(() => isRecording = false);
      onRecordingError(
          'Aufnahmefehler', 'Aufnahme konnte nicht gespeichert werden: $e');
    }
  }

  void toggleRecording() {
    if (isRecording) {
      stopRecording();
    } else {
      startRecording();
    }
  }

  Future<void> toggleAudioPlayback(String url) async {
    try {
      if (isPlaying) {
        await audioPlayer.pause();
      } else {
        final bool needsReload = audioPlayer.audioSource == null;

        if (needsReload) {
          if (url.isNotEmpty &&
              (url.startsWith('https://firebasestorage.googleapis.com') ||
                  (url.startsWith('http') && !url.contains('example.com')))) {
            await audioPlayer.setUrl(url);
            debugPrint('🎵 Playing Firebase URL: $url');
          } else if (recordedAudioPath != null &&
              recordedAudioPath!.isNotEmpty &&
              !recordedAudioPath!.contains('simulated')) {
            final file = File(recordedAudioPath!);
            if (await file.exists()) {
              await audioPlayer.setFilePath(recordedAudioPath!);
              debugPrint('🎵 Playing local file: $recordedAudioPath');
            } else {
              throw Exception('Lokale Datei nicht gefunden');
            }
          } else {
            throw Exception('NO_VALID_SOURCE');
          }
        }

        await audioPlayer.play();
      }
    } catch (e) {
      debugPrint('❌ Audio playback error: $e');
      onPlaybackError(e.toString());
    }
  }

  Future<void> pickAudioFile() async {
    if (isAudioUploading || isRecording) return;

    await audioPlayer.stop();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'ogg', 'flac'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      if (file.path == null) {
        onRecordingError('Fehler', 'Datei konnte nicht geladen werden.');
        return;
      }

      final audioFile = File(file.path!);
      final fileSize = await audioFile.length();

      if (fileSize > 10 * 1024 * 1024) {
        onRecordingError('Datei zu groß', 'Max. 10 MB erlaubt.');
        return;
      }

      int audioDurationSec;
      try {
        await audioPlayer.setFilePath(file.path!);
        final duration = audioPlayer.duration;
        audioDurationSec =
            duration?.inSeconds ?? (fileSize / 16000).round().clamp(1, 120);
        await audioPlayer.stop();
      } catch (e) {
        audioDurationSec = (fileSize / 16000).round().clamp(1, 120);
      }

      setState(() {
        recordedAudioPath = file.path;
        recordingDuration = audioDurationSec;
        waveformData = List.generate(
            24, (index) => 0.3 + (0.7 * ((index * 7 + 3) % 10) / 10));
        audioPosition = Duration.zero;
        audioDuration = Duration(seconds: audioDurationSec);
      });

      onAudioFilePicked(file.path!, audioDurationSec, waveformData);
    } catch (e) {
      onRecordingError('Fehler', e.toString());
    }
  }

  Future<String?> uploadAudio({
    required String memorialId,
    required String blockId,
  }) async {
    if (recordedAudioPath == null) return null;

    setState(() {
      isAudioUploading = true;
      audioUploadProgress = 0.0;
    });

    try {
      final audioFile = File(recordedAudioPath!);

      if (!await audioFile.exists()) {
        throw Exception('Audio-Datei nicht gefunden');
      }

      final String downloadUrl = await audioStorageService.uploadBlockAudio(
        memorialId: memorialId,
        blockId: blockId,
        audioFile: audioFile,
        onProgress: (progress) {
          if (mounted) setState(() => audioUploadProgress = progress);
        },
      );

      await audioPlayer.stop();

      setState(() {
        recordedAudioPath = null;
      });

      try {
        await audioPlayer.setUrl(downloadUrl);
        debugPrint('🎵 AudioPlayer loaded with Firebase URL: $downloadUrl');
      } catch (e) {
        debugPrint('⚠️ Could not preload audio: $e');
      }

      return downloadUrl;
    } catch (e) {
      onRecordingError('Upload fehlgeschlagen', e.toString());
      return null;
    } finally {
      if (mounted) {
        setState(() {
          isAudioUploading = false;
          audioUploadProgress = 0.0;
        });
      }
    }
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String formatDurationObj(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Abstract callbacks to be implemented by the using class
  void onRecordingComplete(String path, int duration, List<double> waveform);
  void onRecordingError(String title, String message);
  void onPlaybackError(String error);
  void onAudioFilePicked(String path, int duration, List<double> waveform);
}

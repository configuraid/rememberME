import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/data/services/firebase_storage_service.dart';

mixin VideoPlayerMixin<T extends StatefulWidget> on State<T> {
  final ImagePicker videoImagePicker = ImagePicker();
  final FirebaseStorageService videoStorageService = FirebaseStorageService();

  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;

  bool isVideoInitialized = false;
  bool isVideoLoading = false;
  bool isVideoUploading = false;

  double videoUploadProgress = 0.0;
  Uint8List? videoThumbnail;
  String? currentVideoUrl;
  String? localVideoPath;

  void disposeVideoPlayer() {
    chewieController?.dispose();
    videoPlayerController?.dispose();
    chewieController = null;
    videoPlayerController = null;
    isVideoInitialized = false;
  }

  Future<void> initializeVideoPlayer(String videoSource,
      {bool isLocal = false}) async {
    if (isVideoLoading) return;

    if (isVideoInitialized && currentVideoUrl == videoSource) return;

    setState(() {
      isVideoLoading = true;
    });

    try {
      disposeVideoPlayer();

      if (isLocal) {
        videoPlayerController = VideoPlayerController.file(File(videoSource));
      } else {
        videoPlayerController =
            VideoPlayerController.networkUrl(Uri.parse(videoSource));
      }

      await videoPlayerController!.initialize();

      final isDark = Theme.of(context).brightness == Brightness.dark;

      chewieController = ChewieController(
        videoPlayerController: videoPlayerController!,
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
        isVideoInitialized = true;
        currentVideoUrl = videoSource;
        isVideoLoading = false;
      });

      debugPrint('🎬 Video Player initialized: $videoSource');
    } catch (e) {
      debugPrint('❌ Error initializing video player: $e');
      setState(() {
        isVideoLoading = false;
        isVideoInitialized = false;
      });
      onVideoError('Video-Fehler', 'Video konnte nicht geladen werden: $e');
    }
  }

  Future<String?> uploadVideo({
    required String memorialId,
    required String blockId,
  }) async {
    if (isVideoUploading) return null;
    try {
      final XFile? video = await videoImagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 15),
      );

      if (video == null) return null;

      final videoFile = File(video.path);
      final fileSize = await videoFile.length();

      if (fileSize > 50 * 1024 * 1024) {
        onVideoError(
            'Upload-Fehler', 'Das Video ist zu groß. Max. 50MB erlaubt.');
        return null;
      }

      disposeVideoPlayer();

      await generateVideoThumbnail(video.path);

      setState(() {
        isVideoUploading = true;
        videoUploadProgress = 0.0;
        localVideoPath = null;
      });

      final String downloadUrl = await videoStorageService.uploadBlockVideo(
        memorialId: memorialId,
        blockId: blockId,
        videoFile: videoFile,
        onProgress: (progress) {
          if (mounted) setState(() => videoUploadProgress = progress);
        },
      );

      String? thumbnailUrl;
      if (videoThumbnail != null) {
        try {
          thumbnailUrl = await videoStorageService.uploadVideoThumbnail(
            memorialId: memorialId,
            blockId: blockId,
            thumbnailData: videoThumbnail!,
          );
        } catch (e) {
          debugPrint('Thumbnail upload failed: $e');
        }
      }

      setState(() {
        isVideoUploading = false;
        videoUploadProgress = 0.0;
      });

      await initializeVideoPlayer(downloadUrl);

      onVideoUploadSuccess(downloadUrl, thumbnailUrl);
      return downloadUrl;
    } catch (e) {
      onVideoError('Upload-Fehler', e.toString());
      setState(() {
        isVideoUploading = false;
        videoUploadProgress = 0.0;
      });
      return null;
    }
  }

  Future<void> generateVideoThumbnail(String videoPath) async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        quality: 75,
      );

      if (thumbnail != null && mounted) {
        setState(() => videoThumbnail = thumbnail);
      }
    } catch (e) {
      debugPrint('Failed to generate thumbnail: $e');
    }
  }

  // Abstract callbacks
  void onVideoError(String title, String message);
  void onVideoUploadSuccess(String videoUrl, String? thumbnailUrl);
}

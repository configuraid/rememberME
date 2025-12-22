import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload image for a content block
  /// Path: memorials/{memorialId}/blocks/{blockId}/image.jpg
  Future<String> uploadBlockImage({
    required String memorialId,
    required String blockId,
    required File imageFile,
  }) async {
    try {
      print('📤 Uploading image for block: $blockId');

      // Build storage path
      final String path = 'memorials/$memorialId/blocks/$blockId/image.jpg';

      // Create reference
      final Reference ref = _storage.ref().child(path);

      // Upload file
      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'memorialId': memorialId,
            'blockId': blockId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      rethrow;
    }
  }

  /// Delete image for a content block
  Future<void> deleteBlockImage({
    required String memorialId,
    required String blockId,
  }) async {
    try {
      print('🗑️ Deleting image for block: $blockId');

      final String path = 'memorials/$memorialId/blocks/$blockId/image.jpg';
      final Reference ref = _storage.ref().child(path);

      await ref.delete();
      print('✅ Image deleted successfully');
    } catch (e) {
      print('❌ Error deleting image: $e');
      // Don't rethrow - file might not exist
    }
  }

  /// Upload multiple images for gallery block
  /// Path: memorials/{memorialId}/blocks/{blockId}/gallery/{index}.jpg
  /// Max 6 images
  Future<List<String>> uploadGalleryImages({
    required String memorialId,
    required String blockId,
    required List<File> imageFiles,
  }) async {
    try {
      print(
          '📤 Uploading ${imageFiles.length} images for gallery block: $blockId');

      // Limit to 6 images
      final limitedFiles = imageFiles.take(6).toList();
      final List<String> downloadUrls = [];

      // Upload each image
      for (int i = 0; i < limitedFiles.length; i++) {
        final file = limitedFiles[i];
        final String path =
            'memorials/$memorialId/blocks/$blockId/gallery/$i.jpg';

        print('📤 Uploading image ${i + 1}/${limitedFiles.length}');

        final Reference ref = _storage.ref().child(path);

        final UploadTask uploadTask = ref.putFile(
          file,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'memorialId': memorialId,
              'blockId': blockId,
              'index': i.toString(),
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );

        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);

        print('✅ Image ${i + 1} uploaded successfully');
      }

      print(
          '✅ All ${downloadUrls.length} gallery images uploaded successfully');
      return downloadUrls;
    } catch (e) {
      print('❌ Error uploading gallery images: $e');
      rethrow;
    }
  }

  /// Delete a specific gallery image
  Future<void> deleteGalleryImage({
    required String memorialId,
    required String blockId,
    required int index,
  }) async {
    try {
      print('🗑️ Deleting gallery image $index for block: $blockId');

      final String path =
          'memorials/$memorialId/blocks/$blockId/gallery/$index.jpg';
      final Reference ref = _storage.ref().child(path);

      await ref.delete();
      print('✅ Gallery image deleted successfully');
    } catch (e) {
      print('❌ Error deleting gallery image: $e');
      // Don't rethrow - file might not exist
    }
  }

  /// Delete all gallery images for a block
  Future<void> deleteAllGalleryImages({
    required String memorialId,
    required String blockId,
  }) async {
    try {
      print('🗑️ Deleting all gallery images for block: $blockId');

      // Delete up to 6 images (max gallery size)
      for (int i = 0; i < 6; i++) {
        await deleteGalleryImage(
          memorialId: memorialId,
          blockId: blockId,
          index: i,
        );
      }

      print('✅ All gallery images deleted');
    } catch (e) {
      print('❌ Error deleting all gallery images: $e');
      // Don't rethrow - some files might not exist
    }
  }

  /// Upload profile image for user
  /// Path: users/{userId}/profile.jpg
  Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      print('📤 Uploading profile image for user: $userId');

      // Build storage path
      final String path = 'users/$userId/profile.jpg';

      // Create reference
      final Reference ref = _storage.ref().child(path);

      // Upload file
      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Profile image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      rethrow;
    }
  }

  /// Delete profile image for user
  Future<void> deleteProfileImage({
    required String userId,
  }) async {
    try {
      print('🗑️ Deleting profile image for user: $userId');

      final String path = 'users/$userId/profile.jpg';
      final Reference ref = _storage.ref().child(path);

      await ref.delete();
      print('✅ Profile image deleted successfully');
    } catch (e) {
      print('❌ Error deleting profile image: $e');
      // Don't rethrow - file might not exist
    }
  }

  /// Upload video for a content block
  /// Path: memorials/{memorialId}/blocks/{blockId}/video.mp4
  Future<String> uploadBlockVideo({
    required String memorialId,
    required String blockId,
    required File videoFile,
    Function(double)? onProgress,
  }) async {
    try {
      print('📤 Uploading video for block: $blockId');

      // Check file size (max 50MB for 15 second video)
      final fileSize = await videoFile.length();
      final maxSize = 50 * 1024 * 1024; // 50MB in bytes

      if (fileSize > maxSize) {
        throw Exception('Video ist zu groß. Maximale Größe: 50MB');
      }

      // Build storage path
      final String path = 'memorials/$memorialId/blocks/$blockId/video.mp4';

      // Create reference
      final Reference ref = _storage.ref().child(path);

      // Upload file with progress tracking
      final UploadTask uploadTask = ref.putFile(
        videoFile,
        SettableMetadata(
          contentType: 'video/mp4',
          customMetadata: {
            'memorialId': memorialId,
            'blockId': blockId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Track progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress?.call(progress.clamp(0.0, 1.0));
          print('📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        }
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Video uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading video: $e');
      rethrow;
    }
  }

  /// Upload video thumbnail
  /// Path: memorials/{memorialId}/blocks/{blockId}/thumbnail.jpg
  Future<String> uploadVideoThumbnail({
    required String memorialId,
    required String blockId,
    required Uint8List thumbnailData,
  }) async {
    try {
      print('📤 Uploading video thumbnail for block: $blockId');

      // Build storage path
      final String path = 'memorials/$memorialId/blocks/$blockId/thumbnail.jpg';

      // Create reference
      final Reference ref = _storage.ref().child(path);

      // Upload thumbnail data
      final UploadTask uploadTask = ref.putData(
        thumbnailData,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'memorialId': memorialId,
            'blockId': blockId,
            'type': 'video_thumbnail',
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Video thumbnail uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading video thumbnail: $e');
      rethrow;
    }
  }

  /// Delete video for a content block
  Future<void> deleteBlockVideo({
    required String memorialId,
    required String blockId,
  }) async {
    try {
      print('🗑️ Deleting video for block: $blockId');

      final String path = 'memorials/$memorialId/blocks/$blockId/video.mp4';
      final Reference ref = _storage.ref().child(path);

      await ref.delete();
      print('✅ Video deleted successfully');

      // Also try to delete thumbnail
      await deleteVideoThumbnail(memorialId: memorialId, blockId: blockId);
    } catch (e) {
      print('❌ Error deleting video: $e');
      // Don't rethrow - file might not exist
    }
  }

  /// Delete video thumbnail
  Future<void> deleteVideoThumbnail({
    required String memorialId,
    required String blockId,
  }) async {
    try {
      print('🗑️ Deleting video thumbnail for block: $blockId');

      final String path = 'memorials/$memorialId/blocks/$blockId/thumbnail.jpg';
      final Reference ref = _storage.ref().child(path);

      await ref.delete();
      print('✅ Video thumbnail deleted successfully');
    } catch (e) {
      print('❌ Error deleting video thumbnail: $e');
      // Don't rethrow - file might not exist
    }
  }

  // ============================================================
  // AUDIO METHODS
  // ============================================================

  /// Upload audio file for a content block
  /// Path: memorials/{memorialId}/blocks/{blockId}/audio.m4a
  /// Supported formats: m4a, mp3, wav, aac, ogg, flac
  Future<String> uploadBlockAudio({
    required String memorialId,
    required String blockId,
    required File audioFile,
    Function(double)? onProgress,
  }) async {
    try {
      print('📤 Uploading audio for block: $blockId');

      // Check file size (max 10MB for 2 minute audio)
      final fileSize = await audioFile.length();
      final maxSize = 10 * 1024 * 1024; // 10MB in bytes

      if (fileSize > maxSize) {
        throw Exception('Audio ist zu groß. Maximale Größe: 10MB');
      }

      // Determine content type based on file extension
      final String extension = audioFile.path.split('.').last.toLowerCase();
      final String contentType = _getAudioContentType(extension);

      // Build storage path (always save as original extension)
      final String path =
          'memorials/$memorialId/blocks/$blockId/audio.$extension';

      // Create reference
      final Reference ref = _storage.ref().child(path);

      // Upload file with progress tracking
      final UploadTask uploadTask = ref.putFile(
        audioFile,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'memorialId': memorialId,
            'blockId': blockId,
            'originalExtension': extension,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Track progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress?.call(progress.clamp(0.0, 1.0));
          print(
              '📊 Audio upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        }
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Audio uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading audio: $e');
      rethrow;
    }
  }

  /// Get content type for audio file extension
  String _getAudioContentType(String extension) {
    switch (extension) {
      case 'm4a':
        return 'audio/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      default:
        return 'audio/mp4'; // Default to m4a
    }
  }

  /// Delete audio for a content block
  Future<void> deleteBlockAudio({
    required String memorialId,
    required String blockId,
  }) async {
    try {
      print('🗑️ Deleting audio for block: $blockId');

      // Try to delete common audio formats
      final extensions = ['m4a', 'mp3', 'wav', 'aac', 'ogg', 'flac'];

      for (final ext in extensions) {
        try {
          final String path =
              'memorials/$memorialId/blocks/$blockId/audio.$ext';
          final Reference ref = _storage.ref().child(path);
          await ref.delete();
          print('✅ Audio file (.$ext) deleted successfully');
          return; // Exit after successful deletion
        } catch (e) {
          // File with this extension doesn't exist, try next
          continue;
        }
      }

      print('⚠️ No audio file found to delete');
    } catch (e) {
      print('❌ Error deleting audio: $e');
      // Don't rethrow - file might not exist
    }
  }

  Future<String> uploadMemorialProfileImage({
    required String memorialId,
    required File imageFile,
  }) async {
    try {
      print('📤 Uploading profile image for memorial: $memorialId');

      // Build storage path
      final String path = 'memorials/$memorialId/profile.jpg';

      // Create reference
      final Reference ref = _storage.ref().child(path);

      // Upload file
      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'memorialId': memorialId,
            'type': 'profile_image',
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Memorial profile image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading memorial profile image: $e');
      rethrow;
    }
  }

  /// Delete profile image for a memorial
  Future<void> deleteMemorialProfileImage({
    required String memorialId,
  }) async {
    try {
      print('🗑️ Deleting profile image for memorial: $memorialId');

      final String path = 'memorials/$memorialId/profile.jpg';
      final Reference ref = _storage.ref().child(path);

      await ref.delete();
      print('✅ Memorial profile image deleted successfully');
    } catch (e) {
      print('❌ Error deleting memorial profile image: $e');
      // Don't rethrow - file might not exist
    }
  }

  /// Update profile image for a memorial (delete old, upload new)
  Future<String> updateMemorialProfileImage({
    required String memorialId,
    required File newImageFile,
  }) async {
    try {
      print('🔄 Updating profile image for memorial: $memorialId');

      // Delete existing image first
      await deleteMemorialProfileImage(memorialId: memorialId);

      // Upload new image
      return await uploadMemorialProfileImage(
        memorialId: memorialId,
        imageFile: newImageFile,
      );
    } catch (e) {
      print('❌ Error updating memorial profile image: $e');
      rethrow;
    }
  }

  /// Upload recorded audio data directly (for in-app recordings)
  /// Path: memorials/{memorialId}/blocks/{blockId}/audio.m4a
  Future<String> uploadRecordedAudio({
    required String memorialId,
    required String blockId,
    required Uint8List audioData,
    String extension = 'm4a',
    Function(double)? onProgress,
  }) async {
    try {
      print('📤 Uploading recorded audio for block: $blockId');

      // Check data size (max 10MB)
      final maxSize = 10 * 1024 * 1024; // 10MB in bytes

      if (audioData.length > maxSize) {
        throw Exception('Audio ist zu groß. Maximale Größe: 10MB');
      }

      // Determine content type
      final String contentType = _getAudioContentType(extension);

      // Build storage path
      final String path =
          'memorials/$memorialId/blocks/$blockId/audio.$extension';

      // Create reference
      final Reference ref = _storage.ref().child(path);

      // Upload data with progress tracking
      final UploadTask uploadTask = ref.putData(
        audioData,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'memorialId': memorialId,
            'blockId': blockId,
            'type': 'recorded_audio',
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Track progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress?.call(progress.clamp(0.0, 1.0));
          print(
              '📊 Audio upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        }
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Recorded audio uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading recorded audio: $e');
      rethrow;
    }
  }
}

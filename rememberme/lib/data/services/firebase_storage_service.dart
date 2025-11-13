import 'dart:io';
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
}

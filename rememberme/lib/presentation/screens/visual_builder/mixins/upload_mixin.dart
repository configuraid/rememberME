import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/core/constants/app_strings.dart';
import 'package:rememberme/data/services/firebase_storage_service.dart';

mixin UploadMixin<T extends StatefulWidget> on State<T> {
  final ImagePicker imagePicker = ImagePicker();
  final FirebaseStorageService storageService = FirebaseStorageService();

  bool isUploading = false;

  Future<String?> uploadImage({
    required String memorialId,
    required String blockId,
  }) async {
    if (isUploading) return null;
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

      setState(() => isUploading = true);

      final String downloadUrl = await storageService.uploadBlockImage(
        memorialId: memorialId,
        blockId: blockId,
        imageFile: File(image.path),
      );

      showSuccessSnackBar(AppStrings.imageUploadSuccess);
      return downloadUrl;
    } catch (e) {
      showErrorDialog(AppStrings.uploadError, e.toString());
      return null;
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  Future<List<String>?> uploadMultipleImages({
    required String memorialId,
    required String blockId,
    required int maxImages,
    required int currentCount,
  }) async {
    if (isUploading) return null;

    final int remaining = maxImages - currentCount;
    if (remaining <= 0) {
      showErrorDialog(AppStrings.maxReached, AppStrings.maxGalleryImages);
      return null;
    }

    try {
      final List<XFile> images = await imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isEmpty) return null;

      final imagesToUpload = images.take(remaining).toList();

      setState(() => isUploading = true);

      final List<File> imageFiles =
          imagesToUpload.map((xfile) => File(xfile.path)).toList();

      final List<String> downloadUrls =
          await storageService.uploadGalleryImages(
        memorialId: memorialId,
        blockId: blockId,
        imageFiles: imageFiles,
      );

      showSuccessSnackBar(
        '${downloadUrls.length} ${downloadUrls.length == 1 ? AppStrings.image : AppStrings.images}${AppStrings.uploadedSuccessfully}',
      );

      return downloadUrls;
    } catch (e) {
      showErrorDialog(AppStrings.uploadError, e.toString());
      return null;
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  void showSuccessSnackBar(String message) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => CupertinoAlertDialog(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void showErrorDialog(String title, String message) {
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

  void showValidationError(String message) {
    if (Platform.isIOS) {
      HapticFeedback.heavyImpact();
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Pflichtfeld fehlt'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:rememberme/presentation/screens/preview/webview_preview_screen.dart';
import '../../../data/models/content_block_model.dart';
import '../../../data/services/preview_service.dart';
import 'preview_dialogs.dart';

/// Mixin that provides web preview functionality to any StatefulWidget
///
/// Usage:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with WebPreviewMixin {
///   void _handlePreview() {
///     showWebPreview(
///       context: context,
///       memorialId: 'your-memorial-id',
///       memorialName: 'Memorial Name',
///       blocks: yourBlocks,
///     );
///   }
/// }
/// ```
mixin WebPreviewMixin<T extends StatefulWidget> on State<T> {
  final PreviewService _previewService = PreviewService();
  bool _isPreviewLoading = false;

  /// Shows the web preview by sending blocks to the server and opening WebView
  Future<void> showWebPreview({
    required BuildContext context,
    required String memorialId,
    required String memorialName,
    required List<ContentBlock> blocks,
  }) async {
    // Prevent double-tap
    if (_isPreviewLoading) return;

    // Check for empty blocks
    if (blocks.isEmpty) {
      _showEmptyBlocksWarning(context);
      return;
    }

    _isPreviewLoading = true;

    // Haptic feedback
    if (Platform.isIOS) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    // Show loading dialog
    PreviewLoadingDialog.show(context);

    try {
      // Send blocks to server
      final result = await _previewService.createPreview(
        memorialId: memorialId,
        blocks: blocks,
      );

      // Hide loading dialog
      if (context.mounted) {
        PreviewLoadingDialog.hide(context);
      }

      if (result.success && result.previewUrl != null) {
        // Success - open WebView
        if (context.mounted) {
          _navigateToWebView(
            context: context,
            previewUrl: result.previewUrl!,
            memorialName: memorialName,
          );
        }
      } else {
        // Error - show error dialog
        if (context.mounted) {
          PreviewErrorDialog.show(
            context,
            title: 'Vorschau fehlgeschlagen',
            message: result.errorMessage ??
                'Ein unbekannter Fehler ist aufgetreten.',
            onRetry: () => showWebPreview(
              context: context,
              memorialId: memorialId,
              memorialName: memorialName,
              blocks: blocks,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading dialog
      if (context.mounted) {
        PreviewLoadingDialog.hide(context);
      }

      // Show error dialog
      if (context.mounted) {
        PreviewErrorDialog.show(
          context,
          title: 'Fehler',
          message: 'Ein unerwarteter Fehler ist aufgetreten: ${e.toString()}',
          onRetry: () => showWebPreview(
            context: context,
            memorialId: memorialId,
            memorialName: memorialName,
            blocks: blocks,
          ),
        );
      }
    } finally {
      _isPreviewLoading = false;
    }
  }

  void _navigateToWebView({
    required BuildContext context,
    required String previewUrl,
    required String memorialName,
  }) {
    // Platform-specific navigation
    if (Platform.isIOS) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => WebViewPreviewScreen(
            previewUrl: previewUrl,
            memorialName: memorialName,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewPreviewScreen(
            previewUrl: previewUrl,
            memorialName: memorialName,
          ),
        ),
      );
    }
  }

  void _showEmptyBlocksWarning(BuildContext context) {
    if (Platform.isIOS) {
      final brightness = MediaQuery.of(context).platformBrightness;
      final isDark = brightness == Brightness.dark;

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            'Keine Inhalte',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Text(
            'Füge zuerst Inhaltsblöcke hinzu, um eine Vorschau anzuzeigen.',
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
              fontFamily: '.SF Pro Text',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(
                'OK',
                style: TextStyle(
                  fontSize: 17,
                  color: CupertinoColors.activeBlue,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Füge zuerst Inhaltsblöcke hinzu, um eine Vorschau anzuzeigen.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/// Standalone function for use without mixin
///
/// Usage:
/// ```dart
/// await showWebPreviewStandalone(
///   context: context,
///   memorialId: 'your-memorial-id',
///   memorialName: 'Memorial Name',
///   blocks: yourBlocks,
/// );
/// ```
Future<void> showWebPreviewStandalone({
  required BuildContext context,
  required String memorialId,
  required String memorialName,
  required List<ContentBlock> blocks,
}) async {
  final previewService = PreviewService();

  // Check for empty blocks
  if (blocks.isEmpty) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Keine Inhalte'),
          content: const Text(
            'Füge zuerst Inhaltsblöcke hinzu, um eine Vorschau anzuzeigen.',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Füge zuerst Inhaltsblöcke hinzu.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return;
  }

  // Haptic feedback
  if (Platform.isIOS) {
    HapticFeedback.lightImpact();
  } else {
    HapticFeedback.mediumImpact();
  }

  // Show loading dialog
  PreviewLoadingDialog.show(context);

  try {
    // Send blocks to server
    final result = await previewService.createPreview(
      memorialId: memorialId,
      blocks: blocks,
    );

    // Hide loading dialog
    if (context.mounted) {
      PreviewLoadingDialog.hide(context);
    }

    if (result.success && result.previewUrl != null) {
      // Success - open WebView
      if (context.mounted) {
        if (Platform.isIOS) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (ctx) => WebViewPreviewScreen(
                previewUrl: result.previewUrl!,
                memorialName: memorialName,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => WebViewPreviewScreen(
                previewUrl: result.previewUrl!,
                memorialName: memorialName,
              ),
            ),
          );
        }
      }
    } else {
      // Error - show error dialog
      if (context.mounted) {
        PreviewErrorDialog.show(
          context,
          title: 'Vorschau fehlgeschlagen',
          message:
              result.errorMessage ?? 'Ein unbekannter Fehler ist aufgetreten.',
          onRetry: () => showWebPreviewStandalone(
            context: context,
            memorialId: memorialId,
            memorialName: memorialName,
            blocks: blocks,
          ),
        );
      }
    }
  } catch (e) {
    // Hide loading dialog
    if (context.mounted) {
      PreviewLoadingDialog.hide(context);
    }

    // Show error dialog
    if (context.mounted) {
      PreviewErrorDialog.show(
        context,
        title: 'Fehler',
        message: 'Ein unerwarteter Fehler ist aufgetreten.',
      );
    }
  }
}

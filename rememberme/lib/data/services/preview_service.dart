import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/content_block_model.dart';

/// Result class for preview operations
class PreviewResult {
  final bool success;
  final String? previewUrl;
  final String? errorMessage;
  final PreviewErrorType? errorType;

  const PreviewResult._({
    required this.success,
    this.previewUrl,
    this.errorMessage,
    this.errorType,
  });

  factory PreviewResult.success(String previewUrl) {
    return PreviewResult._(
      success: true,
      previewUrl: previewUrl,
    );
  }

  factory PreviewResult.failure(String message, PreviewErrorType type) {
    return PreviewResult._(
      success: false,
      errorMessage: message,
      errorType: type,
    );
  }
}

/// Error types for better error handling
enum PreviewErrorType {
  noInternet,
  serverError,
  timeout,
  invalidResponse,
  unknown,
}

/// Service for handling preview functionality with Nuxt.js backend
class PreviewService {
  static const String _baseUrl = 'https://remember-me-slug.vercel.app';
  static const Duration _timeout = Duration(seconds: 15);

  /// Singleton instance
  static final PreviewService _instance = PreviewService._internal();
  factory PreviewService() => _instance;
  PreviewService._internal();

  /// Sends content blocks to the preview endpoint and returns the preview URL
  ///
  /// [memorialId] - The unique identifier for the memorial page
  /// [blocks] - List of content blocks to preview
  ///
  /// Returns a [PreviewResult] indicating success or failure
  Future<PreviewResult> createPreview({
    required String memorialId,
    required List<ContentBlock> blocks,
  }) async {
    // Check for empty blocks
    if (blocks.isEmpty) {
      return PreviewResult.failure(
        'Keine Inhaltsblöcke zum Anzeigen vorhanden.',
        PreviewErrorType.invalidResponse,
      );
    }

    try {
      // Serialize blocks to JSON
      final blocksJson = blocks.map((block) => block.toJson()).toList();

      final requestBody = {
        'memorialId': memorialId,
        'blocks': blocksJson,
        'timestamp': DateTime.now().toIso8601String(),
      };

      debugPrint('📤 Sending preview request for memorial: $memorialId');
      debugPrint('📦 Blocks count: ${blocks.length}');

      // Send POST request to create preview
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/preview'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      // Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        final previewUrl = '$_baseUrl/preview/$memorialId';
        debugPrint('✅ Preview URL: $previewUrl');
        return PreviewResult.success(previewUrl);
      } else if (response.statusCode >= 500) {
        return PreviewResult.failure(
          'Server ist momentan nicht erreichbar. Bitte versuche es später erneut.',
          PreviewErrorType.serverError,
        );
      } else {
        // Try to parse error message from response
        String errorMessage = 'Ein unerwarteter Fehler ist aufgetreten.';
        try {
          final errorJson = jsonDecode(response.body);
          errorMessage = errorJson['message'] ?? errorMessage;
        } catch (_) {}

        return PreviewResult.failure(
          errorMessage,
          PreviewErrorType.invalidResponse,
        );
      }
    } on SocketException {
      debugPrint('❌ No internet connection');
      return PreviewResult.failure(
        'Keine Internetverbindung. Bitte überprüfe deine Verbindung.',
        PreviewErrorType.noInternet,
      );
    } on TimeoutException {
      debugPrint('❌ Request timeout');
      return PreviewResult.failure(
        'Die Anfrage hat zu lange gedauert. Bitte versuche es erneut.',
        PreviewErrorType.timeout,
      );
    } on http.ClientException catch (e) {
      debugPrint('❌ Client exception: $e');
      return PreviewResult.failure(
        'Verbindungsfehler. Bitte versuche es erneut.',
        PreviewErrorType.unknown,
      );
    } catch (e) {
      debugPrint('❌ Unknown error: $e');
      return PreviewResult.failure(
        'Ein unerwarteter Fehler ist aufgetreten: ${e.toString()}',
        PreviewErrorType.unknown,
      );
    }
  }

  /// Validates if the preview service is reachable
  Future<bool> isServiceAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rememberme/data/models/memorial_model.dart';

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
///
/// Sendet Memorial-Daten an das Backend und erhält eine Preview-URL zurück.
class PreviewService {
  static const String _baseUrl = 'https://remember-me-slug.vercel.app';
  static const Duration _timeout = Duration(seconds: 15);

  /// Singleton instance
  static final PreviewService _instance = PreviewService._internal();
  factory PreviewService() => _instance;
  PreviewService._internal();

  /// Sends memorial data to the preview endpoint and returns the preview URL
  ///
  /// [memorial] - The memorial model containing all data
  ///
  /// Returns a [PreviewResult] indicating success or failure
  Future<PreviewResult> createPreview({
    required MemorialModel memorial,
  }) async {
    // Check for empty blocks
    if (memorial.contentBlocks.isEmpty) {
      return PreviewResult.failure(
        'Keine Inhaltsblöcke zum Anzeigen vorhanden.',
        PreviewErrorType.invalidResponse,
      );
    }

    try {
      // Serialize blocks to JSON
      final blocksJson =
          memorial.contentBlocks.map((block) => block.toJson()).toList();

      final requestBody = {
        'memorial': {
          'id': memorial.id,
          'name': memorial.name,
          'subtitle': memorial.subtitle ?? '',
          'biography': memorial.biography ?? '',
          'profileImageUrl': memorial.profileImageUrl,
          'birthDate': memorial.birthDate?.toIso8601String(),
          'deathDate': memorial.deathDate?.toIso8601String(),
        },
        'blocks': blocksJson,
      };

      debugPrint('📤 Sending preview request for memorial: ${memorial.id}');
      debugPrint('📦 Memorial: ${memorial.name}');
      debugPrint('📦 Blocks count: ${memorial.contentBlocks.length}');

      // Send POST request to create preview
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/preview'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'x-preview-secret': memorial.id,
            },
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      // Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseJson = jsonDecode(response.body);
          final previewId = responseJson['previewId'] as String?;

          if (previewId == null) {
            return PreviewResult.failure(
              'Ungültige Server-Antwort: Keine Preview-ID erhalten.',
              PreviewErrorType.invalidResponse,
            );
          }

          final previewUrl = '$_baseUrl/preview/$previewId';
          debugPrint('✅ Preview URL: $previewUrl');
          return PreviewResult.success(previewUrl);
        } catch (e) {
          debugPrint('❌ Failed to parse response: $e');
          return PreviewResult.failure(
            'Ungültige Server-Antwort.',
            PreviewErrorType.invalidResponse,
          );
        }
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

  /// Get the public memorial URL (for sharing)
  String getPublicUrl(String memorialId) {
    return '$_baseUrl/m/$memorialId';
  }

  /// Get the preview URL for a memorial
  String getPreviewUrl(String previewId) {
    return '$_baseUrl/preview/$previewId';
  }
}

import 'package:flutter/foundation.dart';

/// Result of parsing a QR code
class QrParseResult {
  final bool success;
  final String? memorialId;
  final String? errorMessage;

  const QrParseResult._({
    required this.success,
    this.memorialId,
    this.errorMessage,
  });

  factory QrParseResult.success(String memorialId) {
    return QrParseResult._(
      success: true,
      memorialId: memorialId,
    );
  }

  factory QrParseResult.failure(String message) {
    return QrParseResult._(
      success: false,
      errorMessage: message,
    );
  }
}

/// Service for parsing QR codes and extracting memorial IDs
class QrScannerService {
  /// Base URL pattern for memorial QR codes
  static const String _baseUrl = 'https://remember-me-slug.vercel.app';
  static const String _memorialPath = '/m/';

  /// Singleton instance
  static final QrScannerService _instance = QrScannerService._internal();
  factory QrScannerService() => _instance;
  QrScannerService._internal();

  /// Parses a scanned QR code and extracts the memorial ID
  ///
  /// Accepts:
  /// - Full URL: https://remember-me-slug.vercel.app/m/{memorialId}
  /// - Just the memorial ID (UUID format)
  ///
  /// Returns [QrParseResult] with the memorial ID or an error message
  QrParseResult parseQrCode(String scannedData) {
    if (scannedData.isEmpty) {
      return QrParseResult.failure('Leerer QR-Code');
    }

    debugPrint('📷 Parsing QR code: $scannedData');

    // Try to parse as URL first
    final memorialId = _extractMemorialIdFromUrl(scannedData);

    if (memorialId != null) {
      debugPrint('✅ Extracted memorial ID from URL: $memorialId');
      return QrParseResult.success(memorialId);
    }

    // Check if it's a raw UUID
    if (_isValidUuid(scannedData)) {
      debugPrint('✅ Valid UUID detected: $scannedData');
      return QrParseResult.success(scannedData);
    }

    debugPrint('❌ Invalid QR code format');
    return QrParseResult.failure(
      'Ungültiger QR-Code. Bitte scannen Sie einen gültigen RememberMe QR-Code.',
    );
  }

  /// Extracts memorial ID from a URL
  ///
  /// Expected format: https://remember-me-slug.vercel.app/m/{memorialId}
  String? _extractMemorialIdFromUrl(String url) {
    try {
      final uri = Uri.tryParse(url);

      if (uri == null) return null;

      // Check if it's our domain
      if (!url.startsWith(_baseUrl)) {
        // Also accept shortened versions or alternative domains
        if (!uri.path.startsWith(_memorialPath)) {
          return null;
        }
      }

      // Extract the path
      final path = uri.path;

      // Look for /m/{id} pattern
      if (path.startsWith(_memorialPath)) {
        final memorialId = path.substring(_memorialPath.length);

        // Remove any trailing slashes or query params
        final cleanId = memorialId.split('/').first.split('?').first;

        if (cleanId.isNotEmpty && _isValidUuid(cleanId)) {
          return cleanId;
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error parsing URL: $e');
      return null;
    }
  }

  /// Validates if a string is a valid UUID format
  bool _isValidUuid(String value) {
    // UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(value);
  }

  /// Generates the full memorial URL from an ID
  String getMemorialUrl(String memorialId) {
    return '$_baseUrl$_memorialPath$memorialId';
  }
}

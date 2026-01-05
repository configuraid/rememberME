import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Typ des Deep Links
enum DeepLinkType {
  invitation, // /invite/{token} - Einladung zu bestehendem Memorial
  qrCode, // /m/{qrId} oder /memorial/{qrId} - QR-Code Claiming
  unknown,
}

/// Geparstes Deep Link Ergebnis
class ParsedDeepLink {
  final DeepLinkType type;
  final String? token; // Für Invitations
  final String? qrCodeId; // Für QR-Code Claiming

  ParsedDeepLink({
    required this.type,
    this.token,
    this.qrCodeId,
  });
}

/// Handles incoming deep links für Invitations UND QR-Code Claiming
class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Callbacks
  Function(String token)? onInvitationReceived;
  Function(String qrCodeId)? onQrCodeReceived;

  // Keys für SharedPreferences
  static const String _pendingInvitationKey = 'pending_invitation_token';
  static const String _pendingQrCodeKey = 'pending_qr_code_id';

  // Domain Konfiguration
  static const String webDomain = 'remember-me-slug.vercel.app';

  /// Initialize the deep link handler
  Future<void> initialize() async {
    debugPrint('🔗 DeepLinkHandler: Initializing...');

    // Check for initial link (app was opened via link)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        debugPrint('🔗 Initial link: $initialLink');
        await _handleLink(initialLink);
      }
    } catch (e) {
      debugPrint('❌ Error getting initial link: $e');
    }

    // Listen for incoming links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('🔗 Received link: $uri');
        _handleLink(uri);
      },
      onError: (error) {
        debugPrint('❌ Link stream error: $error');
      },
    );

    debugPrint('✅ DeepLinkHandler: Initialized');
  }

  /// Handle an incoming URI
  Future<void> _handleLink(Uri uri) async {
    final linkString = uri.toString();
    debugPrint('🔗 Processing link: $linkString');

    final parsed = parseDeepLink(linkString);

    switch (parsed.type) {
      case DeepLinkType.invitation:
        debugPrint('🎫 Invitation token: ${parsed.token}');
        await storePendingInvitation(parsed.token!);
        onInvitationReceived?.call(parsed.token!);
        break;

      case DeepLinkType.qrCode:
        debugPrint('📱 QR-Code ID: ${parsed.qrCodeId}');
        await storePendingQrCode(parsed.qrCodeId!);
        onQrCodeReceived?.call(parsed.qrCodeId!);
        break;

      case DeepLinkType.unknown:
        debugPrint('⚠️ Unknown link format: $linkString');
        break;
    }
  }

  /// Parse a deep link and extract the relevant data
  static ParsedDeepLink parseDeepLink(String link) {
    try {
      final uri = Uri.tryParse(link);
      if (uri == null) {
        return ParsedDeepLink(type: DeepLinkType.unknown);
      }

      final path = uri.path;
      final pathSegments = uri.pathSegments;

      // Format: /invite/{token}
      if (path.contains('/invite/') || pathSegments.contains('invite')) {
        final inviteIndex = pathSegments.indexOf('invite');
        if (inviteIndex >= 0 && inviteIndex < pathSegments.length - 1) {
          return ParsedDeepLink(
            type: DeepLinkType.invitation,
            token: pathSegments[inviteIndex + 1],
          );
        }
        // Query param: ?token=xxx
        if (uri.queryParameters.containsKey('token')) {
          return ParsedDeepLink(
            type: DeepLinkType.invitation,
            token: uri.queryParameters['token'],
          );
        }
      }

      // Format: /m/{qrCodeId} - QR-Code Claiming (kurze URL)
      if (path.startsWith('/m/') || pathSegments.firstOrNull == 'm') {
        final mIndex = pathSegments.indexOf('m');
        if (mIndex >= 0 && mIndex < pathSegments.length - 1) {
          return ParsedDeepLink(
            type: DeepLinkType.qrCode,
            qrCodeId: pathSegments[mIndex + 1],
          );
        }
      }

      // Format: /memorial/{qrCodeId} - QR-Code Claiming (lange URL)
      // Dies ist der Link der vom QR-Code gescannt wird!
      if (path.contains('/memorial/') || pathSegments.contains('memorial')) {
        final memorialIndex = pathSegments.indexOf('memorial');
        if (memorialIndex >= 0 && memorialIndex < pathSegments.length - 1) {
          return ParsedDeepLink(
            type: DeepLinkType.qrCode,
            qrCodeId: pathSegments[memorialIndex + 1],
          );
        }
      }

      // Prüfe ob es ein reiner Token/ID ist (16 alphanumerische Zeichen)
      if (RegExp(r'^[a-zA-Z0-9]{16}$').hasMatch(link)) {
        return ParsedDeepLink(
          type: DeepLinkType.invitation,
          token: link,
        );
      }

      return ParsedDeepLink(type: DeepLinkType.unknown);
    } catch (e) {
      debugPrint('❌ Error parsing deep link: $e');
      return ParsedDeepLink(type: DeepLinkType.unknown);
    }
  }

  // ========================================
  // INVITATION STORAGE
  // ========================================

  Future<void> storePendingInvitation(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingInvitationKey, token);
      debugPrint('💾 Pending invitation stored: $token');
    } catch (e) {
      debugPrint('❌ Error storing pending invitation: $e');
    }
  }

  Future<String?> consumePendingInvitation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_pendingInvitationKey);
      if (token != null) {
        await prefs.remove(_pendingInvitationKey);
        debugPrint('🎫 Consumed pending invitation: $token');
      }
      return token;
    } catch (e) {
      debugPrint('❌ Error consuming pending invitation: $e');
      return null;
    }
  }

  Future<bool> hasPendingInvitation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_pendingInvitationKey);
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // QR-CODE STORAGE
  // ========================================

  Future<void> storePendingQrCode(String qrCodeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingQrCodeKey, qrCodeId);
      debugPrint('💾 Pending QR-Code stored: $qrCodeId');
    } catch (e) {
      debugPrint('❌ Error storing pending QR-Code: $e');
    }
  }

  Future<String?> consumePendingQrCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final qrCodeId = prefs.getString(_pendingQrCodeKey);
      if (qrCodeId != null) {
        await prefs.remove(_pendingQrCodeKey);
        debugPrint('📱 Consumed pending QR-Code: $qrCodeId');
      }
      return qrCodeId;
    } catch (e) {
      debugPrint('❌ Error consuming pending QR-Code: $e');
      return null;
    }
  }

  Future<bool> hasPendingQrCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_pendingQrCodeKey);
    } catch (e) {
      return false;
    }
  }

  /// Gibt die pending QR-Code ID zurück OHNE sie zu löschen
  Future<String?> getPendingQrCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_pendingQrCodeKey);
    } catch (e) {
      return null;
    }
  }

  // ========================================
  // MANUAL PROCESSING
  // ========================================

  Future<void> processToken(String token) async {
    await storePendingInvitation(token);
    onInvitationReceived?.call(token);
  }

  Future<void> processQrCode(String qrCodeId) async {
    await storePendingQrCode(qrCodeId);
    onQrCodeReceived?.call(qrCodeId);
  }

  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    debugPrint('🔗 DeepLinkHandler: Disposed');
  }
}

final deepLinkHandler = DeepLinkHandler();

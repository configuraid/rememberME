import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:rememberme/data/services/share_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles incoming deep links and stores pending invitations
class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Callback when a valid invitation link is received
  Function(String token)? onInvitationReceived;

  // Key for storing pending invitation in SharedPreferences
  static const String _pendingInvitationKey = 'pending_invitation_token';

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

    // Try to parse as invitation link
    final token = ShareService.parseDeepLink(linkString);

    if (token != null) {
      debugPrint('🎫 Invitation token extracted: $token');
      await storePendingInvitation(token);
      onInvitationReceived?.call(token);
    } else {
      debugPrint('⚠️ Could not parse link: $linkString');
    }
  }

  /// Store a pending invitation token
  Future<void> storePendingInvitation(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingInvitationKey, token);
      debugPrint('💾 Pending invitation stored: $token');
    } catch (e) {
      debugPrint('❌ Error storing pending invitation: $e');
    }
  }

  /// Get and clear the pending invitation token
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

  /// Check if there's a pending invitation
  Future<bool> hasPendingInvitation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_pendingInvitationKey);
    } catch (e) {
      return false;
    }
  }

  /// Manually process a token (for manual input)
  Future<void> processToken(String token) async {
    await storePendingInvitation(token);
    onInvitationReceived?.call(token);
  }

  /// Dispose the handler
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    debugPrint('🔗 DeepLinkHandler: Disposed');
  }
}

/// Global instance for easy access
final deepLinkHandler = DeepLinkHandler();

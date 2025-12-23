import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/memorial_model.dart';
import '../models/invitation_model.dart';

/// Service for generating and sharing memorial invitation links
class ShareService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Deep Link Scheme (für App-zu-App)
  static const String scheme = 'rememberme';
  static const String invitePath = 'invite';

  // ⚠️ WICHTIG: Ersetze mit deiner Firebase Hosting Domain!
  // Format: projektname.web.app oder deine-custom-domain.com
  static const String webDomain = 'remember-me-5d64f.web.app';

  /// Generates an invitation link for a memorial
  Future<ShareResult> shareMemorial({
    required MemorialModel memorial,
    required String inviterId,
    String? customMessage,
  }) async {
    try {
      // 1. Generate unique ID for the invitation
      final invitationId = _uuid.v4();

      // 2. Create invitation using the factory method
      final invitation = InvitationModel.create(
        id: invitationId,
        memorialId: memorial.id,
        invitedById: inviterId,
        validDays: 30,
      );

      await _firestore
          .collection('invitations')
          .doc(invitationId)
          .set(invitation.toJson());

      // 3. Generate HTTPS link (klickbar überall!)
      final shareLink = generateWebLink(invitation.token);

      // 4. Prepare share message
      final message = customMessage ??
          'Ich möchte die Gedenkseite von ${memorial.name} mit dir teilen 💜\n\n'
              '$shareLink';

      // 5. Open native share sheet
      final result = await Share.share(
        message,
        subject: 'Gedenkseite: ${memorial.name}',
      );

      debugPrint('📤 Share result: ${result.status}');
      debugPrint('🔗 Share link: $shareLink');

      return ShareResult(
        success: true,
        token: invitation.token,
        deepLink: shareLink,
        shareStatus: result.status,
      );
    } catch (e) {
      debugPrint('❌ Error sharing memorial: $e');
      return ShareResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Generates a clickable HTTPS link
  String generateWebLink(String token) {
    return 'https://$webDomain/invite/$token';
  }

  /// Generates a deep link (for app-to-app)
  String generateDeepLink(String token) {
    return '$scheme://$invitePath/$token';
  }

  /// Parses any link format and extracts the token
  static String? parseDeepLink(String link) {
    try {
      final uri = Uri.parse(link);

      // Format 1: rememberme://invite/TOKEN
      if (uri.scheme == scheme && uri.host == invitePath) {
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          return pathSegments.first;
        }
        return uri.path.replaceAll('/', '');
      }

      // Format 2: https://domain.web.app/invite/TOKEN
      if (uri.scheme == 'https' && uri.pathSegments.contains('invite')) {
        final inviteIndex = uri.pathSegments.indexOf('invite');
        if (inviteIndex < uri.pathSegments.length - 1) {
          return uri.pathSegments[inviteIndex + 1];
        }
      }

      // Format 3: https://domain.web.app/invite?token=TOKEN
      if (uri.queryParameters.containsKey('token')) {
        return uri.queryParameters['token'];
      }

      // Format 4: Just a token (16 alphanumeric characters)
      if (RegExp(r'^[a-zA-Z0-9]{16}$').hasMatch(link)) {
        return link;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error parsing link: $e');
      return null;
    }
  }

  /// Validates if a token exists and is still valid
  Future<InvitationValidation> validateToken(String token) async {
    try {
      // Query by token field
      final querySnapshot = await _firestore
          .collection('invitations')
          .where('token', isEqualTo: token)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return InvitationValidation(
          isValid: false,
          error: InvitationError.notFound,
          message: 'Einladung nicht gefunden',
        );
      }

      final doc = querySnapshot.docs.first;
      final invitation = InvitationModel.fromJson({
        'id': doc.id,
        ...doc.data(),
      });

      // Check if expired
      if (DateTime.now().isAfter(invitation.expiresAt)) {
        return InvitationValidation(
          isValid: false,
          error: InvitationError.expired,
          message: 'Diese Einladung ist abgelaufen',
        );
      }

      // Check if already used
      if (invitation.status == InvitationStatus.accepted) {
        return InvitationValidation(
          isValid: false,
          error: InvitationError.alreadyUsed,
          message: 'Diese Einladung wurde bereits verwendet',
        );
      }

      // Check if revoked
      if (invitation.status == InvitationStatus.revoked) {
        return InvitationValidation(
          isValid: false,
          error: InvitationError.revoked,
          message: 'Diese Einladung wurde zurückgezogen',
        );
      }

      return InvitationValidation(
        isValid: true,
        invitation: invitation,
      );
    } catch (e) {
      debugPrint('❌ Error validating token: $e');
      return InvitationValidation(
        isValid: false,
        error: InvitationError.unknown,
        message: 'Fehler beim Überprüfen der Einladung',
      );
    }
  }
}

/// Result of a share operation
class ShareResult {
  final bool success;
  final String? token;
  final String? deepLink;
  final ShareResultStatus? shareStatus;
  final String? errorMessage;

  ShareResult({
    required this.success,
    this.token,
    this.deepLink,
    this.shareStatus,
    this.errorMessage,
  });
}

/// Result of invitation validation
class InvitationValidation {
  final bool isValid;
  final InvitationModel? invitation;
  final InvitationError? error;
  final String? message;

  InvitationValidation({
    required this.isValid,
    this.invitation,
    this.error,
    this.message,
  });
}

/// Possible invitation errors
enum InvitationError {
  notFound,
  expired,
  alreadyUsed,
  revoked,
  unknown,
}

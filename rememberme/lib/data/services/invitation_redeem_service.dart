import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/invitation_model.dart';
import '../models/memorial_model.dart';
import '../models/memorial_access_model.dart';
import 'share_service.dart';
import '../../core/utils/deep_link_handler.dart';

/// Service for redeeming invitation tokens and granting memorial access
class InvitationRedeemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ShareService _shareService = ShareService();

  /// Redeems an invitation for a user
  /// Returns the memorial if successful
  Future<RedeemResult> redeemInvitation({
    required String token,
    required String userId,
  }) async {
    try {
      debugPrint('🎫 Redeeming invitation: $token for user: $userId');

      // 1. Validate the token
      final validation = await _shareService.validateToken(token);

      if (!validation.isValid) {
        return RedeemResult(
          success: false,
          error: validation.error,
          message: validation.message,
        );
      }

      final invitation = validation.invitation!;

      // 2. Load the memorial first to check ownership
      final memorial = await _loadMemorial(invitation.memorialId);

      if (memorial == null) {
        return RedeemResult(
          success: false,
          error: InvitationError.notFound,
          message: 'Gedenkseite nicht gefunden',
        );
      }

      // 3. Check if user is the OWNER of this memorial
      if (memorial.ownerId == userId) {
        debugPrint('ℹ️ User is already the owner of this memorial');
        return RedeemResult(
          success: true,
          memorial: memorial,
          message: 'Du bist der Ersteller dieser Gedenkseite',
          alreadyHadAccess: true,
        );
      }

      // 4. Check if user already has access to this memorial
      final existingAccess = await _firestore
          .collection('memorial_access')
          .where('userId', isEqualTo: userId)
          .where('memorialId', isEqualTo: invitation.memorialId)
          .get();

      if (existingAccess.docs.isNotEmpty) {
        // User already has access - just return success
        debugPrint('ℹ️ User already has access to memorial');

        return RedeemResult(
          success: true,
          memorial: memorial,
          message: 'Du hast bereits Zugang zu dieser Gedenkseite',
          alreadyHadAccess: true,
        );
      }

      // 5. Create memorial access for the user
      final access = MemorialAccessModel.createForInvitee(
        id: '${userId}_${invitation.memorialId}',
        userId: userId,
        memorialId: invitation.memorialId,
        invitedById: invitation.invitedById,
      );

      await _firestore
          .collection('memorial_access')
          .doc('${userId}_${invitation.memorialId}')
          .set(access.toJson());

      debugPrint('✅ Memorial access granted');

      // 6. Update invitation status (use invitation.id as document ID)
      await _firestore.collection('invitations').doc(invitation.id).update({
        'status': 'accepted',
        'usedByUserId': userId,
        'usedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Invitation marked as accepted');

      // 7. Return success

      return RedeemResult(
        success: true,
        memorial: memorial,
        invitation: invitation,
        message: 'Gedenkseite erfolgreich hinzugefügt',
      );
    } catch (e) {
      debugPrint('❌ Error redeeming invitation: $e');
      return RedeemResult(
        success: false,
        error: InvitationError.unknown,
        message: 'Fehler beim Einlösen der Einladung: ${e.toString()}',
      );
    }
  }

  /// Check and redeem any pending invitation after login
  Future<RedeemResult?> checkAndRedeemPendingInvitation(String userId) async {
    try {
      // Get pending invitation token
      final token = await deepLinkHandler.consumePendingInvitation();

      if (token == null) {
        debugPrint('ℹ️ No pending invitation to redeem');
        return null;
      }

      debugPrint('🎫 Found pending invitation: $token');

      // Redeem it
      return await redeemInvitation(
        token: token,
        userId: userId,
      );
    } catch (e) {
      debugPrint('❌ Error checking pending invitation: $e');
      return null;
    }
  }

  /// Load a memorial by ID
  Future<MemorialModel?> _loadMemorial(String memorialId) async {
    try {
      final doc =
          await _firestore.collection('memorials').doc(memorialId).get();

      if (!doc.exists) return null;

      return MemorialModel.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      debugPrint('❌ Error loading memorial: $e');
      return null;
    }
  }

  /// Get all memorials a user has access to (owned + shared)
  Future<List<MemorialModel>> getAccessibleMemorials(String userId) async {
    try {
      final List<MemorialModel> memorials = [];

      // 1. Get owned memorials
      final ownedDocs = await _firestore
          .collection('memorials')
          .where('ownerId', isEqualTo: userId)
          .get();

      for (final doc in ownedDocs.docs) {
        memorials.add(MemorialModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        }));
      }

      // 2. Get shared memorials (via memorial_access)
      final accessDocs = await _firestore
          .collection('memorial_access')
          .where('userId', isEqualTo: userId)
          .get();

      for (final accessDoc in accessDocs.docs) {
        final memorialId = accessDoc.data()['memorialId'] as String?;
        if (memorialId == null) continue;

        // Skip if already in list (user is owner)
        if (memorials.any((m) => m.id == memorialId)) continue;

        final memorial = await _loadMemorial(memorialId);
        if (memorial != null) {
          memorials.add(memorial);
        }
      }

      debugPrint('📚 Found ${memorials.length} accessible memorials for user');
      return memorials;
    } catch (e) {
      debugPrint('❌ Error getting accessible memorials: $e');
      return [];
    }
  }
}

/// Result of redeeming an invitation
class RedeemResult {
  final bool success;
  final MemorialModel? memorial;
  final InvitationModel? invitation;
  final InvitationError? error;
  final String? message;
  final bool alreadyHadAccess;

  RedeemResult({
    required this.success,
    this.memorial,
    this.invitation,
    this.error,
    this.message,
    this.alreadyHadAccess = false,
  });
}

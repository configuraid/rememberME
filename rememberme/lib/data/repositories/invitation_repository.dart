import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/invitation_model.dart';
import '../models/memorial_access_model.dart';

class InvitationRepository {
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  InvitationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ========================================
  // CREATE INVITATION
  // ========================================

  /// Neue Einladung erstellen
  Future<InvitationModel> createInvitation({
    required String memorialId,
    required String invitedById,
    String? email,
    int validDays = 7,
  }) async {
    try {
      print(
          '➕ InvitationRepository - Erstelle Einladung für Memorial: $memorialId');

      final invitationId = _uuid.v4();

      final invitation = InvitationModel.create(
        id: invitationId,
        memorialId: memorialId,
        invitedById: invitedById,
        email: email,
        validDays: validDays,
      );

      await _firestore
          .collection('invitations')
          .doc(invitationId)
          .set(invitation.toJson());

      print(
          '✅ InvitationRepository - Einladung erstellt: ${invitation.inviteUrl}');
      return invitation;
    } catch (e) {
      print('❌ InvitationRepository - Fehler: $e');
      rethrow;
    }
  }

  // ========================================
  // GET INVITATION
  // ========================================

  /// Einladung nach Token laden
  Future<InvitationModel?> getInvitationByToken(String token) async {
    try {
      print('🔍 InvitationRepository - Suche Einladung mit Token: $token');

      final query = await _firestore
          .collection('invitations')
          .where('token', isEqualTo: token)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        print('❌ InvitationRepository - Einladung nicht gefunden');
        return null;
      }

      final invitation = InvitationModel.fromJson({
        ...query.docs.first.data(),
        'id': query.docs.first.id,
      });

      print('✅ InvitationRepository - Einladung gefunden');
      return invitation;
    } catch (e) {
      print('❌ InvitationRepository - Fehler: $e');
      return null;
    }
  }

  /// Einladung nach ID laden
  Future<InvitationModel?> getInvitationById(String invitationId) async {
    try {
      final doc =
          await _firestore.collection('invitations').doc(invitationId).get();

      if (!doc.exists) return null;

      return InvitationModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      print('❌ InvitationRepository - Fehler: $e');
      return null;
    }
  }

  /// Alle Einladungen für ein Memorial laden
  Future<List<InvitationModel>> getInvitationsForMemorial(
      String memorialId) async {
    try {
      print('📚 InvitationRepository - Lade Einladungen für: $memorialId');

      final query = await _firestore
          .collection('invitations')
          .where('memorialId', isEqualTo: memorialId)
          .orderBy('createdAt', descending: true)
          .get();

      final invitations = query.docs
          .map((doc) => InvitationModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      print(
          '✅ InvitationRepository - ${invitations.length} Einladungen geladen');
      return invitations;
    } catch (e) {
      print('❌ InvitationRepository - Fehler: $e');
      return [];
    }
  }

  /// Alle aktiven (pending) Einladungen für ein Memorial
  Future<List<InvitationModel>> getActiveInvitationsForMemorial(
      String memorialId) async {
    try {
      final query = await _firestore
          .collection('invitations')
          .where('memorialId', isEqualTo: memorialId)
          .where('status', isEqualTo: 'pending')
          .get();

      final invitations = query.docs
          .map((doc) => InvitationModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // Filter abgelaufene
      return invitations.where((inv) => !inv.isExpired).toList();
    } catch (e) {
      print('❌ InvitationRepository - Fehler: $e');
      return [];
    }
  }

  // ========================================
  // REDEEM INVITATION
  // ========================================

  /// Einladung einlösen
  /// Gibt MemorialAccessModel zurück wenn erfolgreich
  Future<MemorialAccessModel> redeemInvitation({
    required String token,
    required String userId,
  }) async {
    try {
      print('🎫 InvitationRepository - Löse Einladung ein: $token');

      // 1. Einladung laden
      final invitation = await getInvitationByToken(token);
      if (invitation == null) {
        throw Exception('Einladung nicht gefunden');
      }

      // 2. Prüfen ob gültig
      if (!invitation.isValid) {
        if (invitation.isExpired) {
          throw Exception('Diese Einladung ist abgelaufen');
        }
        if (invitation.isUsed) {
          throw Exception('Diese Einladung wurde bereits verwendet');
        }
        if (invitation.isRevoked) {
          throw Exception('Diese Einladung wurde widerrufen');
        }
        throw Exception('Diese Einladung ist nicht mehr gültig');
      }

      // 3. Prüfen ob User bereits Zugang hat
      final existingAccess = await _firestore
          .collection('memorialAccess')
          .where('memorialId', isEqualTo: invitation.memorialId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (existingAccess.docs.isNotEmpty) {
        throw Exception('Du hast bereits Zugang zu diesem Memorial');
      }

      // 4. MemorialAccess erstellen
      final accessId = _uuid.v4();
      final access = MemorialAccessModel.createForInvitee(
        id: accessId,
        userId: userId,
        memorialId: invitation.memorialId,
        invitedById: invitation.invitedById,
      );

      await _firestore
          .collection('memorialAccess')
          .doc(accessId)
          .set(access.toJson());

      // 5. Einladung als verwendet markieren
      await _firestore.collection('invitations').doc(invitation.id).update({
        'status': InvitationStatus.accepted.name,
        'usedAt': Timestamp.now(),
        'usedByUserId': userId,
      });

      print('✅ InvitationRepository - Einladung eingelöst, Zugang erstellt');
      return access;
    } catch (e) {
      print('❌ InvitationRepository - Fehler: $e');
      rethrow;
    }
  }

  // ========================================
  // REVOKE INVITATION
  // ========================================

  /// Einladung widerrufen
  Future<void> revokeInvitation({
    required String invitationId,
    required String requestingUserId,
  }) async {
    try {
      print('🚫 InvitationRepository - Widerrufe Einladung: $invitationId');

      final invitation = await getInvitationById(invitationId);
      if (invitation == null) {
        throw Exception('Einladung nicht gefunden');
      }

      // Nur der Einladende kann widerrufen
      if (invitation.invitedById != requestingUserId) {
        // Prüfe ob Owner des Memorials
        final memorial = await _firestore
            .collection('memorials')
            .doc(invitation.memorialId)
            .get();

        if (memorial.data()?['ownerId'] != requestingUserId) {
          throw Exception('Keine Berechtigung zum Widerrufen');
        }
      }

      await _firestore.collection('invitations').doc(invitationId).update({
        'status': InvitationStatus.revoked.name,
      });

      print('✅ InvitationRepository - Einladung widerrufen');
    } catch (e) {
      print('❌ InvitationRepository - Fehler: $e');
      rethrow;
    }
  }

  // ========================================
  // DELETE INVITATION
  // ========================================

  /// Einladung löschen
  Future<void> deleteInvitation(String invitationId) async {
    try {
      print('🗑️ InvitationRepository - Lösche Einladung: $invitationId');

      await _firestore.collection('invitations').doc(invitationId).delete();

      print('✅ InvitationRepository - Einladung gelöscht');
    } catch (e) {
      print('❌ InvitationRepository - Fehler: $e');
      rethrow;
    }
  }

  /// Alle Einladungen für ein Memorial löschen
  Future<void> deleteAllInvitationsForMemorial(String memorialId) async {
    try {
      print(
          '🗑️ InvitationRepository - Lösche alle Einladungen für: $memorialId');

      final query = await _firestore
          .collection('invitations')
          .where('memorialId', isEqualTo: memorialId)
          .get();

      for (var doc in query.docs) {
        await doc.reference.delete();
      }

      print(
          '✅ InvitationRepository - ${query.docs.length} Einladungen gelöscht');
    } catch (e) {
      print('❌ InvitationRepository - Fehler: $e');
      rethrow;
    }
  }

  // ========================================
  // CLEANUP EXPIRED
  // ========================================

  /// Abgelaufene Einladungen markieren (für scheduled job)
  Future<int> markExpiredInvitations() async {
    try {
      print('🧹 InvitationRepository - Markiere abgelaufene Einladungen');

      final query = await _firestore
          .collection('invitations')
          .where('status', isEqualTo: 'pending')
          .where('expiresAt', isLessThan: Timestamp.now())
          .get();

      for (var doc in query.docs) {
        await doc.reference.update({
          'status': InvitationStatus.expired.name,
        });
      }

      print(
          '✅ InvitationRepository - ${query.docs.length} Einladungen als abgelaufen markiert');
      return query.docs.length;
    } catch (e) {
      print('❌ InvitationRepository - Fehler: $e');
      return 0;
    }
  }

  // ========================================
  // VALIDATE TOKEN
  // ========================================

  /// Prüfe ob Token gültig ist (ohne einzulösen)
  Future<InvitationValidationResult> validateToken(String token) async {
    try {
      final invitation = await getInvitationByToken(token);

      if (invitation == null) {
        return InvitationValidationResult(
          isValid: false,
          error: 'Einladung nicht gefunden',
        );
      }

      if (invitation.isExpired) {
        return InvitationValidationResult(
          isValid: false,
          error: 'Diese Einladung ist abgelaufen',
          invitation: invitation,
        );
      }

      if (invitation.isUsed) {
        return InvitationValidationResult(
          isValid: false,
          error: 'Diese Einladung wurde bereits verwendet',
          invitation: invitation,
        );
      }

      if (invitation.isRevoked) {
        return InvitationValidationResult(
          isValid: false,
          error: 'Diese Einladung wurde widerrufen',
          invitation: invitation,
        );
      }

      return InvitationValidationResult(
        isValid: true,
        invitation: invitation,
      );
    } catch (e) {
      return InvitationValidationResult(
        isValid: false,
        error: 'Fehler beim Validieren: $e',
      );
    }
  }
}

/// Ergebnis der Token-Validierung
class InvitationValidationResult {
  final bool isValid;
  final String? error;
  final InvitationModel? invitation;

  InvitationValidationResult({
    required this.isValid,
    this.error,
    this.invitation,
  });
}

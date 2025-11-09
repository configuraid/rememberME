import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../models/auth/organization_model.dart';
import '../../models/auth/organization_member_model.dart';
import '../../models/auth/user_model.dart';

class OrganizationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ========== ORGANIZATIONS ==========

  /// Organisation nach Auth-Key finden
  Future<OrganizationModel?> getOrganizationByAuthKey(String authKey) async {
    try {
      print('🔍 Suche Organisation mit Auth-Key: $authKey');

      final querySnapshot = await _firestore
          .collection('organizations')
          .where('authKey', isEqualTo: authKey)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('❌ Keine Organisation mit diesem Auth-Key gefunden');
        return null;
      }

      final doc = querySnapshot.docs.first;
      print('✅ Organisation gefunden: ${doc.id}');
      return OrganizationModel.fromJson({...doc.data(), 'id': doc.id});
    } catch (e) {
      print('❌ Fehler beim Laden der Organisation: $e');
      return null;
    }
  }

  /// Organisation nach ID laden
  Future<OrganizationModel?> getOrganizationById(String organizationId) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return OrganizationModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      print('❌ Fehler beim Laden der Organisation: $e');
      return null;
    }
  }

  /// Neue Organisation erstellen
  Future<OrganizationModel> createOrganization({
    required String name,
    required String authKey,
    required String ownerId,
  }) async {
    try {
      print('➕ Erstelle neue Organisation: $name');

      final orgId = _uuid.v4();
      final organization = OrganizationModel.create(
        id: orgId,
        name: name,
        authKey: authKey,
        ownerId: ownerId,
      );

      await _firestore
          .collection('organizations')
          .doc(orgId)
          .set(organization.toJson());

      print('✅ Organisation erstellt: $orgId');
      return organization;
    } catch (e) {
      print('❌ Fehler beim Erstellen der Organisation: $e');
      rethrow;
    }
  }

  /// Organisation aktualisieren
  Future<void> updateOrganization(OrganizationModel organization) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(organization.id)
          .update(organization.copyWith(updatedAt: DateTime.now()).toJson());

      print('✅ Organisation aktualisiert: ${organization.id}');
    } catch (e) {
      print('❌ Fehler beim Aktualisieren der Organisation: $e');
      rethrow;
    }
  }

  // ========== MEMBERS ==========

  Future<List<OrganizationMemberModel>> getOrganizationMembers(
      String organizationId) async {
    try {
      print('👥 Lade Mitglieder für Organisation: $organizationId');

      final querySnapshot = await _firestore
          .collection('organizationMembers')
          .where('organizationId', isEqualTo: organizationId)
          .get();

      final members = querySnapshot.docs
          .map((doc) =>
              OrganizationMemberModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // ✅ Sortiere lokal im Code
      members.sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

      print('✅ ${members.length} Mitglieder gefunden');
      return members;
    } catch (e) {
      print('❌ Fehler beim Laden der Mitglieder: $e');
      return [];
    }
  }

  /// Mitgliedschaft für einen User in einer Organisation finden
  Future<OrganizationMemberModel?> getMembershipForUser(
    String organizationId,
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('organizationMembers')
          .where('organizationId', isEqualTo: organizationId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return OrganizationMemberModel.fromJson({...doc.data(), 'id': doc.id});
    } catch (e) {
      print('❌ Fehler beim Laden der Mitgliedschaft: $e');
      return null;
    }
  }

  /// Neues Mitglied zur Organisation hinzufügen
  Future<OrganizationMemberModel> addMember({
    required String organizationId,
    required String userId,
    required MemberRole role,
    String? pin,
  }) async {
    try {
      print('➕ Füge Mitglied hinzu: $userId zu Organisation: $organizationId');

      final memberId = _uuid.v4();
      final member = OrganizationMemberModel.create(
        id: memberId,
        organizationId: organizationId,
        userId: userId,
        role: role,
        pin: pin,
      );

      await _firestore
          .collection('organizationMembers')
          .doc(memberId)
          .set(member.toJson());

      print('✅ Mitglied hinzugefügt: $memberId');
      return member;
    } catch (e) {
      print('❌ Fehler beim Hinzufügen des Mitglieds: $e');
      rethrow;
    }
  }

  /// Mitgliedschaft aktualisieren
  Future<void> updateMember(OrganizationMemberModel member) async {
    try {
      await _firestore
          .collection('organizationMembers')
          .doc(member.id)
          .update(member.toJson());

      print('✅ Mitglied aktualisiert: ${member.id}');
    } catch (e) {
      print('❌ Fehler beim Aktualisieren des Mitglieds: $e');
      rethrow;
    }
  }

  /// Mitglied entfernen
  Future<void> removeMember(String memberId) async {
    try {
      await _firestore.collection('organizationMembers').doc(memberId).delete();
      print('✅ Mitglied entfernt: $memberId');
    } catch (e) {
      print('❌ Fehler beim Entfernen des Mitglieds: $e');
      rethrow;
    }
  }

  /// Mitglied-Rolle ändern
  Future<void> updateMemberRole(String memberId, MemberRole newRole) async {
    try {
      await _firestore
          .collection('organizationMembers')
          .doc(memberId)
          .update({'role': newRole.toString().split('.').last});

      print('✅ Rolle aktualisiert für Mitglied: $memberId');
    } catch (e) {
      print('❌ Fehler beim Aktualisieren der Rolle: $e');
      rethrow;
    }
  }

  /// Mitglied-PIN ändern
  Future<void> updateMemberPin(String memberId, String? pin) async {
    try {
      await _firestore
          .collection('organizationMembers')
          .doc(memberId)
          .update({'pin': pin});

      print('✅ PIN aktualisiert für Mitglied: $memberId');
    } catch (e) {
      print('❌ Fehler beim Aktualisieren der PIN: $e');
      rethrow;
    }
  }

  /// Last Active aktualisieren
  Future<void> updateLastActive(String memberId) async {
    try {
      await _firestore.collection('organizationMembers').doc(memberId).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Fehler beim Aktualisieren von lastActive: $e');
    }
  }

  // ========== COMBINED QUERIES ==========

  /// Alle User-Daten für Mitglieder einer Organisation laden
  Future<List<Map<String, dynamic>>> getMembersWithUserData(
      String organizationId) async {
    try {
      print('👥 Lade Mitglieder mit User-Daten für: $organizationId');

      final members = await getOrganizationMembers(organizationId);
      final result = <Map<String, dynamic>>[];

      for (var member in members) {
        final userDoc =
            await _firestore.collection('users').doc(member.userId).get();

        if (userDoc.exists) {
          result.add({
            'member': member,
            'user': UserModel.fromJson({...userDoc.data()!, 'id': userDoc.id}),
          });
        }
      }

      print('✅ ${result.length} Mitglieder mit User-Daten geladen');
      return result;
    } catch (e) {
      print('❌ Fehler beim Laden der Mitglieder mit User-Daten: $e');
      return [];
    }
  }

  /// Prüfe ob User Owner der Organisation ist
  Future<bool> isOrganizationOwner(String organizationId, String userId) async {
    try {
      final org = await getOrganizationById(organizationId);
      return org?.ownerId == userId;
    } catch (e) {
      return false;
    }
  }

  /// Prüfe ob User Admin-Rechte hat
  Future<bool> hasAdminRights(String organizationId, String userId) async {
    try {
      final membership = await getMembershipForUser(organizationId, userId);
      return membership?.isAdmin ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Prüfe ob User Bearbeitungs-Rechte hat
  Future<bool> canEdit(String organizationId, String userId) async {
    try {
      final membership = await getMembershipForUser(organizationId, userId);
      return membership?.canEdit ?? false;
    } catch (e) {
      return false;
    }
  }
}

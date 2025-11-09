import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rememberme/data/models/auth/organization_member_model.dart';
import 'package:rememberme/data/models/auth/organization_model.dart';
import 'package:rememberme/data/models/auth/user_model.dart';
import 'package:rememberme/data/repositories/auth/organization_repository.dart';

/// Firebase Auth Repository
/// Implementiert alle Authentifizierungs-Funktionen mit Firebase
class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final OrganizationRepository _organizationRepo;

  // Current State
  UserModel? _currentUser;
  OrganizationModel? _currentOrganization;
  OrganizationMemberModel? _currentMembership;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    OrganizationRepository? organizationRepo,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _organizationRepo = organizationRepo ?? OrganizationRepository();

  // ========================================
  // GETTERS
  // ========================================

  /// Aktuell eingeloggter User
  UserModel? get currentUser => _currentUser;

  /// Aktuell authentifizierte Organisation
  OrganizationModel? get currentOrganization => _currentOrganization;

  /// Aktuelle Mitgliedschaft des Users in der Organisation
  OrganizationMemberModel? get currentMembership => _currentMembership;

  /// Ist ein User eingeloggt?
  bool get isLoggedIn =>
      _currentUser != null && _firebaseAuth.currentUser != null;

  /// Firebase Auth State Stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Ist User Admin?
  bool get isAdmin => _currentMembership?.isAdmin ?? false;

  /// Ist User Owner?
  bool get isOwner => _currentMembership?.isOwner ?? false;

  /// Kann User bearbeiten?
  bool get canEdit => _currentMembership?.canEdit ?? false;

  // ========================================
  // AUTH KEY / QR CODE LOGIN
  // ========================================

  /// Login mit Auth-Key (SCHRITT 1)
  /// Validiert Auth-Key und gibt Organisation zurück
  Future<OrganizationModel?> loginWithAuthKey(String authKey) async {
    try {
      print('🔐 AuthRepository - Validiere Auth-Key: $authKey');

      // 1. Prüfe ob authKey in authKeys Collection existiert
      final authKeyDoc =
          await _firestore.collection('authKeys').doc(authKey).get();

      if (!authKeyDoc.exists) {
        print('❌ AuthRepository - Auth-Key nicht gefunden');
        return null;
      }

      final authKeyData = authKeyDoc.data()!;
      final isValid = authKeyData['isValid'] as bool? ?? false;

      if (!isValid) {
        print('❌ AuthRepository - Auth-Key ist nicht gültig');
        return null;
      }

      // 2. Lade Organisation für diesen Auth-Key
      final organization =
          await _organizationRepo.getOrganizationByAuthKey(authKey);

      if (organization == null) {
        print('❌ AuthRepository - Keine Organisation für Auth-Key gefunden');
        return null;
      }

      // 3. Setze als aktuelle Organisation (User wird später ausgewählt)
      _currentOrganization = organization;

      print(
          '✅ AuthRepository - Auth-Key gültig - Organisation: ${organization.name}');
      return organization;
    } catch (e) {
      print('❌ AuthRepository - Fehler bei Auth-Key Validierung: $e');
      rethrow;
    }
  }

  /// Login mit QR-Code (nutzt loginWithAuthKey)
  Future<OrganizationModel?> loginWithQRCode(String qrCode) async {
    print('📷 AuthRepository - Login mit QR-Code');
    return loginWithAuthKey(qrCode);
  }

  // ========================================
  // USER SELECTION & PROFILE CREATION
  // ========================================

  /// User aus Organisation auswählen (SCHRITT 2)
  Future<UserModel?> selectUser({
    required String organizationId,
    required String userId,
    String? pin,
  }) async {
    try {
      print('👤 AuthRepository - Wähle User: $userId');
      print('📍 Organisation: $organizationId');

      // 1. Lade Mitgliedschaft
      final membership =
          await _organizationRepo.getMembershipForUser(organizationId, userId);

      if (membership == null) {
        print('❌ AuthRepository - Keine Mitgliedschaft gefunden');
        throw Exception('Keine Mitgliedschaft gefunden');
      }

      // 2. Prüfe PIN falls vorhanden
      if (membership.hasPin) {
        if (pin == null || membership.pin != pin) {
          print('❌ AuthRepository - Falsche PIN');
          throw Exception('Falsche PIN');
        }
      }

      // 3. Firebase Anonymous Login (falls noch nicht eingeloggt)
      User? firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        print('🔐 AuthRepository - Firebase Anonymous Login...');
        final userCredential = await _firebaseAuth.signInAnonymously();
        firebaseUser = userCredential.user;
      }

      if (firebaseUser == null) {
        throw Exception('Firebase Login fehlgeschlagen');
      }

      // 4. Lade User-Daten
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print('❌ AuthRepository - User nicht gefunden');
        throw Exception('User nicht gefunden');
      }

      // 5. Update Firebase UID und lastLogin
      await _firestore.collection('users').doc(userId).update({
        'firebaseUid': firebaseUser.uid,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'primaryOrganizationId': organizationId,
      });

      // 6. Update Mitgliedschaft lastActive
      await _organizationRepo.updateLastActive(membership.id);

      // 7. Lade Organisation (falls noch nicht geladen)
      if (_currentOrganization == null ||
          _currentOrganization!.id != organizationId) {
        _currentOrganization =
            await _organizationRepo.getOrganizationById(organizationId);
      }

      // 8. Setze Current User, Organization und Membership
      _currentUser = UserModel.fromJson({...userDoc.data()!, 'id': userDoc.id});
      _currentMembership = membership;

      print(
          '✅ AuthRepository - User erfolgreich ausgewählt: ${_currentUser!.name}');
      return _currentUser;
    } catch (e) {
      print('❌ AuthRepository - Fehler bei User Selection: $e');
      rethrow;
    }
  }

  /// Neues Profil in Organisation erstellen (SCHRITT 3)
  Future<UserModel?> createNewProfile({
    required String organizationId,
    required String name,
    required String email,
    String? pin,
    MemberRole role = MemberRole.editor, // ✅ Default role
  }) async {
    try {
      print('➕ AuthRepository - Erstelle neues Profil: $name');
      print('📍 Organisation: $organizationId');
      print('👔 Rolle: $role');

      // 1. Firebase Anonymous Login (falls noch nicht eingeloggt)
      User? firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        print('🔐 AuthRepository - Firebase Anonymous Login...');
        final userCredential = await _firebaseAuth.signInAnonymously();
        firebaseUser = userCredential.user;
      }

      if (firebaseUser == null) {
        throw Exception('Firebase Login fehlgeschlagen');
      }

      // 2. Erstelle User
      final userRef = _firestore.collection('users').doc();
      final newUser = UserModel(
        id: userRef.id,
        name: name,
        email: email,
        primaryOrganizationId: organizationId,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        role: UserRole.viewer,
        firebaseUid: firebaseUser.uid,
        profileImageUrl: null,
      );

      await userRef.set(newUser.toJson());

      // 3. Füge User als Mitglied zur Organisation hinzu
      final membership = await _organizationRepo.addMember(
        organizationId: organizationId,
        userId: userRef.id,
        role: role, // ✅ Verwendung des übergebenen role
        pin: pin,
      );

      // 4. Lade Organisation (falls noch nicht geladen)
      if (_currentOrganization == null ||
          _currentOrganization!.id != organizationId) {
        _currentOrganization =
            await _organizationRepo.getOrganizationById(organizationId);
      }

      // 5. Setze Current User, Organization und Membership
      _currentUser = newUser;
      _currentMembership = membership;

      print('✅ AuthRepository - Profil erfolgreich erstellt: ${newUser.name}');
      return newUser;
    } catch (e) {
      print('❌ AuthRepository - Fehler beim Erstellen des Profils: $e');
      rethrow;
    }
  }

  // ========================================
  // PROFILE MANAGEMENT
  // ========================================

  /// User-Profil aktualisieren
  Future<UserModel> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) {
      throw Exception('Kein User eingeloggt');
    }

    if (_currentUser!.id != userId) {
      throw Exception('Kann nur eigenes Profil aktualisieren');
    }

    try {
      print('📝 AuthRepository - Update Profil: $userId');

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      if (profileImageUrl != null) {
        updates['profileImageUrl'] = profileImageUrl;
      }

      if (updates.isEmpty) {
        print('ℹ️ AuthRepository - Keine Änderungen zum Speichern');
        return _currentUser!;
      }

      await _firestore.collection('users').doc(userId).update(updates);

      _currentUser = _currentUser!.copyWith(
        name: name,
        email: email,
        profileImageUrl: profileImageUrl,
      );

      print('✅ AuthRepository - Profil erfolgreich aktualisiert');
      return _currentUser!;
    } catch (e) {
      print('❌ AuthRepository - Fehler beim Aktualisieren des Profils: $e');
      rethrow;
    }
  }

  /// PIN für aktuellen User ändern
  Future<void> updateUserPin(String? newPin) async {
    if (_currentUser == null || _currentMembership == null) {
      throw Exception('Kein User eingeloggt');
    }

    try {
      print('🔒 AuthRepository - PIN aktualisieren...');
      await _organizationRepo.updateMemberPin(_currentMembership!.id, newPin);
      _currentMembership = _currentMembership!.copyWith(pin: newPin);
      print('✅ AuthRepository - PIN erfolgreich aktualisiert');
    } catch (e) {
      print('❌ AuthRepository - Fehler beim Aktualisieren der PIN: $e');
      rethrow;
    }
  }

  // ========================================
  // AUTH STATUS & SESSION
  // ========================================

  /// Auth-Status beim App-Start prüfen
  Future<UserModel?> checkAuthStatus() async {
    try {
      print('🔍 AuthRepository - Prüfe Auth-Status...');

      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        print('ℹ️ AuthRepository - Kein Firebase User eingeloggt');
        return null;
      }

      // User-Daten aus Firestore laden
      final userQuery = await _firestore
          .collection('users')
          .where('firebaseUid', isEqualTo: firebaseUser.uid)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print('❌ AuthRepository - Keine User-Daten gefunden');
        await _firebaseAuth.signOut();
        return null;
      }

      final userDoc = userQuery.docs.first;
      _currentUser = UserModel.fromJson({...userDoc.data(), 'id': userDoc.id});

      // Lade Organisation und Mitgliedschaft
      if (_currentUser!.primaryOrganizationId != null) {
        _currentOrganization = await _organizationRepo
            .getOrganizationById(_currentUser!.primaryOrganizationId!);

        _currentMembership = await _organizationRepo.getMembershipForUser(
          _currentUser!.primaryOrganizationId!,
          _currentUser!.id,
        );
      }

      print('✅ AuthRepository - User eingeloggt: ${_currentUser!.name}');
      return _currentUser;
    } catch (e) {
      print('❌ AuthRepository - Fehler beim Prüfen des Auth-Status: $e');
      // Bei Fehler: Logout und null zurückgeben
      await logout();
      return null;
    }
  }

  /// Token erneuern
  Future<void> refreshAuthToken() async {
    if (_firebaseAuth.currentUser == null) {
      throw Exception('Kein Firebase User eingeloggt');
    }

    if (_currentUser == null) {
      throw Exception('Keine User-Daten vorhanden');
    }

    try {
      print('🔄 AuthRepository - Token erneuern...');

      final refreshedUser = await getUserById(_currentUser!.id);
      if (refreshedUser != null) {
        _currentUser = refreshedUser;
        print('✅ AuthRepository - Token erfolgreich erneuert');
      }
    } catch (e) {
      print('❌ AuthRepository - Fehler beim Erneuern des Tokens: $e');
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      print('👋 AuthRepository - Logout...');

      await _firebaseAuth.signOut();
      _currentUser = null;
      _currentOrganization = null;
      _currentMembership = null;

      print('✅ AuthRepository - Logout erfolgreich');
    } catch (e) {
      print('❌ AuthRepository - Logout Fehler: $e');
      rethrow;
    }
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  /// User nach ID abrufen
  Future<UserModel?> getUserById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromJson({...userDoc.data()!, 'id': userDoc.id});
    } catch (e) {
      print('❌ AuthRepository - Fehler beim Laden des Users: $e');
      return null;
    }
  }

  /// Alle User für Organisation laden (für User Selection Screen)
  Future<List<Map<String, dynamic>>> getUsersForOrganization(
      String organizationId) async {
    try {
      print('👥 AuthRepository - Lade User für Organisation: $organizationId');

      return await _organizationRepo.getMembersWithUserData(organizationId);
    } catch (e) {
      print('❌ AuthRepository - Fehler beim Laden der User: $e');
      return [];
    }
  }
}

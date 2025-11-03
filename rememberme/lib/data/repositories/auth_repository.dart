import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;

  // Getter für aktuellen User
  UserModel? get currentUser => _currentUser;

  // Prüfen ob User eingeloggt ist
  bool get isLoggedIn =>
      _currentUser != null && _firebaseAuth.currentUser != null;

  // Stream für Auth-Status Änderungen
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Login mit Auth-Key
  /// 1. Anonymous Firebase Login
  /// 2. AuthKey in Firestore validieren
  /// 3. User-Daten laden oder erstellen
  Future<UserModel?> loginWithAuthKey(String authKey) async {
    try {
      // 1. Anonymous Login
      User? firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        final userCredential = await _firebaseAuth.signInAnonymously();
        firebaseUser = userCredential.user;
      }

      if (firebaseUser == null) {
        throw Exception('Firebase Anonymous Login fehlgeschlagen');
      }

      // 2. AuthKey validieren
      final authKeyDoc =
          await _firestore.collection('authKeys').doc(authKey).get();

      if (!authKeyDoc.exists) {
        throw Exception('Ungültiger Auth-Key');
      }

      final authKeyData = authKeyDoc.data()!;
      final isValid = authKeyData['isValid'] as bool? ?? false;

      if (!isValid) {
        throw Exception('Auth-Key ist nicht mehr gültig');
      }

      // 3. Suche User mit diesem Firebase UID
      final userQuery = await _firestore
          .collection('users')
          .where('firebaseUid', isEqualTo: firebaseUser.uid)
          .where('authKey', isEqualTo: authKey)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        // User existiert bereits
        final userDoc = userQuery.docs.first;
        _currentUser = UserModel.fromJson({
          ...userDoc.data(),
          'id': userDoc.id,
        });

        await _updateLastLogin(_currentUser!.id);
      } else {
        // Neuen User erstellen
        _currentUser = await _createNewUser(
          authKey: authKey,
          firebaseUid: firebaseUser.uid,
          role: authKeyData['role'] as String? ?? 'viewer',
        );
      }

      return _currentUser;
    } catch (e) {
      print('Login Fehler: $e');
      return null;
    }
  }

  /// Login mit QR-Code (nutzt loginWithAuthKey)
  Future<UserModel?> loginWithQRCode(String qrCode) async {
    return loginWithAuthKey(qrCode);
  }

  /// Neuen User erstellen
  Future<UserModel> _createNewUser({
    required String authKey,
    required String firebaseUid,
    required String role,
  }) async {
    final userRef = _firestore.collection('users').doc();

    final newUser = UserModel(
      id: userRef.id,
      name: 'Neuer Benutzer', // Kann später vom User geändert werden
      email: '', // Wird später vom User eingegeben
      authKey: authKey,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == role,
        orElse: () => UserRole.viewer,
      ),
      firebaseUid: firebaseUid,
    );

    await userRef.set(newUser.toJson());
    return newUser;
  }

  /// LastLogin aktualisieren
  Future<void> _updateLastLogin(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });

    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(lastLoginAt: DateTime.now());
    }
  }

  /// Logout
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _currentUser = null;
  }

  /// User-Profil aktualisieren
  Future<UserModel> updateUserProfile({
    String? name,
    String? email,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) {
      throw Exception('Kein User eingeloggt');
    }

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;
    if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

    await _firestore.collection('users').doc(_currentUser!.id).update(updates);

    _currentUser = _currentUser!.copyWith(
      name: name,
      email: email,
      profileImageUrl: profileImageUrl,
    );

    return _currentUser!;
  }

  /// User nach ID abrufen
  Future<UserModel?> getUserById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromJson({
        ...userDoc.data()!,
        'id': userDoc.id,
      });
    } catch (e) {
      print('Fehler beim Laden des Users: $e');
      return null;
    }
  }

  /// Aktuellen User aus Firestore neu laden
  Future<void> refreshAuthToken() async {
    if (_firebaseAuth.currentUser == null) {
      throw Exception('Kein Firebase User eingeloggt');
    }

    if (_currentUser == null) {
      throw Exception('Kein User-Daten vorhanden');
    }

    // User-Daten neu laden
    final refreshedUser = await getUserById(_currentUser!.id);
    if (refreshedUser != null) {
      _currentUser = refreshedUser;
    }
  }

  /// Auth-Status beim App-Start prüfen
  /// Lädt User-Daten wenn Firebase User existiert
  Future<UserModel?> checkAuthStatus() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        return null;
      }

      // User-Daten aus Firestore laden
      final userQuery = await _firestore
          .collection('users')
          .where('firebaseUid', isEqualTo: firebaseUser.uid)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        // Firebase User existiert, aber keine User-Daten
        // User muss sich neu mit authKey einloggen
        await _firebaseAuth.signOut();
        return null;
      }

      final userDoc = userQuery.docs.first;
      _currentUser = UserModel.fromJson({
        ...userDoc.data(),
        'id': userDoc.id,
      });

      return _currentUser;
    } catch (e) {
      print('Fehler beim Prüfen des Auth-Status: $e');
      return null;
    }
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Auth Repository
///
/// Email/Password Authentifizierung mit Firebase.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  UserModel? _currentUser;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // ========================================
  // GETTERS
  // ========================================

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _auth.currentUser != null && _currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  String? get currentUserId => _currentUser?.id;

  // ========================================
  // REGISTER
  // ========================================

  /// Neuen User registrieren
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      print('📝 AuthRepository - Registrierung: $email');

      // 1. Firebase Auth Account erstellen
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Firebase User konnte nicht erstellt werden');
      }

      // 2. Display Name in Firebase Auth setzen
      await firebaseUser.updateDisplayName(displayName);

      // 3. User Document in Firestore erstellen
      final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
      final user = UserModel.create(
        id: firebaseUser.uid,
        email: email,
        displayName: displayName,
        firebaseUid: firebaseUser.uid,
      );

      await userDoc.set(user.toJson());

      _currentUser = user;
      print('✅ AuthRepository - User registriert: ${user.displayName}');
      return user;
    } catch (e) {
      print('❌ AuthRepository - Registrierung fehlgeschlagen: $e');
      rethrow;
    }
  }

  // ========================================
  // LOGIN
  // ========================================

  /// Mit Email/Password einloggen
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 AuthRepository - Login: $email');

      // 1. Firebase Auth Login
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Login fehlgeschlagen');
      }

      // 2. User aus Firestore laden
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        throw Exception('User-Daten nicht gefunden');
      }

      // 3. Last Login aktualisieren
      await userDoc.reference.update({
        'lastLoginAt': Timestamp.now(),
      });

      _currentUser = UserModel.fromJson({
        ...userDoc.data()!,
        'id': userDoc.id,
      });

      print(
          '✅ AuthRepository - Login erfolgreich: ${_currentUser!.displayName}');
      return _currentUser!;
    } catch (e) {
      print('❌ AuthRepository - Login fehlgeschlagen: $e');
      rethrow;
    }
  }

  // ========================================
  // LOGOUT
  // ========================================

  /// Ausloggen
  Future<void> logout() async {
    try {
      print('👋 AuthRepository - Logout');
      await _auth.signOut();
      _currentUser = null;
      print('✅ AuthRepository - Logout erfolgreich');
    } catch (e) {
      print('❌ AuthRepository - Logout fehlgeschlagen: $e');
      rethrow;
    }
  }

  // ========================================
  // PASSWORD RESET
  // ========================================

  /// Passwort Reset Email senden
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('🔑 AuthRepository - Password Reset: $email');
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ AuthRepository - Reset Email gesendet');
    } catch (e) {
      print('❌ AuthRepository - Password Reset fehlgeschlagen: $e');
      rethrow;
    }
  }

  // ========================================
  // GET CURRENT USER
  // ========================================

  /// Aktuellen User laden (für App-Start)
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;

      if (firebaseUser == null) {
        print('ℹ️ AuthRepository - Kein Firebase User');
        return null;
      }

      // User aus Firestore laden
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        print('⚠️ AuthRepository - User-Dokument nicht gefunden');
        await _auth.signOut();
        return null;
      }

      _currentUser = UserModel.fromJson({
        ...userDoc.data()!,
        'id': userDoc.id,
      });

      print('✅ AuthRepository - User geladen: ${_currentUser!.displayName}');
      return _currentUser;
    } catch (e) {
      print('❌ AuthRepository - getCurrentUser fehlgeschlagen: $e');
      return null;
    }
  }

  // ========================================
  // UPDATE PROFILE
  // ========================================

  /// Profil aktualisieren
  Future<UserModel> updateProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      print('📝 AuthRepository - Update Profile: $userId');

      final updates = <String, dynamic>{};

      if (displayName != null) {
        updates['displayName'] = displayName;
        await _auth.currentUser?.updateDisplayName(displayName);
      }

      if (avatarUrl != null) {
        updates['avatarUrl'] = avatarUrl;
        await _auth.currentUser?.updatePhotoURL(avatarUrl);
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updates);
      }

      // Aktualisiertes User laden
      final userDoc = await _firestore.collection('users').doc(userId).get();
      _currentUser = UserModel.fromJson({
        ...userDoc.data()!,
        'id': userDoc.id,
      });

      print('✅ AuthRepository - Profil aktualisiert');
      return _currentUser!;
    } catch (e) {
      print('❌ AuthRepository - Update Profile fehlgeschlagen: $e');
      rethrow;
    }
  }

  // ========================================
  // GET USER BY ID
  // ========================================

  /// User nach ID laden
  Future<UserModel?> getUserById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return null;

      return UserModel.fromJson({
        ...userDoc.data()!,
        'id': userDoc.id,
      });
    } catch (e) {
      print('❌ AuthRepository - getUserById fehlgeschlagen: $e');
      return null;
    }
  }

  // ========================================
  // DELETE ACCOUNT
  // ========================================

  /// Account komplett löschen
  Future<void> deleteAccount() async {
    try {
      print('🗑️ AuthRepository - Lösche Account');

      final userId = _currentUser?.id;
      if (userId == null) {
        throw Exception('Kein User eingeloggt');
      }

      // 1. User-Dokument löschen
      await _firestore.collection('users').doc(userId).delete();

      // 2. Firebase Auth Account löschen
      await _auth.currentUser?.delete();

      _currentUser = null;
      print('✅ AuthRepository - Account gelöscht');
    } catch (e) {
      print('❌ AuthRepository - Account löschen fehlgeschlagen: $e');
      rethrow;
    }
  }
}

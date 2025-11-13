import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../business_logic/profile/profile_state.dart';
import '../services/firebase_storage_service.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorageService _storageService = FirebaseStorageService();

  // ========== SETTINGS ==========

  /// Lade User-Settings aus Firestore
  Future<ProfileSettings> getSettings(String userId) async {
    print('⚙️ ProfileRepository - Lade Settings für User: $userId');

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print('❌ ProfileRepository - User nicht gefunden');
        return _getDefaultSettings();
      }

      final data = userDoc.data()!;
      final settings = data['settings'] as Map<String, dynamic>?;

      if (settings == null) {
        print('ℹ️ ProfileRepository - Keine Settings gefunden, nutze Defaults');
        return _getDefaultSettings();
      }

      print('✅ ProfileRepository - Settings geladen');
      return ProfileSettings(
        themeMode: settings['themeMode'] as String? ?? 'system',
        languageCode: settings['languageCode'] as String? ?? 'de',
        pushNotifications: settings['pushNotifications'] as bool? ?? true,
        emailNotifications: settings['emailNotifications'] as bool? ?? true,
        memorialUpdates: settings['memorialUpdates'] as bool? ?? true,
        groupInvites: settings['groupInvites'] as bool? ?? true,
        profilePublic: settings['profilePublic'] as bool? ?? false,
        showEmail: settings['showEmail'] as bool? ?? false,
        allowSearchEngines: settings['allowSearchEngines'] as bool? ?? false,
      );
    } catch (e) {
      print('❌ ProfileRepository - Fehler beim Laden der Settings: $e');
      return _getDefaultSettings();
    }
  }

  ProfileSettings _getDefaultSettings() {
    return const ProfileSettings(
      themeMode: 'system',
      languageCode: 'de',
      pushNotifications: true,
      emailNotifications: true,
      memorialUpdates: true,
      groupInvites: true,
      profilePublic: false,
      showEmail: false,
      allowSearchEngines: false,
    );
  }

  // ========== STATISTICS ==========

  /// Berechne Statistiken aus vorhandenen Daten
  Future<ProfileStatistics> getStatistics(String userId) async {
    print('📊 ProfileRepository - Berechne Statistiken für User: $userId');

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('❌ ProfileRepository - User nicht gefunden');
        return _getDefaultStatistics();
      }

      final userData = userDoc.data()!;
      final organizationId = userData['primaryOrganizationId'] as String?;

      if (organizationId == null) {
        print('ℹ️ ProfileRepository - Keine Organisation gefunden');
        return _getDefaultStatistics();
      }

      // 1. Zähle Memorials der Organisation
      final memorialsQuery = await _firestore
          .collection('memorials')
          .where('organizationId', isEqualTo: organizationId)
          .get();

      final totalMemorials = memorialsQuery.docs.length;
      final publishedMemorials = memorialsQuery.docs
          .where((doc) => doc.data()['isPublished'] == true)
          .length;

      // 2. Summiere Views
      int totalViews = 0;
      for (var doc in memorialsQuery.docs) {
        totalViews += (doc.data()['viewCount'] as int? ?? 0);
      }

      // 3. Zähle Gruppenmitgliedschaften (Organizations)
      final membershipsQuery = await _firestore
          .collection('organizationMembers')
          .where('userId', isEqualTo: userId)
          .get();

      final groupMemberships = membershipsQuery.docs.length;

      // 4. Member Since Datum
      final memberSince =
          (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      print('✅ ProfileRepository - Statistiken berechnet:');
      print(
          '   📄 Memorials: $totalMemorials ($publishedMemorials veröffentlicht)');
      print('   👁️ Views: $totalViews');
      print('   👥 Gruppenmitgliedschaften: $groupMemberships');

      return ProfileStatistics(
        totalMemorials: totalMemorials,
        publishedMemorials: publishedMemorials,
        totalViews: totalViews,
        totalCondolences:
            0, // TODO: Condolences Feature noch nicht implementiert
        groupMemberships: groupMemberships,
        memberSince: memberSince,
      );
    } catch (e) {
      print('❌ ProfileRepository - Fehler beim Berechnen der Statistiken: $e');
      return _getDefaultStatistics();
    }
  }

  ProfileStatistics _getDefaultStatistics() {
    return ProfileStatistics(
      totalMemorials: 0,
      publishedMemorials: 0,
      totalViews: 0,
      totalCondolences: 0,
      groupMemberships: 0,
      memberSince: DateTime.now(),
    );
  }

  // ========== PROFILE ==========

  /// Lade User-Profil
  Future<Map<String, dynamic>> getProfile(String userId) async {
    print('👤 ProfileRepository - Lade Profil für User: $userId');

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print('❌ ProfileRepository - User nicht gefunden');
        throw Exception('User nicht gefunden');
      }

      final data = userDoc.data()!;

      print('✅ ProfileRepository - Profil geladen: ${data['name']}');
      return {
        'imageUrl': data['profileImageUrl'],
        'name': data['name'] ?? '',
        'email': data['email'] ?? '',
        'phone': data['phone'] ?? '',
        'bio': data['bio'] ?? '',
      };
    } catch (e) {
      print('❌ ProfileRepository - Fehler beim Laden des Profils: $e');
      rethrow;
    }
  }

  /// Aktualisiere User-Profil
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? email,
    String? phone,
    String? bio,
  }) async {
    print('📝 ProfileRepository - Aktualisiere Profil für User: $userId');

    final currentUser = FirebaseAuth.instance.currentUser;
    print('🔑 Firebase Auth UID: ${currentUser?.uid}');
    print('🆔 Übergebene userId: $userId');
    print('✅ Match: ${currentUser?.uid == userId}');

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      if (phone != null) updates['phone'] = phone;
      if (bio != null) updates['bio'] = bio;

      print('📦 Updates: $updates');

      await _firestore.collection('users').doc(userId).update(updates);

      print('✅ ProfileRepository - Profil aktualisiert');
    } catch (e) {
      print('❌ ProfileRepository - Fehler beim Aktualisieren: $e');
      print('❌ Error Type: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('❌ Firebase Code: ${e.code}');
        print('❌ Firebase Message: ${e.message}');
      }
      rethrow;
    }
  }

  /// Aktualisiere Profilbild mit Firebase Storage Integration
  Future<String> updateProfileImage({
    required String userId,
    required String imagePath,
  }) async {
    print('📷 ProfileRepository - Aktualisiere Profilbild für User: $userId');

    try {
      // 1. Upload image to Firebase Storage
      final imageFile = File(imagePath);
      final String downloadUrl = await _storageService.uploadProfileImage(
        userId: userId,
        imageFile: imageFile,
      );

      // 2. Update user document with new profile image URL
      await _firestore.collection('users').doc(userId).update({
        'profileImageUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ ProfileRepository - Profilbild aktualisiert: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print(
          '❌ ProfileRepository - Fehler beim Aktualisieren des Profilbilds: $e');
      rethrow;
    }
  }

  // ========== THEME & LANGUAGE ==========

  /// Aktualisiere Theme-Einstellung
  Future<void> updateTheme(String userId, String themeMode) async {
    print('🎨 ProfileRepository - Aktualisiere Theme: $themeMode');

    try {
      await _firestore.collection('users').doc(userId).update({
        'settings.themeMode': themeMode,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ ProfileRepository - Theme aktualisiert');
    } catch (e) {
      print('❌ ProfileRepository - Fehler: $e');
      rethrow;
    }
  }

  /// Aktualisiere Sprache
  Future<void> updateLanguage(String userId, String languageCode) async {
    print('🌐 ProfileRepository - Aktualisiere Sprache: $languageCode');

    try {
      await _firestore.collection('users').doc(userId).update({
        'settings.languageCode': languageCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ ProfileRepository - Sprache aktualisiert');
    } catch (e) {
      print('❌ ProfileRepository - Fehler: $e');
      rethrow;
    }
  }

  // ========== NOTIFICATION SETTINGS ==========

  /// Aktualisiere Benachrichtigungs-Einstellungen
  Future<void> updateNotificationSettings({
    required String userId,
    required bool pushEnabled,
    required bool emailEnabled,
    required bool memorialUpdates,
    required bool groupInvites,
  }) async {
    print(
        '🔔 ProfileRepository - Aktualisiere Benachrichtigungs-Einstellungen');

    try {
      await _firestore.collection('users').doc(userId).update({
        'settings.pushNotifications': pushEnabled,
        'settings.emailNotifications': emailEnabled,
        'settings.memorialUpdates': memorialUpdates,
        'settings.groupInvites': groupInvites,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print(
          '✅ ProfileRepository - Benachrichtigungs-Einstellungen aktualisiert');
    } catch (e) {
      print('❌ ProfileRepository - Fehler: $e');
      rethrow;
    }
  }

  // ========== PRIVACY SETTINGS ==========

  /// Aktualisiere Datenschutz-Einstellungen
  Future<void> updatePrivacySettings({
    required String userId,
    required bool profilePublic,
    required bool showEmail,
    required bool allowSearchEngines,
  }) async {
    print('🔒 ProfileRepository - Aktualisiere Datenschutz-Einstellungen');

    try {
      await _firestore.collection('users').doc(userId).update({
        'settings.profilePublic': profilePublic,
        'settings.showEmail': showEmail,
        'settings.allowSearchEngines': allowSearchEngines,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ ProfileRepository - Datenschutz-Einstellungen aktualisiert');
    } catch (e) {
      print('❌ ProfileRepository - Fehler: $e');
      rethrow;
    }
  }

  // ========== PASSWORD & ACCOUNT ==========

  /// Ändere Passwort
  /// Hinweis: Bei Anonymous Auth gibt es kein Passwort
  /// Diese Methode ist für zukünftige Email/Password Auth vorbereitet
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    print('🔐 ProfileRepository - Passwort-Änderung angefordert');

    // TODO: Firebase Auth Password Change
    // Bei Anonymous Auth nicht verfügbar
    // Für Email/Password Auth:
    // final user = FirebaseAuth.instance.currentUser;
    // await user?.updatePassword(newPassword);

    throw UnimplementedError(
        'Passwort-Änderung ist bei Anonymous Auth nicht verfügbar');
  }

  /// Lösche Account
  Future<void> deleteAccount({
    required String userId,
    required String password,
  }) async {
    print('🗑️ ProfileRepository - Account-Löschung angefordert für: $userId');

    try {
      // 1. Lösche Profilbild aus Storage
      await _storageService.deleteProfileImage(userId: userId);

      // 2. Lösche alle Memorials des Users
      final memorialsQuery = await _firestore
          .collection('memorials')
          .where('ownerId', isEqualTo: userId)
          .get();

      for (var doc in memorialsQuery.docs) {
        await doc.reference.delete();
      }

      // 3. Lösche alle Mitgliedschaften
      final membershipsQuery = await _firestore
          .collection('organizationMembers')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in membershipsQuery.docs) {
        await doc.reference.delete();
      }

      // 4. Lösche User-Dokument
      await _firestore.collection('users').doc(userId).delete();

      // 5. Lösche Firebase Auth Account
      // TODO: FirebaseAuth.instance.currentUser?.delete();

      print('✅ ProfileRepository - Account erfolgreich gelöscht');
    } catch (e) {
      print('❌ ProfileRepository - Fehler beim Löschen des Accounts: $e');
      rethrow;
    }
  }
}

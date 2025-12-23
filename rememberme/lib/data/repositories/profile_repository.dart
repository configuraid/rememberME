import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_storage_service.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorageService _storageService;

  ProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseStorageService? storageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storageService = storageService ?? FirebaseStorageService();

  // ========================================
  // PROFILE
  // ========================================

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

      print('✅ ProfileRepository - Profil geladen: ${data['displayName']}');
      return {
        'id': userId,
        'avatarUrl': data['avatarUrl'],
        'displayName': data['displayName'] ?? '',
        'email': data['email'] ?? '',
        'phone': data['phone'] ?? '',
        'bio': data['bio'] ?? '',
        'createdAt': data['createdAt'],
        'lastLoginAt': data['lastLoginAt'],
      };
    } catch (e) {
      print('❌ ProfileRepository - Fehler beim Laden des Profils: $e');
      rethrow;
    }
  }

  /// Aktualisiere User-Profil
  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? email,
    String? phone,
    String? bio,
  }) async {
    print('📝 ProfileRepository - Aktualisiere Profil für User: $userId');

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) {
        updates['displayName'] = displayName;
        // Auch in Firebase Auth aktualisieren
        await FirebaseAuth.instance.currentUser?.updateDisplayName(displayName);
      }
      if (email != null) updates['email'] = email;
      if (phone != null) updates['phone'] = phone;
      if (bio != null) updates['bio'] = bio;

      print('📦 Updates: $updates');

      await _firestore.collection('users').doc(userId).update(updates);

      print('✅ ProfileRepository - Profil aktualisiert');
    } catch (e) {
      print('❌ ProfileRepository - Fehler beim Aktualisieren: $e');
      rethrow;
    }
  }

  /// Aktualisiere Profilbild
  Future<String> updateProfileImage({
    required String userId,
    required String imagePath,
  }) async {
    print('📷 ProfileRepository - Aktualisiere Profilbild für User: $userId');

    try {
      // 1. Upload to Firebase Storage
      final imageFile = File(imagePath);
      final String downloadUrl = await _storageService.uploadProfileImage(
        userId: userId,
        imageFile: imageFile,
      );

      // 2. Update user document
      await _firestore.collection('users').doc(userId).update({
        'avatarUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Update Firebase Auth
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(downloadUrl);

      print('✅ ProfileRepository - Profilbild aktualisiert: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print(
          '❌ ProfileRepository - Fehler beim Aktualisieren des Profilbilds: $e');
      rethrow;
    }
  }

  /// Lösche Profilbild
  Future<void> deleteProfileImage(String userId) async {
    print('🗑️ ProfileRepository - Lösche Profilbild für User: $userId');

    try {
      await _storageService.deleteProfileImage(userId: userId);

      await _firestore.collection('users').doc(userId).update({
        'avatarUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseAuth.instance.currentUser?.updatePhotoURL(null);

      print('✅ ProfileRepository - Profilbild gelöscht');
    } catch (e) {
      print('❌ ProfileRepository - Fehler: $e');
      rethrow;
    }
  }

  // ========================================
  // SETTINGS
  // ========================================

  /// Lade User-Settings
  Future<ProfileSettings> getSettings(String userId) async {
    print('⚙️ ProfileRepository - Lade Settings für User: $userId');

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print('❌ ProfileRepository - User nicht gefunden');
        return ProfileSettings.defaults();
      }

      final data = userDoc.data()!;
      final settings = data['settings'] as Map<String, dynamic>?;

      if (settings == null) {
        print('ℹ️ ProfileRepository - Keine Settings gefunden, nutze Defaults');
        return ProfileSettings.defaults();
      }

      print('✅ ProfileRepository - Settings geladen');
      return ProfileSettings.fromJson(settings);
    } catch (e) {
      print('❌ ProfileRepository - Fehler beim Laden der Settings: $e');
      return ProfileSettings.defaults();
    }
  }

  /// Aktualisiere Theme
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

  /// Aktualisiere Benachrichtigungs-Einstellungen
  Future<void> updateNotificationSettings({
    required String userId,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? memorialUpdates,
    bool? groupInvites,
  }) async {
    print(
        '🔔 ProfileRepository - Aktualisiere Benachrichtigungs-Einstellungen');

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (pushEnabled != null)
        updates['settings.pushNotifications'] = pushEnabled;
      if (emailEnabled != null)
        updates['settings.emailNotifications'] = emailEnabled;
      if (memorialUpdates != null)
        updates['settings.memorialUpdates'] = memorialUpdates;
      if (groupInvites != null) updates['settings.groupInvites'] = groupInvites;

      await _firestore.collection('users').doc(userId).update(updates);

      print(
          '✅ ProfileRepository - Benachrichtigungs-Einstellungen aktualisiert');
    } catch (e) {
      print('❌ ProfileRepository - Fehler: $e');
      rethrow;
    }
  }

  /// Aktualisiere Datenschutz-Einstellungen
  Future<void> updatePrivacySettings({
    required String userId,
    bool? profilePublic,
    bool? showEmail,
    bool? allowSearchEngines,
  }) async {
    print('🔒 ProfileRepository - Aktualisiere Datenschutz-Einstellungen');

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (profilePublic != null)
        updates['settings.profilePublic'] = profilePublic;
      if (showEmail != null) updates['settings.showEmail'] = showEmail;
      if (allowSearchEngines != null)
        updates['settings.allowSearchEngines'] = allowSearchEngines;

      await _firestore.collection('users').doc(userId).update(updates);

      print('✅ ProfileRepository - Datenschutz-Einstellungen aktualisiert');
    } catch (e) {
      print('❌ ProfileRepository - Fehler: $e');
      rethrow;
    }
  }

  // ========================================
  // STATISTICS
  // ========================================

  /// Berechne Statistiken
  Future<ProfileStatistics> getStatistics(String userId) async {
    print('📊 ProfileRepository - Berechne Statistiken für User: $userId');

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('❌ ProfileRepository - User nicht gefunden');
        return ProfileStatistics.empty();
      }

      final userData = userDoc.data()!;

      // 1. Lade alle Memorials wo User Zugang hat
      final accessQuery = await _firestore
          .collection('memorialAccess')
          .where('userId', isEqualTo: userId)
          .get();

      final memorialIds = accessQuery.docs
          .map((doc) => doc.data()['memorialId'] as String)
          .toList();

      // 2. Zähle eigene Memorials
      final ownedQuery = await _firestore
          .collection('memorials')
          .where('ownerId', isEqualTo: userId)
          .get();

      final totalOwned = ownedQuery.docs.length;
      final publishedOwned = ownedQuery.docs
          .where((doc) => doc.data()['status'] == 'published')
          .length;

      // 3. Summiere Views
      int totalViews = 0;
      for (var doc in ownedQuery.docs) {
        totalViews += (doc.data()['viewCount'] as int? ?? 0);
      }

      // 4. Member Since
      final memberSince = userData['createdAt'] is Timestamp
          ? (userData['createdAt'] as Timestamp).toDate()
          : DateTime.now();

      print('✅ ProfileRepository - Statistiken berechnet:');
      print(
          '   📄 Eigene Memorials: $totalOwned ($publishedOwned veröffentlicht)');
      print('   👁️ Views: $totalViews');
      print('   🔗 Zugang zu: ${memorialIds.length} Memorials');

      return ProfileStatistics(
        totalMemorialsOwned: totalOwned,
        publishedMemorials: publishedOwned,
        totalMemorialsAccess: memorialIds.length,
        totalViews: totalViews,
        memberSince: memberSince,
      );
    } catch (e) {
      print('❌ ProfileRepository - Fehler beim Berechnen der Statistiken: $e');
      return ProfileStatistics.empty();
    }
  }

  // ========================================
  // ACCOUNT
  // ========================================

  /// Passwort ändern
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    print('🔐 ProfileRepository - Passwort-Änderung angefordert');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Kein User eingeloggt');
      }

      // Re-Authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Change Password
      await user.updatePassword(newPassword);

      print('✅ ProfileRepository - Passwort geändert');
    } catch (e) {
      print('❌ ProfileRepository - Fehler beim Ändern des Passworts: $e');
      rethrow;
    }
  }

  /// Account komplett löschen
  Future<void> deleteAccount({
    required String userId,
    required String password,
  }) async {
    print('🗑️ ProfileRepository - Account-Löschung angefordert für: $userId');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Kein User eingeloggt');
      }

      // Re-Authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // 1. Lösche Profilbild aus Storage
      try {
        await _storageService.deleteProfileImage(userId: userId);
      } catch (_) {
        // Ignore if no profile image
      }

      // 2. Lösche alle eigenen Memorials
      final ownedMemorials = await _firestore
          .collection('memorials')
          .where('ownerId', isEqualTo: userId)
          .get();

      for (var doc in ownedMemorials.docs) {
        // Lösche zugehörige Access-Einträge
        final accessDocs = await _firestore
            .collection('memorialAccess')
            .where('memorialId', isEqualTo: doc.id)
            .get();
        for (var accessDoc in accessDocs.docs) {
          await accessDoc.reference.delete();
        }

        // Lösche zugehörige Invitations
        final inviteDocs = await _firestore
            .collection('invitations')
            .where('memorialId', isEqualTo: doc.id)
            .get();
        for (var inviteDoc in inviteDocs.docs) {
          await inviteDoc.reference.delete();
        }

        // Lösche Memorial
        await doc.reference.delete();
      }

      // 3. Lösche alle Access-Einträge des Users
      final userAccess = await _firestore
          .collection('memorialAccess')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in userAccess.docs) {
        await doc.reference.delete();
      }

      // 4. Lösche User-Dokument
      await _firestore.collection('users').doc(userId).delete();

      // 5. Lösche Firebase Auth Account
      await user.delete();

      print('✅ ProfileRepository - Account erfolgreich gelöscht');
    } catch (e) {
      print('❌ ProfileRepository - Fehler beim Löschen des Accounts: $e');
      rethrow;
    }
  }
}

// ========================================
// HELPER CLASSES
// ========================================

/// Profile Settings
class ProfileSettings {
  final String themeMode;
  final String languageCode;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool memorialUpdates;
  final bool groupInvites;
  final bool profilePublic;
  final bool showEmail;
  final bool allowSearchEngines;

  const ProfileSettings({
    required this.themeMode,
    required this.languageCode,
    required this.pushNotifications,
    required this.emailNotifications,
    required this.memorialUpdates,
    required this.groupInvites,
    required this.profilePublic,
    required this.showEmail,
    required this.allowSearchEngines,
  });

  factory ProfileSettings.defaults() {
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

  factory ProfileSettings.fromJson(Map<String, dynamic> json) {
    return ProfileSettings(
      themeMode: json['themeMode'] as String? ?? 'system',
      languageCode: json['languageCode'] as String? ?? 'de',
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      emailNotifications: json['emailNotifications'] as bool? ?? true,
      memorialUpdates: json['memorialUpdates'] as bool? ?? true,
      groupInvites: json['groupInvites'] as bool? ?? true,
      profilePublic: json['profilePublic'] as bool? ?? false,
      showEmail: json['showEmail'] as bool? ?? false,
      allowSearchEngines: json['allowSearchEngines'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'languageCode': languageCode,
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'memorialUpdates': memorialUpdates,
      'groupInvites': groupInvites,
      'profilePublic': profilePublic,
      'showEmail': showEmail,
      'allowSearchEngines': allowSearchEngines,
    };
  }

  ProfileSettings copyWith({
    String? themeMode,
    String? languageCode,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? memorialUpdates,
    bool? groupInvites,
    bool? profilePublic,
    bool? showEmail,
    bool? allowSearchEngines,
  }) {
    return ProfileSettings(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      memorialUpdates: memorialUpdates ?? this.memorialUpdates,
      groupInvites: groupInvites ?? this.groupInvites,
      profilePublic: profilePublic ?? this.profilePublic,
      showEmail: showEmail ?? this.showEmail,
      allowSearchEngines: allowSearchEngines ?? this.allowSearchEngines,
    );
  }
}

/// Profile Statistics
class ProfileStatistics {
  final int totalMemorialsOwned;
  final int publishedMemorials;
  final int totalMemorialsAccess;
  final int totalViews;
  final DateTime memberSince;

  const ProfileStatistics({
    required this.totalMemorialsOwned,
    required this.publishedMemorials,
    required this.totalMemorialsAccess,
    required this.totalViews,
    required this.memberSince,
  });

  factory ProfileStatistics.empty() {
    return ProfileStatistics(
      totalMemorialsOwned: 0,
      publishedMemorials: 0,
      totalMemorialsAccess: 0,
      totalViews: 0,
      memberSince: DateTime.now(),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result of memorial validation
class MemorialValidationResult {
  final bool exists;
  final String? memorialId;
  final String? memorialName;
  final String? errorMessage;

  const MemorialValidationResult._({
    required this.exists,
    this.memorialId,
    this.memorialName,
    this.errorMessage,
  });

  factory MemorialValidationResult.found({
    required String memorialId,
    required String memorialName,
  }) {
    return MemorialValidationResult._(
      exists: true,
      memorialId: memorialId,
      memorialName: memorialName,
    );
  }

  factory MemorialValidationResult.notFound() {
    return const MemorialValidationResult._(
      exists: false,
      errorMessage: 'Diese Gedenkseite existiert nicht.',
    );
  }

  factory MemorialValidationResult.error(String message) {
    return MemorialValidationResult._(
      exists: false,
      errorMessage: message,
    );
  }
}

/// Service for validating memorial IDs and managing pending QR access
class MemorialValidationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Key for storing pending memorial ID in SharedPreferences
  static const String _pendingMemorialKey = 'pending_qr_memorial_id';

  /// Singleton instance
  static final MemorialValidationService _instance =
      MemorialValidationService._internal();
  factory MemorialValidationService() => _instance;
  MemorialValidationService._internal();

  /// Validates if a memorial exists in Firestore
  ///
  /// Returns [MemorialValidationResult] with memorial info if found
  Future<MemorialValidationResult> validateMemorial(String memorialId) async {
    try {
      debugPrint('🔍 Validating memorial: $memorialId');

      final doc =
          await _firestore.collection('memorials').doc(memorialId).get();

      if (!doc.exists) {
        debugPrint('❌ Memorial not found: $memorialId');
        return MemorialValidationResult.notFound();
      }

      final data = doc.data()!;
      final name = data['name'] as String? ?? 'Unbekannt';

      debugPrint('✅ Memorial found: $name');

      return MemorialValidationResult.found(
        memorialId: memorialId,
        memorialName: name,
      );
    } catch (e) {
      debugPrint('❌ Error validating memorial: $e');
      return MemorialValidationResult.error(
        'Fehler bei der Überprüfung. Bitte versuche es erneut.',
      );
    }
  }

  /// Stores a pending memorial ID for access after login
  Future<void> storePendingMemorial(String memorialId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingMemorialKey, memorialId);
      debugPrint('💾 Stored pending memorial: $memorialId');
    } catch (e) {
      debugPrint('❌ Error storing pending memorial: $e');
    }
  }

  /// Gets and clears the pending memorial ID
  Future<String?> consumePendingMemorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memorialId = prefs.getString(_pendingMemorialKey);

      if (memorialId != null) {
        await prefs.remove(_pendingMemorialKey);
        debugPrint('🎫 Consumed pending memorial: $memorialId');
      }

      return memorialId;
    } catch (e) {
      debugPrint('❌ Error consuming pending memorial: $e');
      return null;
    }
  }

  /// Checks if there's a pending memorial
  Future<bool> hasPendingMemorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_pendingMemorialKey);
    } catch (e) {
      return false;
    }
  }

  /// Grants access to a memorial for a user
  ///
  /// Creates a memorial_access entry in Firestore
  Future<bool> grantAccess({
    required String userId,
    required String memorialId,
  }) async {
    try {
      debugPrint(
          '🔓 Granting access to memorial: $memorialId for user: $userId');

      // Check if user is the owner
      final memorialDoc =
          await _firestore.collection('memorials').doc(memorialId).get();

      if (!memorialDoc.exists) {
        debugPrint('❌ Memorial not found');
        return false;
      }

      final ownerId = memorialDoc.data()?['ownerId'] as String?;

      if (ownerId == userId) {
        debugPrint('ℹ️ User is already the owner');
        return true;
      }

      // Check if user already has access
      final existingAccess = await _firestore
          .collection('memorial_access')
          .where('userId', isEqualTo: userId)
          .where('memorialId', isEqualTo: memorialId)
          .get();

      if (existingAccess.docs.isNotEmpty) {
        debugPrint('ℹ️ User already has access');
        return true;
      }

      // Create access entry
      final accessId = '${userId}_$memorialId';
      await _firestore.collection('memorial_access').doc(accessId).set({
        'id': accessId,
        'userId': userId,
        'memorialId': memorialId,
        'role': 'viewer',
        'joinedAt': FieldValue.serverTimestamp(),
        'invitedById': null, // QR code access, not invited
        'accessType': 'qr_code',
      });

      debugPrint('✅ Access granted via QR code');
      return true;
    } catch (e) {
      debugPrint('❌ Error granting access: $e');
      return false;
    }
  }

  /// Checks and grants access for pending memorial after login
  Future<GrantAccessResult?> checkAndGrantPendingAccess(String userId) async {
    try {
      final memorialId = await consumePendingMemorial();

      if (memorialId == null) {
        debugPrint('ℹ️ No pending memorial to grant access');
        return null;
      }

      debugPrint('🎫 Found pending memorial: $memorialId');

      // Validate the memorial still exists
      final validation = await validateMemorial(memorialId);

      if (!validation.exists) {
        return GrantAccessResult(
          success: false,
          message: 'Die Gedenkseite existiert nicht mehr.',
        );
      }

      // Grant access
      final granted = await grantAccess(
        userId: userId,
        memorialId: memorialId,
      );

      if (granted) {
        return GrantAccessResult(
          success: true,
          memorialId: memorialId,
          memorialName: validation.memorialName,
          message: 'Du hast jetzt Zugang zu "${validation.memorialName}".',
        );
      } else {
        return GrantAccessResult(
          success: false,
          message: 'Fehler beim Gewähren des Zugangs.',
        );
      }
    } catch (e) {
      debugPrint('❌ Error checking pending access: $e');
      return null;
    }
  }
}

/// Result of granting access
class GrantAccessResult {
  final bool success;
  final String? memorialId;
  final String? memorialName;
  final String message;

  GrantAccessResult({
    required this.success,
    this.memorialId,
    this.memorialName,
    required this.message,
  });
}

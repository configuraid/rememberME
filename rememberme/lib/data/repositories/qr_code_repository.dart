import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/qr_code_model.dart';

/// Ergebnis eines Claim-Versuchs
class ClaimResult {
  final bool success;
  final QrCodeModel? qrCode;
  final String? errorMessage;
  final ClaimErrorType? errorType;

  const ClaimResult._({
    required this.success,
    this.qrCode,
    this.errorMessage,
    this.errorType,
  });

  factory ClaimResult.success(QrCodeModel qrCode) {
    return ClaimResult._(success: true, qrCode: qrCode);
  }

  // ✅ GEÄNDERT: qrCode Parameter hinzugefügt
  factory ClaimResult.failure(String message, ClaimErrorType type,
      {QrCodeModel? qrCode}) {
    return ClaimResult._(
      success: false,
      errorMessage: message,
      errorType: type,
      qrCode: qrCode,
    );
  }
}

enum ClaimErrorType {
  notFound,
  alreadyClaimed,
  claimingInProgress,
  transactionFailed,
  unknown,
}

class QrCodeRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'qrCodes';

  QrCodeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ========================================
  // GET QR CODE STATUS
  // ========================================

  /// Holt den aktuellen Status eines QR-Codes
  Future<QrCodeModel?> getQrCode(String qrId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(qrId).get();

      if (!doc.exists) {
        debugPrint('❌ QR-Code nicht gefunden: $qrId');
        return null;
      }

      return QrCodeModel.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      debugPrint('❌ Fehler beim Laden des QR-Codes: $e');
      return null;
    }
  }

  /// Prüft ob ein QR-Code existiert und unclaimed ist
  Future<QrCodeCheckResult> checkQrCodeStatus(String qrId) async {
    try {
      final qrCode = await getQrCode(qrId);

      if (qrCode == null) {
        return QrCodeCheckResult(
          exists: false,
          canBeClaimed: false,
          message: 'QR-Code nicht gefunden',
        );
      }

      if (qrCode.isActive) {
        return QrCodeCheckResult(
          exists: true,
          canBeClaimed: false,
          qrCode: qrCode,
          message: 'QR-Code bereits aktiviert',
          memorialId: qrCode.memorialId,
        );
      }

      if (qrCode.isClaiming && !qrCode.isClaimingExpired) {
        return QrCodeCheckResult(
          exists: true,
          canBeClaimed: false,
          qrCode: qrCode,
          message: 'Aktivierung läuft bereits',
        );
      }

      return QrCodeCheckResult(
        exists: true,
        canBeClaimed: true,
        qrCode: qrCode,
        message: 'QR-Code kann aktiviert werden',
      );
    } catch (e) {
      debugPrint('❌ Fehler beim Prüfen: $e');
      return QrCodeCheckResult(
        exists: false,
        canBeClaimed: false,
        message: 'Fehler beim Prüfen des QR-Codes',
      );
    }
  }

  // ========================================
  // CLAIM QR CODE (ATOMARE TRANSAKTION!)
  // ========================================

  /// Claimed einen QR-Code für einen User
  ///
  /// ⚠️ KRITISCH: Verwendet Firestore Transaction für Atomarität!
  /// Verhindert Race Conditions wenn mehrere User gleichzeitig claimen.
  Future<ClaimResult> claimQrCode({
    required String qrId,
    required String userId,
  }) async {
    try {
      debugPrint('🔐 Starte Claim-Transaktion für QR: $qrId, User: $userId');

      final qrRef = _firestore.collection(_collection).doc(qrId);

      // ⚠️ ATOMARE TRANSAKTION - Das ist der kritische Teil!
      final result = await _firestore.runTransaction<ClaimResult>(
        (transaction) async {
          // 1. Aktuellen Status lesen (innerhalb der Transaktion!)
          final snapshot = await transaction.get(qrRef);

          if (!snapshot.exists) {
            debugPrint('❌ QR-Code existiert nicht');
            return ClaimResult.failure(
              'QR-Code nicht gefunden. Bitte prüfe den Code.',
              ClaimErrorType.notFound,
            );
          }

          final qrCode = QrCodeModel.fromJson({
            'id': snapshot.id,
            ...snapshot.data()!,
          });

          // 2. Prüfen ob Claiming möglich
          if (qrCode.isActive) {
            debugPrint('❌ QR-Code bereits aktiviert von: ${qrCode.ownerId}');
            // ✅ GEÄNDERT: qrCode wird jetzt mitgegeben!
            return ClaimResult.failure(
              'Dieser QR-Code wurde bereits aktiviert.',
              ClaimErrorType.alreadyClaimed,
              qrCode: qrCode,
            );
          }

          if (qrCode.isClaiming && !qrCode.isClaimingExpired) {
            // Prüfen ob der GLEICHE User bereits der Claimer ist
            if (qrCode.ownerId == userId) {
              debugPrint('✅ User ist bereits Owner, Claiming fortsetzen...');
              // Der gleiche User - das ist OK, weitermachen!
              return ClaimResult.success(qrCode);
            }

            debugPrint('❌ Claiming bereits in Bearbeitung von anderem User');
            // ✅ GEÄNDERT: qrCode wird jetzt mitgegeben!
            return ClaimResult.failure(
              'Die Aktivierung wird gerade von jemand anderem durchgeführt. '
              'Bitte versuche es in wenigen Minuten erneut.',
              ClaimErrorType.claimingInProgress,
              qrCode: qrCode,
            );
          }

          // 3. Status auf CLAIMING setzen (Lock!)
          final now = DateTime.now();
          transaction.update(qrRef, {
            'status': QrCodeStatus.claiming.name,
            'claimingStartedAt': Timestamp.fromDate(now),
            'ownerId': userId,
          });

          debugPrint('✅ Claiming-Lock gesetzt für User: $userId');

          return ClaimResult.success(qrCode.copyWith(
            status: QrCodeStatus.claiming,
            claimingStartedAt: now,
            ownerId: userId,
          ));
        },
        timeout: const Duration(seconds: 10),
      );

      return result;
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase Fehler beim Claiming: ${e.message}');
      return ClaimResult.failure(
        'Fehler bei der Aktivierung. Bitte erneut versuchen.',
        ClaimErrorType.transactionFailed,
      );
    } catch (e) {
      debugPrint('❌ Unbekannter Fehler beim Claiming: $e');
      return ClaimResult.failure(
        'Ein unerwarteter Fehler ist aufgetreten.',
        ClaimErrorType.unknown,
      );
    }
  }

  // ========================================
  // FINALIZE CLAIM (Nach Memorial-Erstellung)
  // ========================================

  /// Finalisiert das Claiming nachdem das Memorial erstellt wurde
  Future<bool> finalizeClaim({
    required String qrId,
    required String userId,
    required String memorialId,
  }) async {
    try {
      debugPrint('✅ Finalisiere Claim: QR=$qrId, Memorial=$memorialId');

      final qrRef = _firestore.collection(_collection).doc(qrId);

      // Atomare Prüfung ob der User noch der "Claimer" ist
      return await _firestore.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(qrRef);

        if (!snapshot.exists) return false;

        final data = snapshot.data()!;
        final currentOwnerId = data['ownerId'] as String?;
        final currentStatus = data['status'] as String?;

        // Sicherheitsprüfung: Nur der ursprüngliche Claimer darf finalisieren
        if (currentOwnerId != userId) {
          debugPrint('❌ User ist nicht mehr der Claimer');
          return false;
        }

        if (currentStatus != QrCodeStatus.claiming.name) {
          debugPrint('❌ Status ist nicht mehr CLAIMING');
          return false;
        }

        transaction.update(qrRef, {
          'status': QrCodeStatus.active.name,
          'memorialId': memorialId,
          'claimedAt': Timestamp.fromDate(DateTime.now()),
          'claimingStartedAt': FieldValue.delete(),
        });

        return true;
      });
    } catch (e) {
      debugPrint('❌ Fehler beim Finalisieren: $e');
      return false;
    }
  }

  // ========================================
  // ABORT CLAIM (Bei Fehler/Abbruch)
  // ========================================

  /// Bricht einen Claiming-Versuch ab und setzt Status zurück
  Future<void> abortClaim({
    required String qrId,
    required String userId,
  }) async {
    try {
      debugPrint('⚠️ Breche Claiming ab: $qrId');

      final qrRef = _firestore.collection(_collection).doc(qrId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(qrRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        final currentOwnerId = data['ownerId'] as String?;
        final currentStatus = data['status'] as String?;

        // Nur zurücksetzen wenn User noch der Claimer ist
        if (currentOwnerId == userId &&
            currentStatus == QrCodeStatus.claiming.name) {
          transaction.update(qrRef, {
            'status': QrCodeStatus.unclaimed.name,
            'ownerId': FieldValue.delete(),
            'claimingStartedAt': FieldValue.delete(),
          });
          debugPrint('✅ Claiming abgebrochen, Status zurückgesetzt');
        }
      });
    } catch (e) {
      debugPrint('❌ Fehler beim Abbrechen: $e');
    }
  }

  // ========================================
  // RELEASE QR CODE (Bei Memorial-Löschung)
  // ========================================

  /// Entfernt die Memorial-Verknüpfung wenn das Memorial gelöscht wird
  /// Der QR-Code bleibt beim User (ownerId bleibt erhalten)
  /// Status wird auf 'claiming' gesetzt, damit ein neues Memorial erstellt werden kann
  Future<bool> releaseQrCodeForMemorial(
      String memorialId, String userId) async {
    try {
      debugPrint('🔓 Suche QR-Code für Memorial: $memorialId');

      // QR-Code mit dieser memorialId suchen
      final query = await _firestore
          .collection(_collection)
          .where('memorialId', isEqualTo: memorialId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        debugPrint('ℹ️ Kein QR-Code für dieses Memorial gefunden');
        return true; // Kein Fehler, einfach kein QR-Code vorhanden
      }

      final qrDoc = query.docs.first;
      final data = qrDoc.data();
      final currentOwnerId = data['ownerId'] as String?;

      // Sicherheitsprüfung: Nur Owner darf QR-Code freigeben
      if (currentOwnerId != userId) {
        debugPrint(
            '❌ User $userId ist nicht Owner des QR-Codes (Owner: $currentOwnerId)');
        return false;
      }

      debugPrint(
          '🔓 QR-Code gefunden: ${qrDoc.id}, entferne Memorial-Verknüpfung...');

      // memorialId entfernen, ownerId bleibt!
      // Status auf 'claiming' setzen, damit neues Memorial erstellt werden kann
      // WICHTIG: ownerId muss explizit gesetzt werden für Firestore Rules!
      await qrDoc.reference.update({
        'status': QrCodeStatus.claiming.name,
        'memorialId': FieldValue.delete(),
        'claimedAt': FieldValue.delete(),
        'claimingStartedAt': Timestamp.fromDate(DateTime.now()),
        'ownerId': userId, // Muss explizit gesetzt werden für Security Rules!
      });

      debugPrint(
          '✅ QR-Code ${qrDoc.id}: Memorial-Verknüpfung entfernt, Owner bleibt erhalten');
      return true;
    } catch (e) {
      debugPrint('❌ Fehler beim Freigeben des QR-Codes: $e');
      return false;
    }
  }

  // ========================================
  // ADMIN: QR-Codes erstellen
  // ========================================

  /// Erstellt einen neuen unclaimed QR-Code (Admin/Produktion)
  Future<QrCodeModel?> createQrCode(String qrId) async {
    try {
      final qrCode = QrCodeModel.create(id: qrId);
      await _firestore.collection(_collection).doc(qrId).set(qrCode.toJson());
      debugPrint('✅ QR-Code erstellt: $qrId');
      return qrCode;
    } catch (e) {
      debugPrint('❌ Fehler beim Erstellen: $e');
      return null;
    }
  }

  /// Batch-Import von QR-Codes (für Produktion)
  Future<int> batchCreateQrCodes(List<String> qrIds) async {
    try {
      final batch = _firestore.batch();

      for (final qrId in qrIds) {
        final qrCode = QrCodeModel.create(id: qrId);
        final ref = _firestore.collection(_collection).doc(qrId);
        batch.set(ref, qrCode.toJson());
      }

      await batch.commit();
      debugPrint('✅ ${qrIds.length} QR-Codes importiert');
      return qrIds.length;
    } catch (e) {
      debugPrint('❌ Fehler beim Batch-Import: $e');
      return 0;
    }
  }
}

/// Ergebnis der QR-Code Status-Prüfung
class QrCodeCheckResult {
  final bool exists;
  final bool canBeClaimed;
  final QrCodeModel? qrCode;
  final String message;
  final String? memorialId; // Falls bereits aktiviert

  QrCodeCheckResult({
    required this.exists,
    required this.canBeClaimed,
    this.qrCode,
    required this.message,
    this.memorialId,
  });
}

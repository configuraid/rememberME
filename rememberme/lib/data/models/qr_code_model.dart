import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum QrCodeStatus {
  unclaimed, // Frisch aus der Box, noch nicht aktiviert
  claiming, // Gerade im Aktivierungsprozess (Race-Condition Schutz)
  active, // Aktiviert und mit Memorial verknüpft
  suspended, // Temporär deaktiviert
}

/// Repräsentiert den physischen QR-Code auf dem Produkt.
/// Ein QR-Code verweist auf ein Memorial nach Aktivierung.
class QrCodeModel extends Equatable {
  final String id; // Die ID im QR-Code (z.B. "xyz")
  final QrCodeStatus status;
  final String? ownerId; // User der den Code aktiviert hat
  final String? memorialId; // Verknüpftes Memorial (nach Aktivierung)
  final DateTime createdAt; // Wann wurde der QR-Code erstellt (Produktion)
  final DateTime? claimedAt; // Wann wurde er aktiviert
  final DateTime? claimingStartedAt; // Für Race-Condition Timeout

  const QrCodeModel({
    required this.id,
    required this.status,
    this.ownerId,
    this.memorialId,
    required this.createdAt,
    this.claimedAt,
    this.claimingStartedAt,
  });

  // ========================================
  // COMPUTED PROPERTIES
  // ========================================

  bool get isUnclaimed => status == QrCodeStatus.unclaimed;
  bool get isActive => status == QrCodeStatus.active;
  bool get isClaiming => status == QrCodeStatus.claiming;

  /// Prüft ob ein Claiming-Versuch abgelaufen ist (Timeout 5 Min)
  bool get isClaimingExpired {
    if (status != QrCodeStatus.claiming || claimingStartedAt == null) {
      return false;
    }
    return DateTime.now().difference(claimingStartedAt!).inMinutes > 5;
  }

  /// Kann dieser QR-Code geclaimed werden?
  bool get canBeClaimed => isUnclaimed || (isClaiming && isClaimingExpired);

  // ========================================
  // COPY WITH
  // ========================================

  QrCodeModel copyWith({
    String? id,
    QrCodeStatus? status,
    String? ownerId,
    String? memorialId,
    DateTime? createdAt,
    DateTime? claimedAt,
    DateTime? claimingStartedAt,
  }) {
    return QrCodeModel(
      id: id ?? this.id,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      memorialId: memorialId ?? this.memorialId,
      createdAt: createdAt ?? this.createdAt,
      claimedAt: claimedAt ?? this.claimedAt,
      claimingStartedAt: claimingStartedAt ?? this.claimingStartedAt,
    );
  }

  // ========================================
  // JSON SERIALIZATION
  // ========================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.name,
      'ownerId': ownerId,
      'memorialId': memorialId,
      'createdAt': Timestamp.fromDate(createdAt),
      'claimedAt': claimedAt != null ? Timestamp.fromDate(claimedAt!) : null,
      'claimingStartedAt': claimingStartedAt != null
          ? Timestamp.fromDate(claimingStartedAt!)
          : null,
    };
  }

  factory QrCodeModel.fromJson(Map<String, dynamic> json) {
    return QrCodeModel(
      id: json['id'] as String,
      status: QrCodeStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => QrCodeStatus.unclaimed,
      ),
      ownerId: json['ownerId'] as String?,
      memorialId: json['memorialId'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      claimedAt: json['claimedAt'] != null
          ? (json['claimedAt'] as Timestamp).toDate()
          : null,
      claimingStartedAt: json['claimingStartedAt'] != null
          ? (json['claimingStartedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Factory für neue QR-Codes (bei Produktion/Import)
  factory QrCodeModel.create({required String id}) {
    return QrCodeModel(
      id: id,
      status: QrCodeStatus.unclaimed,
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        status,
        ownerId,
        memorialId,
        createdAt,
        claimedAt,
        claimingStartedAt,
      ];
}

import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

enum InvitationStatus {
  pending, // Erstellt, noch nicht verwendet
  accepted, // Eingelöst
  expired, // Abgelaufen
  revoked, // Vom Owner widerrufen
}

/// Invitation Model
///
/// Ein Einladungslink hat einen einmaligen Token und läuft nach 7 Tagen ab.
/// URL: remembermemorial.app/invite/{token}
class InvitationModel extends Equatable {
  final String id;
  final String memorialId;
  final String invitedById; // Wer hat eingeladen?
  final String token; // Zufälliger Token für den Link
  final String? email; // Optional: E-Mail des Eingeladenen
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final String? usedByUserId; // Wer hat die Einladung eingelöst?

  const InvitationModel({
    required this.id,
    required this.memorialId,
    required this.invitedById,
    required this.token,
    this.email,
    this.status = InvitationStatus.pending,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
    this.usedByUserId,
  });

  // ========================================
  // COMPUTED PROPERTIES
  // ========================================

  /// Einladungslink URL
  String get inviteUrl => 'https://remembermemorial.app/invite/$token';

  /// Ist die Einladung noch gültig?
  bool get isValid {
    if (status != InvitationStatus.pending) return false;
    if (DateTime.now().isAfter(expiresAt)) return false;
    return true;
  }

  /// Ist abgelaufen?
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Wurde bereits verwendet?
  bool get isUsed => status == InvitationStatus.accepted;

  /// Wurde widerrufen?
  bool get isRevoked => status == InvitationStatus.revoked;

  /// Tage bis Ablauf
  int get daysUntilExpiry {
    final diff = expiresAt.difference(DateTime.now());
    return diff.inDays;
  }

  String get statusText {
    switch (status) {
      case InvitationStatus.pending:
        return isExpired ? 'Abgelaufen' : 'Ausstehend';
      case InvitationStatus.accepted:
        return 'Angenommen';
      case InvitationStatus.expired:
        return 'Abgelaufen';
      case InvitationStatus.revoked:
        return 'Widerrufen';
    }
  }

  // ========================================
  // COPY WITH
  // ========================================

  InvitationModel copyWith({
    String? id,
    String? memorialId,
    String? invitedById,
    String? token,
    String? email,
    InvitationStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? usedAt,
    String? usedByUserId,
  }) {
    return InvitationModel(
      id: id ?? this.id,
      memorialId: memorialId ?? this.memorialId,
      invitedById: invitedById ?? this.invitedById,
      token: token ?? this.token,
      email: email ?? this.email,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
      usedByUserId: usedByUserId ?? this.usedByUserId,
    );
  }

  // ========================================
  // JSON SERIALIZATION
  // ========================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memorialId': memorialId,
      'invitedById': invitedById,
      'token': token,
      'email': email,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'usedByUserId': usedByUserId,
    };
  }

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: json['id'] as String,
      memorialId: json['memorialId'] as String,
      invitedById: json['invitedById'] as String,
      token: json['token'] as String,
      email: json['email'] as String?,
      status: InvitationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InvitationStatus.pending,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      expiresAt: (json['expiresAt'] as Timestamp).toDate(),
      usedAt: json['usedAt'] != null
          ? (json['usedAt'] as Timestamp).toDate()
          : null,
      usedByUserId: json['usedByUserId'] as String?,
    );
  }

  /// Factory für neue Einladung (Standard: 7 Tage gültig)
  factory InvitationModel.create({
    required String id,
    required String memorialId,
    required String invitedById,
    String? email,
    int validDays = 7,
  }) {
    final now = DateTime.now();
    return InvitationModel(
      id: id,
      memorialId: memorialId,
      invitedById: invitedById,
      token: _generateToken(),
      email: email,
      status: InvitationStatus.pending,
      createdAt: now,
      expiresAt: now.add(Duration(days: validDays)),
    );
  }

  /// Generiert einen zufälligen Token
  static String _generateToken() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  List<Object?> get props => [
        id,
        memorialId,
        invitedById,
        token,
        email,
        status,
        createdAt,
        expiresAt,
        usedAt,
        usedByUserId,
      ];
}

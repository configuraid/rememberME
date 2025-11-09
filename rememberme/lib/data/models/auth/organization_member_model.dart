import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum MemberRole {
  owner, // Kann alles (Organisation löschen, Mitglieder verwalten)
  admin, // Kann Gedenkseiten erstellen & Mitglieder einladen
  editor, // Kann Gedenkseiten bearbeiten
  viewer, // Kann nur ansehen
}

enum MemberStatus {
  active,
  invited, // Einladung versendet, aber noch nicht akzeptiert
  suspended, // Temporär deaktiviert
}

class OrganizationMemberModel extends Equatable {
  final String id;
  final String organizationId;
  final String userId;
  final MemberRole role;
  final MemberStatus status;
  final DateTime joinedAt;
  final DateTime? invitedAt;
  final String? invitedBy; // User-ID des Einladenden
  final DateTime? lastActiveAt;
  final String? pin; // Optional: PIN für Profil-Schutz

  const OrganizationMemberModel({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.role,
    this.status = MemberStatus.active,
    required this.joinedAt,
    this.invitedAt,
    this.invitedBy,
    this.lastActiveAt,
    this.pin,
  });

  // Computed Properties
  bool get isActive => status == MemberStatus.active;
  bool get isOwner => role == MemberRole.owner;
  bool get isAdmin => role == MemberRole.admin || role == MemberRole.owner;
  bool get canEdit => role == MemberRole.editor || isAdmin;
  bool get hasPin => pin != null && pin!.isNotEmpty;

  String get roleText {
    switch (role) {
      case MemberRole.owner:
        return 'Eigentümer';
      case MemberRole.admin:
        return 'Administrator';
      case MemberRole.editor:
        return 'Bearbeiter';
      case MemberRole.viewer:
        return 'Betrachter';
    }
  }

  String get statusText {
    switch (status) {
      case MemberStatus.active:
        return 'Aktiv';
      case MemberStatus.invited:
        return 'Eingeladen';
      case MemberStatus.suspended:
        return 'Gesperrt';
    }
  }

  OrganizationMemberModel copyWith({
    String? id,
    String? organizationId,
    String? userId,
    MemberRole? role,
    MemberStatus? status,
    DateTime? joinedAt,
    DateTime? invitedAt,
    String? invitedBy,
    DateTime? lastActiveAt,
    String? pin,
  }) {
    return OrganizationMemberModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      invitedAt: invitedAt ?? this.invitedAt,
      invitedBy: invitedBy ?? this.invitedBy,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      pin: pin ?? this.pin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'userId': userId,
      'role': role.toString().split('.').last,
      'status': status.toString().split('.').last,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'invitedAt': invitedAt != null ? Timestamp.fromDate(invitedAt!) : null,
      'invitedBy': invitedBy,
      'lastActiveAt':
          lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
      'pin': pin,
    };
  }

  factory OrganizationMemberModel.fromJson(Map<String, dynamic> json) {
    return OrganizationMemberModel(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      userId: json['userId'] as String,
      role: MemberRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => MemberRole.viewer,
      ),
      status: MemberStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'active'),
        orElse: () => MemberStatus.active,
      ),
      joinedAt: (json['joinedAt'] as Timestamp).toDate(),
      invitedAt: json['invitedAt'] != null
          ? (json['invitedAt'] as Timestamp).toDate()
          : null,
      invitedBy: json['invitedBy'] as String?,
      lastActiveAt: json['lastActiveAt'] != null
          ? (json['lastActiveAt'] as Timestamp).toDate()
          : null,
      pin: json['pin'] as String?,
    );
  }

  factory OrganizationMemberModel.create({
    required String id,
    required String organizationId,
    required String userId,
    required MemberRole role,
    String? pin,
  }) {
    final now = DateTime.now();
    return OrganizationMemberModel(
      id: id,
      organizationId: organizationId,
      userId: userId,
      role: role,
      status: MemberStatus.active,
      joinedAt: now,
      lastActiveAt: now,
      pin: pin,
    );
  }

  @override
  List<Object?> get props => [
        id,
        organizationId,
        userId,
        role,
        status,
        joinedAt,
        invitedAt,
        invitedBy,
        lastActiveAt,
        pin,
      ];
}

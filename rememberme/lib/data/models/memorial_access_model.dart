import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Memorial Access Model
///
/// Trackt wer Zugang zu welchem Memorial hat.
/// Alle Members haben die GLEICHEN Rechte (Content bearbeiten, Leute einladen)
/// Nur der OWNER kann: Memorial löschen, Public/Private ändern
/// Owner wird über Memorial.ownerId bestimmt, NICHT hier
class MemorialAccessModel extends Equatable {
  final String id;
  final String userId;
  final String memorialId;
  final DateTime joinedAt;
  final String? invitedById; // Wer hat eingeladen? (null = Owner/Ersteller)

  const MemorialAccessModel({
    required this.id,
    required this.userId,
    required this.memorialId,
    required this.joinedAt,
    this.invitedById,
  });

  /// Wurde der User eingeladen (oder ist er der Ersteller)?
  bool get wasInvited => invitedById != null;

  MemorialAccessModel copyWith({
    String? id,
    String? userId,
    String? memorialId,
    DateTime? joinedAt,
    String? invitedById,
  }) {
    return MemorialAccessModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      memorialId: memorialId ?? this.memorialId,
      joinedAt: joinedAt ?? this.joinedAt,
      invitedById: invitedById ?? this.invitedById,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'memorialId': memorialId,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'invitedById': invitedById,
    };
  }

  factory MemorialAccessModel.fromJson(Map<String, dynamic> json) {
    return MemorialAccessModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      memorialId: json['memorialId'] as String,
      joinedAt: (json['joinedAt'] as Timestamp).toDate(),
      invitedById: json['invitedById'] as String?,
    );
  }

  /// Factory für Owner (erstellt Memorial)
  factory MemorialAccessModel.createForOwner({
    required String id,
    required String userId,
    required String memorialId,
  }) {
    return MemorialAccessModel(
      id: id,
      userId: userId,
      memorialId: memorialId,
      joinedAt: DateTime.now(),
      invitedById: null,
    );
  }

  /// Factory für eingeladenen User
  factory MemorialAccessModel.createForInvitee({
    required String id,
    required String userId,
    required String memorialId,
    required String invitedById,
  }) {
    return MemorialAccessModel(
      id: id,
      userId: userId,
      memorialId: memorialId,
      joinedAt: DateTime.now(),
      invitedById: invitedById,
    );
  }

  @override
  List<Object?> get props => [id, userId, memorialId, joinedAt, invitedById];
}

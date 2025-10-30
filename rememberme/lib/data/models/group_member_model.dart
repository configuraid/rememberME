import 'package:equatable/equatable.dart';
import 'user_model.dart';

class GroupMemberModel extends Equatable {
  final String id;
  final String memorialId;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userProfileImageUrl;
  final UserRole role;
  final DateTime invitedAt;
  final DateTime? joinedAt;
  final bool isActive;
  final String? invitationCode;

  const GroupMemberModel({
    required this.id,
    required this.memorialId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userProfileImageUrl,
    required this.role,
    required this.invitedAt,
    this.joinedAt,
    this.isActive = true,
    this.invitationCode,
  });

  // Getter für Rollen-Name in Deutsch
  String get roleDisplayName {
    switch (role) {
      case UserRole.owner:
        return 'Besitzer';
      case UserRole.coAdmin:
        return 'Co-Administrator';
      case UserRole.editor:
        return 'Bearbeiter';
      case UserRole.viewer:
        return 'Betrachter';
    }
  }

  // Getter für Berechtigungen
  bool get canEdit {
    return role == UserRole.owner ||
        role == UserRole.coAdmin ||
        role == UserRole.editor;
  }

  bool get canDelete {
    return role == UserRole.owner || role == UserRole.coAdmin;
  }

  bool get canInviteMembers {
    return role == UserRole.owner || role == UserRole.coAdmin;
  }

  bool get canManagePermissions {
    return role == UserRole.owner;
  }

  // Prüfen ob Einladung noch ausstehend
  bool get isPending => joinedAt == null;

  // Factory zum Erstellen eines Members
  factory GroupMemberModel.create({
    required String id,
    required String memorialId,
    required String userId,
    required String userName,
    required String userEmail,
    String? userProfileImageUrl,
    required UserRole role,
    String? invitationCode,
  }) {
    return GroupMemberModel(
      id: id,
      memorialId: memorialId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userProfileImageUrl: userProfileImageUrl,
      role: role,
      invitedAt: DateTime.now(),
      invitationCode: invitationCode,
    );
  }

  // CopyWith Methode
  GroupMemberModel copyWith({
    String? id,
    String? memorialId,
    String? userId,
    String? userName,
    String? userEmail,
    String? userProfileImageUrl,
    UserRole? role,
    DateTime? invitedAt,
    DateTime? joinedAt,
    bool? isActive,
    String? invitationCode,
  }) {
    return GroupMemberModel(
      id: id ?? this.id,
      memorialId: memorialId ?? this.memorialId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      role: role ?? this.role,
      invitedAt: invitedAt ?? this.invitedAt,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
      invitationCode: invitationCode ?? this.invitationCode,
    );
  }

  // ToJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memorialId': memorialId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userProfileImageUrl': userProfileImageUrl,
      'role': role.toString().split('.').last,
      'invitedAt': invitedAt.toIso8601String(),
      'joinedAt': joinedAt?.toIso8601String(),
      'isActive': isActive,
      'invitationCode': invitationCode,
    };
  }

  // FromJson
  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: json['id'] as String,
      memorialId: json['memorialId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userEmail: json['userEmail'] as String,
      userProfileImageUrl: json['userProfileImageUrl'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.viewer,
      ),
      invitedAt: DateTime.parse(json['invitedAt'] as String),
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      invitationCode: json['invitationCode'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        memorialId,
        userId,
        userName,
        userEmail,
        userProfileImageUrl,
        role,
        invitedAt,
        joinedAt,
        isActive,
        invitationCode,
      ];
}

import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { owner, coAdmin, editor, viewer }

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final String?
      authKey; // Deprecated - wird durch primaryOrganizationId ersetzt
  final String? primaryOrganizationId; // ✅ NEU: Haupt-Organisation des Users
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final UserRole role;
  final String? firebaseUid;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.authKey,
    this.primaryOrganizationId,
    required this.createdAt,
    this.lastLoginAt,
    this.role = UserRole.owner,
    this.firebaseUid,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    String? authKey,
    String? primaryOrganizationId,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserRole? role,
    String? firebaseUid,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      authKey: authKey ?? this.authKey,
      primaryOrganizationId:
          primaryOrganizationId ?? this.primaryOrganizationId,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      role: role ?? this.role,
      firebaseUid: firebaseUid ?? this.firebaseUid,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'authKey': authKey, // Deprecated
      'primaryOrganizationId': primaryOrganizationId,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'role': role.toString().split('.').last,
      'firebaseUid': firebaseUid,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      authKey: json['authKey'] as String?,
      primaryOrganizationId: json['primaryOrganizationId'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastLoginAt: json['lastLoginAt'] != null
          ? (json['lastLoginAt'] as Timestamp).toDate()
          : null,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.viewer,
      ),
      firebaseUid: json['firebaseUid'] as String?,
    );
  }

  factory UserModel.empty() {
    return UserModel(
      id: '',
      name: '',
      email: '',
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        profileImageUrl,
        authKey,
        primaryOrganizationId,
        createdAt,
        lastLoginAt,
        role,
        firebaseUid,
      ];
}

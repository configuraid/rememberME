import 'package:equatable/equatable.dart';

enum UserRole { owner, coAdmin, editor, viewer }

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final String authKey;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final UserRole role;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.authKey,
    required this.createdAt,
    this.lastLoginAt,
    this.role = UserRole.owner,
  });

  // CopyWith Methode
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    String? authKey,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserRole? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      authKey: authKey ?? this.authKey,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      role: role ?? this.role,
    );
  }

  // ToJson (später für Firebase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'authKey': authKey,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'role': role.toString().split('.').last,
    };
  }

  // FromJson (später für Firebase)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      authKey: json['authKey'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.viewer,
      ),
    );
  }

  // Leere User Factory
  factory UserModel.empty() {
    return UserModel(
      id: '',
      name: '',
      email: '',
      authKey: '',
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
        createdAt,
        lastLoginAt,
        role,
      ];
}

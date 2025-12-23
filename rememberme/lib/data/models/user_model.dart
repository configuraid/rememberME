import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// User Model (Vereinfacht)
///
/// Ein User registriert sich mit Email/Password.
/// Er kann mehrere Memorials besitzen oder Zugang zu mehreren haben.
/// Keine Organization mehr nötig!
class UserModel extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? firebaseUid;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.firebaseUid,
  });

  // ========================================
  // COMPUTED PROPERTIES
  // ========================================

  /// Erster Buchstabe für Avatar-Fallback
  String get initials {
    if (displayName.isEmpty) return '?';
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName[0].toUpperCase();
  }

  /// Hat ein Profilbild?
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  // ========================================
  // COPY WITH
  // ========================================

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? firebaseUid,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      firebaseUid: firebaseUid ?? this.firebaseUid,
    );
  }

  // ========================================
  // JSON SERIALIZATION
  // ========================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'firebaseUid': firebaseUid,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastLoginAt: json['lastLoginAt'] != null
          ? (json['lastLoginAt'] as Timestamp).toDate()
          : null,
      firebaseUid: json['firebaseUid'] as String?,
    );
  }

  /// Factory für neuen User bei Registrierung
  factory UserModel.create({
    required String id,
    required String email,
    required String displayName,
    required String firebaseUid,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      firebaseUid: firebaseUid,
    );
  }

  /// Leerer User (für Initial State)
  factory UserModel.empty() {
    return UserModel(
      id: '',
      email: '',
      displayName: '',
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        avatarUrl,
        createdAt,
        lastLoginAt,
        firebaseUid,
      ];
}

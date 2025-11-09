import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationModel extends Equatable {
  final String id;
  final String name;
  final String authKey;
  final String ownerId;
  final List<String> memorialIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? settings;
  final bool isActive;

  const OrganizationModel({
    required this.id,
    required this.name,
    required this.authKey,
    required this.ownerId,
    this.memorialIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.settings,
    this.isActive = true,
  });

  int get memberCount => memorialIds.length;
  bool get hasMemorials => memorialIds.isNotEmpty;

  OrganizationModel copyWith({
    String? id,
    String? name,
    String? authKey,
    String? ownerId,
    List<String>? memorialIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? settings,
    bool? isActive,
  }) {
    return OrganizationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      authKey: authKey ?? this.authKey,
      ownerId: ownerId ?? this.ownerId,
      memorialIds: memorialIds ?? this.memorialIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      settings: settings ?? this.settings,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'authKey': authKey,
      'ownerId': ownerId,
      'memorialIds': memorialIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'settings': settings,
      'isActive': isActive,
    };
  }

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      authKey: json['authKey'] as String,
      ownerId: json['ownerId'] as String? ?? '',
      memorialIds: (json['memorialIds'] as List?)?.cast<String>() ?? [],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      settings: json['settings'] as Map<String, dynamic>?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  factory OrganizationModel.create({
    required String id,
    required String name,
    required String authKey,
    required String ownerId,
  }) {
    final now = DateTime.now();
    return OrganizationModel(
      id: id,
      name: name,
      authKey: authKey,
      ownerId: ownerId,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        authKey,
        ownerId,
        memorialIds,
        createdAt,
        updatedAt,
        settings,
        isActive,
      ];
}

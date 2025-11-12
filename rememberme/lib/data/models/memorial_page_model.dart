import 'package:equatable/equatable.dart';
import 'content_block_model.dart';

enum PrivacyLevel {
  public,
  familyOnly,
  private,
}

class MemorialPageModel extends Equatable {
  final String id;
  final String organizationId;
  final String ownerId;
  final String name;
  final String? subtitle;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String templateId;
  final PrivacyLevel privacyLevel;
  final List<ContentBlock> contentBlocks;
  final List<String>? groupMemberIds;
  final DateTime createdAt;

  const MemorialPageModel({
    required this.id,
    required this.organizationId,
    required this.ownerId,
    required this.name,
    this.subtitle,
    this.birthDate,
    this.deathDate,
    required this.templateId,
    this.privacyLevel = PrivacyLevel.private,
    this.contentBlocks = const [],
    this.groupMemberIds,
    required this.createdAt,
  });

  // Computed Properties
  String get lifespan {
    if (birthDate == null && deathDate == null) {
      return 'Keine Daten';
    }

    final birth = birthDate != null ? _formatDate(birthDate!) : '?';
    final death = deathDate != null ? _formatDate(deathDate!) : '?';

    return '$birth - $death';
  }

  List<ContentBlock> get sortedContentBlocks {
    final sorted = List<ContentBlock>.from(contentBlocks);
    return sorted;
  }

  int get publishedBlocksCount {
    return contentBlocks.length;
  }

  bool get hasContent {
    return contentBlocks.isNotEmpty;
  }

  String get privacyLevelText {
    switch (privacyLevel) {
      case PrivacyLevel.public:
        return 'Öffentlich';
      case PrivacyLevel.familyOnly:
        return 'Nur Familie';
      case PrivacyLevel.private:
        return 'Privat';
    }
  }

  // Group Management
  bool get hasGroupMembers {
    return groupMemberIds != null && groupMemberIds!.isNotEmpty;
  }

  int get groupMemberCount {
    return groupMemberIds?.length ?? 0;
  }

  bool isGroupMember(String userId) {
    return groupMemberIds?.contains(userId) ?? false;
  }

  bool canEdit(String userId) {
    return ownerId == userId;
  }

  // Content Block Helpers
  ContentBlock? getBlockById(String blockId) {
    try {
      return contentBlocks.firstWhere((block) => block.id == blockId);
    } catch (_) {
      return null;
    }
  }

  List<ContentBlock> getBlocksByType(ContentBlockType type) {
    return contentBlocks.where((block) => block.type == type).toList();
  }

  bool hasBlockType(ContentBlockType type) {
    return contentBlocks.any((block) => block.type == type);
  }

  MemorialPageModel copyWith({
    String? id,
    String? organizationId,
    String? ownerId,
    String? name,
    String? subtitle,
    DateTime? birthDate,
    DateTime? deathDate,
    String? templateId,
    PrivacyLevel? privacyLevel,
    List<ContentBlock>? contentBlocks,
    List<String>? collaboratorIds,
    List<String>? groupMemberIds,
    DateTime? createdAt,
  }) {
    return MemorialPageModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      birthDate: birthDate ?? this.birthDate,
      deathDate: deathDate ?? this.deathDate,
      templateId: templateId ?? this.templateId,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      contentBlocks: contentBlocks ?? this.contentBlocks,
      groupMemberIds: groupMemberIds ?? this.groupMemberIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MemorialPageModel.fromJson(Map<String, dynamic> json) {
    return MemorialPageModel(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      ownerId: json['ownerId'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String?,
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      deathDate: json['deathDate'] != null
          ? DateTime.parse(json['deathDate'] as String)
          : null,
      templateId: json['templateId'] as String? ?? 'default',
      privacyLevel: _parsePrivacyLevel(json['privacyLevel'] as String?),
      contentBlocks: (json['contentBlocks'] as List?)
              ?.map((e) => ContentBlock.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      groupMemberIds: (json['groupMemberIds'] as List?)?.cast<String>(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'ownerId': ownerId,
      'name': name,
      'subtitle': subtitle,
      'birthDate': birthDate?.toIso8601String(),
      'deathDate': deathDate?.toIso8601String(),
      'templateId': templateId,
      'privacyLevel': privacyLevel.toString().split('.').last,
      'contentBlocks': contentBlocks.map((block) => block.toJson()).toList(),
      'groupMemberIds': groupMemberIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static PrivacyLevel _parsePrivacyLevel(String? privacyString) {
    if (privacyString == null) return PrivacyLevel.private;
    try {
      return PrivacyLevel.values.firstWhere(
        (e) => e.toString().split('.').last == privacyString,
      );
    } catch (_) {
      return PrivacyLevel.private;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  List<Object?> get props => [
        id,
        organizationId,
        ownerId,
        name,
        subtitle,
        birthDate,
        deathDate,
        templateId,
        privacyLevel,
        contentBlocks,
        groupMemberIds,
        createdAt,
      ];
}

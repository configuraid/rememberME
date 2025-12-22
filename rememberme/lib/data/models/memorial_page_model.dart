import 'package:equatable/equatable.dart';
import 'content_block_model.dart';

enum MemorialStatus {
  draft,
  published,
  archived,
}

class MemorialPageModel extends Equatable {
  final String id;
  final String organizationId;
  final String ownerId;
  final String name;
  final String? subtitle;
  final String? profileImageUrl;
  final String? biography;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String templateId;
  final bool isPublic;
  final MemorialStatus status;
  final List<ContentBlock> contentBlocks;
  final List<String>? groupMemberIds;
  final DateTime createdAt;

  const MemorialPageModel({
    required this.id,
    required this.organizationId,
    required this.ownerId,
    required this.name,
    this.subtitle,
    this.profileImageUrl,
    this.biography,
    this.birthDate,
    this.deathDate,
    required this.templateId,
    this.isPublic = false,
    this.status = MemorialStatus.draft,
    this.contentBlocks = const [],
    this.groupMemberIds,
    required this.createdAt,
  });

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

  bool get hasProfileImage {
    return profileImageUrl != null && profileImageUrl!.isNotEmpty;
  }

  bool get hasBiography {
    return biography != null && biography!.isNotEmpty;
  }

  String get visibilityText {
    return isPublic ? 'Öffentlich' : 'Privat';
  }

  String get statusText {
    switch (status) {
      case MemorialStatus.draft:
        return 'Entwurf';
      case MemorialStatus.published:
        return 'Veröffentlicht';
      case MemorialStatus.archived:
        return 'Archiviert';
    }
  }

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
    String? profileImageUrl,
    String? biography,
    DateTime? birthDate,
    DateTime? deathDate,
    String? templateId,
    bool? isPublic,
    MemorialStatus? status,
    List<ContentBlock>? contentBlocks,
    List<String>? groupMemberIds,
    DateTime? createdAt,
  }) {
    return MemorialPageModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      biography: biography ?? this.biography,
      birthDate: birthDate ?? this.birthDate,
      deathDate: deathDate ?? this.deathDate,
      templateId: templateId ?? this.templateId,
      isPublic: isPublic ?? this.isPublic,
      status: status ?? this.status,
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
      profileImageUrl: json['profileImageUrl'] as String?,
      biography: json['biography'] as String?,
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      deathDate: json['deathDate'] != null
          ? DateTime.parse(json['deathDate'] as String)
          : null,
      templateId: json['templateId'] as String? ?? 'default',
      isPublic: json['isPublic'] as bool? ?? false,
      status: _parseStatus(json['status'] as String?),
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
      'profileImageUrl': profileImageUrl,
      'biography': biography,
      'birthDate': birthDate?.toIso8601String(),
      'deathDate': deathDate?.toIso8601String(),
      'templateId': templateId,
      'isPublic': isPublic,
      'status': status.toString().split('.').last,
      'contentBlocks': contentBlocks.map((block) => block.toJson()).toList(),
      'groupMemberIds': groupMemberIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static MemorialStatus _parseStatus(String? statusString) {
    if (statusString == null) return MemorialStatus.draft;
    try {
      return MemorialStatus.values.firstWhere(
        (e) => e.toString().split('.').last == statusString,
      );
    } catch (_) {
      return MemorialStatus.draft;
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
        profileImageUrl,
        biography,
        birthDate,
        deathDate,
        templateId,
        isPublic,
        status,
        contentBlocks,
        groupMemberIds,
        createdAt,
      ];
}

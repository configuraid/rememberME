import 'package:equatable/equatable.dart';
import 'content_block_model.dart';

enum MemorialStatus {
  draft,
  published,
  archived,
}

enum PrivacyLevel {
  public,
  familyOnly,
  private,
}

class MemorialPageModel extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String? subtitle;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? profileImageUrl;
  final String templateId;
  final bool isPublished;
  final MemorialStatus status;
  final PrivacyLevel privacyLevel;
  final List<ContentBlockModel> contentBlocks;
  final int viewCount;
  final List<String> collaboratorIds;
  final List<String>? groupMemberIds;
  final Map<String, dynamic>? settings;
  final String? vercelUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  const MemorialPageModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.subtitle,
    this.birthDate,
    this.deathDate,
    this.profileImageUrl,
    required this.templateId,
    this.isPublished = false,
    this.status = MemorialStatus.draft,
    this.privacyLevel = PrivacyLevel.private,
    this.contentBlocks = const [],
    this.viewCount = 0,
    this.collaboratorIds = const [],
    this.groupMemberIds,
    this.settings,
    this.vercelUrl,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
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

  List<ContentBlockModel> get sortedContentBlocks {
    final sorted = List<ContentBlockModel>.from(contentBlocks);
    sorted.sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }

  int get publishedBlocksCount {
    return contentBlocks.length;
  }

  bool get hasContent {
    return contentBlocks.isNotEmpty;
  }

  String get statusText {
    switch (status) {
      case MemorialStatus.published:
        return 'Veröffentlicht';
      case MemorialStatus.draft:
        return 'Entwurf';
      case MemorialStatus.archived:
        return 'Archiviert';
    }
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

  bool get hasCollaborators {
    return collaboratorIds.isNotEmpty;
  }

  int get collaboratorCount {
    return collaboratorIds.length;
  }

  bool isGroupMember(String userId) {
    return groupMemberIds?.contains(userId) ?? false;
  }

  bool isCollaborator(String userId) {
    return collaboratorIds.contains(userId);
  }

  bool canEdit(String userId) {
    return ownerId == userId || isCollaborator(userId);
  }

  // Content Block Helpers
  ContentBlockModel? getBlockById(String blockId) {
    try {
      return contentBlocks.firstWhere((block) => block.id == blockId);
    } catch (_) {
      return null;
    }
  }

  List<ContentBlockModel> getBlocksByType(ContentBlockType type) {
    return contentBlocks.where((block) => block.type == type).toList();
  }

  bool hasBlockType(ContentBlockType type) {
    return contentBlocks.any((block) => block.type == type);
  }

  // Settings Helpers
  bool getSetting(String key, {bool defaultValue = false}) {
    return settings?[key] as bool? ?? defaultValue;
  }

  String? getSettingString(String key) {
    return settings?[key] as String?;
  }

  MemorialPageModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? subtitle,
    DateTime? birthDate,
    DateTime? deathDate,
    String? profileImageUrl,
    String? templateId,
    bool? isPublished,
    MemorialStatus? status,
    PrivacyLevel? privacyLevel,
    List<ContentBlockModel>? contentBlocks,
    int? viewCount,
    List<String>? collaboratorIds,
    List<String>? groupMemberIds,
    Map<String, dynamic>? settings,
    String? vercelUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return MemorialPageModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      birthDate: birthDate ?? this.birthDate,
      deathDate: deathDate ?? this.deathDate,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      templateId: templateId ?? this.templateId,
      isPublished: isPublished ?? this.isPublished,
      status: status ?? this.status,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      contentBlocks: contentBlocks ?? this.contentBlocks,
      viewCount: viewCount ?? this.viewCount,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
      groupMemberIds: groupMemberIds ?? this.groupMemberIds,
      settings: settings ?? this.settings,
      vercelUrl: vercelUrl ?? this.vercelUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  factory MemorialPageModel.fromJson(Map<String, dynamic> json) {
    return MemorialPageModel(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String?,
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      deathDate: json['deathDate'] != null
          ? DateTime.parse(json['deathDate'] as String)
          : null,
      profileImageUrl: json['profileImageUrl'] as String?,
      templateId: json['templateId'] as String? ?? 'default',
      isPublished: json['isPublished'] as bool? ?? false,
      status: _parseStatus(json['status'] as String?),
      privacyLevel: _parsePrivacyLevel(json['privacyLevel'] as String?),
      contentBlocks: (json['contentBlocks'] as List?)
              ?.map(
                  (e) => ContentBlockModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      viewCount: json['viewCount'] as int? ?? 0,
      collaboratorIds: (json['collaboratorIds'] as List?)?.cast<String>() ?? [],
      groupMemberIds: (json['groupMemberIds'] as List?)?.cast<String>(),
      settings: json['settings'] as Map<String, dynamic>?,
      vercelUrl: json['vercelUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'subtitle': subtitle,
      'birthDate': birthDate?.toIso8601String(),
      'deathDate': deathDate?.toIso8601String(),
      'profileImageUrl': profileImageUrl,
      'templateId': templateId,
      'isPublished': isPublished,
      'status': status.toString().split('.').last,
      'privacyLevel': privacyLevel.toString().split('.').last,
      'contentBlocks': contentBlocks.map((block) => block.toJson()).toList(),
      'viewCount': viewCount,
      'collaboratorIds': collaboratorIds,
      'groupMemberIds': groupMemberIds,
      'settings': settings,
      'vercelUrl': vercelUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'publishedAt': publishedAt?.toIso8601String(),
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
        ownerId,
        name,
        subtitle,
        birthDate,
        deathDate,
        profileImageUrl,
        templateId,
        isPublished,
        status,
        privacyLevel,
        contentBlocks,
        viewCount,
        collaboratorIds,
        groupMemberIds,
        settings,
        vercelUrl,
        createdAt,
        updatedAt,
        publishedAt,
      ];
}

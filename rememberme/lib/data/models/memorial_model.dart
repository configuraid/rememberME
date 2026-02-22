import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'content_block_model.dart';

enum MemorialStatus {
  draft, // Entwurf
  published, // Veröffentlicht
  archived, // Archiviert
}

class MemorialModel extends Equatable {
  final String id;
  final String ownerId;

  final String name;
  final DateTime? birthDate;
  final DateTime? deathDate;

  final String? subtitle;
  final String? biography;
  final String? profileImageUrl;
  final String? coverImageUrl;

  // Content Blocks
  final List<ContentBlock> contentBlocks;
  final String templateId;

  // Settings
  final bool isPublic;
  final MemorialStatus status;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const MemorialModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.birthDate,
    this.deathDate,
    this.subtitle,
    this.biography,
    this.profileImageUrl,
    this.coverImageUrl,
    this.contentBlocks = const [],
    this.templateId = 'default',
    this.isPublic = false,
    this.status = MemorialStatus.draft,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Lebensspanne formatiert
  String get lifespan {
    if (birthDate == null && deathDate == null) {
      return 'Keine Daten';
    }
    final birth = birthDate != null ? _formatDate(birthDate!) : '?';
    final death = deathDate != null ? _formatDate(deathDate!) : '?';
    return '$birth – $death';
  }

  /// Nur Basis-Infos (für Public View bei Private Memorials)
  Map<String, dynamic> get publicInfo => {
        'id': id,
        'name': name,
        'birthDate': birthDate,
        'deathDate': deathDate,
        'lifespan': lifespan,
      };

  /// Hat Profilbild?
  bool get hasProfileImage =>
      profileImageUrl != null && profileImageUrl!.isNotEmpty;

  /// Hat Biografie?
  bool get hasBiography => biography != null && biography!.isNotEmpty;

  /// Hat Content?
  bool get hasContent => contentBlocks.isNotEmpty;

  /// Anzahl Content Blocks
  int get contentBlockCount => contentBlocks.length;

  /// Ist der User der Owner?
  bool isOwner(String oderId) => ownerId == oderId;

  String get visibilityText => isPublic ? 'Öffentlich' : 'Privat';

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

  // ========================================
  // CONTENT BLOCK HELPERS
  // ========================================

  /// ContentBlock nach ID finden
  ContentBlock? getBlockById(String blockId) {
    try {
      return contentBlocks.firstWhere((block) => block.id == blockId);
    } catch (_) {
      return null;
    }
  }

  /// ContentBlocks nach Typ filtern
  List<ContentBlock> getBlocksByType(ContentBlockType type) {
    return contentBlocks.where((block) => block.type == type).toList();
  }

  /// Prüfen ob ein bestimmter Block-Typ existiert
  bool hasBlockType(ContentBlockType type) {
    return contentBlocks.any((block) => block.type == type);
  }

  MemorialModel addContentBlock(ContentBlock block) {
    return copyWith(
      contentBlocks: [...contentBlocks, block],
      updatedAt: DateTime.now(),
    );
  }

  /// ContentBlock aktualisieren
  MemorialModel updateContentBlock(ContentBlock updatedBlock) {
    final index = contentBlocks.indexWhere((b) => b.id == updatedBlock.id);
    if (index == -1) return this;

    final newBlocks = List<ContentBlock>.from(contentBlocks);
    newBlocks[index] = updatedBlock;

    return copyWith(
      contentBlocks: newBlocks,
      updatedAt: DateTime.now(),
    );
  }

  /// ContentBlock entfernen
  MemorialModel removeContentBlock(String blockId) {
    return copyWith(
      contentBlocks: contentBlocks.where((b) => b.id != blockId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// ContentBlocks neu ordnen
  MemorialModel reorderContentBlocks(int oldIndex, int newIndex) {
    final newBlocks = List<ContentBlock>.from(contentBlocks);
    final block = newBlocks.removeAt(oldIndex);
    newBlocks.insert(newIndex, block);

    return copyWith(
      contentBlocks: newBlocks,
      updatedAt: DateTime.now(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // ========================================
  // COPY WITH
  // ========================================

  MemorialModel copyWith({
    String? id,
    String? qrCodeId,
    String? ownerId,
    String? name,
    DateTime? birthDate,
    DateTime? deathDate,
    String? subtitle,
    String? biography,
    String? profileImageUrl,
    String? coverImageUrl,
    List<ContentBlock>? contentBlocks,
    String? templateId,
    bool? isPublic,
    MemorialStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemorialModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      deathDate: deathDate ?? this.deathDate,
      subtitle: subtitle ?? this.subtitle,
      biography: biography ?? this.biography,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      contentBlocks: contentBlocks ?? this.contentBlocks,
      templateId: templateId ?? this.templateId,
      isPublic: isPublic ?? this.isPublic,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ========================================
  // JSON SERIALIZATION
  // ========================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'birthDate': birthDate?.toIso8601String(),
      'deathDate': deathDate?.toIso8601String(),
      'subtitle': subtitle,
      'biography': biography,
      'profileImageUrl': profileImageUrl,
      'coverImageUrl': coverImageUrl,
      'contentBlocks': contentBlocks.map((block) => block.toJson()).toList(),
      'templateId': templateId,
      'isPublic': isPublic,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory MemorialModel.fromJson(Map<String, dynamic> json) {
    return MemorialModel(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      name: json['name'] as String,
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      deathDate: json['deathDate'] != null
          ? DateTime.parse(json['deathDate'] as String)
          : null,
      subtitle: json['subtitle'] as String?,
      biography: json['biography'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      contentBlocks: (json['contentBlocks'] as List?)
              ?.map((e) => ContentBlock.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      templateId: json['templateId'] as String? ?? 'default',
      isPublic: json['isPublic'] as bool? ?? false,
      status: MemorialStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MemorialStatus.draft,
      ),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Factory für neues Memorial
  factory MemorialModel.create({
    required String id,
    required String qrCodeId,
    required String ownerId,
    required String name,
    DateTime? birthDate,
    DateTime? deathDate,
    bool isPublic = false,
    String templateId = 'default',
  }) {
    final now = DateTime.now();
    return MemorialModel(
      id: id,
      ownerId: ownerId,
      name: name,
      birthDate: birthDate,
      deathDate: deathDate,
      isPublic: isPublic,
      templateId: templateId,
      status: MemorialStatus.draft,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        name,
        birthDate,
        deathDate,
        subtitle,
        biography,
        profileImageUrl,
        coverImageUrl,
        contentBlocks,
        templateId,
        isPublic,
        status,
        createdAt,
        updatedAt,
      ];
}

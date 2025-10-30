import 'package:equatable/equatable.dart';
import 'content_block_model.dart';

enum MemorialStatus { draft, published, archived }

enum PrivacyLevel { public, private, familyOnly }

class MemorialPageModel extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String? subtitle;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? profileImageUrl;
  final MemorialStatus status;
  final PrivacyLevel privacyLevel;
  final String? password; // For password-protected pages
  final List<ContentBlockModel> contentBlocks;
  final String templateId;
  final Map<String, dynamic> themeSettings;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;
  final String? customDomain;
  final String? vercelUrl;
  final int viewCount;
  final List<String> collaboratorIds;

  const MemorialPageModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.subtitle,
    this.birthDate,
    this.deathDate,
    this.profileImageUrl,
    this.status = MemorialStatus.draft,
    this.privacyLevel = PrivacyLevel.public,
    this.password,
    this.contentBlocks = const [],
    required this.templateId,
    this.themeSettings = const {},
    required this.createdAt,
    this.updatedAt,
    this.publishedAt,
    this.customDomain,
    this.vercelUrl,
    this.viewCount = 0,
    this.collaboratorIds = const [],
  });

  // Getter für die Lebensspanne
  String get lifespan {
    if (birthDate == null) return '';
    final birth = '${birthDate!.day}.${birthDate!.month}.${birthDate!.year}';
    if (deathDate == null) return birth;
    final death = '${deathDate!.day}.${deathDate!.month}.${deathDate!.year}';
    return '$birth - $death';
  }

  // Getter für das Alter
  int? get ageAtDeath {
    if (birthDate == null || deathDate == null) return null;
    return deathDate!.year - birthDate!.year;
  }

  // Prüfen ob veröffentlicht
  bool get isPublished => status == MemorialStatus.published;

  // Prüfen ob privat
  bool get isPrivate => privacyLevel == PrivacyLevel.private;

  // Prüfen ob passwortgeschützt
  bool get isPasswordProtected => password != null && password!.isNotEmpty;

  // Sortierte Content-Blöcke nach Order
  List<ContentBlockModel> get sortedContentBlocks {
    final blocks = List<ContentBlockModel>.from(contentBlocks);
    blocks.sort((a, b) => a.order.compareTo(b.order));
    return blocks;
  }

  // Factory für neue Gedenkseite
  factory MemorialPageModel.create({
    required String id,
    required String ownerId,
    required String name,
    required String templateId,
  }) {
    return MemorialPageModel(
      id: id,
      ownerId: ownerId,
      name: name,
      templateId: templateId,
      createdAt: DateTime.now(),
      contentBlocks: const [],
    );
  }

  // CopyWith Methode
  MemorialPageModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? subtitle,
    DateTime? birthDate,
    DateTime? deathDate,
    String? profileImageUrl,
    MemorialStatus? status,
    PrivacyLevel? privacyLevel,
    String? password,
    List<ContentBlockModel>? contentBlocks,
    String? templateId,
    Map<String, dynamic>? themeSettings,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    String? customDomain,
    String? vercelUrl,
    int? viewCount,
    List<String>? collaboratorIds,
  }) {
    return MemorialPageModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      birthDate: birthDate ?? this.birthDate,
      deathDate: deathDate ?? this.deathDate,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      status: status ?? this.status,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      password: password ?? this.password,
      contentBlocks: contentBlocks ?? this.contentBlocks,
      templateId: templateId ?? this.templateId,
      themeSettings: themeSettings ?? this.themeSettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      customDomain: customDomain ?? this.customDomain,
      vercelUrl: vercelUrl ?? this.vercelUrl,
      viewCount: viewCount ?? this.viewCount,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
    );
  }

  // ToJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'subtitle': subtitle,
      'birthDate': birthDate?.toIso8601String(),
      'deathDate': deathDate?.toIso8601String(),
      'profileImageUrl': profileImageUrl,
      'status': status.toString().split('.').last,
      'privacyLevel': privacyLevel.toString().split('.').last,
      'password': password,
      'contentBlocks': contentBlocks.map((block) => block.toJson()).toList(),
      'templateId': templateId,
      'themeSettings': themeSettings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'publishedAt': publishedAt?.toIso8601String(),
      'customDomain': customDomain,
      'vercelUrl': vercelUrl,
      'viewCount': viewCount,
      'collaboratorIds': collaboratorIds,
    };
  }

  // FromJson
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
      status: MemorialStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MemorialStatus.draft,
      ),
      privacyLevel: PrivacyLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['privacyLevel'],
        orElse: () => PrivacyLevel.public,
      ),
      password: json['password'] as String?,
      contentBlocks: (json['contentBlocks'] as List?)
              ?.map((block) =>
                  ContentBlockModel.fromJson(block as Map<String, dynamic>))
              .toList() ??
          [],
      templateId: json['templateId'] as String,
      themeSettings: json['themeSettings'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : null,
      customDomain: json['customDomain'] as String?,
      vercelUrl: json['vercelUrl'] as String?,
      viewCount: json['viewCount'] as int? ?? 0,
      collaboratorIds:
          List<String>.from(json['collaboratorIds'] as List? ?? []),
    );
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
        status,
        privacyLevel,
        password,
        contentBlocks,
        templateId,
        themeSettings,
        createdAt,
        updatedAt,
        publishedAt,
        customDomain,
        vercelUrl,
        viewCount,
        collaboratorIds,
      ];
}

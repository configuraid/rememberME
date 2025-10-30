import 'package:equatable/equatable.dart';

enum ContentBlockType {
  heroSection,
  textBlock,
  imageGallery,
  quoteSection,
  videoCollage,
  audioPlayer,
  timeline,
  guestbook,
  memoryMap,
  photoGallery3D,
}

class ContentBlockModel extends Equatable {
  final String id;
  final ContentBlockType type;
  final int order;
  final Map<String, dynamic> data;
  final bool isVisible;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ContentBlockModel({
    required this.id,
    required this.type,
    required this.order,
    required this.data,
    this.isVisible = true,
    required this.createdAt,
    this.updatedAt,
  });

  // Factory für Hero Section
  factory ContentBlockModel.heroSection({
    required String id,
    required String name,
    required String subtitle,
    String? imageUrl,
    DateTime? birthDate,
    DateTime? deathDate,
  }) {
    return ContentBlockModel(
      id: id,
      type: ContentBlockType.heroSection,
      order: 0,
      data: {
        'name': name,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'birthDate': birthDate?.toIso8601String(),
        'deathDate': deathDate?.toIso8601String(),
      },
      createdAt: DateTime.now(),
    );
  }

  // Factory für Text Block
  factory ContentBlockModel.textBlock({
    required String id,
    required int order,
    required String title,
    required String content,
  }) {
    return ContentBlockModel(
      id: id,
      type: ContentBlockType.textBlock,
      order: order,
      data: {
        'title': title,
        'content': content,
      },
      createdAt: DateTime.now(),
    );
  }

  // Factory für Image Gallery
  factory ContentBlockModel.imageGallery({
    required String id,
    required int order,
    required List<String> imageUrls,
    String? title,
  }) {
    return ContentBlockModel(
      id: id,
      type: ContentBlockType.imageGallery,
      order: order,
      data: {
        'title': title,
        'imageUrls': imageUrls,
      },
      createdAt: DateTime.now(),
    );
  }

  // Factory für Quote Section
  factory ContentBlockModel.quoteSection({
    required String id,
    required int order,
    required String quote,
    String? author,
  }) {
    return ContentBlockModel(
      id: id,
      type: ContentBlockType.quoteSection,
      order: order,
      data: {
        'quote': quote,
        'author': author,
      },
      createdAt: DateTime.now(),
    );
  }

  // Factory für Timeline
  factory ContentBlockModel.timeline({
    required String id,
    required int order,
    required List<Map<String, dynamic>> events,
  }) {
    return ContentBlockModel(
      id: id,
      type: ContentBlockType.timeline,
      order: order,
      data: {
        'events': events,
      },
      createdAt: DateTime.now(),
    );
  }

  // Factory für Video Collage (Lifetime only)
  factory ContentBlockModel.videoCollage({
    required String id,
    required int order,
    required List<String> videoUrls,
    String? backgroundMusic,
  }) {
    return ContentBlockModel(
      id: id,
      type: ContentBlockType.videoCollage,
      order: order,
      data: {
        'videoUrls': videoUrls,
        'backgroundMusic': backgroundMusic,
      },
      createdAt: DateTime.now(),
    );
  }

  // Factory für Audio Player (Lifetime only)
  factory ContentBlockModel.audioPlayer({
    required String id,
    required int order,
    required List<Map<String, dynamic>> audioFiles,
  }) {
    return ContentBlockModel(
      id: id,
      type: ContentBlockType.audioPlayer,
      order: order,
      data: {
        'audioFiles': audioFiles,
      },
      createdAt: DateTime.now(),
    );
  }

  // Hilfsmethode zum Prüfen ob Block für Basis-Lizenz verfügbar ist
  bool get isAvailableForBasicLicense {
    return type == ContentBlockType.heroSection ||
        type == ContentBlockType.textBlock ||
        type == ContentBlockType.imageGallery ||
        type == ContentBlockType.quoteSection;
  }

  // CopyWith Methode
  ContentBlockModel copyWith({
    String? id,
    ContentBlockType? type,
    int? order,
    Map<String, dynamic>? data,
    bool? isVisible,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContentBlockModel(
      id: id ?? this.id,
      type: type ?? this.type,
      order: order ?? this.order,
      data: data ?? this.data,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ToJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'order': order,
      'data': data,
      'isVisible': isVisible,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // FromJson
  factory ContentBlockModel.fromJson(Map<String, dynamic> json) {
    return ContentBlockModel(
      id: json['id'] as String,
      type: ContentBlockType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      order: json['order'] as int,
      data: Map<String, dynamic>.from(json['data'] as Map),
      isVisible: json['isVisible'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        order,
        data,
        isVisible,
        createdAt,
        updatedAt,
      ];
}

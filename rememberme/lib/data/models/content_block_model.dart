import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

enum ContentBlockType {
  header, // Überschrift
  text, // Text/Absatz
  image, // Einzelbild
  gallery, // Bildergalerie
  quote, // Zitat
  video, // Video
  audio, // Audio/Sprachmemo
  imageText, // Bild mit Text
  timeline, // Timeline/Lebenslauf
}

/// Simplified content block for memorial pages
class ContentBlock {
  final String id;
  final ContentBlockType type;
  final Map<String, dynamic> content;

  ContentBlock({
    String? id,
    required this.type,
    Map<String, dynamic>? content,
  })  : id = id ?? const Uuid().v4(),
        content = content ?? _getDefaultContent(type);

  static Map<String, dynamic> _getDefaultContent(ContentBlockType type) {
    switch (type) {
      case ContentBlockType.header:
        return {
          'text': '',
          'level': 1, // h1, h2, h3
          'align': 'center',
          'color': '#000000',
        };
      case ContentBlockType.text:
        return {
          'text': '',
          'align': 'left',
          'fontSize': 16.0,
          'color': '#333333',
        };
      case ContentBlockType.image:
        return {
          'url': '',
          'caption': '',
          'fit': 'cover',
        };
      case ContentBlockType.gallery:
        return {
          'images': <String>[], // List of URLs
          'columns': 3,
          'displayMode': 'grid', // 'grid' oder 'slider'
        };
      case ContentBlockType.quote:
        return {
          'text': '',
          'author': '',
          'color': '#666666',
        };
      case ContentBlockType.video:
        return {
          'url': '',
          'caption': '',
          'autoplay': false,
          'thumbnailUrl': '',
        };
      case ContentBlockType.audio:
        return {
          'url': '',
          'title': '',
          'duration': 0,
          'waveformData': <double>[], // Waveform-Daten für Visualisierung
        };
      case ContentBlockType.imageText:
        return {
          'imageUrl': '',
          'title': '',
          'text': '',
          'layout': 'left',
          'imageSize': 0.4,
          'imageCaption': '',
          'color': '#333333',
        };
      case ContentBlockType.timeline:
        return {
          'entries': <Map<String, dynamic>>[],
        };
    }
  }

  /// Erstellt eine Timeline mit automatischen Einträgen aus Memorial-Daten
  static ContentBlock createTimelineWithDates({
    String? birthDate,
    String? deathDate,
  }) {
    final entries = <Map<String, dynamic>>[];

    if (birthDate != null && birthDate.isNotEmpty) {
      entries.add({
        'id': const Uuid().v4(),
        'date': birthDate,
        'label': 'Geboren',
        'imageUrl': '',
        'text': '',
      });
    }

    if (deathDate != null && deathDate.isNotEmpty) {
      entries.add({
        'id': const Uuid().v4(),
        'date': deathDate,
        'label': '✝',
        'imageUrl': '',
        'text': '',
      });
    }

    return ContentBlock(
      type: ContentBlockType.timeline,
      content: {
        'entries': entries,
      },
    );
  }

  ContentBlock copyWith({
    ContentBlockType? type,
    Map<String, dynamic>? content,
    DateTime? updatedAt,
  }) {
    return ContentBlock(
      id: id,
      type: type ?? this.type,
      content: content ?? this.content,
    );
  }

  ContentBlock updateContent(String key, dynamic value) {
    return copyWith(
      content: {...content, key: value},
      updatedAt: DateTime.now(),
    );
  }

  T getContent<T>(String key, T defaultValue) {
    return content[key] as T? ?? defaultValue;
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'type': type.name,
      'content': content,
    };

    print('📦 ContentBlock.toJson(): $json');

    return json;
  }

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    print('📥 ContentBlock.fromJson(): $json');

    return ContentBlock(
      id: json['id'] as String,
      type: ContentBlockType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () {
          print('⚠️ Unbekannter ContentBlockType: ${json['type']}');
          return ContentBlockType.text;
        },
      ),
      content: Map<String, dynamic>.from(json['content'] as Map),
    );
  }
}

/// Helper to get display info for block types
class BlockTypeInfo {
  static String getTitle(ContentBlockType type) {
    switch (type) {
      case ContentBlockType.header:
        return 'Überschrift';
      case ContentBlockType.text:
        return 'Geschichte';
      case ContentBlockType.image:
        return 'Foto';
      case ContentBlockType.gallery:
        return 'Galerie';
      case ContentBlockType.quote:
        return 'Zitat';
      case ContentBlockType.video:
        return 'Video';
      case ContentBlockType.audio:
        return 'Stimme';
      case ContentBlockType.imageText:
        return 'Foto & Text';
      case ContentBlockType.timeline:
        return 'Lebensweg';
    }
  }

  /// Get platform-specific icon for block type
  static IconData getIcon(ContentBlockType type) {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      switch (type) {
        case ContentBlockType.header:
          return CupertinoIcons.textformat_size;
        case ContentBlockType.text:
          return CupertinoIcons.textformat;
        case ContentBlockType.image:
          return CupertinoIcons.photo;
        case ContentBlockType.gallery:
          return CupertinoIcons.photo_on_rectangle;
        case ContentBlockType.quote:
          return CupertinoIcons.quote_bubble;
        case ContentBlockType.video:
          return CupertinoIcons.videocam;
        case ContentBlockType.audio:
          return CupertinoIcons.mic_fill;
        case ContentBlockType.imageText:
          return CupertinoIcons.text_badge_plus;
        case ContentBlockType.timeline:
          return CupertinoIcons.time;
      }
    } else {
      switch (type) {
        case ContentBlockType.header:
          return Icons.title_rounded;
        case ContentBlockType.text:
          return Icons.text_fields_rounded;
        case ContentBlockType.image:
          return Icons.image_outlined;
        case ContentBlockType.gallery:
          return Icons.photo_library_outlined;
        case ContentBlockType.quote:
          return Icons.format_quote_rounded;
        case ContentBlockType.video:
          return Icons.videocam_outlined;
        case ContentBlockType.audio:
          return Icons.mic_rounded;
        case ContentBlockType.imageText:
          return Icons.article_rounded;
        case ContentBlockType.timeline:
          return Icons.timeline_rounded;
      }
    }
  }

  static String getDescription(ContentBlockType type) {
    switch (type) {
      case ContentBlockType.header:
        return 'Setze einen Akzent';
      case ContentBlockType.text:
        return 'Erzähle von ihr/ihm';
      case ContentBlockType.image:
        return 'Ein besonderer Moment';
      case ContentBlockType.gallery:
        return 'Geteilte Erinnerungen';
      case ContentBlockType.quote:
        return 'Worte, die bleiben';
      case ContentBlockType.video:
        return 'Bewegende Momente';
      case ContentBlockType.audio:
        return 'Lass sie/ihn sprechen';
      case ContentBlockType.imageText:
        return 'Bild & Geschichte';
      case ContentBlockType.timeline:
        return 'Die wichtigen Stationen';
    }
  }
}

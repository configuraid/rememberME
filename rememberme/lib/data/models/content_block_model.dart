import 'package:uuid/uuid.dart';

/// Simple content block types for memorial pages
enum ContentBlockType {
  header, // Überschrift
  text, // Text/Absatz
  image, // Einzelbild
  gallery, // Bildergalerie
  quote, // Zitat
  divider, // Trennlinie
  video, // Video
  date, // Lebensdaten (Geboren - Gestorben)
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
          'text': 'Überschrift eingeben',
          'level': 1, // h1, h2, h3
          'align': 'center',
          'color': '#000000',
        };
      case ContentBlockType.text:
        return {
          'text': 'Text eingeben...',
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
        };
      case ContentBlockType.quote:
        return {
          'text': 'Zitat eingeben...',
          'author': '',
          'color': '#666666',
        };
      case ContentBlockType.divider:
        return {
          'color': '#E0E0E0',
          'thickness': 1.0,
          'margin': 20.0,
        };
      case ContentBlockType.video:
        return {
          'url': '',
          'caption': '',
        };
      case ContentBlockType.date:
        return {
          'birthDate': '',
          'deathDate': '',
          'format': 'DD.MM.YYYY',
        };
    }
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
        return 'Text';
      case ContentBlockType.image:
        return 'Bild';
      case ContentBlockType.gallery:
        return 'Bildergalerie';
      case ContentBlockType.quote:
        return 'Zitat';
      case ContentBlockType.divider:
        return 'Trennlinie';
      case ContentBlockType.video:
        return 'Video';
      case ContentBlockType.date:
        return 'Lebensdaten';
    }
  }

  static String getIcon(ContentBlockType type) {
    switch (type) {
      case ContentBlockType.header:
        return '📝';
      case ContentBlockType.text:
        return '📄';
      case ContentBlockType.image:
        return '🖼️';
      case ContentBlockType.gallery:
        return '📷';
      case ContentBlockType.quote:
        return '💬';
      case ContentBlockType.divider:
        return '━';
      case ContentBlockType.video:
        return '🎬';
      case ContentBlockType.date:
        return '📅';
    }
  }

  static String getDescription(ContentBlockType type) {
    switch (type) {
      case ContentBlockType.header:
        return 'Große Überschrift';
      case ContentBlockType.text:
        return 'Textabsatz';
      case ContentBlockType.image:
        return 'Einzelnes Bild';
      case ContentBlockType.gallery:
        return 'Mehrere Bilder';
      case ContentBlockType.quote:
        return 'Bedeutsames Zitat';
      case ContentBlockType.divider:
        return 'Visueller Trenner';
      case ContentBlockType.video:
        return 'Video einbetten';
      case ContentBlockType.date:
        return 'Geburts- und Sterbedatum';
    }
  }
}

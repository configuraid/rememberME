import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // WICHTIG: Für Flutter's Color class

enum ContentBlockType {
  hero,
  text,
  gallery,
  quote,
  timeline,
  video,
  audio,
  map,
  condolences,
}

class ContentBlockModel extends Equatable {
  final String id;
  final ContentBlockType type;
  final int order;
  final Map<String, dynamic> data;
  final Map<String, dynamic> styles;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContentBlockModel({
    required this.id,
    required this.type,
    required this.order,
    this.data = const {},
    this.styles = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Helper Getters für spezifische Block-Typen

  // Hero Block
  String? get heroImageUrl => data['imageUrl'] as String?;
  String? get heroTitle => data['title'] as String?;
  String? get heroSubtitle => data['subtitle'] as String?;

  // Text Block
  String? get textContent => data['content'] as String?;
  String? get textHeading => data['heading'] as String?;

  // Gallery Block
  List<String> get galleryImages =>
      (data['images'] as List?)?.cast<String>() ?? [];

  // Quote Block
  String? get quoteText => data['quote'] as String?;
  String? get quoteAuthor => data['author'] as String?;
  String? get quoteContext => data['context'] as String?;

  // Timeline Block
  List<Map<String, dynamic>> get timelineEvents =>
      (data['events'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  // Style Helpers
  String get layoutStyle => styles['layout'] as String? ?? 'default';
  String get themeStyle => styles['theme'] as String? ?? 'default';

  Color? get primaryColor {
    final colorHex = styles['primaryColor'] as String?;
    return colorHex != null ? _hexToColor(colorHex) : null;
  }

  ContentBlockModel copyWith({
    String? id,
    ContentBlockType? type,
    int? order,
    Map<String, dynamic>? data,
    Map<String, dynamic>? styles,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContentBlockModel(
      id: id ?? this.id,
      type: type ?? this.type,
      order: order ?? this.order,
      data: data ?? this.data,
      styles: styles ?? this.styles,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ContentBlockModel.fromJson(Map<String, dynamic> json) {
    return ContentBlockModel(
      id: json['id'] as String,
      type: _parseBlockType(json['type'] as String?),
      order: json['order'] as int? ?? 0,
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      styles: Map<String, dynamic>.from(json['styles'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'order': order,
      'data': data,
      'styles': styles,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static ContentBlockType _parseBlockType(String? typeString) {
    if (typeString == null) return ContentBlockType.text;

    try {
      return ContentBlockType.values.firstWhere(
        (e) => e.toString().split('.').last == typeString,
      );
    } catch (_) {
      return ContentBlockType.text;
    }
  }

  // Helper Methode zum Konvertieren von Hex zu Color
  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  @override
  List<Object?> get props => [
        id,
        type,
        order,
        data,
        styles,
        createdAt,
        updatedAt,
      ];
}

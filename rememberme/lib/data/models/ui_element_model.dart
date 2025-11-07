// lib/data/models/ui_element_model.dart

import 'package:uuid/uuid.dart';

/// Flexible UI Element Types - can be combined and nested
enum UIElementType {
  // Containers
  container,
  column,
  row,
  stack,

  // Content
  text,
  image,
  icon,

  // Interactive
  button,

  // Layout
  spacer,
  divider,
}

/// Base class for all UI elements with flexible property system
class UIElement {
  final String id;
  final UIElementType type;
  final Map<String, dynamic> properties;
  final List<UIElement> children;
  final DateTime createdAt;
  final DateTime updatedAt;

  UIElement({
    String? id,
    required this.type,
    Map<String, dynamic>? properties,
    List<UIElement>? children,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        properties = properties ?? {},
        children = children ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Check if this element can have children
  bool get canHaveChildren {
    return type == UIElementType.container ||
        type == UIElementType.column ||
        type == UIElementType.row ||
        type == UIElementType.stack ||
        type == UIElementType.button;
  }

  /// Get property with default value
  T getProperty<T>(String key, T defaultValue) {
    return properties[key] as T? ?? defaultValue;
  }

  /// Update a single property
  UIElement updateProperty(String key, dynamic value) {
    return copyWith(
      properties: {...properties, key: value},
      updatedAt: DateTime.now(),
    );
  }

  /// Add a child element
  UIElement addChild(UIElement child) {
    if (!canHaveChildren) {
      throw Exception('Element of type $type cannot have children');
    }
    return copyWith(
      children: [...children, child],
      updatedAt: DateTime.now(),
    );
  }

  /// Remove a child by ID
  UIElement removeChild(String childId) {
    return copyWith(
      children: children.where((c) => c.id != childId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Update a child recursively
  UIElement updateChild(String childId, UIElement updatedChild) {
    return copyWith(
      children: children.map((child) {
        if (child.id == childId) {
          return updatedChild;
        } else if (child.canHaveChildren) {
          return child.updateChild(childId, updatedChild);
        }
        return child;
      }).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Find an element by ID recursively
  UIElement? findById(String elementId) {
    if (id == elementId) return this;

    for (final child in children) {
      final found = child.findById(elementId);
      if (found != null) return found;
    }

    return null;
  }

  UIElement copyWith({
    UIElementType? type,
    Map<String, dynamic>? properties,
    List<UIElement>? children,
    DateTime? updatedAt,
  }) {
    return UIElement(
      id: id,
      type: type ?? this.type,
      properties: properties ?? this.properties,
      children: children ?? this.children,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'properties': properties,
      'children': children.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UIElement.fromJson(Map<String, dynamic> json) {
    return UIElement(
      id: json['id'],
      type: UIElementType.values.firstWhere((e) => e.name == json['type']),
      properties: Map<String, dynamic>.from(json['properties']),
      children:
          (json['children'] as List).map((c) => UIElement.fromJson(c)).toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

/// Factory methods for creating common elements with default properties
class UIElementFactory {
  static UIElement createContainer({
    Map<String, dynamic>? customProperties,
  }) {
    return UIElement(
      type: UIElementType.container,
      properties: {
        'padding': 16.0,
        'margin': 0.0,
        'backgroundColor': '#FFFFFF',
        'borderRadius': 0.0,
        'borderWidth': 0.0,
        'borderColor': '#000000',
        'width': null,
        'height': null,
        'alignment': 'topLeft',
        ...?customProperties,
      },
    );
  }

  static UIElement createColumn({
    Map<String, dynamic>? customProperties,
  }) {
    return UIElement(
      type: UIElementType.column,
      properties: {
        'mainAxisAlignment': 'start',
        'crossAxisAlignment': 'center',
        'mainAxisSize': 'max',
        'spacing': 0.0,
        'padding': 0.0,
        ...?customProperties,
      },
    );
  }

  static UIElement createRow({
    Map<String, dynamic>? customProperties,
  }) {
    return UIElement(
      type: UIElementType.row,
      properties: {
        'mainAxisAlignment': 'start',
        'crossAxisAlignment': 'center',
        'mainAxisSize': 'max',
        'spacing': 0.0,
        'padding': 0.0,
        ...?customProperties,
      },
    );
  }

  static UIElement createText({
    String text = 'Text eingeben',
    Map<String, dynamic>? customProperties,
  }) {
    return UIElement(
      type: UIElementType.text,
      properties: {
        'text': text,
        'fontSize': 16.0,
        'fontWeight': 'normal',
        'fontFamily': 'default',
        'color': '#000000',
        'textAlign': 'left',
        'maxLines': null,
        'letterSpacing': 0.0,
        'lineHeight': 1.5,
        ...?customProperties,
      },
    );
  }

  static UIElement createImage({
    String? url,
    Map<String, dynamic>? customProperties,
  }) {
    return UIElement(
      type: UIElementType.image,
      properties: {
        'url': url ?? '',
        'width': 200.0,
        'height': 200.0,
        'fit': 'cover',
        'borderRadius': 0.0,
        'alignment': 'center',
        ...?customProperties,
      },
    );
  }

  static UIElement createIcon({
    Map<String, dynamic>? customProperties,
  }) {
    return UIElement(
      type: UIElementType.icon,
      properties: {
        'iconCode': 0xe047, // Icons.favorite
        'size': 24.0,
        'color': '#000000',
        ...?customProperties,
      },
    );
  }

  static UIElement createButton({
    String text = 'Button',
    Map<String, dynamic>? customProperties,
  }) {
    return UIElement(
      type: UIElementType.button,
      properties: {
        'text': text,
        'fontSize': 16.0,
        'fontWeight': 'bold',
        'textColor': '#FFFFFF',
        'backgroundColor': '#2196F3',
        'padding': 16.0,
        'borderRadius': 8.0,
        'elevation': 2.0,
        'width': null,
        'height': null,
        ...?customProperties,
      },
    );
  }

  static UIElement createSpacer({
    double height = 16.0,
  }) {
    return UIElement(
      type: UIElementType.spacer,
      properties: {
        'height': height,
        'width': null,
      },
    );
  }

  static UIElement createDivider({
    Map<String, dynamic>? customProperties,
  }) {
    return UIElement(
      type: UIElementType.divider,
      properties: {
        'height': 1.0,
        'color': '#E0E0E0',
        'indent': 0.0,
        'endIndent': 0.0,
        ...?customProperties,
      },
    );
  }
}

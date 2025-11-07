// lib/data/models/element_properties.dart

/// Property types for dynamic UI generation
enum PropertyType {
  text,
  number,
  color,
  dropdown,
  boolean,
  spacing,
  alignment,
  fontWeight,
  borderRadius,
}

/// Base class for element properties
abstract class ElementProperty {
  final String key;
  final String label;
  final PropertyType type;
  final dynamic defaultValue;
  final String? description;
  final String? category;

  const ElementProperty({
    required this.key,
    required this.label,
    required this.type,
    required this.defaultValue,
    this.description,
    this.category,
  });

  /// Validate if a value is valid for this property
  bool isValid(dynamic value);
}

/// Text property
class TextProperty extends ElementProperty {
  final int? maxLength;
  final int? minLength;
  final int maxLines;
  final String? placeholder;

  const TextProperty({
    required super.key,
    required super.label,
    required super.defaultValue,
    super.description,
    super.category,
    this.maxLength,
    this.minLength,
    this.maxLines = 1,
    this.placeholder,
  }) : super(type: PropertyType.text);

  @override
  bool isValid(dynamic value) {
    if (value is! String) return false;
    if (minLength != null && value.length < minLength!) return false;
    if (maxLength != null && value.length > maxLength!) return false;
    return true;
  }
}

/// Number property (double or int)
class NumberProperty extends ElementProperty {
  final double min;
  final double max;
  final int decimals;
  final bool nullable;
  final String? unit;

  const NumberProperty({
    required super.key,
    required super.label,
    required super.defaultValue,
    super.description,
    super.category,
    this.min = 0,
    this.max = 1000,
    this.decimals = 0,
    this.nullable = false,
    this.unit,
  }) : super(type: PropertyType.number);

  @override
  bool isValid(dynamic value) {
    if (value == null) return nullable;
    if (value is! num) return false;
    if (value < min || value > max) return false;
    return true;
  }
}

/// Color property (renamed to avoid conflict with Flutter's ColorProperty)
class ElementColorProperty extends ElementProperty {
  final bool allowAlpha;
  final List<String>? presetColors;

  const ElementColorProperty({
    required super.key,
    required super.label,
    required super.defaultValue,
    super.description,
    super.category,
    this.allowAlpha = true,
    this.presetColors,
  }) : super(type: PropertyType.color);

  @override
  bool isValid(dynamic value) {
    if (value is! String) return false;
    // Check if valid hex color
    final hexPattern = RegExp(r'^#?([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$');
    return hexPattern.hasMatch(value);
  }
}

/// Dropdown property
class DropdownProperty extends ElementProperty {
  final Map<String, String> options;

  const DropdownProperty({
    required super.key,
    required super.label,
    required super.defaultValue,
    required this.options,
    super.description,
    super.category,
  }) : super(type: PropertyType.dropdown);

  @override
  bool isValid(dynamic value) {
    if (value is! String) return false;
    return options.containsKey(value);
  }
}

/// Boolean property
class BooleanProperty extends ElementProperty {
  const BooleanProperty({
    required super.key,
    required super.label,
    required super.defaultValue,
    super.description,
    super.category,
  }) : super(type: PropertyType.boolean);

  @override
  bool isValid(dynamic value) {
    return value is bool;
  }
}

/// Spacing property (for padding, margin etc.)
class SpacingProperty extends ElementProperty {
  final double min;
  final double max;
  final bool allowIndividual; // top, right, bottom, left

  const SpacingProperty({
    required super.key,
    required super.label,
    required super.defaultValue,
    super.description,
    super.category,
    this.min = 0,
    this.max = 200,
    this.allowIndividual = false,
  }) : super(type: PropertyType.spacing);

  @override
  bool isValid(dynamic value) {
    if (value is num) {
      return value >= min && value <= max;
    }
    if (allowIndividual && value is Map) {
      // Check if all values are valid
      return ['top', 'right', 'bottom', 'left'].every((key) {
        final v = value[key];
        return v is num && v >= min && v <= max;
      });
    }
    return false;
  }
}

/// Property definitions for each element type
class ElementPropertyDefinitions {
  // Container Properties
  static List<ElementProperty> get containerProperties => [
        const NumberProperty(
          key: 'padding',
          label: 'Padding',
          defaultValue: 16.0,
          min: 0,
          max: 100,
          category: 'Layout',
          unit: 'px',
        ),
        const NumberProperty(
          key: 'margin',
          label: 'Margin',
          defaultValue: 0.0,
          min: 0,
          max: 100,
          category: 'Layout',
          unit: 'px',
        ),
        const NumberProperty(
          key: 'width',
          label: 'Width',
          defaultValue: null,
          min: 0,
          max: 2000,
          nullable: true,
          category: 'Layout',
          unit: 'px',
        ),
        const NumberProperty(
          key: 'height',
          label: 'Height',
          defaultValue: null,
          min: 0,
          max: 2000,
          nullable: true,
          category: 'Layout',
          unit: 'px',
        ),
        const ElementColorProperty(
          key: 'backgroundColor',
          label: 'Background Color',
          defaultValue: '#FFFFFF',
          category: 'Styling',
        ),
        const NumberProperty(
          key: 'borderRadius',
          label: 'Border Radius',
          defaultValue: 0.0,
          min: 0,
          max: 50,
          category: 'Styling',
          unit: 'px',
        ),
        const NumberProperty(
          key: 'borderWidth',
          label: 'Border Width',
          defaultValue: 0.0,
          min: 0,
          max: 10,
          category: 'Styling',
          unit: 'px',
        ),
        const ElementColorProperty(
          key: 'borderColor',
          label: 'Border Color',
          defaultValue: '#000000',
          category: 'Styling',
        ),
        const DropdownProperty(
          key: 'alignment',
          label: 'Alignment',
          defaultValue: 'topLeft',
          options: {
            'topLeft': 'Top Left',
            'topCenter': 'Top Center',
            'topRight': 'Top Right',
            'centerLeft': 'Center Left',
            'center': 'Center',
            'centerRight': 'Center Right',
            'bottomLeft': 'Bottom Left',
            'bottomCenter': 'Bottom Center',
            'bottomRight': 'Bottom Right',
          },
          category: 'Layout',
        ),
      ];

  // Column/Row Properties
  static List<ElementProperty> get layoutProperties => [
        const DropdownProperty(
          key: 'mainAxisAlignment',
          label: 'Main Axis Alignment',
          defaultValue: 'start',
          options: {
            'start': 'Start',
            'center': 'Center',
            'end': 'End',
            'spaceBetween': 'Space Between',
            'spaceAround': 'Space Around',
            'spaceEvenly': 'Space Evenly',
          },
          category: 'Layout',
        ),
        const DropdownProperty(
          key: 'crossAxisAlignment',
          label: 'Cross Axis Alignment',
          defaultValue: 'center',
          options: {
            'start': 'Start',
            'center': 'Center',
            'end': 'End',
            'stretch': 'Stretch',
          },
          category: 'Layout',
        ),
        const NumberProperty(
          key: 'spacing',
          label: 'Spacing',
          defaultValue: 0.0,
          min: 0,
          max: 50,
          category: 'Layout',
          unit: 'px',
        ),
        const NumberProperty(
          key: 'padding',
          label: 'Padding',
          defaultValue: 0.0,
          min: 0,
          max: 100,
          category: 'Layout',
          unit: 'px',
        ),
      ];

  // Text Properties
  static List<ElementProperty> get textProperties => [
        const TextProperty(
          key: 'text',
          label: 'Text',
          defaultValue: 'Text eingeben',
          maxLines: 5,
          placeholder: 'Enter text...',
          category: 'Content',
        ),
        const NumberProperty(
          key: 'fontSize',
          label: 'Font Size',
          defaultValue: 16.0,
          min: 8,
          max: 72,
          category: 'Typography',
          unit: 'px',
        ),
        const DropdownProperty(
          key: 'fontWeight',
          label: 'Font Weight',
          defaultValue: 'normal',
          options: {
            'light': 'Light',
            'normal': 'Normal',
            'medium': 'Medium',
            'semiBold': 'Semi Bold',
            'bold': 'Bold',
          },
          category: 'Typography',
        ),
        const DropdownProperty(
          key: 'textAlign',
          label: 'Text Align',
          defaultValue: 'left',
          options: {
            'left': 'Left',
            'center': 'Center',
            'right': 'Right',
            'justify': 'Justify',
          },
          category: 'Typography',
        ),
        const ElementColorProperty(
          key: 'color',
          label: 'Text Color',
          defaultValue: '#000000',
          category: 'Typography',
        ),
        const NumberProperty(
          key: 'lineHeight',
          label: 'Line Height',
          defaultValue: 1.5,
          min: 1.0,
          max: 3.0,
          decimals: 1,
          category: 'Typography',
        ),
        const NumberProperty(
          key: 'letterSpacing',
          label: 'Letter Spacing',
          defaultValue: 0.0,
          min: -2.0,
          max: 10.0,
          decimals: 1,
          category: 'Typography',
          unit: 'px',
        ),
        const NumberProperty(
          key: 'maxLines',
          label: 'Max Lines',
          defaultValue: null,
          min: 1,
          max: 20,
          nullable: true,
          category: 'Typography',
        ),
      ];

  // Image Properties
  static List<ElementProperty> get imageProperties => [
        const TextProperty(
          key: 'url',
          label: 'Image URL',
          defaultValue: '',
          placeholder: 'https://...',
          category: 'Content',
        ),
        const NumberProperty(
          key: 'width',
          label: 'Width',
          defaultValue: 200.0,
          min: 0,
          max: 2000,
          category: 'Layout',
          unit: 'px',
        ),
        const NumberProperty(
          key: 'height',
          label: 'Height',
          defaultValue: 200.0,
          min: 0,
          max: 2000,
          category: 'Layout',
          unit: 'px',
        ),
        const DropdownProperty(
          key: 'fit',
          label: 'Fit',
          defaultValue: 'cover',
          options: {
            'cover': 'Cover',
            'contain': 'Contain',
            'fill': 'Fill',
            'fitWidth': 'Fit Width',
            'fitHeight': 'Fit Height',
          },
          category: 'Layout',
        ),
        const NumberProperty(
          key: 'borderRadius',
          label: 'Border Radius',
          defaultValue: 0.0,
          min: 0,
          max: 50,
          category: 'Styling',
          unit: 'px',
        ),
      ];

  // Button Properties
  static List<ElementProperty> get buttonProperties => [
        const TextProperty(
          key: 'text',
          label: 'Button Text',
          defaultValue: 'Button',
          category: 'Content',
        ),
        const NumberProperty(
          key: 'fontSize',
          label: 'Font Size',
          defaultValue: 16.0,
          min: 8,
          max: 32,
          category: 'Typography',
          unit: 'px',
        ),
        const DropdownProperty(
          key: 'fontWeight',
          label: 'Font Weight',
          defaultValue: 'bold',
          options: {
            'normal': 'Normal',
            'medium': 'Medium',
            'semiBold': 'Semi Bold',
            'bold': 'Bold',
          },
          category: 'Typography',
        ),
        const ElementColorProperty(
          key: 'textColor',
          label: 'Text Color',
          defaultValue: '#FFFFFF',
          category: 'Typography',
        ),
        const ElementColorProperty(
          key: 'backgroundColor',
          label: 'Background Color',
          defaultValue: '#2196F3',
          category: 'Styling',
        ),
        const NumberProperty(
          key: 'padding',
          label: 'Padding',
          defaultValue: 16.0,
          min: 0,
          max: 50,
          category: 'Layout',
          unit: 'px',
        ),
        const NumberProperty(
          key: 'borderRadius',
          label: 'Border Radius',
          defaultValue: 8.0,
          min: 0,
          max: 50,
          category: 'Styling',
          unit: 'px',
        ),
        const NumberProperty(
          key: 'elevation',
          label: 'Elevation',
          defaultValue: 2.0,
          min: 0,
          max: 24,
          category: 'Styling',
        ),
        const NumberProperty(
          key: 'width',
          label: 'Width',
          defaultValue: null,
          min: 0,
          max: 500,
          nullable: true,
          category: 'Layout',
          unit: 'px',
        ),
        const NumberProperty(
          key: 'height',
          label: 'Height',
          defaultValue: null,
          min: 0,
          max: 200,
          nullable: true,
          category: 'Layout',
          unit: 'px',
        ),
      ];

  // Icon Properties
  static List<ElementProperty> get iconProperties => [
        const NumberProperty(
          key: 'iconCode',
          label: 'Icon Code',
          defaultValue: 0xe047,
          min: 0,
          max: 999999,
          category: 'Content',
        ),
        const NumberProperty(
          key: 'size',
          label: 'Size',
          defaultValue: 24.0,
          min: 12,
          max: 200,
          category: 'Layout',
          unit: 'px',
        ),
        const ElementColorProperty(
          key: 'color',
          label: 'Color',
          defaultValue: '#000000',
          category: 'Styling',
        ),
      ];

  // Spacer Properties
  static List<ElementProperty> get spacerProperties => [
        const NumberProperty(
          key: 'height',
          label: 'Height',
          defaultValue: 16.0,
          min: 0,
          max: 200,
          category: 'Layout',
          unit: 'px',
        ),
        const NumberProperty(
          key: 'width',
          label: 'Width',
          defaultValue: null,
          min: 0,
          max: 200,
          nullable: true,
          category: 'Layout',
          unit: 'px',
        ),
      ];

  // Divider Properties
  static List<ElementProperty> get dividerProperties => [
        const NumberProperty(
          key: 'height',
          label: 'Height',
          defaultValue: 1.0,
          min: 0,
          max: 10,
          decimals: 1,
          category: 'Layout',
          unit: 'px',
        ),
        const ElementColorProperty(
          key: 'color',
          label: 'Color',
          defaultValue: '#E0E0E0',
          category: 'Styling',
        ),
        const NumberProperty(
          key: 'indent',
          label: 'Indent Left',
          defaultValue: 0.0,
          min: 0,
          max: 100,
          category: 'Layout',
          unit: 'px',
        ),
        const NumberProperty(
          key: 'endIndent',
          label: 'Indent Right',
          defaultValue: 0.0,
          min: 0,
          max: 100,
          category: 'Layout',
          unit: 'px',
        ),
      ];
}

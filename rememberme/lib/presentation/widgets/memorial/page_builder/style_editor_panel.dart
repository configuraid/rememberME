import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../business_logic/page_builder/page_builder_bloc.dart';
import '../../../../business_logic/page_builder/page_builder_event.dart';
import '../../../../business_logic/page_builder/page_builder_state.dart';
import '../../../../data/models/content_block_model.dart';
import '../../../../core/constants/app_colors.dart';

class StyleEditorPanel extends StatelessWidget {
  final ContentBlockModel block;
  final VoidCallback onClose;

  const StyleEditorPanel({
    super.key,
    required this.block,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Styling',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: BlocBuilder<PageBuilderBloc, PageBuilderState>(
              builder: (context, state) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Templates Section
                    _buildTemplatesSection(context, state),
                    const SizedBox(height: 24),

                    // Style Controls based on block type
                    ..._buildStyleControls(context, block),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesSection(BuildContext context, PageBuilderState state) {
    final templates =
        state.availableTemplates.where((t) => t.type == block.type).toList();

    if (templates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vorlagen',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...templates.map((template) {
          return _buildTemplateCard(context, template);
        }),
      ],
    );
  }

  Widget _buildTemplateCard(BuildContext context, BlockTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          context.read<PageBuilderBloc>().add(
                PageBuilderBlockTemplateSelectRequested(
                  blockId: block.id,
                  templateId: template.id,
                ),
              );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                template.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStyleControls(
      BuildContext context, ContentBlockModel block) {
    switch (block.type) {
      case ContentBlockType.hero:
        return _buildHeroStyleControls(context, block);
      case ContentBlockType.text:
        return _buildTextStyleControls(context, block);
      case ContentBlockType.gallery:
        return _buildGalleryStyleControls(context, block);
      case ContentBlockType.quote:
        return _buildQuoteStyleControls(context, block);
      case ContentBlockType.timeline:
        return _buildTimelineStyleControls(context, block);
      default:
        return [];
    }
  }

  List<Widget> _buildHeroStyleControls(
      BuildContext context, ContentBlockModel block) {
    return [
      _buildSectionHeader('Layout'),
      _buildDropdownControl(
        context: context,
        label: 'Text-Position',
        value: block.styles['layout'] ?? 'centered',
        items: const [
          {'value': 'centered', 'label': 'Zentriert'},
          {'value': 'left', 'label': 'Links'},
          {'value': 'right', 'label': 'Rechts'},
        ],
        onChanged: (value) => _updateStyle(context, 'layout', value),
      ),
      const SizedBox(height: 16),
      _buildSectionHeader('Farben'),
      _buildColorPicker(
        context: context,
        label: 'Textfarbe',
        value: block.styles['textColor'] ?? '#FFFFFF',
        onChanged: (color) => _updateStyle(context, 'textColor', color),
      ),
      const SizedBox(height: 16),
      _buildSliderControl(
        context: context,
        label: 'Overlay-Transparenz',
        value: (block.styles['overlayOpacity'] ?? 0.3) as double,
        min: 0.0,
        max: 1.0,
        onChanged: (value) => _updateStyle(context, 'overlayOpacity', value),
      ),
      const SizedBox(height: 16),
      _buildSectionHeader('Typografie'),
      _buildDropdownControl(
        context: context,
        label: 'Schriftgröße',
        value: block.styles['fontSize'] ?? 'large',
        items: const [
          {'value': 'small', 'label': 'Klein'},
          {'value': 'medium', 'label': 'Mittel'},
          {'value': 'large', 'label': 'Groß'},
          {'value': 'xlarge', 'label': 'Sehr groß'},
        ],
        onChanged: (value) => _updateStyle(context, 'fontSize', value),
      ),
    ];
  }

  List<Widget> _buildTextStyleControls(
      BuildContext context, ContentBlockModel block) {
    return [
      _buildSectionHeader('Ausrichtung'),
      _buildSegmentedControl(
        context: context,
        label: 'Text-Ausrichtung',
        value: block.styles['alignment'] ?? 'left',
        items: const [
          {'value': 'left', 'icon': Icons.format_align_left},
          {'value': 'center', 'icon': Icons.format_align_center},
          {'value': 'right', 'icon': Icons.format_align_right},
          {'value': 'justify', 'icon': Icons.format_align_justify},
        ],
        onChanged: (value) => _updateStyle(context, 'alignment', value),
      ),
      const SizedBox(height: 16),
      _buildSectionHeader('Typografie'),
      _buildDropdownControl(
        context: context,
        label: 'Schriftart',
        value: block.styles['fontFamily'] ?? 'sans-serif',
        items: const [
          {'value': 'sans-serif', 'label': 'Sans Serif'},
          {'value': 'serif', 'label': 'Serif'},
          {'value': 'monospace', 'label': 'Monospace'},
        ],
        onChanged: (value) => _updateStyle(context, 'fontFamily', value),
      ),
      const SizedBox(height: 12),
      _buildDropdownControl(
        context: context,
        label: 'Schriftgröße',
        value: block.styles['fontSize'] ?? 'medium',
        items: const [
          {'value': 'small', 'label': 'Klein'},
          {'value': 'medium', 'label': 'Mittel'},
          {'value': 'large', 'label': 'Groß'},
        ],
        onChanged: (value) => _updateStyle(context, 'fontSize', value),
      ),
      const SizedBox(height: 12),
      _buildSliderControl(
        context: context,
        label: 'Zeilenhöhe',
        value: (block.styles['lineHeight'] ?? 1.6) as double,
        min: 1.0,
        max: 3.0,
        divisions: 20,
        onChanged: (value) => _updateStyle(context, 'lineHeight', value),
      ),
      const SizedBox(height: 16),
      _buildSectionHeader('Farben'),
      _buildColorPicker(
        context: context,
        label: 'Textfarbe',
        value: block.styles['color'] ?? '#333333',
        onChanged: (color) => _updateStyle(context, 'color', color),
      ),
    ];
  }

  List<Widget> _buildGalleryStyleControls(
      BuildContext context, ContentBlockModel block) {
    return [
      _buildSectionHeader('Layout'),
      _buildDropdownControl(
        context: context,
        label: 'Galerie-Layout',
        value: block.styles['layout'] ?? 'grid',
        items: const [
          {'value': 'grid', 'label': 'Raster'},
          {'value': 'masonry', 'label': 'Mauerwerk'},
          {'value': 'carousel', 'label': 'Karussell'},
        ],
        onChanged: (value) => _updateStyle(context, 'layout', value),
      ),
      const SizedBox(height: 12),
      _buildSliderControl(
        context: context,
        label: 'Spalten',
        value: (block.styles['columns'] ?? 3).toDouble(),
        min: 1,
        max: 6,
        divisions: 5,
        onChanged: (value) => _updateStyle(context, 'columns', value.toInt()),
      ),
      const SizedBox(height: 12),
      _buildSliderControl(
        context: context,
        label: 'Abstand',
        value: (block.styles['spacing'] ?? 16).toDouble(),
        min: 0,
        max: 32,
        divisions: 16,
        onChanged: (value) => _updateStyle(context, 'spacing', value.toInt()),
      ),
      const SizedBox(height: 16),
      _buildSectionHeader('Styling'),
      _buildSliderControl(
        context: context,
        label: 'Ecken-Radius',
        value: (block.styles['borderRadius'] ?? 8).toDouble(),
        min: 0,
        max: 24,
        divisions: 24,
        onChanged: (value) =>
            _updateStyle(context, 'borderRadius', value.toInt()),
      ),
    ];
  }

  List<Widget> _buildQuoteStyleControls(
      BuildContext context, ContentBlockModel block) {
    return [
      _buildSectionHeader('Stil'),
      _buildDropdownControl(
        context: context,
        label: 'Zitat-Stil',
        value: block.styles['style'] ?? 'classic',
        items: const [
          {'value': 'classic', 'label': 'Klassisch'},
          {'value': 'modern', 'label': 'Modern'},
          {'value': 'minimal', 'label': 'Minimal'},
        ],
        onChanged: (value) => _updateStyle(context, 'style', value),
      ),
      const SizedBox(height: 16),
      _buildSectionHeader('Typografie'),
      _buildDropdownControl(
        context: context,
        label: 'Schriftgröße',
        value: block.styles['fontSize'] ?? 'large',
        items: const [
          {'value': 'medium', 'label': 'Mittel'},
          {'value': 'large', 'label': 'Groß'},
          {'value': 'xlarge', 'label': 'Sehr groß'},
        ],
        onChanged: (value) => _updateStyle(context, 'fontSize', value),
      ),
      const SizedBox(height: 12),
      _buildSwitchControl(
        context: context,
        label: 'Kursiv',
        value: block.styles['italics'] ?? true,
        onChanged: (value) => _updateStyle(context, 'italics', value),
      ),
      const SizedBox(height: 16),
      _buildSectionHeader('Farben'),
      _buildColorPicker(
        context: context,
        label: 'Textfarbe',
        value: block.styles['color'] ?? '#555555',
        onChanged: (color) => _updateStyle(context, 'color', color),
      ),
      const SizedBox(height: 12),
      _buildColorPicker(
        context: context,
        label: 'Hintergrund',
        value: block.styles['backgroundColor'] ?? '#F8F9FA',
        onChanged: (color) => _updateStyle(context, 'backgroundColor', color),
      ),
    ];
  }

  List<Widget> _buildTimelineStyleControls(
      BuildContext context, ContentBlockModel block) {
    return [
      _buildSectionHeader('Layout'),
      _buildDropdownControl(
        context: context,
        label: 'Ausrichtung',
        value: block.styles['layout'] ?? 'vertical',
        items: const [
          {'value': 'vertical', 'label': 'Vertikal'},
          {'value': 'horizontal', 'label': 'Horizontal'},
        ],
        onChanged: (value) => _updateStyle(context, 'layout', value),
      ),
      const SizedBox(height: 16),
      _buildSectionHeader('Farben'),
      _buildColorPicker(
        context: context,
        label: 'Linien-Farbe',
        value: block.styles['lineColor'] ?? '#3498DB',
        onChanged: (color) => _updateStyle(context, 'lineColor', color),
      ),
      const SizedBox(height: 12),
      _buildColorPicker(
        context: context,
        label: 'Icon-Farbe',
        value: block.styles['iconColor'] ?? '#3498DB',
        onChanged: (color) => _updateStyle(context, 'iconColor', color),
      ),
      const SizedBox(height: 16),
      _buildSectionHeader('Karten-Stil'),
      _buildDropdownControl(
        context: context,
        label: 'Stil',
        value: block.styles['cardStyle'] ?? 'elevated',
        items: const [
          {'value': 'elevated', 'label': 'Erhöht'},
          {'value': 'flat', 'label': 'Flach'},
          {'value': 'outlined', 'label': 'Umrandet'},
        ],
        onChanged: (value) => _updateStyle(context, 'cardStyle', value),
      ),
    ];
  }

  // Helper Widgets
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDropdownControl({
    required BuildContext context,
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item['value'],
              child: Text(item['label']!),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ],
    );
  }

  Widget _buildSliderControl({
    required BuildContext context,
    required String label,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              value.toStringAsFixed(divisions != null ? 0 : 2),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildColorPicker({
    required BuildContext context,
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    final color = _hexToColor(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showColorPicker(context, value, onChanged),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  value.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl({
    required BuildContext context,
    required String label,
    required String value,
    required List<Map<String, dynamic>> items,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: items.map((item) {
            final isSelected = item['value'] == value;
            return Expanded(
              child: InkWell(
                onTap: () => onChanged(item['value']),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey[300]!,
                    ),
                  ),
                  child: Icon(
                    item['icon'],
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSwitchControl({
    required BuildContext context,
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  void _updateStyle(BuildContext context, String key, dynamic value) {
    context.read<PageBuilderBloc>().add(
          PageBuilderBlockStyleChangeRequested(
            blockId: block.id,
            styleKey: key,
            styleValue: value,
          ),
        );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  void _showColorPicker(
    BuildContext context,
    String currentColor,
    Function(String) onChanged,
  ) {
    final colors = [
      '#FFFFFF',
      '#F8F9FA',
      '#E9ECEF',
      '#DEE2E6',
      '#CED4DA',
      '#ADB5BD',
      '#6C757D',
      '#495057',
      '#343A40',
      '#212529',
      '#FF6B6B',
      '#EE5A6F',
      '#C92A2A',
      '#A61E4D',
      '#862E9C',
      '#5F3DC4',
      '#364FC7',
      '#1864AB',
      '#0B7285',
      '#087F5B',
      '#2B8A3E',
      '#5C940D',
      '#E67700',
      '#D9480F',
      '#E03131',
      '#3498DB',
      '#2ECC71',
      '#F39C12',
      '#E74C3C',
      '#9B59B6',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Farbe wählen'),
        content: SizedBox(
          width: 300,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: colors.map((color) {
              final isSelected =
                  color.toUpperCase() == currentColor.toUpperCase();
              return InkWell(
                onTap: () {
                  onChanged(color);
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _hexToColor(color),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey[300]!,
                      width: isSelected ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class TextBlockEditor extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onDataChanged;

  const TextBlockEditor({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  @override
  State<TextBlockEditor> createState() => _TextBlockEditorState();
}

class _TextBlockEditorState extends State<TextBlockEditor> {
  late TextEditingController _contentController;
  late TextEditingController _headingController;

  @override
  void initState() {
    super.initState();
    _contentController =
        TextEditingController(text: widget.data['content'] ?? '');
    _headingController =
        TextEditingController(text: widget.data['heading'] ?? '');
  }

  @override
  void dispose() {
    _contentController.dispose();
    _headingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Überschrift (optional)
        Text(
          'Überschrift (optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _headingController,
          decoration: InputDecoration(
            hintText: 'z.B. Sein Leben',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          onChanged: (value) => _updateData('heading', value),
        ),
        const SizedBox(height: 24),

        // Text-Inhalt
        Text(
          'Text',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contentController,
          decoration: InputDecoration(
            hintText: 'Schreiben Sie hier den Text...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            alignLabelWithHint: true,
          ),
          maxLines: 12,
          onChanged: (value) => _updateData('content', value),
        ),
        const SizedBox(height: 16),

        // Zeichenzähler
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${_contentController.text.length} Zeichen',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Format-Hilfe
        _buildFormatGuide(),
        const SizedBox(height: 24),

        // Tipps
        _buildTipsCard(),
      ],
    );
  }

  Widget _buildFormatGuide() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline),
        title: const Text('Formatierungs-Hilfe'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormatItem('**Fett**', 'Fetter Text'),
                _buildFormatItem('*Kursiv*', 'Kursiver Text'),
                _buildFormatItem('# Überschrift', 'Große Überschrift'),
                _buildFormatItem('## Überschrift', 'Mittlere Überschrift'),
                _buildFormatItem('- Liste', 'Aufzählungsliste'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatItem(String syntax, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                syntax,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward, size: 16),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(description, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Card(
      color: AppColors.info.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.info),
                const SizedBox(width: 8),
                const Text(
                  'Schreibtipps',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTipItem('Schreiben Sie in kurzen, klaren Sätzen'),
            _buildTipItem('Teilen Sie lange Texte in Absätze auf'),
            _buildTipItem('Verwenden Sie emotionale und persönliche Sprache'),
            _buildTipItem('Erzählen Sie Geschichten statt nur Fakten'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _updateData(String key, dynamic value) {
    final updatedData = Map<String, dynamic>.from(widget.data);
    if (value == null || value.toString().isEmpty) {
      updatedData.remove(key);
    } else {
      updatedData[key] = value;
    }
    widget.onDataChanged(updatedData);
  }
}

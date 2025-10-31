import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class QuoteBlockEditor extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onDataChanged;

  const QuoteBlockEditor({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  @override
  State<QuoteBlockEditor> createState() => _QuoteBlockEditorState();
}

class _QuoteBlockEditorState extends State<QuoteBlockEditor> {
  late TextEditingController _quoteController;
  late TextEditingController _authorController;
  late TextEditingController _contextController;

  @override
  void initState() {
    super.initState();
    _quoteController = TextEditingController(text: widget.data['quote'] ?? '');
    _authorController =
        TextEditingController(text: widget.data['author'] ?? '');
    _contextController =
        TextEditingController(text: widget.data['context'] ?? '');
  }

  @override
  void dispose() {
    _quoteController.dispose();
    _authorController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Zitat
        Text(
          'Zitat',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _quoteController,
          decoration: InputDecoration(
            hintText: 'Das Leben ist wie...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.format_quote),
          ),
          maxLines: 4,
          style: const TextStyle(
            fontSize: 18,
            fontStyle: FontStyle.italic,
          ),
          onChanged: (value) => _updateData('quote', value),
        ),
        const SizedBox(height: 24),

        // Autor
        Text(
          'Autor/Quelle',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _authorController,
          decoration: InputDecoration(
            hintText: 'z.B. Max Mustermann',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.person),
          ),
          onChanged: (value) => _updateData('author', value),
        ),
        const SizedBox(height: 24),

        // Kontext (optional)
        Text(
          'Kontext (optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contextController,
          decoration: InputDecoration(
            hintText: 'z.B. Aus seiner Abschiedsrede 2020',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.info_outline),
          ),
          onChanged: (value) => _updateData('context', value),
        ),
        const SizedBox(height: 24),

        // Vorschau
        _buildPreview(),
        const SizedBox(height: 24),

        // Tipps
        _buildTipsCard(),
      ],
    );
  }

  Widget _buildPreview() {
    final quote = _quoteController.text;
    final author = _authorController.text;
    final quoteContext =
        _contextController.text; // GEÄNDERT: context -> quoteContext

    if (quote.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vorschau',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.format_quote, size: 36, color: AppColors.accent),
              const SizedBox(height: 12),
              Text(
                quote,
                style: const TextStyle(
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),
              if (author.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      author,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              if (quoteContext.isNotEmpty) ...[
                // GEÄNDERT: context -> quoteContext
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    quoteContext, // GEÄNDERT: context -> quoteContext
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
                  'Zitat-Tipps',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTipItem('Wählen Sie bedeutungsvolle Worte'),
            _buildTipItem('Kurze Zitate haben oft mehr Wirkung'),
            _buildTipItem('Geben Sie immer die Quelle an'),
            _buildTipItem('Der Kontext hilft beim Verständnis'),
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

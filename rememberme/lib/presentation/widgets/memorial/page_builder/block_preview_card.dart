import 'package:flutter/material.dart';
import '../../../../data/models/content_block_model.dart';
import '../../../../core/constants/app_colors.dart';

class BlockPreviewCard extends StatelessWidget {
  final ContentBlockModel block;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onStyle;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const BlockPreviewCard({
    super.key,
    required this.block,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onStyle,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.accent : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected ? AppColors.accent.withOpacity(0.05) : Colors.white,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Drag Handle
                  Icon(
                    Icons.drag_handle,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                  const SizedBox(width: 12),

                  // Block Icon & Name
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getBlockColor(block.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getBlockIcon(block.type),
                      color: _getBlockColor(block.type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getBlockName(block.type),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (block.data.isNotEmpty)
                          Text(
                            _getBlockPreviewText(block),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  PopupMenuButton<String>(
                    // GEÄNDERT: Typ hinzugefügt
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      // GEÄNDERT: const entfernt
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            // GEÄNDERT: const entfernt
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 12),
                            Text('Bearbeiten'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'style',
                        child: Row(
                          children: [
                            // GEÄNDERT: const entfernt
                            Icon(Icons.palette, size: 20),
                            SizedBox(width: 12),
                            Text('Styling'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            // GEÄNDERT: const entfernt
                            Icon(Icons.content_copy, size: 20),
                            SizedBox(width: 12),
                            Text('Duplizieren'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            // GEÄNDERT: const entfernt
                            Icon(Icons.delete,
                                size: 20, color: AppColors.error),
                            SizedBox(width: 12),
                            Text('Löschen',
                                style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'style':
                          onStyle();
                          break;
                        case 'duplicate':
                          onDuplicate();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                  ),
                ],
              ),

              // Preview Content
              if (block.data.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildBlockPreview(block),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockPreview(ContentBlockModel block) {
    switch (block.type) {
      case ContentBlockType.hero:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (block.data['imageUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  block.data['imageUrl'],
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 48),
                  ),
                ),
              ),
            if (block.data['title'] != null) ...[
              const SizedBox(height: 8),
              Text(
                block.data['title'],
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        );

      case ContentBlockType.text:
        return Text(
          block.data['content'] ?? 'Kein Text',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        );

      case ContentBlockType.gallery:
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: List.generate(
            (block.data['images'] as List?)?.length ?? 0,
            (index) => Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.image, size: 24),
            ),
          ).take(6).toList(),
        );

      case ContentBlockType.quote:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.format_quote, size: 32),
            Text(
              block.data['quote'] ?? 'Kein Zitat',
              style: const TextStyle(fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (block.data['author'] != null) ...[
              const SizedBox(height: 4),
              Text(
                '- ${block.data['author']}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        );

      case ContentBlockType.timeline:
        return Column(
          children: List.generate(
            (block.data['events'] as List?)?.length ?? 0,
            (index) => ListTile(
              dense: true,
              leading: const Icon(Icons.circle, size: 12),
              title: Text('Event ${index + 1}'),
            ),
          ).take(3).toList(),
        );

      default:
        return Text('Block-Typ: ${block.type}');
    }
  }

  IconData _getBlockIcon(ContentBlockType type) {
    switch (type) {
      case ContentBlockType.hero:
        return Icons.image;
      case ContentBlockType.text:
        return Icons.text_fields;
      case ContentBlockType.gallery:
        return Icons.photo_library;
      case ContentBlockType.quote:
        return Icons.format_quote;
      case ContentBlockType.timeline:
        return Icons.timeline;
      default:
        return Icons.widgets;
    }
  }

  Color _getBlockColor(ContentBlockType type) {
    switch (type) {
      case ContentBlockType.hero:
        return AppColors.primary;
      case ContentBlockType.text:
        return AppColors.success;
      case ContentBlockType.gallery:
        return AppColors.accent;
      case ContentBlockType.quote:
        return AppColors.warning;
      case ContentBlockType.timeline:
        return AppColors.info;
      default:
        return Colors.grey;
    }
  }

  String _getBlockName(ContentBlockType type) {
    switch (type) {
      case ContentBlockType.hero:
        return 'Hero-Bild';
      case ContentBlockType.text:
        return 'Textblock';
      case ContentBlockType.gallery:
        return 'Galerie';
      case ContentBlockType.quote:
        return 'Zitat';
      case ContentBlockType.timeline:
        return 'Zeitleiste';
      default:
        return 'Unbekannt';
    }
  }

  String _getBlockPreviewText(ContentBlockModel block) {
    switch (block.type) {
      case ContentBlockType.hero:
        return block.data['title'] ?? 'Hero-Bild';
      case ContentBlockType.text:
        final content = block.data['content'] ?? '';
        return content.length > 50 ? '${content.substring(0, 50)}...' : content;
      case ContentBlockType.gallery:
        final count = (block.data['images'] as List?)?.length ?? 0;
        return '$count Bild${count != 1 ? 'er' : ''}';
      case ContentBlockType.quote:
        return block.data['quote'] ?? 'Zitat';
      case ContentBlockType.timeline:
        final count = (block.data['events'] as List?)?.length ?? 0;
        return '$count Event${count != 1 ? 's' : ''}';
      default:
        return '';
    }
  }
}

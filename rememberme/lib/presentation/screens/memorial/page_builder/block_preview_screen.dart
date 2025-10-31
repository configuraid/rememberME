import 'package:flutter/material.dart';
import '../../../../data/models/content_block_model.dart';

class BlockPreviewScreen extends StatelessWidget {
  final List<ContentBlockModel> blocks;

  const BlockPreviewScreen({
    super.key,
    required this.blocks,
  });

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Keine Inhalte zur Vorschau',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: blocks.length,
      itemBuilder: (context, index) {
        final block = blocks[index];
        return _buildBlockPreview(context, block);
      },
    );
  }

  Widget _buildBlockPreview(BuildContext context, ContentBlockModel block) {
    switch (block.type) {
      case ContentBlockType.hero:
        return _buildHeroPreview(context, block);
      case ContentBlockType.text:
        return _buildTextPreview(context, block);
      case ContentBlockType.gallery:
        return _buildGalleryPreview(context, block);
      case ContentBlockType.quote:
        return _buildQuotePreview(context, block);
      case ContentBlockType.timeline:
        return _buildTimelinePreview(context, block);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHeroPreview(BuildContext context, ContentBlockModel block) {
    final imageUrl = block.data['imageUrl'];
    final title = block.data['title'] ?? '';
    final subtitle = block.data['subtitle'] ?? '';

    return Container(
      height: 400,
      decoration: BoxDecoration(
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              )
            : null,
        color: imageUrl == null ? Colors.grey[300] : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(
                  (block.styles['overlayOpacity'] ?? 0.3) as double),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: TextStyle(
                      color:
                          _hexToColor(block.styles['textColor'] ?? '#FFFFFF'),
                      fontSize:
                          _getFontSize(block.styles['fontSize'] ?? 'large'),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _hexToColor(block.styles['textColor'] ?? '#FFFFFF')
                          .withOpacity(0.9),
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextPreview(BuildContext context, ContentBlockModel block) {
    final content = block.data['content'] ?? '';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        content,
        style: TextStyle(
          fontSize: _getFontSize(block.styles['fontSize'] ?? 'medium'),
          height: (block.styles['lineHeight'] ?? 1.6) as double,
          color: _hexToColor(block.styles['color'] ?? '#333333'),
          fontFamily: block.styles['fontFamily'] ?? 'sans-serif',
        ),
        textAlign: _getTextAlignment(block.styles['alignment'] ?? 'left'),
      ),
    );
  }

  Widget _buildGalleryPreview(BuildContext context, ContentBlockModel block) {
    final images = (block.data['images'] as List?)?.cast<String>() ?? [];
    final columns = block.styles['columns'] ?? 3;
    final spacing = (block.styles['spacing'] ?? 16).toDouble();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(
                (block.styles['borderRadius'] ?? 8).toDouble()),
            child: Image.network(
              images[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 48),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuotePreview(BuildContext context, ContentBlockModel block) {
    final quote = block.data['quote'] ?? '';
    final author = block.data['author'] ?? '';

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _hexToColor(block.styles['backgroundColor'] ?? '#F8F9FA'),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote,
            size: 48,
            color: _hexToColor(block.styles['color'] ?? '#555555')
                .withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            quote,
            style: TextStyle(
              fontSize: _getFontSize(block.styles['fontSize'] ?? 'large'),
              fontStyle: (block.styles['italics'] ?? true)
                  ? FontStyle.italic
                  : FontStyle.normal,
              color: _hexToColor(block.styles['color'] ?? '#555555'),
            ),
          ),
          if (author.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '— $author',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _hexToColor(block.styles['color'] ?? '#555555'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelinePreview(BuildContext context, ContentBlockModel block) {
    final events =
        (block.data['events'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final lineColor = _hexToColor(block.styles['lineColor'] ?? '#3498DB');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: events.map((event) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: lineColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.circle,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 80,
                    color: lineColor,
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['date'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (event['description'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            event['description'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
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

  double _getFontSize(String size) {
    switch (size) {
      case 'small':
        return 14;
      case 'medium':
        return 16;
      case 'large':
        return 24;
      case 'xlarge':
        return 32;
      default:
        return 16;
    }
  }

  TextAlign _getTextAlignment(String alignment) {
    switch (alignment) {
      case 'left':
        return TextAlign.left;
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }
}

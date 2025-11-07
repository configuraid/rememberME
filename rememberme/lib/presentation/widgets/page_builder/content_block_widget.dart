import 'package:flutter/material.dart';
import 'package:rememberme/data/models/content_block_model.dart';

class ContentBlockWidget extends StatelessWidget {
  final ContentBlock block;
  final bool isSelected;
  final bool isPreview;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final Function(String key, dynamic value) onContentChanged;

  const ContentBlockWidget({
    super.key,
    required this.block,
    required this.isSelected,
    this.isPreview = false,
    required this.onTap,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    required this.onContentChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isPreview) {
      return _buildPreviewContent();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: isSelected ? 4 : 1,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with type and actions
                _buildHeader(context),

                // Divider
                Divider(height: 1, color: Colors.grey[200]),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Drag Handle
          Icon(Icons.drag_indicator, color: Colors.grey[400], size: 20),
          const SizedBox(width: 8),

          // Icon & Type
          Text(
            BlockTypeInfo.getIcon(block.type),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Text(
            BlockTypeInfo.getTitle(block.type),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),

          const Spacer(),

          // Quick Actions
          IconButton(
            icon: Icon(Icons.settings, size: 18, color: Colors.grey[600]),
            onPressed: onEdit,
            tooltip: 'Bearbeiten',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.content_copy, size: 18, color: Colors.grey[600]),
            onPressed: onDuplicate,
            tooltip: 'Duplizieren',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[400]),
            onPressed: onDelete,
            tooltip: 'Löschen',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (block.type) {
      case ContentBlockType.header:
        return _buildHeaderContent();
      case ContentBlockType.text:
        return _buildTextContent();
      case ContentBlockType.image:
        return _buildImageContent();
      case ContentBlockType.gallery:
        return _buildGalleryContent();
      case ContentBlockType.quote:
        return _buildQuoteContent();
      case ContentBlockType.divider:
        return _buildDividerContent();
      case ContentBlockType.video:
        return _buildVideoContent();
      case ContentBlockType.date:
        return _buildDateContent();
    }
  }

  Widget _buildPreviewContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _buildContent(),
    );
  }

  // ===== CONTENT RENDERERS =====

  Widget _buildHeaderContent() {
    final text = block.getContent('text', 'Überschrift');
    final level = block.getContent('level', 1);
    final align = block.getContent('align', 'center');
    final colorHex = block.getContent('color', '#000000');

    double fontSize = level == 1
        ? 32
        : level == 2
            ? 24
            : 20;

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: _hexToColor(colorHex),
      ),
      textAlign: align == 'center'
          ? TextAlign.center
          : align == 'right'
              ? TextAlign.right
              : TextAlign.left,
    );
  }

  Widget _buildTextContent() {
    final text = block.getContent('text', 'Text eingeben...');
    final align = block.getContent('align', 'left');
    final fontSize = block.getContent('fontSize', 16.0);
    final colorHex = block.getContent('color', '#333333');

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: _hexToColor(colorHex),
        height: 1.6,
      ),
      textAlign: align == 'center'
          ? TextAlign.center
          : align == 'right'
              ? TextAlign.right
              : TextAlign.left,
    );
  }

  Widget _buildImageContent() {
    final url = block.getContent('url', '');
    final caption = block.getContent('caption', '');

    if (url.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Bild hochladen',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: Colors.grey[200],
              child:
                  Icon(Icons.broken_image, size: 64, color: Colors.grey[400]),
            ),
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            caption,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildGalleryContent() {
    final images = block.getContent<List>('images', []);
    final columns = block.getContent('columns', 3);

    if (images.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Bildergalerie (${images.length} Bilder)',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            images[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[200],
              child: Icon(Icons.broken_image, color: Colors.grey[400]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuoteContent() {
    final text = block.getContent('text', 'Zitat eingeben...');
    final author = block.getContent('author', '');
    final colorHex = block.getContent('color', '#666666');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: _hexToColor(colorHex), width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"$text"',
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: _hexToColor(colorHex),
              height: 1.6,
            ),
          ),
          if (author.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '— $author',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDividerContent() {
    final colorHex = block.getContent('color', '#E0E0E0');
    final thickness = block.getContent('thickness', 1.0);

    return Container(
      height: thickness,
      color: _hexToColor(colorHex),
    );
  }

  Widget _buildVideoContent() {
    final url = block.getContent('url', '');
    final caption = block.getContent('caption', '');

    if (url.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Video hinzufügen',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(Icons.play_circle_outline,
                size: 64, color: Colors.white.withOpacity(0.8)),
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            caption,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildDateContent() {
    final birthDate = block.getContent('birthDate', '');
    final deathDate = block.getContent('deathDate', '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (birthDate.isNotEmpty) ...[
            const Icon(Icons.cake, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              birthDate,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
          if (birthDate.isNotEmpty && deathDate.isNotEmpty) ...[
            const SizedBox(width: 16),
            Text('–', style: TextStyle(fontSize: 20, color: Colors.grey[400])),
            const SizedBox(width: 16),
          ],
          if (deathDate.isNotEmpty) ...[
            Text(
              deathDate,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.favorite, size: 20, color: Colors.grey),
          ],
        ],
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
}

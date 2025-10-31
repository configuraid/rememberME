import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';

class GalleryBlockEditor extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onDataChanged;

  const GalleryBlockEditor({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  @override
  State<GalleryBlockEditor> createState() => _GalleryBlockEditorState();
}

class _GalleryBlockEditorState extends State<GalleryBlockEditor> {
  final ImagePicker _picker = ImagePicker();
  List<String> _images = [];

  @override
  void initState() {
    super.initState();
    _images = (widget.data['images'] as List?)?.cast<String>() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header mit Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Galerie-Bilder',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            ElevatedButton.icon(
              onPressed: _addImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Bilder hinzufügen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Galerie Grid
        if (_images.isEmpty) _buildEmptyState() else _buildGalleryGrid(),

        const SizedBox(height: 24),

        // Tipps
        _buildTipsCard(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Noch keine Bilder',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _addImages,
              icon: const Icon(Icons.add),
              label: const Text('Erste Bilder hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryGrid() {
    return Column(
      children: [
        // Info-Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_images.length} Bild${_images.length != 1 ? 'er' : ''} - Halten und ziehen zum Sortieren',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Reorderable Grid
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _images.length,
          onReorder: _reorderImages,
          itemBuilder: (context, index) {
            return _buildImageCard(index, _images[index]);
          },
        ),
      ],
    );
  }

  Widget _buildImageCard(int index, String imageUrl) {
    return Card(
      key: ValueKey(imageUrl),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_handle),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image),
                ),
              ),
            ),
          ],
        ),
        title: Text('Bild ${index + 1}'),
        subtitle: Text(
          imageUrl.split('/').last,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editImageCaption(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () => _removeImage(index),
            ),
          ],
        ),
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
                  'Galerie-Tipps',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTipItem('Verwenden Sie hochauflösende Bilder'),
            _buildTipItem('Sortieren Sie Bilder chronologisch oder thematisch'),
            _buildTipItem('3-12 Bilder sind ideal für eine Galerie'),
            _buildTipItem('Vermeiden Sie Duplikate'),
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

  Future<void> _addImages() async {
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (images.isNotEmpty) {
      setState(() {
        // TODO: Upload zu Server
        // Für jetzt Mock-URLs
        for (var i = 0; i < images.length; i++) {
          _images.add(
              'https://picsum.photos/800/600?random=${DateTime.now().millisecondsSinceEpoch + i}');
        }
      });
      _updateData();
    }
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
    });
    _updateData();
  }

  void _removeImage(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bild entfernen'),
        content: const Text('Möchten Sie dieses Bild wirklich entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _images.removeAt(index);
              });
              _updateData();
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
  }

  void _editImageCaption(int index) {
    // TODO: Bildunterschriften implementieren
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bildunterschriften kommen bald!'),
      ),
    );
  }

  void _updateData() {
    final updatedData = Map<String, dynamic>.from(widget.data);
    updatedData['images'] = _images;
    widget.onDataChanged(updatedData);
  }
}

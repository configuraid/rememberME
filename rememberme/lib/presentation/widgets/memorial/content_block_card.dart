import 'package:flutter/material.dart';
import '../../../data/models/content_block_model.dart';
import '../../../core/constants/app_colors.dart';

class ContentBlockCard extends StatelessWidget {
  final ContentBlockModel block;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ContentBlockCard({
    super.key,
    required this.block,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(_getBlockIcon(), color: AppColors.primary),
        title: Text(_getBlockTitle()),
        subtitle: Text(block.type.toString().split('.').last),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onTap,
            ),
            if (onDelete != null)
              IconButton(
                icon:
                    const Icon(Icons.delete, size: 20, color: AppColors.error),
                onPressed: onDelete,
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  IconData _getBlockIcon() {
    switch (block.type) {
      case ContentBlockType.heroSection:
        return Icons.image;
      case ContentBlockType.textBlock:
        return Icons.text_fields;
      case ContentBlockType.imageGallery:
        return Icons.photo_library;
      case ContentBlockType.quoteSection:
        return Icons.format_quote;
      case ContentBlockType.videoCollage:
        return Icons.video_library;
      case ContentBlockType.audioPlayer:
        return Icons.audiotrack;
      case ContentBlockType.timeline:
        return Icons.timeline;
      case ContentBlockType.guestbook:
        return Icons.book;
      case ContentBlockType.memoryMap:
        return Icons.map;
      case ContentBlockType.photoGallery3D:
        return Icons.view_in_ar;
    }
  }

  String _getBlockTitle() {
    if (block.data['title'] != null) {
      return block.data['title'] as String;
    }
    if (block.data['name'] != null) {
      return block.data['name'] as String;
    }
    return block.type.toString().split('.').last;
  }
}

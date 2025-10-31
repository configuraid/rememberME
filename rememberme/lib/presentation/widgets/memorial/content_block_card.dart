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
      case ContentBlockType.hero:
        return Icons.image;
      case ContentBlockType.text:
        return Icons.text_fields;
      case ContentBlockType.gallery:
        return Icons.photo_library;
      case ContentBlockType.quote:
        return Icons.format_quote;
      case ContentBlockType.video:
        return Icons.video_library;
      case ContentBlockType.audio:
        return Icons.audiotrack;
      case ContentBlockType.timeline:
        return Icons.timeline;
      case ContentBlockType.condolences:
        return Icons.book;
      case ContentBlockType.map:
        return Icons.map;
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

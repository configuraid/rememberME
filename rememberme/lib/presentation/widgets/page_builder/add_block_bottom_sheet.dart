// lib/presentation/widgets/page_builder/add_block_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:rememberme/data/models/content_block_model.dart';

class AddBlockBottomSheet extends StatelessWidget {
  final Function(ContentBlockType) onBlockTypeSelected;

  const AddBlockBottomSheet({
    super.key,
    required this.onBlockTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Block hinzufügen',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Block Types Grid
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3, // Erhöht von 1.5 auf 1.3 für mehr Höhe
                children: ContentBlockType.values.map((type) {
                  return _buildBlockTypeCard(context, type);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockTypeCard(BuildContext context, ContentBlockType type) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: InkWell(
        onTap: () => onBlockTypeSelected(type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12), // Reduziert von 16 auf 12
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Text(
                BlockTypeInfo.getIcon(type),
                style: const TextStyle(fontSize: 28), // Reduziert von 32 auf 28
              ),
              const SizedBox(height: 6), // Reduziert von 8 auf 6

              // Title
              Text(
                BlockTypeInfo.getTitle(type),
                style: const TextStyle(
                  fontSize: 13, // Reduziert von 14 auf 13
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3), // Reduziert von 4 auf 3

              // Description
              Text(
                BlockTypeInfo.getDescription(type),
                style: TextStyle(
                  fontSize: 10, // Reduziert von 11 auf 10
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

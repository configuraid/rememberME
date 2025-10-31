import 'package:flutter/material.dart';
import '../../../../data/models/content_block_model.dart';
import '../../../../core/constants/app_colors.dart';

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Block hinzufügen',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Block Types Grid
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBlockTypeCard(
                  context,
                  'Hero-Bild',
                  'Großes Titelbild mit Text',
                  Icons.image,
                  AppColors.primary,
                  ContentBlockType.hero,
                ),
                _buildBlockTypeCard(
                  context,
                  'Textblock',
                  'Fließtext und Absätze',
                  Icons.text_fields,
                  AppColors.success,
                  ContentBlockType.text,
                ),
                _buildBlockTypeCard(
                  context,
                  'Galerie',
                  'Foto-Sammlung',
                  Icons.photo_library,
                  AppColors.accent,
                  ContentBlockType.gallery,
                ),
                _buildBlockTypeCard(
                  context,
                  'Zitat',
                  'Wichtige Aussagen',
                  Icons.format_quote,
                  AppColors.warning,
                  ContentBlockType.quote,
                ),
                _buildBlockTypeCard(
                  context,
                  'Zeitleiste',
                  'Chronologische Events',
                  Icons.timeline,
                  AppColors.info,
                  ContentBlockType.timeline,
                ),
                _buildBlockTypeCard(
                  context,
                  'Mehr',
                  'Weitere Blocks',
                  Icons.add_circle_outline,
                  Colors.grey,
                  null,
                  comingSoon: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBlockTypeCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    ContentBlockType? type, {
    bool comingSoon = false,
  }) {
    return InkWell(
      onTap: comingSoon
          ? null
          : () {
              if (type != null) {
                onBlockTypeSelected(type);
              }
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: comingSoon ? Colors.grey[100] : Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(comingSoon ? 0.3 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: comingSoon ? Colors.grey : color,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: comingSoon ? Colors.grey : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              comingSoon ? 'Bald verfügbar' : description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../data/models/memorial_page_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class PageBuilderScreen extends StatelessWidget {
  const PageBuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final memorial =
        ModalRoute.of(context)!.settings.arguments as MemorialPageModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.pageBuilder),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.save,
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Content-Block Auswahl
          Container(
            height: 120,
            color: AppColors.background,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              children: [
                _buildContentBlockOption(context, 'Hero', Icons.image),
                _buildContentBlockOption(context, 'Text', Icons.text_fields),
                _buildContentBlockOption(
                    context, 'Galerie', Icons.photo_library),
                _buildContentBlockOption(context, 'Zitat', Icons.format_quote),
                _buildContentBlockOption(context, 'Timeline', Icons.timeline),
              ],
            ),
          ),

          // Preview-Bereich
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: memorial.contentBlocks.length,
              itemBuilder: (context, index) {
                final block = memorial.contentBlocks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.drag_handle),
                    title: Text(block.type.toString().split('.').last),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      onPressed: () {},
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentBlockOption(
      BuildContext context, String label, IconData icon) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

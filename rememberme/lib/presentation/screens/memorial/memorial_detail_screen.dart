import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/memorial/memorial_bloc.dart';
import '../../../business_logic/memorial/memorial_event.dart';
import '../../../data/models/memorial_page_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';

class MemorialDetailScreen extends StatelessWidget {
  const MemorialDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final memorial =
        ModalRoute.of(context)!.settings.arguments as MemorialPageModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(memorial.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pushNamed(
              AppRoutes.pageBuilder,
              arguments: memorial,
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'publish', child: Text('Veröffentlichen')),
              const PopupMenuItem(value: 'preview', child: Text('Vorschau')),
              const PopupMenuItem(value: 'delete', child: Text('Löschen')),
            ],
            onSelected: (value) {
              if (value == 'publish') {
                context
                    .read<MemorialBloc>()
                    .add(MemorialPublishRequested(memorial.id));
              } else if (value == 'delete') {
                _showDeleteDialog(context, memorial.id);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            if (memorial.profileImageUrl != null)
              Image.network(
                memorial.profileImageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.favorite, size: 64),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Daten
                  Text(memorial.name,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(memorial.lifespan,
                      style: Theme.of(context).textTheme.titleMedium),

                  const SizedBox(height: 16),

                  // Status Badge
                  _buildStatusBadge(memorial),

                  const SizedBox(height: 24),

                  // Content Blocks
                  Text('Inhalte (${memorial.contentBlocks.length})',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),

                  ...memorial.sortedContentBlocks.map((block) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(_getBlockIcon(block.type)),
                        title: Text(_getBlockTypeName(block.type)),
                        trailing: const Icon(Icons.drag_handle),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context, rootNavigator: true).pushNamed(
          AppRoutes.pageBuilder,
          arguments: memorial,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Inhalt hinzufügen'),
      ),
    );
  }

  Widget _buildStatusBadge(MemorialPageModel memorial) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: memorial.isPublished
            ? AppColors.success.withOpacity(0.2)
            : AppColors.warning.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            memorial.isPublished ? Icons.check_circle : Icons.edit,
            size: 16,
            color: memorial.isPublished ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            memorial.isPublished ? 'Veröffentlicht' : 'Entwurf',
            style: TextStyle(
              color:
                  memorial.isPublished ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBlockIcon(type) {
    // Vereinfachte Icons für Content-Block-Typen
    return Icons.article;
  }

  String _getBlockTypeName(type) {
    return type.toString().split('.').last;
  }

  void _showDeleteDialog(BuildContext context, String memorialId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Löschen bestätigen'),
        content: const Text(AppStrings.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              context
                  .read<MemorialBloc>()
                  .add(MemorialDeleteRequested(memorialId));
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}

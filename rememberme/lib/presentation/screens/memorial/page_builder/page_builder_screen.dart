import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../business_logic/page_builder/page_builder_bloc.dart';
import '../../../../business_logic/page_builder/page_builder_event.dart';
import '../../../../business_logic/page_builder/page_builder_state.dart';
import '../../../../data/models/memorial_page_model.dart';
import '../../../../data/models/content_block_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../widgets/common/loading_indicator.dart';
import '../../../widgets/memorial/page_builder/block_editor_panel.dart';
import '../../../widgets/memorial/page_builder/block_preview_card.dart';
import '../../../widgets/memorial/page_builder/add_block_bottom_sheet.dart';
import '../../../widgets/memorial/page_builder/style_editor_panel.dart';
import '../page_builder/block_preview_screen.dart';

class PageBuilderScreen extends StatefulWidget {
  const PageBuilderScreen({super.key});

  @override
  State<PageBuilderScreen> createState() => _PageBuilderScreenState();
}

class _PageBuilderScreenState extends State<PageBuilderScreen> {
  bool _showStylePanel = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final memorial =
          ModalRoute.of(context)!.settings.arguments as MemorialPageModel;
      context
          .read<PageBuilderBloc>()
          .add(PageBuilderLoadRequested(memorial.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PageBuilderBloc, PageBuilderState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        if (state.hasError && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.blocks.isEmpty) {
          return const Scaffold(
            body: LoadingIndicator(),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(context, state),
          body: state.isPreviewMode
              ? _buildPreviewMode(state)
              : _buildEditMode(state),
          bottomNavigationBar:
              !state.isPreviewMode ? _buildBottomBar(context, state) : null,
          floatingActionButton: !state.isPreviewMode && !_showStylePanel
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddBlockSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Block hinzufügen'),
                  backgroundColor: AppColors.accent,
                )
              : null,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, PageBuilderState state) {
    return AppBar(
      title: Text(state.memorial?.name ?? AppStrings.pageBuilder),
      actions: [
        // Undo Button
        IconButton(
          icon: const Icon(Icons.undo),
          onPressed: state.canUndo
              ? () => context.read<PageBuilderBloc>().add(
                    const PageBuilderUndoRequested(),
                  )
              : null,
        ),
        // Redo Button
        IconButton(
          icon: const Icon(Icons.redo),
          onPressed: state.canRedo
              ? () => context.read<PageBuilderBloc>().add(
                    const PageBuilderRedoRequested(),
                  )
              : null,
        ),
        // Preview Toggle
        IconButton(
          icon: Icon(
            state.isPreviewMode ? Icons.edit : Icons.visibility,
          ),
          onPressed: () => context.read<PageBuilderBloc>().add(
                const PageBuilderPreviewToggleRequested(),
              ),
        ),
        // Save Button
        if (!state.isPreviewMode)
          TextButton.icon(
            onPressed: state.memorial != null
                ? () => _saveChanges(context, state.memorial!.id)
                : null,
            icon: state.status == PageBuilderStatus.saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save, color: Colors.white),
            label: const Text(
              'Speichern',
              style: TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildEditMode(PageBuilderState state) {
    return Row(
      children: [
        // Hauptbereich mit Blocks
        Expanded(
          flex: _showStylePanel ? 2 : 3,
          child: _buildBlocksList(state),
        ),

        // Style Editor Panel
        if (_showStylePanel && state.selectedBlock != null)
          Expanded(
            flex: 1,
            child: StyleEditorPanel(
              block: state.selectedBlock!,
              onClose: () => setState(() => _showStylePanel = false),
            ),
          ),
      ],
    );
  }

  Widget _buildBlocksList(PageBuilderState state) {
    if (state.blocks.isEmpty) {
      return _buildEmptyState(context);
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.blocks.length,
      onReorder: (oldIndex, newIndex) {
        context.read<PageBuilderBloc>().add(
              PageBuilderBlockReorderRequested(
                oldIndex: oldIndex,
                newIndex: newIndex > oldIndex ? newIndex - 1 : newIndex,
              ),
            );
      },
      itemBuilder: (context, index) {
        final block = state.blocks[index];
        final isSelected = block.id == state.selectedBlockId;

        return BlockPreviewCard(
          key: ValueKey(block.id),
          block: block,
          isSelected: isSelected,
          onTap: () {
            context.read<PageBuilderBloc>().add(
                  PageBuilderBlockSelectRequested(block.id),
                );
            setState(() => _showStylePanel = false);
          },
          onEdit: () => _editBlock(context, block),
          onStyle: () {
            context.read<PageBuilderBloc>().add(
                  PageBuilderBlockSelectRequested(block.id),
                );
            setState(() => _showStylePanel = true);
          },
          onDelete: () => _deleteBlock(context, block.id),
          onDuplicate: () => _duplicateBlock(context, block),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.web,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Noch keine Inhalte',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fügen Sie Ihren ersten Block hinzu',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddBlockSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Block hinzufügen'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewMode(PageBuilderState state) {
    return BlockPreviewScreen(blocks: state.blocks);
  }

  Widget _buildBottomBar(BuildContext context, PageBuilderState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${state.blocks.length} Block${state.blocks.length != 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _showTemplatesDialog(context),
                icon: const Icon(Icons.dashboard_customize),
                label: const Text('Templates'),
              ),
              const SizedBox(width: 8),
              if (state.selectedBlock != null)
                TextButton.icon(
                  onPressed: () {
                    context.read<PageBuilderBloc>().add(
                          const PageBuilderBlockSelectRequested(null),
                        );
                    setState(() => _showStylePanel = false);
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Auswahl aufheben'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddBlockSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddBlockBottomSheet(
        onBlockTypeSelected: (type) {
          context.read<PageBuilderBloc>().add(
                PageBuilderBlockAddRequested(blockType: type),
              );
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _editBlock(BuildContext context, ContentBlockModel block) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlockEditorPanel(block: block),
      ),
    );
  }

  void _deleteBlock(BuildContext context, String blockId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block löschen'),
        content: const Text(
          'Möchten Sie diesen Block wirklich löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<PageBuilderBloc>().add(
                    PageBuilderBlockDeleteRequested(blockId),
                  );
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _duplicateBlock(BuildContext context, ContentBlockModel block) {
    context.read<PageBuilderBloc>().add(
          PageBuilderBlockAddRequested(
            blockType: block.type,
            initialData: block.data,
          ),
        );
  }

  void _saveChanges(BuildContext context, String memorialId) {
    context.read<PageBuilderBloc>().add(
          PageBuilderSaveRequested(memorialId),
        );
  }

  void _showTemplatesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seitenvorlagen'),
        content: const Text(
          'Möchten Sie eine vorgefertigte Vorlage laden?\n\nAchtung: Ihre aktuellen Änderungen gehen dabei verloren.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Template-Auswahl implementieren
              Navigator.of(ctx).pop();
            },
            child: const Text('Vorlagen anzeigen'),
          ),
        ],
      ),
    );
  }
}

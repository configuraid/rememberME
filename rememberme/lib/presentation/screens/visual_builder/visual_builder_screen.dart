import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/data/models/content_block_model.dart';
import 'package:rememberme/data/models/memorial_page_model.dart';
import 'package:rememberme/business_logic/memorial/memorial_bloc.dart';
import 'package:rememberme/business_logic/memorial/memorial_event.dart';
import '../../widgets/page_builder/content_block_widget.dart';
import '../../widgets/page_builder/add_block_bottom_sheet.dart';
import '../../widgets/page_builder/block_settings_bottom_sheet.dart';

class IntuitivePageBuilderScreen extends StatefulWidget {
  final MemorialPageModel memorial;

  const IntuitivePageBuilderScreen({
    super.key,
    required this.memorial,
  });

  @override
  State<IntuitivePageBuilderScreen> createState() =>
      _IntuitivePageBuilderScreenState();
}

class _IntuitivePageBuilderScreenState
    extends State<IntuitivePageBuilderScreen> {
  List<ContentBlock> _blocks = [];
  String? _selectedBlockId;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadMemorialContent();
  }

  void _loadMemorialContent() {
    // ✅ Lade die ECHTEN Blöcke aus dem Memorial
    _blocks = List.from(widget.memorial.contentBlocks);
    print('📦 Geladene Blöcke: ${_blocks.length}');
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _showSuccessMessage(String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );

    // Auto-dismiss after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true; // Keine Änderungen, kann zurück
    }

    // Zeige Warnung bei ungespeicherten Änderungen
    final shouldPop = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Ungespeicherte Änderungen'),
        content: const Text(
          'Du hast ungespeicherte Änderungen. Möchtest du wirklich zurück?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Abbrechen'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Verwerfen'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(widget.memorial.name),
          centerTitle: true,
          actions: [
            // Unsaved changes indicator
            if (_hasUnsavedChanges)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.circle, color: Colors.orange, size: 12),
                ),
              ),
            // Preview
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: _showPreview,
              tooltip: 'Vorschau',
            ),
            // Save
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _save,
              tooltip: 'Speichern',
            ),
          ],
        ),
        body: _blocks.isEmpty ? _buildEmptyState() : _buildBlockList(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddBlockSheet,
          icon: const Icon(Icons.add),
          label: const Text('Block hinzufügen'),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Noch keine Inhalte',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Füge deinen ersten Block hinzu',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddBlockSheet,
            icon: const Icon(Icons.add),
            label: const Text('Block hinzufügen'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _blocks.length + 1, // +1 for add button at bottom
      onReorder: _reorderBlocks,
      itemBuilder: (context, index) {
        // Add button at bottom
        if (index == _blocks.length) {
          return _buildAddBlockButton(key: const ValueKey('add-button'));
        }

        final block = _blocks[index];
        final isSelected = block.id == _selectedBlockId;

        return ContentBlockWidget(
          key: ValueKey(block.id),
          block: block,
          isSelected: isSelected,
          onTap: () => _selectBlock(block.id),
          onEdit: () => _showBlockSettings(block),
          onDuplicate: () => _duplicateBlock(block),
          onDelete: () => _deleteBlock(block.id),
          onContentChanged: (key, value) =>
              _updateBlockContent(block.id, key, value),
        );
      },
    );
  }

  Widget _buildAddBlockButton({required Key key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(top: 16),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: _showAddBlockSheet,
          icon: const Icon(Icons.add),
          label: const Text('Weiteren Block hinzufügen'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
    );
  }

  // ===== BLOCK MANAGEMENT =====

  void _selectBlock(String blockId) {
    setState(() {
      _selectedBlockId = _selectedBlockId == blockId ? null : blockId;
    });
  }

  void _showAddBlockSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddBlockBottomSheet(
        onBlockTypeSelected: (type) {
          _addBlock(type);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _addBlock(ContentBlockType type) {
    setState(() {
      final newBlock = ContentBlock(type: type);
      _blocks.add(newBlock);
      _selectedBlockId = newBlock.id;
      _markAsChanged();
    });

    // Scroll to new block
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Show settings immediately for text/header blocks
      if (type == ContentBlockType.text || type == ContentBlockType.header) {
        _showBlockSettings(_blocks.last);
      }
    });
  }

  void _duplicateBlock(ContentBlock block) {
    setState(() {
      final duplicate = ContentBlock(
        type: block.type,
        content: Map<String, dynamic>.from(block.content),
      );
      final index = _blocks.indexWhere((b) => b.id == block.id);
      _blocks.insert(index + 1, duplicate);
      _selectedBlockId = duplicate.id;
      _markAsChanged();
    });
  }

  void _deleteBlock(String blockId) {
    // Confirm deletion
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block löschen?'),
        content: const Text('Möchtest du diesen Block wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _blocks.removeWhere((b) => b.id == blockId);
                if (_selectedBlockId == blockId) {
                  _selectedBlockId = null;
                }
                _markAsChanged();
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _reorderBlocks(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final block = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, block);
      _markAsChanged();
    });
  }

  void _updateBlockContent(String blockId, String key, dynamic value) {
    setState(() {
      final index = _blocks.indexWhere((b) => b.id == blockId);
      if (index != -1) {
        _blocks[index] = _blocks[index].updateContent(key, value);
        _markAsChanged();
      }
    });
  }

  void _showBlockSettings(ContentBlock block) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlockSettingsBottomSheet(
        block: block,
        onUpdate: (key, value) => _updateBlockContent(block.id, key, value),
      ),
    );
  }

  // ===== ACTIONS =====

  void _showPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PreviewScreen(
          memorial: widget.memorial,
          blocks: _blocks,
        ),
      ),
    );
  }

  void _save() {
    print('💾 Speichere ${_blocks.length} Blöcke...');

    // Erstelle aktualisiertes Memorial mit neuen Blöcken
    final updatedMemorial = widget.memorial.copyWith(
      contentBlocks: _blocks,
    );

    // ✅ Sende Update-Event ans BLoC
    context.read<MemorialBloc>().add(
          MemorialUpdateRequested(memorial: updatedMemorial),
        );

    setState(() {
      _hasUnsavedChanges = false;
    });

    _showSuccessMessage('✓ Seite gespeichert');

    // Optional: Nach 1.5 Sekunden zurück
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }
}

// ===== PREVIEW SCREEN =====

class _PreviewScreen extends StatelessWidget {
  final MemorialPageModel memorial;
  final List<ContentBlock> blocks;

  const _PreviewScreen({
    required this.memorial,
    required this.blocks,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Vorschau - ${memorial.name}'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: blocks.length,
        itemBuilder: (context, index) {
          return ContentBlockWidget(
            block: blocks[index],
            isSelected: false,
            isPreview: true,
            onTap: () {},
            onEdit: () {},
            onDuplicate: () {},
            onDelete: () {},
            onContentChanged: (_, __) {},
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../business_logic/page_builder/page_builder_bloc.dart';
import '../../../../business_logic/page_builder/page_builder_event.dart';
import '../../../../data/models/content_block_model.dart';
import 'hero_block_editor.dart';
import 'text_block_editor.dart';
import 'gallery_block_editor.dart';
import 'quote_block_editor.dart';
import 'timeline_block_editor.dart';

class BlockEditorPanel extends StatefulWidget {
  final ContentBlockModel block;

  const BlockEditorPanel({
    super.key,
    required this.block,
  });

  @override
  State<BlockEditorPanel> createState() => _BlockEditorPanelState();
}

class _BlockEditorPanelState extends State<BlockEditorPanel> {
  late Map<String, dynamic> _editedData;

  @override
  void initState() {
    super.initState();
    _editedData = Map.from(widget.block.data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getBlockName(widget.block.type)),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text(
              'Speichern',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildEditor(),
      ),
    );
  }

  Widget _buildEditor() {
    switch (widget.block.type) {
      case ContentBlockType.hero:
        return HeroBlockEditor(
          data: _editedData,
          onDataChanged: (data) => setState(() => _editedData = data),
        );
      case ContentBlockType.text:
        return TextBlockEditor(
          data: _editedData,
          onDataChanged: (data) => setState(() => _editedData = data),
        );
      case ContentBlockType.gallery:
        return GalleryBlockEditor(
          data: _editedData,
          onDataChanged: (data) => setState(() => _editedData = data),
        );
      case ContentBlockType.quote:
        return QuoteBlockEditor(
          data: _editedData,
          onDataChanged: (data) => setState(() => _editedData = data),
        );
      case ContentBlockType.timeline:
        return TimelineBlockEditor(
          data: _editedData,
          onDataChanged: (data) => setState(() => _editedData = data),
        );
      default:
        return const Center(
          child: Text('Editor für diesen Block-Typ nicht verfügbar'),
        );
    }
  }

  String _getBlockName(ContentBlockType type) {
    switch (type) {
      case ContentBlockType.hero:
        return 'Hero-Bild bearbeiten';
      case ContentBlockType.text:
        return 'Text bearbeiten';
      case ContentBlockType.gallery:
        return 'Galerie bearbeiten';
      case ContentBlockType.quote:
        return 'Zitat bearbeiten';
      case ContentBlockType.timeline:
        return 'Zeitleiste bearbeiten';
      default:
        return 'Block bearbeiten';
    }
  }

  void _saveChanges() {
    context.read<PageBuilderBloc>().add(
          PageBuilderBlockUpdateRequested(
            blockId: widget.block.id,
            data: _editedData,
          ),
        );
    Navigator.of(context).pop();
  }
}

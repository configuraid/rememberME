// lib/data/repositories/page_builder_repository.dart

import 'package:rememberme/data/models/content_block_model.dart';

import '../models/memorial_page_model.dart';

class PageBuilderRepository {
  /// Load memorial with its content blocks
  Future<MemorialPageModel> getMemorial(String memorialId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    print('📦 PageBuilderRepository - Lade Memorial: $memorialId');

    // TODO: Replace with actual API call
    // Example: final response = await http.get('/api/memorials/$memorialId');

    // For now, return mock memorial with example blocks
    return MemorialPageModel(
      id: memorialId,
      ownerId: 'user-1',
      name: 'Max Mustermann',
      subtitle: 'In liebevoller Erinnerung',
      birthDate: DateTime(1950, 1, 1),
      deathDate: DateTime(2024, 1, 1),
      profileImageUrl: 'https://via.placeholder.com/400',
      templateId: 'template1',
      isPublished: false,
      status: MemorialStatus.draft,
      privacyLevel: PrivacyLevel.private,
      contentBlocks: _getExampleBlocks(),
      viewCount: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now(),
    );
  }

  /// Get example/starter blocks for a new memorial
  List<ContentBlock> _getExampleBlocks() {
    return [
      // Header block
      ContentBlock(
        type: ContentBlockType.header,
        content: {
          'text': 'Max Mustermann',
          'level': 1,
          'align': 'center',
          'color': '#2C3E50',
        },
      ),

      // Date block
      ContentBlock(
        type: ContentBlockType.date,
        content: {
          'birthDate': '01.01.1950',
          'deathDate': '01.01.2024',
          'format': 'DD.MM.YYYY',
        },
      ),

      // Text block
      ContentBlock(
        type: ContentBlockType.text,
        content: {
          'text': 'Hier kannst du über das Leben erzählen...',
          'fontSize': 16.0,
          'align': 'left',
          'color': '#333333',
        },
      ),
    ];
  }

  /// Save content blocks to memorial
  Future<void> saveBlocks({
    required String memorialId,
    required List<ContentBlock> blocks,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    print(
        '💾 PageBuilderRepository - Speichere ${blocks.length} Blocks für Memorial: $memorialId');

    // TODO: Replace with actual API call
    // Example:
    // final json = blocks.map((b) => b.toJson()).toList();
    // await http.put(
    //   '/api/memorials/$memorialId/blocks',
    //   body: jsonEncode({'blocks': json}),
    // );

    // Simulate success
    print('✅ PageBuilderRepository - Blocks erfolgreich gespeichert');
  }

  /// Load a specific block by ID
  Future<ContentBlock?> getBlock(String memorialId, String blockId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    print('📦 PageBuilderRepository - Lade Block: $blockId');

    final memorial = await getMemorial(memorialId);
    try {
      final block = memorial.contentBlocks.firstWhere((b) => b.id == blockId);
      print('✅ PageBuilderRepository - Block gefunden: ${block.type.name}');
      return block;
    } catch (e) {
      print('❌ PageBuilderRepository - Block nicht gefunden: $blockId');
      return null;
    }
  }

  /// Add a single block
  Future<ContentBlock> addBlock({
    required String memorialId,
    required ContentBlock block,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    print('➕ PageBuilderRepository - Füge Block hinzu: ${block.type.name}');

    // TODO: API call to add block
    // Example:
    // final response = await http.post(
    //   '/api/memorials/$memorialId/blocks',
    //   body: jsonEncode(block.toJson()),
    // );

    print('✅ PageBuilderRepository - Block hinzugefügt: ${block.id}');
    return block;
  }

  /// Update a single block
  Future<ContentBlock> updateBlock({
    required String memorialId,
    required ContentBlock block,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    print('🔄 PageBuilderRepository - Aktualisiere Block: ${block.id}');

    // TODO: API call to update block
    // Example:
    // await http.put(
    //   '/api/memorials/$memorialId/blocks/${block.id}',
    //   body: jsonEncode(block.toJson()),
    // );

    print('✅ PageBuilderRepository - Block aktualisiert');
    return block;
  }

  /// Delete a single block
  Future<void> deleteBlock({
    required String memorialId,
    required String blockId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    print('🗑️ PageBuilderRepository - Lösche Block: $blockId');

    // TODO: API call to delete block
    // Example:
    // await http.delete('/api/memorials/$memorialId/blocks/$blockId');

    print('✅ PageBuilderRepository - Block gelöscht');
  }

  /// Reorder blocks
  Future<void> reorderBlocks({
    required String memorialId,
    required List<String> blockIds,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    print('🔀 PageBuilderRepository - Sortiere ${blockIds.length} Blocks neu');

    // TODO: API call to reorder
    // Example:
    // await http.put(
    //   '/api/memorials/$memorialId/blocks/reorder',
    //   body: jsonEncode({'blockIds': blockIds}),
    // );

    print('✅ PageBuilderRepository - Blocks neu sortiert');
  }

  /// Duplicate a block
  Future<ContentBlock> duplicateBlock({
    required String memorialId,
    required String blockId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    print('📋 PageBuilderRepository - Dupliziere Block: $blockId');

    // Get original block
    final original = await getBlock(memorialId, blockId);
    if (original == null) {
      throw Exception('Block nicht gefunden: $blockId');
    }

    // Create duplicate with new ID
    final duplicate = ContentBlock(
      type: original.type,
      content: Map<String, dynamic>.from(original.content),
    );

    // TODO: API call to save duplicate
    // await addBlock(memorialId: memorialId, block: duplicate);

    print('✅ PageBuilderRepository - Block dupliziert: ${duplicate.id}');
    return duplicate;
  }

  /// Get template blocks for a specific template
  Future<List<ContentBlock>> getTemplateBlocks(String templateId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    print('📋 PageBuilderRepository - Lade Template: $templateId');

    // TODO: API call to get template blocks
    // Example:
    // final response = await http.get('/api/templates/$templateId/blocks');

    // Return example template blocks based on template ID
    switch (templateId) {
      case 'classic':
        return _getClassicTemplate();
      case 'modern':
        return _getModernTemplate();
      case 'minimal':
        return _getMinimalTemplate();
      default:
        return [];
    }
  }

  List<ContentBlock> _getClassicTemplate() {
    return [
      ContentBlock(
        type: ContentBlockType.header,
        content: {
          'text': 'In liebevollem Gedenken',
          'level': 1,
          'align': 'center',
          'color': '#2C3E50',
        },
      ),
      ContentBlock(
        type: ContentBlockType.date,
        content: {
          'birthDate': '',
          'deathDate': '',
        },
      ),
      ContentBlock(
        type: ContentBlockType.text,
        content: {
          'text': 'Hier kannst du die Geschichte erzählen...',
          'fontSize': 16.0,
          'align': 'left',
          'color': '#333333',
        },
      ),
      ContentBlock(
        type: ContentBlockType.gallery,
        content: {
          'images': [],
          'columns': 3,
        },
      ),
      ContentBlock(
        type: ContentBlockType.quote,
        content: {
          'text': 'Ein bedeutsames Zitat...',
          'author': '',
          'color': '#666666',
        },
      ),
    ];
  }

  List<ContentBlock> _getModernTemplate() {
    return [
      ContentBlock(
        type: ContentBlockType.image,
        content: {
          'url': '',
          'caption': '',
          'fit': 'cover',
        },
      ),
      ContentBlock(
        type: ContentBlockType.header,
        content: {
          'text': 'Name der Person',
          'level': 1,
          'align': 'left',
          'color': '#1A1A1A',
        },
      ),
      ContentBlock(
        type: ContentBlockType.date,
        content: {
          'birthDate': '',
          'deathDate': '',
        },
      ),
      ContentBlock(
        type: ContentBlockType.divider,
        content: {
          'color': '#E0E0E0',
          'thickness': 2.0,
          'margin': 20.0,
        },
      ),
      ContentBlock(
        type: ContentBlockType.text,
        content: {
          'text': 'Eine kurze Biografie...',
          'fontSize': 18.0,
          'align': 'left',
          'color': '#333333',
        },
      ),
    ];
  }

  List<ContentBlock> _getMinimalTemplate() {
    return [
      ContentBlock(
        type: ContentBlockType.header,
        content: {
          'text': 'Name',
          'level': 2,
          'align': 'center',
          'color': '#000000',
        },
      ),
      ContentBlock(
        type: ContentBlockType.date,
        content: {
          'birthDate': '',
          'deathDate': '',
        },
      ),
      ContentBlock(
        type: ContentBlockType.text,
        content: {
          'text': 'In stillem Gedenken...',
          'fontSize': 16.0,
          'align': 'center',
          'color': '#666666',
        },
      ),
    ];
  }

  /// Export blocks as JSON
  Future<Map<String, dynamic>> exportBlocks({
    required String memorialId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    print('📤 PageBuilderRepository - Exportiere Blocks für: $memorialId');

    final memorial = await getMemorial(memorialId);
    final blocksJson = memorial.contentBlocks.map((b) => b.toJson()).toList();

    final export = {
      'memorialId': memorialId,
      'exportedAt': DateTime.now().toIso8601String(),
      'blockCount': memorial.contentBlocks.length,
      'blocks': blocksJson,
    };

    print(
        '✅ PageBuilderRepository - ${export['blockCount']} Blocks exportiert');
    return export;
  }

  /// Import blocks from JSON
  Future<List<ContentBlock>> importBlocks({
    required String memorialId,
    required Map<String, dynamic> data,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    print('📥 PageBuilderRepository - Importiere Blocks für: $memorialId');

    final blocksData = data['blocks'] as List;
    final blocks = blocksData
        .map((json) => ContentBlock.fromJson(json as Map<String, dynamic>))
        .toList();

    // Save imported blocks
    await saveBlocks(memorialId: memorialId, blocks: blocks);

    print('✅ PageBuilderRepository - ${blocks.length} Blocks importiert');
    return blocks;
  }

  /// Validate blocks before saving
  bool validateBlocks(List<ContentBlock> blocks) {
    if (blocks.isEmpty) {
      print('⚠️ PageBuilderRepository - Keine Blocks zum Validieren');
      return false;
    }

    // Check for required block types
    final hasHeader = blocks.any((b) =>
        b.type == ContentBlockType.header || b.type == ContentBlockType.text);

    if (!hasHeader) {
      print('⚠️ PageBuilderRepository - Kein Header/Text Block gefunden');
      return false;
    }

    // Validate each block's content
    for (final block in blocks) {
      if (block.content.isEmpty) {
        print('⚠️ PageBuilderRepository - Block ${block.id} hat keinen Inhalt');
        return false;
      }
    }

    print('✅ PageBuilderRepository - ${blocks.length} Blocks sind valide');
    return true;
  }
}

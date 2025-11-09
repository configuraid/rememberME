import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rememberme/data/models/content_block_model.dart';
import '../models/memorial_page_model.dart';
import 'package:uuid/uuid.dart';

class PageBuilderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Load memorial with its content blocks
  Future<MemorialPageModel?> getMemorial(String memorialId) async {
    print('📦 PageBuilderRepository - Lade Memorial: $memorialId');

    try {
      final doc =
          await _firestore.collection('memorials').doc(memorialId).get();

      if (!doc.exists) {
        print('❌ PageBuilderRepository - Memorial nicht gefunden');
        return null;
      }

      final memorial =
          MemorialPageModel.fromJson({...doc.data()!, 'id': doc.id});
      print('✅ PageBuilderRepository - Memorial geladen: ${memorial.name}');
      print(
          '📊 PageBuilderRepository - ${memorial.contentBlocks.length} Blocks');
      return memorial;
    } catch (e) {
      print('❌ PageBuilderRepository - Fehler beim Laden: $e');
      return null;
    }
  }

  /// Save content blocks to memorial
  Future<void> saveBlocks({
    required String memorialId,
    required List<ContentBlock> blocks,
  }) async {
    print(
        '💾 PageBuilderRepository - Speichere ${blocks.length} Blocks für Memorial: $memorialId');

    try {
      // Konvertiere Blocks zu JSON
      final blocksJson = blocks.map((b) => b.toJson()).toList();

      // Update Memorial mit neuen Blocks
      await _firestore.collection('memorials').doc(memorialId).update({
        'contentBlocks': blocksJson,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ PageBuilderRepository - Blocks erfolgreich gespeichert');
    } catch (e) {
      print('❌ PageBuilderRepository - Fehler beim Speichern: $e');
      rethrow;
    }
  }

  /// Load a specific block by ID
  Future<ContentBlock?> getBlock(String memorialId, String blockId) async {
    print('📦 PageBuilderRepository - Lade Block: $blockId');

    try {
      final memorial = await getMemorial(memorialId);
      if (memorial == null) {
        print('❌ PageBuilderRepository - Memorial nicht gefunden');
        return null;
      }

      final block =
          memorial.contentBlocks.firstWhere((b) => b.id == blockId, orElse: () {
        throw Exception('Block nicht gefunden: $blockId');
      });

      print('✅ PageBuilderRepository - Block gefunden: ${block.type.name}');
      return block;
    } catch (e) {
      print('❌ PageBuilderRepository - Fehler: $e');
      return null;
    }
  }

  /// Add a single block
  Future<ContentBlock> addBlock({
    required String memorialId,
    required ContentBlock block,
  }) async {
    print('➕ PageBuilderRepository - Füge Block hinzu: ${block.type.name}');

    try {
      final memorial = await getMemorial(memorialId);
      if (memorial == null) {
        throw Exception('Memorial nicht gefunden');
      }

      // Füge Block zur Liste hinzu
      final updatedBlocks = [...memorial.contentBlocks, block];

      // Speichere aktualisierte Blocks
      await saveBlocks(memorialId: memorialId, blocks: updatedBlocks);

      print('✅ PageBuilderRepository - Block hinzugefügt: ${block.id}');
      return block;
    } catch (e) {
      print('❌ PageBuilderRepository - Fehler: $e');
      rethrow;
    }
  }

  /// Update a single block
  Future<ContentBlock> updateBlock({
    required String memorialId,
    required ContentBlock block,
  }) async {
    print('🔄 PageBuilderRepository - Aktualisiere Block: ${block.id}');

    try {
      final memorial = await getMemorial(memorialId);
      if (memorial == null) {
        throw Exception('Memorial nicht gefunden');
      }

      // Aktualisiere Block in der Liste
      final updatedBlocks = memorial.contentBlocks.map((b) {
        return b.id == block.id ? block : b;
      }).toList();

      // Speichere aktualisierte Blocks
      await saveBlocks(memorialId: memorialId, blocks: updatedBlocks);

      print('✅ PageBuilderRepository - Block aktualisiert');
      return block;
    } catch (e) {
      print('❌ PageBuilderRepository - Fehler: $e');
      rethrow;
    }
  }

  /// Delete a single block
  Future<void> deleteBlock({
    required String memorialId,
    required String blockId,
  }) async {
    print('🗑️ PageBuilderRepository - Lösche Block: $blockId');

    try {
      final memorial = await getMemorial(memorialId);
      if (memorial == null) {
        throw Exception('Memorial nicht gefunden');
      }

      // Entferne Block aus der Liste
      final updatedBlocks =
          memorial.contentBlocks.where((b) => b.id != blockId).toList();

      // Speichere aktualisierte Blocks
      await saveBlocks(memorialId: memorialId, blocks: updatedBlocks);

      print('✅ PageBuilderRepository - Block gelöscht');
    } catch (e) {
      print('❌ PageBuilderRepository - Fehler: $e');
      rethrow;
    }
  }

  /// Reorder blocks
  Future<void> reorderBlocks({
    required String memorialId,
    required List<String> blockIds,
  }) async {
    print('🔀 PageBuilderRepository - Sortiere ${blockIds.length} Blocks neu');

    try {
      final memorial = await getMemorial(memorialId);
      if (memorial == null) {
        throw Exception('Memorial nicht gefunden');
      }

      // Erstelle neue Block-Liste in der richtigen Reihenfolge
      final reorderedBlocks = <ContentBlock>[];
      for (var blockId in blockIds) {
        final block = memorial.contentBlocks.firstWhere(
          (b) => b.id == blockId,
          orElse: () => throw Exception('Block nicht gefunden: $blockId'),
        );
        reorderedBlocks.add(block);
      }

      // Speichere neu sortierte Blocks
      await saveBlocks(memorialId: memorialId, blocks: reorderedBlocks);

      print('✅ PageBuilderRepository - Blocks neu sortiert');
    } catch (e) {
      print('❌ PageBuilderRepository - Fehler: $e');
      rethrow;
    }
  }

  /// Duplicate a block
  Future<ContentBlock> duplicateBlock({
    required String memorialId,
    required String blockId,
  }) async {
    print('📋 PageBuilderRepository - Dupliziere Block: $blockId');

    try {
      // Get original block
      final original = await getBlock(memorialId, blockId);
      if (original == null) {
        throw Exception('Block nicht gefunden: $blockId');
      }

      // Create duplicate with new ID
      final duplicate = ContentBlock(
        id: _uuid.v4(),
        type: original.type,
        content: Map<String, dynamic>.from(original.content),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add duplicate to memorial
      await addBlock(memorialId: memorialId, block: duplicate);

      print('✅ PageBuilderRepository - Block dupliziert: ${duplicate.id}');
      return duplicate;
    } catch (e) {
      print('❌ PageBuilderRepository - Fehler: $e');
      rethrow;
    }
  }

  /// Get template blocks for a specific template
  Future<List<ContentBlock>> getTemplateBlocks(String templateId) async {
    print('📋 PageBuilderRepository - Lade Template: $templateId');

    // Return example template blocks based on template ID
    switch (templateId) {
      case 'classic':
        return _getClassicTemplate();
      case 'modern':
        return _getModernTemplate();
      case 'minimal':
        return _getMinimalTemplate();
      default:
        return _getClassicTemplate();
    }
  }

  List<ContentBlock> _getClassicTemplate() {
    final now = DateTime.now();
    return [
      ContentBlock(
        id: _uuid.v4(),
        type: ContentBlockType.header,
        content: {
          'text': 'In liebevollem Gedenken',
          'level': 1,
          'align': 'center',
          'color': '#2C3E50',
        },
        createdAt: now,
        updatedAt: now,
      ),
      ContentBlock(
        id: _uuid.v4(),
        type: ContentBlockType.date,
        content: {
          'birthDate': '',
          'deathDate': '',
        },
        createdAt: now,
        updatedAt: now,
      ),
      ContentBlock(
        id: _uuid.v4(),
        type: ContentBlockType.text,
        content: {
          'text': 'Hier kannst du die Geschichte erzählen...',
          'fontSize': 16.0,
          'align': 'left',
          'color': '#333333',
        },
        createdAt: now,
        updatedAt: now,
      ),
      ContentBlock(
        id: _uuid.v4(),
        type: ContentBlockType.gallery,
        content: {
          'images': [],
          'columns': 3,
        },
        createdAt: now,
        updatedAt: now,
      ),
      ContentBlock(
        id: _uuid.v4(),
        type: ContentBlockType.quote,
        content: {
          'text': 'Ein bedeutsames Zitat...',
          'author': '',
          'color': '#666666',
        },
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  List<ContentBlock> _getModernTemplate() {
    final now = DateTime.now();
    return [
      ContentBlock(
        id: _uuid.v4(),
        type: ContentBlockType.image,
        content: {
          'url': '',
          'caption': '',
          'fit': 'cover',
        },
        createdAt: now,
        updatedAt: now,
      ),
      ContentBlock(
        id: _uuid.v4(),
        type: ContentBlockType.header,
        content: {
          'text': 'Name der Person',
          'level': 1,
          'align': 'left',
          'color': '#1A1A1A',
        },
        createdAt: now,
        updatedAt: now,
      ),
      ContentBlock(
        id: _uuid.v4(),
        type: ContentBlockType.date,
        content: {
          'birthDate': '',
          'deathDate': '',
        },
        createdAt: now,
        updatedAt: now,
      ),
      ContentBlock(
        id: _uuid.v4(),
        type: ContentBlockType.divider,
        content: {
          'color': '#E0E0E0',
          'thickness': 2.0,
          'margin': 20.0,
        },
        createdAt: now,
        updatedAt: now,
      ),
      ContentBlock(
        id: _uuid.v4(),
        type: ContentBlockType.text,
        content: {
          'text': 'Eine kurze Biografie...',
          'fontSize': 18.0,
          'align': 'left',
          'color': '#333333',
        },
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  List<ContentBlock> _getMinimalTemplate() {
    final now = DateTime.now();
    return [
      ContentBlock(
        id: _uuid.v4(),
        type: ContentBlockType.header,
        content: {
          'text': 'Name',
          'level': 2,
          'align': 'center',
          'color': '#000000',
        },
        createdAt: now,
        updatedAt: now,
      ),
      ContentBlock(
        id: _uuid.v4(),
        type: ContentBlockType.date,
        content: {
          'birthDate': '',
          'deathDate': '',
        },
        createdAt: now,
        updatedAt: now,
      ),
      ContentBlock(
        id: _uuid.v4(),
        type: ContentBlockType.text,
        content: {
          'text': 'In stillem Gedenken...',
          'fontSize': 16.0,
          'align': 'center',
          'color': '#666666',
        },
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Export blocks as JSON
  Future<Map<String, dynamic>> exportBlocks({
    required String memorialId,
  }) async {
    print('📤 PageBuilderRepository - Exportiere Blocks für: $memorialId');

    try {
      final memorial = await getMemorial(memorialId);
      if (memorial == null) {
        throw Exception('Memorial nicht gefunden');
      }

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
    } catch (e) {
      print('❌ PageBuilderRepository - Fehler: $e');
      rethrow;
    }
  }

  /// Import blocks from JSON
  Future<List<ContentBlock>> importBlocks({
    required String memorialId,
    required Map<String, dynamic> data,
  }) async {
    print('📥 PageBuilderRepository - Importiere Blocks für: $memorialId');

    try {
      final blocksData = data['blocks'] as List;
      final blocks = blocksData
          .map((json) => ContentBlock.fromJson(json as Map<String, dynamic>))
          .toList();

      // Save imported blocks
      await saveBlocks(memorialId: memorialId, blocks: blocks);

      print('✅ PageBuilderRepository - ${blocks.length} Blocks importiert');
      return blocks;
    } catch (e) {
      print('❌ PageBuilderRepository - Fehler: $e');
      rethrow;
    }
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

  /// Auto-save functionality
  Future<void> autoSave({
    required String memorialId,
    required List<ContentBlock> blocks,
  }) async {
    print('💾 PageBuilderRepository - Auto-Save für: $memorialId');

    try {
      if (!validateBlocks(blocks)) {
        print(
            '⚠️ PageBuilderRepository - Auto-Save übersprungen (Validierung fehlgeschlagen)');
        return;
      }

      await saveBlocks(memorialId: memorialId, blocks: blocks);
      print('✅ PageBuilderRepository - Auto-Save erfolgreich');
    } catch (e) {
      print('❌ PageBuilderRepository - Auto-Save Fehler: $e');
      // Auto-save errors sollten nicht die App crashen
    }
  }
}

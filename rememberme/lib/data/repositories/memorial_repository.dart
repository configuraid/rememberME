import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/memorial_page_model.dart';
import '../models/content_block_model.dart';
import 'package:uuid/uuid.dart';

class MemorialRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  MemorialRepository();

  // ========== MEMORIALS NACH ORGANISATION ==========

  /// Alle Gedenkseiten einer Organisation abrufen
  Future<List<MemorialPageModel>> getMemorialsByOrganization(
      String organizationId) async {
    print('🔍 Repository - Lade Memorials für Organisation: $organizationId');

    try {
      final querySnapshot = await _firestore
          .collection('memorials')
          .where('organizationId', isEqualTo: organizationId)
          .orderBy('createdAt',
              descending: true) // ✅ GEÄNDERT: createdAt statt updatedAt
          .get();

      print(
          '📊 Repository - Query Result: ${querySnapshot.docs.length} Dokumente');

      final memorials = querySnapshot.docs.map((doc) {
        final data = {...doc.data(), 'id': doc.id};
        print('📄 Repository - Doc: ${doc.id}');
        print('   → Data: $data');
        return MemorialPageModel.fromJson(data);
      }).toList();

      print('✅ Repository - ${memorials.length} Memorial(s) gefunden');
      return memorials;
    } catch (e, stackTrace) {
      print('❌ Repository - Fehler beim Laden der Memorials: $e');
      print('📚 StackTrace: $stackTrace');
      return [];
    }
  }

  // ========== EINZELNE GEDENKSEITE ==========

  /// Einzelne Gedenkseite abrufen
  Future<MemorialPageModel?> getMemorialById(String memorialId) async {
    print('🔍 Repository - Lade Memorial: $memorialId');

    try {
      final doc =
          await _firestore.collection('memorials').doc(memorialId).get();

      if (!doc.exists) {
        print('❌ Repository - Memorial nicht gefunden: $memorialId');
        return null;
      }

      final memorial =
          MemorialPageModel.fromJson({...doc.data()!, 'id': doc.id});
      print('✅ Repository - Memorial gefunden: ${memorial.name}');
      print('   → ContentBlocks: ${memorial.contentBlocks.length}');
      return memorial;
    } catch (e) {
      print('❌ Repository - Fehler: $e');
      return null;
    }
  }

  // ========== ERSTELLEN ==========

  /// Neue Gedenkseite erstellen
  Future<MemorialPageModel> createMemorial({
    required String organizationId,
    required String ownerId,
    required String name,
    required String templateId,
    DateTime? birthDate,
    DateTime? deathDate,
  }) async {
    print('➕ Repository - Erstelle neue Gedenkseite: $name');
    print('📍 Organisation: $organizationId');
    print('👤 Owner: $ownerId');

    final now = DateTime.now();
    final newId = _uuid.v4();

    final newMemorial = MemorialPageModel(
      id: newId,
      organizationId: organizationId,
      ownerId: ownerId,
      name: name,
      subtitle: 'In liebevoller Erinnerung',
      birthDate: birthDate,
      deathDate: deathDate,
      templateId: templateId,
      privacyLevel: PrivacyLevel.private,
      createdAt: now,
      contentBlocks: [
        ContentBlock(
          id: _uuid.v4(),
          type: ContentBlockType.header,
        ),
      ],
    );

    try {
      // ✅ DEBUG: Zeige das JSON das gespeichert wird
      final jsonData = newMemorial.toJson();
      print('🔍 Zu speicherndes JSON:');
      print('   id: ${jsonData['id']}');
      print('   name: ${jsonData['name']}');
      print('   organizationId: ${jsonData['organizationId']}');
      print('   contentBlocks: ${jsonData['contentBlocks']}');

      // 1. Memorial in Firestore speichern
      await _firestore.collection('memorials').doc(newId).set(jsonData);

      // 2. Memorial-ID zur Organisation hinzufügen
      await _firestore.collection('organizations').doc(organizationId).update({
        'memorialIds': FieldValue.arrayUnion([newId]),
      });

      print('✅ Repository - Memorial erstellt: ${newMemorial.id}');
      print('✅ Repository - Memorial zur Organisation hinzugefügt');

      return newMemorial;
    } catch (e, stackTrace) {
      print('❌ Repository - Fehler beim Erstellen: $e');
      print('📚 StackTrace: $stackTrace');
      rethrow;
    }
  }

  // ========== AKTUALISIEREN ==========

  /// Gedenkseite aktualisieren
  Future<MemorialPageModel> updateMemorial(MemorialPageModel memorial) async {
    print(
        '🔄 Repository - Aktualisiere Memorial: ${memorial.name} (${memorial.id})');
    print('   → ContentBlocks: ${memorial.contentBlocks.length}');

    try {
      final jsonData = memorial.toJson();

      print('🔍 Update JSON:');
      print('   contentBlocks: ${jsonData['contentBlocks']}');

      await _firestore
          .collection('memorials')
          .doc(memorial.id)
          .update(jsonData);

      print('✅ Repository - Memorial aktualisiert');
      return memorial;
    } catch (e, stackTrace) {
      print('❌ Repository - Fehler beim Aktualisieren: $e');
      print('📚 StackTrace: $stackTrace');
      rethrow;
    }
  }

  // ========== LÖSCHEN ==========

  /// Gedenkseite löschen
  Future<void> deleteMemorial(String memorialId) async {
    print('🗑️ Repository - Lösche Memorial: $memorialId');

    try {
      // 1. Lade Memorial um organizationId zu bekommen
      final memorial = await getMemorialById(memorialId);
      if (memorial == null) {
        throw Exception('Memorial nicht gefunden');
      }

      // 2. Lösche Memorial
      await _firestore.collection('memorials').doc(memorialId).delete();

      // 3. Entferne Memorial-ID aus Organisation
      await _firestore
          .collection('organizations')
          .doc(memorial.organizationId)
          .update({
        'memorialIds': FieldValue.arrayRemove([memorialId]),
      });

      print('✅ Repository - Memorial gelöscht');
      print('✅ Repository - Memorial aus Organisation entfernt');
    } catch (e, stackTrace) {
      print('❌ Repository - Fehler beim Löschen: $e');
      print('📚 StackTrace: $stackTrace');
      rethrow;
    }
  }

  // ========== CONTENT BLOCKS ==========

  /// Content-Block hinzufügen
  Future<MemorialPageModel> addContentBlock(
    String memorialId,
    ContentBlock block,
  ) async {
    print('➕ Repository - Füge Content-Block hinzu: ${block.type}');

    try {
      final memorial = await getMemorialById(memorialId);
      if (memorial == null) {
        throw Exception('Gedenkseite nicht gefunden');
      }

      final updatedBlocks = [...memorial.contentBlocks, block];
      final updatedMemorial = memorial.copyWith(contentBlocks: updatedBlocks);

      await updateMemorial(updatedMemorial);

      print(
          '✅ Repository - Block hinzugefügt, nun ${updatedBlocks.length} Blocks');
      return updatedMemorial;
    } catch (e) {
      print('❌ Repository - Fehler: $e');
      rethrow;
    }
  }

  /// Content-Block aktualisieren
  Future<MemorialPageModel> updateContentBlock(
    String memorialId,
    ContentBlock block,
  ) async {
    print('🔄 Repository - Aktualisiere Content-Block: ${block.id}');

    try {
      final memorial = await getMemorialById(memorialId);
      if (memorial == null) {
        throw Exception('Gedenkseite nicht gefunden');
      }

      final updatedBlocks = memorial.contentBlocks.map((b) {
        return b.id == block.id ? block : b;
      }).toList();

      final updatedMemorial = memorial.copyWith(contentBlocks: updatedBlocks);
      await updateMemorial(updatedMemorial);

      print('✅ Repository - Block aktualisiert');
      return updatedMemorial;
    } catch (e) {
      print('❌ Repository - Fehler: $e');
      rethrow;
    }
  }

  /// Content-Block löschen
  Future<MemorialPageModel> deleteContentBlock(
    String memorialId,
    String blockId,
  ) async {
    print('🗑️ Repository - Lösche Content-Block: $blockId');

    try {
      final memorial = await getMemorialById(memorialId);
      if (memorial == null) {
        throw Exception('Gedenkseite nicht gefunden');
      }

      final countBefore = memorial.contentBlocks.length;
      final updatedBlocks =
          memorial.contentBlocks.where((b) => b.id != blockId).toList();

      final updatedMemorial = memorial.copyWith(contentBlocks: updatedBlocks);
      await updateMemorial(updatedMemorial);

      print(
          '✅ Repository - Block gelöscht, ${countBefore} → ${updatedBlocks.length} Blocks');
      return updatedMemorial;
    } catch (e) {
      print('❌ Repository - Fehler: $e');
      rethrow;
    }
  }

  /// Content-Blocks neu sortieren
  Future<MemorialPageModel> reorderContentBlocks(
    String memorialId,
    List<String> blockIds,
  ) async {
    print('🔀 Repository - Sortiere ${blockIds.length} Content-Blocks neu');

    try {
      final memorial = await getMemorialById(memorialId);
      if (memorial == null) {
        throw Exception('Gedenkseite nicht gefunden');
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

      final updatedMemorial = memorial.copyWith(contentBlocks: reorderedBlocks);
      await updateMemorial(updatedMemorial);

      print('✅ Repository - Blocks neu sortiert');
      return updatedMemorial;
    } catch (e) {
      print('❌ Repository - Fehler: $e');
      rethrow;
    }
  }

  // ========== VERÖFFENTLICHEN ==========

  /// Gedenkseite veröffentlichen
  Future<MemorialPageModel> publishMemorial(String memorialId) async {
    print('🌐 Repository - Veröffentliche Memorial: $memorialId');

    try {
      final memorial = await getMemorialById(memorialId);
      if (memorial == null) {
        throw Exception('Gedenkseite nicht gefunden');
      }

      // Validierung
      if (memorial.contentBlocks.isEmpty) {
        throw Exception('Gedenkseite muss mindestens einen Block enthalten');
      }

      final updatedMemorial = memorial.copyWith();

      await updateMemorial(updatedMemorial);

      print('✅ Repository - Memorial veröffentlicht');
      return updatedMemorial;
    } catch (e) {
      print('❌ Repository - Fehler: $e');
      rethrow;
    }
  }

  /// Gedenkseite zurück in Entwurf
  Future<MemorialPageModel> unpublishMemorial(String memorialId) async {
    print('📝 Repository - Zurück zu Entwurf: $memorialId');

    try {
      final memorial = await getMemorialById(memorialId);
      if (memorial == null) {
        throw Exception('Gedenkseite nicht gefunden');
      }

      final updatedMemorial = memorial.copyWith();

      await updateMemorial(updatedMemorial);

      print('✅ Repository - Memorial ist nun Entwurf');
      return updatedMemorial;
    } catch (e) {
      print('❌ Repository - Fehler: $e');
      rethrow;
    }
  }

  /// Gedenkseite archivieren
  Future<MemorialPageModel> archiveMemorial(String memorialId) async {
    print('📦 Repository - Archiviere Memorial: $memorialId');

    try {
      final memorial = await getMemorialById(memorialId);
      if (memorial == null) {
        throw Exception('Gedenkseite nicht gefunden');
      }

      final updatedMemorial = memorial.copyWith();

      await updateMemorial(updatedMemorial);

      print('✅ Repository - Memorial archiviert');
      return updatedMemorial;
    } catch (e) {
      print('❌ Repository - Fehler: $e');
      rethrow;
    }
  }
}

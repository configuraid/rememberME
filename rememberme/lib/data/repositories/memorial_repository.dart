import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/memorial_page_model.dart';
import '../models/content_block_model.dart';
import 'package:uuid/uuid.dart';

class MemorialRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  MemorialRepository() {
    // Mock-Daten nicht mehr standardmäßig laden
  }

  // ========== MEMORIALS NACH ORGANISATION ==========

  /// Alle Gedenkseiten einer Organisation abrufen
  Future<List<MemorialPageModel>> getMemorialsByOrganization(
      String organizationId) async {
    print('🔍 Repository - Lade Memorials für Organisation: $organizationId');

    try {
      final querySnapshot = await _firestore
          .collection('memorials')
          .where('organizationId', isEqualTo: organizationId)
          .orderBy('updatedAt', descending: true)
          .get();

      final memorials = querySnapshot.docs
          .map((doc) =>
              MemorialPageModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      print('✅ Repository - ${memorials.length} Memorial(s) gefunden');
      return memorials;
    } catch (e) {
      print('❌ Repository - Fehler beim Laden der Memorials: $e');
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
      status: MemorialStatus.draft,
      isPublished: false,
      privacyLevel: PrivacyLevel.private,
      createdAt: now,
      updatedAt: now,
      contentBlocks: [
        ContentBlock(
          id: _uuid.v4(),
          type: ContentBlockType.header,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    try {
      // 1. Memorial in Firestore speichern
      await _firestore
          .collection('memorials')
          .doc(newId)
          .set(newMemorial.toJson());

      // 2. Memorial-ID zur Organisation hinzufügen
      await _firestore.collection('organizations').doc(organizationId).update({
        'memorialIds': FieldValue.arrayUnion([newId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Repository - Memorial erstellt: ${newMemorial.id}');
      print('✅ Repository - Memorial zur Organisation hinzugefügt');
      return newMemorial;
    } catch (e) {
      print('❌ Repository - Fehler beim Erstellen: $e');
      rethrow;
    }
  }

  // ========== AKTUALISIEREN ==========

  /// Gedenkseite aktualisieren
  Future<MemorialPageModel> updateMemorial(MemorialPageModel memorial) async {
    print(
        '🔄 Repository - Aktualisiere Memorial: ${memorial.name} (${memorial.id})');

    try {
      final updatedMemorial = memorial.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection('memorials')
          .doc(memorial.id)
          .update(updatedMemorial.toJson());

      print('✅ Repository - Memorial aktualisiert');
      return updatedMemorial;
    } catch (e) {
      print('❌ Repository - Fehler beim Aktualisieren: $e');
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
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Repository - Memorial gelöscht');
      print('✅ Repository - Memorial aus Organisation entfernt');
    } catch (e) {
      print('❌ Repository - Fehler beim Löschen: $e');
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

      // Generiere Vercel URL
      final slug = memorial.name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'-+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
      final shortId = memorial.id.substring(0, 8);
      final vercelUrl = 'https://$slug-$shortId.memorial.vercel.app';

      final updatedMemorial = memorial.copyWith(
        status: MemorialStatus.published,
        isPublished: true,
        publishedAt: DateTime.now(),
        vercelUrl: vercelUrl,
      );

      await updateMemorial(updatedMemorial);

      print('✅ Repository - Memorial veröffentlicht');
      print('🔗 Repository - Vercel URL: $vercelUrl');
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

      final updatedMemorial = memorial.copyWith(
        status: MemorialStatus.draft,
        isPublished: false,
      );

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

      final updatedMemorial = memorial.copyWith(
        status: MemorialStatus.archived,
        isPublished: false,
      );

      await updateMemorial(updatedMemorial);

      print('✅ Repository - Memorial archiviert');
      return updatedMemorial;
    } catch (e) {
      print('❌ Repository - Fehler: $e');
      rethrow;
    }
  }

  // ========== PERMISSIONS ==========

  /// Prüfe ob User berechtigt ist, Memorial zu bearbeiten
  Future<bool> canUserEditMemorial(
    String memorialId,
    String userId,
    String organizationId,
  ) async {
    print('🔐 Repository - Prüfe Berechtigung für User: $userId');

    try {
      final membershipQuery = await _firestore
          .collection('organizationMembers')
          .where('organizationId', isEqualTo: organizationId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (membershipQuery.docs.isEmpty) {
        print('❌ Repository - User ist kein Mitglied der Organisation');
        return false;
      }

      final membership = membershipQuery.docs.first.data();
      final role = membership['role'] as String;

      // Owner, Admin und Editor können bearbeiten
      final canEdit = role == 'owner' || role == 'admin' || role == 'editor';
      print('✅ Repository - User-Rolle: $role, Kann bearbeiten: $canEdit');
      return canEdit;
    } catch (e) {
      print('❌ Repository - Fehler beim Prüfen der Berechtigung: $e');
      return false;
    }
  }

  // ========== STATISTIKEN ==========

  /// Gedenkseiten-Views erhöhen
  Future<void> incrementViewCount(String memorialId) async {
    print('👁️ Repository - Erhöhe View-Count für: $memorialId');

    try {
      await _firestore.collection('memorials').doc(memorialId).update({
        'viewCount': FieldValue.increment(1),
      });
      print('✅ Repository - View-Count erhöht');
    } catch (e) {
      print('❌ Repository - Fehler: $e');
    }
  }

  /// Statistiken für Organisation abrufen
  Future<Map<String, dynamic>> getOrganizationStatistics(
      String organizationId) async {
    print('📊 Repository - Lade Statistiken für Organisation: $organizationId');

    try {
      final memorials = await getMemorialsByOrganization(organizationId);
      final totalViews = memorials.fold<int>(
        0,
        (sum, memorial) => sum + memorial.viewCount,
      );

      final stats = {
        'totalMemorials': memorials.length,
        'publishedMemorials':
            memorials.where((m) => m.status == MemorialStatus.published).length,
        'draftMemorials':
            memorials.where((m) => m.status == MemorialStatus.draft).length,
        'totalViews': totalViews,
        'totalBlocks': memorials.fold<int>(
          0,
          (sum, memorial) => sum + memorial.contentBlocks.length,
        ),
      };

      print(
          '✅ Repository - Statistiken geladen: ${stats['totalMemorials']} Memorials, ${stats['totalViews']} Views');
      return stats;
    } catch (e) {
      print('❌ Repository - Fehler: $e');
      return {
        'totalMemorials': 0,
        'publishedMemorials': 0,
        'draftMemorials': 0,
        'totalViews': 0,
        'totalBlocks': 0,
      };
    }
  }
}

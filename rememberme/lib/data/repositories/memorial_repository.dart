import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/memorial_model.dart';
import '../models/memorial_access_model.dart';
import '../models/content_block_model.dart';

class MemorialRepository {
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  MemorialRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ========================================
  // MEMORIAL CRUD
  // ========================================

  /// Memorial erstellen
  Future<MemorialModel> createMemorial({
    required String ownerId,
    required String name,
    DateTime? birthDate,
    DateTime? deathDate,
    String? biography,
    bool isPublic = false,
    String templateId = 'default',
  }) async {
    try {
      print('➕ MemorialRepository - Erstelle Memorial: $name');

      final memorialId = _uuid.v4();
      final now = DateTime.now();

      final memorial = MemorialModel(
        id: memorialId,
        ownerId: ownerId,
        name: name,
        birthDate: birthDate,
        deathDate: deathDate,
        biography: biography,
        isPublic: isPublic,
        templateId: templateId,
        status: MemorialStatus.draft,
        contentBlocks: [
          // Standard Header Block
          ContentBlock(
            type: ContentBlockType.header,
            content: {
              'text': 'In liebevoller Erinnerung',
              'level': 1,
              'align': 'center',
              'color': '#000000',
            },
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      // 1. Memorial speichern
      await _firestore
          .collection('memorials')
          .doc(memorialId)
          .set(memorial.toJson());

      // 2. Owner als ersten Member hinzufügen
      await _addAccess(
        memorialId: memorialId,
        userId: ownerId,
        invitedById: null, // Owner wurde nicht eingeladen
      );

      print('✅ MemorialRepository - Memorial erstellt: $memorialId');
      return memorial;
    } catch (e) {
      print('❌ MemorialRepository - Fehler beim Erstellen: $e');
      rethrow;
    }
  }

  /// Memorial nach ID laden
  Future<MemorialModel?> getMemorialById(String memorialId) async {
    try {
      print('🔍 MemorialRepository - Lade Memorial: $memorialId');

      final doc =
          await _firestore.collection('memorials').doc(memorialId).get();

      if (!doc.exists) {
        print('❌ MemorialRepository - Memorial nicht gefunden');
        return null;
      }

      final memorial = MemorialModel.fromJson({...doc.data()!, 'id': doc.id});
      print('✅ MemorialRepository - Memorial geladen: ${memorial.name}');
      return memorial;
    } catch (e) {
      print('❌ MemorialRepository - Fehler: $e');
      return null;
    }
  }

  /// Alle Memorials eines Users laden (eigene + eingeladene)
  Future<List<MemorialModel>> getMemorialsForUser(String userId) async {
    try {
      print('📚 MemorialRepository - Lade Memorials für User: $userId');

      // 1. Alle MemorialAccess für diesen User laden
      final accessQuery = await _firestore
          .collection('memorialAccess')
          .where('userId', isEqualTo: userId)
          .get();

      if (accessQuery.docs.isEmpty) {
        print('ℹ️ MemorialRepository - Keine Memorials gefunden');
        return [];
      }

      // 2. Memorial IDs extrahieren
      final memorialIds = accessQuery.docs
          .map((doc) => doc.data()['memorialId'] as String)
          .toList();

      // 3. Memorials laden (Firestore 'whereIn' max 10 items)
      final memorials = <MemorialModel>[];

      for (var i = 0; i < memorialIds.length; i += 10) {
        final batch = memorialIds.skip(i).take(10).toList();
        final query = await _firestore
            .collection('memorials')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        memorials.addAll(
          query.docs.map((doc) => MemorialModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              })),
        );
      }

      // 4. Nach Erstellungsdatum sortieren (neueste zuerst)
      memorials.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ MemorialRepository - ${memorials.length} Memorials geladen');
      return memorials;
    } catch (e) {
      print('❌ MemorialRepository - Fehler: $e');
      return [];
    }
  }

  /// Memorial aktualisieren
  Future<MemorialModel> updateMemorial(MemorialModel memorial) async {
    try {
      print('🔄 MemorialRepository - Aktualisiere Memorial: ${memorial.id}');

      final updated = memorial.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection('memorials')
          .doc(memorial.id)
          .update(updated.toJson());

      print('✅ MemorialRepository - Memorial aktualisiert');
      return updated;
    } catch (e) {
      print('❌ MemorialRepository - Fehler: $e');
      rethrow;
    }
  }

  /// Memorial löschen (nur Owner!)
  Future<void> deleteMemorial({
    required String memorialId,
    required String requestingUserId,
  }) async {
    try {
      print('🗑️ MemorialRepository - Lösche Memorial: $memorialId');

      // 1. Memorial laden und Owner prüfen
      final memorial = await getMemorialById(memorialId);
      if (memorial == null) {
        throw Exception('Memorial nicht gefunden');
      }

      if (memorial.ownerId != requestingUserId) {
        throw Exception('Nur der Ersteller kann das Memorial löschen');
      }

      // 2. Alle Access-Einträge löschen
      final accessQuery = await _firestore
          .collection('memorialAccess')
          .where('memorialId', isEqualTo: memorialId)
          .get();

      for (var doc in accessQuery.docs) {
        await doc.reference.delete();
      }

      // 3. Alle Invitations löschen
      final inviteQuery = await _firestore
          .collection('invitations')
          .where('memorialId', isEqualTo: memorialId)
          .get();

      for (var doc in inviteQuery.docs) {
        await doc.reference.delete();
      }

      // 4. Memorial löschen
      await _firestore.collection('memorials').doc(memorialId).delete();

      print('✅ MemorialRepository - Memorial gelöscht');
    } catch (e) {
      print('❌ MemorialRepository - Fehler: $e');
      rethrow;
    }
  }

  // ========================================
  // VISIBILITY & STATUS
  // ========================================

  /// Sichtbarkeit ändern (nur Owner!)
  Future<MemorialModel> updateVisibility({
    required String memorialId,
    required String requestingUserId,
    required bool isPublic,
  }) async {
    try {
      print(
          '🔒 MemorialRepository - Ändere Sichtbarkeit: $memorialId → $isPublic');

      final memorial = await getMemorialById(memorialId);
      if (memorial == null) {
        throw Exception('Memorial nicht gefunden');
      }

      if (memorial.ownerId != requestingUserId) {
        throw Exception('Nur der Ersteller kann die Sichtbarkeit ändern');
      }

      final updated = memorial.copyWith(
        isPublic: isPublic,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('memorials')
          .doc(memorialId)
          .update({'isPublic': isPublic, 'updatedAt': Timestamp.now()});

      print('✅ MemorialRepository - Sichtbarkeit geändert');
      return updated;
    } catch (e) {
      print('❌ MemorialRepository - Fehler: $e');
      rethrow;
    }
  }

  /// Status ändern (publish, unpublish, archive)
  Future<MemorialModel> updateStatus({
    required String memorialId,
    required MemorialStatus status,
  }) async {
    try {
      print('📊 MemorialRepository - Ändere Status: $memorialId → $status');

      await _firestore.collection('memorials').doc(memorialId).update({
        'status': status.name,
        'updatedAt': Timestamp.now(),
      });

      final memorial = await getMemorialById(memorialId);
      if (memorial == null) {
        throw Exception('Memorial nicht gefunden nach Update');
      }

      print('✅ MemorialRepository - Status geändert');
      return memorial;
    } catch (e) {
      print('❌ MemorialRepository - Fehler: $e');
      rethrow;
    }
  }

  // ========================================
  // MEMORIAL ACCESS
  // ========================================

  /// Prüfen ob User Zugang hat
  Future<bool> hasAccess({
    required String memorialId,
    required String userId,
  }) async {
    try {
      final query = await _firestore
          .collection('memorialAccess')
          .where('memorialId', isEqualTo: memorialId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('❌ MemorialRepository - hasAccess Fehler: $e');
      return false;
    }
  }

  /// Prüfen ob User Owner ist
  Future<bool> isOwner({
    required String memorialId,
    required String userId,
  }) async {
    try {
      final memorial = await getMemorialById(memorialId);
      return memorial?.ownerId == userId;
    } catch (e) {
      return false;
    }
  }

  /// Access hinzufügen (intern)
  Future<MemorialAccessModel> _addAccess({
    required String memorialId,
    required String userId,
    String? invitedById,
  }) async {
    final accessId = _uuid.v4();

    final access = invitedById != null
        ? MemorialAccessModel.createForInvitee(
            id: accessId,
            userId: userId,
            memorialId: memorialId,
            invitedById: invitedById,
          )
        : MemorialAccessModel.createForOwner(
            id: accessId,
            userId: userId,
            memorialId: memorialId,
          );

    await _firestore
        .collection('memorialAccess')
        .doc(accessId)
        .set(access.toJson());

    return access;
  }

  /// Access für eingeladenen User hinzufügen
  Future<MemorialAccessModel> addMemberAccess({
    required String memorialId,
    required String userId,
    required String invitedById,
  }) async {
    try {
      print('➕ MemorialRepository - Füge Member hinzu: $userId');

      // Bereits Member?
      final alreadyMember = await hasAccess(
        memorialId: memorialId,
        userId: userId,
      );

      if (alreadyMember) {
        throw Exception('User hat bereits Zugang');
      }

      final access = await _addAccess(
        memorialId: memorialId,
        userId: userId,
        invitedById: invitedById,
      );

      print('✅ MemorialRepository - Member hinzugefügt');
      return access;
    } catch (e) {
      print('❌ MemorialRepository - Fehler: $e');
      rethrow;
    }
  }

  /// Alle Members eines Memorials laden
  Future<List<MemorialAccessModel>> getMembersForMemorial(
      String memorialId) async {
    try {
      print('👥 MemorialRepository - Lade Members für: $memorialId');

      final query = await _firestore
          .collection('memorialAccess')
          .where('memorialId', isEqualTo: memorialId)
          .orderBy('joinedAt')
          .get();

      final members = query.docs
          .map((doc) =>
              MemorialAccessModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      print('✅ MemorialRepository - ${members.length} Members geladen');
      return members;
    } catch (e) {
      print('❌ MemorialRepository - Fehler: $e');
      return [];
    }
  }

  /// Member entfernen (Owner kann nicht entfernt werden)
  Future<void> removeMember({
    required String memorialId,
    required String userIdToRemove,
    required String requestingUserId,
  }) async {
    try {
      print('🗑️ MemorialRepository - Entferne Member: $userIdToRemove');

      // Owner darf nicht entfernt werden
      final memorial = await getMemorialById(memorialId);
      if (memorial != null && memorial.ownerId == userIdToRemove) {
        throw Exception('Der Ersteller kann nicht entfernt werden');
      }

      // Nur Owner oder der User selbst darf entfernen
      if (requestingUserId != userIdToRemove) {
        final isRequesterOwner = await isOwner(
          memorialId: memorialId,
          userId: requestingUserId,
        );
        if (!isRequesterOwner) {
          throw Exception('Keine Berechtigung');
        }
      }

      final query = await _firestore
          .collection('memorialAccess')
          .where('memorialId', isEqualTo: memorialId)
          .where('userId', isEqualTo: userIdToRemove)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.delete();
        print('✅ MemorialRepository - Member entfernt');
      }
    } catch (e) {
      print('❌ MemorialRepository - Fehler: $e');
      rethrow;
    }
  }

  // ========================================
  // CONTENT BLOCKS
  // ========================================

  /// ContentBlock hinzufügen
  Future<MemorialModel> addContentBlock({
    required String memorialId,
    required ContentBlock block,
  }) async {
    try {
      print('➕ MemorialRepository - Füge Block hinzu: ${block.type.name}');

      final memorial = await getMemorialById(memorialId);
      if (memorial == null) {
        throw Exception('Memorial nicht gefunden');
      }

      final updatedMemorial = memorial.addContentBlock(block);
      await updateMemorial(updatedMemorial);

      print('✅ MemorialRepository - Block hinzugefügt');
      return updatedMemorial;
    } catch (e) {
      print('❌ MemorialRepository - Fehler: $e');
      rethrow;
    }
  }

  /// ContentBlock aktualisieren
  Future<MemorialModel> updateContentBlock({
    required String memorialId,
    required ContentBlock block,
  }) async {
    try {
      print('🔄 MemorialRepository - Aktualisiere Block: ${block.id}');

      final memorial = await getMemorialById(memorialId);
      if (memorial == null) {
        throw Exception('Memorial nicht gefunden');
      }

      final updatedMemorial = memorial.updateContentBlock(block);
      await updateMemorial(updatedMemorial);

      print('✅ MemorialRepository - Block aktualisiert');
      return updatedMemorial;
    } catch (e) {
      print('❌ MemorialRepository - Fehler: $e');
      rethrow;
    }
  }

  /// ContentBlock löschen
  Future<MemorialModel> deleteContentBlock({
    required String memorialId,
    required String blockId,
  }) async {
    try {
      print('🗑️ MemorialRepository - Lösche Block: $blockId');

      final memorial = await getMemorialById(memorialId);
      if (memorial == null) {
        throw Exception('Memorial nicht gefunden');
      }

      final updatedMemorial = memorial.removeContentBlock(blockId);
      await updateMemorial(updatedMemorial);

      print('✅ MemorialRepository - Block gelöscht');
      return updatedMemorial;
    } catch (e) {
      print('❌ MemorialRepository - Fehler: $e');
      rethrow;
    }
  }

  /// ContentBlocks neu ordnen
  Future<MemorialModel> reorderContentBlocks({
    required String memorialId,
    required int oldIndex,
    required int newIndex,
  }) async {
    try {
      print('🔀 MemorialRepository - Sortiere Blocks: $oldIndex → $newIndex');

      final memorial = await getMemorialById(memorialId);
      if (memorial == null) {
        throw Exception('Memorial nicht gefunden');
      }

      final updatedMemorial = memorial.reorderContentBlocks(oldIndex, newIndex);
      await updateMemorial(updatedMemorial);

      print('✅ MemorialRepository - Blocks sortiert');
      return updatedMemorial;
    } catch (e) {
      print('❌ MemorialRepository - Fehler: $e');
      rethrow;
    }
  }

  /// Alle ContentBlocks speichern (Batch-Update)
  Future<MemorialModel> saveContentBlocks({
    required String memorialId,
    required List<ContentBlock> blocks,
  }) async {
    try {
      print('💾 MemorialRepository - Speichere ${blocks.length} Blocks');

      final memorial = await getMemorialById(memorialId);
      if (memorial == null) {
        throw Exception('Memorial nicht gefunden');
      }

      final updatedMemorial = memorial.copyWith(
        contentBlocks: blocks,
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('memorials').doc(memorialId).update({
        'contentBlocks': blocks.map((b) => b.toJson()).toList(),
        'updatedAt': Timestamp.now(),
      });

      print('✅ MemorialRepository - Blocks gespeichert');
      return updatedMemorial;
    } catch (e) {
      print('❌ MemorialRepository - Fehler: $e');
      rethrow;
    }
  }
}

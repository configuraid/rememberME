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

      print(
          '📋 MemorialRepository - ${accessQuery.docs.length} Access-Einträge gefunden');

      // Debug: Zeige alle Access-Einträge
      for (var doc in accessQuery.docs) {
        final data = doc.data();
        print(
            '   📎 Access: memorialId=${data['memorialId']}, visitorType=${data['visitorType']}');
      }

      if (accessQuery.docs.isEmpty) {
        print('ℹ️ MemorialRepository - Keine Memorials gefunden');
        return [];
      }

      // 2. Memorial IDs extrahieren
      final memorialIds = accessQuery.docs
          .map((doc) => doc.data()['memorialId'] as String)
          .toList();

      print('📋 MemorialRepository - Memorial IDs: $memorialIds');

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

    print(
        '✅ MemorialRepository - Access erstellt: $accessId für User $userId auf Memorial $memorialId');

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

// ============================================================
// FÜGE DIESE METHODE ZU MemorialRepository HINZU
// ============================================================

  /// Prüft welchen Zugang ein User zu einem Memorial hat
  ///
  /// Logik:
  /// 1. Memorial laden
  /// 2. Ist User Owner oder Member? → fullAccess (kann bearbeiten)
  /// 3. Ist Memorial öffentlich? → publicReadOnly (kann nur ansehen)
  /// 4. Sonst → privateNoAccess (sieht nur Basis-Infos)
  Future<MemorialViewAccess> checkViewAccess({
    required String memorialId,
    required String userId,
  }) async {
    try {
      print(
          '🔐 MemorialRepository - Prüfe View-Access: $memorialId für User: $userId');

      // 1. Memorial laden
      final memorial = await getMemorialById(memorialId);
      if (memorial == null) {
        print('❌ MemorialRepository - Memorial nicht gefunden');
        return MemorialViewAccess.notFound();
      }

      // 2. Prüfen ob User Owner ist
      if (memorial.ownerId == userId) {
        print('✅ MemorialRepository - User ist Owner → fullAccess');
        return MemorialViewAccess.fullAccess(memorial);
      }

      // 3. Prüfen ob User eingeladener Member ist
      final isMember = await hasAccess(memorialId: memorialId, userId: userId);
      if (isMember) {
        print('✅ MemorialRepository - User ist Member → fullAccess');
        return MemorialViewAccess.fullAccess(memorial);
      }

      // 4. User ist weder Owner noch Member
      if (memorial.isPublic) {
        // Öffentlich → kann ansehen, aber nicht bearbeiten
        print(
            '👁️ MemorialRepository - Memorial ist öffentlich → publicReadOnly');
        return MemorialViewAccess.publicReadOnly(memorial);
      } else {
        // Privat → kein Zugang zu Inhalten
        print('🔒 MemorialRepository - Memorial ist privat → privateNoAccess');
        return MemorialViewAccess.privateNoAccess(memorial);
      }
    } catch (e) {
      print('❌ MemorialRepository - checkViewAccess Fehler: $e');
      return MemorialViewAccess.notFound();
    }
  }

  /// Schnelle Prüfung ob User Inhalte sehen darf
  /// (für Guards in der UI)
  Future<bool> canViewContent({
    required String memorialId,
    required String userId,
  }) async {
    final access =
        await checkViewAccess(memorialId: memorialId, userId: userId);
    return access.canViewContent;
  }

  /// Schnelle Prüfung ob User bearbeiten darf
  Future<bool> canEdit({
    required String memorialId,
    required String userId,
  }) async {
    final access =
        await checkViewAccess(memorialId: memorialId, userId: userId);
    return access.canEdit;
  }
}

// ============================================================
// FÜGE DIESE METHODEN ZU deiner memorial_repository.dart HINZU
// ============================================================

/// Ergebnis der View-Access-Prüfung
enum MemorialViewAccessType {
  /// User ist Owner oder eingeladener Member → voller Zugriff, kann bearbeiten
  fullAccess,

  /// Memorial ist öffentlich, User hat aber keinen Edit-Zugriff → nur ansehen
  publicReadOnly,

  /// Memorial ist privat und User hat keinen Zugriff → nur Basis-Infos
  privateNoAccess,

  /// Memorial nicht gefunden
  notFound,
}

class MemorialViewAccess {
  final MemorialViewAccessType type;
  final MemorialModel? memorial;
  final bool canEdit;
  final bool canViewContent;

  const MemorialViewAccess._({
    required this.type,
    this.memorial,
    this.canEdit = false,
    this.canViewContent = false,
  });

  factory MemorialViewAccess.fullAccess(MemorialModel memorial) {
    return MemorialViewAccess._(
      type: MemorialViewAccessType.fullAccess,
      memorial: memorial,
      canEdit: true,
      canViewContent: true,
    );
  }

  factory MemorialViewAccess.publicReadOnly(MemorialModel memorial) {
    return MemorialViewAccess._(
      type: MemorialViewAccessType.publicReadOnly,
      memorial: memorial,
      canEdit: false,
      canViewContent: true,
    );
  }

  factory MemorialViewAccess.privateNoAccess(MemorialModel memorial) {
    return MemorialViewAccess._(
      type: MemorialViewAccessType.privateNoAccess,
      memorial: memorial,
      canEdit: false,
      canViewContent: false,
    );
  }

  factory MemorialViewAccess.notFound() {
    return const MemorialViewAccess._(
      type: MemorialViewAccessType.notFound,
    );
  }

  /// Für schnelle Checks
  bool get hasFullAccess => type == MemorialViewAccessType.fullAccess;
  bool get isPublicReadOnly => type == MemorialViewAccessType.publicReadOnly;
  bool get isPrivateNoAccess => type == MemorialViewAccessType.privateNoAccess;
  bool get isNotFound => type == MemorialViewAccessType.notFound;
}

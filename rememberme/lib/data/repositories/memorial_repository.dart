import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rememberme/data/models/auth/user_model.dart';
import '../models/memorial_page_model.dart';
import '../models/content_block_model.dart';
import '../models/group_member_model.dart';
import 'package:uuid/uuid.dart';

class MemorialRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Mock-Daten für Entwicklung (werden später durch Firebase ersetzt)
  final List<MemorialPageModel> _mockMemorials = [];
  bool _useMockData = true; // ✅ Auf false setzen für Firebase

  MemorialRepository() {
    if (_useMockData) {
      _initializeMockData();
    }
  }

  void _initializeMockData() {
    print('📦 MemorialRepository - Initialisiere Mock-Daten...');
    final now = DateTime.now();

    // ✨ Beispiel-Gedenkseite für Organisation "org-mueller-family"
    _mockMemorials.add(
      MemorialPageModel(
        id: 'memorial-1',
        organizationId: 'org-mueller-family', // ✅ NEU
        ownerId: 'user-1',
        name: 'Maria Müller',
        subtitle: 'In liebevoller Erinnerung',
        birthDate: DateTime(1950, 3, 15),
        deathDate: DateTime(2024, 8, 22),
        profileImageUrl: 'https://via.placeholder.com/400',
        status: MemorialStatus.published,
        isPublished: true,
        privacyLevel: PrivacyLevel.public,
        templateId: 'template-1',
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 10)),
        publishedAt: now.subtract(const Duration(days: 10)),
        vercelUrl: 'https://maria-mueller.memorial.app',
        viewCount: 247,
        collaboratorIds: ['user-2'],
        contentBlocks: [
          ContentBlock(
            id: 'block-1',
            type: ContentBlockType.divider,
            createdAt: now.subtract(const Duration(days: 15)),
            updatedAt: now.subtract(const Duration(days: 10)),
          ),
          ContentBlock(
            id: 'block-2',
            type: ContentBlockType.text,
            createdAt: now.subtract(const Duration(days: 15)),
            updatedAt: now.subtract(const Duration(days: 10)),
          ),
          ContentBlock(
            id: 'block-3',
            type: ContentBlockType.gallery,
            createdAt: now.subtract(const Duration(days: 15)),
            updatedAt: now.subtract(const Duration(days: 10)),
          ),
          ContentBlock(
            id: 'block-4',
            type: ContentBlockType.quote,
            createdAt: now.subtract(const Duration(days: 15)),
            updatedAt: now.subtract(const Duration(days: 10)),
          ),
          ContentBlock(
            id: 'block-5',
            type: ContentBlockType.gallery,
            createdAt: now.subtract(const Duration(days: 15)),
            updatedAt: now.subtract(const Duration(days: 10)),
          ),
        ],
      ),
    );

    print(
        '✅ MemorialRepository - ${_mockMemorials.length} Memorial(s) initialisiert');
    print(
        '📄 Memorial: ${_mockMemorials.first.name} (${_mockMemorials.first.id})');
  }

  // ========== NEUE METHODE: Memorials nach Organisation laden ==========

  /// Alle Gedenkseiten einer Organisation abrufen
  /// ✅ ERSETZT die alte getMemorialsByUserId() Methode
  Future<List<MemorialPageModel>> getMemorialsByOrganization(
      String organizationId) async {
    print('🔍 Repository - Lade Memorials für Organisation: $organizationId');

    if (_useMockData) {
      // Mock-Daten
      await Future.delayed(const Duration(milliseconds: 500));

      final orgMemorials = _mockMemorials
          .where((memorial) => memorial.organizationId == organizationId)
          .toList();

      print(
          '✅ Repository - ${orgMemorials.length} Memorial(s) gefunden (Mock)');
      return orgMemorials;
    } else {
      // Firebase
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
  }

  // ========== ALTE METHODE (für Kompatibilität behalten) ==========

  /// @deprecated Verwende stattdessen getMemorialsByOrganization()
  /// Alle Gedenkseiten eines Users abrufen
  Future<List<MemorialPageModel>> getMemorialsByUserId(String userId) async {
    print('⚠️ Repository - getMemorialsByUserId() ist deprecated');
    print('🔍 Repository - Lade Memorials für User: $userId');

    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));

      final userMemorials = _mockMemorials
          .where((memorial) =>
              memorial.ownerId == userId ||
              memorial.collaboratorIds.contains(userId))
          .toList();

      print(
          '✅ Repository - ${userMemorials.length} Memorial(s) gefunden für User: $userId');
      return userMemorials;
    } else {
      // Firebase: Suche nach ownerId oder collaboratorIds
      try {
        final querySnapshot = await _firestore
            .collection('memorials')
            .where('ownerId', isEqualTo: userId)
            .get();

        final memorials = querySnapshot.docs
            .map((doc) =>
                MemorialPageModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList();

        print('✅ Repository - ${memorials.length} Memorial(s) gefunden');
        return memorials;
      } catch (e) {
        print('❌ Repository - Fehler: $e');
        return [];
      }
    }
  }

  // ========== EINZELNE GEDENKSEITE ==========

  /// Einzelne Gedenkseite abrufen
  Future<MemorialPageModel?> getMemorialById(String memorialId) async {
    print('🔍 Repository - Lade Memorial: $memorialId');

    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));

      try {
        final memorial = _mockMemorials.firstWhere((m) => m.id == memorialId);
        print('✅ Repository - Memorial gefunden: ${memorial.name}');
        return memorial;
      } catch (e) {
        print('❌ Repository - Memorial nicht gefunden: $memorialId');
        return null;
      }
    } else {
      // Firebase
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
  }

  // ========== ERSTELLEN ==========

  /// Neue Gedenkseite erstellen
  /// ✅ WICHTIG: Benötigt jetzt organizationId
  Future<MemorialPageModel> createMemorial({
    required String organizationId, // ✅ NEU - Pflichtfeld
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
      organizationId: organizationId, // ✅ NEU
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

    if (_useMockData) {
      // Mock-Daten
      await Future.delayed(const Duration(milliseconds: 500));
      _mockMemorials.add(newMemorial);
      print('✅ Repository - Memorial erstellt (Mock): ${newMemorial.id}');
    } else {
      // Firebase
      try {
        await _firestore
            .collection('memorials')
            .doc(newId)
            .set(newMemorial.toJson());

        // ✅ WICHTIG: Memorial-ID zur Organisation hinzufügen
        await _firestore
            .collection('organizations')
            .doc(organizationId)
            .update({
          'memorialIds': FieldValue.arrayUnion([newId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('✅ Repository - Memorial erstellt: ${newMemorial.id}');
        print('✅ Repository - Memorial zur Organisation hinzugefügt');
      } catch (e) {
        print('❌ Repository - Fehler beim Erstellen: $e');
        rethrow;
      }
    }

    print(
        '📊 Repository - Aktuell ${_mockMemorials.length} Memorial(s) gespeichert');
    return newMemorial;
  }

  // ========== AKTUALISIEREN ==========

  /// Gedenkseite aktualisieren
  Future<MemorialPageModel> updateMemorial(MemorialPageModel memorial) async {
    print(
        '🔄 Repository - Aktualisiere Memorial: ${memorial.name} (${memorial.id})');

    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));

      final index = _mockMemorials.indexWhere((m) => m.id == memorial.id);
      if (index != -1) {
        _mockMemorials[index] = memorial.copyWith(updatedAt: DateTime.now());
        print('✅ Repository - Memorial aktualisiert: ${memorial.name}');
        return _mockMemorials[index];
      }

      print('❌ Repository - Memorial nicht gefunden: ${memorial.id}');
      throw Exception('Gedenkseite nicht gefunden');
    } else {
      // Firebase
      try {
        await _firestore
            .collection('memorials')
            .doc(memorial.id)
            .update(memorial.copyWith(updatedAt: DateTime.now()).toJson());

        print('✅ Repository - Memorial aktualisiert');
        return memorial.copyWith(updatedAt: DateTime.now());
      } catch (e) {
        print('❌ Repository - Fehler beim Aktualisieren: $e');
        rethrow;
      }
    }
  }

  // ========== LÖSCHEN ==========

  /// Gedenkseite löschen
  Future<void> deleteMemorial(String memorialId) async {
    print('🗑️ Repository - Lösche Memorial: $memorialId');

    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));

      final countBefore = _mockMemorials.length;
      _mockMemorials.removeWhere((m) => m.id == memorialId);
      final countAfter = _mockMemorials.length;

      if (countBefore > countAfter) {
        print('✅ Repository - Memorial gelöscht');
        print('📊 Repository - Verbleibende Memorials: $countAfter');
      } else {
        print('⚠️ Repository - Kein Memorial gelöscht (ID nicht gefunden)');
      }
    } else {
      // Firebase
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
  }

  // ========== CONTENT BLOCKS ==========

  /// Content-Block hinzufügen
  Future<MemorialPageModel> addContentBlock(
    String memorialId,
    ContentBlock block,
  ) async {
    print('➕ Repository - Füge Content-Block hinzu: ${block.type}');

    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));

      final memorial = await getMemorialById(memorialId);
      if (memorial == null) {
        print('❌ Repository - Memorial nicht gefunden für Block-Hinzufügung');
        throw Exception('Gedenkseite nicht gefunden');
      }

      final updatedBlocks = [...memorial.contentBlocks, block];
      print(
          '✅ Repository - Block hinzugefügt, nun ${updatedBlocks.length} Blocks');
      return updateMemorial(memorial.copyWith(contentBlocks: updatedBlocks));
    } else {
      // Firebase
      try {
        await _firestore.collection('memorials').doc(memorialId).update({
          'contentBlocks': FieldValue.arrayUnion([block.toJson()]),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final updatedMemorial = await getMemorialById(memorialId);
        print('✅ Repository - Block hinzugefügt');
        return updatedMemorial!;
      } catch (e) {
        print('❌ Repository - Fehler: $e');
        rethrow;
      }
    }
  }

  /// Content-Block aktualisieren
  Future<MemorialPageModel> updateContentBlock(
    String memorialId,
    ContentBlock block,
  ) async {
    print('🔄 Repository - Aktualisiere Content-Block: ${block.id}');

    final memorial = await getMemorialById(memorialId);
    if (memorial == null) {
      print('❌ Repository - Memorial nicht gefunden für Block-Update');
      throw Exception('Gedenkseite nicht gefunden');
    }

    final updatedBlocks = memorial.contentBlocks.map((b) {
      return b.id == block.id ? block : b;
    }).toList();

    print('✅ Repository - Block aktualisiert');
    return updateMemorial(memorial.copyWith(contentBlocks: updatedBlocks));
  }

  /// Content-Block löschen
  Future<MemorialPageModel> deleteContentBlock(
    String memorialId,
    String blockId,
  ) async {
    print('🗑️ Repository - Lösche Content-Block: $blockId');

    final memorial = await getMemorialById(memorialId);
    if (memorial == null) {
      print('❌ Repository - Memorial nicht gefunden für Block-Löschung');
      throw Exception('Gedenkseite nicht gefunden');
    }

    final countBefore = memorial.contentBlocks.length;
    final updatedBlocks =
        memorial.contentBlocks.where((b) => b.id != blockId).toList();

    print(
        '✅ Repository - Block gelöscht, ${countBefore} → ${updatedBlocks.length} Blocks');
    return updateMemorial(memorial.copyWith(contentBlocks: updatedBlocks));
  }

  /// Content-Blocks neu sortieren
  Future<MemorialPageModel> reorderContentBlocks(
    String memorialId,
    List<String> blockIds,
  ) async {
    print('🔀 Repository - Sortiere ${blockIds.length} Content-Blocks neu');

    final memorial = await getMemorialById(memorialId);
    if (memorial == null) {
      print('❌ Repository - Memorial nicht gefunden für Block-Sortierung');
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

    print('✅ Repository - Blocks neu sortiert');
    return updateMemorial(memorial.copyWith(contentBlocks: reorderedBlocks));
  }

  // ========== VERÖFFENTLICHEN ==========

  /// Gedenkseite veröffentlichen
  Future<MemorialPageModel> publishMemorial(String memorialId) async {
    print('🌐 Repository - Veröffentliche Memorial: $memorialId');

    if (_useMockData) {
      await Future.delayed(const Duration(seconds: 2)); // Simuliere Deployment
    }

    final memorial = await getMemorialById(memorialId);
    if (memorial == null) {
      print('❌ Repository - Memorial nicht gefunden für Veröffentlichung');
      throw Exception('Gedenkseite nicht gefunden');
    }

    // Validierung
    if (memorial.contentBlocks.isEmpty) {
      print('❌ Repository - Memorial hat keine Content-Blocks');
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

    print('✅ Repository - Memorial veröffentlicht');
    print('🔗 Repository - Vercel URL: $vercelUrl');

    return updateMemorial(
      memorial.copyWith(
        status: MemorialStatus.published,
        isPublished: true,
        publishedAt: DateTime.now(),
        vercelUrl: vercelUrl,
      ),
    );
  }

  /// Gedenkseite zurück in Entwurf
  Future<MemorialPageModel> unpublishMemorial(String memorialId) async {
    print('📝 Repository - Zurück zu Entwurf: $memorialId');

    final memorial = await getMemorialById(memorialId);
    if (memorial == null) {
      print('❌ Repository - Memorial nicht gefunden');
      throw Exception('Gedenkseite nicht gefunden');
    }

    print('✅ Repository - Memorial ist nun Entwurf');
    return updateMemorial(
      memorial.copyWith(
        status: MemorialStatus.draft,
        isPublished: false,
      ),
    );
  }

  /// Gedenkseite archivieren
  Future<MemorialPageModel> archiveMemorial(String memorialId) async {
    print('📦 Repository - Archiviere Memorial: $memorialId');

    final memorial = await getMemorialById(memorialId);
    if (memorial == null) {
      print('❌ Repository - Memorial nicht gefunden');
      throw Exception('Gedenkseite nicht gefunden');
    }

    print('✅ Repository - Memorial archiviert');
    return updateMemorial(
      memorial.copyWith(
        status: MemorialStatus.archived,
        isPublished: false,
      ),
    );
  }

  // ========== PERMISSIONS ==========

  /// Prüfe ob User berechtigt ist, Memorial zu bearbeiten
  Future<bool> canUserEditMemorial(
    String memorialId,
    String userId,
    String organizationId,
  ) async {
    print('🔐 Repository - Prüfe Berechtigung für User: $userId');

    if (_useMockData) {
      // Mock: Immer erlauben für Entwicklung
      return true;
    } else {
      // Firebase: Prüfe Mitgliedschaft
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
  }

  // ========== GRUPPENMITGLIEDER (Legacy - für GroupMemberModel) ==========

  /// @deprecated Verwende stattdessen OrganizationMemberModel
  /// Gruppenmitglieder abrufen
  Future<List<GroupMemberModel>> getGroupMembers(String memorialId) async {
    print('👥 Repository - Lade Gruppenmitglieder für: $memorialId');
    await Future.delayed(const Duration(milliseconds: 300));

    // Mock-Daten - später aus Firebase
    final members = [
      GroupMemberModel(
        id: 'member-1',
        memorialId: memorialId,
        userId: 'user-2',
        userName: 'Anna Schmidt',
        userEmail: 'anna@example.com',
        role: UserRole.editor,
        invitedAt: DateTime.now().subtract(const Duration(days: 5)),
        joinedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      GroupMemberModel(
        id: 'member-2',
        memorialId: memorialId,
        userId: 'user-3',
        userName: 'Thomas Müller',
        userEmail: 'thomas@example.com',
        role: UserRole.viewer,
        invitedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    print('✅ Repository - ${members.length} Gruppenmitglieder gefunden');
    return members;
  }

  /// @deprecated
  /// Gruppenmitglied einladen
  Future<GroupMemberModel> inviteGroupMember({
    required String memorialId,
    required String userEmail,
    required UserRole role,
  }) async {
    print('📧 Repository - Lade Gruppenmitglied ein: $userEmail als $role');
    await Future.delayed(const Duration(milliseconds: 500));

    final member = GroupMemberModel.create(
      id: _uuid.v4(),
      memorialId: memorialId,
      userId: 'user-temp',
      userName: userEmail.split('@').first,
      userEmail: userEmail,
      role: role,
      invitationCode: 'INV-${DateTime.now().millisecondsSinceEpoch}',
    );

    print('✅ Repository - Einladung erstellt: ${member.invitationCode}');
    return member;
  }

  /// @deprecated
  /// Gruppenmitglied entfernen
  Future<void> removeGroupMember(String memorialId, String memberId) async {
    print('🗑️ Repository - Entferne Gruppenmitglied: $memberId');
    await Future.delayed(const Duration(milliseconds: 300));
    print('✅ Repository - Gruppenmitglied entfernt (Mock)');
  }

  // ========== STATISTIKEN ==========

  /// Gedenkseiten-Views erhöhen
  Future<void> incrementViewCount(String memorialId) async {
    print('👁️ Repository - Erhöhe View-Count für: $memorialId');

    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 100));

      final memorial = await getMemorialById(memorialId);
      if (memorial != null) {
        await updateMemorial(
          memorial.copyWith(viewCount: memorial.viewCount + 1),
        );
        print(
            '✅ Repository - View-Count erhöht auf: ${memorial.viewCount + 1}');
      }
    } else {
      // Firebase
      try {
        await _firestore.collection('memorials').doc(memorialId).update({
          'viewCount': FieldValue.increment(1),
        });
        print('✅ Repository - View-Count erhöht');
      } catch (e) {
        print('❌ Repository - Fehler: $e');
      }
    }
  }

  /// Statistiken für Organisation abrufen
  Future<Map<String, dynamic>> getOrganizationStatistics(
      String organizationId) async {
    print('📊 Repository - Lade Statistiken für Organisation: $organizationId');

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
  }

  /// @deprecated Verwende getOrganizationStatistics()
  /// Statistiken für User abrufen (Legacy)
  Future<Map<String, dynamic>> getStatistics(String userId) async {
    print('⚠️ Repository - getStatistics() ist deprecated');
    print('📊 Repository - Lade Statistiken für User: $userId');

    final memorials = await getMemorialsByUserId(userId);
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
  }

  // ========== HELPER ==========

  /// Datum formatieren
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  /// Mock-Modus ein/ausschalten
  void setUseMockData(bool useMock) {
    _useMockData = useMock;
    if (useMock && _mockMemorials.isEmpty) {
      _initializeMockData();
    }
  }
}

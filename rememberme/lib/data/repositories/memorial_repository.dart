import 'package:rememberme/data/models/user_model.dart';

import '../models/memorial_page_model.dart';
import '../models/content_block_model.dart';
import '../models/group_member_model.dart';
import 'package:uuid/uuid.dart';

class MemorialRepository {
  final _uuid = const Uuid();

  // Mock-Daten für Entwicklung
  final List<MemorialPageModel> _mockMemorials = [];

  MemorialRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    print('📦 MemorialRepository - Initialisiere Mock-Daten...');
    final now = DateTime.now();

    // ✨ NUR NOCH EINE Beispiel-Gedenkseite - Veröffentlicht mit vollem Inhalt
    _mockMemorials.add(
      MemorialPageModel(
        id: 'memorial-1',
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
          // Hero Block
          ContentBlock(
            id: 'block-1',
            type: ContentBlockType.divider,
            createdAt: now.subtract(const Duration(days: 15)),
            updatedAt: now.subtract(const Duration(days: 10)),
          ),
          // Text Block
          ContentBlock(
            id: 'block-2',
            type: ContentBlockType.text,
            createdAt: now.subtract(const Duration(days: 15)),
            updatedAt: now.subtract(const Duration(days: 10)),
          ),
          // Gallery Block
          ContentBlock(
            id: 'block-3',
            type: ContentBlockType.gallery,
            createdAt: now.subtract(const Duration(days: 15)),
            updatedAt: now.subtract(const Duration(days: 10)),
          ),
          // Quote Block
          ContentBlock(
            id: 'block-4',
            type: ContentBlockType.quote,
            createdAt: now.subtract(const Duration(days: 15)),
            updatedAt: now.subtract(const Duration(days: 10)),
          ),
          // Timeline Block
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

  // Alle Gedenkseiten eines Users abrufen
  Future<List<MemorialPageModel>> getMemorialsByUserId(String userId) async {
    print('🔍 Repository - Lade Memorials für User: $userId');
    await Future.delayed(const Duration(milliseconds: 500));

    final userMemorials = _mockMemorials
        .where((memorial) =>
            memorial.ownerId == userId ||
            memorial.collaboratorIds.contains(userId))
        .toList();

    print(
        '✅ Repository - ${userMemorials.length} Memorial(s) gefunden für User: $userId');
    return userMemorials;
  }

  // Einzelne Gedenkseite abrufen
  Future<MemorialPageModel?> getMemorialById(String memorialId) async {
    print('🔍 Repository - Lade Memorial: $memorialId');
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final memorial = _mockMemorials.firstWhere((m) => m.id == memorialId);
      print('✅ Repository - Memorial gefunden: ${memorial.name}');
      return memorial;
    } catch (e) {
      print('❌ Repository - Memorial nicht gefunden: $memorialId');
      return null;
    }
  }

  // Neue Gedenkseite erstellen
  Future<MemorialPageModel> createMemorial({
    required String ownerId,
    required String name,
    required String templateId,
    DateTime? birthDate,
    DateTime? deathDate,
  }) async {
    print('➕ Repository - Erstelle neue Gedenkseite: $name');
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    final newId = _uuid.v4();

    final newMemorial = MemorialPageModel(
      id: newId,
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

    _mockMemorials.add(newMemorial);
    print('✅ Repository - Memorial erstellt: ${newMemorial.id}');
    print(
        '📊 Repository - Aktuell ${_mockMemorials.length} Memorial(s) gespeichert');
    return newMemorial;
  }

  // Gedenkseite aktualisieren
  Future<MemorialPageModel> updateMemorial(MemorialPageModel memorial) async {
    print(
        '🔄 Repository - Aktualisiere Memorial: ${memorial.name} (${memorial.id})');
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _mockMemorials.indexWhere((m) => m.id == memorial.id);
    if (index != -1) {
      _mockMemorials[index] = memorial.copyWith(updatedAt: DateTime.now());
      print('✅ Repository - Memorial aktualisiert: ${memorial.name}');
      return _mockMemorials[index];
    }

    print('❌ Repository - Memorial nicht gefunden: ${memorial.id}');
    throw Exception('Gedenkseite nicht gefunden');
  }

  // Gedenkseite löschen
  Future<void> deleteMemorial(String memorialId) async {
    print('🗑️ Repository - Lösche Memorial: $memorialId');
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
  }

  // Content-Block hinzufügen
  Future<MemorialPageModel> addContentBlock(
    String memorialId,
    ContentBlock block,
  ) async {
    print('➕ Repository - Füge Content-Block hinzu: ${block.type}');
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
  }

  // Content-Block aktualisieren
  Future<MemorialPageModel> updateContentBlock(
    String memorialId,
    ContentBlock block,
  ) async {
    print('🔄 Repository - Aktualisiere Content-Block: ${block.id}');
    await Future.delayed(const Duration(milliseconds: 300));

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

  // Content-Block löschen
  Future<MemorialPageModel> deleteContentBlock(
    String memorialId,
    String blockId,
  ) async {
    print('🗑️ Repository - Lösche Content-Block: $blockId');
    await Future.delayed(const Duration(milliseconds: 300));

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

  // Content-Blocks neu sortieren
  Future<MemorialPageModel> reorderContentBlocks(
    String memorialId,
    List<String> blockIds,
  ) async {
    print('🔀 Repository - Sortiere ${blockIds.length} Content-Blocks neu');
    await Future.delayed(const Duration(milliseconds: 300));

    final memorial = await getMemorialById(memorialId);
    if (memorial == null) {
      print('❌ Repository - Memorial nicht gefunden für Block-Sortierung');
      throw Exception('Gedenkseite nicht gefunden');
    }

    // Erstelle neue Block-Liste in der richtigen Reihenfolge
    final reorderedBlocks = <ContentBlock>[];
    for (var i = 0; i < blockIds.length; i++) {
      final block = memorial.contentBlocks.firstWhere(
        (b) => b.id == blockIds[i],
      );
    }

    print('✅ Repository - Blocks neu sortiert');
    return updateMemorial(memorial.copyWith(contentBlocks: reorderedBlocks));
  }

  // Gedenkseite veröffentlichen
  Future<MemorialPageModel> publishMemorial(String memorialId) async {
    print('🌐 Repository - Veröffentliche Memorial: $memorialId');
    await Future.delayed(const Duration(seconds: 2)); // Simuliere Deployment

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

  // Gedenkseite zurück in Entwurf
  Future<MemorialPageModel> unpublishMemorial(String memorialId) async {
    print('📝 Repository - Zurück zu Entwurf: $memorialId');
    await Future.delayed(const Duration(milliseconds: 500));

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

  // Gedenkseite archivieren
  Future<MemorialPageModel> archiveMemorial(String memorialId) async {
    print('📦 Repository - Archiviere Memorial: $memorialId');
    await Future.delayed(const Duration(milliseconds: 500));

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

  // Gruppenmitglieder abrufen
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

  // Gruppenmitglied einladen
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

  // Gruppenmitglied entfernen
  Future<void> removeGroupMember(String memorialId, String memberId) async {
    print('🗑️ Repository - Entferne Gruppenmitglied: $memberId');
    await Future.delayed(const Duration(milliseconds: 300));
    print('✅ Repository - Gruppenmitglied entfernt (Mock)');
    // Mock - später Firebase
  }

  // Gedenkseiten-Views erhöhen
  Future<void> incrementViewCount(String memorialId) async {
    print('👁️ Repository - Erhöhe View-Count für: $memorialId');
    await Future.delayed(const Duration(milliseconds: 100));

    final memorial = await getMemorialById(memorialId);
    if (memorial != null) {
      await updateMemorial(
        memorial.copyWith(viewCount: memorial.viewCount + 1),
      );
      print('✅ Repository - View-Count erhöht auf: ${memorial.viewCount + 1}');
    }
  }

  // Statistiken abrufen
  Future<Map<String, dynamic>> getStatistics(String userId) async {
    print('📊 Repository - Lade Statistiken für User: $userId');
    await Future.delayed(const Duration(milliseconds: 300));

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

  // Helper: Datum formatieren
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

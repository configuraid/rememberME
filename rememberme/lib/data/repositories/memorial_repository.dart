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
          ContentBlockModel(
            id: 'block-1',
            type: ContentBlockType.hero,
            order: 0,
            data: {
              'title': 'Maria Müller',
              'subtitle': '15. März 1950 - 22. August 2024',
              'imageUrl': 'https://via.placeholder.com/800',
            },
            styles: {
              'layout': 'centered',
              'textColor': '#FFFFFF',
              'overlayOpacity': 0.4,
            },
            createdAt: now.subtract(const Duration(days: 15)),
            updatedAt: now.subtract(const Duration(days: 10)),
          ),
          // Text Block
          ContentBlockModel(
            id: 'block-2',
            type: ContentBlockType.text,
            order: 1,
            data: {
              'heading': 'Biografie',
              'content':
                  'Maria war eine liebevolle Mutter und Großmutter. Sie widmete ihr Leben ihrer Familie und ihrer Leidenschaft für Gartenarbeit. Ihre warme Art und ihr strahlendes Lächeln werden uns immer in Erinnerung bleiben.\n\nGeboren in München, verbrachte sie ihr ganzes Leben in Bayern. Nach ihrer Ausbildung zur Krankenschwester arbeitete sie über 30 Jahre im städtischen Krankenhaus, wo sie unzähligen Patienten half und Hoffnung schenkte.',
            },
            styles: {
              'alignment': 'left',
              'fontSize': 'medium',
              'lineHeight': 1.6,
            },
            createdAt: now.subtract(const Duration(days: 15)),
            updatedAt: now.subtract(const Duration(days: 10)),
          ),
          // Gallery Block
          ContentBlockModel(
            id: 'block-3',
            type: ContentBlockType.gallery,
            order: 2,
            data: {
              'images': [
                'https://via.placeholder.com/400/FFB6C1/000000?text=Hochzeit',
                'https://via.placeholder.com/400/87CEEB/000000?text=Familie',
                'https://via.placeholder.com/400/98FB98/000000?text=Garten',
                'https://via.placeholder.com/400/DDA0DD/000000?text=Urlaub',
                'https://via.placeholder.com/400/F0E68C/000000?text=Geburtstag',
                'https://via.placeholder.com/400/FFE4B5/000000?text=Freunde',
              ],
            },
            styles: {
              'layout': 'grid',
              'columns': 3,
              'spacing': 16,
              'borderRadius': 8,
            },
            createdAt: now.subtract(const Duration(days: 15)),
            updatedAt: now.subtract(const Duration(days: 10)),
          ),
          // Quote Block
          ContentBlockModel(
            id: 'block-4',
            type: ContentBlockType.quote,
            order: 3,
            data: {
              'quote':
                  'Die Liebe ist stärker als der Tod, und die Erinnerung währt ewig.',
              'author': 'Unbekannt',
            },
            styles: {
              'style': 'classic',
              'fontSize': 'large',
              'italics': true,
              'color': '#555555',
            },
            createdAt: now.subtract(const Duration(days: 15)),
            updatedAt: now.subtract(const Duration(days: 10)),
          ),
          // Timeline Block
          ContentBlockModel(
            id: 'block-5',
            type: ContentBlockType.timeline,
            order: 4,
            data: {
              'events': [
                {
                  'date': '15. März 1950',
                  'title': 'Geboren in München',
                  'description': 'Geburt in München, Bayern',
                },
                {
                  'date': '1968',
                  'title': 'Ausbildung zur Krankenschwester',
                  'description':
                      'Beginn der Ausbildung am städtischen Krankenhaus',
                },
                {
                  'date': '1972',
                  'title': 'Hochzeit mit Hans Müller',
                  'description': 'Kirchliche Trauung in St. Peter',
                },
                {
                  'date': '1974 & 1977',
                  'title': 'Geburt der Kinder',
                  'description': 'Anna (1974) und Thomas (1977)',
                },
                {
                  'date': '2000',
                  'title': 'Ruhestand',
                  'description': 'Nach 32 Jahren im Pflegedienst',
                },
                {
                  'date': '22. August 2024',
                  'title': 'Verstorben',
                  'description': 'Friedlich im Kreise ihrer Familie',
                },
              ],
            },
            styles: {
              'layout': 'vertical',
              'lineColor': '#3498DB',
              'iconColor': '#3498DB',
              'cardStyle': 'elevated',
            },
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
        ContentBlockModel(
          id: _uuid.v4(),
          type: ContentBlockType.hero,
          order: 0,
          data: {
            'title': name,
            'subtitle': birthDate != null && deathDate != null
                ? '${_formatDate(birthDate)} - ${_formatDate(deathDate)}'
                : 'In liebevoller Erinnerung',
          },
          styles: {
            'layout': 'centered',
            'textColor': '#FFFFFF',
          },
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
    ContentBlockModel block,
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
    ContentBlockModel block,
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
    final reorderedBlocks = <ContentBlockModel>[];
    for (var i = 0; i < blockIds.length; i++) {
      final block = memorial.contentBlocks.firstWhere(
        (b) => b.id == blockIds[i],
      );
      reorderedBlocks.add(block.copyWith(order: i));
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

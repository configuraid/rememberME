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
    final now = DateTime.now();

    // Beispiel Gedenkseite 1 - Veröffentlicht
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

    // Beispiel Gedenkseite 2 - Entwurf
    _mockMemorials.add(
      MemorialPageModel(
        id: 'memorial-2',
        ownerId: 'user-1',
        name: 'Johann Schmidt',
        subtitle: 'Unvergessen',
        birthDate: DateTime(1945, 7, 8),
        deathDate: DateTime(2024, 9, 15),
        status: MemorialStatus.draft,
        isPublished: false,
        privacyLevel: PrivacyLevel.familyOnly,
        templateId: 'template-2',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
        contentBlocks: [
          // Hero Block (minimalistisch)
          ContentBlockModel(
            id: 'block-6',
            type: ContentBlockType.hero,
            order: 0,
            data: {
              'title': 'Johann Schmidt',
              'subtitle': '8. Juli 1945 - 15. September 2024',
            },
            styles: {
              'layout': 'centered',
              'textColor': '#2C3E50',
            },
            createdAt: now.subtract(const Duration(days: 3)),
            updatedAt: now.subtract(const Duration(days: 3)),
          ),
        ],
      ),
    );

    // Beispiel Gedenkseite 3 - Privat mit mehr Inhalt
    _mockMemorials.add(
      MemorialPageModel(
        id: 'memorial-3',
        ownerId: 'user-1',
        name: 'Elisabeth Weber',
        subtitle: 'Für immer in unseren Herzen',
        birthDate: DateTime(1958, 11, 23),
        deathDate: DateTime(2024, 10, 5),
        profileImageUrl: 'https://via.placeholder.com/400',
        status: MemorialStatus.draft,
        isPublished: false,
        privacyLevel: PrivacyLevel.private,
        templateId: 'template-1',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        contentBlocks: [
          ContentBlockModel(
            id: 'block-7',
            type: ContentBlockType.hero,
            order: 0,
            data: {
              'title': 'Elisabeth Weber',
              'subtitle': '23. November 1958 - 5. Oktober 2024',
              'imageUrl':
                  'https://via.placeholder.com/800/FFC0CB/000000?text=Elisabeth',
            },
            createdAt: now.subtract(const Duration(days: 1)),
            updatedAt: now.subtract(const Duration(days: 1)),
          ),
          ContentBlockModel(
            id: 'block-8',
            type: ContentBlockType.text,
            order: 1,
            data: {
              'heading': 'Ein Leben voller Musik',
              'content':
                  'Elisabeth war eine talentierte Pianistin, die ihr Leben der Musik widmete. Als Musiklehrerin inspirierte sie Generationen von Schülern.',
            },
            createdAt: now.subtract(const Duration(days: 1)),
            updatedAt: now.subtract(const Duration(days: 1)),
          ),
        ],
      ),
    );
  }

  // Alle Gedenkseiten eines Users abrufen
  Future<List<MemorialPageModel>> getMemorialsByUserId(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockMemorials
        .where((memorial) =>
            memorial.ownerId == userId ||
            memorial.collaboratorIds.contains(userId))
        .toList();
  }

  // Einzelne Gedenkseite abrufen
  Future<MemorialPageModel?> getMemorialById(String memorialId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockMemorials.firstWhere((m) => m.id == memorialId);
    } catch (e) {
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
    return newMemorial;
  }

  // Gedenkseite aktualisieren
  Future<MemorialPageModel> updateMemorial(MemorialPageModel memorial) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _mockMemorials.indexWhere((m) => m.id == memorial.id);
    if (index != -1) {
      _mockMemorials[index] = memorial.copyWith(updatedAt: DateTime.now());
      return _mockMemorials[index];
    }
    throw Exception('Gedenkseite nicht gefunden');
  }

  // Gedenkseite löschen
  Future<void> deleteMemorial(String memorialId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockMemorials.removeWhere((m) => m.id == memorialId);
  }

  // Content-Block hinzufügen
  Future<MemorialPageModel> addContentBlock(
    String memorialId,
    ContentBlockModel block,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final memorial = await getMemorialById(memorialId);
    if (memorial == null) {
      throw Exception('Gedenkseite nicht gefunden');
    }

    final updatedBlocks = [...memorial.contentBlocks, block];
    return updateMemorial(memorial.copyWith(contentBlocks: updatedBlocks));
  }

  // Content-Block aktualisieren
  Future<MemorialPageModel> updateContentBlock(
    String memorialId,
    ContentBlockModel block,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final memorial = await getMemorialById(memorialId);
    if (memorial == null) {
      throw Exception('Gedenkseite nicht gefunden');
    }

    final updatedBlocks = memorial.contentBlocks.map((b) {
      return b.id == block.id ? block : b;
    }).toList();

    return updateMemorial(memorial.copyWith(contentBlocks: updatedBlocks));
  }

  // Content-Block löschen
  Future<MemorialPageModel> deleteContentBlock(
    String memorialId,
    String blockId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final memorial = await getMemorialById(memorialId);
    if (memorial == null) {
      throw Exception('Gedenkseite nicht gefunden');
    }

    final updatedBlocks =
        memorial.contentBlocks.where((b) => b.id != blockId).toList();
    return updateMemorial(memorial.copyWith(contentBlocks: updatedBlocks));
  }

  // Content-Blocks neu sortieren
  Future<MemorialPageModel> reorderContentBlocks(
    String memorialId,
    List<String> blockIds,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final memorial = await getMemorialById(memorialId);
    if (memorial == null) {
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

    return updateMemorial(memorial.copyWith(contentBlocks: reorderedBlocks));
  }

  // Gedenkseite veröffentlichen
  Future<MemorialPageModel> publishMemorial(String memorialId) async {
    await Future.delayed(const Duration(seconds: 2)); // Simuliere Deployment

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
    await Future.delayed(const Duration(milliseconds: 500));

    final memorial = await getMemorialById(memorialId);
    if (memorial == null) {
      throw Exception('Gedenkseite nicht gefunden');
    }

    return updateMemorial(
      memorial.copyWith(
        status: MemorialStatus.draft,
        isPublished: false,
      ),
    );
  }

  // Gedenkseite archivieren
  Future<MemorialPageModel> archiveMemorial(String memorialId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final memorial = await getMemorialById(memorialId);
    if (memorial == null) {
      throw Exception('Gedenkseite nicht gefunden');
    }

    return updateMemorial(
      memorial.copyWith(
        status: MemorialStatus.archived,
        isPublished: false,
      ),
    );
  }

  // Gruppenmitglieder abrufen
  Future<List<GroupMemberModel>> getGroupMembers(String memorialId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock-Daten - später aus Firebase
    return [
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
  }

  // Gruppenmitglied einladen
  Future<GroupMemberModel> inviteGroupMember({
    required String memorialId,
    required String userEmail,
    required UserRole role,
  }) async {
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

    return member;
  }

  // Gruppenmitglied entfernen
  Future<void> removeGroupMember(String memorialId, String memberId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock - später Firebase
  }

  // Gedenkseiten-Views erhöhen
  Future<void> incrementViewCount(String memorialId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final memorial = await getMemorialById(memorialId);
    if (memorial != null) {
      await updateMemorial(
        memorial.copyWith(viewCount: memorial.viewCount + 1),
      );
    }
  }

  // Statistiken abrufen
  Future<Map<String, dynamic>> getStatistics(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final memorials = await getMemorialsByUserId(userId);
    final totalViews = memorials.fold<int>(
      0,
      (sum, memorial) => sum + memorial.viewCount,
    );

    return {
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
  }

  // Helper: Datum formatieren
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

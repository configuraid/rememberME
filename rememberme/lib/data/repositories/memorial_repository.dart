import '../models/memorial_page_model.dart';
import '../models/content_block_model.dart';
import '../models/group_member_model.dart';
import '../models/user_model.dart';

class MemorialRepository {
  // Mock-Daten für Entwicklung
  final List<MemorialPageModel> _mockMemorials = [];

  MemorialRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Beispiel Gedenkseite 1
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
        privacyLevel: PrivacyLevel.public,
        templateId: 'template-1',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        publishedAt: DateTime.now().subtract(const Duration(days: 10)),
        vercelUrl: 'https://maria-mueller.memorial.app',
        viewCount: 247,
        contentBlocks: [
          ContentBlockModel.heroSection(
            id: 'block-1',
            name: 'Maria Müller',
            subtitle: 'In liebevoller Erinnerung',
            imageUrl: 'https://via.placeholder.com/800',
            birthDate: DateTime(1950, 3, 15),
            deathDate: DateTime(2024, 8, 22),
          ),
          ContentBlockModel.textBlock(
            id: 'block-2',
            order: 1,
            title: 'Biografie',
            content:
                'Maria war eine liebevolle Mutter und Großmutter. Sie widmete ihr Leben ihrer Familie und ihrer Leidenschaft für Gartenarbeit. Ihre warme Art und ihr strahlendes Lächeln werden uns immer in Erinnerung bleiben.',
          ),
          ContentBlockModel.imageGallery(
            id: 'block-3',
            order: 2,
            title: 'Erinnerungen',
            imageUrls: const [
              'https://via.placeholder.com/400',
              'https://via.placeholder.com/400',
              'https://via.placeholder.com/400',
              'https://via.placeholder.com/400',
            ],
          ),
          ContentBlockModel.quoteSection(
            id: 'block-4',
            order: 3,
            quote:
                'Die Liebe ist stärker als der Tod, und die Erinnerung währt ewig.',
            author: 'Unbekannt',
          ),
        ],
      ),
    );

    // Beispiel Gedenkseite 2 (Draft)
    _mockMemorials.add(
      MemorialPageModel(
        id: 'memorial-2',
        ownerId: 'user-1',
        name: 'Johann Schmidt',
        subtitle: 'Unvergessen',
        birthDate: DateTime(1945, 7, 8),
        deathDate: DateTime(2024, 9, 15),
        status: MemorialStatus.draft,
        privacyLevel: PrivacyLevel.familyOnly,
        templateId: 'template-2',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        contentBlocks: [
          ContentBlockModel.heroSection(
            id: 'block-5',
            name: 'Johann Schmidt',
            subtitle: 'Unvergessen',
            birthDate: DateTime(1945, 7, 8),
            deathDate: DateTime(2024, 9, 15),
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

    final newMemorial = MemorialPageModel(
      id: 'memorial-${DateTime.now().millisecondsSinceEpoch}',
      ownerId: ownerId,
      name: name,
      birthDate: birthDate,
      deathDate: deathDate,
      templateId: templateId,
      createdAt: DateTime.now(),
      contentBlocks: [
        ContentBlockModel.heroSection(
          id: 'hero-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          subtitle: 'In liebevoller Erinnerung',
          birthDate: birthDate,
          deathDate: deathDate,
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

  // Gedenkseite veröffentlichen
  Future<MemorialPageModel> publishMemorial(String memorialId) async {
    await Future.delayed(const Duration(seconds: 2)); // Simuliere Deployment

    final memorial = await getMemorialById(memorialId);
    if (memorial == null) {
      throw Exception('Gedenkseite nicht gefunden');
    }

    // Generiere Vercel URL
    final slug = memorial.name.toLowerCase().replaceAll(' ', '-');
    final vercelUrl =
        'https://$slug-${memorial.id.substring(0, 8)}.memorial.vercel.app';

    return updateMemorial(
      memorial.copyWith(
        status: MemorialStatus.published,
        publishedAt: DateTime.now(),
        vercelUrl: vercelUrl,
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
      id: 'member-${DateTime.now().millisecondsSinceEpoch}',
      memorialId: memorialId,
      userId: 'user-temp',
      userName: userEmail.split('@').first,
      userEmail: userEmail,
      role: role,
      invitationCode: 'INV-${DateTime.now().millisecondsSinceEpoch}',
    );

    return member;
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
}

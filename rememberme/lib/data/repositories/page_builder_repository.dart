import '../models/memorial_page_model.dart';
import '../models/content_block_model.dart';
import '../../business_logic/page_builder/page_builder_state.dart';

class PageBuilderRepository {
  // Memorial laden
  Future<MemorialPageModel> getMemorial(String memorialId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: API-Call
    // Für jetzt Mock-Daten
    return MemorialPageModel(
      id: memorialId,
      ownerId: 'user1',
      name: 'Max Mustermann',
      birthDate: DateTime(1950, 1, 1),
      deathDate: DateTime(2024, 1, 1),
      profileImageUrl: null,
      templateId: 'template1',
      isPublished: false,
      contentBlocks: [],
      viewCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Verfügbare Block-Templates laden
  Future<List<BlockTemplate>> getAvailableTemplates() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      // Hero Block Templates
      const BlockTemplate(
        id: 'hero_classic',
        name: 'Klassisch',
        description: 'Elegantes Hero-Bild mit zentriertem Text',
        type: ContentBlockType.hero,
        defaultStyles: {
          'layout': 'centered',
          'overlayOpacity': 0.3,
          'textColor': '#FFFFFF',
          'fontSize': 'large',
        },
      ),
      const BlockTemplate(
        id: 'hero_modern',
        name: 'Modern',
        description: 'Modernes Design mit Farbverlauf',
        type: ContentBlockType.hero,
        defaultStyles: {
          'layout': 'left',
          'overlayOpacity': 0.5,
          'textColor': '#FFFFFF',
          'fontSize': 'xlarge',
          'gradient': true,
        },
      ),

      // Text Block Templates
      const BlockTemplate(
        id: 'text_simple',
        name: 'Einfach',
        description: 'Schlichter Textblock',
        type: ContentBlockType.text,
        defaultStyles: {
          'alignment': 'left',
          'fontSize': 'medium',
          'lineHeight': 1.6,
          'color': '#333333',
        },
      ),
      const BlockTemplate(
        id: 'text_elegant',
        name: 'Elegant',
        description: 'Eleganter Textblock mit Serifen-Schrift',
        type: ContentBlockType.text,
        defaultStyles: {
          'alignment': 'center',
          'fontSize': 'large',
          'lineHeight': 1.8,
          'color': '#2C3E50',
          'fontFamily': 'serif',
        },
      ),

      // Gallery Templates
      const BlockTemplate(
        id: 'gallery_grid',
        name: 'Raster',
        description: 'Gleichmäßiges Foto-Raster',
        type: ContentBlockType.gallery,
        defaultStyles: {
          'layout': 'grid',
          'columns': 3,
          'spacing': 16,
          'borderRadius': 8,
        },
      ),
      const BlockTemplate(
        id: 'gallery_masonry',
        name: 'Mauerwerk',
        description: 'Pinterest-Style Galerie',
        type: ContentBlockType.gallery,
        defaultStyles: {
          'layout': 'masonry',
          'columns': 2,
          'spacing': 12,
          'borderRadius': 12,
        },
      ),

      // Quote Templates
      const BlockTemplate(
        id: 'quote_classic',
        name: 'Klassisch',
        description: 'Klassisches Zitat-Design',
        type: ContentBlockType.quote,
        defaultStyles: {
          'style': 'classic',
          'fontSize': 'large',
          'color': '#555555',
          'borderLeft': true,
          'italics': true,
        },
      ),
      const BlockTemplate(
        id: 'quote_modern',
        name: 'Modern',
        description: 'Modernes Zitat mit Hintergrund',
        type: ContentBlockType.quote,
        defaultStyles: {
          'style': 'modern',
          'fontSize': 'xlarge',
          'color': '#2C3E50',
          'backgroundColor': '#F8F9FA',
          'padding': 32,
          'borderRadius': 16,
        },
      ),

      // Timeline Templates
      const BlockTemplate(
        id: 'timeline_vertical',
        name: 'Vertikal',
        description: 'Vertikale Timeline',
        type: ContentBlockType.timeline,
        defaultStyles: {
          'layout': 'vertical',
          'lineColor': '#3498DB',
          'iconColor': '#3498DB',
          'cardStyle': 'elevated',
        },
      ),
      const BlockTemplate(
        id: 'timeline_horizontal',
        name: 'Horizontal',
        description: 'Horizontale Timeline',
        type: ContentBlockType.timeline,
        defaultStyles: {
          'layout': 'horizontal',
          'lineColor': '#E74C3C',
          'iconColor': '#E74C3C',
          'cardStyle': 'flat',
        },
      ),
    ];
  }

  // Template-Blocks laden
  Future<List<ContentBlockModel>> getTemplateBlocks(String templateId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: API-Call für vorgefertigte Templates
    return [];
  }

  // Blocks speichern
  Future<void> saveBlocks({
    required String memorialId,
    required List<ContentBlockModel> blocks,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // TODO: API-Call zum Speichern
  }
}

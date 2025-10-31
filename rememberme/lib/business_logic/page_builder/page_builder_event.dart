import 'package:equatable/equatable.dart';
import '../../../data/models/content_block_model.dart';

abstract class PageBuilderEvent extends Equatable {
  const PageBuilderEvent();

  @override
  List<Object?> get props => [];
}

// Page Builder für Memorial laden
class PageBuilderLoadRequested extends PageBuilderEvent {
  final String memorialId;

  const PageBuilderLoadRequested(this.memorialId);

  @override
  List<Object?> get props => [memorialId];
}

// Block hinzufügen
class PageBuilderBlockAddRequested extends PageBuilderEvent {
  final ContentBlockType blockType;
  final Map<String, dynamic>? initialData;

  const PageBuilderBlockAddRequested({
    required this.blockType,
    this.initialData,
  });

  @override
  List<Object?> get props => [blockType, initialData];
}

// Block aktualisieren
class PageBuilderBlockUpdateRequested extends PageBuilderEvent {
  final String blockId;
  final Map<String, dynamic> data;

  const PageBuilderBlockUpdateRequested({
    required this.blockId,
    required this.data,
  });

  @override
  List<Object?> get props => [blockId, data];
}

// Block löschen
class PageBuilderBlockDeleteRequested extends PageBuilderEvent {
  final String blockId;

  const PageBuilderBlockDeleteRequested(this.blockId);

  @override
  List<Object?> get props => [blockId];
}

// Block verschieben/sortieren
class PageBuilderBlockReorderRequested extends PageBuilderEvent {
  final int oldIndex;
  final int newIndex;

  const PageBuilderBlockReorderRequested({
    required this.oldIndex,
    required this.newIndex,
  });

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

// Block-Style ändern
class PageBuilderBlockStyleChangeRequested extends PageBuilderEvent {
  final String blockId;
  final String styleKey;
  final dynamic styleValue;

  const PageBuilderBlockStyleChangeRequested({
    required this.blockId,
    required this.styleKey,
    required this.styleValue,
  });

  @override
  List<Object?> get props => [blockId, styleKey, styleValue];
}

// Block-Template auswählen
class PageBuilderBlockTemplateSelectRequested extends PageBuilderEvent {
  final String blockId;
  final String templateId;

  const PageBuilderBlockTemplateSelectRequested({
    required this.blockId,
    required this.templateId,
  });

  @override
  List<Object?> get props => [blockId, templateId];
}

// Block zur Bearbeitung auswählen
class PageBuilderBlockSelectRequested extends PageBuilderEvent {
  final String? blockId;

  const PageBuilderBlockSelectRequested(this.blockId);

  @override
  List<Object?> get props => [blockId];
}

// Änderungen speichern
class PageBuilderSaveRequested extends PageBuilderEvent {
  final String memorialId;

  const PageBuilderSaveRequested(this.memorialId);

  @override
  List<Object?> get props => [memorialId];
}

// Vorschau-Modus umschalten
class PageBuilderPreviewToggleRequested extends PageBuilderEvent {
  const PageBuilderPreviewToggleRequested();
}

// Rückgängig machen
class PageBuilderUndoRequested extends PageBuilderEvent {
  const PageBuilderUndoRequested();
}

// Wiederholen
class PageBuilderRedoRequested extends PageBuilderEvent {
  const PageBuilderRedoRequested();
}

// Template laden
class PageBuilderTemplateLoadRequested extends PageBuilderEvent {
  final String templateId;

  const PageBuilderTemplateLoadRequested(this.templateId);

  @override
  List<Object?> get props => [templateId];
}

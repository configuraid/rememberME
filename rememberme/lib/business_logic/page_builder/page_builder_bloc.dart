import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/page_builder_repository.dart';
import '../../data/models/content_block_model.dart';
import 'page_builder_event.dart';
import 'page_builder_state.dart';

class PageBuilderBloc extends Bloc<PageBuilderEvent, PageBuilderState> {
  final PageBuilderRepository pageBuilderRepository;
  final _uuid = const Uuid();

  PageBuilderBloc({required this.pageBuilderRepository})
      : super(PageBuilderState.initial()) {
    on<PageBuilderLoadRequested>(_onLoad);
    on<PageBuilderBlockAddRequested>(_onAddBlock);
    on<PageBuilderBlockUpdateRequested>(_onUpdateBlock);
    on<PageBuilderBlockDeleteRequested>(_onDeleteBlock);
    on<PageBuilderBlockReorderRequested>(_onReorderBlock);
    on<PageBuilderBlockStyleChangeRequested>(_onChangeBlockStyle);
    on<PageBuilderBlockTemplateSelectRequested>(_onSelectTemplate);
    on<PageBuilderBlockSelectRequested>(_onSelectBlock);
    on<PageBuilderSaveRequested>(_onSave);
    on<PageBuilderPreviewToggleRequested>(_onTogglePreview);
    on<PageBuilderUndoRequested>(_onUndo);
    on<PageBuilderRedoRequested>(_onRedo);
    on<PageBuilderTemplateLoadRequested>(_onLoadTemplate);
  }

  Future<void> _onLoad(
    PageBuilderLoadRequested event,
    Emitter<PageBuilderState> emit,
  ) async {
    emit(PageBuilderState.loading());

    try {
      final memorial =
          await pageBuilderRepository.getMemorial(event.memorialId);
      final blocks = memorial.contentBlocks;
      final templates = await pageBuilderRepository.getAvailableTemplates();

      emit(PageBuilderState.loaded(
        memorial: memorial,
        blocks: blocks,
        templates: templates,
      ));
    } catch (e) {
      emit(PageBuilderState.error('Fehler beim Laden: ${e.toString()}'));
    }
  }

  Future<void> _onAddBlock(
    PageBuilderBlockAddRequested event,
    Emitter<PageBuilderState> emit,
  ) async {
    try {
      final newBlock = ContentBlockModel(
        id: _uuid.v4(),
        type: event.blockType,
        order: state.blocks.length,
        data: event.initialData ?? {},
        styles: {},
      );

      final updatedBlocks = [...state.blocks, newBlock];

      emit(state.copyWith(
        blocks: updatedBlocks,
        selectedBlockId: newBlock.id,
        status: PageBuilderStatus.editing,
        successMessage: 'Block hinzugefügt',
      ));

      _addToHistory(emit, updatedBlocks);
    } catch (e) {
      emit(state.copyWith(
        status: PageBuilderStatus.error,
        errorMessage: 'Fehler beim Hinzufügen: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateBlock(
    PageBuilderBlockUpdateRequested event,
    Emitter<PageBuilderState> emit,
  ) async {
    try {
      final updatedBlocks = state.blocks.map((block) {
        if (block.id == event.blockId) {
          return block.copyWith(data: {...block.data, ...event.data});
        }
        return block;
      }).toList();

      emit(state.copyWith(
        blocks: updatedBlocks,
        status: PageBuilderStatus.editing,
      ));

      _addToHistory(emit, updatedBlocks);
    } catch (e) {
      emit(state.copyWith(
        status: PageBuilderStatus.error,
        errorMessage: 'Fehler beim Aktualisieren: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDeleteBlock(
    PageBuilderBlockDeleteRequested event,
    Emitter<PageBuilderState> emit,
  ) async {
    try {
      final updatedBlocks =
          state.blocks.where((block) => block.id != event.blockId).toList();

      // Order neu setzen
      for (var i = 0; i < updatedBlocks.length; i++) {
        updatedBlocks[i] = updatedBlocks[i].copyWith(order: i);
      }

      emit(state.copyWith(
        blocks: updatedBlocks,
        clearSelectedBlock: true,
        status: PageBuilderStatus.editing,
        successMessage: 'Block gelöscht',
      ));

      _addToHistory(emit, updatedBlocks);
    } catch (e) {
      emit(state.copyWith(
        status: PageBuilderStatus.error,
        errorMessage: 'Fehler beim Löschen: ${e.toString()}',
      ));
    }
  }

  Future<void> _onReorderBlock(
    PageBuilderBlockReorderRequested event,
    Emitter<PageBuilderState> emit,
  ) async {
    try {
      final updatedBlocks = List<ContentBlockModel>.from(state.blocks);
      final block = updatedBlocks.removeAt(event.oldIndex);
      updatedBlocks.insert(event.newIndex, block);

      // Order neu setzen
      for (var i = 0; i < updatedBlocks.length; i++) {
        updatedBlocks[i] = updatedBlocks[i].copyWith(order: i);
      }

      emit(state.copyWith(
        blocks: updatedBlocks,
        status: PageBuilderStatus.editing,
      ));

      _addToHistory(emit, updatedBlocks);
    } catch (e) {
      emit(state.copyWith(
        status: PageBuilderStatus.error,
        errorMessage: 'Fehler beim Sortieren: ${e.toString()}',
      ));
    }
  }

  Future<void> _onChangeBlockStyle(
    PageBuilderBlockStyleChangeRequested event,
    Emitter<PageBuilderState> emit,
  ) async {
    try {
      final updatedBlocks = state.blocks.map((block) {
        if (block.id == event.blockId) {
          final updatedStyles = {...block.styles};
          updatedStyles[event.styleKey] = event.styleValue;
          return block.copyWith(styles: updatedStyles);
        }
        return block;
      }).toList();

      emit(state.copyWith(
        blocks: updatedBlocks,
        status: PageBuilderStatus.editing,
      ));

      _addToHistory(emit, updatedBlocks);
    } catch (e) {
      emit(state.copyWith(
        status: PageBuilderStatus.error,
        errorMessage: 'Fehler beim Ändern des Styles: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSelectTemplate(
    PageBuilderBlockTemplateSelectRequested event,
    Emitter<PageBuilderState> emit,
  ) async {
    try {
      final template =
          state.availableTemplates.firstWhere((t) => t.id == event.templateId);

      final updatedBlocks = state.blocks.map((block) {
        if (block.id == event.blockId) {
          return block.copyWith(
            styles: template.defaultStyles,
          );
        }
        return block;
      }).toList();

      emit(state.copyWith(
        blocks: updatedBlocks,
        status: PageBuilderStatus.editing,
        successMessage: 'Template "${template.name}" angewendet',
      ));

      _addToHistory(emit, updatedBlocks);
    } catch (e) {
      emit(state.copyWith(
        status: PageBuilderStatus.error,
        errorMessage: 'Fehler beim Anwenden des Templates: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSelectBlock(
    PageBuilderBlockSelectRequested event,
    Emitter<PageBuilderState> emit,
  ) async {
    emit(state.copyWith(
      selectedBlockId: event.blockId,
      clearSelectedBlock: event.blockId == null,
    ));
  }

  Future<void> _onSave(
    PageBuilderSaveRequested event,
    Emitter<PageBuilderState> emit,
  ) async {
    emit(state.copyWith(status: PageBuilderStatus.saving));

    try {
      await pageBuilderRepository.saveBlocks(
        memorialId: event.memorialId,
        blocks: state.blocks,
      );

      emit(state.copyWith(
        status: PageBuilderStatus.saved,
        successMessage: 'Änderungen gespeichert',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PageBuilderStatus.error,
        errorMessage: 'Fehler beim Speichern: ${e.toString()}',
      ));
    }
  }

  Future<void> _onTogglePreview(
    PageBuilderPreviewToggleRequested event,
    Emitter<PageBuilderState> emit,
  ) async {
    emit(state.copyWith(
      isPreviewMode: !state.isPreviewMode,
      clearSelectedBlock: true,
    ));
  }

  Future<void> _onUndo(
    PageBuilderUndoRequested event,
    Emitter<PageBuilderState> emit,
  ) async {
    if (state.canUndo) {
      final newIndex = state.historyIndex - 1;
      emit(state.copyWith(
        blocks: state.history[newIndex],
        historyIndex: newIndex,
        status: PageBuilderStatus.editing,
      ));
    }
  }

  Future<void> _onRedo(
    PageBuilderRedoRequested event,
    Emitter<PageBuilderState> emit,
  ) async {
    if (state.canRedo) {
      final newIndex = state.historyIndex + 1;
      emit(state.copyWith(
        blocks: state.history[newIndex],
        historyIndex: newIndex,
        status: PageBuilderStatus.editing,
      ));
    }
  }

  Future<void> _onLoadTemplate(
    PageBuilderTemplateLoadRequested event,
    Emitter<PageBuilderState> emit,
  ) async {
    try {
      final templateBlocks =
          await pageBuilderRepository.getTemplateBlocks(event.templateId);

      emit(state.copyWith(
        blocks: templateBlocks,
        status: PageBuilderStatus.editing,
        successMessage: 'Template geladen',
      ));

      _addToHistory(emit, templateBlocks);
    } catch (e) {
      emit(state.copyWith(
        status: PageBuilderStatus.error,
        errorMessage: 'Fehler beim Laden des Templates: ${e.toString()}',
      ));
    }
  }

  void _addToHistory(
    Emitter<PageBuilderState> emit,
    List<ContentBlockModel> blocks,
  ) {
    // Entferne alle Einträge nach dem aktuellen Index
    final newHistory = state.history.sublist(0, state.historyIndex + 1);
    newHistory.add(blocks);

    // Limitiere die History auf 20 Einträge
    final limitedHistory = newHistory.length > 20
        ? newHistory.sublist(newHistory.length - 20)
        : newHistory;

    emit(state.copyWith(
      history: limitedHistory,
      historyIndex: limitedHistory.length - 1,
    ));
  }
}

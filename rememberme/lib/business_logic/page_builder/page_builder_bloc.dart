import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/data/models/content_block_model.dart';
import '../../data/repositories/page_builder_repository.dart';
import 'page_builder_event.dart';
import 'page_builder_state.dart';

class PageBuilderBloc extends Bloc<PageBuilderEvent, PageBuilderState> {
  final PageBuilderRepository pageBuilderRepository;

  PageBuilderBloc({required this.pageBuilderRepository})
      : super(PageBuilderState.initial()) {
    on<PageBuilderLoadRequested>(_onLoad);
    on<PageBuilderBlockAddRequested>(_onAddBlock);
    on<PageBuilderBlockUpdateRequested>(_onUpdateBlock);
    on<PageBuilderBlockDeleteRequested>(_onDeleteBlock);
    on<PageBuilderBlockReorderRequested>(_onReorderBlock);
    on<PageBuilderBlockDuplicateRequested>(_onDuplicateBlock);
    on<PageBuilderSaveRequested>(_onSave);
    on<PageBuilderUndoRequested>(_onUndo);
    on<PageBuilderRedoRequested>(_onRedo);
  }

  // ✅ FIX: Null-Behandlung für getMemorial
  Future<void> _onLoad(
    PageBuilderLoadRequested event,
    Emitter<PageBuilderState> emit,
  ) async {
    emit(PageBuilderState.loading());

    try {
      print('📦 PageBuilderBloc - Lade Memorial: ${event.memorialId}');

      final memorial =
          await pageBuilderRepository.getMemorial(event.memorialId);

      // ✅ FIX: Prüfe ob Memorial existiert
      if (memorial == null) {
        print('❌ PageBuilderBloc - Memorial nicht gefunden');
        emit(PageBuilderState.error('Memorial nicht gefunden'));
        return;
      }

      final blocks = memorial.contentBlocks;

      print('✅ PageBuilderBloc - ${blocks.length} Blocks geladen');

      emit(PageBuilderState.loaded(
        memorial: memorial,
        blocks: blocks,
      ));
    } catch (e) {
      print('❌ PageBuilderBloc - Fehler beim Laden: $e');
      emit(PageBuilderState.error('Fehler beim Laden: ${e.toString()}'));
    }
  }

  Future<void> _onAddBlock(
    PageBuilderBlockAddRequested event,
    Emitter<PageBuilderState> emit,
  ) async {
    try {
      print('➕ PageBuilderBloc - Füge Block hinzu: ${event.blockType.name}');

      final newBlock = ContentBlock(type: event.blockType);
      final updatedBlocks = [...state.blocks, newBlock];

      emit(state.copyWith(
        blocks: updatedBlocks,
        selectedBlockId: newBlock.id,
        status: PageBuilderStatus.editing,
        successMessage:
            '${BlockTypeInfo.getTitle(event.blockType)} hinzugefügt',
      ));

      _addToHistory(emit, updatedBlocks);
      print('✅ PageBuilderBloc - Block hinzugefügt: ${newBlock.id}');
    } catch (e) {
      print('❌ PageBuilderBloc - Fehler beim Hinzufügen: $e');
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
      print('🔄 PageBuilderBloc - Aktualisiere Block: ${event.blockId}');

      final updatedBlocks = state.blocks.map((block) {
        if (block.id == event.blockId) {
          return block.updateContent(event.key, event.value);
        }
        return block;
      }).toList();

      emit(state.copyWith(
        blocks: updatedBlocks,
        status: PageBuilderStatus.editing,
      ));

      _addToHistory(emit, updatedBlocks);
      print('✅ PageBuilderBloc - Block aktualisiert');
    } catch (e) {
      print('❌ PageBuilderBloc - Fehler beim Aktualisieren: $e');
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
      print('🗑️ PageBuilderBloc - Lösche Block: ${event.blockId}');

      final updatedBlocks =
          state.blocks.where((block) => block.id != event.blockId).toList();

      emit(state.copyWith(
        blocks: updatedBlocks,
        clearSelectedBlock: true,
        status: PageBuilderStatus.editing,
        successMessage: 'Block gelöscht',
      ));

      _addToHistory(emit, updatedBlocks);
      print(
          '✅ PageBuilderBloc - Block gelöscht, ${updatedBlocks.length} verbleibend');
    } catch (e) {
      print('❌ PageBuilderBloc - Fehler beim Löschen: $e');
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
      print(
          '🔀 PageBuilderBloc - Sortiere Blocks: ${event.oldIndex} → ${event.newIndex}');

      final updatedBlocks = List<ContentBlock>.from(state.blocks);
      final block = updatedBlocks.removeAt(event.oldIndex);
      updatedBlocks.insert(event.newIndex, block);

      emit(state.copyWith(
        blocks: updatedBlocks,
        status: PageBuilderStatus.editing,
      ));

      _addToHistory(emit, updatedBlocks);
      print('✅ PageBuilderBloc - Blocks neu sortiert');
    } catch (e) {
      print('❌ PageBuilderBloc - Fehler beim Sortieren: $e');
      emit(state.copyWith(
        status: PageBuilderStatus.error,
        errorMessage: 'Fehler beim Sortieren: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDuplicateBlock(
    PageBuilderBlockDuplicateRequested event,
    Emitter<PageBuilderState> emit,
  ) async {
    try {
      print('📋 PageBuilderBloc - Dupliziere Block: ${event.blockId}');

      final originalIndex =
          state.blocks.indexWhere((b) => b.id == event.blockId);
      if (originalIndex == -1) {
        throw Exception('Block nicht gefunden');
      }

      final original = state.blocks[originalIndex];
      final duplicate = ContentBlock(
        type: original.type,
        content: Map<String, dynamic>.from(original.content),
      );

      final updatedBlocks = List<ContentBlock>.from(state.blocks);
      updatedBlocks.insert(originalIndex + 1, duplicate);

      emit(state.copyWith(
        blocks: updatedBlocks,
        selectedBlockId: duplicate.id,
        status: PageBuilderStatus.editing,
        successMessage: 'Block dupliziert',
      ));

      _addToHistory(emit, updatedBlocks);
      print('✅ PageBuilderBloc - Block dupliziert: ${duplicate.id}');
    } catch (e) {
      print('❌ PageBuilderBloc - Fehler beim Duplizieren: $e');
      emit(state.copyWith(
        status: PageBuilderStatus.error,
        errorMessage: 'Fehler beim Duplizieren: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSave(
    PageBuilderSaveRequested event,
    Emitter<PageBuilderState> emit,
  ) async {
    emit(state.copyWith(status: PageBuilderStatus.saving));

    try {
      print('💾 PageBuilderBloc - Speichere ${state.blocks.length} Blocks');

      await pageBuilderRepository.saveBlocks(
        memorialId: event.memorialId,
        blocks: state.blocks,
      );

      emit(state.copyWith(
        status: PageBuilderStatus.saved,
        successMessage: 'Änderungen gespeichert',
      ));

      print('✅ PageBuilderBloc - Erfolgreich gespeichert');
    } catch (e) {
      print('❌ PageBuilderBloc - Fehler beim Speichern: $e');
      emit(state.copyWith(
        status: PageBuilderStatus.error,
        errorMessage: 'Fehler beim Speichern: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUndo(
    PageBuilderUndoRequested event,
    Emitter<PageBuilderState> emit,
  ) async {
    if (state.canUndo) {
      print('↩️ PageBuilderBloc - Undo');
      final newIndex = state.historyIndex - 1;
      emit(state.copyWith(
        blocks: state.history[newIndex],
        historyIndex: newIndex,
        status: PageBuilderStatus.editing,
        successMessage: 'Rückgängig gemacht',
      ));
    }
  }

  Future<void> _onRedo(
    PageBuilderRedoRequested event,
    Emitter<PageBuilderState> emit,
  ) async {
    if (state.canRedo) {
      print('↪️ PageBuilderBloc - Redo');
      final newIndex = state.historyIndex + 1;
      emit(state.copyWith(
        blocks: state.history[newIndex],
        historyIndex: newIndex,
        status: PageBuilderStatus.editing,
        successMessage: 'Wiederhergestellt',
      ));
    }
  }

  void _addToHistory(
    Emitter<PageBuilderState> emit,
    List<ContentBlock> blocks,
  ) {
    // Entferne alle Einträge nach dem aktuellen Index
    final newHistory = state.history.sublist(0, state.historyIndex + 1);
    newHistory.add(blocks);

    // Limitiere die History auf 50 Einträge
    final limitedHistory = newHistory.length > 50
        ? newHistory.sublist(newHistory.length - 50)
        : newHistory;

    emit(state.copyWith(
      history: limitedHistory,
      historyIndex: limitedHistory.length - 1,
    ));

    print(
        '📜 PageBuilderBloc - History: ${limitedHistory.length} Einträge (Index: ${limitedHistory.length - 1})');
  }
}

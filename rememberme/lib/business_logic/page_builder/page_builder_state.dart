import 'package:equatable/equatable.dart';
import '../../data/models/content_block_model.dart';
import '../../data/models/memorial_model.dart';

enum PageBuilderStatus {
  initial,
  loading,
  loaded,
  editing,
  saving,
  saved,
  error,
}

class PageBuilderState extends Equatable {
  final PageBuilderStatus status;
  final MemorialModel? memorial;
  final List<ContentBlock> blocks;
  final String? selectedBlockId;
  final String? errorMessage;
  final String? successMessage;

  // Undo/Redo History
  final List<List<ContentBlock>> history;
  final int historyIndex;

  const PageBuilderState({
    this.status = PageBuilderStatus.initial,
    this.memorial,
    this.blocks = const [],
    this.selectedBlockId,
    this.errorMessage,
    this.successMessage,
    this.history = const [],
    this.historyIndex = -1,
  });

  // ========================================
  // FACTORY CONSTRUCTORS
  // ========================================

  factory PageBuilderState.initial() {
    return const PageBuilderState(status: PageBuilderStatus.initial);
  }

  factory PageBuilderState.loading() {
    return const PageBuilderState(status: PageBuilderStatus.loading);
  }

  factory PageBuilderState.loaded({
    required MemorialModel memorial,
    required List<ContentBlock> blocks,
  }) {
    return PageBuilderState(
      status: PageBuilderStatus.loaded,
      memorial: memorial,
      blocks: blocks,
      history: [blocks],
      historyIndex: 0,
    );
  }

  factory PageBuilderState.error(String message) {
    return PageBuilderState(
      status: PageBuilderStatus.error,
      errorMessage: message,
    );
  }

  // ========================================
  // COMPUTED PROPERTIES
  // ========================================

  bool get isLoading =>
      status == PageBuilderStatus.loading || status == PageBuilderStatus.saving;

  bool get hasError => status == PageBuilderStatus.error;

  bool get canUndo => historyIndex > 0;

  bool get canRedo => historyIndex < history.length - 1;

  bool get hasBlocks => blocks.isNotEmpty;

  int get blockCount => blocks.length;

  bool get hasUnsavedChanges => status == PageBuilderStatus.editing;

  bool get isSaved => status == PageBuilderStatus.saved;

  /// Aktuell ausgewählter Block
  ContentBlock? get selectedBlock {
    if (selectedBlockId == null) return null;
    try {
      return blocks.firstWhere((block) => block.id == selectedBlockId);
    } catch (e) {
      return null;
    }
  }

  /// Block nach ID finden
  ContentBlock? getBlockById(String blockId) {
    try {
      return blocks.firstWhere((block) => block.id == blockId);
    } catch (e) {
      return null;
    }
  }

  /// Blocks nach Typ filtern
  List<ContentBlock> getBlocksByType(ContentBlockType type) {
    return blocks.where((block) => block.type == type).toList();
  }

  /// Prüfen ob ein Block-Typ existiert
  bool hasBlockType(ContentBlockType type) {
    return blocks.any((block) => block.type == type);
  }

  /// Index eines Blocks
  int getBlockIndex(String blockId) {
    return blocks.indexWhere((b) => b.id == blockId);
  }

  // ========================================
  // COPY WITH
  // ========================================

  PageBuilderState copyWith({
    PageBuilderStatus? status,
    MemorialModel? memorial,
    List<ContentBlock>? blocks,
    String? selectedBlockId,
    bool clearSelectedBlock = false,
    String? errorMessage,
    String? successMessage,
    List<List<ContentBlock>>? history,
    int? historyIndex,
  }) {
    return PageBuilderState(
      status: status ?? this.status,
      memorial: memorial ?? this.memorial,
      blocks: blocks ?? this.blocks,
      selectedBlockId:
          clearSelectedBlock ? null : (selectedBlockId ?? this.selectedBlockId),
      errorMessage: errorMessage,
      successMessage: successMessage,
      history: history ?? this.history,
      historyIndex: historyIndex ?? this.historyIndex,
    );
  }

  @override
  List<Object?> get props => [
        status,
        memorial,
        blocks,
        selectedBlockId,
        errorMessage,
        successMessage,
        history,
        historyIndex,
      ];

  @override
  String toString() {
    return 'PageBuilderState(status: $status, blocks: ${blocks.length}, selected: $selectedBlockId, historyIndex: $historyIndex/${history.length})';
  }
}

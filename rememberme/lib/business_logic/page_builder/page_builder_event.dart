import 'package:equatable/equatable.dart';
import '../../data/models/content_block_model.dart';

abstract class PageBuilderEvent extends Equatable {
  const PageBuilderEvent();

  @override
  List<Object?> get props => [];
}

// ========================================
// LOADING
// ========================================

/// Load page builder for a memorial
class PageBuilderLoadRequested extends PageBuilderEvent {
  final String memorialId;

  const PageBuilderLoadRequested(this.memorialId);

  @override
  List<Object?> get props => [memorialId];

  @override
  String toString() => 'PageBuilderLoadRequested(memorialId: $memorialId)';
}

// ========================================
// BLOCK MANAGEMENT
// ========================================

/// Add a new block
class PageBuilderBlockAddRequested extends PageBuilderEvent {
  final ContentBlockType blockType;

  const PageBuilderBlockAddRequested(this.blockType);

  @override
  List<Object?> get props => [blockType];

  @override
  String toString() => 'PageBuilderBlockAddRequested(type: ${blockType.name})';
}

/// Update block content
class PageBuilderBlockUpdateRequested extends PageBuilderEvent {
  final String blockId;
  final String key;
  final dynamic value;

  const PageBuilderBlockUpdateRequested({
    required this.blockId,
    required this.key,
    required this.value,
  });

  @override
  List<Object?> get props => [blockId, key, value];

  @override
  String toString() =>
      'PageBuilderBlockUpdateRequested(blockId: $blockId, key: $key)';
}

/// Delete a block
class PageBuilderBlockDeleteRequested extends PageBuilderEvent {
  final String blockId;

  const PageBuilderBlockDeleteRequested(this.blockId);

  @override
  List<Object?> get props => [blockId];

  @override
  String toString() => 'PageBuilderBlockDeleteRequested(blockId: $blockId)';
}

/// Reorder blocks (drag & drop)
class PageBuilderBlockReorderRequested extends PageBuilderEvent {
  final int oldIndex;
  final int newIndex;

  const PageBuilderBlockReorderRequested({
    required this.oldIndex,
    required this.newIndex,
  });

  @override
  List<Object?> get props => [oldIndex, newIndex];

  @override
  String toString() =>
      'PageBuilderBlockReorderRequested(from: $oldIndex, to: $newIndex)';
}

/// Duplicate a block
class PageBuilderBlockDuplicateRequested extends PageBuilderEvent {
  final String blockId;

  const PageBuilderBlockDuplicateRequested(this.blockId);

  @override
  List<Object?> get props => [blockId];

  @override
  String toString() => 'PageBuilderBlockDuplicateRequested(blockId: $blockId)';
}

/// Select a block for editing
class PageBuilderBlockSelectRequested extends PageBuilderEvent {
  final String? blockId;

  const PageBuilderBlockSelectRequested(this.blockId);

  @override
  List<Object?> get props => [blockId];

  @override
  String toString() => 'PageBuilderBlockSelectRequested(blockId: $blockId)';
}

// ========================================
// SAVING
// ========================================

/// Save all changes
class PageBuilderSaveRequested extends PageBuilderEvent {
  final String memorialId;

  const PageBuilderSaveRequested(this.memorialId);

  @override
  List<Object?> get props => [memorialId];

  @override
  String toString() => 'PageBuilderSaveRequested(memorialId: $memorialId)';
}

/// Auto-save changes
class PageBuilderAutoSaveRequested extends PageBuilderEvent {
  final String memorialId;

  const PageBuilderAutoSaveRequested(this.memorialId);

  @override
  List<Object?> get props => [memorialId];

  @override
  String toString() => 'PageBuilderAutoSaveRequested(memorialId: $memorialId)';
}

// ========================================
// UNDO/REDO
// ========================================

/// Undo last change
class PageBuilderUndoRequested extends PageBuilderEvent {
  const PageBuilderUndoRequested();

  @override
  String toString() => 'PageBuilderUndoRequested()';
}

/// Redo last undone change
class PageBuilderRedoRequested extends PageBuilderEvent {
  const PageBuilderRedoRequested();

  @override
  String toString() => 'PageBuilderRedoRequested()';
}

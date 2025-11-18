import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:rememberme/data/models/content_block_model.dart';
import 'package:rememberme/data/models/memorial_page_model.dart';
import 'package:rememberme/business_logic/memorial/memorial_bloc.dart';
import 'package:rememberme/business_logic/memorial/memorial_event.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import '../../widgets/page_builder/content_block_widget.dart';
import '../../widgets/page_builder/add_block_bottom_sheet.dart';
import '../../widgets/page_builder/block_settings_bottom_sheet.dart';

class IntuitivePageBuilderScreen extends StatefulWidget {
  final MemorialPageModel memorial;

  const IntuitivePageBuilderScreen({
    super.key,
    required this.memorial,
  });

  @override
  State<IntuitivePageBuilderScreen> createState() =>
      _IntuitivePageBuilderScreenState();
}

class _IntuitivePageBuilderScreenState
    extends State<IntuitivePageBuilderScreen> {
  List<ContentBlock> _blocks = [];
  String? _selectedBlockId;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadMemorialContent();
  }

  void _loadMemorialContent() {
    _blocks = List.from(widget.memorial.contentBlocks);
    print('📦 Geladene Blöcke: ${_blocks.length}');
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _showSuccessMessage(String message) {
    if (Platform.isIOS) {
      // iOS: CupertinoAlertDialog
      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => CupertinoAlertDialog(
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      // Android: Material Design Dialog
      final isDark = Theme.of(context).brightness == Brightness.dark;

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.5)
                      : Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.success.withOpacity(0.2),
                        AppColors.success.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 48,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Auto-dismiss after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    if (Platform.isIOS) {
      // iOS: CupertinoAlertDialog
      final shouldPop = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Ungespeicherte Änderungen'),
          content: const Text(
            'Du hast ungespeicherte Änderungen. Möchtest du wirklich zurück?',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Abbrechen'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Verwerfen'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    } else {
      // Android: Material Design Dialog
      final isDark = Theme.of(context).brightness == Brightness.dark;

      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? AppColors.error.withOpacity(0.3)
                    : Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.5)
                      : Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.error.withOpacity(0.2),
                        AppColors.error.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    size: 56,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Ungespeicherte Änderungen',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Du hast ungespeicherte Änderungen. Möchtest du wirklich zurück?',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? const Color(0xFFB0B0B0)
                              : AppColors.textSecondary,
                          height: 1.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF404040)
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Abbrechen',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textLight
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Verwerfen',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );

      return shouldPop ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
        appBar: AppBar(
          title: Text(widget.memorial.name),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
          foregroundColor: AppColors.textLight,
          actions: [
            // Unsaved changes indicator
            if (_hasUnsavedChanges)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.circle, color: Colors.orange, size: 8),
                        SizedBox(width: 6),
                        Text(
                          'Nicht gespeichert',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Preview
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.visibility_rounded),
                onPressed: _showPreview,
                tooltip: 'Vorschau',
              ),
            ),
            // Save
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success,
                    AppColors.success.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.check_rounded),
                onPressed: _save,
                tooltip: 'Speichern',
                color: Colors.white,
              ),
            ),
          ],
        ),
        body: _blocks.isEmpty
            ? _buildEmptyState(isDark)
            : _buildBlockList(isDark),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddBlockSheet,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Block hinzufügen'),
          backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.primaryLight.withOpacity(0.2),
                          AppColors.primaryLight.withOpacity(0.1),
                        ]
                      : [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.08),
                        ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.primaryLight.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.article_outlined,
                size: 80,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Noch keine Inhalte',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Füge deinen ersten Block hinzu,\num deine Gedenkseite zu gestalten',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? const Color(0xFFB0B0B0)
                        : AppColors.textSecondary,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.primaryLight,
                          AppColors.primaryLight.withOpacity(0.8),
                        ]
                      : [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.9),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? AppColors.primaryLight.withOpacity(0.3)
                        : AppColors.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _showAddBlockSheet,
                icon: const Icon(Icons.add_rounded, size: 24),
                label: const Text(
                  'Block hinzufügen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockList(bool isDark) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _blocks.length + 1,
      onReorder: _reorderBlocks,
      itemBuilder: (context, index) {
        if (index == _blocks.length) {
          return _buildAddBlockButton(
              key: const ValueKey('add-button'), isDark: isDark);
        }

        final block = _blocks[index];
        final isSelected = block.id == _selectedBlockId;

        return ContentBlockWidget(
          key: ValueKey(block.id),
          block: block,
          isSelected: isSelected,
          onTap: () => _selectBlock(block.id),
          onEdit: () => _showBlockSettings(block),
          onDuplicate: () => _duplicateBlock(block),
          onDelete: () => _deleteBlock(block.id),
          onContentChanged: (key, value) =>
              _updateBlockContent(block.id, key, value),
        );
      },
    );
  }

  Widget _buildAddBlockButton({required Key key, required bool isDark}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(top: 16),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.primaryLight.withOpacity(0.3)
                  : AppColors.primary.withOpacity(0.3),
              width: 2,
              style: BorderStyle.solid,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showAddBlockSheet,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  AppColors.primaryLight.withOpacity(0.25),
                                  AppColors.primaryLight.withOpacity(0.15),
                                ]
                              : [
                                  AppColors.primary.withOpacity(0.15),
                                  AppColors.primary.withOpacity(0.08),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppColors.primaryLight.withOpacity(0.3)
                              : AppColors.primary.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Weiteren Block hinzufügen',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                            letterSpacing: 0.15,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== BLOCK MANAGEMENT =====

  void _selectBlock(String blockId) {
    setState(() {
      _selectedBlockId = _selectedBlockId == blockId ? null : blockId;
    });
  }

  void _showAddBlockSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddBlockBottomSheet(
        onBlockTypeSelected: (type) {
          _addBlock(type);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _addBlock(ContentBlockType type) {
    setState(() {
      final newBlock = ContentBlock(type: type);
      _blocks.add(newBlock);
      _selectedBlockId = newBlock.id;
      _markAsChanged();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (type == ContentBlockType.text || type == ContentBlockType.header) {
        _showBlockSettings(_blocks.last);
      }
    });
  }

  void _duplicateBlock(ContentBlock block) {
    setState(() {
      final duplicate = ContentBlock(
        type: block.type,
        content: Map<String, dynamic>.from(block.content),
      );
      final index = _blocks.indexWhere((b) => b.id == block.id);
      _blocks.insert(index + 1, duplicate);
      _selectedBlockId = duplicate.id;
      _markAsChanged();
    });
  }

  void _deleteBlock(String blockId) {
    if (Platform.isIOS) {
      // iOS: CupertinoAlertDialog
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Block löschen?'),
          content: const Text('Möchtest du diesen Block wirklich löschen?'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Abbrechen'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Löschen'),
              onPressed: () {
                setState(() {
                  _blocks.removeWhere((b) => b.id == blockId);
                  if (_selectedBlockId == blockId) {
                    _selectedBlockId = null;
                  }
                  _markAsChanged();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    } else {
      // Android: Material Design Dialog
      final isDark = Theme.of(context).brightness == Brightness.dark;

      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? AppColors.error.withOpacity(0.3)
                    : Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.5)
                      : Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.error.withOpacity(0.2),
                        AppColors.error.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    size: 56,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Block löschen?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Möchtest du diesen Block wirklich löschen?',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? const Color(0xFFB0B0B0)
                              : AppColors.textSecondary,
                          height: 1.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF404040)
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Abbrechen',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textLight
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _blocks.removeWhere((b) => b.id == blockId);
                              if (_selectedBlockId == blockId) {
                                _selectedBlockId = null;
                              }
                              _markAsChanged();
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Löschen',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _reorderBlocks(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final block = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, block);
      _markAsChanged();
    });
  }

  void _updateBlockContent(String blockId, String key, dynamic value) {
    setState(() {
      final index = _blocks.indexWhere((b) => b.id == blockId);
      if (index != -1) {
        _blocks[index] = _blocks[index].updateContent(key, value);
        _markAsChanged();
      }
    });
  }

  void _showBlockSettings(ContentBlock block) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlockSettingsBottomSheet(
        block: block,
        memorialId: widget.memorial.id,
        onUpdate: (key, value) => _updateBlockContent(block.id, key, value),
      ),
    );
  }

  // ===== ACTIONS =====

  void _showPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PreviewScreen(
          memorial: widget.memorial,
          blocks: _blocks,
        ),
      ),
    );
  }

  void _save() {
    print('💾 Speichere ${_blocks.length} Blöcke...');

    final updatedMemorial = widget.memorial.copyWith(
      contentBlocks: _blocks,
    );

    context.read<MemorialBloc>().add(
          MemorialUpdateRequested(memorial: updatedMemorial),
        );

    setState(() {
      _hasUnsavedChanges = false;
    });

    _showSuccessMessage('✓ Seite gespeichert');

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }
}

// ===== PREVIEW SCREEN =====

class _PreviewScreen extends StatelessWidget {
  final MemorialPageModel memorial;
  final List<ContentBlock> blocks;

  const _PreviewScreen({
    required this.memorial,
    required this.blocks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text('Vorschau - ${memorial.name}'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: blocks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.preview_rounded,
                    size: 64,
                    color:
                        isDark ? const Color(0xFF404040) : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Keine Blöcke vorhanden',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? const Color(0xFF808080)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: blocks.length,
              itemBuilder: (context, index) {
                return ContentBlockWidget(
                  block: blocks[index],
                  isSelected: false,
                  isPreview: true,
                  onTap: () {},
                  onEdit: () {},
                  onDuplicate: () {},
                  onDelete: () {},
                  onContentChanged: (_, __) {},
                );
              },
            ),
    );
  }
}

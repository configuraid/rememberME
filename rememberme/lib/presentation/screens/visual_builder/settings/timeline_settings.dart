import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/data/services/firebase_storage_service.dart';

class TimelineSettings extends StatefulWidget {
  final Map<String, dynamic> content;
  final String memorialId;
  final String blockId;
  final ValueChanged<List<Map<String, dynamic>>> onEntriesChanged;

  const TimelineSettings({
    super.key,
    required this.content,
    required this.memorialId,
    required this.blockId,
    required this.onEntriesChanged,
  });

  @override
  State<TimelineSettings> createState() => _TimelineSettingsState();
}

class _TimelineSettingsState extends State<TimelineSettings> {
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _entries = List<Map<String, dynamic>>.from(widget.content['entries'] ?? []);
  }

  void _notifyChange() {
    widget.onEntriesChanged(_entries);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info hint
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.accent.withOpacity(0.1)
                : AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? AppColors.accent.withOpacity(0.3)
                  : AppColors.primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Geburts- und Sterbedatum werden automatisch aus den Profildaten übernommen.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Preview
        _buildTimelinePreview(isDark),
        const SizedBox(height: 24),

        // Entries List
        if (_entries.isNotEmpty) ...[
          _buildEntriesList(isDark),
          const SizedBox(height: 16),
        ],

        // Add Entry Button
        _buildAddEntryButton(isDark),

        // Clear All Button
        if (_entries.length > 1) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _entries.clear();
              });
              _notifyChange();
            },
            icon:
                const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
            label: const Text(
              'Alle Ereignisse entfernen',
              style: TextStyle(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.error.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimelinePreview(bool isDark) {
    if (_entries.isEmpty) {
      return _buildEmptyState(isDark);
    }

    final previewEntries = _entries.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLighter,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_rounded,
                size: 14,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Vorschau',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '${_entries.length} Ereignis${_entries.length == 1 ? '' : 'se'}',
                style: TextStyle(fontSize: 11, color: AppColors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...previewEntries.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == previewEntries.length - 1;
            return _buildPreviewEntry(item, isLast, isDark);
          }),
          if (_entries.length > 3)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 8),
              child: Text(
                '+ ${_entries.length - 3} weitere...',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewEntry(
      Map<String, dynamic> entry, bool isLast, bool isDark) {
    final date = entry['date'] as String? ?? '';
    final label = entry['label'] as String? ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isDark ? AppColors.accent : AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isDark
                    ? AppColors.accent.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.accent : AppColors.primary,
                  ),
                ),
                if (label.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDarkElevated
            : AppColors.greyLighter.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLight,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Platform.isIOS ? CupertinoIcons.time : Icons.timeline_rounded,
            size: 48,
            color: AppColors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            'Noch keine Ereignisse',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Füge wichtige Lebensereignisse hinzu',
            style: TextStyle(fontSize: 13, color: AppColors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ereignisse (${_entries.length})',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_entries.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildEntryCard(index, isDark),
          );
        }),
      ],
    );
  }

  Widget _buildEntryCard(int index, bool isDark) {
    final entry = _entries[index];
    final date = entry['date'] as String? ?? '';
    final label = entry['label'] as String? ?? '';
    final imageUrl = entry['imageUrl'] as String? ?? '';
    final text = entry['text'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLighter,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator_rounded,
            color: AppColors.grey.withOpacity(0.5),
            size: 20,
          ),
          const SizedBox(width: 8),
          if (imageUrl.isNotEmpty)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.greyLighter,
                    child: Icon(Icons.image, size: 20, color: AppColors.grey),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.accent : AppColors.primary,
                  ),
                ),
                if (label.isNotEmpty)
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (text.isNotEmpty)
                  Text(
                    text,
                    style: TextStyle(fontSize: 11, color: AppColors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _editEntry(index),
            icon: Icon(
              Platform.isIOS ? CupertinoIcons.pencil : Icons.edit_rounded,
              size: 20,
            ),
            color: isDark ? AppColors.accent : AppColors.primary,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            onPressed: () => _deleteEntry(index),
            icon: Icon(
              Platform.isIOS ? CupertinoIcons.trash : Icons.delete_outline,
              size: 20,
            ),
            color: AppColors.error,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildAddEntryButton(bool isDark) {
    return GestureDetector(
      onTap: _addEntry,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.accent.withOpacity(0.15),
                    AppColors.accent.withOpacity(0.05),
                  ]
                : [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.03),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.accent.withOpacity(0.3)
                : AppColors.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.accent : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                size: 20,
                color: isDark ? AppColors.primary : AppColors.background,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Ereignis hinzufügen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addEntry() {
    _showEntryDialog(null, -1);
  }

  void _editEntry(int index) {
    _showEntryDialog(_entries[index], index);
  }

  void _deleteEntry(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _entries.removeAt(index);
    });
    _notifyChange();
  }

  void _showEntryDialog(Map<String, dynamic>? entry, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = entry != null;

    String date = entry?['date'] ?? '';
    String label = entry?['label'] ?? '';
    String imageUrl = entry?['imageUrl'] ?? '';
    String text = entry?['text'] ?? '';

    final dateController = TextEditingController(text: date);
    final labelController = TextEditingController(text: label);
    final textController = TextEditingController(text: text);

    bool isUploadingImage = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDarkElevated
                    : AppColors.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.borderDark : AppColors.greyLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Abbrechen',
                              style: TextStyle(color: AppColors.grey)),
                        ),
                        const Spacer(),
                        Text(
                          isEditing ? 'Bearbeiten' : 'Ereignis',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            if (dateController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bitte Datum eingeben'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            final newEntry = {
                              'id': entry?['id'] ?? const Uuid().v4(),
                              'date': dateController.text.trim(),
                              'label': labelController.text.trim(),
                              'imageUrl': imageUrl,
                              'text': textController.text.trim(),
                            };

                            setState(() {
                              if (isEditing) {
                                _entries[index] = newEntry;
                              } else {
                                _entries.add(newEntry);
                              }
                            });
                            _notifyChange();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Speichern',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? AppColors.accent : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Date
                        Text(
                          'Datum *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: dateController,
                          decoration: InputDecoration(
                            hintText: 'z.B. 1985, März 1990, 15.06.2000',
                            filled: true,
                            fillColor: isDark
                                ? AppColors.backgroundDark
                                : AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Label
                        Text(
                          'Bezeichnung',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: labelController,
                          decoration: InputDecoration(
                            hintText: 'z.B. Geburt, Hochzeit, Umzug',
                            filled: true,
                            fillColor: isDark
                                ? AppColors.backgroundDark
                                : AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Image
                        Text(
                          'Bild',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: isUploadingImage
                              ? null
                              : () async {
                                  final XFile? image =
                                      await _imagePicker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 1920,
                                    maxHeight: 1920,
                                    imageQuality: 85,
                                  );
                                  if (image == null) return;

                                  setDialogState(() => isUploadingImage = true);

                                  try {
                                    final url =
                                        await _storageService.uploadBlockImage(
                                      memorialId: widget.memorialId,
                                      blockId:
                                          '${widget.blockId}_timeline_${DateTime.now().millisecondsSinceEpoch}',
                                      imageFile: File(image.path),
                                    );
                                    setDialogState(() {
                                      imageUrl = url;
                                      isUploadingImage = false;
                                    });
                                  } catch (e) {
                                    setDialogState(
                                        () => isUploadingImage = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Upload fehlgeschlagen: $e'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.backgroundDark
                                  : AppColors.greyLighter,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.greyLight,
                              ),
                            ),
                            child: isUploadingImage
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : imageUrl.isNotEmpty
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                      Icons.broken_image),
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () => setDialogState(
                                                  () => imageUrl = ''),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: AppColors.error,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: AppColors.textLight,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_rounded,
                                            size: 32,
                                            color: AppColors.grey,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Bild hinzufügen',
                                            style: TextStyle(
                                                color: AppColors.grey),
                                          ),
                                        ],
                                      ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Description
                        Text(
                          'Beschreibung',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: textController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Optionale Beschreibung...',
                            filled: true,
                            fillColor: isDark
                                ? AppColors.backgroundDark
                                : AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

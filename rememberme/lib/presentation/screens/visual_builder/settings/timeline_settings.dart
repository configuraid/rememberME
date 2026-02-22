import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/data/services/firebase_storage_service.dart';
import 'package:rememberme/presentation/screens/visual_builder/widgets/live_preview_container.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
      children: [
        // ===== STICKY: Live Preview oben fixiert =====
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: LivePreviewContainer(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: _entries.isEmpty
                  ? _buildEmptyPreview(isDark)
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildTimelinePreview(isDark),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ===== SCROLLBAR: Einstellungen scrollen darunter =====
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add Entry Button
                _buildAddEntryButton(isDark),

                // Clear All Button
                if (_entries.length > 1) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _entries.clear();
                        });
                        _notifyChange();
                      },
                      icon: const Icon(Icons.delete_sweep_rounded,
                          color: AppColors.error),
                      label: const Text(
                        'Alle Ereignisse entfernen',
                        style: TextStyle(color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side:
                            BorderSide(color: AppColors.error.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],

                // Entries List
                if (_entries.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Ereignisse (${_entries.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_entries.length, (index) {
                    final entry = _entries[index];
                    final entryId = entry['id'] ?? index.toString();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Slidable(
                        key: ValueKey('slide_$entryId'),
                        endActionPane: ActionPane(
                          motion: const BehindMotion(),
                          extentRatio: 0.3,
                          children: [
                            SlidableAction(
                              onPressed: (_) {
                                HapticFeedback.lightImpact();
                                _editEntry(index);
                              },
                              backgroundColor:
                                  isDark ? AppColors.accent : AppColors.primary,
                              foregroundColor: isDark
                                  ? AppColors.primary
                                  : AppColors.textLight,
                              icon: Platform.isIOS
                                  ? CupertinoIcons.pencil
                                  : Icons.edit_rounded,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                            SlidableAction(
                              onPressed: (_) {
                                HapticFeedback.mediumImpact();
                                setState(() {
                                  _entries.removeAt(index);
                                });
                                _notifyChange();
                              },
                              backgroundColor: AppColors.error,
                              foregroundColor: AppColors.textLight,
                              icon: Platform.isIOS
                                  ? CupertinoIcons.trash_fill
                                  : Icons.delete_rounded,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                          ],
                        ),
                        child: _buildEntryCard(index, isDark),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Timeline Live-Preview
  // ============================================================

  Widget _buildEmptyPreview(bool isDark) {
    return Column(
      children: [
        Icon(
          Platform.isIOS ? CupertinoIcons.time : Icons.timeline_rounded,
          size: 32,
          color: AppColors.grey,
        ),
        const SizedBox(height: 8),
        Text(
          'Noch keine Ereignisse',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Füge wichtige Lebensereignisse hinzu',
          style: TextStyle(fontSize: 12, color: AppColors.grey),
        ),
      ],
    );
  }

  Widget _buildTimelinePreview(bool isDark) {
    final previewEntries = _entries;
    final accentColor = isDark ? AppColors.accent : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Anzahl Badge
        Row(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_entries.length} Ereignis${_entries.length == 1 ? '' : 'se'}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Timeline Einträge
        ...previewEntries.asMap().entries.map((e) {
          final index = e.key;
          final item = e.value;
          final isLast = index == previewEntries.length - 1;
          return _buildPreviewEntry(item, isLast, isDark, accentColor);
        }),
      ],
    );
  }

  Widget _buildPreviewEntry(
    Map<String, dynamic> entry,
    bool isLast,
    bool isDark,
    Color accentColor,
  ) {
    final date = entry['date'] as String? ?? '';
    final label = entry['label'] as String? ?? '';
    final imageUrl = entry['imageUrl'] as String? ?? '';
    final hasImage = imageUrl.isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline-Linie + Dot
          SizedBox(
            width: 12,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: accentColor.withOpacity(0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Row(
                children: [
                  // Thumbnail
                  if (hasImage)
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: accentColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: isDark
                                ? AppColors.backgroundDarkElevated
                                : AppColors.greyLighter,
                            child: Icon(Icons.image,
                                size: 14, color: AppColors.grey),
                          ),
                        ),
                      ),
                    ),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                        if (label.isNotEmpty)
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textLight
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Entry Cards (Bearbeitungsliste)
  // ============================================================

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

  // ============================================================
  // Entry Actions
  // ============================================================

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

    DateTime? selectedDate;
    // Versuche bestehendes Datum zu parsen
    if (entry?['date'] != null && entry!['date'].toString().isNotEmpty) {
      try {
        final parts = entry['date'].toString().split('.');
        if (parts.length == 3) {
          selectedDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (_) {}
    }

    String label = entry?['label'] ?? '';
    String imageUrl = entry?['imageUrl'] ?? '';
    String text = entry?['text'] ?? '';

    final labelController = TextEditingController(text: label);
    final textController = TextEditingController(text: text);

    bool isUploadingImage = false;

    String _formatDate(DateTime d) {
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    }

    void _showDatePicker(StateSetter setDialogState) {
      if (Platform.isIOS) {
        DateTime tempDate = selectedDate ?? DateTime.now();
        showCupertinoModalPopup(
          context: context,
          builder: (ctx) => Container(
            height: 300,
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Text(
                          'Abbrechen',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 17,
                            fontFamily: '.SF Pro Text',
                            decoration: TextDecoration.none,
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Text(
                          'Fertig',
                          style: TextStyle(
                            color:
                                isDark ? AppColors.accent : AppColors.primary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            fontFamily: '.SF Pro Text',
                            decoration: TextDecoration.none,
                          ),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selectedDate = tempDate;
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: selectedDate ?? DateTime.now(),
                    minimumDate: DateTime(1900),
                    maximumDate: DateTime.now(),
                    dateOrder: DatePickerDateOrder.dmy,
                    onDateTimeChanged: (dateTime) {
                      tempDate = dateTime;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          locale: const Locale('de', 'DE'),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark
                    ? ColorScheme.dark(
                        primary: AppColors.accent,
                        onPrimary: AppColors.primary,
                        surface: AppColors.backgroundDarkElevated,
                      )
                    : ColorScheme.light(
                        primary: AppColors.primary,
                        onPrimary: AppColors.textLight,
                        surface: AppColors.surface,
                      ),
              ),
              child: child!,
            );
          },
        ).then((picked) {
          if (picked != null) {
            setDialogState(() {
              selectedDate = picked;
            });
          }
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasDate = selectedDate != null;

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
                          onPressed: hasDate
                              ? () {
                                  final newEntry = {
                                    'id': entry?['id'] ?? const Uuid().v4(),
                                    'date': _formatDate(selectedDate!),
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
                                }
                              : null,
                          child: Text(
                            'Speichern',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: hasDate
                                  ? (isDark
                                      ? AppColors.accent
                                      : AppColors.primary)
                                  : AppColors.grey.withOpacity(0.5),
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
                        // Date Picker
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
                        GestureDetector(
                          onTap: () => _showDatePicker(setDialogState),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.backgroundDark
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasDate
                                    ? (isDark
                                        ? AppColors.accent
                                        : AppColors.primary)
                                    : (isDark
                                        ? AppColors.borderDark
                                        : AppColors.greyLight),
                                width: hasDate ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Platform.isIOS
                                      ? CupertinoIcons.calendar
                                      : Icons.calendar_today_rounded,
                                  size: 20,
                                  color: hasDate
                                      ? (isDark
                                          ? AppColors.accent
                                          : AppColors.primary)
                                      : AppColors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    hasDate
                                        ? _formatDate(selectedDate!)
                                        : 'Datum auswählen...',
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: hasDate
                                          ? (isDark
                                              ? AppColors.textLight
                                              : AppColors.textPrimary)
                                          : AppColors.grey,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: AppColors.grey,
                                ),
                              ],
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

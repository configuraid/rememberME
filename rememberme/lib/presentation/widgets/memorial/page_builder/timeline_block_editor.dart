import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class TimelineBlockEditor extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onDataChanged;

  const TimelineBlockEditor({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  @override
  State<TimelineBlockEditor> createState() => _TimelineBlockEditorState();
}

class _TimelineBlockEditorState extends State<TimelineBlockEditor> {
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _events =
        (widget.data['events'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header mit Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Zeitleiste',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            ElevatedButton.icon(
              onPressed: _addEvent,
              icon: const Icon(Icons.add),
              label: const Text('Event hinzufügen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Events Liste
        if (_events.isEmpty) _buildEmptyState() else _buildEventsList(),

        const SizedBox(height: 24),

        // Tipps
        _buildTipsCard(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Noch keine Events',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _addEvent,
              icon: const Icon(Icons.add),
              label: const Text('Erstes Event hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    return Column(
      children: [
        // Info-Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_events.length} Event${_events.length != 1 ? 's' : ''} - Halten und ziehen zum Sortieren',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Reorderable List
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _events.length,
          onReorder: _reorderEvents,
          itemBuilder: (context, index) {
            return _buildEventCard(index, _events[index]);
          },
        ),
      ],
    );
  }

  Widget _buildEventCard(int index, Map<String, dynamic> event) {
    return Card(
      key: ValueKey(event),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.drag_handle),
        title: Text(
          event['title'] ?? 'Event ${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(event['date'] ?? 'Kein Datum'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: AppColors.error),
          onPressed: () => _removeEvent(index),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Datum
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Datum',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(text: event['date']),
                  onChanged: (value) {
                    setState(() {
                      event['date'] = value;
                    });
                    _updateData();
                  },
                ),
                const SizedBox(height: 12),

                // Titel
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Titel',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.title),
                  ),
                  controller: TextEditingController(text: event['title']),
                  onChanged: (value) {
                    setState(() {
                      event['title'] = value;
                    });
                    _updateData();
                  },
                ),
                const SizedBox(height: 12),

                // Beschreibung
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Beschreibung (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
                  controller: TextEditingController(text: event['description']),
                  onChanged: (value) {
                    setState(() {
                      event['description'] = value;
                    });
                    _updateData();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Card(
      color: AppColors.info.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.info),
                const SizedBox(width: 8),
                const Text(
                  'Zeitleisten-Tipps',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTipItem('Sortieren Sie Events chronologisch'),
            _buildTipItem('Verwenden Sie einheitliche Datumsformate'),
            _buildTipItem('5-15 Events sind ideal für eine Timeline'),
            _buildTipItem('Beschreiben Sie wichtige Meilensteine'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _addEvent() {
    setState(() {
      _events.add({
        'date': '',
        'title': '',
        'description': '',
      });
    });
    _updateData();
  }

  void _removeEvent(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Event entfernen'),
        content: const Text('Möchten Sie dieses Event wirklich entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _events.removeAt(index);
              });
              _updateData();
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
  }

  void _reorderEvents(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _events.removeAt(oldIndex);
      _events.insert(newIndex, item);
    });
    _updateData();
  }

  void _updateData() {
    final updatedData = Map<String, dynamic>.from(widget.data);
    updatedData['events'] = _events;
    widget.onDataChanged(updatedData);
  }
}

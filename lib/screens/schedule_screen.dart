import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import '../database/database.dart';
import '../main.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const _eventTypes = ['practice', 'game', 'other'];
  static const _typeLabels = {'practice': 'Practice', 'game': 'Game', 'other': 'Other'};
  static const _typeIcons = {
    'practice': Icons.fitness_center_rounded,
    'game': Icons.sports_rounded,
    'other': Icons.event_rounded,
  };
  static const _typeColors = {
    'practice': Color(0xFF4FC3F7),
    'game': Color(0xFFEF5350),
    'other': Color(0xFFFFA726),
  };

  // ── Add / Edit dialog ──
  Future<void> _showEventDialog({ScheduleEvent? existing}) async {
    final titleC = TextEditingController(text: existing?.title ?? '');
    final locC = TextEditingController(text: existing?.location ?? '');
    final notesC = TextEditingController(text: existing?.notes ?? '');
    String type = existing?.type ?? 'practice';
    DateTime date = existing?.dateTime_ ?? DateTime.now();
    TimeOfDay time = existing != null
        ? TimeOfDay.fromDateTime(existing.dateTime_)
        : TimeOfDay.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing == null ? 'Add Event' : 'Edit Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(titleC, 'Title *'),
                const SizedBox(height: 12),
                // Type selector
                Row(
                  children: _eventTypes.map((t) {
                    final sel = type == t;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ChoiceChip(
                          label: Text(_typeLabels[t]!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: sel ? Colors.white : Colors.white70)),
                          selected: sel,
                          selectedColor: _typeColors[t]!.withValues(alpha: 0.3),
                          backgroundColor: const Color(0xFF121218),
                          side: BorderSide(
                            color: sel
                                ? _typeColors[t]!
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                          onSelected: (_) => setDlg(() => type = t),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Date & time pickers
                Row(
                  children: [
                    Expanded(
                      child: _pickerTile(
                        icon: Icons.calendar_today_rounded,
                        label:
                            '${date.month}/${date.day}/${date.year}',
                        onTap: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) setDlg(() => date = d);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _pickerTile(
                        icon: Icons.access_time_rounded,
                        label: time.format(ctx),
                        onTap: () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: time,
                          );
                          if (t != null) setDlg(() => time = t);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _field(locC, 'Location'),
                const SizedBox(height: 12),
                _field(notesC, 'Notes', maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (titleC.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    if (existing != null) {
      await db.updateEvent(ScheduleEventsCompanion(
        id: Value(existing.id),
        title: Value(titleC.text.trim()),
        dateTime_: Value(dt),
        location: Value(locC.text.trim()),
        type: Value(type),
        notes: Value(notesC.text.trim()),
      ));
    } else {
      await db.insertEvent(ScheduleEventsCompanion(
        title: Value(titleC.text.trim()),
        dateTime_: Value(dt),
        location: Value(locC.text.trim()),
        type: Value(type),
        notes: Value(notesC.text.trim()),
      ));
    }
  }

  Future<void> _confirmDelete(ScheduleEvent e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Event'),
        content: Text('Delete "${e.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: const Color(0xFFEF5350)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await db.deleteEvent(e.id);
  }

  Widget _field(TextEditingController c, String hint, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFF121218),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _pickerTile(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF121218),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF4FC3F7)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Schedule',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('Games & practices',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color:
                                      Colors.white.withValues(alpha: 0.5))),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FC3F7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add_rounded,
                          color: Color(0xFF4FC3F7)),
                      onPressed: () => _showEventDialog(),
                    ),
                  ),
                ],
              ),
            ),

            // Event list (reactive)
            Expanded(
              child: StreamBuilder<List<ScheduleEvent>>(
                stream: db.watchAllEvents(),
                builder: (ctx, snap) {
                  final events = snap.data ?? [];
                  if (events.isEmpty) return _emptyState();
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: events.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _eventCard(events[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventCard(ScheduleEvent e) {
    final color = _typeColors[e.type] ?? const Color(0xFF4FC3F7);
    final icon = _typeIcons[e.type] ?? Icons.event_rounded;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(e.title,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${_formatDate(e.dateTime_)} · ${TimeOfDay.fromDateTime(e.dateTime_).format(context)}'
          '${e.location.isNotEmpty ? ' · ${e.location}' : ''}',
          style: TextStyle(
              fontSize: 12, color: Colors.white.withValues(alpha: 0.45)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_rounded,
                  size: 18, color: Colors.white.withValues(alpha: 0.3)),
              onPressed: () => _showEventDialog(existing: e),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  size: 18, color: Colors.white.withValues(alpha: 0.3)),
              onPressed: () => _confirmDelete(e),
            ),
          ],
        ),
        onTap: () => _showEventDialog(existing: e),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_month_rounded,
                size: 48, color: Color(0xFF4FC3F7)),
          ),
          const SizedBox(height: 20),
          Text('No Events Scheduled',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Add games and practices to your calendar',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}

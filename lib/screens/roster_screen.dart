import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import '../database/database.dart';
import '../main.dart';

class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key});

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

  // Girls lacrosse positions
  const _positions = [
    // Attack
    '1st Home',
    '2nd Home',
    '3rd Home',
    // Midfield
    'Center',
    'Left Attack Wing',
    'Right Attack Wing',
    'Left Defensive Wing',
    'Right Defensive Wing',
    // Defense
    '3rd Man',
    'Cover Point',
    'Point',
    // Goalie
    'Goalie',
  ];

class _RosterScreenState extends State<RosterScreen> {
  // ── Add / Edit dialog ──
  Future<void> _showPlayerDialog({Player? existing}) async {
    final nameC = TextEditingController(text: existing?.name ?? '');
    final numC = TextEditingController(text: existing?.number ?? '');
    String? selectedPosition = existing?.position;
    // If the existing position is empty or not in the list, reset to null
    if (selectedPosition != null &&
        (selectedPosition.isEmpty || !_positions.contains(selectedPosition))) {
      selectedPosition = null;
    }
    final notesC = TextEditingController(text: existing?.notes ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing == null ? 'Add Player' : 'Edit Player'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameC, 'Name *'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(numC, 'Number')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedPosition,
                        hint: Text('Position',
                            style: TextStyle(
                                color:
                                    Colors.white.withValues(alpha: 0.4),
                                fontSize: 14)),
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1A1A24),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF121218),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        items: _positions.map((pos) {
                          return DropdownMenuItem<String>(
                            value: pos,
                            child: Text(pos, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (val) => setDlg(() => selectedPosition = val),
                      ),
                    ),
                  ],
                ),
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
                if (nameC.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    if (existing != null) {
      await db.updatePlayer(PlayersCompanion(
        id: Value(existing.id),
        name: Value(nameC.text.trim()),
        number: Value(numC.text.trim()),
        position: Value(selectedPosition ?? ''),
        notes: Value(notesC.text.trim()),
      ));
    } else {
      await db.insertPlayer(PlayersCompanion(
        name: Value(nameC.text.trim()),
        number: Value(numC.text.trim()),
        position: Value(selectedPosition ?? ''),
        notes: Value(notesC.text.trim()),
      ));
    }
  }

  Future<void> _confirmDelete(Player p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Player'),
        content: Text('Remove ${p.name} from the roster?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF5350)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) await db.deletePlayer(p.id);
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
                      Text('Roster',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('Manage your team',
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
                      icon: const Icon(Icons.person_add_rounded,
                          color: Color(0xFF4FC3F7)),
                      onPressed: () => _showPlayerDialog(),
                    ),
                  ),
                ],
              ),
            ),

            // Player list (reactive)
            Expanded(
              child: StreamBuilder<List<Player>>(
                stream: db.watchAllPlayers(),
                builder: (ctx, snap) {
                  final players = snap.data ?? [];
                  if (players.isEmpty) return _emptyState();
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: players.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _playerCard(players[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerCard(Player p) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF4FC3F7).withValues(alpha: 0.15),
          child: Text(
            p.number.isNotEmpty ? p.number : p.name[0].toUpperCase(),
            style: const TextStyle(
                color: Color(0xFF4FC3F7), fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(p.name,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: p.position.isNotEmpty
            ? Text(p.position,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.45)))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_rounded,
                  size: 18, color: Colors.white.withValues(alpha: 0.3)),
              onPressed: () => _showPlayerDialog(existing: p),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  size: 18, color: Colors.white.withValues(alpha: 0.3)),
              onPressed: () => _confirmDelete(p),
            ),
          ],
        ),
        onTap: () => _showPlayerDialog(existing: p),
      ),
    );
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
            child: const Icon(Icons.groups_rounded,
                size: 48, color: Color(0xFF4FC3F7)),
          ),
          const SizedBox(height: 20),
          Text('No Players Yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Add players to build your roster',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}

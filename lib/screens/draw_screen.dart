import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import '../database/database.dart';
import '../main.dart';
import '../models/drawing_stroke.dart';
import '../models/player_token.dart';
import '../models/sport.dart';
import '../painters/drawing_painter.dart';
import '../painters/token_painter.dart';
import '../utils/stroke_utils.dart';

class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  // ── Strokes ──
  final List<DrawingStroke> _strokes = [];
  List<Offset> _currentPoints = [];

  // ── Tokens ──
  final List<PlayerToken> _tokens = [];
  int? _draggingIndex;
  Offset? _dragStartPos;
  bool _wasExistingToken = false;

  // ── Play metadata ──
  int? _currentPlayId;
  String? _currentPlayName;

  // ── Sport ──
  Sport _sport = Sport.girlsLacrosse;

  // ── Tool state ──
  bool _isPlayerMode = false;
  bool _isOpponent = false;
  Color _selectedColor = Colors.white;
  double _strokeWidth = 3.0;
  int _nextHomeNum = 1;
  int _nextOpponentNum = 1;

  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadSport();
  }

  Future<void> _loadSport() async {
    final value = await db.getSetting(kSportSettingKey);
    if (!mounted) return;
    setState(() => _sport = sportFromString(value));
  }

  static const List<Color> _palette = [
    Colors.white,
    Color(0xFFFFD54F),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFFFFA726),
    Color(0xFF212121),
  ];
  static const List<double> _widths = [2.0, 4.0, 7.0];

  Size? get _canvasSize {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.size;
  }

  // ═══════════════════════════════════════════════════════════
  //  GESTURE HANDLERS
  // ═══════════════════════════════════════════════════════════

  void _onPanStart(DragStartDetails d) {
    if (_isPlayerMode) {
      _handleTokenPanStart(d.localPosition);
    } else {
      _currentPoints = [d.localPosition];
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_isPlayerMode) {
      _handleTokenPanUpdate(d.localPosition);
    } else {
      setState(() => _currentPoints = [..._currentPoints, d.localPosition]);
    }
  }

  void _onPanEnd(DragEndDetails d) {
    if (_isPlayerMode) {
      _handleTokenPanEnd();
    } else {
      if (_currentPoints.isNotEmpty) {
        setState(() {
          _strokes.add(DrawingStroke(
            points: simplifyPoints(_currentPoints),
            color: _selectedColor,
            strokeWidth: _strokeWidth,
          ));
          _currentPoints = [];
        });
      }
    }
  }

  // ── Token gestures ──

  void _handleTokenPanStart(Offset pos) {
    final hit = TokenPainter.tokenAt(_tokens, pos);
    if (hit >= 0) {
      // Start dragging existing token
      _draggingIndex = hit;
      _dragStartPos = pos;
      _wasExistingToken = true;
    } else {
      // Place a new token and start dragging it
      final label = _isOpponent ? '$_nextOpponentNum' : '$_nextHomeNum';
      _tokens.add(PlayerToken(
        label: label,
        position: pos,
        isOpponent: _isOpponent,
      ));
      if (_isOpponent) {
        _nextOpponentNum++;
      } else {
        _nextHomeNum++;
      }
      _draggingIndex = _tokens.length - 1;
      _dragStartPos = pos;
      _wasExistingToken = false;
    }
    setState(() {});
  }

  void _handleTokenPanUpdate(Offset pos) {
    if (_draggingIndex != null) {
      setState(() {
        _tokens[_draggingIndex!].position = pos;
      });
    }
  }

  void _handleTokenPanEnd() {
    // If it was an existing token and barely moved → remove it (tap-to-remove)
    if (_wasExistingToken && _draggingIndex != null && _dragStartPos != null) {
      final moved =
          (_tokens[_draggingIndex!].position - _dragStartPos!).distance;
      if (moved < 4) {
        setState(() {
          _tokens.removeAt(_draggingIndex!);
          _recalcNumbers();
        });
        _draggingIndex = null;
        _dragStartPos = null;
        return;
      }
    }
    setState(() {
      _draggingIndex = null;
      _dragStartPos = null;
    });
  }

  void _recalcNumbers() {
    int h = 1, o = 1;
    for (final t in _tokens) {
      if (t.isOpponent) {
        t.label = '${o++}';
      } else {
        t.label = '${h++}';
      }
    }
    _nextHomeNum = h;
    _nextOpponentNum = o;
  }

  // ═══════════════════════════════════════════════════════════
  //  UNDO / CLEAR
  // ═══════════════════════════════════════════════════════════

  void _undo() {
    setState(() {
      if (_isPlayerMode && _tokens.isNotEmpty) {
        _tokens.removeLast();
        _recalcNumbers();
      } else if (!_isPlayerMode && _strokes.isNotEmpty) {
        _strokes.removeLast();
      }
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _tokens.clear();
      _currentPoints = [];
      _nextHomeNum = 1;
      _nextOpponentNum = 1;
    });
  }

  bool get _hasContent => _strokes.isNotEmpty || _tokens.isNotEmpty;

  // ═══════════════════════════════════════════════════════════
  //  COORDINATE HELPERS
  // ═══════════════════════════════════════════════════════════

  List<Map<String, double>> _normalizePoints(List<Offset> pts, Size s) =>
      pts.map((p) => {'x': p.dx / s.width, 'y': p.dy / s.height}).toList();

  List<Offset> _denormalizePoints(List<Map<String, double>> pts, Size s) =>
      pts.map((p) => Offset(p['x']! * s.width, p['y']! * s.height)).toList();

  // ═══════════════════════════════════════════════════════════
  //  SAVE / LOAD / NEW
  // ═══════════════════════════════════════════════════════════

  Future<void> _savePlay() async {
    final size = _canvasSize;
    if (size == null || !_hasContent) return;

    final nameC = TextEditingController(text: _currentPlayName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Save Play'),
        content: TextField(
          controller: nameC,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Play name',
            filled: true,
            fillColor: const Color(0xFF121218),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, nameC.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    // Build stroke companions
    final strokeCs = <PlayStrokesCompanion>[];
    for (int i = 0; i < _strokes.length; i++) {
      final s = _strokes[i];
      strokeCs.add(PlayStrokesCompanion(
        pointsJson: Value(encodePoints(_normalizePoints(s.points, size))),
        color: Value(s.color.toARGB32()),
        strokeWidth: Value(s.strokeWidth),
        orderIndex: Value(i),
      ));
    }

    // Build token companions
    final tokenCs = <PlayTokensCompanion>[];
    for (int i = 0; i < _tokens.length; i++) {
      final t = _tokens[i];
      tokenCs.add(PlayTokensCompanion(
        label: Value(t.label),
        x: Value(t.position.dx / size.width),
        y: Value(t.position.dy / size.height),
        isOpponent: Value(t.isOpponent),
        orderIndex: Value(i),
      ));
    }

    if (_currentPlayId != null) {
      await db.updatePlay(_currentPlayId!, name, strokeCs, tokenCs);
    } else {
      final id = await db.insertPlay(name, strokeCs, tokenCs);
      _currentPlayId = id;
    }
    _currentPlayName = name;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "$name"'),
          backgroundColor: const Color(0xFF1A1A24),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadPlay(Play play) async {
    final size = _canvasSize;
    if (size == null) return;

    final dbStrokes = await db.getStrokesForPlay(play.id);
    final dbTokens = await db.getTokensForPlay(play.id);

    final loadedStrokes = <DrawingStroke>[];
    for (final s in dbStrokes) {
      final pts = decodePoints(s.pointsJson);
      loadedStrokes.add(DrawingStroke(
        points: _denormalizePoints(pts, size),
        color: Color(s.color),
        strokeWidth: s.strokeWidth,
      ));
    }

    final loadedTokens = <PlayerToken>[];
    for (final t in dbTokens) {
      loadedTokens.add(PlayerToken(
        label: t.label,
        position: Offset(t.x * size.width, t.y * size.height),
        isOpponent: t.isOpponent,
      ));
    }

    setState(() {
      _strokes
        ..clear()
        ..addAll(loadedStrokes);
      _tokens
        ..clear()
        ..addAll(loadedTokens);
      _currentPoints = [];
      _currentPlayId = play.id;
      _currentPlayName = play.name;
      _recalcNumbers();
    });
  }

  void _newPlay() {
    setState(() {
      _strokes.clear();
      _tokens.clear();
      _currentPoints = [];
      _currentPlayId = null;
      _currentPlayName = null;
      _nextHomeNum = 1;
      _nextOpponentNum = 1;
    });
  }

  void _showPlaysSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _PlaysSheet(
        onLoad: (play) {
          Navigator.pop(ctx);
          _loadPlay(play);
        },
        onDelete: (play) async {
          await db.deletePlay(play.id);
          if (play.id == _currentPlayId) _newPlay();
        },
        onNewPlay: () {
          Navigator.pop(ctx);
          _newPlay();
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildCanvas()),
            _buildModeBar(context),
            if (_isPlayerMode) _buildTeamBar(context) else _buildPenToolbar(context),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentPlayName ?? 'Plays',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700, letterSpacing: -0.5),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Design plays · ${sportConfigs[_sport]!.displayName}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white.withValues(alpha: 0.45)),
                ),
              ],
            ),
          ),
          _headerBtn(Icons.folder_open_rounded, 'Saved Plays', _showPlaysSheet),
          _headerBtn(
              Icons.save_rounded, 'Save', _hasContent ? _savePlay : null),
          _headerBtn(Icons.undo_rounded, 'Undo',
              _hasContent ? _undo : null),
          _headerBtn(Icons.delete_outline_rounded, 'Clear',
              _hasContent ? _clear : null),
        ],
      ),
    );
  }

  Widget _headerBtn(IconData icon, String tip, VoidCallback? onTap) {
    final ok = onTap != null;
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon,
              size: 21,
              color: ok
                  ? const Color(0xFF4FC3F7)
                  : Colors.white.withValues(alpha: 0.15)),
        ),
      ),
    );
  }

  // ── Canvas ──
  Widget _buildCanvas() {
    final config = sportConfigs[_sport]!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(
        child: AspectRatio(
          // Matches the field/court's real proportions so it fills the
          // canvas edge-to-edge instead of floating inside a letterboxed gap.
          aspectRatio: config.aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: RepaintBoundary(
                child: Stack(
                  children: [
                    // Field background
                    Positioned.fill(
                      child: CustomPaint(
                        key: _canvasKey,
                        painter: config.implemented ? config.fieldPainter() : null,
                        child: config.implemented
                            ? const SizedBox.expand()
                            : _ComingSoonField(config: config),
                      ),
                    ),
                    // Tokens layer (between field and strokes)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: TokenPainter(
                          tokens: _tokens,
                          draggingIndex: _draggingIndex,
                        ),
                      ),
                    ),
                    // Drawing strokes layer (on top)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: DrawingPainter(
                          strokes: _strokes,
                          currentPoints: _currentPoints,
                          currentColor: _selectedColor,
                          currentStrokeWidth: _strokeWidth,
                        ),
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

  // ── Mode toggle bar ──
  Widget _buildModeBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A24),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  _modeChip(Icons.edit_rounded, 'Pen', !_isPlayerMode, () {
                    setState(() => _isPlayerMode = false);
                  }),
                  const SizedBox(width: 4),
                  _modeChip(Icons.person_pin_rounded, 'Players', _isPlayerMode,
                      () {
                    setState(() => _isPlayerMode = true);
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(
      IconData icon, String label, bool selected, VoidCallback onTap) {
    const accent = Color(0xFF4FC3F7);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected
                      ? accent
                      : Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected
                        ? accent
                        : Colors.white.withValues(alpha: 0.4),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Team toggle (shown in player mode) ──
  Widget _buildTeamBar(BuildContext context) {
    const home = Color(0xFF42A5F5);
    const opp = Color(0xFFEF5350);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Text('Place:',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.45))),
          const SizedBox(width: 12),
          _teamChip('Home', home, !_isOpponent, () {
            setState(() => _isOpponent = false);
          }),
          const SizedBox(width: 8),
          _teamChip('Opponent', opp, _isOpponent, () {
            setState(() => _isOpponent = true);
          }),
          const Spacer(),
          Text(
            'Tap field to place · Tap token to remove',
            style: TextStyle(
                fontSize: 10, color: Colors.white.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }

  Widget _teamChip(
      String label, Color color, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                )),
          ],
        ),
      ),
    );
  }

  // ── Pen toolbar (shown in pen mode) ──
  Widget _buildPenToolbar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: _palette.map((c) => _colorChip(c)).toList(),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: Colors.white.withValues(alpha: 0.1),
          ),
          ..._widths.map((w) => _widthDot(w)),
        ],
      ),
    );
  }

  Widget _colorChip(Color color) {
    final sel = _selectedColor == color;
    final dark = color.computeLuminance() < 0.15;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: sel
                ? const Color(0xFF4FC3F7)
                : (dark
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.transparent),
            width: sel ? 2.5 : 1,
          ),
          boxShadow: sel
              ? [
                  BoxShadow(
                      color: const Color(0xFF4FC3F7).withValues(alpha: 0.35),
                      blurRadius: 8)
                ]
              : null,
        ),
      ),
    );
  }

  Widget _widthDot(double w) {
    final sel = _strokeWidth == w;
    return GestureDetector(
      onTap: () => setState(() => _strokeWidth = w),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: sel
              ? const Color(0xFF4FC3F7).withValues(alpha: 0.15)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: sel
                ? const Color(0xFF4FC3F7)
                : Colors.white.withValues(alpha: 0.12),
            width: sel ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Container(
            width: w + 2,
            height: w + 2,
            decoration: BoxDecoration(
              color: sel
                  ? const Color(0xFF4FC3F7)
                  : Colors.white.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
//  Saved-plays bottom sheet
// ═════════════════════════════════════════════════════════════

class _PlaysSheet extends StatelessWidget {
  final void Function(Play) onLoad;
  final void Function(Play) onDelete;
  final VoidCallback onNewPlay;

  const _PlaysSheet({
    required this.onLoad,
    required this.onDelete,
    required this.onNewPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Saved Plays',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton.icon(
                onPressed: onNewPlay,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            child: StreamBuilder<List<Play>>(
              stream: db.watchAllPlays(),
              builder: (ctx, snap) {
                final plays = snap.data ?? [];
                if (plays.isEmpty) {
                  return Center(
                    child: Text('No saved plays yet',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4))),
                  );
                }
                return ListView.separated(
                  itemCount: plays.length,
                  separatorBuilder: (_, _) => Divider(
                      height: 1, color: Colors.white.withValues(alpha: 0.06)),
                  itemBuilder: (_, i) {
                    final p = plays[i];
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF4FC3F7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.draw_rounded,
                            color: Color(0xFF4FC3F7), size: 20),
                      ),
                      title: Text(p.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(
                        _formatDate(p.updatedAt),
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline,
                            size: 20,
                            color: Colors.white.withValues(alpha: 0.3)),
                        onPressed: () => onDelete(p),
                      ),
                      onTap: () => onLoad(p),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ═════════════════════════════════════════════════════════════
//  Placeholder shown for sports without a field/court painter yet
// ═════════════════════════════════════════════════════════════

class _ComingSoonField extends StatelessWidget {
  final SportConfig config;

  const _ComingSoonField({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 40, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            '${config.displayName} field coming soon',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
          ),
        ],
      ),
    );
  }
}

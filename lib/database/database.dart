import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// ═══════════════════════════════════════════════════════════
//  TABLE DEFINITIONS
// ═══════════════════════════════════════════════════════════

/// Saved coaching plays (each play has many strokes).
class Plays extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Individual drawing strokes belonging to a play.
/// Points are stored as JSON, normalized to 0–1 range.
class PlayStrokes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playId => integer().references(Plays, #id)();
  TextColumn get pointsJson => text()(); // [{"x":0.1,"y":0.2}, ...]
  IntColumn get color => integer()(); // Color.value
  RealColumn get strokeWidth => real()();
  IntColumn get orderIndex => integer()(); // preserve draw order
}

/// Player tokens placed on the field as part of a play.
class PlayTokens extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playId => integer().references(Plays, #id)();
  TextColumn get label => text()();
  RealColumn get x => real()(); // normalized 0–1
  RealColumn get y => real()(); // normalized 0–1
  BoolColumn get isOpponent =>
      boolean().withDefault(const Constant(false))();
  IntColumn get orderIndex => integer()();
}

/// Team roster players.
class Players extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get number => text().withDefault(const Constant(''))();
  TextColumn get position => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

/// Schedule events (games, practices, etc.).
class ScheduleEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  DateTimeColumn get dateTime_ => dateTime()();
  TextColumn get location => text().withDefault(const Constant(''))();
  TextColumn get type => text().withDefault(const Constant('practice'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

/// Chat messages.
class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get senderName =>
      text().withDefault(const Constant('Coach'))();
  TextColumn get body => text()();
  DateTimeColumn get timestamp =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Key-value settings (e.g. selected sport).
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ═══════════════════════════════════════════════════════════
//  DATABASE
// ═══════════════════════════════════════════════════════════

@DriftDatabase(
    tables: [Plays, PlayStrokes, PlayTokens, Players, ScheduleEvents, ChatMessages, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(playTokens);
          }
          if (from < 3) {
            await m.createTable(appSettings);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'coaching_board',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  // ─── PLAYS ─────────────────────────────────────────────

  /// Watch all plays, newest first.
  Stream<List<Play>> watchAllPlays() {
    return (select(plays)
          ..orderBy(
              [(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
        .watch();
  }

  /// Get all strokes for a play, in draw order.
  Future<List<PlayStroke>> getStrokesForPlay(int playId) {
    return (select(playStrokes)
          ..where((s) => s.playId.equals(playId))
          ..orderBy([(s) => OrderingTerm.asc(s.orderIndex)]))
        .get();
  }

  /// Get all tokens for a play, in order.
  Future<List<PlayToken>> getTokensForPlay(int playId) {
    return (select(playTokens)
          ..where((t) => t.playId.equals(playId))
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .get();
  }

  /// Insert a new play with its strokes and tokens. Returns the play id.
  Future<int> insertPlay(
    String name,
    List<PlayStrokesCompanion> strokes, [
    List<PlayTokensCompanion> tokens = const [],
  ]) {
    return transaction(() async {
      final playId = await into(plays).insert(
        PlaysCompanion.insert(name: name),
      );
      for (final stroke in strokes) {
        await into(playStrokes).insert(
          stroke.copyWith(playId: Value(playId)),
        );
      }
      for (final token in tokens) {
        await into(playTokens).insert(
          token.copyWith(playId: Value(playId)),
        );
      }
      return playId;
    });
  }

  /// Update an existing play (name + replace all strokes and tokens).
  Future<void> updatePlay(
    int playId,
    String name,
    List<PlayStrokesCompanion> strokes, [
    List<PlayTokensCompanion> tokens = const [],
  ]) {
    return transaction(() async {
      await (update(plays)..where((p) => p.id.equals(playId))).write(
        PlaysCompanion(
          name: Value(name),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await (delete(playStrokes)..where((s) => s.playId.equals(playId))).go();
      for (final stroke in strokes) {
        await into(playStrokes).insert(
          stroke.copyWith(playId: Value(playId)),
        );
      }
      await (delete(playTokens)..where((t) => t.playId.equals(playId))).go();
      for (final token in tokens) {
        await into(playTokens).insert(
          token.copyWith(playId: Value(playId)),
        );
      }
    });
  }

  /// Delete a play, its strokes, and its tokens.
  Future<void> deletePlay(int playId) {
    return transaction(() async {
      await (delete(playTokens)..where((t) => t.playId.equals(playId))).go();
      await (delete(playStrokes)..where((s) => s.playId.equals(playId))).go();
      await (delete(plays)..where((p) => p.id.equals(playId))).go();
    });
  }

  // ─── ROSTER ────────────────────────────────────────────

  /// Watch all players, alphabetical.
  Stream<List<Player>> watchAllPlayers() {
    return (select(players)
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  Future<int> insertPlayer(PlayersCompanion entry) =>
      into(players).insert(entry);

  Future<bool> updatePlayer(PlayersCompanion entry) =>
      update(players).replace(entry);

  Future<int> deletePlayer(int id) =>
      (delete(players)..where((p) => p.id.equals(id))).go();

  // ─── SCHEDULE ──────────────────────────────────────────

  /// Watch all events, soonest first.
  Stream<List<ScheduleEvent>> watchAllEvents() {
    return (select(scheduleEvents)
          ..orderBy([(e) => OrderingTerm.asc(e.dateTime_)]))
        .watch();
  }

  Future<int> insertEvent(ScheduleEventsCompanion entry) =>
      into(scheduleEvents).insert(entry);

  Future<bool> updateEvent(ScheduleEventsCompanion entry) =>
      update(scheduleEvents).replace(entry);

  Future<int> deleteEvent(int id) =>
      (delete(scheduleEvents)..where((e) => e.id.equals(id))).go();

  // ─── CHAT ──────────────────────────────────────────────

  /// Watch all messages, oldest first (chat order).
  Stream<List<ChatMessage>> watchAllMessages() {
    return (select(chatMessages)
          ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
        .watch();
  }

  Future<int> insertMessage(ChatMessagesCompanion entry) =>
      into(chatMessages).insert(entry);

  Future<int> deleteMessage(int id) =>
      (delete(chatMessages)..where((m) => m.id.equals(id))).go();

  // ─── SETTINGS ──────────────────────────────────────────

  /// Get a setting value by key. Returns null if not set.
  Future<String?> getSetting(String key) async {
    final row = await (select(appSettings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// Set a setting value (upsert).
  Future<void> setSetting(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(
        key: Value(key),
        value: Value(value),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  HELPERS — stroke ↔ JSON conversion
// ═══════════════════════════════════════════════════════════

/// Encode normalised points to JSON string.
String encodePoints(List<Map<String, double>> points) => jsonEncode(points);

/// Decode JSON string back to point maps.
List<Map<String, double>> decodePoints(String json) {
  final list = jsonDecode(json) as List;
  return list
      .map((e) => {
            'x': (e['x'] as num).toDouble(),
            'y': (e['y'] as num).toDouble(),
          })
      .toList();
}

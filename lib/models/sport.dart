import 'package:flutter/material.dart';
import '../painters/lacrosse_field_painter.dart';
import '../painters/boys_lacrosse_field_painter.dart';
import '../painters/basketball_court_painter.dart';
import '../painters/volleyball_court_painter.dart';
import '../painters/field_hockey_painter.dart';
import '../painters/soccer_field_painter.dart';

/// All supported sports.
enum Sport {
  girlsLacrosse,
  boysLacrosse,
  basketball,
  volleyball,
  fieldHockey,
  soccer,
}

/// Configuration for each sport: display name, icon, positions, and field painter.
class SportConfig {
  final String displayName;
  final IconData icon;
  final List<String> positions;
  final CustomPainter Function() fieldPainter;

  /// Field/court width ÷ height, used to fit the canvas without letterboxing.
  final double aspectRatio;

  /// Whether [fieldPainter] draws real field markings yet. Sports still
  /// using a placeholder painter show a "coming soon" state instead.
  final bool implemented;

  const SportConfig({
    required this.displayName,
    required this.icon,
    required this.positions,
    required this.fieldPainter,
    required this.aspectRatio,
    this.implemented = true,
  });
}

/// Lookup map — one config per sport.
final Map<Sport, SportConfig> sportConfigs = {
  Sport.girlsLacrosse: SportConfig(
    displayName: 'Girls Lacrosse',
    icon: Icons.sports_rounded,
    positions: const [
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
    ],
    fieldPainter: LacrosseFieldPainter.new,
    aspectRatio: 70 / 120,
  ),
  Sport.boysLacrosse: SportConfig(
    displayName: 'Boys Lacrosse',
    icon: Icons.sports_rounded,
    positions: const [
      // Attack
      '1st Attack',
      '2nd Attack',
      '3rd Attack',
      // Midfield
      'Center',
      'Left Wing Midfield',
      'Right Wing Midfield',
      // Defense
      '1st Defense (Close)',
      '2nd Defense (Cover Point)',
      '3rd Defense (Point)',
      // Goalie
      'Goalie',
    ],
    fieldPainter: BoysLacrosseFieldPainter.new,
    aspectRatio: 60 / 110,
  ),
  Sport.basketball: SportConfig(
    displayName: 'Basketball',
    icon: Icons.sports_basketball_rounded,
    positions: const [
      'Point Guard',
      'Shooting Guard',
      'Small Forward',
      'Power Forward',
      'Center',
    ],
    fieldPainter: BasketballCourtPainter.new,
    aspectRatio: 50 / 84,
    implemented: false,
  ),
  Sport.volleyball: SportConfig(
    displayName: 'Volleyball',
    icon: Icons.sports_volleyball_rounded,
    positions: const [
      'Outside Hitter',
      'Opposite Hitter',
      'Setter',
      'Middle Blocker',
      'Libero',
      'Defensive Specialist',
    ],
    fieldPainter: VolleyballCourtPainter.new,
    aspectRatio: 9 / 18,
    implemented: false,
  ),
  Sport.fieldHockey: SportConfig(
    displayName: 'Field Hockey',
    icon: Icons.sports_hockey_rounded,
    positions: const [
      // Forward
      'Left Wing',
      'Center Forward',
      'Right Wing',
      'Left Inner',
      'Right Inner',
      // Midfield
      'Left Half',
      'Center Half',
      'Right Half',
      // Defense
      'Left Back',
      'Right Back',
      'Sweeper',
      // Goalie
      'Goalkeeper',
    ],
    fieldPainter: FieldHockeyPainter.new,
    aspectRatio: 55 / 91.4,
    implemented: false,
  ),
  Sport.soccer: SportConfig(
    displayName: 'Soccer',
    icon: Icons.sports_soccer_rounded,
    positions: const [
      'Goalkeeper',
      'Center Back',
      'Left Back',
      'Right Back',
      'Wing Back',
      'Defensive Midfielder',
      'Central Midfielder',
      'Attacking Midfielder',
      'Left Winger',
      'Right Winger',
      'Striker',
    ],
    fieldPainter: SoccerFieldPainter.new,
    aspectRatio: 68 / 105,
    implemented: false,
  ),
};

/// AppSettings key under which the selected sport's enum name is stored.
const String kSportSettingKey = 'sport';

/// Parse a Sport from its enum name string. Falls back to girlsLacrosse.
Sport sportFromString(String? value) {
  if (value == null) return Sport.girlsLacrosse;
  return Sport.values.firstWhere(
    (s) => s.name == value,
    orElse: () => Sport.girlsLacrosse,
  );
}

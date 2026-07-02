import 'dart:ui';

/// UI model for a player token on the coaching canvas.
class PlayerToken {
  String label;
  Offset position;
  bool isOpponent;

  PlayerToken({
    required this.label,
    required this.position,
    this.isOpponent = false,
  });
}

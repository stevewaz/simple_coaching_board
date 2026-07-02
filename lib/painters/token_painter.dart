import 'package:flutter/material.dart';
import '../models/player_token.dart';

/// Draws player tokens (numbered circles) on the coaching canvas.
/// Rendered between the field background and drawing strokes.
class TokenPainter extends CustomPainter {
  final List<PlayerToken> tokens;
  final int? draggingIndex;

  static const double radius = 14;
  static const Color homeColor = Color(0xFF42A5F5);
  static const Color opponentColor = Color(0xFFEF5350);

  TokenPainter({required this.tokens, this.draggingIndex});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      final isDragging = i == draggingIndex;
      final color = t.isOpponent ? opponentColor : homeColor;
      final center = t.position;

      // Shadow
      canvas.drawCircle(
        center + const Offset(0, 1.5),
        radius + 1,
        Paint()..color = Colors.black.withValues(alpha: isDragging ? 0.4 : 0.25),
      );

      // Outer ring (highlight when dragging)
      if (isDragging) {
        canvas.drawCircle(
          center,
          radius + 3,
          Paint()
            ..color = color.withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      // Filled circle
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = color,
      );

      // Border
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Label text
      final tp = TextPainter(
        text: TextSpan(
          text: t.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant TokenPainter old) => true;

  /// Check if a point hits a token. Returns the index or -1.
  static int tokenAt(List<PlayerToken> tokens, Offset point) {
    // Search in reverse so topmost (latest) tokens are hit first
    for (int i = tokens.length - 1; i >= 0; i--) {
      if ((tokens[i].position - point).distance <= radius + 6) {
        return i;
      }
    }
    return -1;
  }
}

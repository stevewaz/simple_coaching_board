import 'package:flutter/material.dart';

/// Paints a boys lacrosse field (60 × 110 yards, portrait — length along Y).
///
/// Real-world reference dimensions:
///   - Field: 60 yd wide × 110 yd long
///   - Center line at 55 yd
///   - Wing areas: 20 yd from center line (hash marks on sidelines)
///   - Restraining box: 35 yd wide × 40 yd deep from each goal
///   - Goal crease: 9 ft radius circle (~3 yd)
///   - Goal cage: 6 ft wide × 6 ft deep (~2 yd × 2 yd)
///   - Goal sits 15 yd from end line
///   - GLE (Goal Line Extended): dashed line across field through goal center
class BoysLacrosseFieldPainter extends CustomPainter {
  // ── Field dimensions in yards ──
  static const double _fw = 60; // field width
  static const double _fh = 110; // field height (length)

  // ── Key measurements ──
  static const double _midY = _fh / 2; // center line at 55 yd
  static const double _wingDist = 20; // wing area distance from center
  static const double _goalInset = 15; // goal distance from end line
  static const double _rboxW = 35; // restraining box width
  static const double _rboxD = 40; // restraining box depth from goal

  // ── Goal measurements (converted to yards) ──
  // 9 ft radius = 3 yards
  static const double _creaseR = 3.0;
  // 6 ft = 2 yards
  static const double _goalW = 2.0; // half of 6 ft ≈ 1 yd each side
  static const double _goalD = 2.0; // goal depth

  // ── Pi constant (no dart:math import) ──
  static const double _pi = 3.14159265;

  @override
  void paint(Canvas canvas, Size size) {
    // ── Fit field inside canvas, preserving aspect ratio ──
    final double ar = _fw / _fh;
    final double car = size.width / size.height;
    final Rect fr;
    if (car > ar) {
      final h = size.height;
      final w = h * ar;
      fr = Rect.fromLTWH((size.width - w) / 2, 0, w, h);
    } else {
      final w = size.width;
      final h = w / ar;
      fr = Rect.fromLTWH(0, (size.height - h) / 2, w, h);
    }

    final double s = fr.width / _fw; // uniform scale factor
    double fx(double x) => fr.left + x * s;
    double fy(double y) => fr.top + y * s;
    double fs(double v) => v * s;

    // ── Paints ──
    final fieldBg = Paint()..color = const Color(0xFF1B6B2E);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    // ── Background with rounded rect ──
    final rrect = RRect.fromRectAndRadius(fr, const Radius.circular(10));
    canvas.drawRRect(rrect, fieldBg);

    // ── Subtle turf stripes ──
    final stripe = Paint()..color = Colors.white.withValues(alpha: 0.025);
    canvas.save();
    canvas.clipRRect(rrect);

    final double stripeH = _fh / 11; // 11 stripes ≈ 10 yd each
    for (int i = 0; i < 11; i++) {
      if (i.isEven) {
        canvas.drawRect(
          Rect.fromLTWH(fr.left, fy(i * stripeH), fr.width, fs(stripeH)),
          stripe,
        );
      }
    }

    // ── Field outline ──
    canvas.drawRRect(rrect, line);

    // ── Center line (midfield) ──
    canvas.drawLine(
      Offset(fx(0), fy(_midY)),
      Offset(fx(_fw), fy(_midY)),
      line,
    );

    // ── Center X mark ──
    final double xSize = fs(1.2); // size of each arm of the X
    final Offset center = Offset(fx(_fw / 2), fy(_midY));
    canvas.drawLine(
      Offset(center.dx - xSize, center.dy - xSize),
      Offset(center.dx + xSize, center.dy + xSize),
      line,
    );
    canvas.drawLine(
      Offset(center.dx + xSize, center.dy - xSize),
      Offset(center.dx - xSize, center.dy + xSize),
      line,
    );

    // ── Wing area hash marks (20 yd from center, on each sideline) ──
    final double hashLen = fs(1.5); // length of hash mark
    final double wingTop = _midY - _wingDist;
    final double wingBot = _midY + _wingDist;
    // Left sideline hashes
    canvas.drawLine(
      Offset(fx(0), fy(wingTop)),
      Offset(fx(0) + hashLen, fy(wingTop)),
      line,
    );
    canvas.drawLine(
      Offset(fx(0), fy(wingBot)),
      Offset(fx(0) + hashLen, fy(wingBot)),
      line,
    );
    // Right sideline hashes
    canvas.drawLine(
      Offset(fx(_fw), fy(wingTop)),
      Offset(fx(_fw) - hashLen, fy(wingTop)),
      line,
    );
    canvas.drawLine(
      Offset(fx(_fw), fy(wingBot)),
      Offset(fx(_fw) - hashLen, fy(wingBot)),
      line,
    );

    // ── Restraining boxes (dashed) ──
    // Each box is centered on the field, 35 yd wide × 40 yd deep from goal
    final double rboxLeft = (_fw - _rboxW) / 2;
    final double rboxRight = rboxLeft + _rboxW;

    // Top restraining box (goal at y = _goalInset, box extends 40 yd down)
    final double topBoxBottom = _goalInset + _rboxD;
    _drawDashedRect(
      canvas,
      fx(rboxLeft),
      fy(0), // starts at end line
      fx(rboxRight),
      fy(topBoxBottom),
      dashPaint,
    );

    // Bottom restraining box (goal at y = _fh - _goalInset, box extends 40 yd up)
    final double botBoxTop = _fh - _goalInset - _rboxD;
    _drawDashedRect(
      canvas,
      fx(rboxLeft),
      fy(botBoxTop),
      fx(rboxRight),
      fy(_fh), // ends at end line
      dashPaint,
    );

    // ── Goal areas (top and bottom) ──
    _goalArea(canvas, fx, fy, fs, line, dashPaint, isTop: true);
    _goalArea(canvas, fx, fy, fs, line, dashPaint, isTop: false);

    canvas.restore();
  }

  /// Draws goal crease, cage, and GLE for one end of the field.
  void _goalArea(
    Canvas canvas,
    double Function(double) fx,
    double Function(double) fy,
    double Function(double) fs,
    Paint line,
    Paint dashPaint, {
    required bool isTop,
  }) {
    // Goal center position
    final double gy = isTop ? _goalInset : _fh - _goalInset;
    final Offset goalCenter = Offset(fx(_fw / 2), fy(gy));

    // ── Goal crease (full 9 ft radius circle) ──
    canvas.drawCircle(goalCenter, fs(_creaseR), line);

    // ── Goal cage (6 ft wide × 6 ft deep) — thick lines ──
    final cage = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double ghw = fs(_goalW / 2); // half width of goal
    final double gd = fs(_goalD); // goal depth
    // Goal opens toward field center; depth goes behind toward end line
    final double depthDir = isTop ? -gd : gd;

    final path = Path()
      ..moveTo(goalCenter.dx - ghw, goalCenter.dy)
      ..lineTo(goalCenter.dx - ghw, goalCenter.dy + depthDir)
      ..lineTo(goalCenter.dx + ghw, goalCenter.dy + depthDir)
      ..lineTo(goalCenter.dx + ghw, goalCenter.dy);
    canvas.drawPath(path, cage);

    // ── GLE — Goal Line Extended (dashed line across full width) ──
    _dashedLine(
      canvas,
      Offset(fx(0), fy(gy)),
      Offset(fx(_fw), fy(gy)),
      dashPaint,
    );
  }

  // ── Dashed rectangle (four dashed sides) ──
  void _drawDashedRect(
    Canvas c,
    double left,
    double top,
    double right,
    double bottom,
    Paint p,
  ) {
    // Only draw left, right, and the interior horizontal line (top/bottom
    // edges coincide with the end line which is already drawn as the field
    // outline). We draw only the sides that are interior to the field.
    // Left side
    _dashedLine(c, Offset(left, top), Offset(left, bottom), p);
    // Right side
    _dashedLine(c, Offset(right, top), Offset(right, bottom), p);
    // Bottom edge of top box / Top edge of bottom box (the interior edge)
    // We draw both horizontal edges; the one on the end line will overlay
    // the outline but that's fine.
    _dashedLine(c, Offset(left, top), Offset(right, top), p);
    _dashedLine(c, Offset(left, bottom), Offset(right, bottom), p);
  }

  // ── Dashed line helper ──
  void _dashedLine(Canvas c, Offset a, Offset b, Paint p,
      [double dw = 6, double ds = 4]) {
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy);
    _dashedPath(c, path, p, dw, ds);
  }

  // ── Dashed path helper ──
  void _dashedPath(Canvas c, Path src, Paint p,
      [double dw = 5, double ds = 4]) {
    final out = Path();
    for (final m in src.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        final double end = d + dw;
        out.addPath(
          m.extractPath(d, end < m.length ? end : m.length),
          Offset.zero,
        );
        d += dw + ds;
      }
    }
    c.drawPath(out, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

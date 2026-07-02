import 'dart:math';
import 'package:flutter/material.dart';

/// Paints a girls lacrosse field (120 × 70 yards, goals top & bottom).
class LacrosseFieldPainter extends CustomPainter {
  // ── Field dimensions in yards ──
  static const double _fw = 70;
  static const double _fh = 120;

  // ── Key radii (yards) ──
  static const double _centerCircleR = 9;
  static const double _creaseR = 3; // ~2.6 m
  static const double _arc8R = 8.75; // 8 m
  static const double _arc12R = 13.12; // 12 m

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

    final double s = fr.width / _fw; // uniform scale
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

    // ── Background ──
    final rrect = RRect.fromRectAndRadius(fr, const Radius.circular(10));
    canvas.drawRRect(rrect, fieldBg);

    // Subtle turf stripes
    final stripe = Paint()..color = Colors.white.withValues(alpha: 0.025);
    canvas.save();
    canvas.clipRRect(rrect);
    for (int i = 0; i < 12; i++) {
      if (i.isEven) {
        canvas.drawRect(
          Rect.fromLTWH(fr.left, fy(i * 10), fr.width, fs(10)),
          stripe,
        );
      }
    }

    // ── Boundary ──
    canvas.drawRRect(rrect, line);

    // ── Center line & circle ──
    canvas.drawLine(Offset(fx(0), fy(60)), Offset(fx(70), fy(60)), line);
    canvas.drawCircle(Offset(fx(35), fy(60)), fs(_centerCircleR), line);

    // ── Restraining lines (dashed) ──
    final dashLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    _dashedLine(canvas, Offset(fx(0), fy(30)), Offset(fx(70), fy(30)), dashLine);
    _dashedLine(canvas, Offset(fx(0), fy(90)), Offset(fx(70), fy(90)), dashLine);

    // ── Goal areas (top & bottom) ──
    _goalArea(canvas, fx, fy, fs, line, isTop: true);
    _goalArea(canvas, fx, fy, fs, line, isTop: false);

    canvas.restore();
  }

  // ── Goal area: crease, 8 m arc + hashes, 12 m arc, cage ──
  void _goalArea(
    Canvas canvas,
    double Function(double) fx,
    double Function(double) fy,
    double Function(double) fs,
    Paint line, {
    required bool isTop,
  }) {
    final double gy = isTop ? 0 : _fh;
    final Offset center = Offset(fx(35), fy(gy));
    final double sa = isTop ? 0 : pi; // start angle

    // Crease
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: fs(_creaseR)),
      sa,
      pi,
      false,
      line,
    );

    // 8 m arc
    final double r8 = fs(_arc8R);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r8),
      sa,
      pi,
      false,
      line,
    );

    // 8 m hash marks (7 evenly spaced)
    final hashPaint = Paint()
      ..color = line.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final double hl = fs(1.0);
    for (int i = 0; i < 7; i++) {
      final double a = (isTop ? 0 : pi) + i * pi / 6;
      final double ca = cos(a), sna = sin(a);
      canvas.drawLine(
        Offset(center.dx + (r8 - hl / 2) * ca, center.dy + (r8 - hl / 2) * sna),
        Offset(center.dx + (r8 + hl / 2) * ca, center.dy + (r8 + hl / 2) * sna),
        hashPaint,
      );
    }

    // 12 m arc (dashed)
    final arc12 = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: fs(_arc12R)),
        sa,
        pi,
      );
    final dashed = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    _dashedPath(canvas, arc12, dashed);

    // Goal cage
    final cage = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final double ghw = fs(1.0); // half-width
    final double gd = fs(1.2); // depth
    final double dy = isTop ? -gd : gd;
    final path = Path()
      ..moveTo(center.dx - ghw, center.dy)
      ..lineTo(center.dx - ghw, center.dy + dy)
      ..lineTo(center.dx + ghw, center.dy + dy)
      ..lineTo(center.dx + ghw, center.dy);
    canvas.drawPath(path, cage);
  }

  // ── Dashed helpers ──
  void _dashedLine(Canvas c, Offset a, Offset b, Paint p,
      [double dw = 6, double ds = 4]) {
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy);
    _dashedPath(c, path, p, dw, ds);
  }

  void _dashedPath(Canvas c, Path src, Paint p,
      [double dw = 5, double ds = 4]) {
    final out = Path();
    for (final m in src.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        out.addPath(m.extractPath(d, min(d + dw, m.length)), Offset.zero);
        d += dw + ds;
      }
    }
    c.drawPath(out, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

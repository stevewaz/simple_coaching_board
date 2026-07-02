import 'dart:ui';

/// Reduces a hand-drawn point list to the subset needed to preserve its
/// shape, dropping points that lie within [epsilon] pixels of the line
/// between their neighbors. This removes hand tremor while keeping actual
/// corners and curves intact.
List<Offset> simplifyPoints(List<Offset> points, {double epsilon = 3.0}) {
  if (points.length < 3) return points;

  double maxDist = 0;
  int splitIndex = 0;
  final start = points.first;
  final end = points.last;
  for (int i = 1; i < points.length - 1; i++) {
    final dist = _perpendicularDistance(points[i], start, end);
    if (dist > maxDist) {
      maxDist = dist;
      splitIndex = i;
    }
  }

  if (maxDist <= epsilon) return [start, end];

  final left = simplifyPoints(points.sublist(0, splitIndex + 1), epsilon: epsilon);
  final right = simplifyPoints(points.sublist(splitIndex), epsilon: epsilon);
  return [...left.sublist(0, left.length - 1), ...right];
}

double _perpendicularDistance(Offset p, Offset a, Offset b) {
  final dx = b.dx - a.dx;
  final dy = b.dy - a.dy;
  final lengthSquared = dx * dx + dy * dy;
  if (lengthSquared == 0) return (p - a).distance;

  final t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / lengthSquared;
  final closest = Offset(a.dx + t * dx, a.dy + t * dy);
  return (p - closest).distance;
}

/// Builds a smooth path through every point in [points] using a
/// Catmull-Rom spline (converted to cubic Béziers). Unlike a simple
/// polyline or midpoint-smoothed path, the curve passes through each
/// point exactly, so simplified hand-drawn strokes render as clean,
/// evenly-flowing lines instead of jagged segments.
Path catmullRomPath(List<Offset> points) {
  final path = Path();
  if (points.isEmpty) return path;

  path.moveTo(points.first.dx, points.first.dy);
  if (points.length == 1) return path;
  if (points.length == 2) {
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  for (int i = 0; i < points.length - 1; i++) {
    final p0 = i == 0 ? points[i] : points[i - 1];
    final p1 = points[i];
    final p2 = points[i + 1];
    final p3 = i + 2 < points.length ? points[i + 2] : p2;

    final control1 = p1 + (p2 - p0) / 6.0;
    final control2 = p2 - (p3 - p1) / 6.0;

    path.cubicTo(
      control1.dx, control1.dy,
      control2.dx, control2.dy,
      p2.dx, p2.dy,
    );
  }
  return path;
}

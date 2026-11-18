import 'package:flutter/widgets.dart';

/// The عمّرها mark: a roof over a house with an arched door, drawn as white
/// lines. The app icon is rendered from the same painter
/// (tool/render_icons_test.dart), so the opening animation draws the icon.
class BrandMarkPainter extends CustomPainter {
  const BrandMarkPainter({this.roof = 1, this.body = 1, this.color = const Color(0xFFFFFFFF), this.stroke = 0.06});

  /// How much of the roof and of the house is drawn, 0 to 1.
  final double roof;
  final double body;
  final Color color;

  /// Line width as a share of the box side.
  final double stroke;

  static Path roofPath(Size s) => Path()
    ..moveTo(s.width * 0.14, s.height * 0.50)
    ..lineTo(s.width * 0.50, s.height * 0.18)
    ..lineTo(s.width * 0.86, s.height * 0.50);

  /// Walls standing a little under the roof, then the arched door (قنطرة).
  static Path bodyPath(Size s) {
    double x(double v) => s.width * v;
    double y(double v) => s.height * v;
    return Path()
      ..moveTo(x(0.43), y(0.80))
      ..lineTo(x(0.28), y(0.80))
      ..lineTo(x(0.28), y(0.50))
      ..moveTo(x(0.72), y(0.50))
      ..lineTo(x(0.72), y(0.80))
      ..lineTo(x(0.57), y(0.80))
      ..lineTo(x(0.57), y(0.67))
      ..arcToPoint(Offset(x(0.43), y(0.67)), radius: Radius.circular(x(0.07)), clockwise: false)
      ..lineTo(x(0.43), y(0.80));
  }

  static Path _part(Path path, double t) {
    if (t >= 1) return path;
    final out = Path();
    if (t <= 0) return out;
    final metrics = path.computeMetrics().toList();
    var left = metrics.fold<double>(0, (sum, m) => sum + m.length) * t;
    for (final m in metrics) {
      if (left <= 0) break;
      out.addPath(m.extractPath(0, left.clamp(0, m.length)), Offset.zero);
      left -= m.length;
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(_part(roofPath(size), roof), paint);
    canvas.drawPath(_part(bodyPath(size), body), paint);
  }

  @override
  bool shouldRepaint(BrandMarkPainter old) =>
      old.roof != roof || old.body != body || old.color != color || old.stroke != stroke;
}

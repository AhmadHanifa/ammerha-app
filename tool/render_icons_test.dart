// Renders the app icon from the brand mark into assets/icon/.
// Run after changing the mark, then regenerate the launcher icons:
//   flutter test tool/render_icons_test.dart
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ammerha/app/theme.dart';
import 'package:ammerha/widgets/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = 1024.0;

Future<void> _save(String name, void Function(Canvas canvas) draw) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final image = await recorder.endRecording().toImage(_size.toInt(), _size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('assets/icon/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
}

/// The mark centered, taking [share] of the canvas.
void _mark(Canvas canvas, double share) {
  final side = _size * share;
  canvas.save();
  canvas.translate((_size - side) / 2, (_size - side) / 2);
  const BrandMarkPainter().paint(canvas, Size.square(side));
  canvas.restore();
}

final _fill = Paint()
  ..shader = ui.Gradient.linear(Offset.zero, const Offset(_size, _size), [
    const Color(0xFF4A7A6A),
    AppColors.primaryDark,
  ]);

void main() {
  testWidgets('render the icon files', (tester) async {
    await tester.runAsync(() async {
      // Older Android: the whole icon, with its own rounded corners.
      await _save('icon.png', (canvas) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, _size, _size), const Radius.circular(_size * 0.225)),
          _fill,
        );
        _mark(canvas, 0.66);
      });
      // Android 8+: the launcher crops the background to its own shape; the
      // mark stays inside the safe middle.
      await _save('background.png', (canvas) => canvas.drawRect(const Rect.fromLTWH(0, 0, _size, _size), _fill));
      await _save('foreground.png', (canvas) => _mark(canvas, 0.5));
      // Android 13 themed icons tint this one.
      await _save('monochrome.png', (canvas) => _mark(canvas, 0.5));
    });
  });
}

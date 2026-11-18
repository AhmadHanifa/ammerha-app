// Renders frames of the opening animation side by side, to look at it
// without a phone: flutter test tool/render_intro_test.dart
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ammerha/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('render intro frames', (tester) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;

    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: key, child: const AmmerhaApp()));
    await tester.runAsync(() => GoogleFonts.pendingFonts().timeout(const Duration(seconds: 10)));

    final frames = <ui.Image>[];
    var elapsed = 0;
    for (final at in [250, 700, 1150, 1700, 2150, 2600]) {
      await tester.pump(Duration(milliseconds: at - elapsed));
      elapsed = at;
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      frames.add((await tester.runAsync(() => boundary.toImage()))!);
    }

    const gap = 12.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final w = frames.first.width.toDouble(), h = frames.first.height.toDouble();
    canvas.drawRect(Rect.fromLTWH(0, 0, frames.length * (w + gap) + gap, h + 2 * gap), Paint()..color = const Color(0xFFDDE3E0));
    for (final (i, f) in frames.indexed) {
      canvas.drawImage(f, Offset(gap + i * (w + gap), gap), Paint());
    }
    final strip = await tester.runAsync(
      () => recorder.endRecording().toImage((frames.length * (w + gap) + gap).toInt(), (h + 2 * gap).toInt()),
    );
    final bytes = await tester.runAsync(() => strip!.toByteData(format: ui.ImageByteFormat.png));
    File('../design/intro-preview.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    await tester.pumpAndSettle();
  });
}

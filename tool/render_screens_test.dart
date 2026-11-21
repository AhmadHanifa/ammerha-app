// Renders the main screens side by side, to look at them without a phone
// (demo data, no server): flutter test tool/render_screens_test.dart
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
  testWidgets('render main screens', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;

    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: key, child: const AmmerhaApp(showIntro: false)));
    await tester.runAsync(() => GoogleFonts.pendingFonts().timeout(const Duration(seconds: 10)));
    await tester.pumpAndSettle();

    final shots = <ui.Image>[];
    Future<void> shot() async {
      await tester.pumpAndSettle();
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      shots.add((await tester.runAsync(() => boundary.toImage()))!);
    }

    Future<void> tap(String text) async {
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    await shot(); // home
    await tap('شقة كاملة');
    await tap('التالي');
    await tap('التالي');
    await tap('احسب الكلفة');
    await shot(); // result
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await shot(); // result, lower
    await tap('اطلب عرض سعر');
    await shot(); // quote form

    const gap = 12.0;
    final w = shots.first.width.toDouble(), h = shots.first.height.toDouble();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Rect.fromLTWH(0, 0, shots.length * (w + gap) + gap, h + 2 * gap), Paint()..color = const Color(0xFFDDE3E0));
    for (final (i, image) in shots.indexed) {
      canvas.drawImage(image, Offset(gap + i * (w + gap), gap), Paint());
    }
    final strip = await tester.runAsync(
      () => recorder.endRecording().toImage((shots.length * (w + gap) + gap).toInt(), (h + 2 * gap).toInt()),
    );
    final bytes = await tester.runAsync(() => strip!.toByteData(format: ui.ImageByteFormat.png));
    File('../design/screens-preview.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

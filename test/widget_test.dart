import 'package:ammerha/data/estimate.dart';
import 'package:ammerha/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _startApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(const AmmerhaApp(useGoogleFonts: false));
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  test('the demo estimate matches the example in the agreement', () {
    // 100 m², medium level: "8,200 لـ 11,500 دولار".
    final full = demoEstimate(const CalcInput());
    expect((full.min, full.max), (8200, 11500));

    final paint = demoEstimate(const CalcInput(kind: RequestKind.service, services: {Service.paint}));
    final both = demoEstimate(const CalcInput(kind: RequestKind.service, services: {Service.paint, Service.tiles}));
    final tiles = demoEstimate(const CalcInput(kind: RequestKind.service, services: {Service.tiles}));
    expect(both.max, lessThan(paint.max + tiles.max));
    expect(const CalcInput(kind: RequestKind.service, services: {Service.paint}).needsRooms, isFalse);
  });

  testWidgets('the opening animation draws the name, then lifts away; a tap skips it', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AmmerhaApp(useGoogleFonts: false));
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text('عمّرها'), findsNWidgets(2), reason: 'the intro name over the home logo');
    expect(find.text('برعاية سنديان'), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(find.text('عمّرها'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const AmmerhaApp(useGoogleFonts: false));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tapAt(const Offset(200, 400));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('عمّرها'), findsOneWidget);
  });

  testWidgets('a full apartment: calculator, range, quote form, then a request number', (tester) async {
    await _startApp(tester);
    expect(find.text('بدك إكساء شقة كاملة، ولا خدمة وحدة؟'), findsOneWidget);
    expect(find.text('برعاية سنديان'), findsOneWidget);

    await _tapText(tester, 'ابدأ الحساب');
    expect(find.text('قديش مساحة الشقة؟'), findsOneWidget);
    expect(find.text('الخطوة 1 من 3'), findsOneWidget);

    await _tapText(tester, 'التالي');
    expect(find.text('كم غرفة وحمام؟'), findsOneWidget);

    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(find.text('قديش مساحة الشقة؟'), findsOneWidget);

    await _tapText(tester, 'التالي');
    await _tapText(tester, 'التالي');
    await _tapText(tester, 'احسب الكلفة');
    expect(find.text('8,200 – 11,500 \$'), findsOneWidget);
    expect(find.text('هاد سعر تقريبي. السعر النهائي بيحدده فريق سنديان بعد المعاينة.'), findsOneWidget);

    await _tapText(tester, 'اطلب عرض سعر');
    await tester.enterText(find.byType(TextFormField).at(0), 'أبو محمد');
    await tester.enterText(find.byType(TextFormField).at(1), '0912345678');
    await _tapText(tester, 'ابعت الطلب');
    expect(find.text('رقم طلبك'), findsOneWidget);
    expect(find.text('101'), findsOneWidget);

    await _tapText(tester, 'رجوع للرئيسية');
    await tester.tap(find.text('طلباتي'));
    await tester.pumpAndSettle();
    expect(find.text('طلب 101'), findsOneWidget);
  });

  testWidgets('one service skips the rooms step and offers a companion', (tester) async {
    await _startApp(tester);

    await _tapText(tester, 'خدمة وحدة');
    await _tapText(tester, 'دهان');
    await _tapText(tester, 'التالي');
    expect(find.text('الخطوة 1 من 2'), findsOneWidget);

    await _tapText(tester, 'التالي');
    expect(find.text('شو مستوى الإكساء؟'), findsOneWidget);
    await _tapText(tester, 'احسب الكلفة');
    expect(find.text('ضيف البلاط كمان بسعر أحسن'), findsOneWidget);
  });
}

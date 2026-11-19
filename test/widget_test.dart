import 'package:ammerha/data/article.dart';
import 'package:ammerha/data/estimate.dart';
import 'package:ammerha/data/providers.dart';
import 'package:ammerha/features/providers/providers_page.dart';
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
  // Long lists build lazily: scroll until the item exists.
  if (find.text(label).evaluate().isEmpty) {
    await tester.scrollUntilVisible(find.text(label), 300, scrollable: find.byType(Scrollable).first);
  }
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
    expect(find.text('إكساء بيتك، بثقة'), findsOneWidget);
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
    expect(find.textContaining('سنديان'), findsNothing);

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
    expect(find.text('هاد سعر تقريبي. السعر النهائي بيحدده فريق عمّرها بعد المعاينة.'), findsOneWidget);

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

  testWidgets('purchase inspection: from home to a request number, with no level or range', (tester) async {
    await _startApp(tester);
    await _tapText(tester, 'بدك تشتري شقة؟');
    expect(find.text('افحص الشقة قبل ما تشتريها'), findsOneWidget);

    await _tapText(tester, 'اطلب الفحص');
    expect(find.text('لازم تعبّي هالحقل'), findsWidgets);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'حلب، الفرقان');
    await tester.enterText(fields.at(1), '95');
    await tester.enterText(fields.at(3), 'أم علي');
    await tester.enterText(fields.at(4), '0944777888');
    await _tapText(tester, 'اطلب الفحص');
    expect(find.text('رقم طلبك'), findsOneWidget);
    expect(find.text('فحص شقة قبل الشراء'), findsOneWidget);
    expect(find.text('حلب، الفرقان · 95 م²'), findsOneWidget);
  });

  testWidgets('abroad: the page explains the stages and starts the calculator', (tester) async {
    await _startApp(tester);
    await _tapText(tester, 'عايش برّا سوريا؟');
    expect(find.text('عمّر بيتك بسوريا وإنت بمكانك'), findsOneWidget);
    await _tapText(tester, 'ابدأ: احسب كلفة بيتك');
    expect(find.text('قديش مساحة الشقة؟'), findsOneWidget);
  });

  testWidgets('verify: the certificate check opens from home', (tester) async {
    await _startApp(tester);
    await _tapText(tester, 'عندك كود شقة موثّقة؟ تحقق منه');
    await tester.enterText(find.byType(TextField), 'AM-ABC234');
    await _tapText(tester, 'تحقق');
    expect(find.textContaining('ما لقينا شهادة'), findsOneWidget);
  });

  testWidgets('a provider card shows only numbers earned through the app', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    const painter = Provider(
      id: 'p1',
      kind: 'technician',
      name: 'أبو خالد',
      services: ['paint'],
      photos: [],
      jobs: 23,
      reviews: 18,
      claims: 3,
      claimsFixed: 3,
      area: 'حلب',
      verified: true,
      rating: 4.8,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(textDirection: TextDirection.rtl, child: ProviderPage(provider: painter)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('23'), findsOneWidget);
    expect(find.text('3 من 3'), findsOneWidget);
    expect(find.text('موثّق من عمّرها'), findsOneWidget);
    expect(find.text('اطلب منه عرض سعر'), findsOneWidget);
    expect(find.text('لسا ما في تقييمات.'), findsOneWidget);
  });

  test('article bodies split into headings, paragraphs and bullets', () {
    final blocks = parseArticle('مقدمة قصيرة\nبسطرين\n\n## الأسئلة\n- أول\n- تاني\nخاتمة');
    expect(blocks.length, 4);
    expect((blocks[0] as ParagraphBlock).text, 'مقدمة قصيرة بسطرين');
    expect((blocks[1] as HeadingBlock).text, 'الأسئلة');
    expect((blocks[2] as BulletsBlock).items, ['أول', 'تاني']);
    expect((blocks[3] as ParagraphBlock).text, 'خاتمة');
  });

  testWidgets('tips is a tab, and technicians have a way in from home', (tester) async {
    await _startApp(tester);
    await tester.tap(find.text('نصايح'));
    await tester.pumpAndSettle();
    expect(find.text('شو تسأل، شو تفحص، وشو تكتب، لحتى ما حدا يضحك عليك.'), findsOneWidget);

    await tester.tap(find.text('الرئيسية'));
    await tester.pumpAndSettle();
    await _tapText(tester, 'إنت فني أو مهندس؟');
    expect(find.text('انضم لعمّرها'), findsOneWidget);
  });
}

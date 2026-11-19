import 'package:go_router/go_router.dart';

import '../data/article.dart';
import '../data/estimate.dart';
import '../data/providers.dart';
import '../data/showcase.dart';
import '../features/abroad/abroad_page.dart';
import '../features/calculator/calculator_page.dart';
import '../features/calculator/result_page.dart';
import '../features/inspection/inspection_page.dart';
import '../features/pro/job_page.dart';
import '../features/pro/join_page.dart';
import '../features/pro/pro_page.dart';
import '../features/providers/providers_page.dart';
import '../features/quote/quote_page.dart';
import '../features/quote/sent_page.dart';
import '../features/requests/request_file_page.dart';
import '../features/services/services_page.dart';
import '../features/showcase/designs_page.dart';
import '../features/showcase/gallery_page.dart';
import '../features/shell/shell_page.dart';
import '../features/tips/tips_page.dart';
import '../features/verify/verify_page.dart';
import '../services/analytics.dart';
import '../services/requests_store.dart';
import 'transitions.dart';

// Every route uses the shared-axis page so the page underneath also slides out.
GoRouter createRouter() => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: ShellPage(tab: state.uri.queryParameters['tab']),
      ),
    ),
    GoRoute(
      path: '/services',
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: const ScreenTracker(name: 'services', child: ServicesPage()),
      ),
    ),
    GoRoute(
      path: '/calculator',
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: CalculatorPage(input: state.extra as CalcInput? ?? const CalcInput()),
      ),
    ),
    GoRoute(
      path: '/result',
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: ScreenTracker(
          name: 'result',
          child: ResultPage(input: state.extra as CalcInput? ?? const CalcInput()),
        ),
      ),
    ),
    GoRoute(
      path: '/quote',
      redirect: (context, state) => state.extra is QuoteArgs ? null : '/',
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: ScreenTracker(name: 'quote', child: QuotePage(args: state.extra! as QuoteArgs)),
      ),
    ),
    GoRoute(
      path: '/sent',
      redirect: (context, state) => state.extra is SavedRequest ? null : '/',
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: ScreenTracker(name: 'sent', child: SentPage(request: state.extra! as SavedRequest)),
      ),
    ),
    GoRoute(
      path: '/gallery',
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: const ScreenTracker(name: 'gallery', child: GalleryPage()),
      ),
    ),
    GoRoute(
      path: '/gallery/item',
      redirect: (context, state) => state.extra is GalleryProject ? null : '/gallery',
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: ScreenTracker(name: 'gallery_item', child: GalleryProjectPage(project: state.extra! as GalleryProject)),
      ),
    ),
    GoRoute(
      path: '/designs',
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: const ScreenTracker(name: 'designs', child: DesignsPage()),
      ),
    ),
    GoRoute(
      path: '/designs/item',
      redirect: (context, state) => state.extra is ReadyDesign ? null : '/designs',
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: ScreenTracker(name: 'design_item', child: DesignPage(design: state.extra! as ReadyDesign)),
      ),
    ),
    GoRoute(
      path: '/providers',
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: const ScreenTracker(name: 'providers', child: ProvidersPage()),
      ),
    ),
    GoRoute(
      path: '/providers/item',
      redirect: (context, state) => state.extra is Provider ? null : '/providers',
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: ScreenTracker(name: 'provider', child: ProviderPage(provider: state.extra! as Provider)),
      ),
    ),
    GoRoute(
      path: '/tips/item',
      redirect: (context, state) => state.extra is Article ? null : '/?tab=tips',
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: ScreenTracker(name: 'article', child: ArticlePage(article: state.extra! as Article)),
      ),
    ),
    GoRoute(
      path: '/join',
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: const ScreenTracker(name: 'join', child: JoinPage()),
      ),
    ),
    GoRoute(
      path: '/pro',
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: const ScreenTracker(name: 'pro', child: ProPage()),
      ),
    ),
    GoRoute(
      path: '/pro/job/:no',
      redirect: (context, state) => int.tryParse(state.pathParameters['no'] ?? '') == null ? '/pro' : null,
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: ScreenTracker(name: 'pro_job', child: JobPage(number: int.parse(state.pathParameters['no']!))),
      ),
    ),
    GoRoute(
      path: '/abroad',
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: const ScreenTracker(name: 'abroad', child: AbroadPage()),
      ),
    ),
    GoRoute(
      path: '/inspection',
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: ScreenTracker(name: 'inspection', child: InspectionPage(remote: state.extra == true)),
      ),
    ),
    GoRoute(
      path: '/verify',
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: ScreenTracker(name: 'verify', child: VerifyPage(code: state.uri.queryParameters['code'])),
      ),
    ),
    GoRoute(
      path: '/request/:no',
      redirect: (context, state) => int.tryParse(state.pathParameters['no'] ?? '') == null ? '/' : null,
      pageBuilder: (context, state) => sharedAxisPage(
        key: state.pageKey,
        child: ScreenTracker(
          name: 'request_file',
          child: RequestFilePage(number: int.parse(state.pathParameters['no']!)),
        ),
      ),
    ),
  ],
);

import 'package:go_router/go_router.dart';

import '../data/estimate.dart';
import '../features/calculator/calculator_page.dart';
import '../features/calculator/result_page.dart';
import '../features/quote/quote_page.dart';
import '../features/quote/sent_page.dart';
import '../features/services/services_page.dart';
import '../features/shell/shell_page.dart';
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
        child: ShellPage(showRequests: state.uri.queryParameters['tab'] == 'requests'),
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
  ],
);

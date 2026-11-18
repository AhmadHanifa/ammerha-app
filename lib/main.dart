import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/config.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'services/analytics.dart';
import 'services/partner.dart';
import 'services/push.dart';
import 'services/requests_store.dart';
import 'widgets/intro.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The font is bundled; Google's servers may be slow or blocked in Syria.
  GoogleFonts.config.allowRuntimeFetching = false;
  if (AppConfig.hasBackend) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabasePublishableKey);
    unawaited(Analytics.instance.init(Supabase.instance.client));
    unawaited(Partner.instance.load(Supabase.instance.client));
    unawaited(Push.instance.init(Supabase.instance.client));
  }
  unawaited(RequestsStore.instance.load());
  runApp(const AmmerhaApp());
}

class AmmerhaApp extends StatefulWidget {
  const AmmerhaApp({super.key, this.useGoogleFonts = true, this.showIntro = true});

  final bool useGoogleFonts;

  /// The opening animation; widget tests start straight on the home screen.
  final bool showIntro;

  @override
  State<AmmerhaApp> createState() => _AmmerhaAppState();
}

class _AmmerhaAppState extends State<AmmerhaApp> {
  final _router = createRouter();

  @override
  void initState() {
    super.initState();
    Push.instance.onOpen = (screen) => switch (screen) {
      'requests' => _router.go('/?tab=requests'),
      'calculator' => _router.go('/calculator'),
      _ => _router.go('/'),
    };
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'عمّرها',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(useGoogleFonts: widget.useGoogleFonts),
      routerConfig: _router,
      scaffoldMessengerKey: Push.instance.messengerKey,
      builder: (context, child) => IntroOverlay(enabled: widget.showIntro, child: child!),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}

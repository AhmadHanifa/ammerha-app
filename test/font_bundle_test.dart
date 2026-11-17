import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  testWidgets('every weight the theme uses comes from the bundled font', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final weight in [FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700]) {
      GoogleFonts.ibmPlexSansArabic(fontWeight: weight);
    }
    // A weight that is not bundled never finishes loading, so give up early.
    await tester.runAsync(() => GoogleFonts.pendingFonts().timeout(const Duration(seconds: 10)));
  });
}

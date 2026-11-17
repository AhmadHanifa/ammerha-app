import 'package:url_launcher/url_launcher.dart';

import 'partner.dart';
import 'requests_store.dart';

/// Opens the shared business chat with the request already written.
/// False when the number is not set yet or WhatsApp could not be opened.
Future<bool> openWhatsApp(SavedRequest request) async {
  final number = Partner.instance.whatsappNumber;
  if (number.isEmpty) return false;
  final uri = Uri.https('wa.me', '/$number', {'text': request.whatsappText});
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

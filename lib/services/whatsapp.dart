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

/// Digits for a wa.me link; Syrian local numbers (09…) get the country code.
String waPhone(String raw) {
  var d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.startsWith('00')) d = d.substring(2);
  if (d.startsWith('0')) return '963${d.substring(1)}';
  if (d.length == 9 && d.startsWith('9')) return '963$d';
  return d;
}

/// Opens a chat with any number, as a provider does with their customer.
Future<bool> openChat(String phone, String text) async {
  final uri = Uri.https('wa.me', '/${waPhone(phone)}', {'text': text});
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/config.dart';

/// The contractor behind the app: the name shown on every screen and the one
/// shared WhatsApp number. Both come from the `app_config` RPC and are kept
/// from the last launch for when the phone is offline.
class Partner {
  Partner._();
  static final instance = Partner._();

  static const _nameKey = 'partner.sponsor_name';
  static const _numberKey = 'partner.whatsapp_number';

  final sponsorName = ValueNotifier<String>('سنديان');

  /// Digits with the country code, or empty until it is set in the dashboard.
  String whatsappNumber = '';

  Future<void> load(SupabaseClient db) async {
    final prefs = await SharedPreferences.getInstance();
    apply({'sponsor_name': prefs.getString(_nameKey), 'whatsapp_number': prefs.getString(_numberKey)});
    try {
      final json = await db.rpc('app_config').timeout(AppConfig.requestTimeout);
      apply(json as Map<String, dynamic>);
      await prefs.setString(_nameKey, sponsorName.value);
      await prefs.setString(_numberKey, whatsappNumber);
    } catch (_) {
      // Offline: the saved values stay.
    }
  }

  /// Takes `sponsor_name` and `whatsapp_number` from a backend reply.
  void apply(Map<String, dynamic> json) {
    final name = json['sponsor_name'];
    if (name is String && name.trim().isNotEmpty) sponsorName.value = name.trim();
    final number = json['whatsapp_number'];
    if (number != null) whatsappNumber = '$number'.replaceAll(RegExp(r'\D'), '');
  }
}

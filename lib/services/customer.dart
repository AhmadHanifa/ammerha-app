import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/config.dart';
import 'analytics.dart';

/// The customer's anonymous account. Their requests, the photos of their home
/// and their certificate belong to it, so nobody else can open them.
/// Supabase needs "Allow anonymous sign-ins" (Authentication > Sign In).
class Customer {
  Customer._();
  static final instance = Customer._();

  Future<bool>? _pending;
  var _claimed = false;

  bool get signedIn => AppConfig.hasBackend && Supabase.instance.client.auth.currentUser != null;

  /// Signs in once and moves this phone's earlier requests under the account.
  /// False offline, in demo builds, or while anonymous sign-ins are off.
  Future<bool> ensureSignedIn() => _pending ??= _signIn().whenComplete(() => _pending = null);

  Future<bool> _signIn() async {
    if (!AppConfig.hasBackend) return false;
    final db = Supabase.instance.client;
    try {
      if (db.auth.currentUser == null) await db.auth.signInAnonymously().timeout(AppConfig.requestTimeout);
      if (!_claimed) {
        await db
            .rpc('claim_device', params: {'p_device_id': await Analytics.instance.ensureDeviceId()})
            .timeout(AppConfig.requestTimeout);
        _claimed = true;
      }
      return true;
    } catch (_) {
      return db.auth.currentUser != null;
    }
  }
}

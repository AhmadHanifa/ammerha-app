import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/config.dart';
import 'analytics.dart';
import 'requests_store.dart';

/// Push notifications through Firebase Cloud Messaging. The phone's token goes
/// to `set_push_token`; the dashboard and request updates decide who gets what.
class Push {
  Push._();
  static final instance = Push._();

  static const _askedKey = 'push.asked';

  /// Shows a banner while the app is open.
  final messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Opens the screen a notification points to: '', 'home', 'requests' or 'calculator'.
  void Function(String screen)? onOpen;

  SupabaseClient? _db;

  bool get ready => _db != null;

  Future<void> init(SupabaseClient db) async {
    if (!AppConfig.hasPush) return;
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: AppConfig.firebaseApiKey,
          appId: AppConfig.firebaseAppId,
          messagingSenderId: AppConfig.firebaseSenderId,
          projectId: AppConfig.firebaseProjectId,
        ),
      );
    } catch (_) {
      return; // Firebase unreachable or misconfigured: the app works without push.
    }
    _db = db;
    final messaging = FirebaseMessaging.instance;

    FirebaseMessaging.onMessage.listen(_showBanner);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data['screen']));
    // The classic registration token is what the send function's HTTP v1
    // `message.token` takes; the newer register()/onRegistered gives an
    // installation id for a different send path.
    // ignore: deprecated_member_use
    messaging.onTokenRefresh.listen((token) => _save(token, enabled: true));
    final initial = await messaging.getInitialMessage();
    if (initial != null) _open(initial.data['screen']);

    // Allowed before (or Android below 13, where it is on by default).
    final settings = await messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) await _saveCurrent(enabled: true);
  }

  /// Asks once, at a moment the person sees why: after a result or a request.
  Future<void> askOnce() async {
    if (!ready) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_askedKey) ?? false) return;
    await prefs.setBool(_askedKey, true);
    final settings = await FirebaseMessaging.instance.requestPermission();
    await _saveCurrent(enabled: settings.authorizationStatus == AuthorizationStatus.authorized);
  }

  Future<void> _saveCurrent({required bool enabled}) async {
    try {
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken().timeout(AppConfig.requestTimeout);
      await _save(token, enabled: enabled);
    } catch (_) {
      // No token now (offline or no Google services): tried again next launch.
    }
  }

  Future<void> _save(String? token, {required bool enabled}) async {
    final db = _db;
    if (db == null || token == null) return;
    try {
      await db.rpc(
        'set_push_token',
        params: {'p_device_id': await Analytics.instance.ensureDeviceId(), 'p_token': token, 'p_enabled': enabled},
      ).timeout(AppConfig.requestTimeout);
    } catch (_) {
      // Offline: saved again next launch.
    }
  }

  void _open(String? screen) {
    Analytics.instance.track('push_opened', {'screen': screen});
    onOpen?.call(screen ?? '');
  }

  void _showBanner(RemoteMessage message) {
    final n = message.notification;
    final screen = message.data['screen'] as String?;
    if (screen == 'requests') unawaited(RequestsStore.instance.refreshStatuses());
    if (n == null) return;
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text([n.title, n.body].whereType<String>().join('\n')),
        duration: const Duration(seconds: 6),
        action: screen == null || screen.isEmpty ? null : SnackBarAction(label: 'شوف', onPressed: () => _open(screen)),
      ),
    );
  }
}

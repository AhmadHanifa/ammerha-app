import 'dart:async';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Records which screens people open, how long they stay, and key actions,
/// then sends them in batches to the `track_events` RPC. Events wait in
/// local storage while the phone is offline.
class Analytics with WidgetsBindingObserver {
  Analytics._();
  static final instance = Analytics._();

  static const _deviceKey = 'analytics.device_id';
  static const _queueKey = 'analytics.queue';
  static const _maxQueue = 1000;
  static const _batch = 200;
  static const _newSessionAfter = Duration(minutes: 30);

  final _stack = <_Screen>[];
  final _queue = <Map<String, Object?>>[];
  SupabaseClient? _db;
  SharedPreferences? _prefs;
  Timer? _timer;
  bool _flushing = false;

  String? deviceId;
  String _appVersion = '';
  String _sessionId = const Uuid().v4();
  DateTime _sessionStart = DateTime.now();
  DateTime? _segmentStart;
  DateTime? _pausedAt;

  bool get enabled => _db != null;

  Future<void> init(SupabaseClient db) async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    deviceId ??= prefs.getString(_deviceKey) ?? const Uuid().v4();
    await prefs.setString(_deviceKey, deviceId!);

    final saved = prefs.getString(_queueKey);
    if (saved != null) {
      _queue.addAll((jsonDecode(saved) as List).cast<Map<String, Object?>>());
    }

    final package = await PackageInfo.fromPlatform();
    _appVersion = package.version;
    var platform = 'other', os = '', model = '';
    try {
      final android = await DeviceInfoPlugin().androidInfo;
      platform = 'android';
      os = android.version.release;
      model = '${android.manufacturer} ${android.model}';
    } catch (_) {
      // Not Android: keep the defaults.
    }

    _db = db;
    try {
      await db.rpc(
        'register_device',
        params: {'p_id': deviceId, 'p_platform': platform, 'p_os_version': os, 'p_app_version': _appVersion, 'p_model': model},
      );
    } catch (_) {
      // Offline: track_events retries later; registration repeats next launch.
    }

    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => flush());
    unawaited(flush());
  }

  /// The device id, for calls that cannot wait for [init] to finish.
  Future<String> ensureDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = deviceId ??= prefs.getString(_deviceKey) ?? const Uuid().v4();
    await prefs.setString(_deviceKey, id);
    return id;
  }

  /// A screen became visible; returns a token for [screenClosed].
  Object screenOpened(String name, [Map<String, Object?>? props]) {
    _closeSegment();
    final screen = _Screen(name, props);
    _stack.add(screen);
    _segmentStart = DateTime.now();
    return screen;
  }

  void screenClosed(Object token) {
    if (_stack.isEmpty) return;
    if (identical(_stack.last, token)) {
      _closeSegment();
      _stack.removeLast();
      // Back on the screen underneath: it starts a new visible stretch.
      _segmentStart = _stack.isEmpty ? null : DateTime.now();
    } else {
      _stack.remove(token);
    }
  }

  void track(String name, [Map<String, Object?>? props]) {
    _add({'name': name, 'screen': _stack.isEmpty ? null : _stack.last.name, 'props': props});
  }

  void _closeSegment() {
    final start = _segmentStart;
    if (_stack.isEmpty || start == null) return;
    _segmentStart = null;
    final screen = _stack.last;
    _add({
      'name': 'screen_view',
      'screen': screen.name,
      'duration_ms': DateTime.now().difference(start).inMilliseconds,
      'props': screen.props,
      'occurred_at': start.toUtc().toIso8601String(),
    });
  }

  void _add(Map<String, Object?> event) {
    if (!enabled) return;
    _queue.add({
      'occurred_at': DateTime.now().toUtc().toIso8601String(),
      ...event,
      'session_id': _sessionId,
      'session_started_at': _sessionStart.toUtc().toIso8601String(),
    });
    if (_queue.length > _maxQueue) _queue.removeRange(0, _queue.length - _maxQueue);
    _persist();
  }

  Future<void> flush() async {
    final db = _db;
    if (db == null || _flushing || _queue.isEmpty || deviceId == null) return;
    _flushing = true;
    try {
      while (_queue.isNotEmpty) {
        final sessionId = _queue.first['session_id'];
        final batch = _queue.where((e) => e['session_id'] == sessionId).take(_batch).toList();
        await db.rpc(
          'track_events',
          params: {
            'p_device_id': deviceId,
            'p_session_id': sessionId,
            'p_session_started_at': batch.first['session_started_at'],
            'p_app_version': _appVersion,
            'p_events': batch,
          },
        );
        _queue.removeWhere(batch.contains);
        _persist();
      }
    } catch (_) {
      // Offline or server error: the queue stays for the next try.
    } finally {
      _flushing = false;
    }
  }

  void _persist() => _prefs?.setString(_queueKey, jsonEncode(_queue));

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        if (_pausedAt != null) return;
        _closeSegment();
        _pausedAt = DateTime.now();
        unawaited(flush());
      case AppLifecycleState.resumed:
        final pausedAt = _pausedAt;
        _pausedAt = null;
        if (pausedAt != null && DateTime.now().difference(pausedAt) > _newSessionAfter) {
          _sessionId = const Uuid().v4();
          _sessionStart = DateTime.now();
        }
        if (_stack.isNotEmpty) _segmentStart = DateTime.now();
      default:
        break;
    }
  }

  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}

class _Screen {
  _Screen(this.name, this.props);

  final String name;
  final Map<String, Object?>? props;
}

/// Wrap a screen to record when it is visible and for how long.
class ScreenTracker extends StatefulWidget {
  const ScreenTracker({super.key, required this.name, this.props, required this.child});

  final String name;
  final Map<String, Object?>? props;
  final Widget child;

  @override
  State<ScreenTracker> createState() => _ScreenTrackerState();
}

class _ScreenTrackerState extends State<ScreenTracker> {
  late final Object _token;

  @override
  void initState() {
    super.initState();
    _token = Analytics.instance.screenOpened(widget.name, widget.props);
  }

  @override
  void dispose() {
    Analytics.instance.screenClosed(_token);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/config.dart';
import '../data/home_file.dart';
import 'analytics.dart';
import 'customer.dart';
import 'home_files.dart';
import 'partner.dart';

/// A request the customer sent from this phone.
class SavedRequest {
  const SavedRequest({
    required this.number,
    required this.title,
    required this.size,
    required this.level,
    required this.range,
    required this.rangeWords,
    required this.createdAt,
    this.kind = 'full',
  });

  factory SavedRequest.fromJson(Map<String, dynamic> json) => SavedRequest(
    number: json['number'] as int,
    title: json['title'] as String,
    size: json['size'] as String,
    level: json['level'] as String,
    range: json['range'] as String,
    rangeWords: json['range_words'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    kind: json['kind'] as String? ?? 'full',
  );

  /// The number that follows the request to the contract and the statement.
  final int number;
  final String title;

  /// The area and rooms; for an inspection, where the apartment is.
  final String size;

  /// Empty for an inspection, which has no level or estimate.
  final String level;
  final String range;
  final String rangeWords;
  final DateTime createdAt;

  /// full, service or inspection.
  final String kind;

  bool get isInspection => kind == 'inspection';

  Map<String, Object?> toJson() => {
    'number': number,
    'title': title,
    'size': size,
    'level': level,
    'range': range,
    'range_words': rangeWords,
    'created_at': createdAt.toIso8601String(),
    'kind': kind,
  };

  String get dateLabel => '${createdAt.day}/${createdAt.month}/${createdAt.year}';

  /// What the customer sends first on WhatsApp. No name or phone in it: the
  /// request number is enough to find them.
  String get whatsappText => [
    isInspection
        ? 'مرحبا ${Partner.instance.sponsorName.value}، بعتت طلب فحص شقة قبل الشراء من تطبيق عمّرها.'
        : 'مرحبا ${Partner.instance.sponsorName.value}، بعتت طلب عرض سعر من تطبيق عمّرها.',
    'رقم الطلب: $number',
    'الطلب: $title',
    if (size.isNotEmpty) isInspection ? 'الشقة: $size' : 'المساحة: $size',
    if (level.isNotEmpty) 'المستوى: $level',
    if (rangeWords.isNotEmpty) 'الكلفة التقريبية: $rangeWords',
  ].join('\n');
}

/// The customer's own requests, kept on the phone for the "طلباتي" tab, with
/// what the server says about each.
class RequestsStore extends ChangeNotifier {
  RequestsStore._();
  static final instance = RequestsStore._();

  static const _key = 'requests.saved';
  var _items = <SavedRequest>[];
  var _summaries = <int, RequestSummary>{};

  /// Newest first.
  List<SavedRequest> get items => List.unmodifiable(_items);

  /// Null until the server answers.
  RequestSummary? summaryOf(int number) => _summaries[number];

  /// Stages and materials waiting for the customer, across all requests.
  int get waiting => _summaries.values.fold(0, (sum, s) => sum + s.waiting);

  /// Asks the server where each request stands; quiet when offline. With an
  /// account it also learns about stages, reports and certificates.
  Future<void> refreshStatuses() async {
    if (!AppConfig.hasBackend || _items.isEmpty) return;
    try {
      if (await Customer.instance.ensureSignedIn()) {
        _summaries = {for (final s in await HomeFiles.myRequests()) s.number: s};
      } else {
        final rows = await Supabase.instance.client.rpc(
          'my_request_status',
          params: {'p_device_id': await Analytics.instance.ensureDeviceId()},
        ).timeout(AppConfig.requestTimeout) as List;
        _summaries = {
          for (final r in rows.cast<Map<String, dynamic>>())
            (r['request_no'] as num).toInt(): RequestSummary.fromJson({...r, 'kind': 'full'}),
        };
      }
      notifyListeners();
    } catch (_) {
      // Offline: the list shows without statuses.
    }
  }

  /// Demo builds have no server to hand out numbers.
  int get nextDemoNumber => _items.fold(100, (top, r) => r.number > top ? r.number : top) + 1;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    _items = saved == null
        ? []
        : [for (final json in jsonDecode(saved) as List) SavedRequest.fromJson(json as Map<String, dynamic>)];
    notifyListeners();
  }

  Future<void> add(SavedRequest request) async {
    _items = [request, ..._items];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final r in _items) r.toJson()]));
  }
}

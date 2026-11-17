import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/config.dart';
import 'analytics.dart';
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
  });

  factory SavedRequest.fromJson(Map<String, dynamic> json) => SavedRequest(
    number: json['number'] as int,
    title: json['title'] as String,
    size: json['size'] as String,
    level: json['level'] as String,
    range: json['range'] as String,
    rangeWords: json['range_words'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  /// The number that follows the request to the contract and the statement.
  final int number;
  final String title;
  final String size;
  final String level;
  final String range;
  final String rangeWords;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'number': number,
    'title': title,
    'size': size,
    'level': level,
    'range': range,
    'range_words': rangeWords,
    'created_at': createdAt.toIso8601String(),
  };

  String get dateLabel => '${createdAt.day}/${createdAt.month}/${createdAt.year}';

  /// What the customer sends first on WhatsApp. No name or phone in it: the
  /// request number is enough to find them.
  String get whatsappText => [
    'مرحبا ${Partner.instance.sponsorName.value}، بعتت طلب عرض سعر من تطبيق عمّرها.',
    'رقم الطلب: $number',
    'الطلب: $title',
    'المساحة: $size',
    'المستوى: $level',
    'الكلفة التقريبية: $rangeWords',
  ].join('\n');
}

/// Where a request stands, as سنديان records it in the dashboard.
class RequestStatus {
  const RequestStatus(this.status, this.inspectionAt);

  final String status;
  final DateTime? inspectionAt;

  String get label => switch (status) {
    'contacted' => 'تم التواصل',
    'inspection' => inspectionAt == null ? 'معاينة' : 'معاينة ${inspectionAt!.day}/${inspectionAt!.month}',
    'agreed' => 'تم الاتفاق',
    'not_agreed' => 'ما تم الاتفاق',
    'done' => 'خلص الشغل',
    _ => 'وصل طلبك',
  };
}

/// The customer's own requests, kept on the phone for the "طلباتي" tab.
class RequestsStore extends ChangeNotifier {
  RequestsStore._();
  static final instance = RequestsStore._();

  static const _key = 'requests.saved';
  var _items = <SavedRequest>[];
  var _statuses = <int, RequestStatus>{};

  /// Newest first.
  List<SavedRequest> get items => List.unmodifiable(_items);

  /// Null until the server answers.
  RequestStatus? statusOf(int number) => _statuses[number];

  /// Asks the server where each request stands; quiet when offline.
  Future<void> refreshStatuses() async {
    if (!AppConfig.hasBackend || _items.isEmpty) return;
    try {
      final rows = await Supabase.instance.client.rpc(
        'my_request_status',
        params: {'p_device_id': await Analytics.instance.ensureDeviceId()},
      ).timeout(AppConfig.requestTimeout) as List;
      _statuses = {
        for (final r in rows.cast<Map<String, dynamic>>())
          (r['request_no'] as num).toInt(): RequestStatus(
            r['status'] as String,
            r['inspection_at'] == null ? null : DateTime.parse(r['inspection_at'] as String).toLocal(),
          ),
      };
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

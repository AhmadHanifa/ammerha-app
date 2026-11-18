/// Everything about one request that the customer may see: its stages and
/// their photos, the wiring map, the materials, payments, the inspection
/// report and the certificate. Loaded by `my_request_file`.
class RequestFile {
  const RequestFile({
    required this.requestId,
    required this.number,
    required this.kind,
    required this.status,
    required this.stages,
    required this.media,
    required this.payments,
    this.services = const [],
    this.area,
    this.rooms,
    this.baths,
    this.level,
    this.inspectionAt,
    this.remote = false,
    this.report,
    this.certificate,
  });

  factory RequestFile.fromJson(Map<String, dynamic> json, Map<String, String> urls) {
    final r = json['request'] as Map<String, dynamic>;
    return RequestFile(
      requestId: r['id'] as String,
      number: (r['request_no'] as num).toInt(),
      kind: r['kind'] as String,
      status: r['status'] as String,
      services: ((r['services'] as List?) ?? const []).cast<String>(),
      area: r['area_m2'] as num?,
      rooms: (r['rooms'] as num?)?.toInt(),
      baths: (r['baths'] as num?)?.toInt(),
      level: r['level'] as String?,
      inspectionAt: _date(r['inspection_at']),
      remote: r['remote'] == true,
      stages: [for (final s in (json['stages'] as List).cast<Map<String, dynamic>>()) Stage.fromJson(s)],
      media: [
        for (final m in (json['media'] as List).cast<Map<String, dynamic>>())
          MediaItem.fromJson(m, urls[m['path']]),
      ],
      payments: [for (final p in (json['payments'] as List).cast<Map<String, dynamic>>()) Payment.fromJson(p)],
      report: json['report'] == null ? null : InspectionReport.fromJson(json['report'] as Map<String, dynamic>),
      certificate: json['certificate'] == null
          ? null
          : Certificate.fromJson(json['certificate'] as Map<String, dynamic>),
    );
  }

  final String requestId;
  final int number;
  final String kind;
  final String status;
  final List<String> services;
  final num? area;
  final int? rooms;
  final int? baths;
  final String? level;
  final DateTime? inspectionAt;
  final bool remote;
  final List<Stage> stages;
  final List<MediaItem> media;
  final List<Payment> payments;
  final InspectionReport? report;
  final Certificate? certificate;

  bool get isInspection => kind == 'inspection';

  List<MediaItem> category(String name) => media.where((m) => m.category == name).toList();
  List<MediaItem> ofStage(String stageId) => media.where((m) => m.stageId == stageId).toList();
}

DateTime? _date(Object? iso) => iso == null ? null : DateTime.parse(iso as String).toLocal();

String shortDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

class Stage {
  const Stage({
    required this.id,
    required this.title,
    required this.status,
    this.paymentUsd,
    this.readyAt,
    this.decidedAt,
    this.customerNote,
  });

  factory Stage.fromJson(Map<String, dynamic> j) => Stage(
    id: j['id'] as String,
    title: j['title'] as String,
    status: j['status'] as String,
    paymentUsd: j['payment_usd'] as num?,
    readyAt: _date(j['ready_at']),
    decidedAt: _date(j['decided_at']),
    customerNote: j['customer_note'] as String?,
  );

  final String id;
  final String title;
  final String status;
  final num? paymentUsd;
  final DateTime? readyAt;
  final DateTime? decidedAt;
  final String? customerNote;

  bool get waitsForMe => status == 'ready';

  String get label => switch (status) {
    'in_progress' => 'عم يشتغلوا عليها',
    'ready' => 'خلصت، بانتظار موافقتك',
    'approved' => 'وافقت عليها',
    'changes' => 'طلبت تعديل',
    _ => 'لسا ما بلّشت',
  };
}

class MediaItem {
  const MediaItem({
    required this.id,
    required this.category,
    required this.path,
    this.url,
    this.stageId,
    this.caption,
    this.room,
    this.needsConfirmation = false,
    this.confirmedAt,
  });

  factory MediaItem.fromJson(Map<String, dynamic> j, String? url) => MediaItem(
    id: j['id'] as String,
    category: j['category'] as String,
    path: j['path'] as String,
    url: url,
    stageId: j['stage_id'] as String?,
    caption: j['caption'] as String?,
    room: j['room'] as String?,
    needsConfirmation: j['needs_confirmation'] == true,
    confirmedAt: _date(j['confirmed_at']),
  );

  final String id;
  final String category;
  final String path;

  /// A signed link, valid for an hour; null when it could not be made.
  final String? url;
  final String? stageId;
  final String? caption;
  final String? room;
  final bool needsConfirmation;
  final DateTime? confirmedAt;

  bool get waitsForMe => needsConfirmation && confirmedAt == null;
}

class Payment {
  const Payment({required this.amount, required this.paidOn, this.stageId});

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
    amount: j['amount'] as num,
    paidOn: DateTime.parse(j['paid_on'] as String),
    stageId: j['stage_id'] as String?,
  );

  final num amount;
  final DateTime paidOn;
  final String? stageId;
}

class ReportIssue {
  const ReportIssue({required this.title, required this.severity, this.note, this.costMin, this.costMax});

  factory ReportIssue.fromJson(Map<String, dynamic> j) => ReportIssue(
    title: j['title'] as String? ?? '',
    severity: j['severity'] as String? ?? 'medium',
    note: j['note'] as String?,
    costMin: j['cost_min'] as num?,
    costMax: j['cost_max'] as num?,
  );

  final String title;
  final String severity;
  final String? note;
  final num? costMin;
  final num? costMax;

  String get severityLabel => switch (severity) {
    'high' => 'مهم',
    'low' => 'بسيط',
    _ => 'متوسط',
  };
}

class InspectionReport {
  const InspectionReport({required this.issues, this.summary, this.totalMin, this.totalMax, this.publishedAt});

  factory InspectionReport.fromJson(Map<String, dynamic> j) => InspectionReport(
    summary: j['summary'] as String?,
    issues: [for (final i in ((j['issues'] as List?) ?? const []).cast<Map<String, dynamic>>()) ReportIssue.fromJson(i)],
    totalMin: j['total_min'] as num?,
    totalMax: j['total_max'] as num?,
    publishedAt: _date(j['published_at']),
  );

  final String? summary;
  final List<ReportIssue> issues;
  final num? totalMin;
  final num? totalMax;
  final DateTime? publishedAt;
}

class Certificate {
  const Certificate({
    required this.code,
    required this.issuedAt,
    required this.warrantyMonths,
    required this.isPublic,
    this.warrantyUntil,
    this.note,
  });

  factory Certificate.fromJson(Map<String, dynamic> j) => Certificate(
    code: j['code'] as String,
    issuedAt: DateTime.parse(j['issued_at'] as String).toLocal(),
    warrantyMonths: (j['warranty_months'] as num).toInt(),
    warrantyUntil: j['warranty_until'] == null ? null : DateTime.parse(j['warranty_until'] as String),
    isPublic: j['is_public'] == true,
    note: j['note'] as String?,
  );

  final String code;
  final DateTime issuedAt;
  final int warrantyMonths;
  final DateTime? warrantyUntil;
  final bool isPublic;
  final String? note;

  String get shareText =>
      'شقتي موثّقة من عمّرها: فيها مراحل الشغل والمواد والضمان.\n'
      'كود الشهادة: $code\n'
      'تحقق منه من تطبيق عمّرها، من "تحقق من شقة موثّقة".';
}

/// One line in "طلباتي", from `my_requests`.
class RequestSummary {
  const RequestSummary({
    required this.number,
    required this.kind,
    required this.status,
    this.inspectionAt,
    this.stages = 0,
    this.waiting = 0,
    this.report = false,
    this.certificate = false,
  });

  factory RequestSummary.fromJson(Map<String, dynamic> j) => RequestSummary(
    number: (j['request_no'] as num).toInt(),
    kind: j['kind'] as String? ?? 'full',
    status: j['status'] as String,
    inspectionAt: _date(j['inspection_at']),
    stages: (j['stages'] as num? ?? 0).toInt(),
    waiting: (j['waiting'] as num? ?? 0).toInt(),
    report: j['report'] == true,
    certificate: j['certificate'] == true,
  );

  final int number;
  final String kind;
  final String status;
  final DateTime? inspectionAt;
  final int stages;

  /// Stages and materials waiting for the customer's answer.
  final int waiting;
  final bool report;
  final bool certificate;

  String get statusLabel => switch (status) {
    'contacted' => 'تم التواصل',
    'inspection' => inspectionAt == null ? 'معاينة' : 'معاينة ${inspectionAt!.day}/${inspectionAt!.month}',
    'agreed' => 'تم الاتفاق',
    'not_agreed' => 'ما تم الاتفاق',
    'done' => 'خلص الشغل',
    _ => 'وصل طلبك',
  };
}

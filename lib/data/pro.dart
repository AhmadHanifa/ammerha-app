import 'home_file.dart';
import 'providers.dart';
import 'showcase.dart';

/// The signed-in provider's own profile.
class MyProfile {
  const MyProfile({
    required this.id,
    required this.kind,
    required this.name,
    required this.phone,
    required this.services,
    required this.status,
    required this.jobs,
    required this.reviews,
    this.specialty,
    this.area,
    this.years,
    this.bio,
    this.photoUrl,
    this.syndicateNo,
    this.hasCertificate = false,
    this.reviewNote,
    this.verified = false,
    this.rating,
  });

  factory MyProfile.fromJson(Map<String, dynamic> j, String Function(String) url) => MyProfile(
    id: j['id'] as String,
    kind: j['kind'] as String,
    name: j['name'] as String,
    phone: j['phone'] as String? ?? '',
    services: ((j['services'] as List?) ?? const []).cast<String>(),
    status: j['status'] as String,
    jobs: (j['jobs'] as num? ?? 0).toInt(),
    reviews: (j['reviews'] as num? ?? 0).toInt(),
    specialty: j['specialty'] as String?,
    area: j['area'] as String?,
    years: (j['years'] as num?)?.toInt(),
    bio: j['bio'] as String?,
    photoUrl: j['photo_path'] == null ? null : url(j['photo_path'] as String),
    syndicateNo: j['syndicate_no'] as String?,
    hasCertificate: j['has_certificate'] == true,
    reviewNote: j['review_note'] as String?,
    verified: j['is_verified'] == true,
    rating: j['rating'] as num?,
  );

  final String id;
  final String kind;
  final String name;
  final String phone;
  final List<String> services;

  /// pending · approved · rejected · suspended
  final String status;
  final int jobs;
  final int reviews;
  final String? specialty;
  final String? area;
  final int? years;
  final String? bio;
  final String? photoUrl;
  final String? syndicateNo;
  final bool hasCertificate;
  final String? reviewNote;
  final bool verified;
  final num? rating;

  bool get approved => status == 'approved';
  String get kindLabel => providerKindLabels[kind] ?? kind;
}

/// One of the provider's jobs, in their list.
class JobSummary {
  const JobSummary({
    required this.number,
    required this.kind,
    required this.services,
    required this.status,
    required this.customer,
    required this.createdAt,
    this.area,
    this.place,
    this.stages = 0,
    this.openClaims = 0,
  });

  factory JobSummary.fromJson(Map<String, dynamic> j) => JobSummary(
    number: (j['request_no'] as num).toInt(),
    kind: j['kind'] as String,
    services: ((j['services'] as List?) ?? const []).cast<String>(),
    status: j['status'] as String,
    customer: j['name'] as String,
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
    area: j['area_m2'] as num?,
    place: j['area_text'] as String?,
    stages: (j['stages'] as num? ?? 0).toInt(),
    openClaims: (j['open_claims'] as num? ?? 0).toInt(),
  );

  final int number;
  final String kind;
  final List<String> services;
  final String status;
  final String customer;
  final DateTime createdAt;
  final num? area;
  final String? place;
  final int stages;
  final int openClaims;

  String get title => switch (kind) {
    'full' => 'إكساء شقة كاملة',
    'inspection' => 'فحص قبل الشراء',
    _ => servicesLabel(services),
  };
}

/// A job as the provider works on it.
class JobFile {
  const JobFile({
    required this.requestId,
    required this.number,
    required this.title,
    required this.customer,
    required this.whatsapp,
    required this.stages,
    required this.media,
    required this.claims,
    this.place,
    this.notes,
    this.size,
    this.level,
  });

  factory JobFile.fromJson(Map<String, dynamic> j, Map<String, String> urls) {
    final r = j['request'] as Map<String, dynamic>;
    final summary = JobSummary.fromJson({...r, 'created_at': DateTime.now().toIso8601String()});
    return JobFile(
      requestId: r['id'] as String,
      number: summary.number,
      title: summary.title,
      customer: r['name'] as String,
      whatsapp: r['whatsapp'] as String,
      place: r['area_text'] as String?,
      notes: r['notes'] as String?,
      size: [
        if (r['area_m2'] != null) '${r['area_m2']} م²',
        if (r['rooms'] != null) '${r['rooms']} غرف · ${r['baths']} حمام',
      ].join(' · '),
      level: levelFromKey(r['level'])?.label,
      stages: [for (final s in (j['stages'] as List).cast<Map<String, dynamic>>()) Stage.fromJson(s)],
      media: [
        for (final m in (j['media'] as List).cast<Map<String, dynamic>>()) MediaItem.fromJson(m, urls[m['path']]),
      ],
      claims: [for (final c in (j['claims'] as List).cast<Map<String, dynamic>>()) WarrantyClaim.fromJson(c)],
    );
  }

  final String requestId;
  final int number;
  final String title;
  final String customer;
  final String whatsapp;
  final String? place;
  final String? notes;
  final String? size;
  final String? level;
  final List<Stage> stages;
  final List<MediaItem> media;
  final List<WarrantyClaim> claims;

  List<MediaItem> category(String name) => media.where((m) => m.category == name).toList();
  List<MediaItem> ofStage(String stageId) => media.where((m) => m.stageId == stageId).toList();
}

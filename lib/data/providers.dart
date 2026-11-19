import 'showcase.dart';

const providerKindLabels = {'technician': 'فني', 'engineer': 'مهندس', 'contractor': 'متعهد'};

/// A technician, engineer or contractor with a public card. The numbers on
/// it come only from jobs done through the app.
class Provider {
  const Provider({
    required this.id,
    required this.kind,
    required this.name,
    required this.services,
    required this.photos,
    required this.jobs,
    required this.reviews,
    required this.claims,
    required this.claimsFixed,
    this.specialty,
    this.area,
    this.bio,
    this.photoUrl,
    this.years,
    this.verified = false,
    this.rating,
  });

  final String id;
  final String kind;
  final String name;
  final List<String> services;
  final List<ShowcasePhoto> photos;

  /// Jobs done through the app: finished, or with a stage the customer approved.
  final int jobs;
  final int reviews;

  /// Warranty calls that ended, and how many of them were fixed.
  final int claims;
  final int claimsFixed;
  final String? specialty;
  final String? area;
  final String? bio;
  final String? photoUrl;
  final int? years;
  final bool verified;
  final num? rating;

  String get kindLabel => providerKindLabels[kind] ?? kind;

  String get role => specialty ?? (services.isEmpty ? kindLabel : servicesLabel(services));
}

class ProviderReview {
  const ProviderReview({
    required this.rating,
    required this.createdAt,
    this.punctuality,
    this.cleanliness,
    this.quality,
    this.priceKept,
    this.comment,
    this.work,
  });

  factory ProviderReview.fromJson(Map<String, dynamic> j) => ProviderReview(
    rating: (j['rating'] as num).toInt(),
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
    punctuality: (j['punctuality'] as num?)?.toInt(),
    cleanliness: (j['cleanliness'] as num?)?.toInt(),
    quality: (j['quality'] as num?)?.toInt(),
    priceKept: j['price_kept'] as bool?,
    comment: j['comment'] as String?,
    work: j['work'] as String?,
  );

  final int rating;
  final DateTime createdAt;
  final int? punctuality;
  final int? cleanliness;
  final int? quality;
  final bool? priceKept;
  final String? comment;

  /// 'full', or the service keys joined by commas.
  final String? work;

  String get workLabel => work == null || work!.isEmpty
      ? ''
      : work == 'full'
      ? 'إكساء شقة كاملة'
      : servicesLabel(work!.split(','));
}

class WarrantyClaim {
  const WarrantyClaim({
    required this.id,
    required this.description,
    required this.status,
    required this.createdAt,
    this.visitAt,
    this.staffNote,
  });

  factory WarrantyClaim.fromJson(Map<String, dynamic> j) => WarrantyClaim(
    id: j['id'] as String,
    description: j['description'] as String,
    status: j['status'] as String,
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
    visitAt: j['visit_at'] == null ? null : DateTime.parse(j['visit_at'] as String).toLocal(),
    staffNote: j['staff_note'] as String?,
  );

  final String id;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime? visitAt;
  final String? staffNote;

  String get label => switch (status) {
    'scheduled' => visitAt == null ? 'تحدد موعد' : 'موعد ${visitAt!.day}/${visitAt!.month}',
    'fixed' => 'انصلحت',
    'rejected' => 'مو مشمولة بالضمان',
    _ => 'وصلت، عم نتابعها',
  };
}

/// The provider, review and warranty calls of one request.
class RequestExtras {
  const RequestExtras({
    required this.claims,
    required this.canReview,
    required this.canClaim,
    this.provider,
    this.review,
  });

  factory RequestExtras.fromJson(Map<String, dynamic> j, String Function(String path) url) {
    final p = j['provider'] as Map<String, dynamic>?;
    return RequestExtras(
      provider: p == null
          ? null
          : (
              id: p['id'] as String,
              name: p['name'] as String,
              role: p['specialty'] as String? ?? providerKindLabels[p['kind']] ?? '',
              photoUrl: p['photo_path'] == null ? null : url(p['photo_path'] as String),
              verified: p['is_verified'] == true,
            ),
      review: j['review'] == null
          ? null
          : ProviderReview.fromJson({...j['review'] as Map<String, dynamic>, 'work': null}),
      claims: [for (final c in ((j['claims'] as List?) ?? const []).cast<Map<String, dynamic>>()) WarrantyClaim.fromJson(c)],
      canReview: j['can_review'] == true,
      canClaim: j['can_claim'] == true,
    );
  }

  final ({String id, String name, String role, String? photoUrl, bool verified})? provider;
  final ProviderReview? review;
  final List<WarrantyClaim> claims;
  final bool canReview;
  final bool canClaim;
}

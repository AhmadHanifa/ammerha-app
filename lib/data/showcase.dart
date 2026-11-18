import 'estimate.dart';

/// Labels shared by the gallery and the ready designs.
const roomLabels = {
  'living': 'صالون',
  'kitchen': 'مطبخ',
  'bedroom': 'غرفة نوم',
  'bath': 'حمام',
  'entrance': 'مدخل',
  'kids': 'غرفة أولاد',
  'office': 'مكتب',
};

const styleLabels = {
  'modern': 'مودرن',
  'classic': 'كلاسيك',
  'neo_classic': 'نيو كلاسيك',
  'minimal': 'بسيط',
  'rustic': 'ريفي',
};

const photoStageLabels = {'before': 'قبل', 'during': 'خلال الشغل', 'after': 'بعد'};

FinishLevel? levelFromKey(Object? key) => FinishLevel.values.where((l) => l.name == key).firstOrNull;

String servicesLabel(List<String> keys) =>
    Service.values.where((s) => keys.contains(s.key)).map((s) => s.label).join(' + ');

class ShowcasePhoto {
  const ShowcasePhoto({required this.url, this.stage, this.caption});

  final String url;
  final String? stage;
  final String? caption;
}

/// A finished job by سنديان, in "معرض الأعمال".
class GalleryProject {
  const GalleryProject({
    required this.id,
    required this.title,
    required this.kind,
    required this.services,
    required this.photos,
    this.area,
    this.level,
    this.location,
    this.durationWeeks,
    this.costUsd,
    this.story,
  });

  final String id;
  final String title;
  final String kind;
  final List<String> services;
  final List<ShowcasePhoto> photos;
  final num? area;
  final FinishLevel? level;
  final String? location;
  final int? durationWeeks;
  final num? costUsd;
  final String? story;

  /// The "after" photo when there is one.
  ShowcasePhoto? get cover => photos.where((p) => p.stage == 'after').firstOrNull ?? photos.firstOrNull;

  String get workLabel => kind == 'full' ? 'إكساء شقة كاملة' : servicesLabel(services);
}

/// A ready design by the engineer, in "تصاميم جاهزة". It has no price: the
/// customer picks it, and the quote is made for their own home.
class ReadyDesign {
  const ReadyDesign({
    required this.id,
    required this.title,
    required this.room,
    required this.style,
    required this.photos,
    this.level,
    this.description,
  });

  final String id;
  final String title;
  final String room;
  final String style;
  final List<ShowcasePhoto> photos;
  final FinishLevel? level;
  final String? description;

  String get roomLabel => roomLabels[room] ?? room;
  String get styleLabel => styleLabels[style] ?? style;
}

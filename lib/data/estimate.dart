import 'package:flutter/material.dart';

enum FinishLevel {
  economy('اقتصادي'),
  medium('وسط'),
  deluxe('ديلوكس');

  const FinishLevel(this.label);
  final String label;
}

enum RequestKind { full, service }

/// The single services the customer can ask for on their own.
/// [key] matches `unit_prices.service` in the backend.
enum Service {
  paint('paint', 'دهان', 'الدهان', Icons.format_paint_outlined),
  tiles('tiles', 'بلاط', 'البلاط', Icons.grid_view_outlined),
  kitchenWood('kitchen_wood', 'مطبخ وأعمال خشبية', 'المطبخ والأعمال الخشبية', Icons.kitchen_outlined),
  gypsum('gypsum', 'جبصين', 'الجبصين', Icons.layers_outlined),
  electricPlumbing('electric_plumbing', 'كهربا وصحية', 'الكهربا والصحية', Icons.electrical_services_outlined);

  const Service(this.key, this.label, this.definite, this.icon);
  final String key;
  final String label;

  /// With the article, for "ضيف البلاط كمان".
  final String definite;
  final IconData icon;

  /// The service worth offering next to this one.
  Service get companion => switch (this) {
    Service.paint || Service.electricPlumbing => Service.tiles,
    Service.tiles || Service.gypsum || Service.kitchenWood => Service.paint,
  };
}

/// What the customer answered in the calculator.
class CalcInput {
  const CalcInput({
    this.kind = RequestKind.full,
    this.services = const {},
    this.area = 100,
    this.rooms = 3,
    this.baths = 2,
    this.level = FinishLevel.medium,
  });

  final RequestKind kind;
  final Set<Service> services;
  final int area;
  final int rooms;
  final int baths;
  final FinishLevel level;

  bool get isFull => kind == RequestKind.full;

  /// Paint and gypsum are priced from the area alone.
  bool get needsRooms => isFull || services.any((s) => s != Service.paint && s != Service.gypsum);

  List<Service> get orderedServices => [
    for (final s in Service.values)
      if (services.contains(s)) s,
  ];

  String get title => isFull ? 'إكساء شقة كاملة' : orderedServices.map((s) => s.label).join(' + ');

  String get sizeLabel => needsRooms ? '$area م² · $rooms غرف · $baths حمام' : '$area م²';

  CalcInput copyWith({Set<Service>? services, int? area, int? rooms, int? baths, FinishLevel? level}) => CalcInput(
    kind: kind,
    services: services ?? this.services,
    area: area ?? this.area,
    rooms: rooms ?? this.rooms,
    baths: baths ?? this.baths,
    level: level ?? this.level,
  );

  /// Arguments shared by the `calc_estimate` and `submit_quote` RPCs.
  Map<String, Object?> get rpcParams => {
    'p_kind': kind.name,
    'p_services': [for (final s in orderedServices) s.key],
    'p_area': area,
    'p_rooms': needsRooms ? rooms : null,
    'p_baths': needsRooms ? baths : null,
    'p_level': level.name,
  };
}

/// A rule for small jobs that the estimate fell under.
class SmallJobNote {
  const SmallJobNote({required this.minOrder, required this.amount});

  /// True for a minimum order, false for an inspection fee.
  final bool minOrder;
  final int amount;
}

/// The approximate price range; the final price is the contractor's, after the visit.
class Estimate {
  const Estimate({required this.min, required this.max, this.bundleDiscount = 0, this.smallJob});

  factory Estimate.fromJson(Map<String, dynamic> json) {
    final small = json['small_job'] as Map<String, dynamic>?;
    return Estimate(
      min: (json['min'] as num).round(),
      max: (json['max'] as num).round(),
      bundleDiscount: json['bundle_discount'] as num? ?? 0,
      smallJob: small == null
          ? null
          : SmallJobNote(minOrder: small['mode'] == 'min_order', amount: (small['amount'] as num).round()),
    );
  }

  final int min;
  final int max;

  /// Percent taken off when more than one service is ordered together.
  final num bundleDiscount;
  final SmallJobNote? smallJob;

  String get range => '${groupDigits('$min')} – ${groupDigits('$max')} \$';
  String get rangeWords => '${groupDigits('$min')} لـ ${groupDigits('$max')} دولار';
}

String groupDigits(String s) {
  final parts = s.split('.');
  final intPart = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
}

String formatPercent(num v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

// ───────────────────────── Demo builds only ─────────────────────────

/// One priced item: quantity = base + perM2·area + perRoom·rooms + perBath·baths.
class _DemoItem {
  const _DemoItem(this.service, this.prices, {this.base = 0, this.perM2 = 0, this.perRoom = 0, this.perBath = 0});

  /// Null for items that only belong to a full apartment.
  final Service? service;

  /// Economy, medium, deluxe.
  final List<double> prices;
  final double base;
  final double perM2;
  final double perRoom;
  final double perBath;
}

// Placeholder numbers, the same starter rows as the backend migration. A build
// with a backend never uses them: it asks `calc_estimate`, which reads the
// contractor's real unit prices from the dashboard.
const _demoItems = [
  _DemoItem(Service.tiles, [9, 14, 24], perM2: 1.05),
  _DemoItem(Service.tiles, [9, 13, 22], base: 12, perBath: 22),
  _DemoItem(Service.tiles, [1.5, 2.5, 4.5], perM2: 0.6),
  _DemoItem(Service.paint, [2, 3, 5], perM2: 3.2),
  _DemoItem(Service.paint, [1, 1.5, 2.5], perM2: 3.2),
  _DemoItem(Service.gypsum, [7, 11, 17], perM2: 0.6),
  _DemoItem(Service.gypsum, [2.5, 4, 8], perM2: 0.5),
  _DemoItem(Service.electricPlumbing, [10, 14, 20], base: 6, perM2: 0.25, perRoom: 5, perBath: 3),
  _DemoItem(Service.electricPlumbing, [120, 180, 300], base: 1),
  _DemoItem(Service.electricPlumbing, [220, 320, 480], perBath: 1),
  _DemoItem(Service.electricPlumbing, [220, 380, 750], perBath: 1),
  _DemoItem(Service.electricPlumbing, [120, 180, 300], base: 1),
  _DemoItem(Service.kitchenWood, [140, 220, 380], base: 3, perM2: 0.02),
  _DemoItem(Service.kitchenWood, [100, 160, 280], base: 1, perRoom: 1, perBath: 1),
  _DemoItem(Service.kitchenWood, [240, 380, 650], base: 1),
  _DemoItem(null, [45, 65, 110], perM2: 0.12),
];

const _demoSpreadLow = 16.5;
const _demoSpreadHigh = 17.0;
const _demoBundleDiscount = 5;

/// The same arithmetic as `calc_estimate`, for builds without a backend.
Estimate demoEstimate(CalcInput input) {
  final rooms = input.needsRooms ? input.rooms : 0;
  final baths = input.needsRooms ? input.baths : 0;
  var total = 0.0;
  for (final item in _demoItems) {
    if (!input.isFull && !input.services.contains(item.service)) continue;
    final quantity = item.base + item.perM2 * input.area + item.perRoom * rooms + item.perBath * baths;
    total += quantity * item.prices[input.level.index];
  }
  if (input.isFull || input.services.length >= 2) total *= 1 - _demoBundleDiscount / 100;

  int rounded(double v) => v >= 1000 ? (v / 50).round() * 50 : (v / 10).round() * 10;
  return Estimate(
    min: rounded(total * (1 - _demoSpreadLow / 100)),
    max: rounded(total * (1 + _demoSpreadHigh / 100)),
    bundleDiscount: _demoBundleDiscount,
  );
}

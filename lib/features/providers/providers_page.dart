import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/estimate.dart';
import '../../data/home_file.dart';
import '../../data/providers.dart';
import '../../services/showcase.dart';
import '../../widgets/common.dart';
import '../../widgets/rating.dart';
import '../showcase/gallery_page.dart';

/// فنيين ومهندسين موثّقين: everyone with a public card, with numbers that
/// come only from jobs done through the app.
class ProvidersPage extends StatefulWidget {
  const ProvidersPage({super.key});

  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  late Future<List<Provider>> _providers = Showcase.instance.providers();
  String? _kind;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: _providers,
          builder: (context, snap) {
            final all = snap.data ?? const <Provider>[];
            final kinds = [for (final k in providerKindLabels.keys) if (all.any((p) => p.kind == k)) k];
            final shown = _kind == null ? all : all.where((p) => p.kind == _kind).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                ScreenHeader(title: 'فنيين ومهندسين', onBack: () => context.pop()),
                const SizedBox(height: 6),
                Text(
                  'كل رقم هون من شغل حقيقي انعمل عن طريق التطبيق: الشغلات، والتقييمات، والضمان.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                if (kinds.length > 1) ...[
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(label: const Text('الكل'), selected: _kind == null, onSelected: (_) => setState(() => _kind = null)),
                      for (final k in kinds)
                        ChoiceChip(
                          label: Text(switch (k) {
                            'engineer' => 'مهندسين',
                            'contractor' => 'متعهدين',
                            _ => 'فنيين',
                          }),
                          selected: _kind == k,
                          onSelected: (_) => setState(() => _kind = k),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                if (shown.isEmpty)
                  showcaseState(
                    snap,
                    onRetry: () => setState(() => _providers = Showcase.instance.providers(refresh: true)),
                    empty: 'قريباً بيطلع هون فنيين ومهندسين موثّقين بحلب.',
                  )
                else
                  for (final p in shown) ...[ProviderTile(provider: p), const SizedBox(height: 10)],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A provider in a list: photo, name, what they do, stars and jobs.
class ProviderTile extends StatelessWidget {
  const ProviderTile({super.key, required this.provider, this.width});

  final Provider provider;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final p = provider;
    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card + 2),
          side: const BorderSide(color: AppColors.line),
        ),
        child: InkWell(
          onTap: () => context.push('/providers/item', extra: p),
          borderRadius: BorderRadius.circular(AppRadius.card + 2),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ProviderAvatar(name: p.name, url: p.photoUrl, verified: p.verified),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(
                        [p.role, if (p.area != null) p.area!].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (p.rating != null) ...[
                            Stars(value: p.rating!, size: 15),
                            const SizedBox(width: 4),
                            Text('${p.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              p.jobs == 0 ? 'جديد بالتطبيق' : '${p.jobs} شغلة موثّقة',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProviderPage extends StatefulWidget {
  const ProviderPage({super.key, required this.provider});

  final Provider provider;

  @override
  State<ProviderPage> createState() => _ProviderPageState();
}

class _ProviderPageState extends State<ProviderPage> {
  late final Future<List<ProviderReview>> _reviews = Showcase.instance.reviews(widget.provider.id);

  void _ask() {
    final p = widget.provider;
    final services = {for (final s in Service.values) if (p.services.contains(s.key)) s};
    context.push(
      '/calculator',
      extra: services.isEmpty || p.kind != 'technician'
          ? CalcInput(providerId: p.id, providerName: p.name)
          : CalcInput(kind: RequestKind.service, services: services, providerId: p.id, providerName: p.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                children: [
                  ScreenHeader(title: p.name, onBack: () => context.pop()),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ProviderAvatar(name: p.name, url: p.photoUrl, size: 76, verified: p.verified),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.role, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                            Text(
                              [
                                p.kindLabel,
                                if (p.area != null) p.area!,
                                if (p.years != null) 'خبرة ${p.years} سنة',
                              ].join(' · '),
                              style: text.bodySmall,
                            ),
                            if (p.verified)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Pill(label: 'موثّق من عمّرها', background: AppColors.primaryTint, foreground: AppColors.primaryDark),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _Stat(value: '${p.jobs}', label: 'شغلة موثّقة'),
                      const SizedBox(width: 8),
                      _Stat(value: p.rating == null ? '—' : '${p.rating}', label: '${p.reviews} تقييم'),
                      const SizedBox(width: 8),
                      _Stat(value: p.claims == 0 ? '—' : '${p.claimsFixed} من ${p.claims}', label: 'ضمانات انصلحت'),
                    ],
                  ),
                  if (p.bio != null) ...[
                    const SizedBox(height: 16),
                    Text(p.bio!, style: const TextStyle(fontSize: 15, height: 1.7)),
                  ],
                  if (p.photos.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text('من شغله', style: text.titleMedium),
                    const SizedBox(height: 8),
                    PhotoCarousel(photos: p.photos, height: 220),
                  ],
                  const SizedBox(height: 18),
                  Text('شو قالوا عنه', style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text('بس الزباين اللي اشتغل معهن عن طريق التطبيق بيقدروا يقيّموه.', style: text.bodySmall),
                  const SizedBox(height: 8),
                  FutureBuilder(
                    future: _reviews,
                    builder: (context, snap) {
                      final reviews = snap.data ?? const <ProviderReview>[];
                      if (snap.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        );
                      }
                      if (reviews.isEmpty) {
                        return const NoteRow(icon: Icons.rate_review_outlined, text: 'لسا ما في تقييمات.');
                      }
                      return Column(children: [for (final r in reviews) ReviewCard(review: r)]);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
              child: FilledButton(onPressed: _ask, child: const Text('اطلب منه عرض سعر')),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final ProviderReview review;

  @override
  Widget build(BuildContext context) {
    final r = review;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stars(value: r.rating),
                const Spacer(),
                Text(shortDate(r.createdAt), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (r.workLabel.isNotEmpty) Text(r.workLabel, style: Theme.of(context).textTheme.bodySmall),
            if (r.comment != null) ...[
              const SizedBox(height: 4),
              Text(r.comment!, style: const TextStyle(fontSize: 15)),
            ],
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (r.punctuality != null) InfoChip('المواعيد ${r.punctuality}/5'),
                if (r.cleanliness != null) InfoChip('النضافة ${r.cleanliness}/5'),
                if (r.quality != null) InfoChip('الجودة ${r.quality}/5'),
                if (r.priceKept != null) InfoChip(r.priceKept! ? 'التزم بالسعر' : 'غيّر السعر'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/estimate.dart';
import '../../data/showcase.dart';
import '../../services/showcase.dart';
import '../../widgets/common.dart';
import '../../widgets/photos.dart';
import '../../widgets/states.dart';

/// "معرض الأعمال": finished jobs by سنديان, before and after.
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late Future<List<GalleryProject>> _projects = Showcase.instance.gallery();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: _projects,
          builder: (context, snap) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              ScreenHeader(title: 'معرض الأعمال', onBack: () => context.pop()),
              const SizedBox(height: 16),
              if (snap.hasError)
                _Retry(onRetry: () => setState(() => _projects = Showcase.instance.gallery(refresh: true)))
              else if (!snap.hasData)
                const _Loading()
              else if (snap.data!.isEmpty)
                const _Empty(text: 'قريباً بتطلع هون صور من شقق خلّصها فريق سنديان.')
              else
                for (final p in snap.data!) ...[
                  ShowcaseCard(
                    imageUrl: p.cover?.url,
                    title: p.title,
                    subtitle: [
                      p.workLabel,
                      if (p.area != null) '${p.area} م²',
                      if (p.level != null) p.level!.label,
                    ].join(' · '),
                    height: 190,
                    onTap: () => context.push('/gallery/item', extra: p),
                  ),
                  const SizedBox(height: 14),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class GalleryProjectPage extends StatelessWidget {
  const GalleryProjectPage({super.key, required this.project});

  final GalleryProject project;

  @override
  Widget build(BuildContext context) {
    final p = project;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                children: [
                  ScreenHeader(title: p.title, onBack: () => context.pop()),
                  const SizedBox(height: 14),
                  PhotoCarousel(photos: p.photos),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      InfoChip(p.workLabel),
                      if (p.area != null) InfoChip('${p.area} م²'),
                      if (p.level != null) InfoChip('مستوى ${p.level!.label}'),
                      if (p.location != null) InfoChip(p.location!),
                      if (p.durationWeeks != null) InfoChip('${p.durationWeeks} أسابيع'),
                    ],
                  ),
                  if (p.costUsd != null) ...[
                    const SizedBox(height: 14),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(child: Text('كلفة الشغل', style: Theme.of(context).textTheme.bodySmall)),
                          Text(
                            '${groupDigits('${p.costUsd!.round()}')} \$',
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (p.story != null) ...[
                    const SizedBox(height: 14),
                    Text(p.story!, style: const TextStyle(fontSize: 15, height: 1.7)),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
              child: FilledButton(
                onPressed: () => context.push(
                  '/calculator',
                  extra: CalcInput(level: p.level ?? FinishLevel.medium, area: (p.area ?? 100).round()),
                ),
                child: const Text('بدي متل هالشغل: احسب كلفة شقتي'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A photo with a title over a soft shade, for gallery and design lists.
class ShowcaseCard extends StatelessWidget {
  const ShowcaseCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.height = 160,
    this.width,
  });

  final String? imageUrl;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: Material(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              NetImage(imageUrl, radius: 0),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xB3000000)],
                    stops: [0.45, 1],
                  ),
                ),
              ),
              Positioned(
                right: 14,
                left: 14,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Swipeable photos with a "قبل / بعد" label and dots.
class PhotoCarousel extends StatefulWidget {
  const PhotoCarousel({super.key, required this.photos, this.height = 260});

  final List<ShowcasePhoto> photos;
  final double height;

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    if (photos.isEmpty) return SizedBox(height: widget.height, child: const NetImage(null, radius: AppRadius.cardLarge));
    final stage = photoStageLabels[photos[_index].stage];
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              PageView.builder(
                itemCount: photos.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => showPhotos(
                    context,
                    [for (final p in photos) p.url],
                    initial: i,
                    captions: [for (final p in photos) p.caption],
                  ),
                  child: NetImage(photos[i].url, radius: AppRadius.cardLarge),
                ),
              ),
              if (stage != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Pill(label: stage, background: Colors.white, foreground: AppColors.primaryDark),
                ),
            ],
          ),
        ),
        if (photos.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < photos.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.primary : AppColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ],
        if (photos[_index].caption != null) ...[
          const SizedBox(height: 6),
          Text(photos[_index].caption!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const SkeletonList();
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => EmptyState(title: 'قريباً', body: text);
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        const Text('ما قدرنا نجيب الصور هلق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: onRetry,
          style: OutlinedButton.styleFrom(minimumSize: const Size(160, 44)),
          child: const Text('جرّب كمان مرة'),
        ),
      ],
    ),
  );
}

/// Loading, error and empty states for the other showcase screens.
Widget showcaseState<T>(AsyncSnapshot<List<T>> snap, {required VoidCallback onRetry, required String empty}) {
  if (snap.hasError) return _Retry(onRetry: onRetry);
  if (!snap.hasData) return const _Loading();
  return _Empty(text: empty);
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/estimate.dart';
import '../../data/providers.dart';
import '../../data/showcase.dart';
import '../../services/showcase.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/photos.dart';
import '../../widgets/states.dart';
import '../showcase/gallery_page.dart';

/// Three things up top (cost, a provider, an inspection), then real photos,
/// then the rest. Each kept to one tap.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
              child: const CustomPaint(painter: BrandMarkPainter(stroke: 0.09)),
            ),
            const SizedBox(width: 10),
            const Text('عمّرها', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 18),
        Text('شو بدك تعمّر؟', style: text.headlineSmall),
        const SizedBox(height: 2),
        const Text(
          'اعرف الكلفة، لاقي فني موثّق، أو افحص شقة قبل ما تشتريها.',
          style: TextStyle(fontSize: 15, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 16),
        const _CalcHero(),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Tile(
                  icon: Icons.engineering_outlined,
                  title: 'لاقي فني أو مهندس',
                  body: 'شغلهم وتقييماتهم، واحكيهم مباشرة.',
                  onTap: () => context.push('/providers'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Tile(
                  icon: Icons.fact_check_outlined,
                  title: 'افحص شقة قبل ما تشتري',
                  body: 'تقرير بالمشاكل وكلفة تصليحها.',
                  onTap: () => context.push('/inspection'),
                ),
              ),
            ],
          ),
        ),
        _Showcase<GalleryProject>(
          title: 'معرض الأعمال',
          load: Showcase.instance.gallery,
          onAll: () => context.push('/gallery'),
          card: (p) => ShowcaseCard(
            width: 240,
            imageUrl: p.cover?.url,
            title: p.title,
            subtitle: [p.workLabel, if (p.area != null) '${p.area} م²'].join(' · '),
            onTap: () => context.push('/gallery/item', extra: p),
          ),
        ),
        _Showcase<Provider>(
          title: 'فنيين ومهندسين موثّقين',
          load: Showcase.instance.providers,
          onAll: () => context.push('/providers'),
          card: (p) => ShowcaseCard(
            width: 190,
            imageUrl: p.photos.firstOrNull?.url ?? p.photoUrl,
            title: p.name,
            subtitle: [p.role, if (p.rating != null) '★ ${p.rating}'].join(' · '),
            onTap: () => context.push('/providers/item', extra: p),
          ),
        ),
        _Showcase<ReadyDesign>(
          title: 'تصاميم جاهزة',
          load: Showcase.instance.designs,
          onAll: () => context.push('/designs'),
          card: (d) => ShowcaseCard(
            width: 160,
            imageUrl: d.photos.firstOrNull?.url,
            title: d.title,
            subtitle: '${d.roomLabel} · ${d.styleLabel}',
            onTap: () => context.push('/designs/item', extra: d),
          ),
        ),
        const SizedBox(height: 18),
        _AbroadBanner(onTap: () => context.push('/abroad')),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () => context.push('/join'),
              icon: const Icon(Icons.handyman_outlined, size: 18),
              label: const Text('إنت فني أو مهندس؟ سجّل ببلاش'),
            ),
            TextButton.icon(
              onPressed: () => context.push('/verify'),
              icon: const Icon(Icons.workspace_premium_outlined, size: 18),
              label: const Text('عندك كود شقة موثّقة؟ تحقق منه'),
            ),
            TextButton(
              onPressed: () => context.push('/legal'),
              child: const Text('الخصوصية والشروط', style: TextStyle(fontSize: 14, color: AppColors.inkSoft)),
            ),
          ],
        ),
      ],
    );
  }
}

/// "احسب كلفة شقتك": the green card, over a finished job's photo when the
/// gallery has one.
class _CalcHero extends StatefulWidget {
  const _CalcHero();

  @override
  State<_CalcHero> createState() => _CalcHeroState();
}

class _CalcHeroState extends State<_CalcHero> {
  late final Future<List<GalleryProject>> _gallery = Showcase.instance.gallery().catchError((_) => <GalleryProject>[]);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.cardLarge);
    return FutureBuilder(
      future: _gallery,
      builder: (context, snap) {
        final photo = snap.data?.map((p) => p.cover?.url).whereType<String>().firstOrNull;
        return ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              if (photo != null) Positioned.fill(child: NetImage(photo, radius: 0)),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                decoration: BoxDecoration(
                  color: photo == null ? AppColors.primary : null,
                  gradient: photo == null
                      ? null
                      : LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.primaryDark.withValues(alpha: 0.55), AppColors.primaryDark.withValues(alpha: 0.92)],
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'احسب كلفة شقتك',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'كلفة تقريبية بدقيقتين، وبعدها اطلب عرض سعر.',
                      style: TextStyle(color: AppColors.primaryTint, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => context.push('/calculator', extra: const CalcInput()),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryDark,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('شقة كاملة'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.push('/services'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('خدمة وحدة'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.body, required this.onTap});

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.primaryDark),
              ),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 16, height: 1.4, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(body, style: const TextStyle(fontSize: 14, color: AppColors.inkSoft)),
            ],
          ),
        ),
      ),
    );
  }
}

/// «عمّرها وإنت برّا», for owners who live abroad.
class _AbroadBanner extends StatelessWidget {
  const _AbroadBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryTint,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.flight_takeoff_rounded, color: AppColors.primaryDark, size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('عايش برّا سوريا؟', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    Text(
                      'عمّر بيتك وتابع كل مرحلة بالصور من مكانك.',
                      style: TextStyle(fontSize: 14, color: AppColors.primaryDark),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: AppColors.primaryDark),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled row of photo cards: grey shapes while loading, hidden when empty.
class _Showcase<T> extends StatefulWidget {
  const _Showcase({required this.title, required this.load, required this.onAll, required this.card});

  final String title;
  final Future<List<T>> Function() load;
  final VoidCallback onAll;
  final Widget Function(T item) card;

  @override
  State<_Showcase<T>> createState() => _ShowcaseState<T>();
}

class _ShowcaseState<T> extends State<_Showcase<T>> {
  late final Future<List<T>> _items = widget.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _items,
      builder: (context, snap) {
        final loading = snap.connectionState != ConnectionState.done;
        final items = snap.data ?? const [];
        if (!loading && items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleMedium)),
                if (!loading) TextButton(onPressed: widget.onAll, child: const Text('عرض الكل')),
              ],
            ),
            SizedBox(
              height: 170,
              child: loading
                  ? ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 3,
                      separatorBuilder: (context, i) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => const Skeleton(width: 200, height: 170, radius: AppRadius.cardLarge),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      separatorBuilder: (context, i) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => widget.card(items[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

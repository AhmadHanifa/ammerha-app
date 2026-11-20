import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/estimate.dart';
import '../../data/providers.dart';
import '../../data/showcase.dart';
import '../../services/partner.dart';
import '../../services/showcase.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/common.dart';
import '../providers/providers_page.dart';
import '../showcase/gallery_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ValueListenableBuilder(
      valueListenable: Partner.instance.sponsorName,
      builder: (context, sponsor, _) => ListView(
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
          Text('قديش بدها شقتك؟', style: text.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'اعرف الكلفة التقريبية بدقيقتين، واطلب عرض سعر من فريق $sponsor.',
            style: const TextStyle(fontSize: 15, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 20),
          Text('بدك إكساء شقة كاملة، ولا خدمة وحدة؟', style: text.titleMedium),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.cardLarge)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إكساء شقة كاملة',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  'من البلاط للدهان والمطبخ، بعرض سعر واحد.',
                  style: TextStyle(color: AppColors.primaryTint, fontSize: 14),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => context.push('/calculator', extra: const CalcInput()),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ابدأ الحساب'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.cardLarge),
              side: const BorderSide(color: AppColors.line),
            ),
            child: InkWell(
              onTap: () => context.push('/services'),
              borderRadius: BorderRadius.circular(AppRadius.cardLarge),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('خدمة وحدة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(
                            Service.values.map((s) => s.label).join('، '),
                            style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _LinkCard(
            icon: Icons.engineering_outlined,
            title: 'فنيين ومهندسين موثّقين',
            body: 'شوف شغلهم وتقييماتهم، واحكيهم مباشرة.',
            onTap: () => context.push('/providers'),
          ),
          const SizedBox(height: 12),
          _LinkCard(
            icon: Icons.fact_check_outlined,
            title: 'بدك تشتري شقة؟',
            body: 'افحصها قبل ما تشتري: تقرير بالمشاكل وكلفة تصليحها.',
            onTap: () => context.push('/inspection'),
          ),
          const SizedBox(height: 12),
          _AbroadBanner(onTap: () => context.push('/abroad')),
          _Showcase<Provider>(
            title: 'فنيين ومهندسين موثّقين',
            load: Showcase.instance.providers,
            onAll: () => context.push('/providers'),
            height: 96,
            card: (p) => ProviderTile(provider: p, width: 280),
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
          const SizedBox(height: 22),
          Text('كيف بتمشي؟', style: text.titleMedium),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                for (final (i, step) in [
                  'بتحسب الكلفة التقريبية لشقتك أو للخدمة اللي بدك ياها.',
                  'بتكبس "اطلب عرض سعر" وبتاخد رقم لطلبك.',
                  'بينفتح الواتساب، وفريق $sponsor بيحدد معك موعد المعاينة.',
                ].indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(step, style: const TextStyle(fontSize: 15))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          const SizedBox(height: 8),
          _LinkCard(
            icon: Icons.handyman_outlined,
            title: 'إنت فني أو مهندس؟',
            body: 'سجّل ببلاش، وخلي شغلك يجيبلك زباين بتقييمات حقيقية.',
            onTap: () => context.push('/join'),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: () => context.push('/verify'),
              icon: const Icon(Icons.workspace_premium_outlined, size: 18),
              label: const Text('عندك كود شقة موثّقة؟ تحقق منه'),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => context.push('/legal'),
              child: const Text('الخصوصية والشروط', style: TextStyle(fontSize: 13, color: AppColors.inkSoft)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.icon, required this.title, required this.body, required this.onTap});

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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    Text(body, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
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
                      style: TextStyle(fontSize: 13, color: AppColors.primaryDark),
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

/// A titled row of photo cards; hidden while empty or unreachable.
class _Showcase<T> extends StatefulWidget {
  const _Showcase({required this.title, required this.load, required this.onAll, required this.card, this.height = 170});

  final String title;
  final Future<List<T>> Function() load;
  final VoidCallback onAll;
  final Widget Function(T item) card;
  final double height;

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
        final items = snap.data ?? const [];
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleMedium)),
                TextButton(onPressed: widget.onAll, child: const Text('عرض الكل')),
              ],
            ),
            SizedBox(
              height: widget.height,
              child: ListView.separated(
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

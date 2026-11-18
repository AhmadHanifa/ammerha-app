import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/estimate.dart';
import '../../data/showcase.dart';
import '../../services/showcase.dart';
import '../../widgets/common.dart';
import 'gallery_page.dart';

/// "تصاميم جاهزة": the engineer's designs, by room. No prices: the customer
/// picks one and the quote is made for their own home.
class DesignsPage extends StatefulWidget {
  const DesignsPage({super.key});

  @override
  State<DesignsPage> createState() => _DesignsPageState();
}

class _DesignsPageState extends State<DesignsPage> {
  late Future<List<ReadyDesign>> _designs = Showcase.instance.designs();
  String? _room;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: _designs,
          builder: (context, snap) {
            final all = snap.data ?? const <ReadyDesign>[];
            final rooms = [for (final r in roomLabels.keys) if (all.any((d) => d.room == r)) r];
            final shown = _room == null ? all : all.where((d) => d.room == _room).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                ScreenHeader(title: 'تصاميم جاهزة', onBack: () => context.pop()),
                const SizedBox(height: 6),
                Text('اختار التصميم اللي بيعجبك، ومنعملك متله بشقتك.', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 14),
                if (rooms.length > 1) ...[
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _RoomChip(label: 'الكل', selected: _room == null, onTap: () => setState(() => _room = null)),
                        for (final r in rooms)
                          _RoomChip(label: roomLabels[r]!, selected: _room == r, onTap: () => setState(() => _room = r)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (shown.isEmpty)
                  showcaseState(
                    snap,
                    onRetry: () => setState(() => _designs = Showcase.instance.designs(refresh: true)),
                    empty: 'قريباً بتطلع هون تصاميم جاهزة للمطابخ والصالونات والحمامات.',
                  )
                else
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final d in shown)
                        ShowcaseCard(
                          imageUrl: d.photos.firstOrNull?.url,
                          title: d.title,
                          subtitle: '${d.roomLabel} · ${d.styleLabel}',
                          onTap: () => context.push('/designs/item', extra: d),
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RoomChip extends StatelessWidget {
  const _RoomChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Material(
        color: selected ? AppColors.primaryTint : AppColors.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.primary : AppColors.line)),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.primaryDark : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DesignPage extends StatelessWidget {
  const DesignPage({super.key, required this.design});

  final ReadyDesign design;

  @override
  Widget build(BuildContext context) {
    final d = design;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                children: [
                  ScreenHeader(title: d.title, onBack: () => context.pop()),
                  const SizedBox(height: 14),
                  PhotoCarousel(photos: d.photos, height: 300),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      InfoChip(d.roomLabel),
                      InfoChip(d.styleLabel),
                      if (d.level != null) InfoChip('مستوى ${d.level!.label}'),
                    ],
                  ),
                  if (d.description != null) ...[
                    const SizedBox(height: 14),
                    Text(d.description!, style: const TextStyle(fontSize: 15, height: 1.7)),
                  ],
                  const SizedBox(height: 14),
                  const NoteRow(
                    icon: Icons.design_services_outlined,
                    text: 'التصميم بيتعدّل على قياسات شقتك ومستوى الإكساء اللي بتختاره، والسعر بيتحدد بعد المعاينة.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
              child: FilledButton(
                onPressed: () => context.push(
                  '/calculator',
                  extra: CalcInput(level: d.level ?? FinishLevel.medium, designId: d.id, designTitle: d.title),
                ),
                child: const Text('بدي متل هاد'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

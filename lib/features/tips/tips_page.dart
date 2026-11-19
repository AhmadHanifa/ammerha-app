import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme.dart';
import '../../data/article.dart';
import '../../data/estimate.dart';
import '../../services/showcase.dart';
import '../../widgets/common.dart';
import '../../widgets/photos.dart';
import '../showcase/gallery_page.dart';

/// "نصايح": what to ask, check and write down, before, during and after.
class TipsPage extends StatefulWidget {
  const TipsPage({super.key});

  @override
  State<TipsPage> createState() => _TipsPageState();
}

class _TipsPageState extends State<TipsPage> {
  late Future<List<Article>> _articles = Showcase.instance.articles();
  String? _category;
  String? _service;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _articles,
      builder: (context, snap) {
        final all = snap.data ?? const <Article>[];
        final shown = [
          for (final a in all)
            if ((_category == null || a.category == _category) && (_service == null || a.service == _service)) a,
        ];
        final categories = [for (final c in articleCategoryLabels.keys) if (all.any((a) => a.category == c)) c];
        final services = [for (final s in Service.values) if (all.any((a) => a.service == s.key)) s];
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          children: [
            const ScreenHeader(title: 'نصايح'),
            const SizedBox(height: 4),
            Text(
              'شو تسأل، شو تفحص، وشو تكتب، لحتى ما حدا يضحك عليك.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            if (categories.length > 1)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _Chip(label: 'الكل', selected: _category == null, onTap: () => setState(() => _category = null)),
                    for (final c in categories)
                      _Chip(
                        label: articleCategoryLabels[c]!,
                        selected: _category == c,
                        onTap: () => setState(() => _category = c),
                      ),
                  ],
                ),
              ),
            if (services.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final s in services)
                      _Chip(
                        label: s.label,
                        icon: s.icon,
                        selected: _service == s.key,
                        onTap: () => setState(() => _service = _service == s.key ? null : s.key),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (shown.isEmpty)
              showcaseState(
                snap,
                onRetry: () => setState(() => _articles = Showcase.instance.articles(refresh: true)),
                empty: 'قريباً بتطلع هون نصايح قبل ما تتفق مع أي معلم.',
              )
            else
              for (final a in shown) ...[_ArticleCard(article: a), const SizedBox(height: 10)],
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

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
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 16, color: AppColors.primaryDark), const SizedBox(width: 6)],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppColors.primaryDark : AppColors.ink,
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

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final a = article;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card + 2),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/tips/item', extra: a),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (a.coverUrl != null) ...[
                SizedBox.square(dimension: 72, child: NetImage(a.coverUrl, radius: 12)),
                const SizedBox(width: 12),
              ] else ...[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(12)),
                  child: Icon(
                    Service.values.where((s) => s.key == a.service).firstOrNull?.icon ?? Icons.lightbulb_outline_rounded,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.categoryLabel, style: const TextStyle(fontSize: 12, color: AppColors.primaryDark)),
                    Text(a.title, style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w600)),
                    if (a.summary != null)
                      Text(
                        a.summary!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (a.checklist.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'قائمة فحص: ${a.checklist.length} نقاط',
                          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                        ),
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

class ArticlePage extends StatefulWidget {
  const ArticlePage({super.key, required this.article});

  final Article article;

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  var _checked = <int>{};

  String get _key => 'tips.checked.${widget.article.id}';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final saved = prefs.getStringList(_key);
      if (saved != null && mounted) setState(() => _checked = {for (final s in saved) ?int.tryParse(s)});
    });
  }

  Future<void> _toggle(int i) async {
    setState(() => _checked.contains(i) ? _checked.remove(i) : _checked.add(i));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, [for (final i in _checked) '$i']);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            ScreenHeader(title: a.categoryLabel, onBack: () => context.pop()),
            const SizedBox(height: 16),
            if (a.coverUrl != null) ...[
              SizedBox(height: 190, child: NetImage(a.coverUrl, radius: AppRadius.cardLarge)),
              const SizedBox(height: 16),
            ],
            Text(a.title, style: const TextStyle(fontSize: 24, height: 1.45, fontWeight: FontWeight.w700)),
            if (a.summary != null) ...[
              const SizedBox(height: 6),
              Text(a.summary!, style: const TextStyle(fontSize: 16, color: AppColors.inkSoft)),
            ],
            const SizedBox(height: 8),
            for (final block in parseArticle(a.body))
              switch (block) {
                HeadingBlock(:final text) => Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 4),
                  child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                ParagraphBlock(:final text) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(text, style: const TextStyle(fontSize: 16, height: 1.8)),
                ),
                BulletsBlock(:final items) => Column(
                  children: [
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: CircleAvatar(radius: 3, backgroundColor: AppColors.primary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(item, style: const TextStyle(fontSize: 16, height: 1.7))),
                          ],
                        ),
                      ),
                  ],
                ),
              },
            if (a.checklist.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Text('قائمة الفحص', style: text.titleMedium)),
                  Text('${_checked.length} من ${a.checklist.length}', style: text.bodySmall),
                ],
              ),
              const SizedBox(height: 6),
              AppCard(
                child: Column(
                  children: [
                    for (final (i, item) in a.checklist.indexed)
                      CheckboxListTile(
                        value: _checked.contains(i),
                        onChanged: (_) => _toggle(i),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primary,
                        title: Text(
                          item,
                          style: TextStyle(
                            fontSize: 15,
                            decoration: _checked.contains(i) ? TextDecoration.lineThrough : null,
                            color: _checked.contains(i) ? AppColors.inkSoft : AppColors.ink,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text('علاماتك بتنحفظ على موبايلك.', style: text.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

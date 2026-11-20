import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/config.dart';
import '../../app/theme.dart';
import '../../data/estimate.dart';
import '../../data/home_file.dart';
import '../../data/providers.dart';
import '../../services/analytics.dart';
import '../../services/customer.dart';
import '../../services/requests_store.dart';
import '../../services/showcase.dart';
import '../../services/whatsapp.dart';
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

  /// Makes a small request with a number, then opens the provider's WhatsApp.
  /// The number is what keeps the job, its review and its warranty in the app.
  Future<void> _contact() async {
    final p = widget.provider;
    final messenger = ScaffoldMessenger.of(context);
    if (!AppConfig.hasBackend) {
      messenger.showSnackBar(const SnackBar(content: Text('بيشتغل بالنسخة الموصولة بالسيرفر.')));
      return;
    }
    final details = await showModalBottomSheet<({String name, String phone, String? note})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ContactSheet(providerName: p.name),
    );
    if (details == null || !mounted) return;
    try {
      await Customer.instance.ensureSignedIn();
      final json = await Supabase.instance.client.rpc(
        'contact_provider',
        params: {
          'p_device_id': await Analytics.instance.ensureDeviceId(),
          'p_provider_id': p.id,
          'p_name': details.name,
          'p_whatsapp': details.phone,
          'p_note': details.note,
        },
      ).timeout(AppConfig.requestTimeout) as Map<String, dynamic>;
      final number = (json['request_no'] as num).toInt();
      if (RequestsStore.instance.items.every((r) => r.number != number)) {
        await RequestsStore.instance.add(
          SavedRequest(
            number: number,
            title: 'تواصل مع ${p.name}',
            size: p.role,
            level: '',
            range: '',
            rangeWords: '',
            createdAt: DateTime.now(),
            kind: 'direct',
          ),
        );
      }
      Analytics.instance.track('provider_contacted', {'provider': p.id, 'request_no': number});
      final opened = await openChat(
        json['provider_phone'] as String,
        [
          'مرحبا ${p.name}، شفت صفحتك على تطبيق عمّرها.',
          'رقم طلبي: $number',
          if (details.note != null) details.note!,
        ].join('\n'),
      );
      if (!opened) {
        messenger.showSnackBar(const SnackBar(content: Text('ما انفتح الواتساب. طلبك محفوظ بـ"طلباتي".')));
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch ('$e') {
            final s when s.contains('too many requests') => 'بعتت طلبات كتير اليوم. جرّب بكرا.',
            final s when s.contains('bad phone') => 'تأكد من رقمك.',
            final s when s.contains('provider unavailable') => 'هالفني مو متاح هلق.',
            _ => 'ما زبط، تأكد من النت وجرّب كمان مرة',
          }),
        ),
      );
    }
  }

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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(onPressed: _ask, child: const Text('احسب واطلب عرض سعر')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _contact,
                      icon: const Icon(Icons.chat_rounded),
                      label: const Text('احكيه عالواتساب'),
                    ),
                  ),
                ],
              ),
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

/// Name and number before talking to a provider; remembered for next time.
class _ContactSheet extends StatefulWidget {
  const _ContactSheet({required this.providerName});

  final String providerName;

  @override
  State<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<_ContactSheet> {
  static const _nameKey = 'customer.name';
  static const _phoneKey = 'customer.phone';

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      _name.text = prefs.getString(_nameKey) ?? '';
      _phone.text = prefs.getString(_phoneKey) ?? '';
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (!_form.currentState!.validate()) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, _name.text.trim());
    await prefs.setString(_phoneKey, _phone.text.trim());
    if (mounted) {
      Navigator.pop(context, (
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('قبل ما تحكي ${widget.providerName}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'بيصير لطلبك رقم، فبيضل الشغل محفوظ بملف بيتك، وبتقدر تقيّمه وتستفيد من الضمان.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(hintText: 'اسمك'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'لازم تعبّي هالحقل' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(hintText: 'رقم الواتساب تبعك'),
                validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length < 9 ? 'تأكد من الرقم' : null,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'شو بدك؟ (اختياري)'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: _go, icon: const Icon(Icons.chat_rounded), label: const Text('افتح الواتساب')),
            ],
          ),
        ),
      ),
    );
  }
}

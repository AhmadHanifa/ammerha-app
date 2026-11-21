import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/estimate.dart';
import '../../services/analytics.dart';
import '../../services/estimates.dart';
import '../../services/partner.dart';
import '../../services/push.dart';
import '../../widgets/common.dart';
import '../../widgets/states.dart';

/// What the quote screen needs from the result.
class QuoteArgs {
  const QuoteArgs(this.input, this.estimate);

  final CalcInput input;
  final Estimate estimate;
}

class ResultPage extends StatefulWidget {
  const ResultPage({super.key, required this.input});

  final CalcInput input;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late Future<Estimate> _estimate = fetchEstimate(widget.input)..then((_) => Push.instance.askOnce(), onError: (_) {});

  void _retry() => setState(() => _estimate = fetchEstimate(widget.input));

  /// Adds the companion service; asks for rooms first when it now needs them.
  void _addCompanion(Service service) {
    final input = widget.input;
    final next = input.copyWith(services: {...input.services, service});
    Analytics.instance.track('upsell_taken', {'service': service.key});
    if (next.needsRooms && !input.needsRooms) {
      context.pushReplacement('/calculator', extra: next);
    } else {
      context.pushReplacement('/result', extra: next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final input = widget.input;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: _estimate,
          builder: (context, snapshot) {
            final estimate = snapshot.data;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    children: [
                      ScreenHeader(title: 'قديش بدها؟', onBack: () => context.pop()),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          InfoChip(input.title),
                          InfoChip('${input.area} م²'),
                          if (input.needsRooms) InfoChip('${input.rooms} غرف · ${input.baths} حمام'),
                          InfoChip('مستوى ${input.level.label}'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppCard(
                        radius: AppRadius.cardLarge,
                        padding: const EdgeInsets.all(18),
                        child: switch (snapshot.connectionState) {
                          ConnectionState.done when estimate != null => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                input.isFull ? 'الكلفة التقريبية لإكساء شقتك' : 'الكلفة التقريبية لـ${input.title}',
                                style: text.bodySmall,
                              ),
                              Text(
                                estimate.range,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(fontSize: 30, height: 1.35, fontWeight: FontWeight.w700),
                              ),
                              Text('مواد وشغل، بالدولار', style: text.bodySmall),
                            ],
                          ),
                          ConnectionState.done => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ما قدرنا نحسب هلق', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('تأكد من النت وجرّب كمان مرة.', style: text.bodySmall),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: _retry,
                                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                                child: const Text('جرّب كمان مرة'),
                              ),
                            ],
                          ),
                          _ => const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Skeleton(width: 170, height: 14),
                              SizedBox(height: 12),
                              Skeleton(width: 230, height: 30),
                              SizedBox(height: 10),
                              Skeleton(width: 120, height: 12),
                            ],
                          ),
                        },
                      ),
                      if (estimate != null && estimate.parts.length > 1) ...[
                        const SizedBox(height: 14),
                        _Parts(parts: estimate.parts),
                      ],
                      if (estimate != null) ...[
                        const SizedBox(height: 12),
                        const _Included(),
                        const SizedBox(height: 12),
                        ValueListenableBuilder(
                          valueListenable: Partner.instance.sponsorName,
                          builder: (context, sponsor, _) => NoteRow(
                            icon: Icons.info_outline_rounded,
                            text: 'هاد سعر تقريبي. السعر النهائي بيحدده فريق $sponsor بعد المعاينة.',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Material(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          child: InkWell(
                            onTap: () => context.go('/?tab=tips'),
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.lightbulb_outline_rounded, color: AppColors.primaryDark, size: 20),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'قبل ما تتفق مع أي معلم: شو تسأل وشو تكتب بالعقد',
                                      style: TextStyle(fontSize: 14, color: AppColors.primaryDark),
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_rounded, color: AppColors.primaryDark, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (estimate.smallJob case final small?) ...[
                          const SizedBox(height: 10),
                          NoteRow(
                            icon: Icons.receipt_long_outlined,
                            text: small.minOrder
                                ? 'الحد الأدنى للطلب ${groupDigits('${small.amount}')} دولار.'
                                : 'في رسم معاينة ${groupDigits('${small.amount}')} دولار، بينخصم من العقد إذا اتفقتوا.',
                          ),
                        ],
                        if (!input.isFull &&
                            estimate.bundleDiscount > 0 &&
                            !input.services.contains(input.orderedServices.first.companion)) ...[
                          const SizedBox(height: 16),
                          _UpsellCard(
                            service: input.orderedServices.first.companion,
                            discount: estimate.bundleDiscount,
                            onAdd: () => _addCompanion(input.orderedServices.first.companion),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
                  child: FilledButton(
                    onPressed: estimate == null ? null : () => context.push('/quote', extra: QuoteArgs(input, estimate)),
                    child: const Text('اطلب عرض سعر'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// "ضيف البلاط كمان بسعر أحسن".
class _UpsellCard extends StatelessWidget {
  const _UpsellCard({required this.service, required this.discount, required this.onAdd});

  final Service service;
  final num discount;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(AppRadius.card + 2)),
      child: Row(
        children: [
          Icon(service.icon, color: AppColors.primaryDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ضيف ${service.definite} كمان بسعر أحسن',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  'خصم ${formatPercent(discount)}% على الخدمتين سوا',
                  style: const TextStyle(fontSize: 13, color: AppColors.primaryDark),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onAdd, child: const Text('ضيف')),
        ],
      ),
    );
  }
}

/// What each part of the work takes, as bars: no unit prices.
class _Parts extends StatelessWidget {
  const _Parts({required this.parts});

  final List<({String label, int share})> parts;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('وين بتروح الكلفة تقريباً', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final part in parts) ...[
            Row(
              children: [
                Expanded(child: Text(part.label, style: const TextStyle(fontSize: 15))),
                Text('${part.share}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: part.share / 100,
                minHeight: 8,
                backgroundColor: AppColors.lineSoft,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// What the range covers, and what it does not.
class _Included extends StatelessWidget {
  const _Included();

  @override
  Widget build(BuildContext context) {
    Widget line(IconData icon, Color color, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.6))),
        ],
      ),
    );
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('شو داخل بالسعر', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          line(Icons.check_circle_outline_rounded, AppColors.primary, 'المواد والشغل بالمستوى اللي اخترته.'),
          line(Icons.check_circle_outline_rounded, AppColors.primary, 'التركيب والتشطيب لكل قسم بالشريط فوق.'),
          line(Icons.remove_circle_outline_rounded, AppColors.inkSoft, 'الأثاث والأجهزة الكهربائية مو داخلين.'),
          line(Icons.remove_circle_outline_rounded, AppColors.inkSoft, 'أي شغل إضافي بيبيّن بالمعاينة بيتسعّر لحاله.'),
        ],
      ),
    );
  }
}

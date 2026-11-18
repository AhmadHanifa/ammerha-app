import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/estimate.dart';
import '../../services/partner.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/common.dart';

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
              const SizedBox(width: 12),
              const Expanded(
                child: Align(alignment: AlignmentDirectional.centerEnd, child: SponsorBadge()),
              ),
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
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/estimate.dart';
import '../../services/partner.dart';
import '../../widgets/common.dart';

/// «عمّرها وإنت برّا»: for owners abroad who renovate their home in Syria
/// and follow every stage from where they are.
class AbroadPage extends StatelessWidget {
  const AbroadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Partner.instance.sponsorName,
                builder: (context, sponsor, _) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  children: [
                    ScreenHeader(title: 'عمّرها وإنت برّا', onBack: () => context.pop()),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 28),
                          SizedBox(height: 10),
                          Text(
                            'عمّر بيتك بسوريا وإنت بمكانك',
                            style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'شوف كل مرحلة بعينك، ووافق عليها قبل ما تدفع اللي بعدها.',
                            style: TextStyle(color: AppColors.primaryTint, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('شلون بتمشي؟', style: text.titleMedium),
                    const SizedBox(height: 8),
                    for (final (i, (icon, title, body)) in [
                      (Icons.photo_camera_outlined, 'سعر من الصور', 'إنت أو قريبك بحلب بتصوّروا الشقة، وبتوصلك كلفة تقريبية قبل المعاينة.'),
                      (Icons.view_timeline_outlined, 'عقد على مراحل', 'الشغل بينقسم مراحل: تمديدات، جبصين، بلاط، دهان… ولكل مرحلة دفعتها.'),
                      (Icons.verified_outlined, 'صور كل مرحلة وموافقتك', 'فريق $sponsor بيرفع الصور، وإنت بتوافق أو بتطلب تعديل من التطبيق.'),
                      (Icons.cable_outlined, 'خريطة التمديدات وتأكيد المواد', 'بتشوف وين مرّت المي والكهربا قبل ما تتسكّر، وبتأكد ماركة المواد لما توصل.'),
                      (Icons.workspace_premium_outlined, 'شقة موثّقة', 'بالآخر بيصير عندك ملف البيت كامل، وشهادة «شقة موثّقة من عمّرها» مع الضمان.'),
                    ].indexed) ...[
                      _StepTile(number: i + 1, icon: icon, title: title, body: body),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: () => context.push('/calculator', extra: const CalcInput(remote: true)),
                    child: const Text('ابدأ: احسب كلفة بيتك'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => context.push('/inspection', extra: true),
                    child: const Text('بدي افحص شقة قبل ما اشتريها'),
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

class _StepTile extends StatelessWidget {
  const _StepTile({required this.number, required this.icon, required this.title, required this.body});

  final int number;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primaryDark, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$number. $title', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

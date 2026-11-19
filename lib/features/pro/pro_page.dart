import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/home_file.dart';
import '../../data/pro.dart';
import '../../services/pro.dart';
import '../../widgets/common.dart';

/// The provider's space: the jobs the team sent them.
class ProPage extends StatefulWidget {
  const ProPage({super.key});

  @override
  State<ProPage> createState() => _ProPageState();
}

class _ProPageState extends State<ProPage> {
  late Future<List<JobSummary>> _jobs = Pro.jobs();

  void _back() => context.canPop() ? context.pop() : context.go('/');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() => _jobs = Pro.jobs()),
          child: FutureBuilder(
            future: _jobs,
            builder: (context, snap) {
              final jobs = snap.data ?? const <JobSummary>[];
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  ScreenHeader(title: 'شغلاتي', onBack: _back),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => context.push('/join'),
                      icon: const Icon(Icons.person_outline_rounded, size: 18),
                      label: const Text('ملفي'),
                    ),
                  ),
                  if (snap.connectionState != ConnectionState.done)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    )
                  else if (snap.hasError)
                    const NoteRow(
                      icon: Icons.cloud_off_rounded,
                      text: 'ما قدرنا نجيب شغلاتك. إذا ملفك لسا عند الفريق، بتطلع شغلاتك هون بعد الموافقة.',
                    )
                  else if (jobs.isEmpty)
                    const NoteRow(
                      icon: Icons.work_outline_rounded,
                      text: 'لسا ما في شغلات. لما زبون يطلب منك أو يبعتلك الفريق شغلة، بتطلع هون وبيوصلك إشعار.',
                    )
                  else
                    for (final j in jobs) ...[_JobTile(job: j), const SizedBox(height: 10)],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  const _JobTile({required this.job});

  final JobSummary job;

  @override
  Widget build(BuildContext context) {
    final j = job;
    final status = RequestSummary(number: j.number, kind: j.kind, status: j.status).statusLabel;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card + 2),
        side: BorderSide(color: j.openClaims > 0 ? AppColors.priceUp : AppColors.line),
      ),
      child: InkWell(
        onTap: () => context.push('/pro/job/${j.number}'),
        borderRadius: BorderRadius.circular(AppRadius.card + 2),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Pill(label: 'طلب ${j.number}', background: AppColors.primaryTint, foreground: AppColors.primaryDark),
                  const SizedBox(width: 6),
                  Pill(label: status, background: AppColors.freshBg, foreground: AppColors.freshFg),
                  const Spacer(),
                  Text(shortDate(j.createdAt), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 6),
              Text('${j.title} · ${j.customer}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(
                [if (j.area != null) '${j.area} م²', if (j.place != null) j.place!, '${j.stages} مراحل'].join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (j.openClaims > 0)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('في بلاغ ضمان مفتوح', style: TextStyle(fontSize: 13, color: AppColors.priceUp)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

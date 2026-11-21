import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/config.dart';

import '../../app/theme.dart';
import '../../data/estimate.dart';
import '../../services/partner.dart';
import '../../services/requests_store.dart';
import '../../services/whatsapp.dart';
import '../../widgets/common.dart';
import '../../widgets/states.dart';

/// "طلباتي": the requests sent from this phone, each with its number.
class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  @override
  void initState() {
    super.initState();
    RequestsStore.instance.refreshStatuses();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RequestsStore.instance,
      builder: (context, _) {
        final items = RequestsStore.instance.items;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          children: [
            const ScreenHeader(title: 'طلباتي'),
            const SizedBox(height: 18),
            if (items.isEmpty)
              const _Empty()
            else
              for (final request in items) ...[_RequestCard(request: request), const SizedBox(height: 12)],
          ],
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final SavedRequest request;

  @override
  Widget build(BuildContext context) {
    final summary = RequestsStore.instance.summaryOf(request.number);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card + 2),
        side: BorderSide(color: (summary?.waiting ?? 0) > 0 ? AppColors.primary : AppColors.line),
      ),
      child: InkWell(
        onTap: AppConfig.hasBackend ? () => context.push('/request/${request.number}') : null,
        borderRadius: BorderRadius.circular(AppRadius.card + 2),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Pill(
                    label: 'طلب ${request.number}',
                    background: AppColors.primaryTint,
                    foreground: AppColors.primaryDark,
                  ),
                  if (summary != null) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Pill(
                        label: summary.statusLabel,
                        background: AppColors.freshBg,
                        foreground: AppColors.freshFg,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(request.dateLabel, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 8),
              Text(request.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(
                [request.size, request.level].where((t) => t.isNotEmpty).join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (request.range.isNotEmpty)
                Text(
                  request.range,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              if (summary != null &&
                  (summary.waiting > 0 || summary.report || summary.certificate || summary.stages > 0)) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (summary.waiting > 0)
                      Pill(
                        label: 'بانتظار موافقتك (${summary.waiting})',
                        background: AppColors.primary,
                        foreground: Colors.white,
                      ),
                    if (summary.stages > 0 && summary.waiting == 0)
                      const Pill(
                        label: 'ملف البيت',
                        background: AppColors.primaryTint,
                        foreground: AppColors.primaryDark,
                      ),
                    if (summary.report)
                      const Pill(
                        label: 'تقرير الفحص جاهز',
                        background: AppColors.primaryTint,
                        foreground: AppColors.primaryDark,
                      ),
                    if (summary.certificate)
                      const Pill(
                        label: 'شقة موثّقة',
                        background: AppColors.primaryTint,
                        foreground: AppColors.primaryDark,
                      ),
                  ],
                ),
              ],
              if (Partner.instance.whatsappNumber.isNotEmpty) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final opened = await openWhatsApp(request);
                    if (!opened && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ما انفتح الواتساب. تأكد إنو مثبّت وجرّب كمان مرة.')),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: const Text('احكي معنا عالواتساب'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => EmptyState(
    title: 'لسا ما بعتت طلبات',
    body: 'احسب كلفة شقتك أو احكي فني، وبيطلع طلبك هون مع رقمه.',
    action: 'احسب الكلفة',
    onAction: () => context.push('/calculator', extra: const CalcInput()),
  );
}

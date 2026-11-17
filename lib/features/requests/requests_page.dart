import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/estimate.dart';
import '../../services/partner.dart';
import '../../services/requests_store.dart';
import '../../services/whatsapp.dart';
import '../../widgets/common.dart';

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
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pill(label: 'طلب ${request.number}', background: AppColors.primaryTint, foreground: AppColors.primaryDark),
              if (RequestsStore.instance.statusOf(request.number) case final status?) ...[
                const SizedBox(width: 6),
                Pill(label: status.label, background: AppColors.freshBg, foreground: AppColors.freshFg),
              ],
              const Spacer(),
              Text(request.dateLabel, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(request.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text('${request.size} · ${request.level}', style: Theme.of(context).textTheme.bodySmall),
          Text(
            request.range,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
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
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: AppColors.inkSoft),
          const SizedBox(height: 12),
          Text('لسا ما بعتت طلبات', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'احسب كلفة شقتك واطلب عرض سعر، وبيطلع طلبك هون مع رقمه.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push('/calculator', extra: const CalcInput()),
            style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
            child: const Text('احسب الكلفة'),
          ),
        ],
      ),
    );
  }
}

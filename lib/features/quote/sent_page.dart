import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../services/analytics.dart';
import '../../services/partner.dart';
import '../../services/push.dart';
import '../../services/requests_store.dart';
import '../../services/whatsapp.dart';
import '../../widgets/common.dart';

/// The request number, then straight to the shared WhatsApp chat.
class SentPage extends StatefulWidget {
  const SentPage({super.key, required this.request});

  final SavedRequest request;

  @override
  State<SentPage> createState() => _SentPageState();
}

class _SentPageState extends State<SentPage> {
  Timer? _autoOpen;

  bool get _hasNumber => Partner.instance.whatsappNumber.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // A moment to read the number before WhatsApp takes over.
    // Ask about notifications first; WhatsApp opens after the answer.
    unawaited(_askThenOpen());
  }

  Future<void> _askThenOpen() async {
    await Push.instance.askOnce();
    if (!mounted || !_hasNumber) return;
    // A moment to read the number before WhatsApp takes over.
    _autoOpen = Timer(const Duration(milliseconds: 1200), _open);
  }

  @override
  void dispose() {
    _autoOpen?.cancel();
    super.dispose();
  }

  Future<void> _open() async {
    _autoOpen?.cancel();
    final opened = await openWhatsApp(widget.request);
    Analytics.instance.track('whatsapp_opened', {'request_no': widget.request.number, 'ok': opened});
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ما انفتح الواتساب. تأكد إنو مثبّت وجرّب كمان مرة.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                children: [
                  const SizedBox(height: 28),
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, size: 40, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('انبعت طلبك', textAlign: TextAlign.center, style: text.headlineSmall),
                  const SizedBox(height: 14),
                  AppCard(
                    radius: AppRadius.cardLarge,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                    child: Column(
                      children: [
                        Text('رقم طلبك', style: text.bodySmall),
                        Text(
                          '${request.number}',
                          style: const TextStyle(fontSize: 44, height: 1.25, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(request.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        Text(
                          [request.size, request.level].where((t) => t.isNotEmpty).join(' · '),
                          style: text.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        if (request.range.isNotEmpty)
                          Text(
                            request.range,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder(
                    valueListenable: Partner.instance.sponsorName,
                    builder: (context, sponsor, _) => NoteRow(
                      icon: Icons.chat_outlined,
                      text: _hasNumber
                          ? 'عم نفتحلك الواتساب على رقم الشغل، والرسالة جاهزة فيها رقم طلبك. ابعتها، وفريق $sponsor '
                                'بيحكي معك ليحدد موعد المعاينة.'
                          : 'رح يتواصل معك فريق $sponsor عالواتساب ليحدد موعد المعاينة. احتفظ برقم طلبك.',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_hasNumber) ...[
                    FilledButton.icon(
                      onPressed: _open,
                      icon: const Icon(Icons.chat_rounded),
                      label: const Text('افتح الواتساب'),
                    ),
                    const SizedBox(height: 10),
                  ],
                  OutlinedButton(onPressed: () => context.go('/'), child: const Text('رجوع للرئيسية')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

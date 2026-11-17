import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/config.dart';
import '../../app/theme.dart';
import '../../data/estimate.dart';
import '../../services/analytics.dart';
import '../../services/partner.dart';
import '../../services/requests_store.dart';
import '../../widgets/common.dart';
import '../calculator/result_page.dart';

class QuotePage extends StatefulWidget {
  const QuotePage({super.key, required this.args});

  final QuoteArgs args;

  @override
  State<QuotePage> createState() => _QuotePageState();
}

class _QuotePageState extends State<QuotePage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _area = TextEditingController();
  final _notes = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _area, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final input = widget.args.input;
    setState(() => _sending = true);
    try {
      int number;
      var estimate = widget.args.estimate;
      if (AppConfig.hasBackend) {
        final json = await Supabase.instance.client.rpc(
          'submit_quote',
          params: {
            'p_device_id': await Analytics.instance.ensureDeviceId(),
            'p_name': _name.text,
            'p_whatsapp': _phone.text,
            'p_area_text': _area.text,
            'p_notes': _notes.text,
            ...input.rpcParams,
          },
        ).timeout(AppConfig.requestTimeout) as Map<String, dynamic>;
        Partner.instance.apply(json);
        number = (json['request_no'] as num).toInt();
        // The server prices it again; its numbers are the ones on the request.
        estimate = Estimate.fromJson(json);
      } else {
        number = RequestsStore.instance.nextDemoNumber;
      }
      final request = SavedRequest(
        number: number,
        title: input.title,
        size: input.sizeLabel,
        level: input.level.label,
        range: estimate.range,
        rangeWords: estimate.rangeWords,
        createdAt: DateTime.now(),
      );
      await RequestsStore.instance.add(request);
      Analytics.instance.track('quote_submitted', {'request_no': number, 'kind': input.kind.name});
      if (!mounted) return;
      context.go('/sent', extra: request);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '$e'.contains('too many requests')
                ? 'بعتت طلبات كتير اليوم. جرّب بكرا، أو احكينا عالواتساب.'
                : '$e'.contains('bad phone')
                ? 'تأكد من رقم الواتساب.'
                : '$e'.contains('busy, try later')
                ? 'في ضغط هلق، جرّب بعد شوي.'
                : 'ما زبط الإرسال، تأكد من النت وجرّب كمان مرة',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final input = widget.args.input;

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  children: [
                    ScreenHeader(title: 'اطلب عرض سعر', onBack: () => context.pop()),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('طلبك', style: TextStyle(fontSize: 13, color: AppColors.primaryDark)),
                                Text(input.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                Text(
                                  '${input.sizeLabel} · ${input.level.label}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            widget.args.estimate.range,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Field(label: 'الاسم', hint: 'أبو محمد', controller: _name, required: true),
                    _Field(label: 'رقم الواتساب', hint: '09xx xxx xxx', controller: _phone, phone: true, required: true),
                    _Field(label: 'المنطقة', hint: 'حلب، الشهباء', controller: _area),
                    _Field(
                      label: 'ملاحظات (اختياري)',
                      hint: 'بدي المطبخ ألمنيوم، والحمامات سيراميك تركي',
                      controller: _notes,
                      lines: 3,
                    ),
                    ValueListenableBuilder(
                      valueListenable: Partner.instance.sponsorName,
                      builder: (context, sponsor, _) => NoteRow(
                        icon: Icons.verified_user_outlined,
                        text: 'بيوصل طلبك لفريق $sponsor مع رقم خاص فيه، وبيتواصلوا معك عالواتساب لتحددوا موعد المعاينة. '
                            'رقمك ما بيوصل لحدا غيرهن.',
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
                child: FilledButton(onPressed: _sending ? null : _submit, child: Text(_sending ? 'عم نبعت…' : 'ابعت الطلب')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.phone = false,
    this.lines = 1,
    this.required = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool phone;
  final int lines;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: phone ? TextInputType.phone : TextInputType.text,
            textDirection: phone ? TextDirection.ltr : null,
            textAlign: phone ? TextAlign.right : TextAlign.start,
            minLines: lines,
            maxLines: lines,
            decoration: InputDecoration(hintText: hint),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (required && value.isEmpty) return 'لازم تعبّي هالحقل';
              if (phone && value.replaceAll(RegExp(r'\D'), '').length < 9) return 'تأكد من الرقم';
              return null;
            },
          ),
        ],
      ),
    );
  }
}

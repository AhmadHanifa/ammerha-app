import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/config.dart';
import '../../app/theme.dart';
import '../../data/estimate.dart';
import '../../services/analytics.dart';
import '../../services/customer.dart';
import '../../services/home_files.dart';
import '../../services/partner.dart';
import '../../services/requests_store.dart';
import '../../widgets/common.dart';
import '../../widgets/photos.dart';
import '../../widgets/request_extras.dart';

/// فحص الشقة قبل ما تشتريها: the buyer asks, سنديان inspects and writes a
/// report of the problems and what fixing them costs.
class InspectionPage extends StatefulWidget {
  const InspectionPage({super.key, this.remote = false});

  final bool remote;

  @override
  State<InspectionPage> createState() => _InspectionPageState();
}

class _InspectionPageState extends State<InspectionPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _area = TextEditingController();
  final _age = TextEditingController();
  final _notes = TextEditingController();
  final _country = TextEditingController();
  final _agency = TextEditingController();
  late var _remote = widget.remote;
  var _photos = <XFile>[];
  var _sending = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      if (_name.text.isEmpty) _name.text = prefs.getString('customer.name') ?? '';
      if (_phone.text.isEmpty) _phone.text = prefs.getString('customer.phone') ?? '';
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _location, _area, _age, _notes, _country, _agency]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      final area = num.tryParse(_area.text.trim());
      int number;
      String? requestId;
      if (AppConfig.hasBackend) {
        await Customer.instance.ensureSignedIn();
        final json = await Supabase.instance.client.rpc(
          'submit_inspection',
          params: {
            'p_device_id': await Analytics.instance.ensureDeviceId(),
            'p_name': _name.text,
            'p_whatsapp': _phone.text,
            'p_area_text': _location.text,
            'p_notes': _notes.text,
            'p_area': area,
            'p_building_age': int.tryParse(_age.text.trim()),
            'p_remote': _remote,
            'p_country': _remote ? _country.text : null,
            'p_agency_code': _agency.text.trim().isEmpty ? null : _agency.text.trim(),
          },
        ).timeout(AppConfig.requestTimeout) as Map<String, dynamic>;
        Partner.instance.apply(json);
        number = (json['request_no'] as num).toInt();
        requestId = json['request_id'] as String?;
      } else {
        number = RequestsStore.instance.nextDemoNumber;
      }
      if (requestId != null && _photos.isNotEmpty) {
        await HomeFiles.uploadIntake(requestId: requestId, number: number, photos: _photos);
      }
      final request = SavedRequest(
        number: number,
        title: 'فحص شقة قبل الشراء',
        size: [_location.text.trim(), if (area != null) '$area م²'].join(' · '),
        level: '',
        range: '',
        rangeWords: '',
        createdAt: DateTime.now(),
        kind: 'inspection',
      );
      await RequestsStore.instance.add(request);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customer.name', _name.text.trim());
      await prefs.setString('customer.phone', _phone.text.trim());
      Analytics.instance.track('inspection_submitted', {'request_no': number, 'remote': _remote});
      if (!mounted) return;
      context.go('/sent', extra: request);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch ('$e') {
            final s when s.contains('too many requests') => 'بعتت طلبات كتير اليوم. جرّب بكرا، أو احكينا عالواتساب.',
            final s when s.contains('bad phone') => 'تأكد من رقم الواتساب.',
            final s when s.contains('busy, try later') => 'في ضغط هلق، جرّب بعد شوي.',
            _ => 'ما زبط الإرسال، تأكد من النت وجرّب كمان مرة',
          }),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fee = Partner.instance.inspectionFee;
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
                    ScreenHeader(title: 'افحص الشقة قبل ما تشتريها', onBack: () => context.pop()),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(16)),
                      child: ValueListenableBuilder(
                        valueListenable: Partner.instance.sponsorName,
                        builder: (context, sponsor, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'فريق $sponsor بيفحص الشقة قبل ما تدفع حقها',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'رطوبة، تشققات، تمديدات قديمة… وبيوصلك تقرير بالتطبيق فيه كل مشكلة وكلفة تصليحها التقريبية. '
                              'فيك تفاوض فيه عالسعر.',
                              style: TextStyle(fontSize: 14, color: AppColors.primaryDark),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Field(label: 'وين الشقة؟', hint: 'حلب، الفرقان، قرب دوار الصخرة', controller: _location, required: true),
                    Row(
                      children: [
                        Expanded(child: _Field(label: 'المساحة (اختياري)', hint: '100', controller: _area, number: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _Field(label: 'عمر البناء بالسنين', hint: '30', controller: _age, number: true)),
                      ],
                    ),
                    _Field(label: 'الاسم', hint: 'أبو محمد', controller: _name, required: true),
                    _Field(label: 'رقم الواتساب', hint: '09xx xxx xxx', controller: _phone, phone: true, required: true),
                    _Field(label: 'شي لازم نعرفه؟ (اختياري)', hint: 'الشقة طابق رابع، والسطح فيه نش', controller: _notes, lines: 2),
                    AbroadField(remote: _remote, onChanged: (v) => setState(() => _remote = v), country: _country),
                    const SizedBox(height: 4),
                    AgencyCodeField(controller: _agency),
                    const SizedBox(height: 16),
                    PhotoPickerField(
                      photos: _photos,
                      onChanged: (p) => setState(() => _photos = p),
                      hint: 'صور الشقة إذا عندك (اختياري)، بتساعد الفريق يجهّز للفحص.',
                    ),
                    const SizedBox(height: 16),
                    NoteRow(
                      icon: Icons.receipt_long_outlined,
                      text: fee > 0
                          ? 'رسم الفحص ${groupDigits('${fee.round()}')} دولار، وبينخصم من العقد إذا كمّلت الإكساء مع الفريق.'
                          : 'الفريق بيحكي معك عالواتساب عن موعد الفحص ورسمه.',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
                child: FilledButton(
                  onPressed: _sending ? null : _submit,
                  child: Text(_sending ? 'عم نبعت…' : 'اطلب الفحص'),
                ),
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
    this.number = false,
    this.lines = 1,
    this.required = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool phone;
  final bool number;
  final int lines;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final ltr = phone || number;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: phone ? TextInputType.phone : (number ? TextInputType.number : TextInputType.text),
            textDirection: ltr ? TextDirection.ltr : null,
            textAlign: ltr ? TextAlign.right : TextAlign.start,
            minLines: lines,
            maxLines: lines,
            decoration: InputDecoration(hintText: hint),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (required && value.isEmpty) return 'لازم تعبّي هالحقل';
              if (phone && value.replaceAll(RegExp(r'\D'), '').length < 9) return 'تأكد من الرقم';
              if (number && value.isNotEmpty && num.tryParse(value) == null) return 'اكتب رقم';
              return null;
            },
          ),
        ],
      ),
    );
  }
}

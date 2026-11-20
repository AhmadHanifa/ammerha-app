import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/config.dart';
import '../../app/theme.dart';
import '../../data/estimate.dart';
import '../../data/pro.dart';
import '../../data/providers.dart';
import '../../services/analytics.dart';
import '../../services/pro.dart';
import '../../widgets/common.dart';
import '../../widgets/photos.dart';
import '../../widgets/rating.dart';

/// "انضم لعمّرها": technicians sign up with their phone; engineers also with
/// their syndicate number and graduation certificate. Free for now.
/// Once approved, the same page leads to the provider's space.
class JoinPage extends StatefulWidget {
  const JoinPage({super.key});

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  late Future<MyProfile?> _me = Pro.me();
  var _editing = false;

  void _reload() => setState(() {
    _editing = false;
    _me = Pro.me();
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: _me,
          builder: (context, snap) {
            final me = snap.data;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                ScreenHeader(title: me == null ? 'انضم لعمّرها' : 'ملفي كـ${me.kindLabel}', onBack: () => context.pop()),
                const SizedBox(height: 16),
                if (!AppConfig.hasBackend)
                  const NoteRow(icon: Icons.info_outline_rounded, text: 'التسجيل بيشتغل بالنسخة الموصولة بالسيرفر.')
                else if (snap.connectionState != ConnectionState.done)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                else if (snap.hasError)
                  Column(
                    children: [
                      const NoteRow(icon: Icons.cloud_off_rounded, text: 'ما قدرنا نفتح ملفك. تأكد من النت وجرّب كمان مرة.'),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _reload, child: const Text('جرّب كمان مرة')),
                    ],
                  )
                else if (me == null || _editing)
                  _SignUpForm(current: me, onDone: _reload)
                else
                  _Status(me: me, onEdit: () => setState(() => _editing = true)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Status extends StatefulWidget {
  const _Status({required this.me, required this.onEdit});

  final MyProfile me;
  final VoidCallback onEdit;

  @override
  State<_Status> createState() => _StatusState();
}

class _StatusState extends State<_Status> {
  late MyProfile me = widget.me;
  var _busy = false;

  Future<void> _refresh() async {
    final fresh = await Pro.me();
    if (fresh != null && mounted) setState(() => me = fresh);
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
      await _refresh();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('ما ارتفعت، تأكد من النت وجرّب كمان مرة')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (picked == null) return;
    await _run(() => Pro.uploadPhoto(me.id, picked), 'تبدّلت صورتك');
  }

  Future<void> _addWork() async {
    final picked = await ImagePicker().pickMultiImage(maxWidth: 1600, imageQuality: 80, limit: 10);
    if (picked.isEmpty) return;
    await _run(() => Pro.addWorkPhotos(me.id, picked), 'انضافت الصور لصفحتك');
  }

  @override
  Widget build(BuildContext context) {
    final onEdit = widget.onEdit;
    final (title, body, icon) = switch (me.status) {
      'approved' => ('ملفك ظاهر للزباين', 'كل شغل بيوصلك عن طريق التطبيق بيرفع تقييمك وعدد شغلاتك الموثّقة.', Icons.verified_rounded),
      'rejected' => ('في شي ناقص بطلبك', me.reviewNote ?? 'عدّل ملفك وابعته كمان مرة.', Icons.error_outline_rounded),
      'suspended' => ('ملفك موقّف', me.reviewNote ?? 'تواصل مع فريق عمّرها.', Icons.block_rounded),
      _ => ('طلبك عند الفريق', 'رح نتواصل معك عالرقم اللي كتبته لنتأكد منك، وبعدها بيصير ملفك ظاهر.', Icons.hourglass_top_rounded),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _busy ? null : _changePhoto,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ProviderAvatar(name: me.name, url: me.photoUrl, size: 64, verified: me.verified),
                  const Positioned(
                    bottom: -2,
                    right: -2,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.photo_camera_outlined, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(me.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  Text(
                    [me.specialty ?? me.kindLabel, if (me.area != null) me.area!].join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: me.approved ? AppColors.primaryTint : AppColors.freshBg,
            borderRadius: BorderRadius.circular(AppRadius.card + 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: me.approved ? AppColors.primaryDark : AppColors.freshFg),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(body, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Text('صور من شغلك', style: Theme.of(context).textTheme.titleMedium)),
            TextButton.icon(
              onPressed: _busy ? null : _addWork,
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text('ضيف'),
            ),
          ],
        ),
        Text('بتطلع بصفحتك للزباين. صوّر شغل حقيقي عملته.', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        if (me.photos.isEmpty)
          const NoteRow(icon: Icons.photo_library_outlined, text: 'لسا ما ضفت صور. الصفحة اللي فيها صور بتجيب طلبات أكتر.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in me.photos)
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () => showPhotos(context, [for (final x in me.photos) x.url], initial: me.photos.indexOf(p)),
                      child: SizedBox.square(dimension: 84, child: NetImage(p.url, radius: 12)),
                    ),
                    Positioned(
                      top: 2,
                      left: 2,
                      child: InkWell(
                        onTap: _busy ? null : () => _run(() => Pro.removeWorkPhoto(p.id), 'انشالت الصورة'),
                        child: const CircleAvatar(
                          radius: 11,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        if (me.approved) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push('/pro'),
            icon: const Icon(Icons.work_outline_rounded),
            label: const Text('شغلاتي'),
          ),
        ],
        const SizedBox(height: 10),
        OutlinedButton(onPressed: onEdit, child: const Text('عدّل ملفي')),
      ],
    );
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm({required this.onDone, this.current});

  final MyProfile? current;
  final VoidCallback onDone;

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _form = GlobalKey<FormState>();
  late String _kind = widget.current?.kind ?? 'technician';
  late final _name = TextEditingController(text: widget.current?.name);
  late final _phone = TextEditingController(text: widget.current?.phone);
  late final _specialty = TextEditingController(text: widget.current?.specialty);
  late final _area = TextEditingController(text: widget.current?.area);
  late final _years = TextEditingController(text: widget.current?.years?.toString());
  late final _bio = TextEditingController(text: widget.current?.bio);
  late final _syndicate = TextEditingController(text: widget.current?.syndicateNo);
  late final Set<String> _services = {...?widget.current?.services};
  final _code = TextEditingController();
  var _photo = <XFile>[];
  var _certificate = <XFile>[];
  var _busy = false;

  bool get _engineer => _kind == 'engineer';

  @override
  void dispose() {
    for (final c in [_name, _phone, _specialty, _area, _years, _bio, _syndicate, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  void _say(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    if (_engineer && _certificate.isEmpty && !(widget.current?.hasCertificate ?? false)) {
      _say('ضيف صورة شهادة التخرج');
      return;
    }
    setState(() => _busy = true);
    try {
      String? opt(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
      final id = await Pro.apply(
        kind: _kind,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        services: _services.toList(),
        specialty: opt(_specialty),
        area: opt(_area),
        years: int.tryParse(_years.text.trim()),
        bio: opt(_bio),
        syndicateNo: _engineer ? opt(_syndicate) : null,
      );
      final failed = <String>[];
      if (_photo.isNotEmpty) {
        try {
          await Pro.uploadPhoto(id, _photo.first);
        } catch (_) {
          failed.add('صورتك');
        }
      }
      if (_certificate.isNotEmpty) {
        try {
          await Pro.uploadCertificate(id, _certificate.first);
        } catch (_) {
          failed.add('صورة الشهادة');
        }
      }
      Analytics.instance.track('provider_signup', {'kind': _kind, 'upload_failed': failed.length});
      if (failed.isNotEmpty) _say('انحفظ ملفك، بس ${failed.join(' و')} ما ارتفعت. جرّب كمان مرة من "عدّل ملفي".');
      widget.onDone();
    } catch (e) {
      _say(switch ('$e') {
        final s when s.contains('bad phone') => 'تأكد من الرقم.',
        final s when s.contains('syndicate') => 'اكتب رقم النقابة.',
        _ => 'ما انبعت، جرّب كمان مرة',
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _link() async {
    if (_code.text.trim().length != 6) return;
    setState(() => _busy = true);
    try {
      await Pro.claimLink(_code.text);
      widget.onDone();
    } catch (_) {
      _say('الكود غلط أو انتهى. اطلب كود جديد من فريق عمّرها.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(TextEditingController c, String label, {String? hint, bool required = false, bool number = false, bool phone = false, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        minLines: lines,
        maxLines: lines,
        keyboardType: phone ? TextInputType.phone : (number ? TextInputType.number : TextInputType.text),
        textDirection: phone || number ? TextDirection.ltr : null,
        textAlign: phone || number ? TextAlign.right : TextAlign.start,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: (v) {
          final value = v?.trim() ?? '';
          if (required && value.isEmpty) return 'لازم تعبّي هالحقل';
          if (phone && value.replaceAll(RegExp(r'\D'), '').length < 9) return 'تأكد من الرقم';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.current != null;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!editing) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(16)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إنت فني أو مهندس؟', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text(
                    'سجّل ببلاش. ملفك بيصير ظاهر للزباين بحلب، وكل شغلة بتعملها من التطبيق بتكبّر سمعتك بتقييمات حقيقية.',
                    style: TextStyle(fontSize: 14, color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SegmentedButton<String>(
            segments: [for (final e in providerKindLabels.entries) ButtonSegment(value: e.key, label: Text(e.value))],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: 16),
          _field(_name, 'الاسم', hint: _engineer ? 'م. سامر' : 'أبو خالد', required: true),
          _field(_phone, 'رقمك (واتساب)', hint: '09xx xxx xxx', required: true, phone: true),
          if (_engineer) ...[
            _field(_syndicate, 'رقم النقابة', required: true, number: true),
            const Text('صورة شهادة التخرج', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            PhotoPickerField(
              photos: _certificate,
              onChanged: (p) => setState(() => _certificate = p),
              max: 1,
              hint: widget.current?.hasCertificate ?? false
                  ? 'الشهادة واصلة. فيك تبدّلها.'
                  : 'بتشوفها إدارة عمّرها بس، وما بتبيّن للزباين.',
            ),
            const SizedBox(height: 14),
          ],
          if (!_engineer) ...[
            const Text('شو بتشتغل؟', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in Service.values)
                  FilterChip(
                    label: Text(s.label),
                    selected: _services.contains(s.key),
                    onSelected: (on) => setState(() => on ? _services.add(s.key) : _services.remove(s.key)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          _field(_specialty, 'اختصاصك بكلمتين', hint: _engineer ? 'مهندس مدني، إشراف إكساء' : 'دهّان ديكورات'),
          Row(
            children: [
              Expanded(child: _field(_area, 'منطقتك', hint: 'حلب')),
              const SizedBox(width: 10),
              Expanded(child: _field(_years, 'سنين الخبرة', number: true)),
            ],
          ),
          _field(_bio, 'نبذة عنك (اختياري)', lines: 3),
          const Text('صورتك (اختياري)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          PhotoPickerField(photos: _photo, onChanged: (p) => setState(() => _photo = p), max: 1),
          const SizedBox(height: 16),
          const NoteRow(
            icon: Icons.lock_outline_rounded,
            text: 'رقمك ما بيبيّن للزباين. فريق عمّرها بيتواصل معك ليتأكد منك قبل ما يصير ملفك ظاهر.',
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.push('/legal'),
            child: Text(
              'بالتسجيل بتوافق على شروط الاستخدام وسياسة الخصوصية.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(decoration: TextDecoration.underline),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _send,
            child: Text(_busy ? 'عم نبعت…' : (editing ? 'احفظ' : 'سجّل')),
          ),
          if (!editing) ...[
            const Divider(height: 40),
            const Text('مسجّل من قبل وغيّرت موبايلك؟', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('اطلب كود الربط من فريق عمّرها واكتبه هون.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(fontSize: 18, letterSpacing: 4),
                    decoration: const InputDecoration(counterText: '', hintText: '000000'),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(width: 96, child: OutlinedButton(onPressed: _busy ? null : _link, child: const Text('اربط'))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

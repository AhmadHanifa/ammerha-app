import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/config.dart';
import '../../app/theme.dart';
import '../../data/home_file.dart';
import '../../data/showcase.dart';
import '../../services/analytics.dart';
import '../../services/home_files.dart';
import '../../widgets/common.dart';

/// "تحقق من شقة موثّقة": a buyer or an agency types the code the owner shared.
class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key, this.code});

  final String? code;

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  late final _code = TextEditingController(text: widget.code);
  Map<String, dynamic>? _result;
  var _searched = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.code != null) _check();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    if (!AppConfig.hasBackend) {
      setState(() => _searched = true);
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await HomeFiles.verify(code);
      Analytics.instance.track('certificate_checked', {'found': result != null});
      if (mounted) {
        setState(() {
          _result = result;
          _searched = true;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تأكد من النت وجرّب كمان مرة')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            ScreenHeader(title: 'تحقق من شقة موثّقة', onBack: () => context.pop()),
            const SizedBox(height: 10),
            Text(
              'كل شقة بتخلص مع الفريق بتاخد شهادة فيها مراحل الشغل والمواد والضمان. اكتب الكود اللي عطاك ياه صاحب الشقة.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _code,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(hintText: 'AM-XXXXXX'),
                    onSubmitted: (_) => _check(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 96,
                  child: FilledButton(onPressed: _busy ? null : _check, child: const Text('تحقق')),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_searched && _result == null)
              const NoteRow(
                icon: Icons.search_off_rounded,
                text: 'ما لقينا شهادة ظاهرة بهالكود. تأكد منه، أو اطلب من صاحب الشقة يخلّي الشهادة ظاهرة من التطبيق.',
              ),
            if (_result != null) _CertificateCard(data: _result!),
          ],
        ),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final services = ((data['services'] as List?) ?? const []).cast<String>();
    final level = levelFromKey(data['level']);
    final stages = ((data['stages'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final materials = ((data['materials'] as List?) ?? const []).cast<String>();
    final until = data['warranty_until'] == null ? null : DateTime.parse(data['warranty_until'] as String);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.cardLarge)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('شقة موثّقة من عمّرها', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${data['code']}',
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 2, fontWeight: FontWeight.w700),
              ),
              Text(
                [
                  data['kind'] == 'full' ? 'إكساء شقة كاملة' : servicesLabel(services),
                  if (data['area_m2'] != null) '${data['area_m2']} م²',
                  if (level != null) 'مستوى ${level.label}',
                ].join(' · '),
                style: const TextStyle(color: AppColors.primaryTint, fontSize: 14),
              ),
              Text(
                'نفّذها فريق ${data['sponsor_name'] ?? 'سنديان'} · '
                '${shortDate(DateTime.parse(data['issued_at'] as String).toLocal())}',
                style: const TextStyle(color: AppColors.primaryTint, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (until != null)
          NoteRow(
            icon: Icons.shield_outlined,
            text: until.isAfter(DateTime.now()) ? 'الضمان ساري لـ ${shortDate(until)}' : 'الضمان خلص بـ ${shortDate(until)}',
          ),
        if (stages.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('مراحل الشغل', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          AppCard(
            child: Column(
              children: [
                for (final (i, s) in stages.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                    title: Text(s['title'] as String, style: const TextStyle(fontSize: 15)),
                    trailing: s['approved_at'] == null
                        ? null
                        : Text(
                            shortDate(DateTime.parse(s['approved_at'] as String).toLocal()),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (materials.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('المواد المؤكدة', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [for (final m in materials) InfoChip(m)]),
        ],
        const SizedBox(height: 16),
        NoteRow(
          icon: Icons.cable_outlined,
          text: 'بملف البيت ${data['wiring_photos'] ?? 0} صورة لخريطة التمديدات و${data['stage_photos'] ?? 0} صورة لمراحل الشغل، '
              'محفوظين عند صاحب الشقة.',
        ),
      ],
    );
  }
}

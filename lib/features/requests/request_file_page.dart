import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/config.dart';
import '../../app/theme.dart';
import '../../data/estimate.dart';
import '../../data/home_file.dart';
import '../../data/showcase.dart';
import '../../services/analytics.dart';
import '../../services/home_files.dart';
import '../../services/requests_store.dart';
import '../../widgets/common.dart';
import '../../widgets/photos.dart';

/// ملف البيت: one request's stages with their photos and the customer's
/// approval, the wiring map, the materials to confirm, payments, the
/// inspection report and the certificate.
class RequestFilePage extends StatefulWidget {
  const RequestFilePage({super.key, required this.number});

  final int number;

  @override
  State<RequestFilePage> createState() => _RequestFilePageState();
}

class _RequestFilePageState extends State<RequestFilePage> {
  late Future<RequestFile> _file = HomeFiles.load(widget.number);

  void _reload() {
    setState(() => _file = HomeFiles.load(widget.number));
    RequestsStore.instance.refreshStatuses();
  }

  void _back() => context.canPop() ? context.pop() : context.go('/?tab=requests');

  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
      _reload();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('ما زبط، تأكد من النت وجرّب كمان مرة')));
    }
  }

  Future<void> _askChanges(Stage stage) async {
    final note = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('شو بدك يتعدّل بـ ${stage.title}؟'),
        content: TextField(
          controller: note,
          minLines: 3,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'اكتب شو لاحظت، والفريق بيرجعلك'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(context, note.text.trim()),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('ابعت'),
          ),
        ],
      ),
    );
    note.dispose();
    if (text == null || text.isEmpty) return;
    await _run(() => HomeFiles.decideStage(stage.id, approve: false, note: text), 'وصلت ملاحظتك للفريق');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: _file,
          builder: (context, snap) {
            final file = snap.data;
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  ScreenHeader(title: 'طلب ${widget.number}', onBack: _back),
                  const SizedBox(height: 16),
                  if (!AppConfig.hasBackend)
                    const NoteRow(icon: Icons.info_outline_rounded, text: 'ملف البيت بيشتغل بالنسخة الموصولة بالسيرفر.')
                  else if (snap.hasError)
                    _Problem(notSignedIn: snap.error is NotSignedIn, onRetry: _reload)
                  else if (file == null)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    )
                  else
                    ..._sections(file),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _sections(RequestFile f) {
    final text = Theme.of(context).textTheme;
    final stagePhotos = f.category('stage');
    final wiring = f.category('wiring');
    final materials = f.category('materials');
    final handover = f.category('handover');
    final intake = f.category('intake');
    final inspection = f.category('inspection');
    final paid = f.payments.fold<num>(0, (s, p) => s + p.amount);

    Widget title(String t, {String? hint}) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t, style: text.titleMedium),
          if (hint != null) Text(hint, style: text.bodySmall),
        ],
      ),
    );

    return [
      _Summary(file: f),
      if (f.certificate case final cert?) ...[
        title('الشهادة'),
        _CertificateCard(
          certificate: cert,
          onPublic: (v) => _run(
            () => HomeFiles.setCertificatePublic(f.number, v),
            v ? 'صارت الشهادة ظاهرة لمين معه الكود' : 'صارت الشهادة إلك بس',
          ),
        ),
      ],
      if (f.isInspection) ...[
        title('تقرير الفحص'),
        if (f.report case final report?)
          _ReportCard(report: report)
        else
          const NoteRow(icon: Icons.hourglass_top_rounded, text: 'بعد الفحص بيوصلك التقرير هون، وبيجيك إشعار.'),
        if (inspection.isNotEmpty) ...[
          const SizedBox(height: 12),
          PhotoStrip(urls: [for (final m in inspection) m.url], captions: [for (final m in inspection) m.caption]),
        ],
      ],
      if (!f.isInspection) ...[
        title('مراحل الشغل', hint: f.stages.isEmpty ? null : 'وافق على كل مرحلة بعد ما تشوف صورها.'),
        if (f.stages.isEmpty)
          const NoteRow(
            icon: Icons.view_timeline_outlined,
            text: 'لما يبلّش الشغل، بتطلع هون مراحله، وصور كل مرحلة، وبتوافق عليها من هون.',
          )
        else
          for (final (i, stage) in f.stages.indexed) ...[
            _StageCard(
              index: i + 1,
              stage: stage,
              photos: f.ofStage(stage.id),
              paid: f.payments.where((p) => p.stageId == stage.id).fold<num>(0, (s, p) => s + p.amount),
              onApprove: () => _run(() => HomeFiles.decideStage(stage.id, approve: true), 'وافقت على ${stage.title}'),
              onChanges: () => _askChanges(stage),
            ),
            const SizedBox(height: 10),
          ],
        if (stagePhotos.any((m) => m.stageId == null)) ...[
          const SizedBox(height: 4),
          PhotoStrip(
            urls: [for (final m in stagePhotos.where((m) => m.stageId == null)) m.url],
            captions: [for (final m in stagePhotos.where((m) => m.stageId == null)) m.caption],
          ),
        ],
      ],
      if (materials.isNotEmpty) ...[
        title('تأكيد المواد', hint: 'تأكد إنو المواد اللي وصلت هي اللي اتفقتوا عليها.'),
        for (final m in materials) ...[
          _MaterialTile(
            media: m,
            onConfirm: () => _run(() => HomeFiles.confirmMaterial(m.id), 'تأكدت من المواد'),
          ),
          const SizedBox(height: 8),
        ],
      ],
      if (wiring.isNotEmpty) ...[
        title('خريطة التمديدات', hint: 'وين مرّت المي والكهربا قبل ما تتسكّر الحيطان. احتفظ فيها لأي تصليح.'),
        for (final room in {for (final m in wiring) m.room ?? 'غرف تانية'}) ...[
          Text(room, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          PhotoStrip(
            urls: [for (final m in wiring.where((m) => (m.room ?? 'غرف تانية') == room)) m.url],
            captions: [for (final m in wiring.where((m) => (m.room ?? 'غرف تانية') == room)) m.caption],
          ),
          const SizedBox(height: 12),
        ],
      ],
      if (handover.isNotEmpty) ...[
        title('صور التسليم'),
        PhotoStrip(urls: [for (final m in handover) m.url], captions: [for (final m in handover) m.caption], size: 110),
      ],
      if (f.payments.isNotEmpty) ...[
        title('الدفعات'),
        AppCard(
          child: Column(
            children: [
              for (final (i, p) in f.payments.indexed) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  dense: true,
                  title: Text(
                    f.stages.where((s) => s.id == p.stageId).firstOrNull?.title ?? 'دفعة',
                    style: const TextStyle(fontSize: 15),
                  ),
                  subtitle: Text(shortDate(p.paidOn)),
                  trailing: Text(
                    '${groupDigits('${p.amount.round()}')} \$',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const Divider(height: 1),
              ListTile(
                dense: true,
                title: const Text('المجموع', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: Text(
                  '${groupDigits('${paid.round()}')} \$',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
      if (intake.isNotEmpty) ...[
        title('الصور اللي بعتّها'),
        PhotoStrip(urls: [for (final m in intake) m.url]),
      ],
    ];
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.notSignedIn, required this.onRetry});

  final bool notSignedIn;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NoteRow(
          icon: Icons.cloud_off_rounded,
          text: notSignedIn
              ? 'ما قدرنا نفتح ملفك هلق. تأكد من النت وجرّب كمان مرة.'
              : 'ما قدرنا نجيب ملف الطلب. إذا الطلب من موبايل تاني، افتحه من نفس الموبايل.',
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onRetry,
          style: OutlinedButton.styleFrom(minimumSize: const Size(160, 44)),
          child: const Text('جرّب كمان مرة'),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.file});

  final RequestFile file;

  @override
  Widget build(BuildContext context) {
    final f = file;
    final level = levelFromKey(f.level);
    final status = RequestSummary(number: f.number, kind: f.kind, status: f.status, inspectionAt: f.inspectionAt);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  f.isInspection ? 'فحص شقة قبل الشراء' : (f.kind == 'full' ? 'إكساء شقة كاملة' : servicesLabel(f.services)),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Pill(label: status.statusLabel, background: AppColors.freshBg, foreground: AppColors.freshFg),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (f.area != null) '${f.area} م²',
              if (f.rooms != null) '${f.rooms} غرف · ${f.baths} حمام',
              if (level != null) 'مستوى ${level.label}',
              if (f.remote) 'من برّا',
            ].join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (f.inspectionAt != null)
            Text(
              'موعد المعاينة: ${shortDate(f.inspectionAt!)} الساعة '
              '${f.inspectionAt!.hour.toString().padLeft(2, '0')}:${f.inspectionAt!.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 13, color: AppColors.primaryDark),
            ),
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.index,
    required this.stage,
    required this.photos,
    required this.paid,
    required this.onApprove,
    required this.onChanges,
  });

  final int index;
  final Stage stage;
  final List<MediaItem> photos;
  final num paid;
  final VoidCallback onApprove;
  final VoidCallback onChanges;

  @override
  Widget build(BuildContext context) {
    final s = stage;
    final (bg, fg) = switch (s.status) {
      'ready' => (AppColors.freshBg, AppColors.freshFg),
      'approved' => (AppColors.primaryTint, AppColors.primaryDark),
      'changes' => (const Color(0xFFF6E3E0), AppColors.priceUp),
      'in_progress' => (AppColors.importedBg, AppColors.importedFg),
      _ => (AppColors.lineSoft, AppColors.inkSoft),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card + 2),
        border: Border.all(color: s.waitsForMe ? AppColors.primary : AppColors.line, width: s.waitsForMe ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: s.status == 'approved' ? AppColors.primary : AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: s.status == 'approved'
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : Text('$index', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(s.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              Pill(label: s.label, background: bg, foreground: fg),
            ],
          ),
          if (s.paymentUsd != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 38, top: 4),
              child: Text(
                'دفعة المرحلة ${groupDigits('${s.paymentUsd!.round()}')} \$'
                '${paid > 0 ? ' · مدفوع ${groupDigits('${paid.round()}')} \$' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (s.customerNote != null && s.status == 'changes')
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 38, top: 4),
              child: Text('ملاحظتك: ${s.customerNote}', style: Theme.of(context).textTheme.bodySmall),
            ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            PhotoStrip(urls: [for (final m in photos) m.url], captions: [for (final m in photos) m.caption]),
          ],
          if (s.waitsForMe) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onChanges,
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                    child: const Text('بدي تعديل'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: onApprove,
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                    child: const Text('موافق على المرحلة'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({required this.media, required this.onConfirm});

  final MediaItem media;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final m = media;
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => showPhotos(context, [m.url], captions: [m.caption]),
            child: SizedBox.square(dimension: 64, child: NetImage(m.url, radius: 10)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(m.caption ?? 'مواد', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          if (m.confirmedAt != null)
            const Row(
              children: [
                Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 4),
                Text('تأكدت', style: TextStyle(color: AppColors.primaryDark, fontSize: 13)),
              ],
            )
          else if (m.needsConfirmation)
            FilledButton(
              onPressed: onConfirm,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 14)),
              child: const Text('تأكدت'),
            ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final InspectionReport report;

  @override
  Widget build(BuildContext context) {
    final r = report;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (r.totalMin != null && r.totalMax != null)
          AppCard(
            radius: AppRadius.cardLarge,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('كلفة التصليح التقريبية', style: Theme.of(context).textTheme.bodySmall),
                Text(
                  '${groupDigits('${r.totalMin!.round()}')} – ${groupDigits('${r.totalMax!.round()}')} \$',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        if (r.summary != null) ...[
          const SizedBox(height: 12),
          Text(r.summary!, style: const TextStyle(fontSize: 15, height: 1.7)),
        ],
        const SizedBox(height: 12),
        for (final issue in r.issues) ...[
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(issue.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                    Pill(
                      label: issue.severityLabel,
                      background: issue.severity == 'high' ? const Color(0xFFF6E3E0) : AppColors.lineSoft,
                      foreground: issue.severity == 'high' ? AppColors.priceUp : AppColors.inkSoft,
                    ),
                  ],
                ),
                if (issue.note != null) Text(issue.note!, style: Theme.of(context).textTheme.bodySmall),
                if (issue.costMin != null && issue.costMax != null)
                  Text(
                    '${groupDigits('${issue.costMin!.round()}')} – ${groupDigits('${issue.costMax!.round()}')} \$',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.certificate, required this.onPublic});

  final Certificate certificate;
  final ValueChanged<bool> onPublic;

  @override
  Widget build(BuildContext context) {
    final c = certificate;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A7A6A), AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('شقة موثّقة من عمّرها', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            c.code,
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 2, fontWeight: FontWeight.w700),
          ),
          Text(
            [
              'صدرت ${shortDate(c.issuedAt)}',
              if (c.warrantyUntil != null) 'الضمان لـ ${shortDate(c.warrantyUntil!)}',
            ].join(' · '),
            style: const TextStyle(color: AppColors.primaryTint, fontSize: 13),
          ),
          if (c.note != null) Text(c.note!, style: const TextStyle(color: AppColors.primaryTint, fontSize: 13)),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: c.isPublic,
            onChanged: onPublic,
            activeThumbColor: Colors.white,
            title: const Text('خلّيها ظاهرة لمين معه الكود', style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: const Text(
              'بيشوفوا مراحل الشغل والمواد والضمان، بدون اسمك ورقمك.',
              style: TextStyle(color: AppColors.primaryTint, fontSize: 12),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: c.code));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('انتسخ الكود')));
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    minimumSize: const Size(0, 44),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('انسخ'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: c.isPublic
                      ? () {
                          Analytics.instance.track('certificate_shared');
                          launchUrl(
                            Uri.https('wa.me', '/', {'text': c.shareText}),
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    minimumSize: const Size(0, 44),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('شارك'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

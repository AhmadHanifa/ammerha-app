import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../data/home_file.dart';
import '../../data/pro.dart';
import '../../data/providers.dart';
import '../../services/pro.dart';
import '../../services/whatsapp.dart';
import '../../widgets/common.dart';
import '../../widgets/photos.dart';
import '../../widgets/states.dart';

/// One job, for the provider: the customer's contact, the stages with their
/// photos, the wiring map, materials, handover photos and warranty calls.
class JobPage extends StatefulWidget {
  const JobPage({super.key, required this.number});

  final int number;

  @override
  State<JobPage> createState() => _JobPageState();
}

class _JobPageState extends State<JobPage> {
  late Future<JobFile> _job = Pro.job(widget.number);

  void _reload() => setState(() => _job = Pro.job(widget.number));

  void _back() => context.canPop() ? context.pop() : context.go('/pro');

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

  Future<void> _addPhotos(JobFile job, String category, {Stage? stage}) async {
    final details = await showModalBottomSheet<({List<XFile> photos, String? caption, String? room})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _UploadSheet(category: category, stage: stage),
    );
    if (details == null || details.photos.isEmpty) return;
    await _run(
      () async {
        final n = await Pro.addPhotos(
          requestId: job.requestId,
          number: job.number,
          category: category,
          photos: details.photos,
          stageId: stage?.id,
          caption: details.caption,
          room: details.room,
        );
        if (n == 0) throw Exception('none uploaded');
      },
      'ارتفعت الصور',
    );
  }

  Future<void> _finishStage(Stage stage) async {
    final payment = TextEditingController(text: stage.paymentUsd?.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('خلصت ${stage.title}؟'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('الزبون بيوصله إشعار ليشوف الصور ويوافق. ارفع الصور قبل.'),
            const SizedBox(height: 12),
            TextField(
              controller: payment,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'دفعة المرحلة \$ (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('لسا')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('خلصت'),
          ),
        ],
      ),
    );
    final amount = num.tryParse(payment.text.trim());
    payment.dispose();
    if (ok != true) return;
    await _run(() => Pro.setStage(stage.id, 'ready', payment: amount), 'انبعتت للزبون ليوافق');
  }

  Future<void> _claim(WarrantyClaim claim) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('حدد موعد للتصليح'),
              onTap: () => Navigator.pop(c, 'scheduled'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline_rounded),
              title: const Text('صلّحتها'),
              onTap: () => Navigator.pop(c, 'fixed'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    DateTime? visit;
    if (action == 'scheduled') {
      final now = DateTime.now();
      final day = await showDatePicker(context: context, firstDate: now, lastDate: now.add(const Duration(days: 60)));
      if (day == null || !mounted) return;
      final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
      visit = DateTime(day.year, day.month, day.day, time?.hour ?? 10, time?.minute ?? 0);
    }
    await _run(() => Pro.updateClaim(claim.id, action, visitAt: visit), 'وصل للزبون');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: _job,
          builder: (context, snap) {
            final job = snap.data;
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  ScreenHeader(title: 'طلب ${widget.number}', onBack: _back),
                  const SizedBox(height: 16),
                  if (snap.hasError)
                    const NoteRow(icon: Icons.cloud_off_rounded, text: 'ما قدرنا نفتح الشغلة. جرّب كمان مرة.')
                  else if (job == null)
                    const SkeletonList(count: 4)
                  else
                    ..._sections(job),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _sections(JobFile job) {
    final text = Theme.of(context).textTheme;
    Widget title(String t, {String? hint, Widget? action}) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(t, style: text.titleMedium), if (hint != null) Text(hint, style: text.bodySmall)],
            ),
          ),
          ?action,
        ],
      ),
    );

    Widget group(String category, String label, {String? hint}) {
      final items = job.category(category);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title(
            label,
            hint: hint,
            action: TextButton.icon(
              onPressed: () => _addPhotos(job, category),
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text('ضيف'),
            ),
          ),
          if (items.isNotEmpty)
            PhotoStrip(
              urls: [for (final m in items) m.url],
              captions: [
                for (final m in items)
                  [
                    m.room,
                    m.caption,
                    if (m.needsConfirmation) m.confirmedAt == null ? 'بانتظار الزبون' : 'أكّدها الزبون',
                  ].whereType<String>().join(' · '),
              ],
            ),
        ],
      );
    }

    return [
      AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(
              [if (job.size?.isNotEmpty ?? false) job.size!, if (job.level != null) 'مستوى ${job.level}', if (job.place != null) job.place!]
                  .join(' · '),
              style: text.bodySmall,
            ),
            if (job.notes != null) ...[const SizedBox(height: 6), Text('ملاحظات الزبون: ${job.notes}')],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text(job.customer, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                FilledButton.icon(
                  onPressed: () => openChat(job.whatsapp, 'مرحبا ${job.customer}، معك من عمّرها بخصوص طلب ${job.number}.'),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: const Text('واتساب'),
                ),
              ],
            ),
          ],
        ),
      ),
      title(
        'المراحل',
        hint: 'ارفع صور كل مرحلة، وبعدين كبس "خلصت" ليوافق الزبون.',
        action: job.stages.isEmpty
            ? TextButton(onPressed: () => _run(() => Pro.addStages(job.number), 'انضافت المراحل'), child: const Text('ضيف المراحل'))
            : null,
      ),
      if (job.stages.isEmpty)
        const NoteRow(icon: Icons.view_timeline_outlined, text: 'لسا ما في مراحل. ضيف المراحل المعتادة وعدّلها حسب الشغل.')
      else
        for (final s in job.stages) ...[
          _StageCard(
            stage: s,
            photos: job.ofStage(s.id),
            onStart: () => _run(() => Pro.setStage(s.id, 'in_progress'), 'بلّشت ${s.title}'),
            onPhotos: () => _addPhotos(job, 'stage', stage: s),
            onFinish: () => _finishStage(s),
          ),
          const SizedBox(height: 10),
        ],
      group('wiring', 'خريطة التمديدات', hint: 'صوّر المي والكهربا بكل حيط قبل ما يتسكّر.'),
      group('materials', 'المواد', hint: 'صوّر الكراتين والماركة، والزبون بيأكد.'),
      group('handover', 'صور التسليم'),
      if (job.claims.isNotEmpty) ...[
        title('بلاغات الضمان'),
        for (final c in job.claims) ...[
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(shortDate(c.createdAt), style: text.bodySmall)),
                    Pill(label: c.label, background: AppColors.freshBg, foreground: AppColors.freshFg),
                  ],
                ),
                Text(c.description, style: const TextStyle(fontSize: 15)),
                if (c.status == 'open' || c.status == 'scheduled')
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(onPressed: () => _claim(c), child: const Text('حدّث')),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    ];
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.photos,
    required this.onStart,
    required this.onPhotos,
    required this.onFinish,
  });

  final Stage stage;
  final List<MediaItem> photos;
  final VoidCallback onStart;
  final VoidCallback onPhotos;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final s = stage;
    final canWork = s.status == 'pending' || s.status == 'in_progress' || s.status == 'changes';
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(s.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              Pill(
                label: switch (s.status) {
                  'ready' => 'بانتظار الزبون',
                  'approved' => 'وافق الزبون',
                  'changes' => 'طلب تعديل',
                  'in_progress' => 'عم تشتغل عليها',
                  _ => 'لسا',
                },
                background: s.status == 'approved' ? AppColors.primaryTint : AppColors.freshBg,
                foreground: s.status == 'approved' ? AppColors.primaryDark : AppColors.freshFg,
              ),
            ],
          ),
          if (s.status == 'changes' && s.customerNote != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('الزبون: ${s.customerNote}', style: const TextStyle(color: AppColors.priceUp)),
            ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            PhotoStrip(urls: [for (final m in photos) m.url], captions: [for (final m in photos) m.caption]),
          ],
          if (canWork) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (s.status == 'pending')
                  OutlinedButton(
                    onPressed: onStart,
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                    child: const Text('بلّشت'),
                  ),
                OutlinedButton.icon(
                  onPressed: onPhotos,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: const Text('صور'),
                ),
                FilledButton(
                  onPressed: photos.isEmpty ? null : onFinish,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  child: const Text('خلصت'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _UploadSheet extends StatefulWidget {
  const _UploadSheet({required this.category, this.stage});

  final String category;
  final Stage? stage;

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  final _caption = TextEditingController();
  final _room = TextEditingController();
  var _photos = <XFile>[];

  @override
  void dispose() {
    _caption.dispose();
    _room.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    final materials = c == 'materials';
    final ready = _photos.isNotEmpty && (!materials || _caption.text.trim().isNotEmpty);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.stage?.title ??
                  switch (c) {
                    'wiring' => 'خريطة التمديدات',
                    'materials' => 'المواد',
                    _ => 'صور التسليم',
                  },
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            PhotoPickerField(photos: _photos, onChanged: (p) => setState(() => _photos = p), max: 10),
            const SizedBox(height: 12),
            if (c == 'wiring' || c == 'handover')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(controller: _room, decoration: const InputDecoration(hintText: 'الغرفة، مثلاً المطبخ')),
              ),
            TextField(
              controller: _caption,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: materials ? 'المادة والماركة، مثلاً دهان جوتن' : 'وصف قصير (اختياري)',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: ready
                  ? () => Navigator.pop(context, (
                      photos: _photos,
                      caption: _caption.text.trim().isEmpty ? null : _caption.text.trim(),
                      room: _room.text.trim().isEmpty ? null : _room.text.trim(),
                    ))
                  : null,
              child: const Text('ارفع'),
            ),
          ],
        ),
      ),
    );
  }
}

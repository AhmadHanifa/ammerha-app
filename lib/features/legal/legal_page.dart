import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../data/article.dart';
import '../../services/analytics.dart';
import '../../services/partner.dart';
import '../../widgets/common.dart';

/// سياسة الخصوصية وشروط الاستخدام, from assets/legal; the same files are
/// published next to the dashboard for the app stores.
class LegalPage extends StatefulWidget {
  const LegalPage({super.key});

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  var _tab = 0;
  late final _texts = Future.wait([
    rootBundle.loadString('assets/legal/privacy.txt'),
    rootBundle.loadString('assets/legal/terms.txt'),
  ]);

  /// Deletion goes to the team on WhatsApp with this phone's id, so they can
  /// find the requests and photos to delete.
  Future<void> _askDeletion() async {
    final messenger = ScaffoldMessenger.of(context);
    final number = Partner.instance.whatsappNumber;
    if (number.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('رقم واتساب عمّرها مو جاهز هلق. جرّب بعدين.')));
      return;
    }
    final device = await Analytics.instance.ensureDeviceId();
    final text = 'مرحبا، بدي احذف بياناتي من تطبيق عمّرها.\nرقم الجهاز: $device';
    try {
      await launchUrl(Uri.https('wa.me', '/$number', {'text': text}), mode: LaunchMode.externalApplication);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('ما انفتح الواتساب.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: _texts,
          builder: (context, snap) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              ScreenHeader(title: 'الخصوصية والشروط', onBack: () => context.pop()),
              const SizedBox(height: 16),
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 0, label: Text('سياسة الخصوصية')),
                  ButtonSegment(value: 1, label: Text('شروط الاستخدام')),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
              const SizedBox(height: 12),
              if (snap.hasData)
                for (final block in parseArticle(snap.data![_tab]))
                  switch (block) {
                    HeadingBlock(:final text) => Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 4),
                      child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    ),
                    ParagraphBlock(:final text) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(text, style: const TextStyle(fontSize: 15, height: 1.8)),
                    ),
                    BulletsBlock(:final items) => Column(
                      children: [
                        for (final item in items)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 9),
                                  child: CircleAvatar(radius: 3, backgroundColor: AppColors.primary),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(item, style: const TextStyle(fontSize: 15, height: 1.7))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  },
              if (_tab == 0) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _askDeletion,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('اطلب حذف بياناتي'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

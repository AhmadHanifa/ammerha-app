import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/estimate.dart';
import '../../widgets/common.dart';

/// "خدمة وحدة": the customer picks one service or a few.
class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final _picked = <Service>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                children: [
                  ScreenHeader(title: 'خدمة وحدة', onBack: () => context.pop()),
                  const SizedBox(height: 18),
                  const Text(
                    'شو الخدمة اللي بدك ياها؟',
                    style: TextStyle(fontSize: 26, height: 1.45, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'فيك تختار أكتر من وحدة، وكل ما زادوا بيصير السعر أحسن.',
                    style: TextStyle(fontSize: 15, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 20),
                  for (final service in Service.values) ...[
                    _ServiceTile(
                      service: service,
                      selected: _picked.contains(service),
                      onTap: () => setState(() => _picked.contains(service) ? _picked.remove(service) : _picked.add(service)),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
              child: FilledButton(
                onPressed: _picked.isEmpty
                    ? null
                    : () => context.push('/calculator', extra: CalcInput(kind: RequestKind.service, services: {..._picked})),
                child: const Text('التالي'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.selected, required this.onTap});

  final Service service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryTint : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card + 2),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card + 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? AppColors.surface : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(service.icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  service.label,
                  style: TextStyle(fontSize: 17, fontWeight: selected ? FontWeight.w600 : FontWeight.w500),
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? AppColors.primary : AppColors.line,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

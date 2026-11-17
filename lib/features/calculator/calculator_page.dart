import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/transitions.dart';
import '../../data/estimate.dart';
import '../../services/analytics.dart';
import '../../widgets/common.dart';

enum _Step { area, rooms, level }

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key, required this.input});

  /// A full apartment, or the services picked before.
  final CalcInput input;

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  var _step = 0;
  var _reverse = false;
  late var _input = widget.input;

  // Rooms and baths only matter where the price depends on them.
  List<_Step> get _steps => [_Step.area, if (_input.needsRooms) _Step.rooms, _Step.level];

  void _go(int delta) {
    final steps = _steps;
    final next = _step + delta;
    if (next < 0) {
      context.pop();
      return;
    }
    if (next == steps.length) {
      Analytics.instance.track('calc_done', {
        'kind': _input.kind.name,
        'services': [for (final s in _input.orderedServices) s.key],
        'area': _input.area,
        'rooms': _input.rooms,
        'baths': _input.baths,
        'level': _input.level.name,
      });
      context.push('/result', extra: _input);
      return;
    }
    setState(() {
      _reverse = delta < 0;
      _step = next;
    });
  }

  void _update(CalcInput input) => setState(() => _input = input);

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final steps = _steps;
    final step = steps[_step];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  BackSquareButton(onPressed: () => _go(-1)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'الخطوة ${_step + 1} من ${steps.length}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Flexible(child: SponsorBadge()),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  for (var i = 0; i < steps.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: AnimatedContainer(
                        duration: reduced ? Duration.zero : Motion.sharedAxis,
                        curve: Motion.curve,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i <= _step ? AppColors.primary : const Color(0xFFDDE5E0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 28),
              Expanded(
                child: PageTransitionSwitcher(
                  reverse: _reverse,
                  duration: reduced ? Duration.zero : Motion.sharedAxis,
                  transitionBuilder: (child, primary, secondary) =>
                      DirectionalSharedAxis(animation: primary, secondaryAnimation: secondary, child: child),
                  child: ScreenTracker(
                    key: ValueKey(step),
                    name: 'calc_${step.name}',
                    props: {'kind': _input.kind.name},
                    child: _buildStep(step),
                  ),
                ),
              ),
              FilledButton(
                onPressed: () => _go(1),
                child: Text(_step == steps.length - 1 ? 'احسب الكلفة' : 'التالي'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(_Step step) {
    return switch (step) {
      _Step.area => _Question(
        title: _input.isFull ? 'قديش مساحة الشقة؟' : 'قديش مساحة الشقة اللي بدك فيها ${_input.title}؟',
        hint: 'المساحة الداخلية بالمتر المربع. إذا مو متأكد، اختار الأقرب.',
        child: Column(
          children: [
            _Stepper(
              value: _input.area,
              unit: 'متر مربع',
              step: 5,
              min: 20,
              max: 500,
              onChanged: (v) => _update(_input.copyWith(area: v)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final (i, v) in [80, 100, 120, 150].indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _Choice(
                      label: '$v',
                      selected: _input.area == v,
                      onTap: () => _update(_input.copyWith(area: v)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      _Step.rooms => _Question(
        title: 'كم غرفة وحمام؟',
        hint: 'الغرف بدون الصالون والمطبخ.',
        child: Column(
          children: [
            _Stepper(
              value: _input.rooms,
              unit: 'غرف',
              step: 1,
              min: 1,
              max: 8,
              onChanged: (v) => _update(_input.copyWith(rooms: v)),
            ),
            const SizedBox(height: 12),
            _Stepper(
              value: _input.baths,
              unit: 'حمامات',
              step: 1,
              min: 1,
              max: 5,
              onChanged: (v) => _update(_input.copyWith(baths: v)),
            ),
          ],
        ),
      ),
      _Step.level => _Question(
        title: 'شو مستوى الإكساء؟',
        hint: 'بيأثر على نوع المواد وسعرها.',
        child: Column(
          children: [
            for (final level in FinishLevel.values) ...[
              _LevelCard(
                level: level,
                selected: _input.level == level,
                onTap: () => _update(_input.copyWith(level: level)),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    };
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.title, required this.hint, required this.child});

  final String title;
  final String hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(title, style: const TextStyle(fontSize: 26, height: 1.45, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(hint, style: const TextStyle(fontSize: 15, color: AppColors.inkSoft)),
        const SizedBox(height: 20),
        child,
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.unit,
    required this.step,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final String unit;
  final int step;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Row(
        children: [
          _RoundButton(label: '+', tooltip: 'زيد', onTap: value + step <= max ? () => onChanged(value + step) : null),
          Expanded(
            child: Column(
              children: [
                Text('$value', style: const TextStyle(fontSize: 44, height: 1.2, fontWeight: FontWeight.w700)),
                Text(unit, style: const TextStyle(fontSize: 15, color: AppColors.inkSoft)),
              ],
            ),
          ),
          _RoundButton(label: '−', tooltip: 'نقّص', onTap: value - step >= min ? () => onChanged(value - step) : null),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.label, required this.tooltip, required this.onTap});

  final String label;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 56,
        height: 56,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(56, 56),
            backgroundColor: AppColors.primarySoft,
            side: const BorderSide(color: AppColors.line),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 26)),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryTint : AppColors.surface,
      shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.primary : AppColors.line)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.primaryDark : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, required this.selected, required this.onTap});

  final FinishLevel level;
  final bool selected;
  final VoidCallback onTap;

  static const _examples = {
    FinishLevel.economy: 'سيراميك وطني، دهان عادي، أبواب خشب بسيطة',
    FinishLevel.medium: 'سيراميك تركي، جبس بالصالون، ألمنيوم وسط',
    FinishLevel.deluxe: 'بورسلان، جبس كامل، ألمنيوم وصحية ماركات',
  };

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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(level.label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(_examples[level]!, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
            ],
          ),
        ),
      ),
    );
  }
}

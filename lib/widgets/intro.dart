import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../app/transitions.dart';
import 'brand_mark.dart';

/// The opening animation, over the first screen on a cold start: the mark
/// draws itself on brand green, the name rises in, the tagline follows,
/// then the green lifts away to reveal the home screen. A tap skips it.
class IntroOverlay extends StatefulWidget {
  const IntroOverlay({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<IntroOverlay> createState() => _IntroOverlayState();
}

class _IntroOverlayState extends State<IntroOverlay> with SingleTickerProviderStateMixin {
  static const _length = Duration(milliseconds: 2400);

  late final _controller = AnimationController(vsync: this, duration: _length);
  late var _done = !widget.enabled;

  Animation<double> _part(double from, double to, [Curve curve = Motion.curve]) => CurvedAnimation(
    parent: _controller,
    curve: Interval(from, to, curve: curve),
  );

  late final _roof = _part(0.0, 0.28, Curves.easeInOutCubic);
  late final _body = _part(0.16, 0.48, Curves.easeInOutCubic);
  late final _name = _part(0.38, 0.62);
  late final _line = _part(0.50, 0.72);
  late final _tagline = _part(0.56, 0.78);
  late final _exit = _part(0.82, 1.0, Curves.easeInCubic);

  @override
  void initState() {
    super.initState();
    if (_done) return;
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) setState(() => _done = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Reduced motion: no intro at all.
      if (Motion.reduced(context)) {
        setState(() => _done = true);
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skip() {
    if (_controller.value < 0.82) _controller.forward(from: 0.82);
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        // Material gives the texts the app's font and no debug underline.
        Material(
          type: MaterialType.transparency,
          child: GestureDetector(
            onTap: _skip,
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final exit = _exit.value;
                return Opacity(
                  opacity: 1 - exit,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4A7A6A), AppColors.primaryDark],
                      ),
                    ),
                    child: Transform.scale(
                      scale: 1 + 0.06 * exit,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox.square(
                            dimension: 112,
                            child: CustomPaint(
                              painter: BrandMarkPainter(roof: _roof.value, body: _body.value, stroke: 0.07),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Opacity(
                            opacity: _name.value,
                            child: Transform.translate(
                              offset: Offset(0, 14 * (1 - _name.value)),
                              child: const Text(
                                'عمّرها',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  height: 1.3,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 56 * _line.value,
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Opacity(
                            opacity: _tagline.value,
                            child: Text(
                              'إكساء بيتك، بثقة',
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(color: AppColors.primaryTint, fontSize: 15, letterSpacing: 0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

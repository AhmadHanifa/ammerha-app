import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Motion spec lives in docs/transitions.md.
abstract final class Motion {
  /// Material 3 "emphasized decelerate": fast start, soft landing.
  static const curve = Cubic(0.2, 0, 0, 1);
  static const sharedAxis = Duration(milliseconds: 420);
  static const sharedAxisReverse = Duration(milliseconds: 360);
  static const fadeThrough = Duration(milliseconds: 350);
  static const containerOpen = Duration(milliseconds: 440);
  static const containerClose = Duration(milliseconds: 380);
  static const _slide = 30.0;

  static bool reduced(BuildContext context) => MediaQuery.of(context).disableAnimations;
}

/// Horizontal shared-axis transition that follows the reading direction.
///
/// `SharedAxisTransition` from package:animations always enters from the
/// right; in RTL "forward" must enter from the left and leave to the right.
class DirectionalSharedAxis extends StatelessWidget {
  const DirectionalSharedAxis({super.key, required this.animation, required this.secondaryAnimation, required this.child});

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return child;
    final forward = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;

    final enterMove = CurvedAnimation(parent: animation, curve: Motion.curve);
    final enterFade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 1, curve: Curves.easeOut),
    );
    final exitMove = CurvedAnimation(parent: secondaryAnimation, curve: Motion.curve);
    final exitFade = CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Interval(0, 0.3, curve: Curves.easeIn),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: child,
      builder: (context, child) {
        final dx = forward * Motion._slide * (1 - enterMove.value) - forward * Motion._slide * exitMove.value;
        final opacity = enterFade.value * (1 - exitFade.value);
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(dx, 0), child: child),
        );
      },
    );
  }
}

/// A go_router page that slides along the reading direction.
CustomTransitionPage<void> sharedAxisPage({required LocalKey key, required Widget child}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: Motion.sharedAxis,
    reverseTransitionDuration: Motion.sharedAxisReverse,
    transitionsBuilder: (context, animation, secondaryAnimation, child) => DirectionalSharedAxis(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor, child: child),
    ),
  );
}

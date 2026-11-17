import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/transitions.dart';
import '../../data/estimate.dart';
import '../../services/analytics.dart';
import '../home/home_page.dart';
import '../requests/requests_page.dart';

/// Bottom-navigation shell; tabs switch with a fade-through.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key, this.showRequests = false});

  /// Opens on "طلباتي", as a notification about a request does.
  final bool showRequests;

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  static const _calculatorIndex = 1;
  late var _index = widget.showRequests ? _requestsIndex : 0;

  static const _requestsIndex = 2;

  @override
  void didUpdateWidget(ShellPage old) {
    super.didUpdateWidget(old);
    if (widget.showRequests && !old.showRequests) _index = _requestsIndex;
  }

  void _select(int i) {
    if (i == _calculatorIndex) {
      context.push('/calculator', extra: const CalcInput());
      return;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final tab = _index == 0 ? const HomePage() : const RequestsPage();

    return Scaffold(
      body: SafeArea(
        child: PageTransitionSwitcher(
          duration: Motion.reduced(context) ? Duration.zero : Motion.fadeThrough,
          transitionBuilder: (child, primary, secondary) => FadeThroughTransition(
            animation: primary,
            secondaryAnimation: secondary,
            fillColor: AppColors.background,
            child: child,
          ),
          child: ScreenTracker(
            key: ValueKey(_index),
            name: _index == 0 ? 'home' : 'requests',
            child: tab,
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.calculate_outlined), label: 'الحاسبة'),
            NavigationDestination(icon: Icon(Icons.inbox_outlined), selectedIcon: Icon(Icons.inbox_rounded), label: 'طلباتي'),
          ],
        ),
      ),
    );
  }
}

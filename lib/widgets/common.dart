import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../services/partner.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = EdgeInsets.zero, this.radius = AppRadius.card + 2});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, required this.background, required this.foreground});

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 12, color: foreground, height: 1.6)),
    );
  }
}

/// "برعاية سنديان": on every screen, with the name the dashboard sets.
class SponsorBadge extends StatelessWidget {
  const SponsorBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Partner.instance.sponsorName,
      builder: (context, name, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_outlined, size: 14, color: AppColors.primaryDark),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'برعاية $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, height: 1.6, fontWeight: FontWeight.w500, color: AppColors.primaryDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Square back button; the arrow follows the reading direction.
class BackSquareButton extends StatelessWidget {
  const BackSquareButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onPressed,
        tooltip: 'رجوع',
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.ink),
      ),
    );
  }
}

/// The top of an inner screen: back button, title and the sponsor badge.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.onBack});

  final String title;

  /// Null on screens with no way back (the tabs).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final back = onBack;
    return Row(
      children: [
        if (back != null) ...[BackSquareButton(onPressed: back), const SizedBox(width: 8)],
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22),
          ),
        ),
        const SizedBox(width: 8),
        const Flexible(child: SponsorBadge()),
      ],
    );
  }
}

/// A short line of small print with a leading icon.
class NoteRow extends StatelessWidget {
  const NoteRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
      ],
    );
  }
}

/// A rounded chip with the customer's answers, as on the result screen.
class InfoChip extends StatelessWidget {
  const InfoChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}

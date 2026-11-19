import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'photos.dart';

/// Five stars, filled up to [value]; tappable when [onChanged] is set.
class Stars extends StatelessWidget {
  const Stars({super.key, required this.value, this.size = 18, this.onChanged});

  final num value;
  final double size;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            onTap: onChanged == null ? null : () => onChanged!(i),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: onChanged == null ? 0 : 3),
              child: Icon(
                value >= i
                    ? Icons.star_rounded
                    : (value >= i - 0.5 ? Icons.star_half_rounded : Icons.star_outline_rounded),
                size: size,
                color: AppColors.freshFg,
              ),
            ),
          ),
      ],
    );
  }
}

/// A round photo, or the first letter of the name.
class ProviderAvatar extends StatelessWidget {
  const ProviderAvatar({super.key, required this.name, this.url, this.size = 56, this.verified = false});

  final String name;
  final String? url;
  final double size;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox.square(
          dimension: size,
          child: url == null
              ? CircleAvatar(
                  backgroundColor: AppColors.primaryTint,
                  child: Text(
                    name.characters.first,
                    style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                  ),
                )
              : NetImage(url, radius: size / 2),
        ),
        if (verified)
          Positioned(
            bottom: -2,
            left: -2,
            child: Container(
              decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
              padding: const EdgeInsets.all(1.5),
              child: Icon(Icons.verified_rounded, size: size * 0.32, color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

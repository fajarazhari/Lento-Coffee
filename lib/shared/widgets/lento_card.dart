import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class LentoCard extends StatelessWidget {
  const LentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.hasBorder = true,
    this.elevation = 2,
    this.color,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final bool hasBorder;
  final double elevation;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color ?? AppColors.pureWhite,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: hasBorder
            ? BorderSide(color: borderColor ?? AppColors.borderColor)
            : BorderSide.none,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      );
    }
    return card;
  }
}

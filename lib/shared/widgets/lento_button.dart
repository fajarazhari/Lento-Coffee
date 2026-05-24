import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class LentoButton extends StatelessWidget {
  const LentoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = LentoButtonVariant.primary,
    this.width,
    this.height = 44,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final LentoButtonVariant variant;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      LentoButtonVariant.primary   => (AppColors.coffeeBrown, AppColors.pureWhite),
      LentoButtonVariant.secondary => (AppColors.warmCream,   AppColors.coffeeBrown),
      LentoButtonVariant.danger    => (const Color(0xFFC62828), AppColors.pureWhite),
      LentoButtonVariant.ghost     => (Colors.transparent,     AppColors.coffeeBrown),
    };

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withAlpha(120),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: variant == LentoButtonVariant.ghost
                ? const BorderSide(color: AppColors.borderColor)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

enum LentoButtonVariant { primary, secondary, danger, ghost }

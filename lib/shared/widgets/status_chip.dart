import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

enum StatusChipVariant { success, warning, danger, info, muted }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.variant = StatusChipVariant.info,
    this.compact = false,
  });

  final String label;
  final StatusChipVariant variant;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      StatusChipVariant.success => (const Color(0xFFE8F5E9), AppColors.statusGreen),
      StatusChipVariant.warning => (const Color(0xFFFFF3E0), AppColors.statusOrange),
      StatusChipVariant.danger  => (const Color(0xFFFFEBEE), AppColors.statusRed),
      StatusChipVariant.info    => (const Color(0xFFE3F2FD), AppColors.statusBlue),
      StatusChipVariant.muted   => (AppColors.warmCream, AppColors.coffeeMuted),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: compact ? 9 : 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// Maps order/KDS status strings to chip variants
StatusChipVariant statusChipVariantFor(String status) => switch (status) {
  'Draft'       => StatusChipVariant.muted,
  'Paid'        => StatusChipVariant.info,
  'Brewing'     => StatusChipVariant.warning,
  'Ready'       => StatusChipVariant.success,
  'Completed'   => StatusChipVariant.success,
  'Cancelled'   => StatusChipVariant.danger,
  'Refunded'    => StatusChipVariant.danger,
  'Open'        => StatusChipVariant.success,
  'Closed'      => StatusChipVariant.muted,
  _             => StatusChipVariant.muted,
};

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';

/// Cashier Shift — mirrors CashierShiftPage.kt
class ShiftScreen extends ConsumerWidget {
  const ShiftScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      backgroundColor: AppColors.warmCream,
      body: Center(
        child: Text(
          'Cashier Shift',
          style: TextStyle(fontSize: 18, color: AppColors.coffeeBrown, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

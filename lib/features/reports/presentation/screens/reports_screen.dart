import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../transactions/data/models/order_model.dart';
import '../../../transactions/presentation/providers/orders_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // allOrdersProvider includes completed orders for accurate reports
    final ordersAsync = ref.watch(allOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: ordersAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.coffeeBrown)),
        error: (e, _) =>
            Center(child: Text('Error: $e')),
        data: (orders) {
          final paid = orders
              .where((o) =>
                  o.status == OrderStatus.paid ||
                  o.status == OrderStatus.completed)
              .toList();
          final totalRevenue =
              paid.fold(0.0, (s, o) => s + o.total);
          final totalTax =
              paid.fold(0.0, (s, o) => s + o.taxAmount);
          final totalOrders = paid.length;
          final avgOrder =
              totalOrders == 0 ? 0.0 : totalRevenue / totalOrders;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Text('Sales Reports',
                      style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800,
                        color: AppColors.coffeeDark)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 14, color: AppColors.coffeeBrown),
                        const SizedBox(width: 8),
                        Text(
                          'Hari ini — ${DateTime.now().day}/'
                          '${DateTime.now().month}/'
                          '${DateTime.now().year}',
                          style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppColors.coffeeDark)),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Summary cards
                Row(children: [
                  _SummaryCard('Total Revenue',
                      CurrencyFormatter.format(totalRevenue),
                      Icons.attach_money_rounded, AppColors.statusGreen),
                  const SizedBox(width: 16),
                  _SummaryCard('Total Orders', '$totalOrders',
                      Icons.receipt_long_rounded, AppColors.statusBlue),
                  const SizedBox(width: 16),
                  _SummaryCard('Avg Order',
                      CurrencyFormatter.format(avgOrder),
                      Icons.trending_up_rounded, AppColors.statusOrange),
                  const SizedBox(width: 16),
                  _SummaryCard('Tax Collected',
                      CurrencyFormatter.format(totalTax),
                      Icons.percent_rounded, AppColors.coffeeBrown),
                ]),
                const SizedBox(height: 24),
                // Top products table
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Text('Top Products',
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800,
                            color: AppColors.coffeeDark)),
                      ),
                      const Divider(),
                      if (paid.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('Belum ada data transaksi',
                              style: TextStyle(
                                  color: AppColors.coffeeMuted))),
                        )
                      else
                        ..._topProducts(paid).take(10).toList()
                            .asMap()
                            .entries
                            .map((entry) {
                          final rank = entry.key + 1;
                          final item = entry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: AppColors.borderColor))),
                            child: Row(children: [
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: rank <= 3
                                      ? AppColors.goldBrown
                                      : AppColors.warmCream,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text('$rank',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: rank <= 3
                                        ? Colors.white
                                        : AppColors.coffeeMuted)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(item.$1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.coffeeDark))),
                              Text('${item.$2}x',
                                style: const TextStyle(
                                  color: AppColors.coffeeMuted,
                                  fontSize: 13)),
                              const SizedBox(width: 16),
                              Text(CurrencyFormatter.format(item.$3),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.coffeeBrown)),
                            ]),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<(String, int, double)> _topProducts(List<OrderModel> orders) {
    final Map<String, (int, double)> map = {};
    for (final order in orders) {
      for (final item in order.items) {
        final current = map[item.productName] ?? (0, 0.0);
        map[item.productName] = (
          current.$1 + item.quantity,
          current.$2 + item.totalPrice,
        );
      }
    }
    final list =
        map.entries.map((e) => (e.key, e.value.$1, e.value.$2)).toList();
    list.sort((a, b) => b.$3.compareTo(a.$3));
    return list;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                  style: const TextStyle(
                    fontSize: 11, color: AppColors.coffeeMuted,
                    fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value,
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900,
                    color: AppColors.coffeeDark),
                  overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/repositories/report_repository.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(reportFilterProvider);
    final summaryAsync = ref.watch(summaryReportProvider);

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Filters
            Row(
              children: [
                const Text('Sales Reports',
                  style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: AppColors.coffeeDark)),
                const Spacer(),
                
                // Segmented Control
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: ToggleButtons(
                    isSelected: [
                      filterState.type == ReportType.daily,
                      filterState.type == ReportType.monthly,
                      filterState.type == ReportType.yearly,
                    ],
                    onPressed: (index) {
                      final type = ReportType.values[index];
                      ref.read(reportFilterProvider.notifier).setType(type);
                    },
                    color: AppColors.coffeeMuted,
                    selectedColor: AppColors.pureWhite,
                    fillColor: AppColors.coffeeBrown,
                    borderRadius: BorderRadius.circular(7),
                    constraints: const BoxConstraints(minHeight: 36, minWidth: 80),
                    children: const [
                      Text('Daily', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('Monthly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('Yearly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Date Picker Button
                InkWell(
                  onTap: () async {
                    DateTime initialDate = filterState.date;
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.coffeeBrown,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (selected != null) {
                      ref.read(reportFilterProvider.notifier).setDate(selected);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.coffeeBrown),
                      const SizedBox(width: 8),
                      Text(_formatDateLabel(filterState.type, filterState.date),
                        style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppColors.coffeeDark)),
                    ]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Content
            summaryAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(48.0),
                child: CircularProgressIndicator(color: AppColors.coffeeBrown),
              )),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
              data: (summary) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards Row 1
                    Row(children: [
                      _SummaryCard('Gross Revenue', CurrencyFormatter.format(summary.totalRevenue),
                          Icons.attach_money_rounded, AppColors.statusGreen),
                      const SizedBox(width: 16),
                      _SummaryCard('Total Orders', '${summary.totalOrders}',
                          Icons.receipt_long_rounded, AppColors.statusBlue),
                      const SizedBox(width: 16),
                      _SummaryCard('Avg Order', CurrencyFormatter.format(summary.averageOrderValue),
                          Icons.trending_up_rounded, AppColors.statusOrange),
                      const SizedBox(width: 16),
                      _SummaryCard('Top Cashier', summary.topCashier,
                          Icons.person_rounded, AppColors.coffeeBrown),
                    ]),
                    
                    const SizedBox(height: 16),
                    
                    // Summary Cards Row 2 (Tunai / Non-Tunai)
                    Builder(
                      builder: (context) {
                        final tunai = summary.paymentBreakdown['Cash'] ?? 0.0;
                        final nonTunai = summary.paymentBreakdown.entries
                            .where((e) => e.key != 'Cash')
                            .fold(0.0, (sum, e) => sum + e.value);
                            
                        return Row(children: [
                          _SummaryCard('Tunai', CurrencyFormatter.format(tunai),
                              Icons.money_rounded, const Color(0xFF43A047)),
                          const SizedBox(width: 16),
                          _SummaryCard('Non-Tunai (QRIS/Transfer)', CurrencyFormatter.format(nonTunai),
                              Icons.qr_code_rounded, const Color(0xFF039BE5)),
                          const SizedBox(width: 16),
                          const Spacer(),
                          const SizedBox(width: 16),
                          const Spacer(),
                        ]);
                      }
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Chart & Top Products Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chart
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 400,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.pureWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sales Trend',
                                  style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w800,
                                    color: AppColors.coffeeDark)),
                                const SizedBox(height: 24),
                                Expanded(child: _SalesChart(summary)),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 24),
                        
                        // Top Products
                        Expanded(
                          flex: 1,
                          child: Container(
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
                                if (summary.topProducts.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Center(
                                      child: Text('Belum ada data',
                                        style: TextStyle(color: AppColors.coffeeMuted))),
                                  )
                                else
                                  ...summary.topProducts.take(10).toList().asMap().entries.map((entry) {
                                    final rank = entry.key + 1;
                                    final item = entry.value;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: const BoxDecoration(
                                        border: Border(bottom: BorderSide(color: AppColors.borderColor))),
                                      child: Row(children: [
                                        Container(
                                          width: 24, height: 24,
                                          decoration: BoxDecoration(
                                            color: rank <= 3 ? AppColors.goldBrown : AppColors.warmCream,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text('$rank',
                                            style: TextStyle(
                                              fontSize: 11, fontWeight: FontWeight.w800,
                                              color: rank <= 3 ? Colors.white : AppColors.coffeeMuted)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(item.$1,
                                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.coffeeDark),
                                            overflow: TextOverflow.ellipsis,
                                          )),
                                        Text('${item.$2}x',
                                          style: const TextStyle(color: AppColors.coffeeMuted, fontSize: 13)),
                                      ]),
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateLabel(ReportType type, DateTime date) {
    if (type == ReportType.daily) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (type == ReportType.monthly) {
      return '${_monthName(date.month)} ${date.year}';
    } else {
      return '${date.year}';
    }
  }

  String _monthName(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
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

class _SalesChart extends StatelessWidget {
  const _SalesChart(this.summary);
  final ReportSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    if (summary.totalRevenue == 0) {
      return const Center(child: Text('No sales data', style: TextStyle(color: AppColors.coffeeMuted)));
    }
    
    double maxY = summary.chartData.reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 1000;
    // Add 20% padding to top
    maxY = maxY * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.coffeeDark,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                CurrencyFormatter.format(rod.toY),
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _getLabel(value.toInt(), summary.type),
                    style: const TextStyle(color: AppColors.coffeeMuted, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == maxY) return const SizedBox();
                return Text(
                  _formatAxisValue(value),
                  style: const TextStyle(color: AppColors.coffeeMuted, fontSize: 10),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.borderColor,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: summary.chartData.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: AppColors.goldBrown,
                width: summary.type == ReportType.yearly ? 24 : (summary.type == ReportType.monthly ? 8 : 12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _getLabel(int index, ReportType type) {
    if (type == ReportType.daily) {
      if (index % 3 == 0) return '$index:00';
      return '';
    } else if (type == ReportType.monthly) {
      if (index % 5 == 0 || index == summary.chartData.length - 1) return '${index + 1}';
      return '';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return months[index];
    }
  }

  String _formatAxisValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }
}

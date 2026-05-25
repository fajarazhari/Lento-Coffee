import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/date_utils.dart';

part 'report_repository.g.dart';

enum ReportType { daily, monthly, yearly }

// ─── Model ────────────────────────────────────────────────────────────────────
class ReportSummaryModel extends Equatable {
  const ReportSummaryModel({
    required this.type,
    required this.date,
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalRefunds,
    required this.paymentBreakdown,
    required this.topProducts,
    required this.topCashier,
    required this.chartData,
  });

  final ReportType type;
  final DateTime date;
  final double totalRevenue;
  final int totalOrders;
  final double totalRefunds;
  final Map<String, double> paymentBreakdown;  // e.g. {"Cash": 150000}
  final List<(String, int, double)> topProducts; // (name, qty, revenue)
  final String topCashier;
  final List<double> chartData; // length depends on type (24, 28-31, 12)

  double get averageOrderValue =>
      totalOrders > 0 ? totalRevenue / totalOrders : 0;

  @override
  List<Object?> get props => [type, date, totalRevenue, totalOrders];
}

// ─── Repository ───────────────────────────────────────────────────────────────
@riverpod
ReportRepository reportRepository(ReportRepositoryRef ref) {
  return ReportRepository(firestore: FirebaseFirestore.instance);
}

class ReportRepository {
  ReportRepository({required this.firestore});
  final FirebaseFirestore firestore;

  CollectionReference get _orders => firestore.collection(FirestorePaths.orders);

  Future<Either<Failure, ReportSummaryModel>> getSummary(ReportType type, DateTime date) async {
    try {
      late DateTime start;
      late DateTime end;
      late int chartSize;

      if (type == ReportType.daily) {
        start = AppDateUtils.startOfDay(date);
        end = AppDateUtils.endOfDay(date);
        chartSize = 24; // 24 hours
      } else if (type == ReportType.monthly) {
        start = DateTime(date.year, date.month, 1);
        end = DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
        chartSize = end.day; // 28, 29, 30, or 31 days
      } else {
        start = DateTime(date.year, 1, 1);
        end = DateTime(date.year, 12, 31, 23, 59, 59, 999);
        chartSize = 12; // 12 months
      }

      final snap = await _orders
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .where('status', whereIn: ['Completed', 'Paid'])
          .get();

      double totalRevenue = 0;
      double totalRefunds = 0;
      int totalOrders = snap.docs.length;
      final paymentBreakdown = <String, double>{};
      final chartData = List<double>.filled(chartSize, 0);
      
      // For Top Products
      final productMap = <String, (int, double)>{};
      // For Top Cashier
      final cashierMap = <String, double>{};

      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final total = (data['total'] as num?)?.toDouble() ?? 0;
        final method = data['paymentMethod'] as String? ?? 'Cash';
        final cashierName = data['cashierName'] as String? ?? 'Unknown';
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final status = data['status'] as String? ?? '';

        if (status == 'Refunded') {
          totalRefunds += total;
        } else {
          totalRevenue += total;
          paymentBreakdown[method] = (paymentBreakdown[method] ?? 0) + total;
          
          cashierMap[cashierName] = (cashierMap[cashierName] ?? 0) + total;

          if (type == ReportType.daily) {
            chartData[createdAt.hour] += total;
          } else if (type == ReportType.monthly) {
            chartData[createdAt.day - 1] += total;
          } else if (type == ReportType.yearly) {
            chartData[createdAt.month - 1] += total;
          }
        }
      }

      // We need to fetch items from subcollections to calculate top products.
      // Doing this for EVERY order in a year might be heavy. For now, we do it in parallel.
      final itemFutures = snap.docs.where((d) => (d.data() as Map)['status'] != 'Refunded').map((doc) => doc.reference.collection('items').get());
      final itemSnaps = await Future.wait(itemFutures);
      
      for (final itemSnap in itemSnaps) {
        for (final itemDoc in itemSnap.docs) {
          final itemData = itemDoc.data();
          final name = itemData['productName'] as String? ?? 'Unknown';
          final qty = itemData['quantity'] as int? ?? 1;
          final price = (itemData['totalPrice'] as num?)?.toDouble() ?? 0;
          
          final current = productMap[name] ?? (0, 0.0);
          productMap[name] = (current.$1 + qty, current.$2 + price);
        }
      }

      final topProductsList = productMap.entries
          .map((e) => (e.key, e.value.$1, e.value.$2))
          .toList()
        ..sort((a, b) => b.$3.compareTo(a.$3));

      String topCashier = '-';
      if (cashierMap.isNotEmpty) {
        final sortedCashiers = cashierMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        topCashier = sortedCashiers.first.key;
      }

      return Right(ReportSummaryModel(
        type:             type,
        date:             date,
        totalRevenue:     totalRevenue,
        totalOrders:      totalOrders,
        totalRefunds:     totalRefunds,
        paymentBreakdown: paymentBreakdown,
        topProducts:      topProductsList,
        topCashier:       topCashier,
        chartData:        chartData,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

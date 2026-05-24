import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/date_utils.dart';

part 'report_repository.g.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class DailySummaryModel extends Equatable {
  const DailySummaryModel({
    required this.date,
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalRefunds,
    required this.paymentBreakdown,
    required this.topProducts,
    required this.hourlyRevenue,
  });

  final DateTime date;
  final double totalRevenue;
  final int totalOrders;
  final double totalRefunds;
  final Map<String, double> paymentBreakdown;  // {"Cash": 150000, "QRIS": 80000}
  final List<Map<String, dynamic>> topProducts; // [{name, revenue, count}]
  final List<double> hourlyRevenue;             // 24 values, index = hour

  double get averageOrderValue =>
      totalOrders > 0 ? totalRevenue / totalOrders : 0;

  @override
  List<Object?> get props => [date, totalRevenue, totalOrders];
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

  /// Aggregate orders for a specific day into a DailySummaryModel
  Future<Either<Failure, DailySummaryModel>> getDailySummary(DateTime date) async {
    try {
      final start = Timestamp.fromDate(AppDateUtils.startOfDay(date));
      final end   = Timestamp.fromDate(AppDateUtils.endOfDay(date));

      final snap = await _orders
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThanOrEqualTo: end)
          .where('status', whereIn: ['Completed', 'Paid'])
          .get();

      double totalRevenue = 0;
      double totalRefunds = 0;
      int totalOrders = snap.docs.length;
      final paymentBreakdown = <String, double>{};
      final productCount = <String, Map<String, dynamic>>{};
      final hourlyRevenue = List<double>.filled(24, 0);

      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final total = (data['total'] as num?)?.toDouble() ?? 0;
        final method = data['paymentMethod'] as String? ?? 'Cash';
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final status = data['status'] as String? ?? '';

        if (status == 'Refunded') {
          totalRefunds += total;
        } else {
          totalRevenue += total;
          paymentBreakdown[method] = (paymentBreakdown[method] ?? 0) + total;
          hourlyRevenue[createdAt.hour] += total;
        }
      }

      // Top products aggregation would need a separate query or Cloud Function
      // For now, return empty top products (implement with Cloud Functions later)
      return Right(DailySummaryModel(
        date:             date,
        totalRevenue:     totalRevenue,
        totalOrders:      totalOrders,
        totalRefunds:     totalRefunds,
        paymentBreakdown: paymentBreakdown,
        topProducts:      [],
        hourlyRevenue:    hourlyRevenue,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Revenue for the last N days (for weekly chart)
  Future<Either<Failure, List<(DateTime, double)>>> getWeeklyRevenue() async {
    try {
      final results = <(DateTime, double)>[];
      for (int i = 6; i >= 0; i--) {
        final day = DateTime.now().subtract(Duration(days: i));
        final summary = await getDailySummary(day);
        results.add((day, summary.fold((_) => 0.0, (s) => s.totalRevenue)));
      }
      return Right(results);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────
@riverpod
Future<DailySummaryModel> todaySummary(TodaySummaryRef ref) async {
  final result = await ref
      .watch(reportRepositoryProvider)
      .getDailySummary(DateTime.now());
  return result.fold(
    (f) => throw Exception(f.message),
    (summary) => summary,
  );
}

@riverpod
Future<List<(DateTime, double)>> weeklyRevenue(WeeklyRevenueRef ref) async {
  final result = await ref.watch(reportRepositoryProvider).getWeeklyRevenue();
  return result.fold((_) => [], (list) => list);
}

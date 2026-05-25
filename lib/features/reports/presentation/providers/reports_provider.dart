import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/report_repository.dart';

part 'reports_provider.g.dart';

class ReportFilterState extends Equatable {
  const ReportFilterState({
    this.type = ReportType.daily,
    required this.date,
  });

  final ReportType type;
  final DateTime date;

  ReportFilterState copyWith({
    ReportType? type,
    DateTime? date,
  }) {
    return ReportFilterState(
      type: type ?? this.type,
      date: date ?? this.date,
    );
  }

  @override
  List<Object?> get props => [type, date];
}

@riverpod
class ReportFilter extends _$ReportFilter {
  @override
  ReportFilterState build() {
    return ReportFilterState(date: DateTime.now());
  }

  void setType(ReportType type) {
    state = state.copyWith(type: type);
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }
}

@riverpod
Future<ReportSummaryModel> summaryReport(SummaryReportRef ref) async {
  final filter = ref.watch(reportFilterProvider);
  final repo = ref.watch(reportRepositoryProvider);

  final result = await repo.getSummary(filter.type, filter.date);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (summary) => summary,
  );
}

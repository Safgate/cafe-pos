part of 'report_bloc.dart';

enum ReportStatus { initial, loading, loaded, error }

enum ReportPeriod { day, week, month }

extension ReportPeriodX on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.day:
        return 'Day';
      case ReportPeriod.week:
        return 'Week';
      case ReportPeriod.month:
        return 'Month';
    }
  }

  DateRange toRange() {
    switch (this) {
      case ReportPeriod.day:
        return DateRange.today();
      case ReportPeriod.week:
        return DateRange.thisWeek();
      case ReportPeriod.month:
        return DateRange.thisMonth();
    }
  }
}

class ReportState extends Equatable {
  final ReportSummary? summary;
  final ReportStatus status;
  final ReportPeriod period;
  final String? message;

  const ReportState({
    this.summary,
    this.status = ReportStatus.initial,
    this.period = ReportPeriod.day,
    this.message,
  });

  ReportState copyWith({
    ReportSummary? summary,
    ReportStatus? status,
    ReportPeriod? period,
    String? message,
    bool clearMessage = false,
  }) {
    return ReportState(
      summary: summary ?? this.summary,
      status: status ?? this.status,
      period: period ?? this.period,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [summary, status, period, message];
}

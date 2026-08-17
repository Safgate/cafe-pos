part of 'report_bloc.dart';

abstract class ReportEvent extends Equatable {
  const ReportEvent();
  @override
  List<Object?> get props => [];
}

class LoadReport extends ReportEvent {
  /// Defaults to the currently selected period.
  final DateRange? range;
  const LoadReport({this.range});
  @override
  List<Object?> get props => [range];
}

class ChangeReportPeriod extends ReportEvent {
  final ReportPeriod period;
  const ChangeReportPeriod(this.period);
  @override
  List<Object?> get props => [period];
}

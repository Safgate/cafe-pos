import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/utils/date_range.dart';
import '../../domain/entities/report_summary.dart';
import '../../domain/usecases/get_report_usecase.dart';

part 'report_event.dart';
part 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final GetReportUseCase getReport;

  ReportBloc({required this.getReport}) : super(const ReportState()) {
    on<LoadReport>(_onLoadReport);
    on<ChangeReportPeriod>(_onChangePeriod);
  }

  Future<void> _onLoadReport(
      LoadReport event, Emitter<ReportState> emit) async {
    emit(state.copyWith(status: ReportStatus.loading, clearMessage: true));

    final range = event.range ?? state.period.toRange();
    final result = await getReport(range);

    result.fold(
      (failure) => emit(state.copyWith(
          status: ReportStatus.error, message: failure.message)),
      (summary) => emit(state.copyWith(
          status: ReportStatus.loaded, summary: summary)),
    );
  }

  Future<void> _onChangePeriod(
      ChangeReportPeriod event, Emitter<ReportState> emit) async {
    emit(state.copyWith(period: event.period));
    add(LoadReport(range: event.period.toRange()));
  }
}

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/activity_log.dart';
import '../../domain/repositories/activity_log_repository.dart';

part 'activity_event.dart';
part 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityLogRepository repository;

  ActivityBloc({required this.repository}) : super(const ActivityState()) {
    on<LoadActivity>(_onLoad);
    on<FilterActivity>(_onFilter);
  }

  Future<void> _onLoad(LoadActivity event, Emitter<ActivityState> emit) async {
    emit(state.copyWith(status: ActivityStatus.loading));

    final result = await repository.getLogs(
      staffId: state.staffIdFilter,
      action: state.actionFilter,
      limit: 500,
    );

    result.fold(
      (failure) => emit(state.copyWith(
          status: ActivityStatus.error, message: failure.message)),
      (logs) =>
          emit(state.copyWith(status: ActivityStatus.loaded, logs: logs)),
    );
  }

  Future<void> _onFilter(
      FilterActivity event, Emitter<ActivityState> emit) async {
    emit(state.copyWith(
      staffIdFilter: event.staffId,
      actionFilter: event.action,
      clearStaffFilter: event.staffId == null,
      clearActionFilter: event.action == null,
    ));
    add(LoadActivity());
  }
}

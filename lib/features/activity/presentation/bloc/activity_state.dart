part of 'activity_bloc.dart';

enum ActivityStatus { initial, loading, loaded, error }

class ActivityState extends Equatable {
  final List<ActivityLog> logs;
  final ActivityStatus status;
  final String? message;
  final String? staffIdFilter;
  final String? actionFilter;

  const ActivityState({
    this.logs = const [],
    this.status = ActivityStatus.initial,
    this.message,
    this.staffIdFilter,
    this.actionFilter,
  });

  bool get hasFilters => staffIdFilter != null || actionFilter != null;

  /// Staff who appear in the loaded entries, for the filter menu.
  Map<String, String> get staffInLogs {
    final names = <String, String>{};
    for (final log in logs) {
      if (log.staffId.isNotEmpty) names[log.staffId] = log.staffName;
    }
    return names;
  }

  ActivityState copyWith({
    List<ActivityLog>? logs,
    ActivityStatus? status,
    String? message,
    String? staffIdFilter,
    bool clearStaffFilter = false,
    String? actionFilter,
    bool clearActionFilter = false,
  }) {
    return ActivityState(
      logs: logs ?? this.logs,
      status: status ?? this.status,
      message: message ?? this.message,
      staffIdFilter:
          clearStaffFilter ? null : (staffIdFilter ?? this.staffIdFilter),
      actionFilter:
          clearActionFilter ? null : (actionFilter ?? this.actionFilter),
    );
  }

  @override
  List<Object?> get props =>
      [logs, status, message, staffIdFilter, actionFilter];
}

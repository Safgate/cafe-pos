part of 'activity_bloc.dart';

abstract class ActivityEvent extends Equatable {
  const ActivityEvent();
  @override
  List<Object?> get props => [];
}

class LoadActivity extends ActivityEvent {}

/// Pass null for either field to clear that filter.
class FilterActivity extends ActivityEvent {
  final String? staffId;
  final String? action;

  const FilterActivity({this.staffId, this.action});

  @override
  List<Object?> get props => [staffId, action];
}

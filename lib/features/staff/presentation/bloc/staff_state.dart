part of 'staff_bloc.dart';

enum StaffStatus { initial, loading, loaded, success, error }

class StaffState extends Equatable {
  final List<Staff> staff;
  final StaffStatus status;
  final String? message;

  const StaffState({
    this.staff = const [],
    this.status = StaffStatus.initial,
    this.message,
  });

  List<Staff> get active => staff.where((s) => s.active).toList();

  StaffState copyWith({
    List<Staff>? staff,
    StaffStatus? status,
    String? message,
    bool clearMessage = false,
  }) {
    return StaffState(
      staff: staff ?? this.staff,
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [staff, status, message];
}

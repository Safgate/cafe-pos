part of 'staff_bloc.dart';

abstract class StaffEvent extends Equatable {
  const StaffEvent();
  @override
  List<Object?> get props => [];
}

class LoadStaff extends StaffEvent {}

class AddStaffMember extends StaffEvent {
  final String name;
  final String pin;
  final StaffRole role;

  const AddStaffMember({
    required this.name,
    required this.pin,
    required this.role,
  });

  @override
  List<Object?> get props => [name, pin, role];
}

class UpdateStaffMember extends StaffEvent {
  final Staff staff;

  /// Leave null to keep the existing PIN.
  final String? newPin;

  const UpdateStaffMember({required this.staff, this.newPin});

  @override
  List<Object?> get props => [staff, newPin];
}

class DeactivateStaffMember extends StaffEvent {
  final String id;
  const DeactivateStaffMember(this.id);
  @override
  List<Object?> get props => [id];
}

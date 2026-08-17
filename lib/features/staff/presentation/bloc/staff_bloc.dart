import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/pin_hasher.dart';
import '../../domain/entities/staff.dart';
import '../../domain/repositories/staff_repository.dart';

part 'staff_event.dart';
part 'staff_state.dart';

class StaffBloc extends Bloc<StaffEvent, StaffState> {
  final StaffRepository repository;

  StaffBloc({required this.repository}) : super(const StaffState()) {
    on<LoadStaff>(_onLoadStaff);
    on<AddStaffMember>(_onAddStaffMember);
    on<UpdateStaffMember>(_onUpdateStaffMember);
    on<DeactivateStaffMember>(_onDeactivateStaffMember);
  }

  Future<void> _onLoadStaff(LoadStaff event, Emitter<StaffState> emit) async {
    emit(state.copyWith(status: StaffStatus.loading, clearMessage: true));
    final result = await repository.getAllStaff();
    result.fold(
      (failure) => emit(state.copyWith(
          status: StaffStatus.error, message: failure.message)),
      (staff) =>
          emit(state.copyWith(status: StaffStatus.loaded, staff: staff)),
    );
  }

  Future<void> _onAddStaffMember(
      AddStaffMember event, Emitter<StaffState> emit) async {
    final nameTaken = state.staff.any((s) =>
        s.active && s.name.toLowerCase() == event.name.trim().toLowerCase());
    if (nameTaken) {
      emit(state.copyWith(
          status: StaffStatus.error,
          message: 'Someone with that name is already on the team.'));
      return;
    }

    final salt = PinHasher.generateSalt();
    final staff = Staff(
      id: const Uuid().v4(),
      name: event.name.trim(),
      role: event.role,
      pinHash: PinHasher.hash(event.pin, salt),
      pinSalt: salt,
      createdAt: DateTime.now(),
    );

    final result = await repository.addStaff(staff);
    await result.fold(
      (failure) async => emit(state.copyWith(
          status: StaffStatus.error, message: failure.message)),
      (_) async {
        emit(state.copyWith(
            status: StaffStatus.success, message: '${staff.name} added'));
        add(LoadStaff());
      },
    );
  }

  Future<void> _onUpdateStaffMember(
      UpdateStaffMember event, Emitter<StaffState> emit) async {
    var updated = event.staff;

    if (event.newPin != null && event.newPin!.isNotEmpty) {
      final salt = PinHasher.generateSalt();
      updated = updated.copyWith(
        pinSalt: salt,
        pinHash: PinHasher.hash(event.newPin!, salt),
      );
    }

    // Demoting the last owner would leave nobody able to manage the menu,
    // view reports, or void an order.
    if (event.staff.role != StaffRole.owner && _wouldRemoveLastOwner(event.staff.id)) {
      emit(state.copyWith(
          status: StaffStatus.error,
          message: 'You need at least one owner.'));
      return;
    }

    final result = await repository.updateStaff(updated);
    await result.fold(
      (failure) async => emit(state.copyWith(
          status: StaffStatus.error, message: failure.message)),
      (_) async {
        emit(state.copyWith(
            status: StaffStatus.success, message: '${updated.name} updated'));
        add(LoadStaff());
      },
    );
  }

  Future<void> _onDeactivateStaffMember(
      DeactivateStaffMember event, Emitter<StaffState> emit) async {
    if (_wouldRemoveLastOwner(event.id)) {
      emit(state.copyWith(
          status: StaffStatus.error,
          message: 'You need at least one active owner.'));
      return;
    }

    final result = await repository.deactivateStaff(event.id);
    await result.fold(
      (failure) async => emit(state.copyWith(
          status: StaffStatus.error, message: failure.message)),
      (_) async {
        emit(state.copyWith(
            status: StaffStatus.success, message: 'Staff member deactivated'));
        add(LoadStaff());
      },
    );
  }

  bool _wouldRemoveLastOwner(String staffId) {
    final activeOwners =
        state.staff.where((s) => s.active && s.role == StaffRole.owner);
    return activeOwners.length == 1 && activeOwners.first.id == staffId;
  }
}

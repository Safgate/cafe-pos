import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/activity_logger.dart';
import '../../../../core/session/current_session.dart';
import '../../../../core/utils/pin_hasher.dart';
import '../../../activity/domain/entities/activity_log.dart';
import '../../domain/entities/staff.dart';
import '../../domain/repositories/staff_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final StaffRepository repository;
  final ActivityLogger logger;

  AuthBloc({required this.repository, required this.logger})
      : super(const AuthState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthOwnerSetupRequested>(_onOwnerSetupRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthLockRequested>(_onLockRequested);
  }

  Future<void> _onCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    if (repository.isEmpty) {
      emit(state.copyWith(status: AuthStatus.needsSetup, activeStaff: const []));
      return;
    }

    final result = await repository.getActiveStaff();
    result.fold(
      (failure) => emit(state.copyWith(
          status: AuthStatus.loggedOut, error: failure.message)),
      (staff) => emit(state.copyWith(
          status: AuthStatus.loggedOut, activeStaff: staff, clearError: true)),
    );
  }

  Future<void> _onOwnerSetupRequested(
      AuthOwnerSetupRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isBusy: true, clearError: true));

    final salt = PinHasher.generateSalt();
    final owner = Staff(
      id: const Uuid().v4(),
      name: event.name.trim(),
      role: StaffRole.owner,
      pinHash: PinHasher.hash(event.pin, salt),
      pinSalt: salt,
      createdAt: DateTime.now(),
    );

    final result = await repository.addStaff(owner);
    await result.fold(
      (failure) async => emit(state.copyWith(
          isBusy: false, error: failure.message)),
      (_) async {
        CurrentSession.staff = owner;
        await logger.log(
          action: ActivityActions.authLogin,
          entityType: 'auth',
          entityId: owner.id,
          summary: '${owner.name} set up the shop and signed in',
        );
        emit(state.copyWith(
          status: AuthStatus.loggedIn,
          staff: owner,
          activeStaff: [owner],
          isBusy: false,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isBusy: true, clearError: true));

    final result = await repository.getById(event.staffId);

    await result.fold(
      (failure) async =>
          emit(state.copyWith(isBusy: false, error: failure.message)),
      (staff) async {
        if (staff == null || !staff.active) {
          emit(state.copyWith(
              isBusy: false, error: 'That account is no longer active.'));
          return;
        }

        final ok = PinHasher.verify(
          pin: event.pin,
          salt: staff.pinSalt,
          expectedHash: staff.pinHash,
        );

        if (!ok) {
          // Logged before the session is established, so it is attributed to
          // "System" — which is the honest description of who tried.
          await logger.log(
            action: ActivityActions.authLoginFailed,
            entityType: 'auth',
            entityId: staff.id,
            summary: 'Wrong PIN entered for ${staff.name}',
          );
          emit(state.copyWith(
            isBusy: false,
            error: 'Incorrect PIN.',
            failedAttempts: state.failedAttempts + 1,
          ));
          return;
        }

        CurrentSession.staff = staff;
        await logger.log(
          action: ActivityActions.authLogin,
          entityType: 'auth',
          entityId: staff.id,
          summary: '${staff.name} signed in',
        );

        emit(state.copyWith(
          status: AuthStatus.loggedIn,
          staff: staff,
          isBusy: false,
          failedAttempts: 0,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    final who = CurrentSession.staffName;
    await logger.log(
      action: ActivityActions.authLogout,
      entityType: 'auth',
      entityId: CurrentSession.staffId,
      summary: '$who signed out',
    );
    CurrentSession.clear();
    add(AuthCheckRequested());
    emit(state.copyWith(status: AuthStatus.loggedOut, clearStaff: true));
  }

  /// Locks the screen without writing a sign-out entry — the shift is not
  /// over, the phone just went idle.
  Future<void> _onLockRequested(
      AuthLockRequested event, Emitter<AuthState> emit) async {
    CurrentSession.clear();
    add(AuthCheckRequested());
    emit(state.copyWith(status: AuthStatus.loggedOut, clearStaff: true));
  }
}

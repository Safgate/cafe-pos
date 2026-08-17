part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Works out whether anyone exists yet, and refreshes the sign-in list.
class AuthCheckRequested extends AuthEvent {}

class AuthOwnerSetupRequested extends AuthEvent {
  final String name;
  final String pin;
  const AuthOwnerSetupRequested({required this.name, required this.pin});
  @override
  List<Object?> get props => [name, pin];
}

class AuthLoginRequested extends AuthEvent {
  final String staffId;
  final String pin;
  const AuthLoginRequested({required this.staffId, required this.pin});
  @override
  List<Object?> get props => [staffId, pin];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthLockRequested extends AuthEvent {}

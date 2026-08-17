part of 'auth_bloc.dart';

enum AuthStatus {
  /// Before the first check has run.
  unknown,

  /// Nobody has been set up — show the first-run wizard.
  needsSetup,

  /// Someone needs to pick their name and enter a PIN.
  loggedOut,

  loggedIn,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final Staff? staff;
  final List<Staff> activeStaff;
  final String? error;
  final bool isBusy;
  final int failedAttempts;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.staff,
    this.activeStaff = const [],
    this.error,
    this.isBusy = false,
    this.failedAttempts = 0,
  });

  bool get isLoggedIn => status == AuthStatus.loggedIn && staff != null;

  /// Permission helpers, so widgets read `authState.canViewReports` rather
  /// than digging into the role themselves.
  bool get canManageMenu => staff?.canManageMenu ?? false;
  bool get canManageStaff => staff?.canManageStaff ?? false;
  bool get canViewReports => staff?.canViewReports ?? false;
  bool get canViewActivityLog => staff?.canViewActivityLog ?? false;
  bool get canEditOrders => staff?.canEditOrders ?? false;
  bool get canVoidOrders => staff?.canVoidOrders ?? false;

  AuthState copyWith({
    AuthStatus? status,
    Staff? staff,
    bool clearStaff = false,
    List<Staff>? activeStaff,
    String? error,
    bool clearError = false,
    bool? isBusy,
    int? failedAttempts,
  }) {
    return AuthState(
      status: status ?? this.status,
      staff: clearStaff ? null : (staff ?? this.staff),
      activeStaff: activeStaff ?? this.activeStaff,
      error: clearError ? null : (error ?? this.error),
      isBusy: isBusy ?? this.isBusy,
      failedAttempts: failedAttempts ?? this.failedAttempts,
    );
  }

  @override
  List<Object?> get props =>
      [status, staff, activeStaff, error, isBusy, failedAttempts];
}

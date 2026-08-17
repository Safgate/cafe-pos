import '../../features/staff/domain/entities/staff.dart';

/// Who is signed in right now.
///
/// A mutable static is not elegant, but the alternative is threading the
/// signed-in staff member through every use case and repository call purely so
/// the activity log can stamp a name on it. `AuthBloc` is the only writer;
/// everything else reads.
class CurrentSession {
  const CurrentSession._();

  static Staff? staff;

  static bool get isSignedIn => staff != null;

  static String get staffId => staff?.id ?? '';

  /// Actions taken before anyone signs in (startup pruning, first-run setup)
  /// are attributed to "System" rather than left blank.
  static String get staffName => staff?.name ?? 'System';

  static void clear() => staff = null;
}

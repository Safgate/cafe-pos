import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/staff.dart';

abstract class StaffRepository {
  /// Active staff only — the sign-in list.
  Future<Either<Failure, List<Staff>>> getActiveStaff();

  /// Everyone, including deactivated accounts, for the management screen.
  Future<Either<Failure, List<Staff>>> getAllStaff();

  Future<Either<Failure, Staff?>> getById(String id);

  Future<Either<Failure, void>> addStaff(Staff staff);

  Future<Either<Failure, void>> updateStaff(Staff staff);

  /// Deactivates rather than deletes, so historical attribution survives.
  Future<Either<Failure, void>> deactivateStaff(String id);

  /// True when nobody has been set up yet — triggers the first-run wizard.
  bool get isEmpty;
}

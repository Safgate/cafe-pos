import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/activity_logger.dart';
import '../../../activity/domain/entities/activity_log.dart';
import '../../domain/entities/staff.dart';
import '../../domain/repositories/staff_repository.dart';
import '../models/staff_model.dart';

class StaffRepositoryImpl implements StaffRepository {
  final ActivityLogger logger;

  StaffRepositoryImpl(this.logger);

  @override
  bool get isEmpty => HiveDatabase.staffBox.isEmpty;

  @override
  Future<Either<Failure, List<Staff>>> getActiveStaff() async {
    try {
      final staff = HiveDatabase.staffBox.values.where((s) => s.active).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return Right(staff);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Staff>>> getAllStaff() async {
    try {
      final staff = HiveDatabase.staffBox.values.toList()
        ..sort((a, b) {
          if (a.active != b.active) return a.active ? -1 : 1;
          return a.name.compareTo(b.name);
        });
      return Right(staff);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Staff?>> getById(String id) async {
    try {
      return Right(HiveDatabase.staffBox.get(id));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addStaff(Staff staff) async {
    try {
      await HiveDatabase.staffBox.put(staff.id, StaffModel.fromEntity(staff));
      await logger.log(
        action: ActivityActions.staffCreated,
        entityType: 'staff',
        entityId: staff.id,
        summary: 'Added ${staff.name} as ${staff.role.label}',
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateStaff(Staff staff) async {
    try {
      final before = HiveDatabase.staffBox.get(staff.id);
      await HiveDatabase.staffBox.put(staff.id, StaffModel.fromEntity(staff));

      final changes = <String>[];
      if (before != null) {
        if (before.name != staff.name) {
          changes.add('name ${before.name} to ${staff.name}');
        }
        if (before.role != staff.role) {
          changes.add('role ${before.role.label} to ${staff.role.label}');
        }
        if (before.pinHash != staff.pinHash) changes.add('PIN reset');
      }

      await logger.log(
        action: ActivityActions.staffUpdated,
        entityType: 'staff',
        entityId: staff.id,
        summary: 'Updated ${staff.name}',
        details: changes.join('; '),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deactivateStaff(String id) async {
    try {
      final existing = HiveDatabase.staffBox.get(id);
      if (existing == null) {
        return const Left(CacheFailure('That staff member no longer exists.'));
      }

      await HiveDatabase.staffBox.put(
        id,
        StaffModel.fromEntity(existing.copyWith(active: false)),
      );
      await logger.log(
        action: ActivityActions.staffDeactivated,
        entityType: 'staff',
        entityId: id,
        summary: 'Deactivated ${existing.name}',
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

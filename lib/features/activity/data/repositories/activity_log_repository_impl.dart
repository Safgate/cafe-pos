import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/activity_log.dart';
import '../../domain/repositories/activity_log_repository.dart';
import '../models/activity_log_model.dart';

class ActivityLogRepositoryImpl implements ActivityLogRepository {
  /// Unbounded logging on a phone is a slow leak, so entries expire.
  static const Duration retention = Duration(days: 180);
  static const int maxEntries = 10000;

  @override
  Future<Either<Failure, void>> record(ActivityLog entry) async {
    try {
      final box = HiveDatabase.activityLogBox;
      await box.put(entry.id, ActivityLogModel.fromEntity(entry));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ActivityLog>>> getLogs({
    DateTime? from,
    DateTime? to,
    String? staffId,
    String? action,
    int limit = 500,
  }) async {
    try {
      final box = HiveDatabase.activityLogBox;
      final logs = box.values.where((log) {
        if (from != null && log.timestamp.isBefore(from)) return false;
        if (to != null && !log.timestamp.isBefore(to)) return false;
        if (staffId != null &&
            staffId.isNotEmpty &&
            log.staffId != staffId) {
          return false;
        }
        if (action != null && action.isNotEmpty && log.action != action) {
          return false;
        }
        return true;
      }).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return Right(logs.take(limit).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> prune() async {
    try {
      final box = HiveDatabase.activityLogBox;
      final cutoff = DateTime.now().subtract(retention);

      final expiredKeys = box.keys
          .where((key) => box.get(key)!.timestamp.isBefore(cutoff))
          .toList();
      if (expiredKeys.isNotEmpty) await box.deleteAll(expiredKeys);

      var removed = expiredKeys.length;

      // Still over the cap? Drop the oldest remaining entries.
      if (box.length > maxEntries) {
        final sorted = box.keys.toList()
          ..sort((a, b) =>
              box.get(a)!.timestamp.compareTo(box.get(b)!.timestamp));
        final excess = sorted.take(box.length - maxEntries).toList();
        await box.deleteAll(excess);
        removed += excess.length;
      }

      return Right(removed);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

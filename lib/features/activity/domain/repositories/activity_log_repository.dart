import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/activity_log.dart';

abstract class ActivityLogRepository {
  Future<Either<Failure, void>> record(ActivityLog entry);

  /// Newest first. All filters are optional and combine with AND.
  Future<Either<Failure, List<ActivityLog>>> getLogs({
    DateTime? from,
    DateTime? to,
    String? staffId,
    String? action,
    int limit = 500,
  });

  /// Drops entries past the retention window and trims the box back to its
  /// cap. Called once on startup.
  Future<Either<Failure, int>> prune();
}

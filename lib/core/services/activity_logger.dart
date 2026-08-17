import 'package:uuid/uuid.dart';

import '../../features/activity/domain/entities/activity_log.dart';
import '../../features/activity/domain/repositories/activity_log_repository.dart';
import '../session/current_session.dart';

/// Writes activity entries, stamping each with whoever is signed in.
///
/// Repository implementations call this immediately after a successful
/// mutation — that is the one place every data change in the app passes
/// through. Actions that do not touch a repository (signing in, connecting a
/// printer, exporting a report) log explicitly from their bloc.
class ActivityLogger {
  final ActivityLogRepository repository;
  final Uuid _uuid;

  ActivityLogger(this.repository, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  Future<void> log({
    required String action,
    required String entityType,
    required String summary,
    String entityId = '',
    String details = '',
  }) async {
    // Logging must never take down the action it is recording.
    try {
      await repository.record(ActivityLog(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        staffId: CurrentSession.staffId,
        staffName: CurrentSession.staffName,
        action: action,
        entityType: entityType,
        entityId: entityId,
        summary: summary,
        details: details,
      ));
    } catch (_) {
      // Swallowed deliberately.
    }
  }
}

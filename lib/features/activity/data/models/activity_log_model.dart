import 'package:hive/hive.dart';
import '../../domain/entities/activity_log.dart';

part 'activity_log_model.g.dart';

@HiveType(typeId: 7)
class ActivityLogModel extends ActivityLog {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final DateTime timestamp;
  @override
  @HiveField(2)
  final String staffId;
  @override
  @HiveField(3)
  final String staffName;
  @override
  @HiveField(4)
  final String action;
  @override
  @HiveField(5)
  final String entityType;
  @override
  @HiveField(6)
  final String entityId;
  @override
  @HiveField(7)
  final String summary;
  @override
  @HiveField(8)
  final String details;

  const ActivityLogModel({
    required this.id,
    required this.timestamp,
    required this.staffId,
    required this.staffName,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.summary,
    required this.details,
  }) : super(
          id: id,
          timestamp: timestamp,
          staffId: staffId,
          staffName: staffName,
          action: action,
          entityType: entityType,
          entityId: entityId,
          summary: summary,
          details: details,
        );

  factory ActivityLogModel.fromEntity(ActivityLog log) {
    return ActivityLogModel(
      id: log.id,
      timestamp: log.timestamp,
      staffId: log.staffId,
      staffName: log.staffName,
      action: log.action,
      entityType: log.entityType,
      entityId: log.entityId,
      summary: log.summary,
      details: log.details,
    );
  }

  ActivityLog toEntity() => this;
}

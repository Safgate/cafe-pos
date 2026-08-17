import 'package:hive/hive.dart';
import '../../domain/entities/staff.dart';

part 'staff_model.g.dart';

@HiveType(typeId: 6)
class StaffModel extends Staff {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String name;

  /// Role persisted as its enum name, so adding a role later does not need a
  /// new type adapter.
  @HiveField(2)
  final String roleName;

  @override
  @HiveField(3)
  final String pinHash;
  @override
  @HiveField(4)
  final String pinSalt;
  @override
  @HiveField(5)
  final bool active;
  @override
  @HiveField(6)
  final DateTime createdAt;

  StaffModel({
    required this.id,
    required this.name,
    required this.roleName,
    required this.pinHash,
    required this.pinSalt,
    required this.active,
    required this.createdAt,
  }) : super(
          id: id,
          name: name,
          role: staffRoleFromName(roleName),
          pinHash: pinHash,
          pinSalt: pinSalt,
          active: active,
          createdAt: createdAt,
        );

  factory StaffModel.fromEntity(Staff staff) {
    return StaffModel(
      id: staff.id,
      name: staff.name,
      roleName: staff.role.name,
      pinHash: staff.pinHash,
      pinSalt: staff.pinSalt,
      active: staff.active,
      createdAt: staff.createdAt,
    );
  }

  Staff toEntity() => this;
}

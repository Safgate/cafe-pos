import 'package:equatable/equatable.dart';

enum StaffRole { owner, cashier }

StaffRole staffRoleFromName(String name) {
  return StaffRole.values.firstWhere(
    (r) => r.name == name,
    orElse: () => StaffRole.cashier,
  );
}

extension StaffRoleLabel on StaffRole {
  String get label => this == StaffRole.owner ? 'Owner' : 'Cashier';
}

class Staff extends Equatable {
  final String id;
  final String name;
  final StaffRole role;
  final String pinHash;
  final String pinSalt;

  /// Staff are deactivated rather than deleted, so past orders keep a real
  /// name against them.
  final bool active;

  final DateTime createdAt;

  const Staff({
    required this.id,
    required this.name,
    required this.role,
    required this.pinHash,
    required this.pinSalt,
    this.active = true,
    required this.createdAt,
  });

  bool get isOwner => role == StaffRole.owner;

  // Permissions. Cashiers ring up orders and log expenses; everything that
  // rewrites history or exposes the books is Owner-only.
  bool get canManageMenu => isOwner;
  bool get canManageStaff => isOwner;
  bool get canViewReports => isOwner;
  bool get canViewActivityLog => isOwner;
  bool get canEditOrders => isOwner;
  bool get canVoidOrders => isOwner;

  Staff copyWith({
    String? name,
    StaffRole? role,
    String? pinHash,
    String? pinSalt,
    bool? active,
  }) {
    return Staff(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      pinHash: pinHash ?? this.pinHash,
      pinSalt: pinSalt ?? this.pinSalt,
      active: active ?? this.active,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, role, pinHash, pinSalt, active, createdAt];
}

import 'package:equatable/equatable.dart';

/// Every action anyone takes, append-only.
///
/// [staffName] is denormalized on purpose: deactivating a staff member must
/// never blank out who did what last month.
class ActivityLog extends Equatable {
  final String id;
  final DateTime timestamp;
  final String staffId;
  final String staffName;

  /// Dotted action key — see [ActivityActions].
  final String action;

  /// 'order' | 'item' | 'expense' | 'staff' | 'shop' | 'auth' | 'printer' | 'report'
  final String entityType;
  final String entityId;

  /// One line, written for a human reading the log.
  final String summary;

  /// Optional longer text — before/after values on an edit, for example.
  final String details;

  const ActivityLog({
    required this.id,
    required this.timestamp,
    required this.staffId,
    required this.staffName,
    required this.action,
    required this.entityType,
    this.entityId = '',
    required this.summary,
    this.details = '',
  });

  @override
  List<Object?> get props => [
        id,
        timestamp,
        staffId,
        staffName,
        action,
        entityType,
        entityId,
        summary,
        details,
      ];
}

/// The complete set of logged actions. Keep these stable — the log filter and
/// any later analysis key off them.
class ActivityActions {
  const ActivityActions._();

  static const orderCreated = 'order.created';
  static const orderEdited = 'order.edited';
  static const orderVoided = 'order.voided';
  static const orderReprinted = 'order.reprinted';

  static const itemCreated = 'item.created';
  static const itemUpdated = 'item.updated';
  static const itemDeleted = 'item.deleted';

  static const expenseCreated = 'expense.created';
  static const expenseDeleted = 'expense.deleted';

  static const staffCreated = 'staff.created';
  static const staffUpdated = 'staff.updated';
  static const staffDeactivated = 'staff.deactivated';

  static const shopUpdated = 'shop.updated';

  static const authLogin = 'auth.login';
  static const authLoginFailed = 'auth.login_failed';
  static const authLogout = 'auth.logout';

  static const printerConnected = 'printer.connected';

  static const reportPrinted = 'report.printed';
  static const reportExported = 'report.exported';

  static const all = <String>[
    orderCreated,
    orderEdited,
    orderVoided,
    orderReprinted,
    itemCreated,
    itemUpdated,
    itemDeleted,
    expenseCreated,
    expenseDeleted,
    staffCreated,
    staffUpdated,
    staffDeactivated,
    shopUpdated,
    authLogin,
    authLoginFailed,
    authLogout,
    printerConnected,
    reportPrinted,
    reportExported,
  ];

  /// Human label for the filter dropdown and the log list.
  static String label(String action) {
    switch (action) {
      case orderCreated:
        return 'Order taken';
      case orderEdited:
        return 'Order edited';
      case orderVoided:
        return 'Order voided';
      case orderReprinted:
        return 'Receipt reprinted';
      case itemCreated:
        return 'Menu item added';
      case itemUpdated:
        return 'Menu item changed';
      case itemDeleted:
        return 'Menu item deleted';
      case expenseCreated:
        return 'Expense logged';
      case expenseDeleted:
        return 'Expense deleted';
      case staffCreated:
        return 'Staff added';
      case staffUpdated:
        return 'Staff changed';
      case staffDeactivated:
        return 'Staff deactivated';
      case shopUpdated:
        return 'Shop details changed';
      case authLogin:
        return 'Signed in';
      case authLoginFailed:
        return 'Failed sign-in';
      case authLogout:
        return 'Signed out';
      case printerConnected:
        return 'Printer connected';
      case reportPrinted:
        return 'Report printed';
      case reportExported:
        return 'Report exported';
      default:
        return action;
    }
  }
}

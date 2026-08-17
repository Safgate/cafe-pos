import 'package:equatable/equatable.dart';
import 'order_line.dart';

/// A completed sale.
///
/// Orders are never destroyed. Deleting one marks it [voided] with a reason
/// and a timestamp: it drops out of every revenue figure but stays visible in
/// history and in the activity log. A sale that can vanish without trace is
/// how till fraud works, and it also destroys any ability to explain last
/// month's numbers.
class Order extends Equatable {
  final String id;

  /// Resets daily. Printed on the receipt so a customer can quote it.
  final int orderNumber;

  /// When the sale happened. Reports always bucket by this, never by
  /// [updatedAt] — editing a Tuesday order on Friday changes *Tuesday's*
  /// takings, which is correct, and is exactly why the activity log exists.
  final DateTime createdAt;

  final List<OrderLine> lines;

  /// The amount actually taken. Stored rather than recomputed so the figure
  /// can never drift from what the customer paid.
  final double total;

  final String createdByStaffId;

  /// Denormalized: deactivating a staff member must not blank out who rang
  /// up last week's sales.
  final String createdByStaffName;

  final DateTime? updatedAt;
  final int revision;
  final String lastEditedByStaffId;
  final String lastEditedByStaffName;

  final bool voided;
  final DateTime? voidedAt;
  final String voidedByStaffId;
  final String voidedByStaffName;
  final String voidReason;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
    required this.lines,
    required this.total,
    required this.createdByStaffId,
    required this.createdByStaffName,
    this.updatedAt,
    this.revision = 0,
    this.lastEditedByStaffId = '',
    this.lastEditedByStaffName = '',
    this.voided = false,
    this.voidedAt,
    this.voidedByStaffId = '',
    this.voidedByStaffName = '',
    this.voidReason = '',
  });

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);

  bool get wasEdited => revision > 0;

  /// Recomputed from the lines. Should equal [total]; useful as a sanity
  /// check after an edit.
  double get linesTotal =>
      lines.fold(0.0, (sum, line) => sum + line.lineTotal);

  Order copyWith({
    List<OrderLine>? lines,
    double? total,
    DateTime? updatedAt,
    int? revision,
    String? lastEditedByStaffId,
    String? lastEditedByStaffName,
    bool? voided,
    DateTime? voidedAt,
    String? voidedByStaffId,
    String? voidedByStaffName,
    String? voidReason,
  }) {
    return Order(
      id: id,
      orderNumber: orderNumber,
      createdAt: createdAt,
      lines: lines ?? this.lines,
      total: total ?? this.total,
      createdByStaffId: createdByStaffId,
      createdByStaffName: createdByStaffName,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
      lastEditedByStaffId: lastEditedByStaffId ?? this.lastEditedByStaffId,
      lastEditedByStaffName:
          lastEditedByStaffName ?? this.lastEditedByStaffName,
      voided: voided ?? this.voided,
      voidedAt: voidedAt ?? this.voidedAt,
      voidedByStaffId: voidedByStaffId ?? this.voidedByStaffId,
      voidedByStaffName: voidedByStaffName ?? this.voidedByStaffName,
      voidReason: voidReason ?? this.voidReason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        createdAt,
        lines,
        total,
        createdByStaffId,
        createdByStaffName,
        updatedAt,
        revision,
        lastEditedByStaffId,
        lastEditedByStaffName,
        voided,
        voidedAt,
        voidedByStaffId,
        voidedByStaffName,
        voidReason,
      ];
}

extension OrderIterableX on Iterable<Order> {
  /// **The single definition of which orders count as money taken.**
  ///
  /// The dashboard, the drill-downs, the Z-report and the PDF all go through
  /// this, so they cannot drift apart and start disagreeing about whether a
  /// voided sale counts.
  Iterable<Order> get counted => where((order) => !order.voided);

  Iterable<Order> get voidedOnly => where((order) => order.voided);

  double get revenue =>
      counted.fold(0.0, (sum, order) => sum + order.total);
}

import 'package:cafe_pos/features/orders/domain/entities/order.dart';
import 'package:cafe_pos/features/orders/domain/entities/order_line.dart';
import 'package:flutter_test/flutter_test.dart';

final _soldAt = DateTime(2026, 8, 11, 9, 15);

Order _order({
  List<OrderLine>? lines,
  bool voided = false,
  double? total,
}) {
  final actualLines = lines ??
      [
        const OrderLine(
          productId: 'latte',
          itemName: 'Latte',
          variantLabel: 'Large',
          unitPrice: 3.60,
          quantity: 2,
        ),
      ];
  return Order(
    id: 'order-1',
    orderNumber: 7,
    createdAt: _soldAt,
    lines: actualLines,
    total: total ?? actualLines.fold(0.0, (sum, l) => sum + l.lineTotal),
    createdByStaffId: 'staff-1',
    createdByStaffName: 'Sam',
    voided: voided,
  );
}

void main() {
  group('OrderLine', () {
    test('line total is the price sold at, times quantity', () {
      const line = OrderLine(
        productId: 'latte',
        itemName: 'Latte',
        unitPrice: 3.20,
        quantity: 3,
      );

      expect(line.lineTotal, closeTo(9.60, 0.001));
    });

    test('display name includes the size when there is one', () {
      const withSize = OrderLine(
        productId: 'latte',
        itemName: 'Latte',
        variantLabel: 'Large',
        unitPrice: 3.60,
        quantity: 1,
      );
      const withoutSize = OrderLine(
        productId: 'croissant',
        itemName: 'Croissant',
        unitPrice: 2.50,
        quantity: 1,
      );

      expect(withSize.displayName, 'Latte (Large)');
      expect(withoutSize.displayName, 'Croissant');
    });

    test('different sizes of one item are different report keys', () {
      const small = OrderLine(
        productId: 'latte',
        itemName: 'Latte',
        variantLabel: 'Small',
        unitPrice: 2.80,
        quantity: 1,
      );
      const large = OrderLine(
        productId: 'latte',
        itemName: 'Latte',
        variantLabel: 'Large',
        unitPrice: 3.60,
        quantity: 1,
      );

      expect(small.reportKey, isNot(equals(large.reportKey)));
    });
  });

  group('editing an order', () {
    test('keeps the original order number and sale time', () {
      final before = _order();

      final after = before.copyWith(
        lines: [
          ...before.lines,
          const OrderLine(
            productId: 'croissant',
            itemName: 'Croissant',
            unitPrice: 2.50,
            quantity: 1,
          ),
        ],
        total: 9.70,
        revision: before.revision + 1,
        updatedAt: DateTime(2026, 8, 14, 16, 0),
        lastEditedByStaffName: 'Alex',
      );

      // An edit revises a sale; it does not create a new one, and it must not
      // move the sale to the day it was corrected.
      expect(after.orderNumber, 7);
      expect(after.createdAt, _soldAt);
      expect(after.createdByStaffName, 'Sam');
      expect(after.revision, 1);
      expect(after.wasEdited, isTrue);
      expect(after.lastEditedByStaffName, 'Alex');
    });

    test('an unedited order does not claim to be edited', () {
      expect(_order().wasEdited, isFalse);
    });
  });

  group('voiding an order', () {
    test('keeps the record and its total intact', () {
      final voided = _order().copyWith(
        voided: true,
        voidedAt: DateTime(2026, 8, 11, 9, 20),
        voidedByStaffName: 'Sam',
        voidReason: 'customer cancelled',
      );

      expect(voided.total, closeTo(7.20, 0.001));
      expect(voided.lines, isNotEmpty);
      expect(voided.voidReason, 'customer cancelled');
    });
  });

  group('counted / revenue', () {
    test('counted drops voided orders', () {
      final orders = [_order(), _order(voided: true)];

      expect(orders.counted.length, 1);
      expect(orders.voidedOnly.length, 1);
    });

    test('revenue only adds up orders that stand', () {
      final orders = [
        _order(total: 10.00),
        _order(total: 999.00, voided: true),
      ];

      expect(orders.revenue, closeTo(10.00, 0.001));
    });

    test('revenue of an all-voided day is zero, not negative or null', () {
      final orders = [_order(voided: true), _order(voided: true)];

      expect(orders.revenue, 0);
    });
  });

  group('item count', () {
    test('sums quantities rather than counting lines', () {
      final order = _order(lines: [
        const OrderLine(
          productId: 'latte',
          itemName: 'Latte',
          unitPrice: 3.00,
          quantity: 2,
        ),
        const OrderLine(
          productId: 'croissant',
          itemName: 'Croissant',
          unitPrice: 2.50,
          quantity: 3,
        ),
      ]);

      expect(order.itemCount, 5);
      expect(order.linesTotal, closeTo(13.50, 0.001));
    });
  });
}

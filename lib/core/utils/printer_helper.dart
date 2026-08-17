import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/orders/domain/entities/order.dart';
import 'currency.dart';

class EscPos {
  static const List<int> init = [0x1B, 0x40];
  static const List<int> alignCenter = [0x1B, 0x61, 0x01];
  static const List<int> alignLeft = [0x1B, 0x61, 0x00];
  static const List<int> alignRight = [0x1B, 0x61, 0x02];
  static const List<int> boldOn = [0x1B, 0x45, 0x01];
  static const List<int> boldOff = [0x1B, 0x45, 0x00];
  static const List<int> textNormal = [0x1D, 0x21, 0x00];
  static const List<int> textLarge = [0x1D, 0x21, 0x11];
  static const List<int> lineFeed = [0x0A];
}

/// A single line of a top-selling / per-staff summary block.
class SummaryLine {
  final String label;
  final String value;
  const SummaryLine(this.label, this.value);
}

class PrinterHelper {
  // Singleton
  static final PrinterHelper _instance = PrinterHelper._internal();
  factory PrinterHelper() => _instance;
  PrinterHelper._internal();

  /// Characters per line on a 58mm thermal roll at the default font.
  static const int lineWidth = 32;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<bool> checkPermission() async {
    // Android 12+ needs BLUETOOTH_SCAN / BLUETOOTH_CONNECT; older Android
    // needs BLUETOOTH, BLUETOOTH_ADMIN and fine location.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<List<BluetoothInfo>> getBondedDevices() async {
    try {
      return await PrintBluetoothThermal.pairedBluetooths;
    } catch (e) {
      return [];
    }
  }

  Future<bool> connect(String macAddress) async {
    try {
      final bool result =
          await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      _isConnected = result;
      return result;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      final bool result = await PrintBluetoothThermal.disconnect;
      _isConnected = !result;
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Raw text, used by the printer test page.
  Future<void> printText(String text) async {
    if (!_isConnected) return;
    if (!await PrintBluetoothThermal.connectionStatus) return;

    await PrintBluetoothThermal.writeBytes(
        EscPos.init + _textToBytes(text) + EscPos.lineFeed);
  }

  /// Customer receipt for a completed order.
  ///
  /// [isReprint] stamps the copy so a reprint can never be passed off as a
  /// second sale.
  Future<void> printReceipt({
    required String shopName,
    required String address1,
    required String address2,
    required String phone,
    required String footer,
    required Order order,
    bool isReprint = false,
  }) async {
    if (!_isConnected) return;

    final symbol = currencySymbol();
    List<int> bytes = [];

    bytes += EscPos.init;

    // Header
    bytes += EscPos.alignCenter;
    bytes += EscPos.boldOn;
    bytes += EscPos.textLarge;
    bytes += _textToBytes(shopName);
    bytes += EscPos.lineFeed;

    bytes += EscPos.textNormal;
    bytes += EscPos.boldOff;
    for (final line in [address1, address2, phone]) {
      if (line.isNotEmpty) {
        bytes += _textToBytes(line);
        bytes += EscPos.lineFeed;
      }
    }

    if (isReprint) {
      bytes += EscPos.boldOn;
      bytes += _textToBytes('** REPRINT **');
      bytes += EscPos.lineFeed;
      bytes += EscPos.boldOff;
    }
    if (order.voided) {
      bytes += EscPos.boldOn;
      bytes += _textToBytes('** VOIDED **');
      bytes += EscPos.lineFeed;
      bytes += EscPos.boldOff;
    }

    bytes += EscPos.alignLeft;
    bytes += _textToBytes(_divider());
    bytes += EscPos.lineFeed;

    bytes += _textToBytes(_row(
      'Order #${order.orderNumber}',
      DateFormat('dd-MM-yyyy HH:mm').format(order.createdAt),
    ));
    bytes += EscPos.lineFeed;
    bytes += _textToBytes('Served by ${order.createdByStaffName}');
    bytes += EscPos.lineFeed;
    bytes += _textToBytes(_divider());
    bytes += EscPos.lineFeed;

    // Items. The item column is wide because names now carry a size suffix
    // ("Latte (Large)"); the old 16-char cut truncated most of them.
    for (final line in order.lines) {
      bytes += _textToBytes(_row(
        '${line.quantity}x ${line.displayName}',
        amountOnly(line.lineTotal),
        leftMax: lineWidth - 9,
      ));
      bytes += EscPos.lineFeed;

      // Unit price only matters when more than one was sold.
      if (line.quantity > 1) {
        bytes += _textToBytes('   @ ${amountOnly(line.unitPrice)} each');
        bytes += EscPos.lineFeed;
      }
    }

    bytes += _textToBytes(_divider());
    bytes += EscPos.lineFeed;

    bytes += EscPos.boldOn;
    bytes += _textToBytes(_row('TOTAL', '$symbol${amountOnly(order.total)}'));
    bytes += EscPos.lineFeed;
    bytes += EscPos.boldOff;
    bytes += EscPos.lineFeed;

    if (footer.isNotEmpty) {
      bytes += EscPos.alignCenter;
      bytes += _textToBytes(footer);
      bytes += EscPos.lineFeed;
    }
    bytes += EscPos.lineFeed;
    bytes += EscPos.lineFeed;
    bytes += EscPos.lineFeed;

    await PrintBluetoothThermal.writeBytes(bytes);
  }

  /// End-of-day (Z-report) summary for a period.
  Future<void> printDailySummary({
    required String shopName,
    required String periodLabel,
    required double revenue,
    required double expenses,
    required double profit,
    required int orderCount,
    required double averageOrderValue,
    required int voidedCount,
    required double voidedValue,
    required List<SummaryLine> topItems,
    required List<SummaryLine> perStaff,
  }) async {
    if (!_isConnected) return;

    final symbol = currencySymbol();
    List<int> bytes = [];

    bytes += EscPos.init;
    bytes += EscPos.alignCenter;
    bytes += EscPos.boldOn;
    bytes += EscPos.textLarge;
    bytes += _textToBytes(shopName);
    bytes += EscPos.lineFeed;
    bytes += EscPos.textNormal;
    bytes += _textToBytes('SALES SUMMARY');
    bytes += EscPos.lineFeed;
    bytes += EscPos.boldOff;
    bytes += _textToBytes(periodLabel);
    bytes += EscPos.lineFeed;
    bytes += _textToBytes(
        'Printed ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}');
    bytes += EscPos.lineFeed;

    bytes += EscPos.alignLeft;
    bytes += _textToBytes(_divider());
    bytes += EscPos.lineFeed;

    bytes += _textToBytes(_row('Orders', '$orderCount'));
    bytes += EscPos.lineFeed;
    bytes += _textToBytes(
        _row('Average order', '$symbol${amountOnly(averageOrderValue)}'));
    bytes += EscPos.lineFeed;
    bytes += _textToBytes(_divider());
    bytes += EscPos.lineFeed;

    bytes += EscPos.boldOn;
    bytes += _textToBytes(_row('REVENUE', '$symbol${amountOnly(revenue)}'));
    bytes += EscPos.lineFeed;
    bytes += EscPos.boldOff;
    bytes += _textToBytes(_row('Expenses', '-$symbol${amountOnly(expenses)}'));
    bytes += EscPos.lineFeed;
    bytes += EscPos.boldOn;
    bytes += _textToBytes(_row('PROFIT', '$symbol${amountOnly(profit)}'));
    bytes += EscPos.lineFeed;
    bytes += EscPos.boldOff;

    // Voids are printed, never hidden — a rising void count is exactly the
    // thing an owner needs to notice.
    bytes += _textToBytes(_divider());
    bytes += EscPos.lineFeed;
    bytes += _textToBytes(
        _row('Voided orders', '$voidedCount ($symbol${amountOnly(voidedValue)})'));
    bytes += EscPos.lineFeed;

    if (topItems.isNotEmpty) {
      bytes += _textToBytes(_divider());
      bytes += EscPos.lineFeed;
      bytes += EscPos.boldOn;
      bytes += _textToBytes('TOP ITEMS');
      bytes += EscPos.lineFeed;
      bytes += EscPos.boldOff;
      for (final item in topItems) {
        bytes += _textToBytes(_row(item.label, item.value));
        bytes += EscPos.lineFeed;
      }
    }

    if (perStaff.isNotEmpty) {
      bytes += _textToBytes(_divider());
      bytes += EscPos.lineFeed;
      bytes += EscPos.boldOn;
      bytes += _textToBytes('BY STAFF');
      bytes += EscPos.lineFeed;
      bytes += EscPos.boldOff;
      for (final staff in perStaff) {
        bytes += _textToBytes(_row(staff.label, staff.value));
        bytes += EscPos.lineFeed;
      }
    }

    bytes += EscPos.lineFeed;
    bytes += EscPos.lineFeed;
    bytes += EscPos.lineFeed;

    await PrintBluetoothThermal.writeBytes(bytes);
  }

  static String _divider() => '-' * lineWidth;

  /// Left text, right text, padded to fill one line. [leftMax] truncates the
  /// left side when it would otherwise collide with the right.
  static String _row(String left, String right, {int? leftMax}) {
    final limit = leftMax ?? (lineWidth - right.length - 1);
    var l = left;
    if (l.length > limit) l = l.substring(0, limit);
    final gap = lineWidth - l.length - right.length;
    return gap > 0 ? l + ' ' * gap + right : '$l $right';
  }

  List<int> _textToBytes(String text) {
    // Latin-1 covers the ASCII these printers reliably render. Currency
    // symbols outside it (₹, €) can come out as noise on cheap printers — the
    // totals line prints the symbol, the item rows deliberately do not.
    return List.from(text.codeUnits);
  }
}

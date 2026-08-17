import 'package:printing/printing.dart';

import '../../../core/data/hive_database.dart';
import '../../../core/services/activity_logger.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/printer_helper.dart';
import '../../activity/domain/entities/activity_log.dart';
import '../../expenses/domain/entities/expense.dart';
import '../../expenses/domain/repositories/expense_repository.dart';
import '../../orders/domain/entities/order.dart';
import '../../orders/domain/repositories/order_repository.dart';
import '../../shop/domain/entities/shop.dart';
import '../domain/entities/report_summary.dart';
import 'pdf_report_builder.dart';

class ExportResult {
  final bool success;
  final String message;
  const ExportResult(this.success, this.message);
}

/// Gets a report out of the app: onto a thermal roll, or into a PDF handed to
/// the system share sheet.
class ReportExporter {
  final OrderRepository orderRepository;
  final ExpenseRepository expenseRepository;
  final ActivityLogger logger;
  final PrinterHelper printer;

  ReportExporter({
    required this.orderRepository,
    required this.expenseRepository,
    required this.logger,
    PrinterHelper? printer,
  }) : printer = printer ?? PrinterHelper();

  /// End-of-day summary on the Bluetooth thermal printer.
  Future<ExportResult> printSummary({
    required ReportSummary summary,
    required Shop shop,
  }) async {
    if (!printer.isConnected) {
      final savedMac = HiveDatabase.settingsBox.get('printer_mac');
      if (savedMac == null || !await printer.connect(savedMac as String)) {
        return const ExportResult(
            false, 'No printer connected. Pair one under More > Printer.');
      }
    }

    try {
      await printer.printDailySummary(
        shopName: shop.name,
        periodLabel: summary.range.label,
        revenue: summary.revenue,
        expenses: summary.expenses,
        profit: summary.profit,
        orderCount: summary.orderCount,
        averageOrderValue: summary.averageOrderValue,
        voidedCount: summary.voidedCount,
        voidedValue: summary.voidedValue,
        topItems: summary.topItems
            .take(5)
            .map((i) => SummaryLine(i.name, '${i.quantity}'))
            .toList(),
        perStaff: summary.perStaff
            .map((s) => SummaryLine(s.staffName, money(s.revenue)))
            .toList(),
      );

      await logger.log(
        action: ActivityActions.reportPrinted,
        entityType: 'report',
        summary: 'Printed ${summary.range.label} summary — '
            'revenue ${money(summary.revenue)}',
      );
      return const ExportResult(true, 'Summary sent to printer');
    } catch (e) {
      return ExportResult(false, 'Printing failed: $e');
    }
  }

  /// Builds the PDF and opens the system share sheet, which covers saving,
  /// emailing and messaging without a separate dependency for each.
  Future<ExportResult> sharePdf({
    required ReportSummary summary,
    required Shop shop,
  }) async {
    try {
      final ordersResult = await orderRepository.getOrdersInRange(
          summary.range.from, summary.range.to);
      final expensesResult = await expenseRepository.getExpensesInRange(
          summary.range.from, summary.range.to);

      final orders = ordersResult.getOrElse((_) => <Order>[]);
      final expenses = expensesResult.getOrElse((_) => <Expense>[]);

      final bytes = await PdfReportBuilder.build(
        summary: summary,
        shop: shop,
        orders: orders,
        expenses: expenses,
      );

      final filename = 'sales-report-'
          '${summary.range.from.toIso8601String().substring(0, 10)}.pdf';

      await Printing.sharePdf(bytes: bytes, filename: filename);

      await logger.log(
        action: ActivityActions.reportExported,
        entityType: 'report',
        summary: 'Exported ${summary.range.label} PDF — '
            'revenue ${money(summary.revenue)}',
      );
      return const ExportResult(true, 'Report ready to share');
    } catch (e) {
      return ExportResult(false, 'Could not build the PDF: $e');
    }
  }
}

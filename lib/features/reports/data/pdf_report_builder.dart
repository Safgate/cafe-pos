import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/currency.dart';
import '../../expenses/domain/entities/expense.dart';
import '../../orders/domain/entities/order.dart';
import '../../shop/domain/entities/shop.dart';
import '../domain/entities/report_summary.dart';

/// Builds the PDF sales report.
///
/// Known limitation: this uses the PDF standard fonts, which cover Latin-1
/// only. A `$`, `£` or `€` symbol renders correctly; `₹` and other non-Latin
/// symbols will not. Shops using those should read the figures on screen or
/// print the thermal summary instead.
class PdfReportBuilder {
  const PdfReportBuilder._();

  static Future<Uint8List> build({
    required ReportSummary summary,
    required Shop shop,
    required List<Order> orders,
    required List<Expense> expenses,
  }) async {
    final doc = pw.Document();
    final dateFormat = DateFormat('d MMM yyyy');
    final periodLabel = '${summary.range.label} · '
        '${dateFormat.format(summary.range.from)} – '
        '${dateFormat.format(summary.range.to.subtract(const Duration(days: 1)))}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _header(shop, periodLabel),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          _headlineFigures(summary),
          pw.SizedBox(height: 20),
          _dailyTable(summary),
          pw.SizedBox(height: 20),
          if (summary.topItems.isNotEmpty) ...[
            _topItemsTable(summary),
            pw.SizedBox(height: 20),
          ],
          if (summary.perStaff.isNotEmpty) ...[
            _staffTable(summary),
            pw.SizedBox(height: 20),
          ],
          if (expenses.isNotEmpty) ...[
            _expensesTable(expenses),
            pw.SizedBox(height: 20),
          ],
          _ordersTable(orders),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _header(Shop shop, String periodLabel) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(shop.name,
                  style: const pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              if (shop.addressLine1.isNotEmpty)
                pw.Text(shop.addressLine1,
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Sales Report',
                  style: const pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(periodLabel,
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _headlineFigures(ReportSummary summary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            _figureBox('Revenue', money(summary.revenue), PdfColors.green700),
            pw.SizedBox(width: 12),
            _figureBox('Expenses', money(summary.expenses), PdfColors.red700),
            pw.SizedBox(width: 12),
            _figureBox(
              'Profit',
              money(summary.profit),
              summary.profit >= 0 ? PdfColors.blue800 : PdfColors.red700,
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          '${summary.orderCount} orders · '
          'average ${money(summary.averageOrderValue)} · '
          '${summary.voidedCount} voided (${money(summary.voidedValue)})',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _figureBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label.toUpperCase(),
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _section(String title, List<List<String>> rows,
      List<String> headers) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: const pw.TextStyle(
                fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: rows,
          headerStyle: const pw.TextStyle(
              fontSize: 9, fontWeight: pw.FontWeight.bold),
          headerDecoration:
              const pw.BoxDecoration(color: PdfColors.grey200),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            for (var i = 1; i < headers.length; i++)
              i: pw.Alignment.centerRight,
          },
        ),
      ],
    );
  }

  static pw.Widget _dailyTable(ReportSummary summary) {
    final format = DateFormat('EEE d MMM');
    return _section(
      'Daily breakdown',
      summary.buckets
          .map((b) => [
                format.format(b.day),
                '${b.orderCount}',
                money(b.revenue),
                money(b.expenses),
                money(b.profit),
              ])
          .toList(),
      ['Day', 'Orders', 'Revenue', 'Expenses', 'Profit'],
    );
  }

  static pw.Widget _topItemsTable(ReportSummary summary) {
    return _section(
      'Top items',
      summary.topItems
          .take(20)
          .map((i) => [i.name, '${i.quantity}', money(i.revenue)])
          .toList(),
      ['Item', 'Sold', 'Revenue'],
    );
  }

  static pw.Widget _staffTable(ReportSummary summary) {
    return _section(
      'By staff',
      summary.perStaff
          .map((s) => [s.staffName, '${s.orderCount}', money(s.revenue)])
          .toList(),
      ['Staff', 'Orders', 'Revenue'],
    );
  }

  static pw.Widget _expensesTable(List<Expense> expenses) {
    final format = DateFormat('d MMM');
    return _section(
      'Expenses',
      expenses
          .map((e) => [
                format.format(e.createdAt),
                e.category,
                e.note,
                money(e.amount),
              ])
          .toList(),
      ['Date', 'Category', 'Note', 'Amount'],
    );
  }

  static pw.Widget _ordersTable(List<Order> orders) {
    final format = DateFormat('d MMM HH:mm');
    return _section(
      'Orders',
      orders
          .map((o) => [
                '#${o.orderNumber}',
                format.format(o.createdAt),
                o.createdByStaffName,
                '${o.itemCount}',
                o.voided ? 'VOID' : '',
                money(o.total),
              ])
          .toList(),
      ['Order', 'Time', 'Staff', 'Items', 'Status', 'Total'],
    );
  }
}

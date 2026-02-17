import 'package:intl/intl.dart';

import '../models/data_models.dart';

/// Builds list of unique months from reports, sorted newest first
List<String> buildMonthOptions(List<Report> reports) {
  final months = reports
      .map((report) => report.monthLabel)
      .whereType<String>()
      .toSet()
      .toList();
  months.sort((a, b) {
    final aDate = DateFormat('MMMM yyyy').parse(a);
    final bDate = DateFormat('MMMM yyyy').parse(b);
    return bDate.compareTo(aDate);
  });
  return months;
}

/// Formats date range into human-readable label
String formatDateRangeLabel(DateTime? startDate, DateTime? endDate) {
  final formatter = DateFormat('MMM d');
  if (startDate == null && endDate == null) {
    return 'Date range';
  }
  if (startDate != null && endDate != null) {
    return '${formatter.format(startDate)} - ${formatter.format(endDate)}';
  }
  if (startDate != null) {
    return 'From ${formatter.format(startDate)}';
  }
  return 'To ${formatter.format(endDate!)}';
}

/// Calculates summary statistics for filtered reports
ReportSummary calculateSummary(List<Report> reports) {
  return ReportSummary(
    count: reports.length,
    totalAmount: reports.fold(0, (sum, report) => sum + report.amount),
    totalInvoiceAmount:
        reports.fold(0, (sum, report) => sum + report.invoiceTotal),
  );
}

/// Summary statistics for reports
class ReportSummary {
  const ReportSummary({
    required this.count,
    required this.totalAmount,
    required this.totalInvoiceAmount,
  });

  final int count;
  final double totalAmount;
  final double totalInvoiceAmount;
}

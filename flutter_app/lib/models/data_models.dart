import 'package:intl/intl.dart';

/// Represents a stylist with secure token access
class Stylist {
  const Stylist({required this.name, required this.token});

  final String name;
  final String token;

  factory Stylist.fromJson(Map<String, dynamic> json) {
    return Stylist(
      name: (json['name'] ?? '').toString(),
      token: (json['token'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'token': token,
    };
  }
}

/// Represents a consolidated invoice report
class Report {
  Report({
    required this.rawDate,
    required this.invoiceNumber,
    required this.stylist,
    required this.customerName,
    required this.amount,
    required this.invoiceTotal,
  }) {
    dateValue = _parseDate(rawDate);
    monthLabel = dateValue == null
        ? null
        : DateFormat('MMMM yyyy').format(dateValue!);
  }

  final String rawDate;
  final String invoiceNumber;
  final String stylist;
  final String customerName;
  final double amount;
  final double invoiceTotal;
  late DateTime? dateValue;
  late String? monthLabel;

  String get formattedDate {
    if (dateValue == null) {
      return rawDate;
    }
    return DateFormat('yyyy-MM-dd').format(dateValue!);
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      rawDate: (json['date'] ?? '').toString(),
      invoiceNumber: (json['invoiceNumber'] ?? '').toString(),
      stylist: (json['stylist'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      invoiceTotal: (json['invoiceTotal'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': rawDate,
      'invoiceNumber': invoiceNumber,
      'stylist': stylist,
      'customerName': customerName,
      'amount': amount,
      'invoiceTotal': invoiceTotal,
    };
  }
}

/// Container for cached API payload with sync metadata
class CachedPayload {
  const CachedPayload({
    required this.stylists,
    required this.reports,
    required this.lastSync,
  });

  final List<Stylist> stylists;
  final List<Report> reports;
  final DateTime? lastSync;
}

/// Parses various date formats into DateTime
DateTime? _parseDate(String raw) {
  if (raw.isEmpty) {
    return null;
  }

  final direct = DateTime.tryParse(raw);
  if (direct != null) {
    return direct;
  }

  final cleaned = raw.replaceFirst(RegExp(r'GMT.*$'), '').trim();
  for (final format in [
    DateFormat('EEE MMM dd yyyy HH:mm:ss'),
    DateFormat('EEE MMM dd yyyy'),
  ]) {
    try {
      return format.parse(cleaned);
    } catch (_) {}
  }

  return null;
}

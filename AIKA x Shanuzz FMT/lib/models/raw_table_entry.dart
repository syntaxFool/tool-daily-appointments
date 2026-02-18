class RawTableEntry {
  final String reffid;
  final String date;
  final String month;
  final double amount;
  final String modeOfPayment;
  final String rowDesc;
  final String rowNote;
  final String entryTimestamp;
  final String entryUser;
  final String editTimestamp;
  final String editUser;

  RawTableEntry({
    required this.reffid,
    required this.date,
    required this.month,
    required this.amount,
    required this.modeOfPayment,
    required this.rowDesc,
    required this.rowNote,
    required this.entryTimestamp,
    required this.entryUser,
    required this.editTimestamp,
    required this.editUser,
  });

  factory RawTableEntry.fromJson(Map<String, dynamic> json) {
    return RawTableEntry(
      reffid: json['Reffid'] ?? '',
      date: json['Date'] ?? '',
      month: json['Month'] ?? '',
      amount: double.tryParse(json['Amount']?.toString() ?? '0') ?? 0.0,
      modeOfPayment: json['Mode Of Payment'] ?? '',
      rowDesc: json['Row Desc'] ?? '',
      rowNote: json['Row Note'] ?? '',
      entryTimestamp: json['Entry Timestamp'] ?? '',
      entryUser: json['Entry User'] ?? '',
      editTimestamp: json['Edit Timestamp'] ?? '',
      editUser: json['Edit User'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Reffid': reffid,
      'Date': date,
      'Month': month,
      'Amount': amount,
      'Mode Of Payment': modeOfPayment,
      'Row Desc': rowDesc,
      'Row Note': rowNote,
      'Entry Timestamp': entryTimestamp,
      'Entry User': entryUser,
      'Edit Timestamp': editTimestamp,
      'Edit User': editUser,
    };
  }

  RawTableEntry copyWith({
    String? reffid,
    String? date,
    String? month,
    double? amount,
    String? modeOfPayment,
    String? rowDesc,
    String? rowNote,
    String? entryTimestamp,
    String? entryUser,
    String? editTimestamp,
    String? editUser,
  }) {
    return RawTableEntry(
      reffid: reffid ?? this.reffid,
      date: date ?? this.date,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      modeOfPayment: modeOfPayment ?? this.modeOfPayment,
      rowDesc: rowDesc ?? this.rowDesc,
      rowNote: rowNote ?? this.rowNote,
      entryTimestamp: entryTimestamp ?? this.entryTimestamp,
      entryUser: entryUser ?? this.entryUser,
      editTimestamp: editTimestamp ?? this.editTimestamp,
      editUser: editUser ?? this.editUser,
    );
  }
}

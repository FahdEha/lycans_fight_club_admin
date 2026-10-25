class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String userId;
  final String playerName;
  final String packageName;
  final double amount;
  final String paymentMethod;
  final String staffName;
  final DateTime date;
  final bool isPaid;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.userId,
    required this.playerName,
    required this.packageName,
    required this.amount,
    this.paymentMethod = 'Cash',
    this.staffName = '',
    required this.date,
    this.isPaid = true,
  });

  // Reports için uyumluluk getter'ı
  // Eğer description boşsa packageName döner
  String get description => packageName;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'userId': userId,
      'playerName': playerName,
      'packageName': packageName,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'staffName': staffName,
      'date': date.toIso8601String(),
      'isPaid': isPaid,
    };
  }

  factory InvoiceModel.fromMap(String id, Map<String, dynamic> map) {
    // packageName boşsa description'dan da okuyabiliriz (backward compat)
    final packageName = map['packageName']?.toString() ??
        map['description']?.toString() ??
        '';

    return InvoiceModel(
      id: id,
      invoiceNumber: map['invoiceNumber']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      playerName: map['playerName']?.toString() ?? '',
      packageName: packageName,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod']?.toString() ?? 'Cash',
      staffName: map['staffName']?.toString() ?? '',
      date: DateTime.parse(
        map['date']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      isPaid: map['isPaid'] != false,
    );
  }
}
class Debt {
  final String id;
  final String name;
  final double amount;
  final String currency;
  final String type; // 'Haqqim' or 'Qarzim'
  final String date;
  final String? reason;
  final String? phone;
  final bool isPaid;

  Debt({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.type,
    required this.date,
    this.reason,
    this.phone,
    this.isPaid = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'currency': currency,
      'type': type,
      'date': date,
      'reason': reason,
      'phone': phone,
      'isPaid': isPaid,
    };
  }

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'],
      name: json['name'],
      amount: json['amount'].toDouble(),
      currency: json['currency'],
      type: json['type'],
      date: json['date'],
      reason: json['reason'],
      phone: json['phone'],
      isPaid: json['isPaid'] ?? false,
    );
  }
}

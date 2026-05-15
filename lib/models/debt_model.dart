class Product {
  final String name;
  final double quantity;
  final double price;
  final String currency;

  Product({
    required this.name,
    required this.quantity,
    required this.price,
    this.currency = 'UZS',
  });

  Product copyWith({
    String? name,
    double? quantity,
    double? price,
    String? currency,
  }) {
    return Product(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      currency: currency ?? this.currency,
    );
  }

  double get total => quantity * price;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'currency': currency,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'],
      quantity: json['quantity'].toDouble(),
      price: json['price'].toDouble(),
      currency: json['currency'] ?? 'UZS',
    );
  }
}

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
  final List<Product>? products;
  final String? groupId; // New field for grouping mixed currency entries

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
    this.products,
    this.groupId,
  });

  Debt copyWith({
    String? id,
    String? name,
    double? amount,
    String? currency,
    String? type,
    String? date,
    String? reason,
    String? phone,
    bool? isPaid,
    List<Product>? products,
    String? groupId,
  }) {
    return Debt(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      date: date ?? this.date,
      reason: reason ?? this.reason,
      phone: phone ?? this.phone,
      isPaid: isPaid ?? this.isPaid,
      products: products ?? this.products,
      groupId: groupId ?? this.groupId,
    );
  }

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
      'products': products?.map((e) => e.toJson()).toList(),
      'groupId': groupId,
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
      products: json['products'] != null
          ? (json['products'] as List).map((e) => Product.fromJson(e)).toList()
          : null,
      groupId: json['groupId'],
    );
  }
}

class Order {
  final int id;
  final String orderNumber;
  final int? customerId;
  final int? tableId;
  final String orderType;
  final String status;
  final double subtotal;
  final double tax;
  final double serviceCharge;
  final double discount;
  final double total;
  final String? paymentMethod;
  final String paymentStatus;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderNumber,
    this.customerId,
    this.tableId,
    required this.orderType,
    required this.status,
    required this.subtotal,
    required this.tax,
    required this.serviceCharge,
    required this.discount,
    required this.total,
    this.paymentMethod,
    required this.paymentStatus,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: int.tryParse(json['id'].toString()) ?? 0,
      orderNumber: json['order_number'] ?? '',
      customerId: int.tryParse(json['customer_id']?.toString() ?? ''),
      tableId: int.tryParse(json['table_id'].toString()) ?? 0,
      orderType: json['order_type'] ?? 'dine-in',
      status: json['status'] ?? 'pending',
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
      tax: double.tryParse(json['tax'].toString()) ?? 0.0,
      serviceCharge: double.tryParse(json['service_charge'].toString()) ?? 0.0,
      discount: double.tryParse(json['discount'].toString()) ?? 0.0,
      total: double.tryParse(json['total_amount'].toString()) ??
          0.0, // FIX: column name is total_amount
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'] ?? 'unpaid',
      items: json['items'] != null
          ? (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList()
          : [],
    );
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final int menuItemId;
  final String menuName;
  final int quantity;
  final double price;
  final String? notes;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.menuName,
    required this.quantity,
    required this.price,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      orderId: int.tryParse(json['order_id'].toString()) ?? 0,
      menuItemId: int.tryParse(json['menu_item_id'].toString()) ?? 0,
      menuName: json['menu_name'] ?? '',
      quantity: int.tryParse(json['quantity'].toString()) ?? 0,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      notes: json['notes'],
    );
  }

  double get subtotal => quantity * price;
}

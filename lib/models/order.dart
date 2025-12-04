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
      id: json['id'],
      orderNumber: json['order_number'],
      customerId: json['customer_id'],
      tableId: json['table_id'],
      orderType: json['order_type'],
      status: json['status'],
      subtotal: double.parse(json['subtotal'].toString()),
      tax: double.parse(json['tax'].toString()),
      serviceCharge: double.parse(json['service_charge'].toString()),
      discount: double.parse(json['discount'].toString()),
      total: double.parse(json['total'].toString()),
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
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
      id: json['id'],
      orderId: json['order_id'],
      menuItemId: json['menu_item_id'],
      menuName: json['menu_name'] ?? '',
      quantity: json['quantity'],
      price: double.parse(json['price'].toString()),
      notes: json['notes'],
    );
  }
  
  double get subtotal => quantity * price;
}
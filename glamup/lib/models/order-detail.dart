class OrderDetail {
  final int id;
  final int userId;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String createdAt;
  
  // Address data
  final String? fullName;
  final String? phone;
  final String? addressLine;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  
  // Vendor data
  final int? vendorId;
  final String? vendorName;
  
  // Order items
  final List<OrderItem> items;

  OrderDetail({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    this.fullName,
    this.phone,
    this.addressLine,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.vendorId,
    this.vendorName,
    required this.items,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    List<OrderItem> orderItems = [];
    if (json['items'] != null) {
      orderItems = (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList();
    }

    return OrderDetail(
      id: int.parse(json['id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
      status: json['status'],
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      createdAt: json['created_at'],
      fullName: json['full_name'],
      phone: json['phone'],
      addressLine: json['address_line'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zip_code'],
      country: json['country'],
      vendorId: json['vendor_id'] != null ? int.parse(json['vendor_id'].toString()) : null,
      vendorName: json['vendor_name'],
      items: orderItems,
    );
  }

  String get formattedDate {
    DateTime dateTime = DateTime.parse(createdAt);
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  String get fullAddress {
    List<String> addressParts = [
      if (addressLine != null) addressLine!,
      if (city != null) city!,
      if (state != null) state!,
      if (zipCode != null) zipCode!,
      if (country != null) country!,
    ];
    return addressParts.join(', ');
  }
  
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return '#FFA000'; // Amber
      case 'processing':
        return '#1E88E5'; // Blue
      case 'shipped':
        return '#7B1FA2'; // Purple
      case 'delivered':
        return '#388E3C'; // Green
      case 'cancelled':
        return '#D32F2F'; // Red
      default:
        return '#757575'; // Grey
    }
  }
}

class OrderItem {
  final int id;
  final int productId;
  final int quantity;
  final double price;
  final String productName;
  final String? productImage;

  OrderItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.productName,
    this.productImage,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: int.parse(json['id'].toString()),
      productId: int.parse(json['product_id'].toString()),
      quantity: int.parse(json['quantity'].toString()),
      price: double.parse(json['price'].toString()),
      productName: json['product_name'],
      productImage: json['product_image'],
    );
  }
  
  double get subtotal => price * quantity;
}
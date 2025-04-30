class Order {
  final int id;
  final int userId;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String createdAt;
  final String? fullName;

  Order({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    this.fullName,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: int.parse(json['id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
      status: json['status'],
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      createdAt: json['created_at'],
      fullName: json['full_name'],
    );
  }

  String get formattedDate {
    DateTime dateTime = DateTime.parse(createdAt);
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
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
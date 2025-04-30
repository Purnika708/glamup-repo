class Address {
  final int id;
  final String fullName;
  final String phone;
  final String addressLine;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  Address({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      fullName: json['full_name'],
      phone: json['phone'],
      addressLine: json['address_line'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zip_code'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'address_line': addressLine,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
    };
  }
}
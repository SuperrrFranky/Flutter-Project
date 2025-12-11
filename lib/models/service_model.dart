class ServiceItem {
  final String serviceItemId;
  final String serviceItemName;
  final double price;
  final String serviceCategory;

  ServiceItem({
    required this.serviceItemId,
    required this.serviceItemName,
    required this.price,
    required this.serviceCategory,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      serviceItemId: json['serviceId'] as String,
      serviceItemName: json['serviceName'] as String,
      price: (json['price'] as num).toDouble(),
      serviceCategory: (json['serviceCategory'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceItemId,
      'serviceName': serviceItemName,
      'price': price,
      'serviceCategory': serviceCategory,
    };
  }
}

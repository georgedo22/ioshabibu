class SparePart {
  final int? id;
  final String partName;
  final String partCode;
  final int quantity;
  final double price;
  final String storageLocation;
  final int minimumThreshold;
  final String? governorate_id; // Optional field for governorate ID

  SparePart({
    this.id,
    required this.partName,
    required this.partCode,
    required this.quantity,
    required this.price,
    required this.storageLocation,
    required this.minimumThreshold,
    required this.governorate_id,
  });

  factory SparePart.fromJson(Map<String, dynamic> json) {
    return SparePart(
      id: int.tryParse(json['id'].toString()),
      partName: json['part_name'],
      partCode: json['part_code'],
      quantity: int.parse(json['quantity'].toString()),
      price: double.parse(json['price'].toString()),
      storageLocation: json['storage_location'] ?? '',
      minimumThreshold: int.parse(json['minimum_threshold'].toString()),
      governorate_id: json['gov_id'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'part_name': partName,
      'part_code': partCode,
      'quantity': quantity,
      'price': price,
      'storage_location': storageLocation,
      'minimum_threshold': minimumThreshold,
      'gov_id': governorate_id,
    };
  }

  bool get isLowStock => quantity <= minimumThreshold;
}

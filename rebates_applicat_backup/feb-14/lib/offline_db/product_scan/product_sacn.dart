import 'package:hive/hive.dart';

part 'product_sacn.g.dart';

@HiveType(typeId: 24)
class CachedProduct extends HiveObject {
  @HiveField(0)
  final String image;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String defaultCode;

  @HiveField(4)
  final double qtyProduct;

  CachedProduct({
    required this.image,
    required this.name,
    required this.description,
    required this.defaultCode,
    required this.qtyProduct,
  });

  Map<String, dynamic> toMap() {
    return {
      'image': image,
      'name': name,
      'description': description,
      'default_code': defaultCode,
      'qty_product': qtyProduct,
    };
  }

  factory CachedProduct.fromMap(Map<String, dynamic> map) {
    return CachedProduct(
      image: map['image'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      defaultCode: map['default_code'] ?? '',
      qtyProduct: (map['qty_product'] ?? 0).toDouble(),
    );
  }
}

@HiveType(typeId: 28)
class CachedScannedProduct extends HiveObject {
  @HiveField(0)
  final String serialNumber;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String unitPrice;

  @HiveField(3)
  final String state;

  @HiveField(4)
  final List<int>? imageData;

  @HiveField(5)
  final int quantity;

  @HiveField(6)
  final int productId;

  CachedScannedProduct({
    required this.serialNumber,
    required this.name,
    required this.unitPrice,
    required this.state,
    this.imageData,
    required this.quantity,
    required this.productId,
  });

  Map<String, dynamic> toMap() {
    return {
      'serialNumber': serialNumber,
      'name': name,
      'unitPrice': unitPrice,
      'state': state,
      'imageData': imageData,
      'quantity': quantity,
      'productId': productId,
    };
  }
}
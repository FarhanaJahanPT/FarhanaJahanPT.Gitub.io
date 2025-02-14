import 'package:hive/hive.dart';

part 'product_details.g.dart';

@HiveType(typeId: 9)
class ProductDetail extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String quantity;

  @HiveField(2)
  String model;

  @HiveField(3)
  String manufacturer;

  @HiveField(4)
  String image;

  @HiveField(5)
  String state;

  @HiveField(6)
  String type;

  ProductDetail({
    required this.id,
    required this.quantity,
    required this.model,
    required this.manufacturer,
    required this.image,
    required this.state,
    required this.type,
  });
}

@HiveType(typeId: 10)
class CategoryDetail extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  CategoryDetail({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory CategoryDetail.fromMap(Map<String, dynamic> map) {
    return CategoryDetail(
      id: map['id'],
      name: map['name'],
    );
  }
}

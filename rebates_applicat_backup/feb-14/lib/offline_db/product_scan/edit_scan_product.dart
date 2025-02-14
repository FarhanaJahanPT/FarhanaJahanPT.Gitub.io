import 'dart:typed_data';

import 'package:hive/hive.dart';

part 'edit_scan_product.g.dart';

@HiveType(typeId: 26)
class EditScanProduct extends HiveObject {
  @HiveField(0)
  final String barcode;

  @HiveField(1)
  final Uint8List? imageData;

  @HiveField(2)
  final int worksheetId;

  @HiveField(3)
  final String type;

  @HiveField(4)
  final String timestamp;

  @HiveField(5)
  final Map<String, double>? position;

  EditScanProduct({
    required this.barcode,
    this.imageData,
    required this.worksheetId,
    required this.type,
    required this.timestamp,
    this.position,
  });
}

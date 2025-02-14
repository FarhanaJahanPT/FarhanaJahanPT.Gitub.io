import 'package:hive/hive.dart';
import 'dart:typed_data';

part 'owner_signature.g.dart';

@HiveType(typeId: 8)
class OwnerSignatureHive extends HiveObject {
  @HiveField(0)
  final String? ownerName; // Ensure this is defined correctly

  @HiveField(1)
  final DateTime? customerDate;

  @HiveField(2)
  final Uint8List? ownerSignatureImageBytes;

  // Constructor
  OwnerSignatureHive({
    this.ownerName,
    this.customerDate,
    this.ownerSignatureImageBytes,
  });
}

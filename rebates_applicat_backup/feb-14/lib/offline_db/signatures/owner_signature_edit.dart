import 'dart:typed_data';

import 'package:hive/hive.dart';

part 'owner_signature_edit.g.dart';

@HiveType(typeId: 22)
class OwnerSignatureEditData extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  late Uint8List ownerSignature;

  @HiveField(3)
  late String name;

  OwnerSignatureEditData({
    required this.id,
    required this.ownerSignature,
    required this.name,
  });
}
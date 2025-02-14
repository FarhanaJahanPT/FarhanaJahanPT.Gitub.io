import 'dart:typed_data';

import 'package:hive/hive.dart';

part 'installer_signature_edit.g.dart';

@HiveType(typeId: 16)
class SignatureData extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  late Uint8List installSignature;

  @HiveField(2)
  late Uint8List witnessSignature;

  @HiveField(3)
  late String name;

  SignatureData({
    required this.id,
    required this.installSignature,
    required this.witnessSignature,
    required this.name,
  });
}
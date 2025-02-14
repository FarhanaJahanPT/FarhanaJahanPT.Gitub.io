import 'package:hive/hive.dart';

part 'qr_code.g.dart';

@HiveType(typeId: 25)
class Qr_Code {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String qrCode;

  Qr_Code({required this.id, required this.qrCode});
}
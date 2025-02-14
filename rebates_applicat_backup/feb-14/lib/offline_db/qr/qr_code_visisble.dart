import 'package:hive/hive.dart';

part 'qr_code_visisble.g.dart';

@HiveType(typeId: 42)
class QrCodeVisible extends HiveObject {
  @HiveField(0)
  int worksheetId;

  @HiveField(1)
  bool isQrVisible;

  QrCodeVisible({required this.worksheetId, required this.isQrVisible});
}

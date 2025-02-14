import 'package:hive/hive.dart';
import 'dart:typed_data';
part 'installer_signature.g.dart';

@HiveType(typeId: 6)
class InstallerSignature extends HiveObject {
  @HiveField(0)
  String? installerName;

  @HiveField(1)
  String? witnessName;

  @HiveField(2)
  DateTime? installerDate;

  @HiveField(3)
  Uint8List? installerSignatureImageBytes;

  InstallerSignature({
    this.installerName,
    this.witnessName,
    this.installerDate,
    this.installerSignatureImageBytes,
  });
}

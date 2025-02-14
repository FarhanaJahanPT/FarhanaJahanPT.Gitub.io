import 'package:hive/hive.dart';
import 'dart:typed_data';
part 'project_document.g.dart';

@HiveType(typeId: 11)
class ProjectDocuments extends HiveObject {
  @HiveField(0)
  Uint8List? derReceipt;

  @HiveField(1)
  Uint8List? ccewDoc;

  @HiveField(2)
  Uint8List? stcDoc;

  @HiveField(3)
  Uint8List? solarPanelDoc;

  @HiveField(4)
  Uint8List? switchBoardDoc;

  @HiveField(5)
  Uint8List? inverterLocationDoc;

  @HiveField(6)
  Uint8List? batteryLocationDoc;

  ProjectDocuments({
    this.derReceipt,
    this.ccewDoc,
    this.stcDoc,
    this.solarPanelDoc,
    this.switchBoardDoc,
    this.inverterLocationDoc,
    this.batteryLocationDoc,
  });
}

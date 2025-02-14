import 'package:hive/hive.dart';

part 'worksheet_document.g.dart';

@HiveType(typeId: 35)
class WorksheetDocument extends HiveObject {
  @HiveField(0)
  final String? premises;

  @HiveField(1)
  final String? storeys;

  @HiveField(2)
  final String? wallType;

  @HiveField(3)
  final String? roofType;

  @HiveField(4)
  final String? meterBoxPhase;

  @HiveField(5)
  final String? serviceType;

  @HiveField(6)
  final String? nmi;

  @HiveField(7)
  final String? expectedInverterLocation;

  @HiveField(8)
  final String? mountingWallType;

  @HiveField(9)
  final String? inverterLocationNotes;

  @HiveField(10)
  final String? expectedBatteryLocation;

  @HiveField(11)
  final String? mountingType;

  @HiveField(12)
  final String? switchBoardUsed;

  @HiveField(13)
  final String? installedOrNot;

  @HiveField(14)
  final String? description;

  WorksheetDocument({
    this.premises,
    this.storeys,
    this.wallType,
    this.roofType,
    this.meterBoxPhase,
    this.serviceType,
    this.nmi,
    this.expectedInverterLocation,
    this.mountingWallType,
    this.inverterLocationNotes,
    this.expectedBatteryLocation,
    this.mountingType,
    this.switchBoardUsed,
    this.installedOrNot,
    this.description,
  });
}

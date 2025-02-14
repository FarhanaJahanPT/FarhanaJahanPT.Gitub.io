import 'package:hive/hive.dart';

part 'worksheet.g.dart'; // Ensure this is generated

@HiveType(typeId: 13)
class Worksheet {
  @HiveField(0)
  final int? id;

  @HiveField(1)
  final int? panelCount;

  @HiveField(2)
  final int? inverterCount;

  @HiveField(3)
  final int? batteryCount;

  @HiveField(4)
  final int? checklistCount;

  @HiveField(5)
  final int? scannedPanelCount;

  @HiveField(6)
  final int? scannedInverterCount;

  @HiveField(7)
  final int? scannedBatteryCount;

  @HiveField(8)
  final int? checklistCurrentCount;

  Worksheet({
    this.id,
    this.panelCount,
    this.inverterCount,
    this.batteryCount,
    this.checklistCount,
    this.scannedPanelCount,
    this.scannedInverterCount,
    this.scannedBatteryCount,
    this.checklistCurrentCount,
  });
}

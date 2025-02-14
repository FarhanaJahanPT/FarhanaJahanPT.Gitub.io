import 'package:hive/hive.dart';

part 'document.g.dart';

@HiveType(typeId: 12)
class Document {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String datas;

  Document({required this.id, required this.name, required this.datas});
}

import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

part 'assignee.g.dart';

@HiveType(typeId: 1)
class Assignee extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  Assignee({required this.id, required this.name});
}

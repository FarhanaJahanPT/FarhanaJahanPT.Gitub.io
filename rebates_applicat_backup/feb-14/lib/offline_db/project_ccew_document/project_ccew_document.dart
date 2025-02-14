import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'dart:typed_data';
part 'project_ccew_document.g.dart';

@HiveType(typeId: 36)
class ProjectCCEWDocument extends HiveObject {

  @HiveField(1)
  final MemoryImage? documentData;

  ProjectCCEWDocument({
    required this.documentData,
  });
}

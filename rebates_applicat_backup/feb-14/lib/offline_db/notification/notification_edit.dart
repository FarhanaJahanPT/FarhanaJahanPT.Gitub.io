import 'package:hive/hive.dart';

part 'notification_edit.g.dart';

@HiveType(typeId: 21)
class NotificationEdit extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  bool isRead;

  NotificationEdit({
    required this.id,
    required this.isRead,
  });
}

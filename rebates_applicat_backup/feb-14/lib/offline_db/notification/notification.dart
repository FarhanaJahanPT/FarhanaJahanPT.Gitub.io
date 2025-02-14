import 'package:hive/hive.dart';

part 'notification.g.dart';

@HiveType(typeId: 20)
class NotificationModel {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String body;

  @HiveField(2)
  final String subject;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final List<dynamic> authorId;

  @HiveField(5)
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.body,
    required this.subject,
    required this.date,
    required this.authorId,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      body: json['body'] as String,
      subject: json['subject'] as String,
      date: DateTime.parse(json['date'] as String),
      authorId: json['author_id'] as List<dynamic>,
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}

import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../offline_db/notification/notification.dart';

class NotificationOffline {
  String? url;
  OdooClient? client;
  int userId = 0;
  List<Map<String, dynamic>> notifications = [];
  Set<int> newNotificationIds = {};

  Future<void> initializeOdooClient() async {
    print('initializeOdooClient');
    final prefs = await SharedPreferences.getInstance();
    url = prefs.getString('url') ?? '';
    final db = prefs.getString('selectedDatabase') ?? '';
    final sessionId = prefs.getString('sessionId') ?? '';
    final serverVersion = prefs.getString('serverVersion') ?? '';
    final userLang = prefs.getString('userLang') ?? '';
    final companyId = prefs.getInt('companyId');
    final allowedCompaniesStringList =
        prefs.getStringList('allowedCompanies') ?? [];
    List<Company> allowedCompanies = [];

    if (allowedCompaniesStringList.isNotEmpty) {
      allowedCompanies = allowedCompaniesStringList
          .map((jsonString) => Company.fromJson(jsonDecode(jsonString)))
          .toList();
    }

    if (url == null || db.isEmpty || sessionId.isEmpty) {
      throw Exception('URL, database, or session details not set');
    }

    final session = OdooSession(
      id: sessionId,
      userId: prefs.getInt('userId') ?? 0,
      partnerId: prefs.getInt('partnerId') ?? 0,
      userLogin: prefs.getString('userLogin') ?? '',
      userName: prefs.getString('userName') ?? '',
      userLang: userLang,
      userTz: '',
      isSystem: prefs.getBool('isSystem') ?? false,
      dbName: db,
      serverVersion: serverVersion,
      companyId: companyId ?? 1,
      allowedCompanies: allowedCompanies,
    );

    client = OdooClient(url!, session);
    print('kolidddddddddddddddddddd mp');
    fetchNotifications();
  }

  Future<int?> _getUserIdFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }


  Future<void> fetchNotifications() async {
    print("111111111111111111111111111111");
    try {
      await Hive.openBox<NotificationModel>('notificationsBox');
      userId = (await _getUserIdFromPrefs())!;
      print(userId);
      print("userIduserIduserIduserIduserId");
      final notificationDetails = await client?.callKw({
        'model': 'worksheet.notification',
        'method': 'search_read',
        'args': [
          [
            ['author_id', '=', userId],
          ],
        ],
        'kwargs': {
          'fields': ['id', 'body', 'subject', 'date', 'author_id', 'is_read'],
        },
      });
      print(notificationDetails);
      print("notificationDetailsnotificationDetailsnotificationDetails");
      if (notificationDetails != null) {
        final notificationsBox = Hive.box<NotificationModel>('notificationsBox');
        for (var detail in notificationDetails) {
          int notificationId = detail['id'];

          if (!newNotificationIds.contains(notificationId)) {
            newNotificationIds.add(notificationId);
            print(newNotificationIds);
            print("newNotificationIdsnewNotificationIdsnewNotificationIds");
          } else {
            print("Task $notificationId already processed. Skipping...");
            continue;
          }
          final notification = NotificationModel.fromJson(detail);
          // notificationsBox.put(notification.id, notification);
          final existingNotification = notificationsBox.get(notification.id);


          if (existingNotification == null ||
              existingNotification.body != notification.body ||
              existingNotification.subject != notification.subject ||
              existingNotification.date != notification.date ||
              existingNotification.isRead != notification.isRead) {
            notificationsBox.put(notification.id, notification);
            print('Notification saved for ID: ${notification.id}');
          } else {
            print('Notification ID ${notification.id} is already up to date.');
          }
        }
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }
}

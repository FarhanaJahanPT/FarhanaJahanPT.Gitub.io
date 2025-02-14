import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

import '../installation/checklist.dart';
import '../offline_db/checklist/checklist_item_hive.dart';

class Calendar {

  int? userId;
  List<int> categoryIds = [];
  List<int> worksheetIds = [];
  OdooClient? client;
  String url = "";
  Map<DateTime, List<Map<String, String>>> _events = {};
  Set<int> newJobForCalendarIds = {};

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
    print('koli mp');
    getCombinedEvents();
  }

  Future<void> getCombinedEvents() async {
    await Hive.openBox('eventsBox');
    print("33333333333333333333333333333333333333");
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    final processedIds = <int>{};
    try {
      final installingCalendarDetails = await client?.callKw({
        'model': 'project.task',
        'method': 'search_read',
        'args': [
          [
            // ['x_studio_proposed_team', '=', userId],
            ['team_lead_user_id', '=', userId],
            ['project_id', '=', 'New Installation'],
            ['worksheet_id', '!=', false],
            ['team_lead_user_id', '=', userId],
          ]
        ],
        'kwargs': {
          'fields': [
            'activity_ids',
            'project_id',
            'install_status',
            'name',
            'message_ids'
          ],
        },
      });

      final serviceCalendarDetails = await client?.callKw({
        'model': 'project.task',
        'method': 'search_read',
        'args': [
          [
            // ['x_studio_proposed_team', '=', userId],
            ['team_lead_user_id', '=', userId],
            ['project_id', '=', 'Service'],
            ['worksheet_id', '!=', false]
          ]
        ],
        'kwargs': {
          'fields': [
            'activity_ids',
            'project_id',
            'install_status',
            'name',
            'message_ids'
          ],
        },
      });

      final allEvents = <DateTime, List<Map<String, String>>>{};

      final installingEvents =
      await _fetchActivities(installingCalendarDetails, 'Installing');
      final serviceEvents =
      await _fetchActivities(serviceCalendarDetails, 'Service');


      if (installingEvents.isEmpty) {
        print("No installing events found.");
      }

      _mergeEvents(allEvents, installingEvents);
      _mergeEvents(allEvents, serviceEvents);
       _events = allEvents;
      await storeEventsInHive(allEvents);
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> storeEventsInHive(Map<DateTime, List<Map<String, String>>> events) async {
    print(events);
    print("fffffffffffffffffffffffffddddddddddddd");
    var eventsBox = Hive.box('eventsBox');
    await eventsBox.put('allEvents', events);
  }


  Future<Map<DateTime, List<Map<String, String>>>> _fetchActivities(
      List<dynamic>? calendarDetails, String type) async {
    final events = <DateTime, List<Map<String, String>>>{};

    if (calendarDetails != null && calendarDetails.isNotEmpty) {
      for (var detail in calendarDetails) {
        final activityIds = detail['activity_ids'] as List<dynamic>;

        if (activityIds.isNotEmpty) {
          final activityDetails = await client?.callKw({
            'model': 'mail.activity',
            'method': 'search_read',
            'args': [
              [
                ['id', 'in', activityIds]
              ]
            ],
            'kwargs': {
              'fields': [
                'summary',
                'res_name',
                'date_deadline',
                'state',
                'activity_type_id',
                'user_id'
              ],
            },
          });
          print(activityDetails);
          print("activityDetailsactivityDetailsactivityDetails");
          for (var activityDetail in activityDetails) {
            int newJobForCalendarId = activityDetail['id'];

            if (!newJobForCalendarIds.contains(newJobForCalendarId)) {
              newJobForCalendarIds.add(newJobForCalendarId);
              print(newJobForCalendarIds);
              print("newJobIdsnewJobIcccccccccccdbbbbbbbbbbbbbbsnewJobIds555555555555");
            } else {
              print("Task $newJobForCalendarId already processed. Skipping...");
              continue;
            }
            final dateDeadline =
                DateTime.tryParse(activityDetail['date_deadline'] ?? '') ??
                    DateTime.now();
            final activityTypeId = activityDetail['activity_type_id'] != null &&
                activityDetail['activity_type_id'] is List
                ? activityDetail['activity_type_id'][1].toString()
                : '';
            final userId = activityDetail['user_id'] != null &&
                activityDetail['user_id'] is List
                ? activityDetail['user_id'][1].toString()
                : '';
            final event = {
              'title': detail['name']?.toString() ?? '',
              'summary': activityDetail['summary']?.toString() ?? '',
              'res_name': activityDetail['res_name']?.toString() ?? '',
              'type': type,
              'state': activityDetail['state']?.toString() ?? '',
              'activity_type_id': activityTypeId,
              'date_deadline':
              activityDetail['date_deadline']?.toString() ?? '',
              'user_id': userId,
            };
            if (events[dateDeadline] == null) {
              events[dateDeadline] = [];
            }
            events[dateDeadline]!.add(event);
          }
        }
      }
    }
    return events;
  }

  void _mergeEvents(Map<DateTime, List<Map<String, String>>> target,
      Map<DateTime, List<Map<String, String>>> source) {
    source.forEach((date, events) {
      if (target[date] == null) {
        target[date] = [];
      }
      target[date]!.addAll(events);
    });
  }

}

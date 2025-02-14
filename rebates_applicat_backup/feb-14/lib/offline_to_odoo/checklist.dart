import 'dart:developer';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

import '../installation/checklist.dart';
import '../offline_db/checklist/checklist_item_hive.dart';
import '../offline_db/service_checklist/checklist_item_hive.dart';
import '../service_jobs/checklist.dart';

class ChecklistStorageService {
  int? userId;
  List<int> categoryIds = [];
  List<dynamic> workTypeIdList = [];
  List<int> worksheetIds = [];
  OdooClient? client;
  String url = "";
  Set<int> newNotificationIds = {};

  Future<void> initializeOdooClient() async {
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
    getChecklist();
  }

  Future<void> fetchCategoryIds() async {
    try {
      print("gvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvffsss");
      final categories = await client?.callKw({
        'model': 'product.category',
        'method': 'search_read',
        'args': [[]],
        'kwargs': {
          'fields': ['id','name']
        },
      });
      print(categories);
      print("dddddddddddddddddddddddddddddddddddxxxxxxxxxxxxxx");

      if (categories != null && categories is List) {
        categoryIds = categories.map<int>((item) => item['id']).toList();
      }
    } catch (e) {
      print("Failed to fetch category IDs: $e");
    }
  }


  Future<void> fetchWorksheetIdsByType({
    required String serviceType,
    int offset = 0,
    int limit = 10,
    required List<int> targetList,
  }) async {
    try {
      if (client == null) {
        throw Exception("Client instance is null. Please initialize the client.");
      }

      final worksheets = await client!.callKw({
        'model': 'task.worksheet',
        'method': 'search',
        'args': [
          [
            [
              'x_studio_type_of_service',
              '=',
              serviceType,
            ],
          ],
        ],
        'kwargs': {
          'offset': offset,
          'limit': limit,
        },
      });

      if (worksheets is List) {
        final ids = worksheets.whereType<int>().toList();

        if (ids.isNotEmpty) {
          targetList.addAll(ids);
        }

        if (ids.length == limit) {
          await fetchWorksheetIdsByType(
            serviceType: serviceType,
            offset: offset + limit,
            limit: limit,
            targetList: targetList,
          );
        }
      } else {
        throw Exception("Unexpected response type: ${worksheets.runtimeType}");
      }
    } catch (e, stackTrace) {
      print("Error fetching worksheet IDs for $serviceType: $e");
      print("Stack Trace: $stackTrace");
    }
  }


  Future<void> getChecklist() async {
    print("Fetching checklists...");
    userId = await _getUserIdFromPrefs();
    if (categoryIds.isEmpty) await fetchCategoryIds();

    final List<int> installationWorksheetIds = [];
    final List<int> serviceWorksheetIds = [];


    await fetchWorksheetIdsByType(
      serviceType: 'New Installation',
      targetList: installationWorksheetIds,
    );
    await fetchWorksheetIdsByType(
      serviceType: 'Service',
      targetList: serviceWorksheetIds,
    );

    print('Installation Worksheet IDs: $installationWorksheetIds');
    print('Service Worksheet IDs: $serviceWorksheetIds');

    Set<String> addedIds = {};
    List<Future<void>> installationTasks = [];
    List<Future<void>> serviceTasks = [];


    for (var item in installationWorksheetIds) {
      if (!addedIds.contains(item.toString())) {
        installationTasks.add(_fetchChecklistItemForWorksheet(item));
        addedIds.add(item.toString());
      }
    }


    for (var item in serviceWorksheetIds) {
      if (!addedIds.contains(item.toString())) {
        serviceTasks.add(_fetchServiceChecklistItemForWorksheet(item));
        addedIds.add(item.toString());
      }
    }

    print('Added IDs: $addedIds');

    await Future.wait([...installationTasks, ...serviceTasks]);
    print("Checklists fetched successfully.");
  }


  Future<void> _fetchChecklistItemForWorksheet(int worksheetId) async {
    print("22222222222222hhhhhhhhhhhhhhhhhhh2222222");
    print(categoryIds);
    try {
      final worksheet = await client?.callKw({
        'model': 'task.worksheet',
        'method': 'search_read',
        'args': [
          [
            ['id', '=', worksheetId],
          ],
        ],
        'kwargs': {
          'fields': [
            'work_type_ids'
          ],
        },
      });
      if (worksheet.isNotEmpty) {
        workTypeIdList = worksheet[0]['work_type_ids'];
        print(workTypeIdList);
        print("workTypeIdListworkxxxxxxxxxxxxxxxxxxxxxxxxxTypeIdListworkTypeIdList");
        final checklist = await client?.callKw({
          'model': 'installation.checklist',
          'method': 'search_read',
          'args': [
            [
              ['category_ids', 'in', categoryIds],
              [
                'selfie_type',
                'not in',
                ['mid', 'check_out', 'check_in']
              ],
              ['group_ids', 'in', workTypeIdList]
            ]
          ],
          'kwargs': {},
        });
        print("checklistchecklistchecklist");
        print("checklistdddddddddddddddddd$checklist");
        if (checklist != null && checklist is List) {
          print('checking the work sheet id  : $checklist');
          List<ChecklistItem> fetchedChecklistItems = [];
          for (var item in checklist) {
            final items = await client?.callKw({
              'model': 'installation.checklist.item',
              'method': 'search_read',
              'args': [
                [
                  ['checklist_id', '=', item['id']],
                  ['worksheet_id', '=', worksheetId]
                ]
              ],
              'kwargs': {},
            });
            List<File> uploadedImages = [];
            String? textContent;
            if (items != null && items is List && items.isNotEmpty) {
              for (var entry in items) {
                // if (!newNotificationIds.contains(entry['id'])) {
                //   newNotificationIds.add(entry['id']);
                //   print(newNotificationIds);
                //   print("newNotificationIdsnewNotificationIdsnewNotificationIds");
                // } else {
                //   print("Task ${entry['id']} already processed. Skipping...");
                //   continue;
                // }
                if (item['type'] == 'img') {
                  String base64String = entry['image'].toString();
                  if (base64String != null && base64String != 'false') {
                    Uint8List bytes = base64Decode(base64String);
                    Directory appDocDir =
                    await getApplicationDocumentsDirectory();
                    String filePath =
                        '${appDocDir.path}/image_${entry['id']}.jpg';
                    File file = File(filePath);
                    await file.writeAsBytes(bytes);
                    uploadedImages.add(file);
                  } else {}
                } else if (item['type'] == 'text') {
                  if (entry['text'] != null && entry['text'] is String) {
                    textContent = entry['text'];
                  }
                }
              }
            }
            fetchedChecklistItems.add(ChecklistItem(
                title: item['name'] ?? 'Unnamed',
                key: item['id'].toString() ?? '0',
                isMandatory: item['compulsory'] ?? false,
                uploadedImages: item['type'] == 'img' ? uploadedImages : [],
                requiredImages: item['min_qty'] ?? 1,
                textContent: item['type'] == 'text' ? textContent ?? '' : null,
                type: item['type'] ?? '',
                isUpload: item['is_upload'] ?? false

            ));
            await saveChecklist(fetchedChecklistItems, worksheetId);
          }
        }
      }
    } catch (e) {
      print("eehhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh$e");
    }
  }

  Future<void> _fetchServiceChecklistItemForWorksheet(int worksheetId) async {
    print('service checlist $worksheetId');
    try {
      final checklist = await client?.callKw({
        'model': 'service.checklist',
        'method': 'search_read',
        'args': [
          [
            ['category_ids', 'in', categoryIds],
            [
              'selfie_type',
              'not in',
              ['mid', 'check_out', 'check_in']
            ],
          ]
        ],
        'kwargs': {},
      });
      if (checklist != null && checklist is List) {
        List<ChecklistItem> fetchedChecklistItems = [];
        for (var item in checklist) {
          final items = await client?.callKw({
            'model': 'service.checklist.item',
            'method': 'search_read',
            'args': [
              [
                ['service_id', '=', item['id']],
                ['worksheet_id', '=', worksheetId]
              ]
            ],
            'kwargs': {},
          });
          List<File> uploadedImages = [];
          String? textContent;
          if (items != null && items is List && items.isNotEmpty) {
            for (var entry in items) {
              // if (!newNotificationIds.contains(entry['id'])) {
              //   newNotificationIds.add(entry['id']);
              //   print(newNotificationIds);
              //   print("newNotificationIdsnewNotificationIdsnewNotificationIds");
              // } else {
              //   print("Task ${entry['id']} already processed. Skipping...");
              //   continue;
              // }
              if (item['type'] == 'img') {
                String base64String = entry['image'].toString();
                if (base64String != null && base64String != 'false') {
                  Uint8List bytes = base64Decode(base64String);
                  Directory appDocDir =
                  await getApplicationDocumentsDirectory();
                  String filePath =
                      '${appDocDir.path}/image_${entry['id']}.jpg';
                  File file = File(filePath);
                  await file.writeAsBytes(bytes);
                  uploadedImages.add(file);
                } else {
                }
              } else if (item['type'] == 'text') {
                if (entry['text'] != null && entry['text'] is String) {
                  textContent = entry['text'];
                }
              }
            }
          }
          fetchedChecklistItems.add(ChecklistItem(
            title: item['name'] ?? 'Unnamed',
            key: item['id'].toString() ?? '0',
            isMandatory: item['compulsory'] ?? false,
            uploadedImages: item['type'] == 'img' ? uploadedImages : [],
            requiredImages: item['min_qty'] ?? 1,
            textContent: item['type'] == 'text' ? textContent ?? '' : null,
            type: item['type'] ?? '',
              isUpload: item['is_upload'] ?? false
    ));
          await saveChecklist(fetchedChecklistItems, worksheetId);
        }
      }
    } catch (e) {
    }
  }

  Future<int?> _getUserIdFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  // Future<void> saveChecklist(List<ChecklistItem> checklistItems, int worksheetId) async {
  //   final boxName = 'checklistItems_$worksheetId';
  //   final box = await Hive.openBox<ChecklistItemHive>(boxName);
  //   List<ChecklistItemHive> checklistHiveItems = checklistItems.map((item) {
  //     return ChecklistItemHive(
  //       title: item.title,
  //       key: item.key,
  //       isMandatory: item.isMandatory,
  //       uploadedImagePaths: item.uploadedImages.map((file) => file.path).toList(),
  //       requiredImages: item.requiredImages,
  //       textContent: item.textContent,
  //       type: item.type,
  //     );
  //   }).toList();
  //
  //   List<ChecklistItemHive> existingHiveItems = box.values.toList();
  //
  //   bool isDifferent = checklistHiveItems.length != existingHiveItems.length ||
  //       !listEquals(checklistHiveItems, existingHiveItems);
  //
  //   if (isDifferent) {
  //     for (var newItem in checklistHiveItems) {
  //       bool exists = existingHiveItems.any((existingItem) =>
  //       existingItem.key == newItem.key);
  //
  //       if (!exists) {
  //         await box.add(newItem);
  //       } else {
  //       }
  //     }
  //   } else {
  //   }
  //
  //   await box.close();
  // }
  Future<void> saveChecklist(List<ChecklistItem> checklistItems, int worksheetId) async {
    print('checklistItems saveChecklist  ${worksheetId}');
    final boxName = 'checklistItems_$worksheetId';
    final box = await Hive.openBox<ChecklistItemHive>(boxName);

    try {
      List<ChecklistItemHive> checklistHiveItems = checklistItems.map((item) {
        return ChecklistItemHive(
          title: item.title,
          key: item.key,
          isMandatory: item.isMandatory,
          uploadedImagePaths: item.uploadedImages.map((file) => file.path).toList(),
          requiredImages: item.requiredImages,
          textContent: item.textContent,
          type: item.type,
            isUpload: item.isUpload
        );
      }).toList();

      List<ChecklistItemHive> existingHiveItems = box.values.toList();

      bool isDifferent = checklistHiveItems.length != existingHiveItems.length ||
          !listEquals(checklistHiveItems, existingHiveItems);

      if (isDifferent) {
        for (var newItem in checklistHiveItems) {
          bool exists = existingHiveItems.any((existingItem) =>
          existingItem.key == newItem.key);

          if (!exists) {
            await box.add(newItem);
          }
        }
        print('Checklist successfully stored for worksheetId: $worksheetId');
      } else {
        print('No changes detected. Checklist remains the same for worksheetId: $worksheetId');
      }
    } catch (e) {
      print('Error saving checklist: $e');
    } finally {
      await box.close();
    }
  }


  // Future<void> saveServiceChecklist(List<ServiceChecklistItem> serviceChecklistItems, int worksheetId) async {
  //   final boxName = 'checklistServiceItems_$worksheetId';
  //   final box = await Hive.openBox<ServiceChecklistItemHive>(boxName);
  //   print(box);
  //
  //   // Convert ServiceChecklistItems to ServiceChecklistItemHive
  //   List<ServiceChecklistItemHive> serviceChecklistHiveItems = serviceChecklistItems.map((item) {
  //     return ServiceChecklistItemHive(
  //       title: item.title,
  //       key: item.key,
  //       isMandatory: item.isMandatory,
  //       uploadedImagePaths: item.uploadedImages.map((file) => file.path).toList(),
  //       requiredImages: item.requiredImages,
  //       textContent: item.textContent,
  //       type: item.type,
  //     );
  //   }).toList();
  //
  //   print(serviceChecklistHiveItems);
  //
  //   // Get existing items from Hive
  //   List<ServiceChecklistItemHive> existingHiveItems = box.values.toList();
  //
  //   // Check if the service checklist items are different from existing ones
  //   bool isDifferent = serviceChecklistHiveItems.length != existingHiveItems.length ||
  //       !listEquals(serviceChecklistHiveItems, existingHiveItems);
  //
  //   if (isDifferent) {
  //     // Iterate over the serviceChecklistHiveItems and add only those that don't exist in Hive
  //     for (var newItem in serviceChecklistHiveItems) {
  //       bool exists = existingHiveItems.any((existingItem) =>
  //       existingItem.key == newItem.key); // Assuming `key` is a unique identifier
  //
  //       if (!exists) {
  //         await box.add(newItem);
  //         print("Added new item: $newItem");
  //       } else {
  //         print("Item already exists: $newItem");
  //       }
  //     }
  //   } else {
  //     print("No changes detected, skipping update.");
  //   }
  //
  //   // Close the Hive box after updating
  //   await box.close();
  // }
  Future<void> saveServiceChecklist(List<ServiceChecklistItem> serviceChecklistItems, int worksheetId) async {
    print('checklistItems  SERVICE ${serviceChecklistItems.length} , ${worksheetId}');
    final boxName = 'checklistServiceItems_$worksheetId';
    final box = await Hive.openBox<ServiceChecklistItemHive>(boxName);

    try {
      // Map the incoming service checklist items to Hive models.
      List<ServiceChecklistItemHive> serviceChecklistHiveItems = serviceChecklistItems.map((item) {
        return ServiceChecklistItemHive(
          title: item.title,
          key: item.key,
          isMandatory: item.isMandatory,
          uploadedImagePaths: item.uploadedImages.map((file) => file.path).toList(),
          requiredImages: item.requiredImages,
          textContent: item.textContent,
          type: item.type,
        );
      }).toList();


      List<ServiceChecklistItemHive> existingHiveItems = box.values.toList();


      bool isDifferent = serviceChecklistHiveItems.length != existingHiveItems.length ||
          !listEquals(serviceChecklistHiveItems, existingHiveItems);

      if (isDifferent) {
        for (var newItem in serviceChecklistHiveItems) {
          bool exists = existingHiveItems.any((existingItem) => existingItem.key == newItem.key);

          if (!exists) {
            await box.add(newItem);
          }
        }
        print('Service checklist successfully stored for worksheetId: $worksheetId');
      } else {
        print('No new data to save. Service checklist for worksheetId: $worksheetId is already up-to-date.');
      }
    } catch (e) {
      print('Error saving service checklist: $e');
    } finally {
      await box.close();
    }
  }
}
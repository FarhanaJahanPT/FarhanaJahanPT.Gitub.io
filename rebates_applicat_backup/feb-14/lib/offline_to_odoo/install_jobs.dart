import 'dart:convert';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../offline_db/installation_form/document.dart';
import '../offline_db/installation_list/installing_job.dart';


class InstallJobsBackground {
  String? url;
  OdooClient? client;
  int userId = 0;
  int? teamId;
  List<Map<String, dynamic>> attachments_append = [];
  Set<int> newJobIds = {};

  Future<void> initializeOdooClient() async {
    print("-------------------------------------");
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
    getInstallJobsForCurrentUser();
  }


  Future<void> getInstallJobsForCurrentUser() async {
    if (!await _isNetworkAvailable()) {
      // await loadJobsFromHive();
      return;
    }
    print("88888888888fffffffffffffffffffff");
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    print(userId);
    print("hhhhhhhhhhhhhhhhhhhh");
    try {
      final List<dynamic> filters = [
        ['user_ids', '=', userId],
        ['project_id', '=', 'New Installation'],
        [
          'x_studio_type_of_service',
          'in',
          ['New Installation']
        ],
        ['worksheet_id', '!=', false]
      ];

      print("ffffffffffffffffffffffdssssssssssssssss");
      final installJobsDetails = await client?.callKw({
        'model': 'project.task',
        'method': 'search_read',
        'args': [filters],
        'kwargs': {
          'fields': [
            'id',
            'x_studio_site_address_1',
            'x_studio_product_list',
            'date_assign',
            'user_ids',
            'team_lead_id',
            'project_id',
            'install_status',
            'name',
            'subtask_count',
            'closed_subtask_count',
            'partner_id','document_ids'
          ],
        },
      });
      print(installJobsDetails);
      if (installJobsDetails != null && installJobsDetails.isNotEmpty) {
        print('Fedddddddddddddddddddd${installJobsDetails} tched ${installJobsDetails.length} install jobs.');
        List<Map<String, dynamic>> detailedTasks = [];

        for (var task in installJobsDetails) {
          int taskId = task['id'];

          if (!newJobIds.contains(taskId)) {
            newJobIds.add(taskId);
          } else {
            continue;
          }
          List<int> userIds = List<int>.from(task['user_ids'] ?? []);
          // final userDetails = await client?.callKw({
          //   'model': 'res.users',
          //   'method': 'search_read',
          //   'args': [
          //     [
          //       ['id', 'in', userIds]
          //     ]
          //   ],
          //   'kwargs': {'fields': ['name']},
          // });
          // task['user_names'] =
          //     userDetails?.map((user) => user['name']).toList() ?? [];
          final userDetails = await client?.callKw({
            'model': 'team.member',
            'method': 'search_read',
            'args': [
              [
                // ['id', 'in', userIds]
                ['id', '=', task['team_lead_id']]
              ]
            ],
            'kwargs': {
              'fields': ['name'],
            },
          });
          if (userDetails != null && userDetails.isNotEmpty) {
            teamId = task['team_lead_id'][0]??0;
            task['user_name'] = userDetails[0]['name'];
          } else {
            task['user_name'] = 'Unknown'; // Default value if no user is found
          }

          if (task['partner_id'] is List && task['partner_id'].isNotEmpty) {
            final partnerDetails = await client?.callKw({
              'model': 'res.partner',
              'method': 'search_read',
              'args': [
                [
                  ['id', '=', task['partner_id'][0]]
                ]
              ],
              'kwargs': {'fields': ['phone', 'email']},
            });
            task['partner_phone'] = partnerDetails?.first?['phone'];
            task['partner_email'] = partnerDetails?.first?['email'];
          }

          if (task['id'] != null) {
            final worksheet = await client?.callKw({
              'model': 'task.worksheet',
              'method': 'search_read',
              'args': [
                [
                  ['task_id', '=', task['id']],
                  [
                    'x_studio_type_of_service',
                    'in',
                    ['New Installation', 'Service']
                  ],
                ]
              ],
              'kwargs': {
                'fields': [
                  'is_checklist',
                  'checklist_count',
                  // 'witness_signature',
                  'panel_count',
                  'inverter_count',
                  'battery_count',
                  'team_member_ids','team_lead_id'
                ],
              },
            });
            print(worksheet);
            print("fffffffffffffffffworksheet");
            task['worksheetId'] = worksheet[0]['id'];
            task['memberId'] = worksheet[0]['team_lead_id'];
            int checklistCount = 0;
            int signatureCount = 0;
            int scannedBarcodeCount = 0;

            if (worksheet != null && worksheet.isNotEmpty) {
              final worksheetData = worksheet[0];

              checklistCount = worksheetData['checklist_count'] ?? 0;
              task['checklist_count'] = checklistCount;
              task['barcodeTotalCount'] = (worksheetData['panel_count'] ?? 0) +
                  (worksheetData['inverter_count'] ?? 0) +
                  (worksheetData['battery_count'] ?? 0);

              final checklist = await client?.callKw({
                'model': 'installation.checklist.item',
                'method': 'search_read',
                'args': [
                  [
                    ['worksheet_id', '=', worksheetData['id']],
                    ['user_id', '=', userId],
                  ]
                ],
                'kwargs': {'fields': ['id', 'display_name']},
              });
              task['checklist_current_count'] = checklist?.length ?? 0;
              task['team_member_ids'] = worksheet[0]['team_member_ids'];
              final scanningProducts = await client?.callKw({
                'model': 'stock.lot',
                'method': 'search_read',
                'args': [
                  [
                    ['worksheet_id', '=', worksheetData['id']],
                    ['user_id', '=', userId]
                  ]
                ],
                'kwargs': {},
              });
              scannedBarcodeCount = scanningProducts?.length ?? 0;
              task['scannedBarcodeCount'] = scannedBarcodeCount;
            }


            final signatureDetails = await client?.callKw({
              'model': 'project.task',
              'method': 'search_read',
              'args': [
                [
                  [
                    'x_studio_type_of_service',
                    'in',
                    ['New Installation', 'Service']
                  ],
                  ['worksheet_id', '!=', false],
                  // ['x_studio_proposed_team', '=', userId],
                  ['team_lead_user_id', '=', userId],
                  ['id', '=', task['id']]
                ]
              ],
              'kwargs': {
                'fields': [
                  'install_signature',
                  'customer_signature',
                  // 'witness_signature'
                ],
              },
            });

            if (signatureDetails != null && signatureDetails.isNotEmpty) {
              final sigData = signatureDetails.first;
              signatureCount += (sigData['install_signature'] != null &&
                  signatureDetails?.first?['install_signature'] != '' &&
                  signatureDetails?.first?['install_signature'] != false)
                  ? 1
                  : 0;
              signatureCount += (sigData['customer_signature'] != null &&
                  signatureDetails?.first?['customer_signature'] != '' &&
                  signatureDetails?.first?['customer_signature'] != false)
                  ? 1
                  : 0;
              // signatureCount += (sigData['witness_signature'] != null &&
              //     signatureDetails?.first?['witness_signature'] != '' &&
              //     signatureDetails?.first?['witness_signature'] != false)
              //     ? 1
              //     : 0;
            }

            task['signature_count'] = signatureCount;
            task['checklistTotalCount'] = task['checklist_count'];
            detailedTasks.add(task);
          }
          final documentIds = task['document_ids'] as List<dynamic>?;
          if (documentIds != null && documentIds.isNotEmpty) {
            final documentsResponse = await client?.callKw({
              'model': 'documents.document',
              'method': 'search_read',
              'args': [
                [
                  ['id', 'in', documentIds]
                ]
              ],
              'kwargs': {
                'fields': ['id', 'name', 'datas'],
              },
            });
            if (documentsResponse != null && documentsResponse.isNotEmpty) {
              for (var document in documentsResponse) {
                attachments_append.clear();
                attachments_append.add({
                  'id': document['id'],
                  'name': document['name'],
                  'datas': document['datas'],
                });
              }
              await saveOtherDocumentsToHive(task['id']);
            }
          }
        }


        await saveServiceJobsToHive(detailedTasks);


      }
    } catch (e) {
      print(e);
      print("444444444444444444444444444444444");
    }
  }



  Future<void> saveOtherDocumentsToHive(int id) async {
    final box = await Hive.openBox<Document>(
        'documents_$id');
    print(attachments_append);
    print("attachments_appendattachments_appendattachments_append66666666");
    for (var attachment in attachments_append) {
      final newDocument = Document(
        id: attachment['id'],
        name: attachment['name'],
        datas: attachment['datas'],
      );
      await box.put(newDocument.id, newDocument);
    }
  }

  Future<void> saveServiceJobsToHive(List<Map<String, dynamic>> detailedTasks) async {
    try {
      print('detailedTadddddddddddddsks: $detailedTasks');
      final box = await Hive.openBox<InstallingJob>('installationListBox');

      for (var task in detailedTasks) {
        if (task == null || !task.containsKey('id')) {
          print("Invalid task encountered, skipping...");
          continue;
        }

        int taskId = task['id'] ?? 0;

        InstallingJob? existingJob = box.get(taskId);
        if (existingJob != null) {
          print("Task with ID $taskId already exists, skipping...");
          continue;
        }

        int worksheetId = task['worksheetId'] ?? 0;
        List<dynamic> memberId = (task['memberId'] is List<dynamic>) ? task['memberId'] : []; // Ensure it's stored as a list
        String user_name = task['user_name'];

        // List<String> userNames = (task['user_names'] as List<dynamic>?)
        //     ?.map((e) => e.toString())
        //     .toList() ??
        //     [];
        List<int> userIds = (task['user_ids'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList() ??
            [];
        List<int> teamMemberIds = (task['team_member_ids'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList() ?? [];
        print(memberId);
        print("teamMemberIdsteprintprintamMemberIds");
        InstallingJob newJob = InstallingJob(
          id: taskId,
          worksheetId: worksheetId,
          memberId: memberId,
          x_studio_site_address_1: (task['x_studio_site_address_1'] is String)
              ? task['x_studio_site_address_1'] as String
              : '',
          date_assign: (task['date_assign'] is String)
              ? task['date_assign'] as String
              : '',
          partnerPhone: (task['partner_phone'] is String)
              ? task['partner_phone'] as String
              : '',
          partner_email: (task['partner_email'] is String)
              ? task['partner_email'] as String
              : '',
          name: (task['name'] is String) ? task['name'] as String : '',
          user_name: user_name,
          user_ids: userIds,
          project_id: (task['project_id'] is List<dynamic> && task['project_id'].length > 1)
              ? task['project_id'][1] as String
              : null,
          install_status: (task['install_status'] is String)
              ? task['install_status'] as String
              : '',
          scannedBarcodeCount: task['scannedBarcodeCount'] ?? 0,
          checklist_current_count: task['checklist_current_count'] ?? 0,
          signature_count: task['signature_count'] ?? 0,
          barcodeTotalCount: task['barcodeTotalCount'] ?? 0,
          checklistTotalCount: task['checklistTotalCount'] ?? 0,
          team_member_ids: teamMemberIds,
        );

        await box.put(taskId, newJob);
        log("Added new job with ID $taskId");
      }
    } catch (e) {
      log("Error while saving service jobs to Hive: $e");
    }
  }

  // Future<void> saveServiceJobsToHive(List<Map<String, dynamic>> detailedTasks) async {
  //   try {
  //     log('detailedTasks: $detailedTasks');
  //     final box = await Hive.openBox<InstallingJob>('installationListBox');
  //     await box.clear();
  //     for (var task in detailedTasks) {
  //       if (task == null || !task.containsKey('id')) {
  //         log("Invalid task encountered, skipping...");
  //         continue;
  //       }
  //
  //       int taskId = task['id'] ?? 0;
  //       int worksheetId = task['worksheetId'] ?? 0;
  //
  //       List<String> userNames = (task['user_names'] as List<dynamic>?)
  //           ?.map((e) => e.toString())
  //           .toList() ??
  //           [];
  //       List<int> userIds = (task['user_ids'] as List<dynamic>?)
  //           ?.map((e) => e as int)
  //           .toList() ??
  //           [];
  //
  //       InstallingJob newJob = InstallingJob(
  //         id: taskId,
  //         worksheetId: worksheetId,
  //         x_studio_site_address_1: (task['x_studio_site_address_1'] is String)
  //             ? task['x_studio_site_address_1'] as String
  //             : '',
  //         date_assign: (task['date_assign'] is String)
  //             ? task['date_assign'] as String
  //             : '',
  //         partnerPhone: (task['partner_phone'] is String)
  //             ? task['partner_phone'] as String
  //             : '',
  //         partner_email: (task['partner_email'] is String)
  //             ? task['partner_email'] as String
  //             : '',
  //         name: (task['name'] is String) ? task['name'] as String : '',
  //         user_names: userNames,
  //         user_ids: userIds,
  //         project_id: (task['project_id'] is List<dynamic> && task['project_id'].length > 1)
  //             ? task['project_id'][1] as String
  //             : null,
  //         install_status: (task['install_status'] is String)
  //             ? task['install_status'] as String
  //             : '',
  //         scannedBarcodeCount: task['scannedBarcodeCount'] ?? 0,
  //         checklist_current_count: task['checklist_current_count'] ?? 0,
  //         signature_count: task['signature_count'] ?? 0,
  //         barcodeTotalCount: task['barcodeTotalCount'] ?? 0,
  //         checklistTotalCount: task['checklistTotalCount'] ?? 0,
  //       );
  //
  //       if (box.containsKey(taskId)) {
  //         InstallingJob? existingJob = box.get(taskId);
  //
  //         if (existingJob != newJob) {
  //           await box.put(taskId, newJob);
  //         } else {
  //         }
  //       } else {
  //         await box.put(taskId, newJob);
  //       }
  //     }
  //   } catch (e) {
  //   }
  // }

  Future<bool> _isNetworkAvailable() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi;
  }
}
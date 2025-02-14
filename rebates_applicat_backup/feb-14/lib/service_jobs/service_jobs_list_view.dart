import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../offline_db/installation_list/assignee.dart';
import '../offline_db/service_list/service_job.dart';
import '../offline_db/start_finish_job/task_job.dart';

class ServiceJobsListview extends StatefulWidget {
  final VoidCallback? onRefresh;

  ServiceJobsListview({this.onRefresh});

  @override
  State<ServiceJobsListview> createState() => _ServiceJobsListviewState();
}

class _ServiceJobsListviewState extends State<ServiceJobsListview> {
  final NotchBottomBarController _controller =
  NotchBottomBarController(index: 2);
  final int maxCount = 3;
  final List<String> bottomBarPages = [
    'Solar Installation',
    'Calendar',
    'Service Jobs'
  ];
  OdooClient? client;
  String url = "";
  int? userId;
  int? teamId;
  int totalCount = 0;
  int unreadCount = 0;
  List<dynamic> serviceJobsDetailes = [];
  List<dynamic> filteredJobs = [];
  String searchText = '';
  String valueStatus = '';
  int assigneeValue = 0;
  List<String> assignees_items = [];
  List<int> assignees_ids = [];
  DateTime? selectedDate;
  final TextEditingController dateController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  int offset = 0;
  int checklistTotalCount = 0;
  int? barcodeTotalCount;
  int? scannedBarcodeCount;
  final int limit = 20;
  bool hasMoreData = true;
  bool isLoading = true;
  bool progressChange = false;
  Timer? _debounce;
  MemoryImage? profilePicUrl;
  late Future<void> _hiveInitFuture;
  bool isNetworkAvailable = false;
  late List<TaskJob?> taskJobs = [];

  @override
  void initState() {
    super.initState();
    _initialize();
    _loadData();
    // _checkConnectivity().then((_) {
    //   _hiveInitFuture = _initializeHive();
    //   print("yytttttttttggjjjjjjjjjjjjjjjj");
    //   _scrollController.addListener(_scrollListener);
    //   _initializeOdooClient();
    //   // getNotificationCount();
    //   getServiceJobs();
    //   getAssignees();
    //   // getUserProfile();
    // });
  }


  Future<void> _initialize() async {
    await _checkConnectivity();
    _hiveInitFuture = _initializeHive();
    print("yytttttttttggjjjjjjjjjjjjjjjj");
    _scrollController.addListener(_scrollListener);
    _initializeOdooClient();
    // getNotificationCount();
    getServiceJobs();
    getAssignees();
    // getUserProfile();
  }


  Future<void> _loadData() async {
    final box = await Hive.openBox<TaskJob>('taskJobsBox');
    final taskJobsData = box.values.cast<TaskJob?>().toList();
    setState(() {
      taskJobs = taskJobsData;
    });
    await box.close();
  }


  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }


  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    print(connectivityResult);
    print("fffffffffHi Team,ffffffffffffffdddddddddddddd");
    setState(() {
      isNetworkAvailable = connectivityResult != ConnectivityResult.none;
    });
    print('isNetworkAvailable  :  $isNetworkAvailable');
    Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      setState(() {
        isNetworkAvailable = result != ConnectivityResult.none;
      });
      if (isNetworkAvailable) {
        offset = 0;
        hasMoreData = true;
        serviceJobsDetailes.clear();
        await getAssignees();
        // await getUserProfile();
        await getServiceJobs();
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        !isLoading &&
        hasMoreData) {
      getServiceJobs(fromScroll: true);
    }
  }

  Future<void> _initializeOdooClient() async {
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
  }


  Future<void> loadNotificationCount() async {
    final NotificationCountBox = await Hive.openBox('NotificationCount');
    final notificationCount = NotificationCountBox.get('unreadCount');

    if (unreadCount != null) {
      setState(() {
        unreadCount = notificationCount;
      });
    }
  }


  Future<void> getUserProfile() async {
    if (!isNetworkAvailable) {
      print("ddddddddddisNetworkAvailableddddddddddd");
      loadProfilePicUrl();
      return;
    } else {
      final prefs = await SharedPreferences.getInstance();

      userId = prefs.getInt('userId') ?? 0;
      final baseUrl = prefs.getString('url') ?? 0;

      try {
        final Uri url = Uri.parse('$baseUrl/rebates/team_members');
        final userDetails = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "teamId": teamId,
            }
          }),
        );
        print("eeeeeeeeeeeeeeeeeeeeeewwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww");
        final Map<String, dynamic> jsonUserDetailsResponse = json.decode(userDetails.body);
        print("3333333333333333333333$jsonUserDetailsResponse");
        print("userDetailsuserDetailsuserDetails${jsonUserDetailsResponse['result']['team_member_data'][0]['name']}");
        if (jsonUserDetailsResponse['result']['status'] == 'success' && jsonUserDetailsResponse['result']['team_member_data'].isNotEmpty) {
          final user = jsonUserDetailsResponse['result']['team_member_data'][0];
          final imageBase64 = user['image_1920'].toString();
          if (imageBase64 != null && imageBase64 != 'false') {
            final imageData = base64Decode(imageBase64);
            setState(() {
              profilePicUrl = MemoryImage(Uint8List.fromList(imageData));
            });
            final profileBox = await Hive.openBox('profileBox');
            await profileBox.put('profilePicUrl', imageBase64);
          }
        }
        // final userDetails = await client?.callKw({
        //   'model': 'team.members',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       ['id', '=', teamId]
        //     ]
        //   ],
        //   'kwargs': {
        //     'fields': [
        //       'image_1920'
        //     ],
        //   },
        // });
        // if (userDetails != null && userDetails.isNotEmpty) {
        //   final user = userDetails[0];
        //   final imageBase64 = user['image_1920'].toString();
        //   if (imageBase64 != null && imageBase64 != 'false') {
        //     final imageData = base64Decode(imageBase64);
        //     setState(() {
        //       profilePicUrl = MemoryImage(Uint8List.fromList(imageData));
        //     });
        //     final profileBox = await Hive.openBox('profileBox');
        //     await profileBox.put('profilePicUrl', imageBase64);
        //   }
        // }
      } catch (e) {
        print('Error: $e');
      }
    }
  }

  Future<void> loadProfilePicUrl() async {
    final profileBox = await Hive.openBox('profileBox');
    final imageBase64 = profileBox.get('profilePicUrl');

    if (imageBase64 != null) {
      final imageData = base64Decode(imageBase64);
      setState(() {
        profilePicUrl = MemoryImage(Uint8List.fromList(imageData));
      });
    }
  }

  Future<void> reloadService() async {
    offset = 0;
    hasMoreData = true;
    serviceJobsDetailes.clear();
    getServiceJobs();
  }

  Future<void> reloadProfile() async {
    getUserProfile();
  }

  Future<void> getServiceJobs({bool fromScroll = false}) async {
    print("$isNetworkAvailable/Checking connectivity...");
    if (!isNetworkAvailable) {
      List<Map<String, dynamic>> cachedJobs = await loadJobsFromHive();
      setState(() {
        serviceJobsDetailes = cachedJobs;
        filteredJobs = _filterJobs(searchText);
        isLoading = false;
      });
      print(cachedJobs.isNotEmpty ? 'Loaded cached jobs' : 'No cached jobs found');
      return;
    }else {
      print("hhhhhhhhhhh");
      if (!fromScroll) {
        setState(() {
          isLoading = true;
        });
      }

      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;
      teamId = prefs.getInt('teamId') ?? 0;
      final baseUrl = prefs.getString('url') ?? 0;
      try {
        final List<dynamic> filters = [
          // ['x_studio_proposed_team', '=', userId],
          ['team_lead_user_id', '=', userId],
          ['project_id', '=', 'Service'],
          [
            'x_studio_type_of_service',
            'in',
            ['Service']
          ],
          ['worksheet_id', '!=', false]
          // ['date_deadline', '!=', null],
          // ['x_studio_confirmed_with_customer', '=', true]
        ];

        if (valueStatus.isNotEmpty)
          filters.add(['install_status', '=', valueStatus]);

        if (assigneeValue != 0)
          filters.add([
            'user_ids',
            'in',
            [assigneeValue]
          ]);

        if (selectedDate != null) {
          filters.add([
            'date_assign',
            '>=',
            selectedDate!.toIso8601String().split('T')[0] + ' 00:00:00'
          ]);
          filters.add([
            'date_assign',
            '<=',
            selectedDate!.toIso8601String().split('T')[0] + ' 23:59:59'
          ]);
        }
        if (searchText.isNotEmpty) {
          filters.add('|');
          filters.add(['name', 'ilike', searchText]);
          filters.add(['x_studio_site_address_1', 'ilike', searchText]);
        }
        // final serviceJobsDetails = await client?.callKw({
        //   'model': 'project.task',
        //   'method': 'search_read',
        //   'args': [filters],
        //   'kwargs': {
        //     'fields': [
        //       'id',
        //       'x_studio_site_address_1',
        //       'x_studio_product_list',
        //       'date_assign',
        //       'user_ids',
        //       'team_lead_id',
        //       'project_id',
        //       'install_status',
        //       'name',
        //       'subtask_count',
        //       'closed_subtask_count',
        //       'partner_id','document_ids'
        //     ],
        //     if (searchText.isEmpty) 'limit': limit,
        //     if (searchText.isEmpty) 'offset': offset,
        //   },
        // });
        //
        // if (serviceJobsDetails != null && serviceJobsDetails.isNotEmpty) {
        //   List<Map<String, dynamic>> detailedTasks = [];
        //   for (var task in serviceJobsDetails) {

            // List<int> userIds = List<int>.from(task['user_ids'] ?? []);
            // final userDetails = await client?.callKw({
            //   'model': 'res.users',
            //   'method': 'search_read',
            //   'args': [
            //     [
            //       ['id', 'in', userIds]
            //     ]
            //   ],
            //   'kwargs': {
            //     'fields': ['name'],
            //   },
            // });
            // task['user_names'] =
            //     userDetails?.map((user) => user['name']).toList() ?? [];
        print("teamIdteamIdteamIdteamId$teamId");
        final Uri url = Uri.parse('$baseUrl/rebates/project_task');
        final serviceJobsDetails = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "team_id": teamId,
              "type": 'Service',
              "install_status": valueStatus.isNotEmpty ? valueStatus : null,
              "selected_date": selectedDate != null ? selectedDate!.toIso8601String().split('T')[0] : null,
              "searchText": searchText.isNotEmpty ? searchText : null,
            }
          }),
        );
        print(serviceJobsDetails.body);
        print("ddddddddddddddddddddinsktallingCalendarDetailsinsktallingCalendarDetailsinsktallingCalendarDetails");
        final Map<String, dynamic> jsonResponse = json.decode(serviceJobsDetails.body);
        print("3333333333333333333333$jsonResponse");
        if (jsonResponse['result']['status'] == 'success' &&
            jsonResponse['result']['tasks'].isNotEmpty) {
          List<Map<String, dynamic>> detailedTasks = [];
          print(jsonResponse['result']['tasks']);
          for (var task in jsonResponse['result']['tasks']) {
            print(task['team_lead_id']);
            print("pppppppplkjhhhhhhhhhhhhhhhhhhhhhhh");
            // final userDetails = await client?.callKw({
            //   'model': 'team.member',
            //   'method': 'search_read',
            //   'args': [
            //     [
            //       // ['id', 'in', userIds]
            //       ['id', '=', task['team_lead_id'][0]]
            //     ]
            //   ],
            //   'kwargs': {
            //     'fields': ['name'],
            //   },
            // });
            // if (userDetails != null && userDetails.isNotEmpty) {
            //   teamId = task['team_lead_id'][0]??0;
            //   task['user_name'] = userDetails[0]['name'];
            // } else {
            //   task['user_name'] = 'Unknown'; // Default value if no user is found
            // }
            final Uri url = Uri.parse('$baseUrl/rebates/team_members');
            final userDetails = await http.post(
              url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "jsonrpc": "2.0",
                "method": "call",
                "params": {
                  "teamId": teamId,
                }
              }),
            );
            print(task['partner_id'][0]);
            print("ddddddddddddddddddddinsktallingccccCalendarDetailsinsktallingCalendarDetailsinsktallingCalendarDetails");
            final Map<String, dynamic> jsonUserDetailsResponse = json.decode(userDetails.body);
            print("3333333333333333333333$jsonUserDetailsResponse");
            print("userDetailsuserDetailsuserDetails${jsonUserDetailsResponse['result']['team_member_data'][0]['name']}");
            if (jsonUserDetailsResponse['result']['status'] == 'success' && jsonUserDetailsResponse['result']['team_member_data'].isNotEmpty) {
              teamId = task['team_lead_id'][0]??0;
              task['user_name'] = jsonUserDetailsResponse['result']['team_member_data'][0]['name'];
            } else {
              task['user_name'] = 'Unknown';
            }
            if (task['partner_id'] is List && task['partner_id'].isNotEmpty) {
              final Uri url = Uri.parse('$baseUrl/rebates/res_partner');
              final partnerDetails = await http.post(
                url,
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "jsonrpc": "2.0",
                  "method": "call",
                  "params": {
                    "id": task['partner_id'][0],
                  }
                }),
              );
              print(partnerDetails.body);
              print("fffffffffffffffffffhhhhhhhhfffffffmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm");
              final Map<String, dynamic> jsonPartnerDetailsResponse = json.decode(partnerDetails.body);
              print("3333333333333333333333$jsonPartnerDetailsResponse");
              // final partnerDetails = await client?.callKw({
              //   'model': 'res.partner',
              //   'method': 'search_read',
              //   'args': [
              //     [
              //       ['id', '=', task['partner_id'][0]]
              //     ]
              //   ],
              //   'kwargs': {
              //     'fields': ['phone', 'email'],
              //   },
              // });

              task['partner_phone'] = jsonPartnerDetailsResponse['result']['res_partner_data'][0]['phone'];
              task['partner_email'] = jsonPartnerDetailsResponse['result']['res_partner_data'][0]['email'];
            }
            if (task.containsKey('id') && task['id'] != null) {
              // final worksheet = await client?.callKw({
              //   'model': 'task.worksheet',
              //   'method': 'search_read',
              //   'args': [
              //     [
              //       ['task_id', '=', task['id']],
              //       [
              //         'x_studio_type_of_service',
              //         'in',
              //         ['New Installation', 'Service']
              //       ],
              //     ],
              //   ],
              //   'kwargs': {
              //     'fields': [
              //       'is_checklist',
              //       'checklist_count',
              //       // 'witness_signature',
              //       'panel_count',
              //       'inverter_count',
              //       'battery_count',
              //       'team_member_ids','team_lead_id'
              //     ],
              //   },
              // });
              // if (worksheet.isNotEmpty) {
              final Uri url = Uri.parse('$baseUrl/rebates/task_worksheet');
              final worksheet = await http.post(
                url,
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "jsonrpc": "2.0",
                  "method": "call",
                  "params": {
                    "task_id": task['id'],
                    "type": "Service"
                  }
                }),
              );
              print(worksheet.body);
              print("ffffffffffffffffffffsssssssssssfccccccfffffmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm");
              final Map<String, dynamic> jsonWorksheetResponse = json.decode(worksheet.body);
              print("3333333333333333333333$jsonWorksheetResponse");
              if (jsonWorksheetResponse['result']['status'] == 'success' && jsonWorksheetResponse['result']['worksheet_data'].isNotEmpty) {
                task['worksheetId'] = jsonWorksheetResponse['result']['worksheet_data'][0]['id'];
                task['memberId'] = jsonWorksheetResponse['result']['worksheet_data'][0]['team_lead_id'];
                task['team_member_ids'] = jsonWorksheetResponse['result']['worksheet_data'][0]['team_member_ids'];
                try {
                  print(worksheet.body);
                  print("fffffffffffffffffssssssssssffffccccccfffffmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm");
                  final Map<String, dynamic> jsonWorksheetResponse = json.decode(worksheet.body);
                  print("dddddddddddddddddddddddddddddddddzzzzzzzzzzz$jsonWorksheetResponse");
                  final Uri url = Uri.parse('$baseUrl/rebates/stock_lot');
                  final scanningProducts = await http.post(
                    url,
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode({
                      "jsonrpc": "2.0",
                      "method": "call",
                      "params": {
                        "worksheet": jsonWorksheetResponse['result']['worksheet_data'][0]['id'],
                        "teamId": teamId
                      }
                    }),
                  );
                  print(scanningProducts.body);
                  print("fffffffffffffffffssssssssssssssssssffffccccccfffffmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm");
                  final Map<String, dynamic> jsonScanningProductsResponse = json.decode(scanningProducts.body);
                  print("3333333333333333333333$jsonScanningProductsResponse");
                  if (jsonScanningProductsResponse['result']['status'] == 'success' && jsonScanningProductsResponse['result']['stock_lot'].isNotEmpty) {
                    scannedBarcodeCount = jsonScanningProductsResponse.length;
                  } else {
                    scannedBarcodeCount = 0;
                  }
                } catch (e) {
                  print("eeeeeeeeeeeeeeeeeeeeeeeeeeee$e");
                }
                // setState(() {
                //   checklistTotalCount = worksheet[0]['checklist_count']??0;
                //   barcodeTotalCount = (worksheet[0]['panel_count'] ?? 0) +
                //       (worksheet[0]['inverter_count'] ?? 0) +
                //       (worksheet[0]['battery_count'] ?? 0);
                // });
                // final scanningProducts = await client?.callKw({
                //   'model': 'stock.lot',
                //   'method': 'search_read',
                //   'args': [
                //     [
                //       ['worksheet_id', '=', worksheet[0]['id']],
                //       ['user_id', '=', userId],
                //     ],
                //   ],
                //   'kwargs': {},
                // });
                // if (scanningProducts != null && scanningProducts.isNotEmpty) {
                //   scannedBarcodeCount = scanningProducts.length;
                // } else {
                //   scannedBarcodeCount = 0;
                // }
              } else {
                print("Worksheet is empty.");
              }
              List<dynamic>? checklist;
              if (jsonWorksheetResponse['result']['status'] == 'success' && jsonWorksheetResponse['result']['worksheet_data'].isNotEmpty) {
              // if (worksheet != null && worksheet.isNotEmpty) {
                task['checklist_count'] = jsonWorksheetResponse['result']['worksheet_data'][0]['checklist_count'];
                // checklist = await client?.callKw({
                //   'model': 'service.checklist.item',
                //   'method': 'search_read',
                //   'args': [
                //     [
                //       ['worksheet_id', '=', worksheet[0]['id']],
                //     ],
                //   ],
                //   'kwargs': {
                //     'fields': ['id', 'display_name'],
                //   },
                // });
                final Uri url = Uri.parse('$baseUrl/rebates/service_checklist_item');
                final checklistitem = await http.post(
                  url,
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "jsonrpc": "2.0",
                    "method": "call",
                    "params": {
                      "worksheet_id": jsonWorksheetResponse['result']['worksheet_data'][0]['id'],
                    }
                  }),
                );
                final Map<String, dynamic> jsonChecklistResponse = json.decode(checklistitem.body);
                checklist = jsonChecklistResponse['result']['service_checklist_item_data'];
                print("checcccccccccccccccckkkkkkkkk$checklist");
              }
              // final signatureDetails = await client?.callKw({
              //   'model': 'project.task',
              //   'method': 'search_read',
              //   'args': [
              //     [
              //       [
              //         'x_studio_type_of_service',
              //         'in',
              //         ['New Installation', 'Service']
              //       ],
              //       ['worksheet_id', '!=', false],
              //       // ['x_studio_proposed_team', '=', userId],
              //       ['team_lead_user_id', '=', userId],
              //       ['id', '=', task['id']]
              //     ]
              //   ],
              //   'kwargs': {
              //     'fields': [
              //       'install_signature',
              //       'customer_signature',
              //       // 'witness_signature'
              //     ],
              //   },
              // });
              final Uri signatureUrl = Uri.parse('$baseUrl/rebates/project_task');
              final signatureDetails = await http.post(
                signatureUrl,
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "jsonrpc": "2.0",
                  "method": "call",
                  "params": {
                    "team_id": teamId,
                    "type": 'Service',
                    "id": task['id'],
                  }
                }),
              );
              final Map<String, dynamic> jsonSignatureDetailsResponse = json.decode(signatureDetails.body);
              task['barcodeTotalCount'] = (jsonWorksheetResponse['result']['worksheet_data'][0]['panel_count'] ?? 0) +
                  (jsonWorksheetResponse['result']['worksheet_data'][0]['inverter_count'] ?? 0) +
                  (jsonWorksheetResponse['result']['worksheet_data'][0]['battery_count'] ?? 0);
              if (jsonSignatureDetailsResponse['result']['status'] == 'success' && jsonSignatureDetailsResponse['result']['tasks'].isNotEmpty) {
                int signatureCount = 0;
                if (jsonWorksheetResponse['result']['worksheet_data'][0]['install_signature'] != null &&
                    jsonWorksheetResponse['result']['worksheet_data'][0]['install_signature'] != '' &&
                    jsonWorksheetResponse['result']['worksheet_data'][0]['install_signature'] != false) {
                  signatureCount += 1;
                }
                if (jsonWorksheetResponse['result']['worksheet_data'][0]['customer_signature'] != null &&
                    jsonWorksheetResponse['result']['worksheet_data'][0]['customer_signature'] != '' &&
                    jsonWorksheetResponse['result']['worksheet_data'][0]['customer_signature'] != false) {
                  signatureCount += 1;
                }
                // if (signatureDetails?.first?['witness_signature'] != null &&
                //     signatureDetails?.first?['witness_signature'] != '' &&
                //     signatureDetails?.first?['witness_signature'] != false) {
                //   signatureCount += 1;
                // }
                task['signature_count'] = signatureCount;
              }
              int checklistCount = checklist?.length ?? 0;
              task['checklist_current_count'] = checklistCount;
              task['checklistTotalCount'] =
                  jsonWorksheetResponse['result']['worksheet_data'][0]['checklist_count'] ?? 0;
              task['scannedBarcodeCount'] = scannedBarcodeCount;
              print(
                  'checklist_current_count  :  ${task['checklist_current_count']}\nchecklistTotalCount  : ${task['checklistTotalCount']}\nbarcodeTotalCount  : ${task['barcodeTotalCount'] }\n scannedBarcodeCount  : ${task['scannedBarcodeCount']}');
              detailedTasks.add(task);
            }

            setState(() {
              if (offset == 0 || searchText.isNotEmpty) {
                serviceJobsDetailes = detailedTasks;
              } else {
                serviceJobsDetailes.addAll(detailedTasks);
              }

              serviceJobsDetailes = serviceJobsDetailes.toSet().toList();
            });


            // await saveServiceJobsToHive(detailedTasks);
          }
          await saveServiceJobsToHive(detailedTasks);
          if (searchText.isEmpty) {
            offset += limit;
          }
        } else {
          setState(() {
            hasMoreData = false;
            isLoading = false;
          });
        }

        filteredJobs = _filterJobs(searchText);
      } catch (e) {
        List<Map<String, dynamic>> cachedJobs = await loadJobsFromHive();
        setState(() {
          serviceJobsDetailes = cachedJobs;
          filteredJobs = _filterJobs(searchText);
          isLoading = false;
        });
        print(cachedJobs.isNotEmpty ? 'Loaded cached jobs' : 'No cached jobs found');
        return;
      }
    }
  }


  Future<void> saveServiceJobsToHive(List<Map<String, dynamic>> detailedTasks) async {
    try {
      final box = await Hive.openBox<ServiceJobs>('serviceListBox');

      for (var task in detailedTasks) {
        int taskId = task['id'] ?? 0;

        int worksheetId = task['worksheetId'] ?? 0;
        List<dynamic> memberId = (task['memberId'] is List<dynamic>) ? task['memberId'] : []; // Ensure it's stored as a list

        // List<String> userNames = (task['user_names'] as List<dynamic>).map((e) => e.toString()).toList();
        String user_name = task['user_name'];
        List<int> userIds = (task['user_ids'] as List<dynamic>).map((e) => e as int).toList();

        List<int> teamMemberIds = (task['team_member_ids'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList() ?? [];
        print("$memberId/teamMemberIdsteamMemberIdsteamMemberIds$teamMemberIds");
        ServiceJobs newJob = ServiceJobs(
          id: taskId,
          worksheetId: worksheetId,
          memberId: memberId,
          x_studio_site_address_1: (task['x_studio_site_address_1'] is String) ? task['x_studio_site_address_1'] : '',
          date_assign: (task['date_assign'] is String) ? task['date_assign'] : '',
          partnerPhone: (task['partner_phone'] is String) ? task['partner_phone'] : '',
          partner_email: (task['partner_email'] is String) ? task['partner_email'] : '',
          name: (task['name'] is String) ? task['name'] : '',
          user_name: user_name,
          user_ids: userIds,
          project_id: (task['project_id'] is List<dynamic> && task['project_id'].length > 1)
              ? task['project_id'][1] as String
              : null,
          install_status: (task['install_status'] is String) ? task['install_status'] : '',
          scannedBarcodeCount: task['scannedBarcodeCount'] ?? 0,
          checklist_current_count: task['checklist_current_count'] ?? 0,
          signature_count: task['signature_count'] ?? 0,
          barcodeTotalCount: task['barcodeTotalCount'] ?? 0,
          checklistTotalCount: task['checklistTotalCount'] ?? 0,
          team_member_ids: teamMemberIds,
        );


        if (box.containsKey(taskId)) {
          ServiceJobs? existingJob = box.get(taskId);

          if (existingJob != newJob) {
            print("Updating job with ID $taskId due to detected changes.");
            await box.put(taskId, newJob);
          } else {
            print("Job with ID $taskId has no changes, skipping update.");
          }
        } else {
          print("Saving new job with ID $taskId");
          await box.put(taskId, newJob);
        }
      }

      print("All jobs processed and updated if necessary in Hive.");
    } catch (e) {
      print("Error saving or updating jobs to Hive: $e");
    }
  }


  Future<void> _initializeHive() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered (ServiceJobsAdapter
      ().typeId)) {
      Hive.registerAdapter(ServiceJobsAdapter());
    }
    await Hive.openBox<ServiceJobs>('serviceListBox');
    if (!Hive.isAdapterRegistered (AssigneeAdapter
      ().typeId)) {
      Hive.registerAdapter(AssigneeAdapter());
    }
    await Hive.openBox<Assignee>('assignees');
  }



  Future<List<Map<String, dynamic>>> loadJobsFromHive() async {
    final box = await Hive.openBox<ServiceJobs>('serviceListBox');
    List<Map<String, dynamic>> allJobs = box.values.map((job) => job.toMap()).toList();
    bool isFilterSelected = valueStatus.isNotEmpty || assigneeValue != 0 || selectedDate != null;

    List<Map<String, dynamic>> filteredJobs = allJobs.where((job) {
      if (valueStatus.isNotEmpty && job['install_status'] != valueStatus) {
        return false;
      }

      if (assigneeValue != 0 && !(job['user_ids']?.contains(assigneeValue) ?? false)) {
        return false;
      }

      if (selectedDate != null) {
        DateTime jobDate = DateTime.tryParse(job['date_assign'] ?? '') ?? DateTime(1970);
        if (jobDate.toLocal().toString().split(' ')[0] != selectedDate!.toLocal().toString().split(' ')[0]) {
          return false;
        }
      }

      return true;
    }).toList();

    if (isFilterSelected && filteredJobs.isEmpty) {
      return [];
    }

    return filteredJobs;
  }


  bool isSameAsCached(List<Map<String, dynamic>> cached, List<Map<String, dynamic>> current) {
    if (cached.length != current.length) return false;

    for (int i = 0; i < cached.length; i++) {
      if (cached[i]['id'] != current[i]['id'] ||
          cached[i]['install_status'] != current[i]['install_status'] ||
          cached[i]['checklist_count'] != current[i]['checklist_count'] ||
          cached[i]['barcodeTotalCount'] != current[i]['barcodeTotalCount'] ||
          cached[i]['signature_count'] != current[i]['signature_count']) {
        return false;
      }
    }
    return true;
  }



  // Future<void> loadJobsFromHive() async {
  //   print("Loading jobs from Hive...");
  //
  //   try {
  //     if (!Hive.isBoxOpen('serviceListBox')) {
  //       await Hive.openBox<ServiceJobs>('serviceListBox');
  //     }
  //
  //     final box = Hive.box<ServiceJobs>('serviceListBox');
  //
  //     if (box.isEmpty) {
  //       print("No jobs found in the Hive box.");
  //     } else {
  //       var jobMaps = box.values.map((job) => job.toMap()).toList();
  //
  //       // Filtering logic...
  //       if (selectedDate != null) {
  //         String startDate = selectedDate!.toIso8601String().split('T')[0] + ' 00:00:00';
  //         String endDate = selectedDate!.toIso8601String().split('T')[0] + ' 23:59:59';
  //         jobMaps = jobMaps.where((job) {
  //           DateTime jobDate = DateTime.parse(job['date_assign']);
  //           return jobDate.isAfter(DateTime.parse(startDate).subtract(Duration(seconds: 1))) &&
  //               jobDate.isBefore(DateTime.parse(endDate).add(Duration(seconds: 1)));
  //         }).toList();
  //       }
  //       if (valueStatus.isNotEmpty) {
  //         jobMaps = jobMaps.where((job) {
  //           return job['install_status'] == valueStatus;
  //         }).toList();
  //       }
  //       if (assigneeValue != null) {
  //         // jobMaps = jobMaps.where((job) {
  //         //   return (job['user_ids'] as List<dynamic>).contains(assigneeValue);
  //         // }).toList();
  //       }
  //
  //
  //       serviceJobsDetailes = jobMaps;
  //
  //       log('jobMaps  :  $serviceJobsDetailes');
  //       serviceJobsDetailes = serviceJobsDetailes.toSet().toList()
  //         ..sort((a, b) {
  //           if (a['install_status'] == 'progress' && b['install_status'] != 'progress') {
  //             return -1;
  //           } else if (a['install_status'] == 'pending' && b['install_status'] != 'progress' && b['install_status'] != 'pending') {
  //             return -1;
  //           } else if (b['install_status'] == 'progress' && a['install_status'] != 'progress') {
  //             return 1;
  //           } else if (b['install_status'] == 'pending' && a['install_status'] != 'progress' && a['install_status'] != 'pending') {
  //             return 1;
  //           }
  //           return a['install_status'].compareTo(b['install_status']);
  //         });
  //       setState(() {
  //         filteredJobs = _filterJobs(searchText);
  //         isLoading = false;
  //       });
  //
  //       print("Jobs successfully loaded from Hive.");
  //     }
  //   } catch (e) {
  //     print("Error loading jobs from Hive: $e");
  //   }
  // }


  List<dynamic> _filterJobs(String searchText) {
    print("Connectivity result: $isNetworkAvailable");

    List<dynamic> filteredList = serviceJobsDetailes;

    if (!isNetworkAvailable) {
      print("Offline mode, filtering from cached jobs");
      if (searchText.isNotEmpty) {
        filteredList = filteredList.where((job) {
          return job['name'].toLowerCase().contains(searchText.toLowerCase()) ||
              job['x_studio_site_address_1']
                  .toLowerCase()
                  .contains(searchText.toLowerCase());
        }).toList();
      }
    } else {
      if (searchText.isNotEmpty) {
        filteredList = filteredList.where((job) {
          String name = job['name']?.toString() ?? 'None';
          String address = job['x_studio_site_address_1']?.toString() ?? 'None';
          // String assigneesString = (job['user_names']?.isNotEmpty ?? false)
          //     ? (job['user_names'] as List<dynamic>).join(', ')
          //     : 'None';
          String assigneesString = job['user_name'] ?? 'None';
          String installStatus = job['install_status']?.toString() ?? 'None';

          final nameMatches = name.toLowerCase().contains(searchText.toLowerCase());
          final addressMatches = address.toLowerCase().contains(searchText.toLowerCase());
          final assigneesMatches = assigneesString.toLowerCase().contains(searchText.toLowerCase());
          final statusMatches = installStatus.toLowerCase().contains(searchText.toLowerCase());

          return nameMatches || addressMatches || assigneesMatches || statusMatches;
        }).toList();
      }
    }


    filteredList = filteredList.toSet().toList();


    filteredList.sort((a, b) {
      String statusA = a['install_status']?.toString() ?? '';
      String statusB = b['install_status']?.toString() ?? '';


      int getStatusPriority(String status) {
        switch (status.toLowerCase()) {
          case 'progress':
            return 1;
          case 'pending':
            return 2;
          case 'completed':
            return 3;
          default:
            return 4;
        }
      }

      return getStatusPriority(statusA).compareTo(getStatusPriority(statusB));
    });

    setState(() {
      filteredJobs = filteredList;
      isLoading = false;
    });

    return filteredJobs;
  }



  Future<void> getAssignees() async {
    print("$isNetworkAvailable/Checking connisNetworkAvailableectivity...");
    if (!isNetworkAvailable) {
      print("ddddddddddisNetworkAvailableddddddddddd");
      loadAssigneesFromHive();
      return;
    } else {
      print("333333333333333333333333333333333333");
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;
      try {
        final assigneesDetails = await client?.callKw({
          'model': 'team.member',
          'method': 'search_read',
          'args': [[]],
          'kwargs': {
            'fields': [
              'id',
              'name',
            ],
          },
        });
        for (var item in assigneesDetails) {
          assignees_items.add(item['name']);
          assignees_ids.add(item['id']);
        }
        print("dddddddddddddddddddddddddddddddddddddddddddddddd");
        await saveAssigneesJobsToHive();
      } catch (e) {
        print('Error: $e');
        loadAssigneesFromHive();
        return;
      }
    }
  }

  Future<void> loadAssigneesFromHive() async {
    var box = await Hive.openBox<Assignee>('assignees');
    assignees_items.clear();
    assignees_ids.clear();
    for (int i = 0; i < box.length; i++) {
      final assignee = box.getAt(i);

      if (assignee != null) {
        assignees_items.add(assignee.name);
        assignees_ids.add(assignee.id);
      }
    }
  }


  Future<void> saveAssigneesJobsToHive() async {
    print('Assignees ssssssssssssssssssssaved to Hive');
    var box = await Hive.openBox<Assignee>('assignees');
    await box.clear();
    for (int i = 0; i < assignees_items.length; i++) {
      final assignee = Assignee(
        id: assignees_ids[i],
        name: assignees_items[i],
      );
      await box.add(assignee);
    }

    print('Assignees saved to Hive');
  }


  // Future<void> getUserProfile() async {
  //   if (!isNetworkAvailable) {
  //     print("ddddddddddisNetworkAvailableddddddddddd");
  //     // loadProfilePicUrl();
  //     return;
  //   } else {
  //     final prefs = await SharedPreferences.getInstance();
  //
  //     userId = prefs.getInt('userId') ?? 0;
  //
  //     try {
  //       final userDetails = await client?.callKw({
  //         'model': 'res.users',
  //         'method': 'search_read',
  //         'args': [
  //           [
  //             ['id', '=', userId]
  //           ]
  //         ],
  //         'kwargs': {
  //           'fields': [
  //             'image_1920'
  //           ],
  //         },
  //       });
  //       if (userDetails != null && userDetails.isNotEmpty) {
  //         final user = userDetails[0];
  //         final imageBase64 = user['image_1920'].toString();
  //         if (imageBase64 != null && imageBase64 != 'false') {
  //           final imageData = base64Decode(imageBase64);
  //           setState(() {
  //             profilePicUrl = MemoryImage(Uint8List.fromList(imageData));
  //           });
  //           final profileBox = await Hive.openBox('profileBox');
  //           await profileBox.put('profilePicUrl', imageBase64);
  //         }
  //       }
  //     } catch (e) {
  //       print('Error: $e');
  //     }
  //   }
  // }

  Future<bool> _onWillPop() async {
    // Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
    // _controller.index = -1;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text(
        //     'Service Jobs',
        //     style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        //   ),
        //   backgroundColor: Colors.green,
        //   automaticallyImplyLeading: false,
        //   // iconTheme: const IconThemeData(
        //   //   color: Colors.white,
        //   // ),
        //   actions: [
        //     GestureDetector(
        //       onTap: () {
        //         Navigator.pushNamed(context, '/notifications',
        //             arguments: {'reloadNotification': reloadNotification});
        //       },
        //       child: Stack(
        //         clipBehavior: Clip.none,
        //         children: [
        //           Icon(Icons.notifications_rounded,
        //               color: Colors.white, size: 35),
        //           if (unreadCount > 0)
        //             Positioned(
        //             right: -3,
        //             top: -3,
        //             child: Container(
        //               padding: EdgeInsets.all(4),
        //               decoration: BoxDecoration(
        //                 color: Colors.red,
        //                 shape: BoxShape.circle,
        //               ),
        //               constraints: BoxConstraints(
        //                 minWidth: 16,
        //                 minHeight: 16,
        //               ),
        //               child: Center(
        //                 child: Text(
        //                   unreadCount.toString(),
        //                   style: TextStyle(
        //                     color: Colors.white,
        //                     fontWeight: FontWeight.bold,
        //                     fontSize: 10,
        //                   ),
        //                 ),
        //               ),
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //     const SizedBox(width: 10),
        //     Container(
        //       width: 50.0,
        //       height: 50.0,
        //       decoration: BoxDecoration(
        //         shape: BoxShape.circle,
        //         color: Colors.black.withOpacity(0.2),
        //       ),
        //       child: GestureDetector(
        //         onTap: () {
        //           Navigator.pushNamed(context, '/profile_main',
        //               arguments: {
        //                 'reloadProfile': reloadProfile,
        //               });
        //         },
        //         child: CircleAvatar(
        //           radius: 20.0,
        //           backgroundColor: Colors.grey[400],
        //           child: Stack(
        //             children: [
        //               if (profilePicUrl != null)
        //                 Positioned.fill(
        //                   child: ClipOval(
        //                     child: profilePicUrl != null
        //                         ? Image(
        //                       image: profilePicUrl!,
        //                       fit: BoxFit.cover,
        //                       width: 80.0,
        //                       height: 80.0,
        //                       errorBuilder: (BuildContext context,
        //                           Object exception, StackTrace? stackTrace) {
        //                         return Icon(
        //                           Icons.person,
        //                           size: 54,
        //                           color: Colors.white,
        //                         );
        //                       },
        //                     )
        //                         : Icon(Icons.person, size: 54, color: Colors.white),
        //                   ),
        //                 ),
        //               if (profilePicUrl == null)
        //                 Positioned.fill(
        //                   child: Container(
        //                     decoration: BoxDecoration(
        //                       shape: BoxShape.circle,
        //                       color: Colors.grey[400],
        //                     ),
        //                     child: Center(
        //                       child: Icon(Icons.person),
        //                     ),
        //                   ),
        //                 )
        //             ],
        //           ),
        //         ),
        //       ),
        //     ),
        //     const SizedBox(width: 10),
        //   ],
        // ),
        body: Column(
          children: [
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                children: [
                  Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search jobs...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        onChanged: (searchValue) {
                          if (_debounce?.isActive ?? false) _debounce!.cancel();

                          _debounce = Timer(Duration(milliseconds: 500), () {
                            setState(() {
                              searchText = searchValue.trim();
                              offset = 0;
                              hasMoreData = true;
                              serviceJobsDetailes.clear();
                              getServiceJobs();
                            });
                          });
                        },
                      )),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.tune, color: Colors.white),
                      onPressed: () {
                        _filterServiceJobs(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (valueStatus.isNotEmpty ||
                assigneeValue != 0 ||
                selectedDate != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: _clearFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text(
                    'Clear Filters',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            Expanded(
              child: isLoading
                  ? ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: double.infinity,
                              height: 24,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    width: double.infinity,
                                    height: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  width: 60,
                                  height: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: double.infinity,
                              height: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: double.infinity,
                              height: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
                  : filteredJobs.isEmpty
                  ? const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.miscellaneous_services,
                        color: Colors.black,
                        size: 92,
                      ),
                      SizedBox(height: 20),
                      Text(
                        "There are no Service Jobs available to display",
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                itemCount: filteredJobs.length,
                itemBuilder: (context, index) {
                  final job = filteredJobs[index];
                  String name = '';
                  String address = '';
                  String assigneesString = job['user_name']??'';

                  if (job['name'] is String &&
                      job['name'].isNotEmpty) {
                    name = job['name'];
                  } else {
                    name = "None";
                  }
                  if (job.containsKey('x_studio_site_address_1') &&
                      job['x_studio_site_address_1'] is String &&
                      job['x_studio_site_address_1'].isNotEmpty) {
                    address = job['x_studio_site_address_1'];
                  } else {
                    address = "None";
                  }
                  // if (job['user_names'] is List &&
                  //     job['user_names'].isNotEmpty) {
                  //   assigneesString =
                  //       (job['user_names'] as List<dynamic>)
                  //           .join(', ');
                  // }

                  print('signature_count  : ${job}');
                  print(job['barcodeTotalCount']);
                  print("job['barcodeTotalCount']job['barcodeTotalCount']");
                  int? scannedCount = scannedBarcodeCount;
                  int checklistCount = (job['checklist_current_count'] ?? 0).toInt();
                  int signatureCount = (job['signature_count'] ?? 0).toInt();
                  int progressCurrent = job['scannedBarcodeCount'] + checklistCount + signatureCount;
                  int progressTotal = job['barcodeTotalCount'] + 3+ job['checklistTotalCount'];
                  // int progressCurrent = scannedCount! + checklistCount + signatureCount;
                  // int progressTotal = job['barcodeTotalCount'] + 3 + job['checklistTotalCount'];

                  print('scannedCount : $scannedCount\nchecklistCount  : $checklistCount\nsignatureCount  : $signatureCount\nprogressCurrent  : $progressCurrent\nprogressTotal  : $progressTotal');

                  String jobStatus = job['install_status'] ?? 'Unknown'; // Default status

                  final taskJob = taskJobs.firstWhere(
                        (task) => task?.taskId == job['id'],
                    orElse: () => null,
                  );

                  if (taskJob != null) {
                    jobStatus = 'progress'; // Override status if taskJob exists
                  }

                  return GestureDetector(
                    onTap: () {
                      print(job['team_member_ids']);
                      print("team_member_idsteam_member_ids");
                      progressChange = false;
                      if (job['install_status'] == 'pending')
                        setState(() {
                          progressChange = true;
                        });
                      print("job['memberId']${job['memberId']}");
                      Navigator.pushNamed(
                          context, '/service_form_view',
                          arguments: {
                            'job_id': job['id'],
                            'worksheetId': job['worksheetId'],
                            'memberId': job['memberId'][0],
                            'x_studio_site_address_1':
                            job['x_studio_site_address_1'],
                            'date_assign': job['date_assign'],
                            'user_name': job['user_name'],
                            'project_id': job['project_id'],
                            'install_status': job['install_status'],
                            'progressChange': progressChange,
                            'name': job['name'],
                            'partner_phone': job['partner_phone'],
                            'partner_email': job['partner_email'],
                            'reloadService': reloadService,
                            'team_member_ids': job['team_member_ids'] ?? []
                          });
                    },
                    child: JobCard(
                      id: job['id'],
                      name: name,
                      status: jobStatus,
                      location: address,
                      scheduledTime:
                      job['date_assign']?.toString() ?? 'No Date',
                      assignees: assigneesString,
                      progressCurrent: progressCurrent,
                      progressTotal: progressTotal,
                      attachments: 0,
                      checks_checklist: job['checklist_current_count'] ?? 0,
                      checks_total_checklist: job['checklistTotalCount'] ?? 0,
                      barcode_scanned: job['scannedBarcodeCount'] ?? 0,
                      barcode_total: job['barcodeTotalCount'] ?? 0,
                      checks_signature: job['signature_count'] ?? 0,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      // searchText = '';
      valueStatus = '';
      assigneeValue = 0;
      selectedDate = null;
      dateController.clear();
      filteredJobs = serviceJobsDetailes;
      offset = 0;
      hasMoreData = true;
      serviceJobsDetailes.clear();
    });
    getServiceJobs();
  }

  Widget _buildLabelWidget(String labelText, Color color) {
    return Text(
      labelText,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 9,
      ),
    );
  }

  void _filterServiceJobs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          width: MediaQuery.of(context).size.width * 0.89,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Filter Installation Jobs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        value: valueStatus.isNotEmpty ? valueStatus : null,
                        decoration: const InputDecoration(
                          labelText: 'Select Status',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          {'value': 'pending', 'label': "Pending"},
                          {'value': 'progress', 'label': "In Progress"},
                          {'value': 'done', 'label': "Installation Complete"},
                          {'value': 'incomplete', 'label': "Incomplete"},
                          {'value': 'rescheduled', 'label': "Rescheduled"},
                        ].map((status) {
                          return DropdownMenuItem<String>(
                            value: status['value'],
                            child: Text(status['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          valueStatus = value!;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownSearch<int>(
                      selectedItem: assigneeValue != 0 ? assigneeValue : null,
                      dropdownDecoratorProps: const DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Select Assignee',
                        ),
                      ),
                      items: assignees_ids,
                      itemAsString: (int? item) =>
                      assignees_items[assignees_ids.indexOf(item!)],
                      onChanged: (value) {
                        assigneeValue = value!;
                      },
                      popupProps: const PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            labelText: 'Search Assignee',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Select Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                            dateController.text =
                            "${pickedDate.toLocal()}".split(' ')[0];
                          });
                        }
                      },
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        offset = 0;
                        hasMoreData = true;
                        serviceJobsDetailes.clear();
                        getServiceJobs();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class JobCard extends StatelessWidget {
  final int id;
  final String name;
  final String status;
  final String location;
  final String scheduledTime;
  final String assignees;
  final int progressCurrent;
  final int progressTotal;
  final int attachments;
  final int checks_checklist;
  final int checks_total_checklist;
  final int barcode_total;
  final int barcode_scanned;
  final int checks_signature;
  final String? finishedText;

  const JobCard({
    Key? key,
    required this.id,
    required this.name,
    required this.status,
    required this.location,
    required this.scheduledTime,
    required this.assignees,
    required this.progressCurrent,
    required this.progressTotal,
    required this.attachments,
    required this.checks_checklist,
    required this.checks_total_checklist,
    required this.barcode_total,
    required this.barcode_scanned,
    required this.checks_signature,
    this.finishedText,
  }) : super(key: key);

  Color determineStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return Colors.green;
      case 'progress':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      case 'incomplete':
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  String capitalizeFirstLetter(String text) {
    return text.isNotEmpty
        ? '${text[0].toUpperCase()}${text.substring(1)}'
        : text;
  }


  @override
  Widget build(BuildContext context) {
    print(id);
    print("ddddddddddddddddddddddddddddddddstatus");

    final Color statusColor = determineStatusColor(status);
    final String capitalizedStatus = capitalizeFirstLetter(status);
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: statusColor,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            capitalizedStatus,
                            style: TextStyle(color: statusColor, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    // Using a SizedBox for constraint
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: progressCurrent / progressTotal,
                              backgroundColor: Colors.grey[200],
                              color: statusColor,
                            ),
                          ),
                          // SizedBox(width: 10),
                          // Text(
                          //   '$progressCurrent/$progressTotal',
                          //   style: TextStyle(color: Colors.black54),
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Flexible(
                  flex: 3,
                  child: Row(
                    children: [
                      Icon(Icons.location_on,
                          color: Colors.blueAccent, size: 18),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          location,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.blueAccent, size: 18),
                const SizedBox(width: 5),
                Text(
                  scheduledTime,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Assignees: $assignees',
              style: const TextStyle(
                  color: Colors.black87, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 10),
            if (status == 'done' || status == 'pending')
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: status == 'done' ? Colors.green[100] : Colors.blue[50],
                ),
                width: MediaQuery.of(context).size.width,
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      status == 'done' ? 'FINISHED' : status.toUpperCase(),
                      style: TextStyle(
                        color: status == 'done' ? Colors.green : Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      status == 'done' ? Icons.verified : Icons.schedule,
                      color: status == 'done'
                          ? Colors.green[800]
                          : Colors.blue[800],
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: statusColor.withOpacity(0.15),
                ),
                width: MediaQuery.of(context).size.width,
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/barcode.png',
                            width: 24,
                            height: 24,
                          ),
                          if (barcode_total != barcode_scanned || barcode_total == 0)
                            Text('$barcode_scanned/$barcode_total')
                          else
                            Icon(Icons.verified),
                        ],
                      ),
                    ),
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.fact_check_outlined),
                          if (checks_checklist != checks_total_checklist || checks_total_checklist == 0)
                            Text('$checks_checklist/$checks_total_checklist')
                          else
                            Icon(Icons.verified),
                        ],
                      ),
                    ),
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/sign.png',
                            width: 24,
                            height: 24,
                          ),
                          if (checks_signature != 2)
                            Text('$checks_signature/2')
                          else
                            Icon(Icons.verified),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// import 'dart:async';
// import 'dart:convert';
// import 'package:hive/hive.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter/material.dart';
// import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
// import 'package:odoo_rpc/odoo_rpc.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:shimmer/shimmer.dart';
// import 'dart:typed_data';
// import 'dart:convert';
// import 'package:connectivity_plus/connectivity_plus.dart';
//
// import '../offline_db/installation_list/assignee.dart';
// import '../offline_db/service_list/service_job.dart';
//
// class ServiceJobsListview extends StatefulWidget {
//   final VoidCallback? onRefresh;
//
//   ServiceJobsListview({this.onRefresh});
//
//   @override
//   State<ServiceJobsListview> createState() => _ServiceJobsListviewState();
// }
//
// class _ServiceJobsListviewState extends State<ServiceJobsListview> {
//   final NotchBottomBarController _controller =
//   NotchBottomBarController(index: 2);
//   final int maxCount = 3;
//   final List<String> bottomBarPages = [
//     'Solar Installation',
//     'Calendar',
//     'Service Jobs'
//   ];
//   OdooClient? client;
//   String url = "";
//   int? userId;
//   int totalCount = 0;
//   int unreadCount = 0;
//   List<dynamic> serviceJobsDetailes = [];
//   List<dynamic> filteredJobs = [];
//   String searchText = '';
//   String valueStatus = '';
//   int assigneeValue = 0;
//   List<String> assignees_items = [];
//   List<int> assignees_ids = [];
//   DateTime? selectedDate;
//   final TextEditingController dateController = TextEditingController();
//   ScrollController _scrollController = ScrollController();
//   int offset = 0;
//   int checklistTotalCount = 0;
//   int? barcodeTotalCount;
//   int? scannedBarcodeCount;
//   final int limit = 20;
//   bool hasMoreData = true;
//   bool isLoading = true;
//   bool progressChange = false;
//   Timer? _debounce;
//   MemoryImage? profilePicUrl;
//   late Future<void> _hiveInitFuture;
//   bool isNetworkAvailable = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _checkConnectivity().then((_) {
//       _hiveInitFuture = _initializeHive();
//       print("yytttttttttggjjjjjjjjjjjjjjjj");
//       _scrollController.addListener(_scrollListener);
//       _initializeOdooClient();
//       // getNotificationCount();
//       getServiceJobs();
//       getAssignees();
//       // getUserProfile();
//     });
//   }
//
//
//   @override
//   void dispose() {
//     _scrollController.removeListener(_scrollListener);
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//
//   Future<void> _checkConnectivity() async {
//     var connectivityResult = await Connectivity().checkConnectivity();
//     print(connectivityResult);
//     print("fffffffffffffffffffffffdddddddddddddd");
//     setState(() {
//       isNetworkAvailable = connectivityResult != ConnectivityResult.none;
//     });
//     print('isNetworkAvailable  :  $isNetworkAvailable');
//     Connectivity()
//         .onConnectivityChanged
//         .listen((ConnectivityResult result) async {
//       setState(() {
//         isNetworkAvailable = result != ConnectivityResult.none;
//       });
//       if (isNetworkAvailable) {
//         offset = 0;
//         hasMoreData = true;
//         serviceJobsDetailes.clear();
//         await getAssignees();
//         // await getUserProfile();
//         await getServiceJobs();
//       }
//     });
//   }
//
//   void _scrollListener() {
//     if (_scrollController.offset >=
//         _scrollController.position.maxScrollExtent &&
//         !_scrollController.position.outOfRange &&
//         !isLoading &&
//         hasMoreData) {
//       getServiceJobs(fromScroll: true);
//     }
//   }
//
//   Future<void> _initializeOdooClient() async {
//     final prefs = await SharedPreferences.getInstance();
//     url = prefs.getString('url') ?? '';
//     final db = prefs.getString('selectedDatabase') ?? '';
//     final sessionId = prefs.getString('sessionId') ?? '';
//     final serverVersion = prefs.getString('serverVersion') ?? '';
//     final userLang = prefs.getString('userLang') ?? '';
//     final companyId = prefs.getInt('companyId');
//     final allowedCompaniesStringList =
//         prefs.getStringList('allowedCompanies') ?? [];
//     List<Company> allowedCompanies = [];
//
//     if (allowedCompaniesStringList.isNotEmpty) {
//       allowedCompanies = allowedCompaniesStringList
//           .map((jsonString) => Company.fromJson(jsonDecode(jsonString)))
//           .toList();
//     }
//     if (url == null || db.isEmpty || sessionId.isEmpty) {
//       throw Exception('URL, database, or session details not set');
//     }
//
//     final session = OdooSession(
//       id: sessionId,
//       userId: prefs.getInt('userId') ?? 0,
//       partnerId: prefs.getInt('partnerId') ?? 0,
//       userLogin: prefs.getString('userLogin') ?? '',
//       userName: prefs.getString('userName') ?? '',
//       userLang: userLang,
//       userTz: '',
//       isSystem: prefs.getBool('isSystem') ?? false,
//       dbName: db,
//       serverVersion: serverVersion,
//       companyId: companyId ?? 1,
//       allowedCompanies: allowedCompanies,
//     );
//
//     client = OdooClient(url!, session);
//   }
//
//   Future<void> getNotificationCount() async {
//     if (!isNetworkAvailable) {
//       loadNotificationCount();
//       return;
//     } else {
//       final prefs = await SharedPreferences.getInstance();
//       userId = prefs.getInt('userId') ?? 0;
//
//       try {
//         final now = DateTime.now();
//         final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
//         final formattedNow = DateFormat('yyyy-MM-dd').format(now);
//         final formattedOneMonthAgo = DateFormat('yyyy-MM-dd').format(
//             oneMonthAgo);
//         final newInstallation = await client?.callKw({
//           'model': 'project.task',
//           'method': 'search_read',
//           'args': [
//             [
//               ['x_studio_proposed_team', '=', userId],
//               ['project_id', '=', 'New Installation'],
//               ['worksheet_id', '!=', false]
//               // ['date_deadline', '!=', null],
//               // ['x_studio_confirmed_with_customer', '=', true]
//             ]
//           ],
//           'kwargs': {
//             'fields': ['website_message_ids'],
//           },
//         });
//         final service = await client?.callKw({
//           'model': 'project.task',
//           'method': 'search_read',
//           'args': [
//             [
//               ['x_studio_proposed_team', '=', userId],
//               ['project_id', '=', 'Service'],
//               ['worksheet_id', '!=', false]
//               // ['date_deadline', '!=', null],
//               // ['x_studio_confirmed_with_customer', '=', true]
//             ]
//           ],
//           'kwargs': {
//             'fields': ['website_message_ids'],
//           },
//         });
//
//         int newTotalCount = 0;
//         int unreadMessagesCount = 0;
//
//         if (newInstallation != null) {
//           for (var task in newInstallation) {
//             newTotalCount += (task['website_message_ids'] as List).length;
//
//             final messages = await client?.callKw({
//               'model': 'mail.message',
//               'method': 'search_read',
//               'args': [
//                 [
//                   ['id', 'in', task['website_message_ids']],
//                   ['is_read', '=', false],
//                   ['date', '>=', formattedOneMonthAgo],
//                   ['date', '<=', formattedNow]
//                 ]
//               ],
//               'kwargs': {
//                 'fields': ['is_read'],
//               },
//             });
//             if (messages != null) {
//               unreadMessagesCount += (messages
//                   .where((message) => message['is_read'] == false)
//                   .length as int);
//             }
//           }
//         }
//
//         if (service != null) {
//           for (var task in service) {
//             newTotalCount += (task['website_message_ids'] as List).length;
//
//             final messages = await client?.callKw({
//               'model': 'mail.message',
//               'method': 'search_read',
//               'args': [
//                 [
//                   ['id', 'in', task['website_message_ids']],
//                   ['is_read', '=', false],
//                   ['date', '>=', formattedOneMonthAgo],
//                   ['date', '<=', formattedNow]
//                 ]
//               ],
//               'kwargs': {
//                 'fields': ['is_read'],
//               },
//             });
//
//             if (messages != null) {
//               unreadMessagesCount += (messages
//                   .where((message) => message['is_read'] == false)
//                   .length as int);
//             }
//           }
//         }
//
//         setState(() {
//           totalCount = newTotalCount;
//           unreadCount = unreadMessagesCount;
//         });
//         final profileBox = await Hive.openBox('NotificationCount');
//         await profileBox.put('unreadCount', unreadCount);
//
//       } catch (e) {
//         print('Error: $e');
//       }
//     }
//   }
//
//   Future<void> loadNotificationCount() async {
//     final NotificationCountBox = await Hive.openBox('NotificationCount');
//     final notificationCount = NotificationCountBox.get('unreadCount');
//
//     if (unreadCount != null) {
//       setState(() {
//         unreadCount = notificationCount;
//       });
//     }
//   }
//
//
//   Future<void> getUserProfile() async {
//     if (!isNetworkAvailable) {
//       print("ddddddddddisNetworkAvailableddddddddddd");
//       loadProfilePicUrl();
//       return;
//     } else {
//       final prefs = await SharedPreferences.getInstance();
//
//       userId = prefs.getInt('userId') ?? 0;
//
//       try {
//         final userDetails = await client?.callKw({
//           'model': 'res.users',
//           'method': 'search_read',
//           'args': [
//             [
//               ['id', '=', userId]
//             ]
//           ],
//           'kwargs': {
//             'fields': [
//               'image_1920'
//             ],
//           },
//         });
//         if (userDetails != null && userDetails.isNotEmpty) {
//           final user = userDetails[0];
//           final imageBase64 = user['image_1920'].toString();
//           if (imageBase64 != null && imageBase64 != 'false') {
//             final imageData = base64Decode(imageBase64);
//             setState(() {
//               profilePicUrl = MemoryImage(Uint8List.fromList(imageData));
//             });
//             final profileBox = await Hive.openBox('profileBox');
//             await profileBox.put('profilePicUrl', imageBase64);
//           }
//         }
//       } catch (e) {
//         print('Error: $e');
//       }
//     }
//   }
//
//   Future<void> loadProfilePicUrl() async {
//     final profileBox = await Hive.openBox('profileBox');
//     final imageBase64 = profileBox.get('profilePicUrl');
//
//     if (imageBase64 != null) {
//       final imageData = base64Decode(imageBase64);
//       setState(() {
//         profilePicUrl = MemoryImage(Uint8List.fromList(imageData));
//       });
//     }
//   }
//
//   Future<void> reloadService() async {
//     offset = 0;
//     hasMoreData = true;
//     serviceJobsDetailes.clear();
//     getServiceJobs();
//   }
//
//   Future<void> reloadProfile() async {
//     getUserProfile();
//   }
//
//   Future<void> getServiceJobs({bool fromScroll = false}) async {
//     print("$isNetworkAvailable/Checking connectivity...");
//     if (!isNetworkAvailable) {
//       print("dddddddddddddddddddjjjjjjjjjjjjjjjjjjjjjjjjjjjjjdd");
//       loadJobsFromHive();
//       return;
//     } else {
//       print("hhhhhhhhhhh");
//       if (!fromScroll) {
//         setState(() {
//           isLoading = true;
//         });
//       }
//
//       final prefs = await SharedPreferences.getInstance();
//       userId = prefs.getInt('userId') ?? 0;
//       try {
//         final List<dynamic> filters = [
//           ['x_studio_proposed_team', '=', userId],
//           ['project_id', '=', 'Service'],
//           ['worksheet_id', '!=', false]
//           // ['date_deadline', '!=', null],
//           // ['x_studio_confirmed_with_customer', '=', true]
//         ];
//
//         if (valueStatus.isNotEmpty)
//           filters.add(['install_status', '=', valueStatus]);
//
//         if (assigneeValue != 0)
//           filters.add([
//             'user_ids',
//             'in',
//             [assigneeValue]
//           ]);
//
//         if (selectedDate != null) {
//           filters.add([
//             'date_assign',
//             '>=',
//             selectedDate!.toIso8601String().split('T')[0] + ' 00:00:00'
//           ]);
//           filters.add([
//             'date_assign',
//             '<=',
//             selectedDate!.toIso8601String().split('T')[0] + ' 23:59:59'
//           ]);
//         }
//         if (searchText.isNotEmpty) {
//           filters.add('|');
//           filters.add(['name', 'ilike', searchText]);
//           filters.add(['x_studio_site_address_1', 'ilike', searchText]);
//         }
//         final serviceJobsDetails = await client?.callKw({
//           'model': 'project.task',
//           'method': 'search_read',
//           'args': [filters],
//           'kwargs': {
//             'fields': [
//               'id',
//               'x_studio_site_address_1',
//               'x_studio_product_list',
//               'date_assign',
//               'user_ids',
//               'project_id',
//               'install_status',
//               'name',
//               'subtask_count',
//               'closed_subtask_count',
//               'partner_id'
//             ],
//             if (searchText.isEmpty) 'limit': limit,
//             if (searchText.isEmpty) 'offset': offset,
//           },
//         });
//
//         if (serviceJobsDetails != null && serviceJobsDetails.isNotEmpty) {
//           List<Map<String, dynamic>> detailedTasks = [];
//           for (var task in serviceJobsDetails) {
//             List<int> userIds = List<int>.from(task['user_ids'] ?? []);
//             final userDetails = await client?.callKw({
//               'model': 'res.users',
//               'method': 'search_read',
//               'args': [
//                 [
//                   ['id', 'in', userIds]
//                 ]
//               ],
//               'kwargs': {
//                 'fields': ['name'],
//               },
//             });
//             task['user_names'] =
//                 userDetails?.map((user) => user['name']).toList() ?? [];
//
//             if (task['partner_id'] is List && task['partner_id'].isNotEmpty) {
//               final partnerDetails = await client?.callKw({
//                 'model': 'res.partner',
//                 'method': 'search_read',
//                 'args': [
//                   [
//                     ['id', '=', task['partner_id'][0]]
//                   ]
//                 ],
//                 'kwargs': {
//                   'fields': ['phone', 'email'],
//                 },
//               });
//
//               task['partner_phone'] = partnerDetails?.first?['phone'];
//               task['partner_email'] = partnerDetails?.first?['email'];
//             }
//             if (task.containsKey('id') && task['id'] != null) {
//               final worksheet = await client?.callKw({
//                 'model': 'task.worksheet',
//                 'method': 'search_read',
//                 'args': [
//                   [
//                     ['task_id', '=', task['id']],
//                   ],
//                 ],
//                 'kwargs': {
//                   'fields': [
//                     'is_checklist',
//                     'checklist_count',
//                     'witness_signature',
//                     'panel_count',
//                     'inverter_count',
//                     'battery_count'
//                   ],
//                 },
//               });
//               if (worksheet.isNotEmpty) {
//                 // setState(() {
//                 //   checklistTotalCount = worksheet[0]['checklist_count']??0;
//                 //   barcodeTotalCount = (worksheet[0]['panel_count'] ?? 0) +
//                 //       (worksheet[0]['inverter_count'] ?? 0) +
//                 //       (worksheet[0]['battery_count'] ?? 0);
//                 // });
//                 final scanningProducts = await client?.callKw({
//                   'model': 'stock.lot',
//                   'method': 'search_read',
//                   'args': [
//                     [
//                       ['worksheet_id', '=', worksheet[0]['id']],
//                       ['user_id', '=', userId],
//                     ],
//                   ],
//                   'kwargs': {},
//                 });
//                 if (scanningProducts != null && scanningProducts.isNotEmpty) {
//                   scannedBarcodeCount = scanningProducts.length;
//                 } else {
//                   scannedBarcodeCount = 0;
//                 }
//               } else {
//                 print("Worksheet is empty.");
//               }
//               List<dynamic>? checklist;
//
//               if (worksheet != null && worksheet.isNotEmpty) {
//                 task['checklist_count'] = worksheet[0]['checklist_count'];
//                 checklist = await client?.callKw({
//                   'model': 'service.checklist.item',
//                   'method': 'search_read',
//                   'args': [
//                     [
//                       ['worksheet_id', '=', worksheet[0]['id']],
//                     ],
//                   ],
//                   'kwargs': {
//                     'fields': ['id', 'display_name'],
//                   },
//                 });
//               }
//               final signatureDetails = await client?.callKw({
//                 'model': 'project.task',
//                 'method': 'search_read',
//                 'args': [
//                   [
//                     ['x_studio_proposed_team', '=', userId],
//                     ['id', '=', task['id']]
//                   ]
//                 ],
//                 'kwargs': {
//                   'fields': [
//                     'install_signature',
//                     'customer_signature',
//                     'witness_signature'
//                   ],
//                 },
//               });
//               if (signatureDetails != null && signatureDetails.isNotEmpty) {
//                 int signatureCount = 0;
//                 if (signatureDetails?.first?['install_signature'] != null &&
//                     signatureDetails?.first?['install_signature'] != '' &&
//                     signatureDetails?.first?['install_signature'] != false) {
//                   signatureCount += 1;
//                 }
//                 if (signatureDetails?.first?['customer_signature'] != null &&
//                     signatureDetails?.first?['customer_signature'] != '' &&
//                     signatureDetails?.first?['customer_signature'] != false) {
//                   signatureCount += 1;
//                 }
//                 if (signatureDetails?.first?['witness_signature'] != null &&
//                     signatureDetails?.first?['witness_signature'] != '' &&
//                     signatureDetails?.first?['witness_signature'] != false) {
//                   signatureCount += 1;
//                 }
//                 task['signature_count'] = signatureCount;
//               }
//               int checklistCount = checklist?.length ?? 0;
//               task['checklist_current_count'] = checklistCount;
//               task['checklistTotalCount'] =
//                   worksheet[0]['checklist_count'] ?? 0;
//               task['barcodeTotalCount'] = (worksheet[0]['panel_count'] ?? 0) +
//                   (worksheet[0]['inverter_count'] ?? 0) +
//                   (worksheet[0]['battery_count'] ?? 0);
//               task['scannedBarcodeCount'] = scannedBarcodeCount;
//               print(
//                   'checklist_current_count  :  ${task['checklist_current_count']}\nchecklistTotalCount  : ${task['checklistTotalCount']}\nbarcodeTotalCount  : ${task['barcodeTotalCount'] }\n scannedBarcodeCount  : ${task['scannedBarcodeCount']}');
//               detailedTasks.add(task);
//             }
//             setState(() {
//               if (offset == 0 || searchText.isNotEmpty) {
//                 serviceJobsDetailes = detailedTasks;
//               } else {
//                 serviceJobsDetailes.addAll(detailedTasks);
//               }
//
//               serviceJobsDetailes = serviceJobsDetailes.toSet().toList();
//             });
//           }
//           await saveServiceJobsToHive(detailedTasks);
//           if (searchText.isEmpty) {
//             offset += limit;
//           }
//         } else {
//           setState(() {
//             hasMoreData = false;
//             isLoading = false;
//           });
//         }
//
//         filteredJobs = _filterJobs(searchText);
//       } catch (e) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }
//
//
//   Future<void> saveServiceJobsToHive(
//       List<Map<String, dynamic>> detailedTasks) async {
//     List<ServiceJobs> jobList = [];
//     try {
//       final box = await Hive.openBox<ServiceJobs>('serviceListBox');
//       await box.clear();
//       for (var task in detailedTasks) {
//         int taskId = task['id'] ?? 0;
//
//         // if (box.containsKey(taskId)) {
//         //   print("Job with ID $taskId already exists, skipping.");
//         //   continue;
//         // }
//
//         List<String> userNames = (task['user_names'] as List<dynamic>)
//             .map((e) => e.toString())
//             .toList();
//         List<int> userIds = (task['user_ids'] as List<dynamic>)
//             .map((e) => e as int)
//             .toList();
//
//         print('checklist_current_count  : ${task['checklist_current_count'] ?? 0 } \n scannedBarcodeCount :  ${task['scannedBarcodeCount'] ?? 0}  \n signature_count :  ${task['signature_count'] ?? 0}');
//
//         ServiceJobs job = ServiceJobs(
//           id: taskId,
//           x_studio_site_address_1: (task['x_studio_site_address_1'] is String) ? task['x_studio_site_address_1'] : '',
//           date_assign: (task['date_assign'] is String) ? task['date_assign'] : '',
//           partnerPhone: (task['partner_phone'] is String) ? task['partner_phone'] : '',
//           partner_email: (task['partner_email'] is String) ? task['partner_email'] : '',
//           name: (task['name'] is String) ? task['name'] : '',
//           user_names: userNames,
//           user_ids: userIds,
//           project_id: (task['project_id'] is List<dynamic> && task['project_id'].length > 1)
//               ? task['project_id'][1] as String
//               : null,
//           install_status: (task['install_status'] is String)
//               ? task['install_status']
//               : '',
//           scannedBarcodeCount: task['scannedBarcodeCount'] ?? 0,
//           checklist_current_count: task['checklist_current_count'] ?? 0,
//           signature_count: task['signature_count'] ?? 0,
//           barcodeTotalCount: task['barcodeTotalCount'] ?? 0,
//           checklistTotalCount: task['checklistTotalCount'] ?? 0,
//         );
//         try {
//           await box.put(job.id, job);
//           print("Job saved: ${job.id}");
//         } catch (e) {
//           print("Error saving jobs to Hive: $e");
//         }
//       }
//     } catch (e) {
//       print("Error saving jobs to Hive: $e");
//     }
//   }
//
//   Future<void> _initializeHive() async {
//     await Hive.initFlutter();
//     Hive.registerAdapter(ServiceJobsAdapter());
//     await Hive.openBox<ServiceJobs>('serviceListBox');
//     Hive.registerAdapter(AssigneeAdapter());
//     await Hive.openBox<Assignee>('assignees');
//   }
//
//
//   Future<void> loadJobsFromHive() async {
//     print("Loading jobs from Hive...");
//
//     try {
//       // Ensure the box is opened
//       if (!Hive.isBoxOpen('serviceListBox')) {
//         await Hive.openBox<ServiceJobs>('serviceListBox');
//       }
//
//       final box = Hive.box<ServiceJobs>('serviceListBox');
//
//       if (box.isEmpty) {
//         print("No jobs found in the Hive box.");
//       } else {
//         var jobMaps = box.values.map((job) => job.toMap()).toList();
//
//         // Filtering logic...
//         if (selectedDate != null) {
//           String startDate = selectedDate!.toIso8601String().split('T')[0] + ' 00:00:00';
//           String endDate = selectedDate!.toIso8601String().split('T')[0] + ' 23:59:59';
//           jobMaps = jobMaps.where((job) {
//             DateTime jobDate = DateTime.parse(job['date_assign']);
//             return jobDate.isAfter(DateTime.parse(startDate).subtract(Duration(seconds: 1))) &&
//                 jobDate.isBefore(DateTime.parse(endDate).add(Duration(seconds: 1)));
//           }).toList();
//         }
//         if (valueStatus.isNotEmpty) {
//           jobMaps = jobMaps.where((job) {
//             return job['install_status'] == valueStatus;
//           }).toList();
//         }
//         if (assigneeValue != null) {
//           // jobMaps = jobMaps.where((job) {
//           //   return (job['user_ids'] as List<dynamic>).contains(assigneeValue);
//           // }).toList();
//         }
//
//         print('jobMaps  :  $jobMaps');
//
//         setState(() {
//           serviceJobsDetailes = jobMaps;
//           filteredJobs = _filterJobs(searchText);
//           isLoading = false;
//         });
//
//         print("Jobs successfully loaded from Hive.");
//       }
//     } catch (e) {
//       print("Error loading jobs from Hive: $e");
//     }
//   }
//
//
//   List<dynamic> _filterJobs(String searchText) {
//     print("Connectivity result: $isNetworkAvailable");
//
//     if (!isNetworkAvailable) {
//       print(serviceJobsDetailes);
//       print("dddddddddvvvvvvvvvvvvvvvvvvvvvvvvdddddddd");
//       print("ddddddddddddddddddddd");
//       if (searchText.isEmpty) return serviceJobsDetailes;
//
//       return serviceJobsDetailes.where((job) {
//         return job['name'].toLowerCase().contains(searchText.toLowerCase()) ||
//             job['x_studio_site_address_1']
//                 .toLowerCase()
//                 .contains(searchText.toLowerCase());
//       }).toList();
//     } else {
//       if (searchText.isEmpty) {
//         setState(() {
//           filteredJobs = serviceJobsDetailes;
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           filteredJobs = serviceJobsDetailes.where((job) {
//             String name = job['name']?.toString() ?? 'None';
//             String address =
//                 job['x_studio_site_address_1']?.toString() ?? 'None';
//             String assigneesString = (job['user_names']?.isNotEmpty ?? false)
//                 ? (job['user_names'] as List<dynamic>).join(', ')
//                 : 'None';
//             String installStatus = job['install_status']?.toString() ?? 'None';
//
//             final nameMatches =
//             name.toLowerCase().contains(searchText.toLowerCase());
//             final addressMatches =
//             address.toLowerCase().contains(searchText.toLowerCase());
//             final assigneesMatches = assigneesString
//                 .toLowerCase()
//                 .contains(searchText.toLowerCase());
//             final statusMatches =
//             installStatus.toLowerCase().contains(searchText.toLowerCase());
//
//             return nameMatches ||
//                 addressMatches ||
//                 assigneesMatches ||
//                 statusMatches;
//           }).toList();
//           isLoading = false;
//         });
//       }
//
//       return filteredJobs;
//     }
//   }
//
//   Future<void> getAssignees() async {
//     print("$isNetworkAvailable/Checking connisNetworkAvailableectivity...");
//     if (!isNetworkAvailable) {
//       print("ddddddddddisNetworkAvailableddddddddddd");
//       loadAssigneesFromHive();
//       return;
//     } else {
//       print("333333333333333333333333333333333333");
//       final prefs = await SharedPreferences.getInstance();
//       userId = prefs.getInt('userId') ?? 0;
//       try {
//         final assigneesDetails = await client?.callKw({
//           'model': 'res.users',
//           'method': 'search_read',
//           'args': [[]],
//           'kwargs': {
//             'fields': [
//               'id',
//               'name',
//             ],
//           },
//         });
//         for (var item in assigneesDetails) {
//           assignees_items.add(item['name']);
//           assignees_ids.add(item['id']);
//         }
//         print("dddddddddddddddddddddddddddddddddddddddddddddddd");
//         await saveAssigneesJobsToHive();
//       } catch (e) {
//         print('Error: $e');
//       }
//     }
//   }
//
//   Future<void> loadAssigneesFromHive() async {
//     var box = await Hive.openBox<Assignee>('assignees');
//     assignees_items.clear();
//     assignees_ids.clear();
//     for (int i = 0; i < box.length; i++) {
//       final assignee = box.getAt(i);
//
//       if (assignee != null) {
//         assignees_items.add(assignee.name);
//         assignees_ids.add(assignee.id);
//       }
//     }
//   }
//
//
//   Future<void> saveAssigneesJobsToHive() async {
//     print('Assignees ssssssssssssssssssssaved to Hive');
//     var box = await Hive.openBox<Assignee>('assignees');
//     await box.clear();
//     for (int i = 0; i < assignees_items.length; i++) {
//       final assignee = Assignee(
//         id: assignees_ids[i],
//         name: assignees_items[i],
//       );
//       await box.add(assignee);
//     }
//
//     print('Assignees saved to Hive');
//   }
//
//   // Future<void> getUserProfile() async {
//   //   if (!isNetworkAvailable) {
//   //     print("ddddddddddisNetworkAvailableddddddddddd");
//   //     // loadProfilePicUrl();
//   //     return;
//   //   } else {
//   //     final prefs = await SharedPreferences.getInstance();
//   //
//   //     userId = prefs.getInt('userId') ?? 0;
//   //
//   //     try {
//   //       final userDetails = await client?.callKw({
//   //         'model': 'res.users',
//   //         'method': 'search_read',
//   //         'args': [
//   //           [
//   //             ['id', '=', userId]
//   //           ]
//   //         ],
//   //         'kwargs': {
//   //           'fields': [
//   //             'image_1920'
//   //           ],
//   //         },
//   //       });
//   //       if (userDetails != null && userDetails.isNotEmpty) {
//   //         final user = userDetails[0];
//   //         final imageBase64 = user['image_1920'].toString();
//   //         if (imageBase64 != null && imageBase64 != 'false') {
//   //           final imageData = base64Decode(imageBase64);
//   //           setState(() {
//   //             profilePicUrl = MemoryImage(Uint8List.fromList(imageData));
//   //           });
//   //           final profileBox = await Hive.openBox('profileBox');
//   //           await profileBox.put('profilePicUrl', imageBase64);
//   //         }
//   //       }
//   //     } catch (e) {
//   //       print('Error: $e');
//   //     }
//   //   }
//   // }
//
//   Future<bool> _onWillPop() async {
//     // Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
//     // _controller.index = -1;
//     return false;
//   }
//
//   Future<void> reloadNotification() async {
//     getNotificationCount();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         // appBar: AppBar(
//         //   title: const Text(
//         //     'Service Jobs',
//         //     style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//         //   ),
//         //   backgroundColor: Colors.green,
//         //   automaticallyImplyLeading: false,
//         //   // iconTheme: const IconThemeData(
//         //   //   color: Colors.white,
//         //   // ),
//         //   actions: [
//         //     GestureDetector(
//         //       onTap: () {
//         //         Navigator.pushNamed(context, '/notifications',
//         //             arguments: {'reloadNotification': reloadNotification});
//         //       },
//         //       child: Stack(
//         //         clipBehavior: Clip.none,
//         //         children: [
//         //           Icon(Icons.notifications_rounded,
//         //               color: Colors.white, size: 35),
//         //           if (unreadCount > 0)
//         //             Positioned(
//         //             right: -3,
//         //             top: -3,
//         //             child: Container(
//         //               padding: EdgeInsets.all(4),
//         //               decoration: BoxDecoration(
//         //                 color: Colors.red,
//         //                 shape: BoxShape.circle,
//         //               ),
//         //               constraints: BoxConstraints(
//         //                 minWidth: 16,
//         //                 minHeight: 16,
//         //               ),
//         //               child: Center(
//         //                 child: Text(
//         //                   unreadCount.toString(),
//         //                   style: TextStyle(
//         //                     color: Colors.white,
//         //                     fontWeight: FontWeight.bold,
//         //                     fontSize: 10,
//         //                   ),
//         //                 ),
//         //               ),
//         //             ),
//         //           ),
//         //         ],
//         //       ),
//         //     ),
//         //     const SizedBox(width: 10),
//         //     Container(
//         //       width: 50.0,
//         //       height: 50.0,
//         //       decoration: BoxDecoration(
//         //         shape: BoxShape.circle,
//         //         color: Colors.black.withOpacity(0.2),
//         //       ),
//         //       child: GestureDetector(
//         //         onTap: () {
//         //           Navigator.pushNamed(context, '/profile_main',
//         //               arguments: {
//         //                 'reloadProfile': reloadProfile,
//         //               });
//         //         },
//         //         child: CircleAvatar(
//         //           radius: 20.0,
//         //           backgroundColor: Colors.grey[400],
//         //           child: Stack(
//         //             children: [
//         //               if (profilePicUrl != null)
//         //                 Positioned.fill(
//         //                   child: ClipOval(
//         //                     child: profilePicUrl != null
//         //                         ? Image(
//         //                       image: profilePicUrl!,
//         //                       fit: BoxFit.cover,
//         //                       width: 80.0,
//         //                       height: 80.0,
//         //                       errorBuilder: (BuildContext context,
//         //                           Object exception, StackTrace? stackTrace) {
//         //                         return Icon(
//         //                           Icons.person,
//         //                           size: 54,
//         //                           color: Colors.white,
//         //                         );
//         //                       },
//         //                     )
//         //                         : Icon(Icons.person, size: 54, color: Colors.white),
//         //                   ),
//         //                 ),
//         //               if (profilePicUrl == null)
//         //                 Positioned.fill(
//         //                   child: Container(
//         //                     decoration: BoxDecoration(
//         //                       shape: BoxShape.circle,
//         //                       color: Colors.grey[400],
//         //                     ),
//         //                     child: Center(
//         //                       child: Icon(Icons.person),
//         //                     ),
//         //                   ),
//         //                 )
//         //             ],
//         //           ),
//         //         ),
//         //       ),
//         //     ),
//         //     const SizedBox(width: 10),
//         //   ],
//         // ),
//         body: Column(
//           children: [
//             Padding(
//               padding:
//               const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
//               child: Row(
//                 children: [
//                   Expanded(
//                       child: TextField(
//                         decoration: InputDecoration(
//                           prefixIcon: Icon(Icons.search),
//                           hintText: 'Search jobs...',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8.0),
//                             borderSide: BorderSide.none,
//                           ),
//                           filled: true,
//                           fillColor: Colors.grey[200],
//                         ),
//                         onChanged: (searchValue) {
//                           if (_debounce?.isActive ?? false) _debounce!.cancel();
//
//                           _debounce = Timer(Duration(milliseconds: 500), () {
//                             setState(() {
//                               searchText = searchValue.trim();
//                               offset = 0;
//                               hasMoreData = true;
//                               serviceJobsDetailes.clear();
//                               getServiceJobs();
//                             });
//                           });
//                         },
//                       )),
//                   const SizedBox(width: 10),
//                   Container(
//                     decoration: BoxDecoration(
//                       color: Colors.green,
//                       borderRadius: BorderRadius.circular(8.0),
//                     ),
//                     child: IconButton(
//                       icon: Icon(Icons.tune, color: Colors.white),
//                       onPressed: () {
//                         _filterServiceJobs(context);
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             if (valueStatus.isNotEmpty ||
//                 assigneeValue != 0 ||
//                 selectedDate != null)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 8.0),
//                 child: ElevatedButton(
//                   onPressed: _clearFilters,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red,
//                   ),
//                   child: const Text(
//                     'Clear Filters',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ),
//             Expanded(
//               child: isLoading
//                   ? ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: 5,
//                 itemBuilder: (context, index) {
//                   return Card(
//                     elevation: 5,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Shimmer.fromColors(
//                             baseColor: Colors.grey[300]!,
//                             highlightColor: Colors.grey[100]!,
//                             child: Container(
//                               width: double.infinity,
//                               height: 24,
//                               color: Colors.white,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: Shimmer.fromColors(
//                                   baseColor: Colors.grey[300]!,
//                                   highlightColor: Colors.grey[100]!,
//                                   child: Container(
//                                     width: double.infinity,
//                                     height: 16,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               Shimmer.fromColors(
//                                 baseColor: Colors.grey[300]!,
//                                 highlightColor: Colors.grey[100]!,
//                                 child: Container(
//                                   width: 60,
//                                   height: 16,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 8),
//                           Shimmer.fromColors(
//                             baseColor: Colors.grey[300]!,
//                             highlightColor: Colors.grey[100]!,
//                             child: Container(
//                               width: double.infinity,
//                               height: 16,
//                               color: Colors.white,
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//                           Shimmer.fromColors(
//                             baseColor: Colors.grey[300]!,
//                             highlightColor: Colors.grey[100]!,
//                             child: Container(
//                               width: double.infinity,
//                               height: 16,
//                               color: Colors.white,
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//                           Shimmer.fromColors(
//                             baseColor: Colors.grey[300]!,
//                             highlightColor: Colors.grey[100]!,
//                             child: Container(
//                               width: double.infinity,
//                               height: 50,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               )
//                   : filteredJobs.isEmpty
//                   ? const Expanded(
//                 child: Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.miscellaneous_services,
//                         color: Colors.black,
//                         size: 92,
//                       ),
//                       SizedBox(height: 20),
//                       Text(
//                         "There are no Sevice Jobs available to display",
//                         style: TextStyle(
//                           fontSize: 16.0,
//                           color: Colors.black,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               )
//                   : ListView.builder(
//                 controller: _scrollController,
//                 padding: EdgeInsets.all(16),
//                 itemCount: filteredJobs.length,
//                 itemBuilder: (context, index) {
//                   final job = filteredJobs[index];
//                   String name = '';
//                   String address = '';
//                   String assigneesString = '';
//
//                   if (job['name'] is String &&
//                       job['name'].isNotEmpty) {
//                     name = job['name'];
//                   } else {
//                     name = "None";
//                   }
//                   if (job.containsKey('x_studio_site_address_1') &&
//                       job['x_studio_site_address_1'] is String &&
//                       job['x_studio_site_address_1'].isNotEmpty) {
//                     address = job['x_studio_site_address_1'];
//                   } else {
//                     address = "None";
//                   }
//                   if (job['user_names'] is List &&
//                       job['user_names'].isNotEmpty) {
//                     assigneesString =
//                         (job['user_names'] as List<dynamic>)
//                             .join(', ');
//                   }
//                   print(job['barcodeTotalCount']);
//                   print("job['barcodeTotalCount']job['barcodeTotalCount']");
//                   int? scannedCount = scannedBarcodeCount;
//                   int checklistCount = (job['checklist_current_count'] ?? 0).toInt();
//                   int signatureCount = (job['signature_count'] ?? 0).toInt();
//                   int progressCurrent = job['scannedBarcodeCount'] + checklistCount + signatureCount;
//                   int progressTotal = job['barcodeTotalCount'] + 3+ job['checklistTotalCount'];
//                   // int progressCurrent = scannedCount! + checklistCount + signatureCount;
//                   // int progressTotal = job['barcodeTotalCount'] + 3 + job['checklistTotalCount'];
//
//                   return GestureDetector(
//                     onTap: () {
//                       progressChange = false;
//                       if (job['install_status'] == 'pending')
//                         setState(() {
//                           progressChange = true;
//                         });
//                       Navigator.pushNamed(
//                           context, '/service_form_view',
//                           arguments: {
//                             'job_id': job['id'],
//                             'x_studio_site_address_1':
//                             job['x_studio_site_address_1'],
//                             'date_assign': job['date_assign'],
//                             'user_names': job['user_names'],
//                             'project_id': job['project_id'],
//                             'install_status': job['install_status'],
//                             'progressChange': progressChange,
//                             'name': job['name'],
//                             'partner_phone': job['partner_phone'],
//                             'partner_email': job['partner_email'],
//                             'reloadService': reloadService
//                           });
//                     },
//                     child: JobCard(
//                       name: name,
//                       status: job['install_status'] ?? 'Unknown',
//                       location: address,
//                       scheduledTime:
//                       job['date_assign']?.toString() ?? 'No Date',
//                       assignees: assigneesString,
//                       progressCurrent: progressCurrent,
//                       progressTotal: progressTotal,
//                       attachments: 0,
//                       checks_checklist: job['checklist_current_count']??0,
//                       checks_total_checklist: job['checklistTotalCount']??0,
//                       barcode_scanned: job['scannedBarcodeCount']??0,
//                       barcode_total: job['barcodeTotalCount']??0,
//                       checks_signature: job['signature_count']??0,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _clearFilters() {
//     setState(() {
//       // searchText = '';
//       valueStatus = '';
//       assigneeValue = 0;
//       selectedDate = null;
//       dateController.clear();
//       filteredJobs = serviceJobsDetailes;
//       offset = 0;
//       hasMoreData = true;
//       serviceJobsDetailes.clear();
//     });
//     getServiceJobs();
//   }
//
//   Widget _buildLabelWidget(String labelText, Color color) {
//     return Text(
//       labelText,
//       style: TextStyle(
//         color: color,
//         fontWeight: FontWeight.bold,
//         fontSize: 9,
//       ),
//     );
//   }
//
//   void _filterServiceJobs(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (context) {
//         return Container(
//           width: MediaQuery.of(context).size.width * 0.89,
//           child: Padding(
//             padding: EdgeInsets.only(
//               bottom: MediaQuery.of(context).viewInsets.bottom,
//             ),
//             child: SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     const Text(
//                       'Filter Installation Jobs',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     SizedBox(
//                       width: 200,
//                       child: DropdownButtonFormField<String>(
//                         value: valueStatus.isNotEmpty ? valueStatus : null,
//                         decoration: const InputDecoration(
//                           labelText: 'Select Status',
//                           border: OutlineInputBorder(),
//                         ),
//                         items: [
//                           {'value': 'pending', 'label': "Pending"},
//                           {'value': 'progress', 'label': "In Progress"},
//                           {'value': 'done', 'label': "Installation Complete"},
//                           {'value': 'incomplete', 'label': "Incomplete"},
//                           {'value': 'rescheduled', 'label': "Rescheduled"},
//                         ].map((status) {
//                           return DropdownMenuItem<String>(
//                             value: status['value'],
//                             child: Text(status['label']!),
//                           );
//                         }).toList(),
//                         onChanged: (value) {
//                           valueStatus = value!;
//                         },
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     DropdownSearch<int>(
//                       selectedItem: assigneeValue != 0 ? assigneeValue : null,
//                       dropdownDecoratorProps: const DropDownDecoratorProps(
//                         dropdownSearchDecoration: InputDecoration(
//                           border: OutlineInputBorder(),
//                           labelText: 'Select Assignee',
//                         ),
//                       ),
//                       items: assignees_ids,
//                       itemAsString: (int? item) =>
//                       assignees_items[assignees_ids.indexOf(item!)],
//                       onChanged: (value) {
//                         assigneeValue = value!;
//                       },
//                       popupProps: const PopupProps.menu(
//                         showSearchBox: true,
//                         searchFieldProps: TextFieldProps(
//                           decoration: InputDecoration(
//                             labelText: 'Search Assignee',
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     TextField(
//                       controller: dateController,
//                       decoration: const InputDecoration(
//                         labelText: 'Select Date',
//                         border: OutlineInputBorder(),
//                         suffixIcon: Icon(Icons.calendar_today),
//                       ),
//                       readOnly: true,
//                       onTap: () async {
//                         DateTime? pickedDate = await showDatePicker(
//                           context: context,
//                           initialDate: selectedDate ?? DateTime.now(),
//                           firstDate: DateTime(2000),
//                           lastDate: DateTime(2101),
//                         );
//                         if (pickedDate != null) {
//                           setState(() {
//                             selectedDate = pickedDate;
//                             dateController.text =
//                             "${pickedDate.toLocal()}".split(' ')[0];
//                           });
//                         }
//                       },
//                     ),
//                     const SizedBox(
//                       height: 8,
//                     ),
//                     ElevatedButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         offset = 0;
//                         hasMoreData = true;
//                         serviceJobsDetailes.clear();
//                         getServiceJobs();
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                       ),
//                       child: const Text(
//                         'Apply Filters',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
// class JobCard extends StatelessWidget {
//   final String name;
//   final String status;
//   final String location;
//   final String scheduledTime;
//   final String assignees;
//   final int progressCurrent;
//   final int progressTotal;
//   final int attachments;
//   final int checks_checklist;
//   final int checks_total_checklist;
//   final int barcode_total;
//   final int barcode_scanned;
//   final int checks_signature;
//   final String? finishedText;
//
//   const JobCard({
//     Key? key,
//     required this.name,
//     required this.status,
//     required this.location,
//     required this.scheduledTime,
//     required this.assignees,
//     required this.progressCurrent,
//     required this.progressTotal,
//     required this.attachments,
//     required this.checks_checklist,
//     required this.checks_total_checklist,
//     required this.barcode_total,
//     required this.barcode_scanned,
//     required this.checks_signature,
//     this.finishedText,
//   }) : super(key: key);
//
//   Color determineStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'done':
//         return Colors.green;
//       case 'progress':
//         return Colors.orange;
//       case 'pending':
//         return Colors.blue;
//       case 'incomplete':
//         return Colors.red[900]!;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   String capitalizeFirstLetter(String text) {
//     return text.isNotEmpty
//         ? '${text[0].toUpperCase()}${text.substring(1)}'
//         : text;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final Color statusColor = determineStatusColor(status);
//     final String capitalizedStatus = capitalizeFirstLetter(status);
//     return Card(
//       elevation: 5,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     name,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     SizedBox(
//                       width: MediaQuery.of(context).size.width * 0.25,
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.circle,
//                             color: statusColor,
//                             size: 16,
//                           ),
//                           SizedBox(width: 8),
//                           Text(
//                             capitalizedStatus,
//                             style: TextStyle(color: statusColor, fontSize: 16),
//                           ),
//                         ],
//                       ),
//                     ),
//                     SizedBox(height: 8),
//                     // Using a SizedBox for constraint
//                     SizedBox(
//                       width: MediaQuery.of(context).size.width * 0.25,
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: LinearProgressIndicator(
//                               value: progressCurrent / progressTotal,
//                               backgroundColor: Colors.grey[200],
//                               color: statusColor,
//                             ),
//                           ),
//                           // SizedBox(width: 10),
//                           // Text(
//                           //   '$progressCurrent/$progressTotal',
//                           //   style: TextStyle(color: Colors.black54),
//                           // ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Flexible(
//                   flex: 3,
//                   child: Row(
//                     children: [
//                       Icon(Icons.location_on,
//                           color: Colors.blueAccent, size: 18),
//                       const SizedBox(width: 5),
//                       Flexible(
//                         child: Text(
//                           location,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(color: Colors.black54, fontSize: 14),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const Spacer(),
//               ],
//             ),
//             const SizedBox(height: 4),
//             Row(
//               children: [
//                 Icon(Icons.schedule, color: Colors.blueAccent, size: 18),
//                 const SizedBox(width: 5),
//                 Text(
//                   scheduledTime,
//                   style: TextStyle(color: Colors.black54, fontSize: 14),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'Assignees: $assignees',
//               style: const TextStyle(
//                   color: Colors.black87, fontStyle: FontStyle.italic),
//             ),
//             SizedBox(height: 10),
//             if (status == 'done' || status == 'pending')
//               Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(20),
//                   color: status == 'done' ? Colors.green[100] : Colors.blue[50],
//                 ),
//                 width: MediaQuery.of(context).size.width,
//                 height: 50,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       status == 'done' ? 'FINISHED' : status.toUpperCase(),
//                       style: TextStyle(
//                         color: status == 'done' ? Colors.green : Colors.blue,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Icon(
//                       status == 'done' ? Icons.verified : Icons.schedule,
//                       color: status == 'done'
//                           ? Colors.green[800]
//                           : Colors.blue[800],
//                     ),
//                   ],
//                 ),
//               )
//             else
//               Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(20),
//                   color: statusColor.withOpacity(0.15),
//                 ),
//                 width: MediaQuery.of(context).size.width,
//                 height: 50,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     Container(
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Image.asset(
//                             'assets/barcode.png',
//                             width: 24,
//                             height: 24,
//                           ),
//                           if (barcode_total != barcode_scanned || barcode_total == 0)
//                             Text('$barcode_scanned/$barcode_total')
//                           else
//                             Icon(Icons.verified),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Icon(Icons.fact_check_outlined),
//                           if (checks_checklist != checks_total_checklist || checks_total_checklist == 0)
//                             Text('$checks_checklist/$checks_total_checklist')
//                           else
//                             Icon(Icons.verified),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Image.asset(
//                             'assets/sign.png',
//                             width: 24,
//                             height: 24,
//                           ),
//                           if (checks_signature != 3)
//                             Text('$checks_signature/3')
//                           else
//                             Icon(Icons.verified),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
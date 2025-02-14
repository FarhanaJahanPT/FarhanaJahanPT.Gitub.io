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

import '../offline_db/installation_list/assignee.dart';
import '../offline_db/installation_list/installing_job.dart';
import '../offline_db/start_finish_job/task_job.dart';
import 'package:http/http.dart' as http;

class InstalledListView extends StatefulWidget {
  final VoidCallback? onRefresh;

  InstalledListView({this.onRefresh});

  @override
  State<InstalledListView> createState() => _InstalledListViewState();
}

class _InstalledListViewState extends State<InstalledListView> {
  final NotchBottomBarController _controller =
      NotchBottomBarController(index: 0);
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
  List<dynamic> installingJobs = [];
  final TextEditingController _searchController = TextEditingController();
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
  int barcodeTotalCount = 0;
  int scannedBarcodeCount = 0;
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
  }

  Future<void> _initialize() async {
    await _checkConnectivity();
    _hiveInitFuture = _initializeHive();
    _scrollController.addListener(_scrollListener);
    _initializeOdooClient();
    getInstallingJobs();
    // getAssignees();
    // getUserProfile();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      isNetworkAvailable = connectivityResult != ConnectivityResult.none;
    });
    Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      setState(() {
        isNetworkAvailable = result != ConnectivityResult.none;
      });
      if (isNetworkAvailable) {}
    });
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        !isLoading &&
        hasMoreData) {
      getInstallingJobs(fromScroll: true);
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

  Future<void> reloadInstalling() async {
    offset = 0;
    hasMoreData = true;
    installingJobs.clear();
    getInstallingJobs();
  }

  Future<void> reloadProfile() async {
    getUserProfile();
  }


  Future<List<Map<String, dynamic>>> loadJobsFromHive() async {
    final box = await Hive.openBox<InstallingJob>('installationListBox');
    List<Map<String, dynamic>> allJobs =
        box.values.map((job) => job.toMap()).toList();

    log('allJobs  :  $allJobs');

    bool isFilterSelected =
        valueStatus.isNotEmpty || assigneeValue != 0 || selectedDate != null;

    List<Map<String, dynamic>> filteredJobs = allJobs.where((job) {
      if (valueStatus.isNotEmpty && job['install_status'] != valueStatus) {
        return false;
      }

      if (assigneeValue != 0 &&
          !(job['user_ids']?.contains(assigneeValue) ?? false)) {
        return false;
      }

      if (selectedDate != null) {
        DateTime jobDate =
            DateTime.tryParse(job['date_assign'] ?? '') ?? DateTime(1970);
        if (jobDate.toLocal().toString().split(' ')[0] !=
            selectedDate!.toLocal().toString().split(' ')[0]) {
          return false;
        }
      }

      return true;
    }).toList();

    if (isFilterSelected && filteredJobs.isEmpty) {
      return [];
    }
    print("ooooooooooooooooodfilteredJobs$filteredJobs");
    return filteredJobs;
  }

  Future<void> getInstallingJobs({bool fromScroll = false}) async {
    if (!isNetworkAvailable) {
      List<Map<String, dynamic>> cachedJobs = await loadJobsFromHive();
      setState(() {
        installingJobs = cachedJobs;
        filteredJobs = _filterJobs(searchText);
        print("filteredJobscccccfilteredJobs$filteredJobs");
        isLoading = false;
      });
      return;
    } else {
      if (!fromScroll) {
        setState(() {
          isLoading = true;
        });
      }
      final prefs = await SharedPreferences.getInstance();
      // userId = prefs.getInt('userId') ?? 0;
      teamId = prefs.getInt('teamId') ?? 0;
      final baseUrl = prefs.getString('url') ?? 0;
      print("teamIdteamIdteamIdteamId$baseUrl");

      try {
        print("111111111111111111111111111111111");
        final List<dynamic> filters = [
          // ['x_studio_proposed_team', '=', userId],
          ['project_id', '=', 'New Installation'],
          [
            'x_studio_type_of_service',
            'in',
            ['New Installation', 'Service']
          ],
          ['worksheet_id', '!=', false],
          ['team_lead_user_id', '=', userId],
        ];
        if (valueStatus.isNotEmpty) {
          filters.add(['install_status', '=', valueStatus]);
        }
        if (assigneeValue != 0) {
          filters.add([
            'user_ids',
            'in',
            [assigneeValue]
          ]);
        }
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
        print("2222222222222222222222222222222");
        // final installingCalendarDetails = await client!.callRPC('/rebates/project', 'call', {
        //   "id": teamId,
        //   "type": 'New Installation'
        // });
        // final installingCalendarDetails = await client?.callKw({
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
        //       'partner_id'
        //     ],
        //     if (searchText.isEmpty) 'limit': limit,
        //     if (searchText.isEmpty) 'offset': offset,
        //   },
        // });
        // print("3333333333333333333333$installingCalendarDetails");
        // if (installingCalendarDetails != null &&
        //     installingCalendarDetails.isNotEmpty) {
        //   List<Map<String, dynamic>> detailedTasks = [];
        //   for (var task in installingCalendarDetails) {
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
            // print("userDetailsuserDetailsuserDetails");
            // if (userDetails != null && userDetails.isNotEmpty) {
            //   teamId = task['team_lead_id'][0]??0;
            //   task['user_name'] = userDetails[0]['name'];
            // } else {
            //   task['user_name'] = 'Unknown'; // Default value if no user is found
            // }
        final Uri url = Uri.parse('$baseUrl/rebates/project_task');
        final installingCalendarDetails = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "team_id": teamId,
              "type": 'New Installation',
              "install_status": valueStatus.isNotEmpty ? valueStatus : null,
              "selected_date": selectedDate != null ? selectedDate!.toIso8601String().split('T')[0] : null,
              "searchText": searchText.isNotEmpty ? searchText : null,
            }
          }),
        );
        // print(installingCalendarDetails.body);
        print("ddddddddddddddddddddinsktallingCalendarDetailsinsktallingCalendarDetailsinsktallingCalendarDetails");
        final Map<String, dynamic> jsonResponse = json.decode(installingCalendarDetails.body);
        // print("3333333333333333333333$jsonResponse");
        if (jsonResponse['result']['status'] == 'success' &&
            jsonResponse['result']['tasks'].isNotEmpty) {
          List<Map<String, dynamic>> detailedTasks = [];
          print(jsonResponse['result']['tasks']);
          for (var task in jsonResponse['result']['tasks']) {
            print(task['install_status']);
            print("pppppppplkjhhhhhhhhhhhhhhhhhhhhhhh");
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
            // print("3333333333333333333333$jsonUserDetailsResponse");
            // print("userDetailsuserDetailsuserDetails${jsonUserDetailsResponse['result']['team_member_data'][0]['name']}");
            if (jsonUserDetailsResponse['result']['status'] == 'success' && jsonUserDetailsResponse['result']['team_member_data'].isNotEmpty) {
              teamId = task['team_lead_id'][0]??0;
              task['user_name'] = jsonUserDetailsResponse['result']['team_member_data'][0]['name'];
            } else {
              task['user_name'] = 'Unknown';
            }
            print("4444444444444444444444444cccccccccccccccccccccc44${task['partner_id'][0]}");
            // task['user_names'] =
            //     userDetails?.map((user) => user['name']).toList() ?? [];
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
              // print("555555555555555555555dddddd55555555${jsonPartnerDetailsResponse['result']}");
              // print("55555555555555555555555555555${jsonPartnerDetailsResponse['result']['res_partner_data'][0]['phone']}");

              task['partner_phone'] = jsonPartnerDetailsResponse['result']['res_partner_data'][0]['phone'];
              task['partner_email'] = jsonPartnerDetailsResponse['result']['res_partner_data'][0]['email'];
            }
            if (task.containsKey('id') && task['id'] != null) {
              final Uri url = Uri.parse('$baseUrl/rebates/task_worksheet');
              final worksheet = await http.post(
                url,
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "jsonrpc": "2.0",
                  "method": "call",
                  "params": {
                    "task_id": task['id'],
                    "type": "New Installation"
                  }
                }),
              );
              // print(worksheet.body);
              print("ffffffffffffffffffffsssssssssssfccccccfffffmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm");
              final Map<String, dynamic> jsonWorksheetResponse = json.decode(worksheet.body);
              // print("3333333333333333333333$jsonWorksheetResponse");
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
              //       'panel_count',
              //       'inverter_count',
              //       'battery_count',
              //       'team_member_ids','team_lead_id'
              //     ],
              //   },
              // });
              // print("66666666666666666666666666$worksheet");

              if (jsonWorksheetResponse['result']['status'] == 'success' && jsonWorksheetResponse['result']['worksheet_data'].isNotEmpty) {
                print("worksheetwodddddddrksheetworksheet$jsonWorksheetResponse");
                task['worksheetId'] = jsonWorksheetResponse['result']['worksheet_data'][0]['id'];
                task['memberId'] = jsonWorksheetResponse['result']['worksheet_data'][0]['team_lead_id'];
                task['team_member_ids'] = jsonWorksheetResponse['result']['worksheet_data'][0]['team_member_ids'];
                try {
                  // print(worksheet.body);
                  print("fffffffffffffffffssssssssssffffccccccfffffmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm");
                  final Map<String, dynamic> jsonWorksheetResponse = json.decode(worksheet.body);
                  // print("dddddddddddddddddddddddddddddddddzzzzzzzzzzz$jsonWorksheetResponse");
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
                  // print(scanningProducts.body);
                  // print("fffffffffffffffffssssssssssssssssssffffccccccfffffmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm");
                  final Map<String, dynamic> jsonScanningProductsResponse = json.decode(scanningProducts.body);
                  // print("3333333333333333333333$jsonScanningProductsResponse");
                  // final scanningProducts = await client?.callKw({
                  //   'model': 'stock.lot',
                  //   'method': 'search_read',
                  //   'args': [
                  //     [
                  //       ['worksheet_id', '=', jsonWorksheetResponse['result']['worksheet_data'][0]['id']],
                  //       ['user_id', '=', userId],
                  //     ],
                  //   ],
                  //   'kwargs': {},
                  // });
                  // print("7777777777777777777777777$scanningProducts");
                  if (jsonScanningProductsResponse['result']['status'] == 'success' && jsonScanningProductsResponse['result']['stock_lot'].isNotEmpty) {
                    scannedBarcodeCount = jsonScanningProductsResponse.length;
                  } else {
                    scannedBarcodeCount = 0;
                  }
                } catch (e) {
                  print("eeeeeeeeeeeeeeeeeeeeeeeeeeee$e");
                }
              }
              List<dynamic>? checklist;
              if (jsonWorksheetResponse['result']['status'] == 'success' && jsonWorksheetResponse['result']['worksheet_data'].isNotEmpty) {
                task['checklist_count'] = jsonWorksheetResponse['result']['worksheet_data'][0]['checklist_count'];
                // checklist = await client?.callKw({
                //   'model': 'installation.checklist.item',
                //   'method': 'search_read',
                //   'args': [
                //     [
                //       ['worksheet_id', '=', jsonWorksheetResponse['result']['worksheet_data'][0]['id']],
                //       ['user_id', '=', userId],
                //     ],
                //   ],
                //   'kwargs': {
                //     'fields': ['id', 'display_name'],
                //   },
                // });
                final Uri url = Uri.parse('$baseUrl/rebates/installation_checklist_item');
                final checklistitem = await http.post(
                  url,
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "jsonrpc": "2.0",
                    "method": "call",
                    "params": {
                      "worksheet_id": jsonWorksheetResponse['result']['worksheet_data'][0]['id'],
                      "teamId": teamId
                    }
                  }),
                );
                print(checklistitem.body);
                print("fffffffffffffffffssschecklisttttttttttttttttsssssssssssssssffffccccccfffffmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm");
                final Map<String, dynamic> jsonChecklistResponse = json.decode(checklistitem.body);
                checklist = jsonChecklistResponse['result']['installation_checklist_item_data'];
                print("jsonChecklistResponsejsonChecklistResponsejsonChecklistResponse$jsonChecklistResponse");
                print("8888888888888888888888888888$checklist");
              }
              final Uri signatureUrl = Uri.parse('$baseUrl/rebates/project_task');
              final signatureDetails = await http.post(
                signatureUrl,
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "jsonrpc": "2.0",
                  "method": "call",
                  "params": {
                    "team_id": teamId,
                    "type": 'New Installation',
                    "id": task['id'],
                  }
                }),
              );
              // print(signatureDetails.body);
              // print("jsonSignatureDetailsResponsejsonSignatureDetailsResponsess");
              final Map<String, dynamic> jsonSignatureDetailsResponse = json.decode(signatureDetails.body);
              // print("333333jsonSignatureDetailsResponse3333333333333333$jsonSignatureDetailsResponse");
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
              //       ['team_lead_user_id', '=', userId],
              //       // ['x_studio_proposed_team', '=', userId],
              //       ['id', '=', task['id']]
              //     ]
              //   ],
              //   'kwargs': {
              //     'fields': [
              //       'install_signature',
              //       'customer_signature',
              //     ],
              //   },
              // });
              print("9999999999999999999999999999999$signatureDetails");
              if (jsonSignatureDetailsResponse['result']['status'] == 'success' && jsonSignatureDetailsResponse['result']['tasks'].isNotEmpty) {
                int signatureCount = 0;
                if (jsonSignatureDetailsResponse['result']['tasks'][0]['install_signature'] != null &&
                    jsonSignatureDetailsResponse['result']['tasks'][0]['install_signature'] != '' &&
                    jsonSignatureDetailsResponse['result']['tasks'][0]['install_signature'] != false) {
                  signatureCount += 1;
                }
                if (jsonSignatureDetailsResponse['result']['tasks'][0]['customer_signature'] != null &&
                    jsonSignatureDetailsResponse['result']['tasks'][0]['customer_signature'] != '' &&
                    jsonSignatureDetailsResponse['result']['tasks'][0]['customer_signature'] != false) {
                  signatureCount += 1;
                }
                // if (signatureDetails?.first?['witness_signature'] != null &&
                //     signatureDetails?.first?['witness_signature'] != '' &&
                //     signatureDetails?.first?['witness_signature'] != false) {
                //   signatureCount += 1;
                // }
                task['signature_count'] = signatureCount;
              }
              print("wddddddddddddddddddddxxxxxxxxxxx");
              int checklistCount = checklist?.length ?? 0;
              task['checklist_current_count'] = checklistCount;
              print(jsonWorksheetResponse['result']['worksheet_data'][0]['team_member_ids']);
              print(
                  "worksheet[0]['team_member_ids']worksheet[0]['team_member_ids']");
              task['team_member_ids'] = jsonWorksheetResponse['result']['worksheet_data'][0]['team_member_ids'];
              task['checklistTotalCount'] =
                  jsonWorksheetResponse['result']['worksheet_data'][0]['checklist_count'] ?? 0;
              task['barcodeTotalCount'] = (jsonWorksheetResponse['result']['worksheet_data'][0]['panel_count'] ?? 0) +
                  (jsonWorksheetResponse['result']['worksheet_data'][0]['inverter_count'] ?? 0) +
                  (jsonWorksheetResponse['result']['worksheet_data'][0]['battery_count'] ?? 0);
              task['scannedBarcodeCount'] = scannedBarcodeCount;
              detailedTasks.add(task);
            }
            setState(() {
              if (offset == 0 || searchText.isNotEmpty) {
                installingJobs = detailedTasks;
              } else {
                installingJobs.addAll(detailedTasks);
              }

              installingJobs = installingJobs.toSet().toList();
            });
          }
          // print("detailedTasksdetailedTasksdetailedTasks$detailedTasks");
          await saveInstallingJobsToHive(detailedTasks);
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
          installingJobs = cachedJobs;
          filteredJobs = _filterJobs(searchText);
          print(e);
          print("/333333333333filteredJobsfilteredJobs$e");
          isLoading = false;
        });
        return;
      }
    }
  }

  Future<void> saveInstallingJobsToHive(
      List<Map<String, dynamic>> detailedTasks) async {
    try {
      final box = await Hive.openBox<InstallingJob>('installationListBox');
      log('or  :  $detailedTasks');
      box.clear();

      for (var task in detailedTasks) {
        int taskId = task['id'] ?? 0;
        int worksheetId = task['worksheetId'] ?? 0;
        List<dynamic> memberId = (task['memberId'] is List<dynamic>) ? task['memberId'] : []; // Ensure it's stored as a list

        // List<String> userNames = (task['user_names'] as List<dynamic>)
        //     .map((e) => e.toString())
        //     .toList();
        String user_name = task['user_name'];
        List<int> userIds =
            (task['user_ids'] as List<dynamic>).map((e) => e as int).toList();

        List<int> teamMemberIds = (task['team_member_ids'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [];
        print(taskId);
        print("$memberId/teamMemberIdsteamMemberIdsteamMemberIds$teamMemberIds");
        InstallingJob newJob = InstallingJob(
          id: taskId,
          worksheetId: worksheetId,
          memberId: memberId,
          x_studio_site_address_1: (task['x_studio_site_address_1'] is String)
              ? task['x_studio_site_address_1']
              : '',
          date_assign:
              (task['date_assign'] is String) ? task['date_assign'] : '',
          partnerPhone:
              (task['partner_phone'] is String) ? task['partner_phone'] : '',
          partner_email:
              (task['partner_email'] is String) ? task['partner_email'] : '',
          name: (task['name'] is String) ? task['name'] : '',
          user_name: user_name,
          // user_names: user_names,
          user_ids: userIds,
          project_id: (task['project_id'] is List<dynamic> &&
                  task['project_id'].length > 1)
              ? task['project_id'][1] as String
              : null,
          install_status:
              (task['install_status'] is String) ? task['install_status'] : '',
          scannedBarcodeCount: task['scannedBarcodeCount'] ?? 0,
          checklist_current_count: task['checklist_current_count'] ?? 0,
          signature_count: task['signature_count'] ?? 0,
          barcodeTotalCount: task['barcodeTotalCount'] ?? 0,
          checklistTotalCount: task['checklistTotalCount'] ?? 0,
          team_member_ids: teamMemberIds,
        );

        if (box.containsKey(taskId)) {
          InstallingJob? existingJob = box.get(taskId);

          if (existingJob != newJob) {
            await box.put(taskId, newJob);
          } else {}
        } else {
          await box.put(taskId, newJob);
        }
        await box.put(taskId, newJob);
      }
    } catch (e) {}
  }

  Future<void> _initializeHive() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(InstallingJobAdapter().typeId)) {
      Hive.registerAdapter(InstallingJobAdapter());
    }
    await Hive.openBox<InstallingJob>('installationListBox');
    if (!Hive.isAdapterRegistered(AssigneeAdapter().typeId)) {
      Hive.registerAdapter(AssigneeAdapter());
    }
    await Hive.openBox<Assignee>('assignees');
  }

  List<dynamic> _filterJobs(String searchText) {
    List<dynamic> filteredList = installingJobs;

    if (!isNetworkAvailable) {
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

          final nameMatches =
              name.toLowerCase().contains(searchText.toLowerCase());
          final addressMatches =
              address.toLowerCase().contains(searchText.toLowerCase());
          final assigneesMatches =
              assigneesString.toLowerCase().contains(searchText.toLowerCase());
          final statusMatches =
              installStatus.toLowerCase().contains(searchText.toLowerCase());

          return nameMatches ||
              addressMatches ||
              assigneesMatches ||
              statusMatches;
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

  // Future<void> getAssignees() async {
  //   if (!isNetworkAvailable) {
  //     loadAssigneesFromHive();
  //     return;
  //   } else {
  //     final prefs = await SharedPreferences.getInstance();
  //     userId = prefs.getInt('userId') ?? 0;
  //     try {
  //       final assigneesDetails = await client?.callKw({
  //         'model': 'team.member',
  //         'method': 'search_read',
  //         'args': [[]],
  //         'kwargs': {
  //           'fields': [
  //             'id',
  //             'name',
  //           ],
  //         },
  //       });
  //       for (var item in assigneesDetails) {
  //         assignees_items.add(item['name']);
  //         assignees_ids.add(item['id']);
  //       }
  //       await saveAssigneesJobsToHive();
  //     } catch (e) {
  //       loadAssigneesFromHive();
  //       return;
  //     }
  //   }
  // }
  //
  // Future<void> loadAssigneesFromHive() async {
  //   var box = await Hive.openBox<Assignee>('assignees');
  //   assignees_items.clear();
  //   assignees_ids.clear();
  //   for (int i = 0; i < box.length; i++) {
  //     final assignee = box.getAt(i);
  //
  //     if (assignee != null) {
  //       assignees_items.add(assignee.name);
  //       assignees_ids.add(assignee.id);
  //     }
  //   }
  // }

  // Future<void> saveAssigneesJobsToHive() async {
  //   var box = await Hive.openBox<Assignee>('assignees');
  //   await box.clear();
  //   for (int i = 0; i < assignees_items.length; i++) {
  //     final assignee = Assignee(
  //       id: assignees_ids[i],
  //       name: assignees_items[i],
  //     );
  //     await box.add(assignee);
  //   }
  // }

  Future<void> getUserProfile() async {
    if (!isNetworkAvailable) {
      loadProfilePicUrl();
      return;
    } else {
      final prefs = await SharedPreferences.getInstance();

      userId = prefs.getInt('userId') ?? 0;
      final baseUrl = prefs.getString('url') ?? 0;
      print("eeeeeeeeeeeeeeeeeteamIdteamId$teamId");
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
        // print("3333333333333333333333$jsonUserDetailsResponse");
        // print("userDetailsuserDetailsuserDetails${jsonUserDetailsResponse['result']['team_member_data'][0]['name']}");
        // final userDetails = await client?.callKw({
        //   'model': 'team.members',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       ['id', '=', teamId]
        //     ]
        //   ],
        //   'kwargs': {
        //     'fields': ['image_1920'],
        //   },
        // });
        // if (userDetails != null && userDetails.isNotEmpty) {
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
      } catch (e) {}
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
                            installingJobs.clear();
                            getInstallingJobs();
                          });
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.tune, color: Colors.white),
                      onPressed: () {
                        _filterInstallationJobs(context);
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
                  child: Text(
                    'Clear Filters',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            Expanded(
              child: isLoading
                  ? ListView.builder(
                      padding: EdgeInsets.all(16),
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
                                SizedBox(height: 8),
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
                                    SizedBox(width: 8),
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
                                SizedBox(height: 8),
                                Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    width: double.infinity,
                                    height: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    width: double.infinity,
                                    height: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 10),
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
                      ? Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.solar_power,
                                    color: Colors.black,
                                    size: 92,
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "There are no Installing Jobs available to display",
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(16),
                          itemCount: filteredJobs.length,
                          itemBuilder: (context, index) {
                            final job = filteredJobs[index];
                            print("fddddddddddddddddd");
                            print(job['worksheetId']);
                            print("33333333333job");
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
                            int scannedCount = scannedBarcodeCount;
                            int checklistCount =
                                (job['checklist_current_count'] ?? 0).toInt();
                            int signatureCount =
                                (job['signature_count'] ?? 0).toInt();
                            int progressCurrent = job['scannedBarcodeCount'] +
                                checklistCount +
                                signatureCount;
                            int progressTotal = job['barcodeTotalCount'] +
                                3 +
                                job['checklistTotalCount'];

                            String jobStatus = job['install_status'] ?? 'Unknown';

                            final taskJob = taskJobs.firstWhere(
                                  (task) => task?.taskId == job['id'],
                              orElse: () => null,
                            );

                            if (taskJob != null) {
                              jobStatus = 'progress';
                            }
                            final dateAssign = job['date_assign'] == false ? "None" : job['date_assign'];

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
                                    context, '/installing_form_view',
                                    arguments: {
                                      'job_id': job['id'],
                                      'worksheetId': job['worksheetId'],
                                      'memberId': job['memberId'][0],
                                      'x_studio_site_address_1':
                                          job['x_studio_site_address_1'],
                                      'date_assign': dateAssign,
                                      'user_name': job['user_name'],
                                      'project_id': job['project_id'],
                                      'install_status': job['install_status'],
                                      'progressChange': progressChange,
                                      'name': job['name'],
                                      'partner_phone': job['partner_phone'],
                                      'partner_email': job['partner_email'],
                                      'reloadInstalling': reloadInstalling,
                                      'team_member_ids': job['team_member_ids']
                                    });
                              },
                              child: JobCard(
                                name: name,
                                status: jobStatus,
                                location: address,
                                scheduledTime: dateAssign,
                                assignees: assigneesString,
                                progressCurrent: progressCurrent,
                                progressTotal: progressTotal,
                                attachments: 0,
                                checks_checklist:
                                    job['checklist_current_count'] ?? 0,
                                checks_total_checklist:
                                    job['checklistTotalCount'] ?? 0,
                                barcode_scanned:
                                    job['scannedBarcodeCount'] ?? 0,
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

  Future<void> _loadData() async {
    final box = await Hive.openBox<TaskJob>('taskJobsBox');
    final taskJobsData = box.values.cast<TaskJob?>().toList();
    setState(() {
      taskJobs = taskJobsData;
    });
    await box.close();
  }


  void _clearFilters() {
    setState(() {
      searchText = '';
      valueStatus = '';
      assigneeValue = 0;
      selectedDate = null;
      dateController.clear();
      filteredJobs = installingJobs;
      offset = 0;
      hasMoreData = true;
      installingJobs.clear();
    });
    getInstallingJobs();
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

  void _filterInstallationJobs(BuildContext context) {
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
                    Text(
                      'Filter Installation Jobs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        value: valueStatus.isNotEmpty ? valueStatus : null,
                        // Set the initial value
                        decoration: InputDecoration(
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
                    SizedBox(height: 16),
                    // DropdownSearch<int>(
                    //   selectedItem: assigneeValue != 0 ? assigneeValue : null,
                    //   dropdownDecoratorProps: DropDownDecoratorProps(
                    //     dropdownSearchDecoration: InputDecoration(
                    //       border: OutlineInputBorder(),
                    //       labelText: 'Select Assignee',
                    //     ),
                    //   ),
                    //   items: assignees_ids,
                    //   itemAsString: (int? item) =>
                    //       assignees_items[assignees_ids.indexOf(item!)],
                    //   onChanged: (value) {
                    //     assigneeValue = value!;
                    //   },
                    //   popupProps: PopupProps.menu(
                    //     showSearchBox: true,
                    //     searchFieldProps: TextFieldProps(
                    //       decoration: InputDecoration(
                    //         labelText: 'Search Assignee',
                    //         border: OutlineInputBorder(),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // SizedBox(height: 16),
                    TextField(
                      controller: dateController,
                      decoration: InputDecoration(
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
                    SizedBox(
                      height: 8,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        offset = 0;
                        hasMoreData = true;
                        installingJobs.clear();
                        getInstallingJobs();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text(
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
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
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
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Flexible(
                  flex: 3,
                  child: Row(
                    children: [
                      Icon(Icons.location_on,
                          color: Colors.blueAccent, size: 18),
                      SizedBox(width: 5),
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
                Spacer(),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.blueAccent, size: 18),
                SizedBox(width: 5),
                Text(
                  scheduledTime,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Assignee: $assignees',
              style:
                  TextStyle(color: Colors.black87, fontStyle: FontStyle.italic),
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
                    SizedBox(width: 10),
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
                          if (barcode_total != barcode_scanned ||
                              barcode_total == 0)
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
                          if (checks_checklist != checks_total_checklist ||
                              checks_total_checklist == 0)
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

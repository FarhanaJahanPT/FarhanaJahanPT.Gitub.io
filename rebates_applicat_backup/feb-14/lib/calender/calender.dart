import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CalenderPage extends StatefulWidget {
  @override
  State<CalenderPage> createState() => _CalenderPageState();
}

class _CalenderPageState extends State<CalenderPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, String>>> _events = {};
  final NotchBottomBarController _controller =
      NotchBottomBarController(index: 1);
  final int maxCount = 3;
  final List<String> bottomBarPages = [
    'Solar Installation',
    'Calendar',
    'Service Jobs'
  ];
  bool _showInstalling = true;
  bool _showService = true;
  OdooClient? client;
  String url = "";
  int? userId;
  int totalCount = 0;
  int unreadCount = 0;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  bool _isWeeklyView = false;
  double _dragPosition = 0.0;
  MemoryImage? profilePicUrl;
  late Future<void> _hiveInitFuture;
  bool isNetworkAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity().then((_) {
      _hiveInitFuture = _initializeHive();
      // _initializeOdooClient();
      // getNotificationCount();
      getCombinedEvents();
      // getUserProfile();
    });
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
      if (isNetworkAvailable) {
        // await getNotificationCount();
        await getCombinedEvents();
        // await getUserProfile();
      }
    });
  }

  Future<void> _initializeHive() async {
    await Hive.initFlutter();
    await Hive.openBox('notificationBox');
    await Hive.openBox('eventsBox');
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


  Future<void> storeNotificationCountInHive(int totalCount, int unreadCount) async {
    var notificationBox = Hive.box('notificationBox');
    await notificationBox.put('totalCount', totalCount);
    await notificationBox.put('unreadCount', unreadCount);
  }

  Future<void> retrieveNotificationCountFromHive() async {
    var notificationBox = Hive.box('notificationBox');
    setState(() {
      totalCount = notificationBox.get('totalCount', defaultValue: 0);
      unreadCount = notificationBox.get('unreadCount', defaultValue: 0);
    });
  }


  Future<void> getCombinedEvents() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    final teamId = prefs.getInt('teamId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    print("eeeeeeeeeeeeeeeeeeee4444444444");
    try {
      // final installingCalendarDetails = await client?.callKw({
      //   'model': 'project.task',
      //   'method': 'search_read',
      //   'args': [
      //     [
      //       // ['x_studio_proposed_team', '=', userId],
      //       ['project_id', '=', 'New Installation'],
      //       ['worksheet_id', '!=', false],
      //       ['team_lead_user_id', '=', userId],
      //     ]
      //   ],
      //   'kwargs': {
      //     'fields': [
      //       'activity_ids',
      //       'project_id',
      //       'install_status',
      //       'name',
      //       'message_ids'
      //     ],
      //   },
      // });
      final Uri installingUrl = Uri.parse('$baseUrl/rebates/project_task');
      final installingCalendarDetails = await http.post(
        installingUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "team_id": teamId,
            "type": 'New Installation'

          }
        }),
      );
      final Map<String, dynamic> jsonInstallingCalendarDetailsResponse = json.decode(installingCalendarDetails.body);
      print(jsonInstallingCalendarDetailsResponse);
      print("jsonInstallingCalendarDetailsResponsejsonInstallingCalendarDetailsResponse");

      final Uri serviceUrl = Uri.parse('$baseUrl/rebates/project_task');
      final serviceCalendarDetails = await http.post(
        serviceUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "team_id": teamId,
            "type": 'Service'

          }
        }),
      );
      final Map<String, dynamic> jsonServiceCalendarDetailsResponse = json.decode(serviceCalendarDetails.body);
      print(jsonServiceCalendarDetailsResponse);
      print("jsonServiceCalendarDetailsResponsejsonServiceCalendarDetailsResponse");

      //   final serviceCalendarDetails = await client?.callKw({
      //   'model': 'project.task',
      //   'method': 'search_read',
      //   'args': [
      //     [
      //       // ['x_studio_proposed_team', '=', userId],
      //       ['project_id', '=', 'Service'],
      //       ['worksheet_id', '!=', false],
      //       ['team_lead_user_id', '=', userId],
      //     ]
      //   ],
      //   'kwargs': {
      //     'fields': [
      //       'activity_ids',
      //       'project_id',
      //       'install_status',
      //       'name',
      //       'message_ids'
      //     ],
      //   },
      // });
      final allEvents = <DateTime, List<Map<String, String>>>{};

      final installingEvents =
          await _fetchActivities(jsonInstallingCalendarDetailsResponse['result']['tasks'], 'Installing');
      final serviceEvents =
          await _fetchActivities(jsonServiceCalendarDetailsResponse['result']['tasks'], 'Service');


      if (installingEvents.isEmpty) {
      }

      _mergeEvents(allEvents, installingEvents);
      _mergeEvents(allEvents, serviceEvents);

        setState(() {
          _events = allEvents;
        });
      } catch (e) {
        retrieveEventsFromHive();
      }
  }

  Future<void> storeEventsInHive(Map<DateTime, List<Map<String, String>>> events) async {
    var eventsBox = Hive.box('eventsBox');
    await eventsBox.put('allEvents', events);
  }

  Future<void> retrieveEventsFromHive() async {
    var eventsBox = Hive.box('eventsBox');
    setState(() {
      _events = eventsBox.get('allEvents', defaultValue: {});
    });
  }

  Future<Map<DateTime, List<Map<String, String>>>> _fetchActivities(
      List<dynamic>? calendarDetails, String type) async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    final teamId = prefs.getInt('teamId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    final events = <DateTime, List<Map<String, String>>>{};

    if (calendarDetails != null && calendarDetails.isNotEmpty) {
      for (var detail in calendarDetails) {
        final activityIds = detail['activity_ids'] as List<dynamic>;

        if (activityIds.isNotEmpty) {
          // final activityDetails = await client?.callKw({
          //   'model': 'mail.activity',
          //   'method': 'search_read',
          //   'args': [
          //     [
          //       ['id', 'in', activityIds]
          //     ]
          //   ],
          //   'kwargs': {
          //     'fields': [
          //       'summary',
          //       'res_name',
          //       'date_deadline',
          //       'state',
          //       'activity_type_id',
          //       'user_id'
          //     ],
          //   },
          // });
          print("jsonActivityDetailsResponsejsonActivityDetailsResponsejsonActivityDetailsResponsessss");
          final Uri activityUrl = Uri.parse('$baseUrl/rebates/mail_activity');
          final activityDetails = await http.post(
            activityUrl,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "jsonrpc": "2.0",
              "method": "call",
              "params": {
                "activityIds": activityIds,

              }
            }),
          );
          final Map<String, dynamic> jsonActivityDetailsResponse = json.decode(activityDetails.body);
          print(jsonActivityDetailsResponse);
          print("jsonActivityDetailsResponsejsonActivityDetailsResponsejsonActivityDetailsResponse");
          for (var activityDetail in jsonActivityDetailsResponse['result']['activities']) {
            final dateDeadline =
                DateTime.tryParse(activityDetail['date_deadline'] ?? '') ??
                    DateTime.now();
            final activityTypeId = activityDetail['activity_type_id'] != null &&
                    activityDetail['activity_type_id'] is List
                ? activityDetail['activity_type_id'][1].toString()
                : '';
            final userId = activityDetail['team_id'] != null &&
                    activityDetail['team_id'] is List
                ? activityDetail['team_id'][1].toString()
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
              'team_id': userId,
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

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _focusedDay) {
      setState(() {
        _selectedDay = picked;
        _focusedDay = picked;
      });
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


  bool _hasEventsForDay(DateTime day) {
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay]?.isNotEmpty ?? false;
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text('Calendar',
        //       style:
        //           TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        //                   unreadCount > 99 ? '99+' : unreadCount.toString(),
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
        //     SizedBox(width: 10),
        //     Container(
        //       width: 50.0,
        //       height: 50.0,
        //       decoration: BoxDecoration(
        //         shape: BoxShape.circle,
        //         color: Colors.black.withOpacity(0.2),
        //       ),
        //       child: GestureDetector(
        //         onTap: () {
        //           Navigator.pushNamed(context, '/profile_main', arguments: {
        //             'reloadProfile': reloadProfile,
        //           });
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
        //                             image: profilePicUrl!,
        //                             fit: BoxFit.cover,
        //                             width: 80.0,
        //                             height: 80.0,
        //                             errorBuilder: (BuildContext context,
        //                                 Object exception,
        //                                 StackTrace? stackTrace) {
        //                               return Icon(
        //                                 Icons.person,
        //                                 size: 54,
        //                                 color: Colors.white,
        //                               );
        //                             },
        //                           )
        //                         : Icon(Icons.person,
        //                             size: 54, color: Colors.white),
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
        //     SizedBox(width: 10),
        //   ],
        // ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    _selectDate(context);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_calendar_outlined, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        DateFormat.yMMMM().format(_focusedDay),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // TableCalendar section
                TableCalendar(
                  firstDay: DateTime.utc(2000, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarFormat: _calendarFormat,
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerVisible: false,
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final hasEvent = _hasEventsForDay(day);
                      return Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: hasEvent ? Colors.red : Colors.black,
                            decoration: hasEvent
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10.0),

                GestureDetector(
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _dragPosition += details.delta.dy;
                      if (_dragPosition > 50) {
                        _calendarFormat = CalendarFormat.month;
                      } else if (_dragPosition < -50) {
                        _calendarFormat = CalendarFormat.week;
                      }
                    });
                  },
                  onVerticalDragEnd: (details) {
                    setState(() {
                      _dragPosition = 0.0;
                    });
                  },
                  child: Icon(
                    _calendarFormat == CalendarFormat.month
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                    size: 40,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 10.0),
                Divider(),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Activities",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 25,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.solar_power,
                            color: _showInstalling ? Colors.green : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _showInstalling = !_showInstalling;
                              _showService = true;
                            });
                          },
                        ),
                        SizedBox(width: 10),
                        IconButton(
                          icon: Icon(
                            Icons.build,
                            color: _showService ? Colors.green : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _showService = !_showService;
                              _showInstalling = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                SizedBox(
                  height: 300,
                  child: _buildActivityList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  Widget _buildActivityList() {
    final events = _getEventsForDay(_selectedDay ?? _focusedDay);
    final filteredEvents = events.where((event) {
      if (!_showInstalling && event['type'] == 'Installing') return false;
      if (!_showService && event['type'] == 'Service') return false;
      return true;
    }).toList();
    if (filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_sharp,
              color: Colors.black,
              size: 92,
            ),
            SizedBox(height: 20),
            Text(
              "No activities scheduled for this day",
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        final status = filteredEvents[index]['state'] ?? 'Unknown';
        var summary = filteredEvents[index]['summary'];
        String? summaryText;
        if (summary == 'false') {
          summaryText = filteredEvents[index]['res_name'];
        } else {
          summaryText = summary ?? 'No Summary';
        }

        String statusText;
        Color statusColor;
        switch (status) {
          case 'done':
            statusText = 'Done';
            statusColor = Colors.green;
            break;
          case 'today':
            statusText = 'Today';
            statusColor = Colors.orange[600]!;
            break;
          case 'planned':
            statusText = 'Planned';
            statusColor = Colors.blue;
            break;
          case 'overdue':
            statusText = 'Overdue';
            statusColor = Colors.red;
            break;
          default:
            statusText = 'Unknown';
            statusColor = Colors.grey;
        }

        return Card(
          color: Colors.teal[50],
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: ListTile(
            onTap: () {
              _showEventDialog(context, event);
            },
            leading: Icon(
              filteredEvents[index]['type'] == 'Installing'
                  ? Icons.solar_power
                  : Icons.build,
              color: Colors.teal,
            ),
            title: Text(
              filteredEvents[index]['title'] ?? 'No Title',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal[900],
              ),
            ),
            subtitle: Text(summaryText!),
            trailing: Text(
              statusText,
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ),
        );
      },
    );
  }

  void _showEventDialog(BuildContext context, Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        print("event['summary']event['summary']${event['summary']}");
        String eventSummary = (event['summary'] == 'false' ||
            event['summary'] == null ||
            event['summary'] == '')
            ? 'N/A'
            : event['summary'];
        String eventActivityTypes = (event['activity_type_id'] == 'false' ||
            event['activity_type_id'] == null ||
            event['activity_type_id'] == '')
            ? 'N/A'
            : event['activity_type_id'];
        String eventDeadline = (event['date_deadline'] == 'false' ||
            event['date_deadline'] == null ||
            event['date_deadline'] == '')
            ? 'N/A'
            : event['date_deadline'];
        String assigned = (event['team_id'] == 'false' ||
            event['team_id'] == null ||
            event['team_id'] == '')
            ? 'N/A'
            : event['team_id'];
        String document = (event['res_name'] == 'false' ||
            event['res_name'] == null ||
            event['res_name'] == '')
            ? 'N/A'
            : event['res_name'];

        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Event Details",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 21,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          ),
          content: Container(
            height: MediaQuery.of(context).size.height * 0.25,
            width: MediaQuery.of(context).size.width * 0.95,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Document:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      document,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey),
                      maxLines: null,
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.013),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Activity Type:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(eventActivityTypes,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.013),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Summary:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(eventSummary,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.grey),
                        maxLines: null),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.013),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Due Date:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(eventDeadline,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.013),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Assigned to:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(assigned,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.grey),
                        maxLines: null),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

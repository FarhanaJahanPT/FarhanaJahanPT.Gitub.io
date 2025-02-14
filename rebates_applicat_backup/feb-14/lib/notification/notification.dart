import 'dart:convert';
import 'dart:io';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../installation/installation_form_view.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../offline_db/notification/notification.dart';
import '../offline_db/notification/notification_edit.dart';
import 'package:http/http.dart' as http;

class NotificationItem {
  final int id;
  final String title;
  final String body;
  final DateTime date;
  final String author;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.author,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.tryParse(json['date'] ?? '')?.toUtc() ??
        DateTime.now().toUtc();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(parsedDate);
    return NotificationItem(
      id: json['id'],
      title: json['title'] ?? 'No Title',
      body: json['body'] ?? 'No Body',
      date: parsedDate,
      author: json['author'] ?? 'Unknown author',
      isRead: json['isRead'] ?? false,
    );
  }
}

class NotificationsPage extends StatefulWidget {
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotchBottomBarController _controller =
      NotchBottomBarController(index: -1);
  final int maxCount = 3;
  final List<String> bottomBarPages = [
    'Solar Installation',
    'Calendar',
    'Service Jobs'
  ];
  String? url;
  OdooClient? client;
  int userId = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> installNamesList = [];
  int installingMessageCount = 0;
  int serviceMessageCount = 0;
  List<Map<String, dynamic>> serviceNamesList = [];
  bool isNotificationsPageOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final int limit = 20;
  int offset = 0;
  ScrollController _scrollController = ScrollController();
  bool hasMoreData = true;
  String? timezoneName;
  bool isNetworkAvailable = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _initializeOdooClient();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkConnectivity();
    fetchNotifications();
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
        await fetchNotifications();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        !_isLoading &&
        hasMoreData) {
      fetchNotifications();
    }
  }

  Future<void> _initializeOdooClient() async {
    final prefs = await SharedPreferences.getInstance();
    url = prefs.getString('url') ?? '';
    userId = prefs.getInt('userId') ?? 0;
    final db = prefs.getString('selectedDatabase') ?? '';
    final sessionId = prefs.getString('sessionId') ?? '';
    final serverVersion = prefs.getString('serverVersion') ?? '';
    final userLang = prefs.getString('userLang') ?? '';
    final companyId = prefs.getInt('companyId');
    timezoneName = prefs.getString('userTimezone');

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

  Future<bool> _onWillPop() async {
    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
    _controller.index = -1;
    return false;
  }

  Future<void> _readNotification(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('url') ?? 0;
    final teamId = prefs.getInt('teamId') ?? 0;
    try {
      // final response = await client?.callKw({
      //   'model': 'worksheet.notification',
      //   'method': 'write',
      //   'args': [
      //     [id],
      //     {
      //       'is_read': true,
      //     }
      //   ],
      //   'kwargs': {},
      // });
      final Uri notificationUrl = Uri.parse('$baseUrl/rebates/worksheet_notification/write');
      final worksheet = await http.post(
        notificationUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "id": id,
          }
        }),
      );
      final Map<String, dynamic> jsonNotificationResponse = json.decode(worksheet.body);
      print(jsonNotificationResponse);
      print(jsonNotificationResponse['result']['status']);
      print("jsonNotificationResponsejsonNotificationResponse");
      if (jsonNotificationResponse['result']['status'] == 'success') {
      // if (response == true) {
        setState(() {
          fetchNotifications();
        });
      } else {}
    } catch (e) {}
  }

  Future<List<NotificationModel>> loadNotifications() async {
    try {
      print("444444444444dddddddddddddddddddddddd");
      await Hive.openBox<NotificationModel>('notificationsBox');
      final notificationsBox = Hive.box<NotificationModel>('notificationsBox');
      List<NotificationModel> notifications = notificationsBox.values.toList();
      print(notifications);
      print("rrrrrrrrrrrrrrrrrrrrrrrrrfdddddddddddd");
      return notifications;
    } catch (e) {
      print("4444444444444444444ddddddddddddddddddd$e");
      return [];
    }
  }

  List<Map<String, dynamic>> notifications = [];

  Future<void> fetchNotifications() async {
    print("3333333333333344444444444444444444edddddddddddddd");
    final prefs = await SharedPreferences.getInstance();
    // userId = prefs.getInt('userId') ?? 0;
    final teamId = prefs.getInt('teamId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;

    if (!isNetworkAvailable) {
        print("ffffffffffffffffffffffdddddddddd");
        final dateFormatter = DateFormat('yyyy-MM-dd');
        final localNotifications = await loadNotifications();
        notifications = localNotifications
            .map((notif) => {
                  'id': notif.id,
                  'body': notif.body,
                  'subject': notif.subject,
                  'date': dateFormatter.format(notif.date),
                  'author_id': notif.authorId,
                  'is_read': notif.isRead,
                })
            .toList();
        setState(() {
          _isLoading = false;
        });
      } else {
        print(userId);
        try {
          // final notificationDetails = await client?.callKw({
          //   'model': 'worksheet.notification',
          //   'method': 'search_read',
          //   'args': [
          //     [
          //       ['author_id', '=', userId],
          //     ],
          //   ],
          //   'kwargs': {
          //     'fields': ['id', 'body', 'subject', 'date', 'author_id', 'is_read'],
          //   },
          // });
          final Uri url = Uri.parse('$baseUrl/rebates/worksheet_notification');
          final notificationDetails = await http.post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "jsonrpc": "2.0",
              "method": "call",
              "params": {
                "team_id": teamId,
              }
            }),
          );
          final Map<String, dynamic> jsonNotificationDetailsResponse = json
              .decode(notificationDetails.body);
          print(jsonNotificationDetailsResponse);
          print("notificationDetailsddddddddddddddd");
          // if (notificationDetails != null) {
          if (jsonNotificationDetailsResponse['result']['status'] == 'success' &&
              jsonNotificationDetailsResponse['result']['notifications']
                  .isNotEmpty) {
            setState(() {
              notifications =
              List<Map<String, dynamic>>.from(jsonNotificationDetailsResponse['result']['notifications']);
              _isLoading = false;
            });
          }
        } catch (e) {
          final dateFormatter = DateFormat('yyyy-MM-dd');
          final localNotifications = await loadNotifications();
          notifications = localNotifications
              .map((notif) => {
            'id': notif.id,
            'body': notif.body,
            'subject': notif.subject,
            'date': dateFormatter.format(notif.date),
            'author_id': notif.authorId,
            'is_read': notif.isRead,
          })
              .toList();
          setState(() {
            _isLoading = false;
          });
        }
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Container(
        color: Colors.green.withOpacity(0.2),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.0357),
          child: Center(
            child: _isLoading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: ListView.builder(
                      itemCount: 20,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: buildShimmerItem(),
                      ),
                    ),
                  )
                : notifications.isEmpty
                    ? buildEmptyNotifications()
                    : buildGroupedNotifications(),
          ),
        ),
      ),
    );
  }

  Widget buildShimmerItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: Colors.grey[300]!,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 12.0,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8.0),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 12.0,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEmptyNotifications() {
    return Expanded(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_on_outlined,
                color: Colors.black,
                size: 92,
              ),
              SizedBox(height: 20),
              Text(
                "There are no Notifications to display",
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
    );
  }

  Widget buildGroupedNotifications() {
    DateTime now = DateTime.now();
    DateTime yesterday = now.subtract(const Duration(days: 1));
    DateTime tomorrow = now.add(const Duration(days: 1));

    notifications.sort((a, b) {
      DateTime dateA = DateTime.parse(a['date']);
      DateTime dateB = DateTime.parse(b['date']);

      int dateComparison = dateB.compareTo(dateA);
      if (dateComparison != 0) return dateComparison;

      bool isReadA = a['is_read'] ?? true;
      bool isReadB = b['is_read'] ?? true;
      if (isReadA == isReadB) return 0;
      return isReadA ? 1 : -1;
    });

    Map<String, List<Map<String, dynamic>>> groupedNotifications = {};
    for (var notification in notifications) {
      DateTime createDate = DateTime.parse(notification['date']);
      String dateKey;

      if (isSameDate(createDate, now)) {
        dateKey = 'Today';
      } else if (isSameDate(createDate, yesterday)) {
        dateKey = 'Yesterday';
      } else if (isSameDate(createDate, tomorrow)) {
        dateKey = 'Tomorrow';
      } else {
        dateKey = '${createDate.day}/${createDate.month}/${createDate.year}';
      }

      if (!groupedNotifications.containsKey(dateKey)) {
        groupedNotifications[dateKey] = [];
      }
      groupedNotifications[dateKey]!.add(notification);
    }

    return ListView(
      controller: _scrollController,
      children: groupedNotifications.entries.map((entry) {
        String dateKey = entry.key;
        List<Map<String, dynamic>> notificationsForDate = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  dateKey,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ...notificationsForDate.map((record) {
              return buildListItem(
                  context, record, notifications.indexOf(record));
            }).toList(),
          ],
        );
      }).toList(),
    );
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  IconData getIconForNotification(String changes) {
    if (changes.toLowerCase().contains('updated')) {
      return Icons.update;
    } else if (changes.toLowerCase().contains('create')) {
      return Icons.create_new_folder;
    } else if (changes.toLowerCase().contains('assigned')) {
      return Icons.assignment;
    } else if (changes.toLowerCase().contains('remove')) {
      return Icons.remove_circle;
    } else if (changes.toLowerCase().contains('qr')) {
      return Icons.qr_code;
    } else if (changes.toLowerCase().contains('password')) {
      return Icons.lock;
    } else if (changes.toLowerCase().contains('scheduled')) {
      return Icons.schedule_sharp;
    } else {
      return Icons.notifications;
    }
  }

  Color getColorForNotification(String changes) {
    if (changes.toLowerCase().contains('updated')) {
      return Colors.blue;
    } else if (changes.toLowerCase().contains('create')) {
      return Colors.green;
    } else if (changes.toLowerCase().contains('assigned')) {
      return Colors.orange;
    } else if (changes.toLowerCase().contains('remove')) {
      return Colors.red;
    } else if (changes.toLowerCase().contains('qr')) {
      return Colors.purple;
    } else if (changes.toLowerCase().contains('password')) {
      return Colors.pink;
    } else if (changes.toLowerCase().contains('scheduled')) {
      return Colors.teal;
    } else {
      return Colors.grey;
    }
  }
  //
  // Future<void> saveNotificationToHive(int id) async {
  //   final box = await Hive.openBox<NotificationEdit>('notificationsEdit');
  //   final notification = NotificationEdit(
  //     id: id,
  //     isRead: true,
  //   );
  //   await box.put(id, notification);
  //   await box.close();
  // }

  Future<void> saveNotificationToHive(int id) async {
    Box<NotificationEdit>? box;
    try {
      box = await Hive.openBox<NotificationEdit>('notificationsEdit');
      final notification = NotificationEdit(
        id: id,
        isRead: true,
      );
      await box.put(id, notification);
      print("Notification saved: $notification");
    } catch (e) {
      print("Error while saving notification: $e");
    } finally {
      if (box != null && box.isOpen) {
        await box.close();
        print("Box closed properly.");
      }
    }
  }


  Widget buildListItem(
      BuildContext context, Map<String, dynamic> record, int index) {
    IconData notificationIcon = getIconForNotification(record['subject'] ?? '');
    Color notificationColor = getColorForNotification(record['subject'] ?? '');
    DateTime parsedDate =
        DateTime.tryParse(record['date'] ?? '') ?? DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: GestureDetector(
        onTap: () async {
          if (record['is_read'] == false) {
            if (!isNetworkAvailable) {
              await saveNotificationToHive(record['id']);
            } else {
              await _readNotification(record['id']);
            }
          }
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        record['subject'] ?? 'No Subject',
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
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Date:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(record['date'] ?? 'Unknown'),
                      ],
                    ),
                    // const SizedBox(height: 10),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     const Text(
                    //       "Author:",
                    //       style: TextStyle(fontWeight: FontWeight.bold),
                    //     ),
                    //     Expanded(
                    //       child: Text(
                    //         record['team_id'][1] ?? 'Unknown',
                    //         textAlign:
                    //             TextAlign.right, // Aligns the text to the right
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Body:',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.height * 0.1,
                          width: MediaQuery.of(context).size.width * 0.6,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                            ),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Text(
                              '${record['body'] == 'false' ? 'None' : record['body']}',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10.0,
                spreadRadius: 5.0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: notificationColor.withOpacity(0.3),
                child: Icon(
                  notificationIcon,
                  color: record['is_read'] == true
                      ? notificationColor.withOpacity(0.3)
                      : notificationColor,
                  size: 30.0,
                ),
                radius: 30,
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record['body'] ?? 'No details available',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: record['is_read'] == true
                            ? Colors.grey
                            : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      record['date'],
                      style: TextStyle(
                        fontSize: 12.0,
                        color: record['is_read'] == true
                            ? Colors.black38
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListTile(
        title: Container(
          width: double.infinity,
          height: 20.0,
          color: Colors.white,
        ),
        subtitle: Container(
          width: double.infinity,
          height: 14.0,
          color: Colors.white,
          margin: const EdgeInsets.only(top: 8.0),
        ),
        trailing: Container(
          width: 40.0,
          height: 20.0,
          color: Colors.white,
        ),
      ),
    );
  }
}

class FileViewer extends StatelessWidget {
  final String filePath;

  FileViewer({required this.filePath});

  @override
  Widget build(BuildContext context) {
    final fileExtension = filePath.split('.').last.toLowerCase();
    switch (fileExtension) {
      case 'pdf':
        return PDFViewerPage(documentPath: filePath);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return ImageViewer(filePath: filePath);
      case 'docx':
        return _openFile(filePath);
      default:
        return _openFile(filePath);
    }
  }

  Widget _openFile(String filePath) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Open File',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            requestPermissions();
            final result = await OpenFile.open(filePath);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: Text(
            'Open ${filePath.split('.').last.toUpperCase()} File',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    if (await Permission.manageExternalStorage.request().isGranted) {
    } else {}
  }
}

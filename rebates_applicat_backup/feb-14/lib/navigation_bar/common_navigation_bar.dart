import 'dart:typed_data';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../calender/calender.dart';
import '../installation/installed_list_view.dart';
import '../service_jobs/service_jobs_list_view.dart';

class MainScreen extends StatefulWidget {
  final int initialPageIndex;

  MainScreen({this.initialPageIndex = 0, Key? key}) : super(key: key);
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  late PageController _pageController;

  final List<Widget> _pages = [
    InstalledListView(),
    CalenderPage(),
    ServiceJobsListview(),
  ];

  int unreadCount = 0;
  MemoryImage? profilePicUrl;
  bool isNetworkAvailable = false;
  OdooClient? client;
  String url = "";
  int? userId;
  int? teamId;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPageIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initialize();
    print("ddddddddddddddddddddddddddddddddddsccccccccccccccvvvvvv");
  }

  Future<void> _initialize() async {
    await _checkConnectivity();
    // _initializeOdooClient();
    getNotificationCount();
    getUserProfile();
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
        await getUserProfile();
        await getNotificationCount();
      }
    });
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    print(index);
    print("ddddddddddddddddddddddddsssssssssss");
    setState(() {
      getNotificationCount();
      getUserProfile();
      _currentIndex = index;
    });
  }

  String getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Installing Jobs';
      case 1:
        return 'Calendar';
      case 2:
        return 'Service Jobs';
      default:
        return 'App';
    }
  }

  Future<void> reloadProfile() async {
    getUserProfile();
  }

  Future<void> getUserProfile() async {
    if (!isNetworkAvailable) {
      loadProfilePicUrl();
      return;
    } else {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;
      teamId = prefs.getInt('teamId') ?? 0;
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
        //   'model': 'team.member',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       ['id', '=', 1]
        //     ]
        //   ],
        //   'kwargs': {
        //     'fields': ['image_1920'],
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
        loadProfilePicUrl();
        return;
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

  Future<void> loadNotificationCount() async {
    final NotificationCountBox = await Hive.openBox('NotificationCount');
    final notificationCount = NotificationCountBox.get('unreadCount');
    if (unreadCount != null) {
      setState(() {
        unreadCount = notificationCount;
      });
    }
  }

  Future<void> getNotificationCount() async {
    if (!isNetworkAvailable) {
      loadNotificationCount();
      return;
    } else {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;
      final baseUrl = prefs.getString('url') ?? 0;
      final teamId = prefs.getInt('teamId') ?? 0;
      try {
        int unreadMessagesCount = 0;
        // final messages = await client?.callKw({
        //   'model': 'worksheet.notification',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       ['author_id', '=', userId],
        //       ['is_read', '=', false],
        //     ],
        //   ],
        //   'kwargs': {
        //     'fields': ['body', 'subject', 'date', 'author_id'],
        //   },
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/worksheet_notification');
        final messages = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "member_id": teamId,
            }
          }),
        );
        print("eeeeeeeeeeeeeeeeeeeeeewwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww");
        final Map<String, dynamic> jsonMessagesResponse = json.decode(messages.body);
        print("3333333333333333333333$jsonMessagesResponse");
        // print("userDetailsuserDetailsuserDetails${jsonMessagesResponse['result']['notifications'][0]['name']}");
        if (jsonMessagesResponse['result']['status'] == 'success' && jsonMessagesResponse['result']['notifications'].isNotEmpty) {

          // if (messages != null) {
          unreadMessagesCount = jsonMessagesResponse['result']['notifications'].length;
        }
        setState(() {
          unreadCount = unreadMessagesCount;
        });
        final profileBox = await Hive.openBox('NotificationCount');
        await profileBox.put('unreadCount', unreadCount);
      } catch (e) {
        loadNotificationCount();
        return;
      }
    }
  }

  Future<void> reloadNotification() async {
    getNotificationCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          getAppBarTitle(),
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/notifications',
                arguments: {'reloadNotification': reloadNotification},
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_rounded,
                    color: Colors.white, size: 35),
                if (unreadCount > 0)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 10),
          Container(
            width: 50.0,
            height: 50.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.2),
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/profile_main',
                  arguments: {'reloadProfile': reloadProfile},
                );
              },
              child: CircleAvatar(
                radius: 20.0,
                backgroundColor: Colors.grey[400],
                child: Stack(
                  children: [
                    if (profilePicUrl != null)
                      Positioned.fill(
                        child: ClipOval(
                          child: Image(
                            image: profilePicUrl!,
                            fit: BoxFit.cover,
                            width: 80.0,
                            height: 80.0,
                            errorBuilder: (BuildContext context,
                                Object exception, StackTrace? stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 54,
                                color: Colors.white,
                              );
                            },
                          ),
                        ),
                      ),
                    if (profilePicUrl == null)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[400],
                          ),
                          child: Center(
                            child: Icon(Icons.person),
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: ConvexAppBar(
        backgroundColor: Colors.green,
        activeColor: Colors.white,
        items: [
          TabItem(icon: Icons.solar_power, title: 'Installation'),
          TabItem(icon: Icons.calendar_month, title: 'Calendar'),
          TabItem(icon: Icons.build, title: 'Service'),
        ],
        initialActiveIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
          _onPageChanged(index);
          _pageController.jumpToPage(index);
        },
      ),
    );
  }
}
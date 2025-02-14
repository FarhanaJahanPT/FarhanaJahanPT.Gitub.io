import 'dart:convert';
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rebates_solar/pofile/privacy_policy.dart';
import 'package:rebates_solar/pofile/profile.dart';
import 'package:rebates_solar/pofile/profile_main.dart';
import 'package:rebates_solar/pofile/rewards.dart';
import 'package:rebates_solar/pofile/settings.dart';
import 'package:rebates_solar/pofile/terms_of_use.dart';
import 'package:rebates_solar/service_jobs/checklist.dart';
import 'package:rebates_solar/service_jobs/service_jobs_form_view.dart';
import 'package:rebates_solar/service_jobs/service_jobs_list_view.dart';
import 'package:rebates_solar/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'background/background_service.dart';
import 'calender/calender.dart';
import 'initializing.dart';
import 'installation/checklist.dart';
import 'installation/installation_form_view.dart';
import 'installation/installed_list_view.dart';
import 'login/login.dart';
import 'notification/notification.dart';
import 'notification/notification_alert.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'offline_db/checklist/checklist_item_hive.dart';
import 'offline_db/checklist/edit_checklist.dart';
import 'offline_db/installation_form/attendance.dart';
import 'offline_db/installation_form/attendance_checkout.dart';
import 'offline_db/installation_form/document.dart';
import 'offline_db/installation_form/owner_details.dart';
import 'offline_db/installation_form/product_category.dart';
import 'offline_db/installation_form/product_details.dart';
import 'offline_db/installation_form/project_document.dart';
import 'offline_db/installation_form/worksheet.dart';
import 'offline_db/installation_list/assignee.dart';
import 'offline_db/installation_list/installing_job.dart';
import 'offline_db/notification/notification.dart';
import 'offline_db/notification/notification_edit.dart';
import 'offline_db/product_scan/edit_scan_product.dart';
import 'offline_db/product_scan/product_sacn.dart';
import 'offline_db/profile/edit_user.dart';
import 'offline_db/profile/profile.dart';
import 'offline_db/project_ccew_document/project_ccew_document.dart';
import 'offline_db/qr/qr_code.dart';
import 'offline_db/qr/qr_code_visisble.dart';
import 'offline_db/selfies/hive_selfie.dart';
import 'offline_db/selfies/selfie_edit.dart';
import 'offline_db/selfies/service_hive_selfie.dart';
import 'offline_db/selfies/service_selfie_edit.dart';
import 'offline_db/service_checklist/checklist_item_hive.dart';
import 'offline_db/service_checklist/edit_checklist.dart';
import 'offline_db/service_list/service_job.dart';
import 'offline_db/signatures/installer_signature.dart';
import 'offline_db/signatures/installer_signature_edit.dart';
import 'offline_db/signatures/owner_signature.dart';
import 'offline_db/signatures/owner_signature_edit.dart';
import 'offline_db/start_finish_job/finish_job.dart';
import 'offline_db/start_finish_job/task_job.dart';
import 'offline_db/swms/hazard_question.dart';
import 'offline_db/swms/hazard_response.dart';
import 'offline_db/swms/risk_item.dart';
import 'offline_db/swms/safety_items.dart';
import 'offline_db/swms/swms_detail.dart';
import 'offline_db/worksheet_document/worksheet_document.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
OdooClient? client;
String url = "";
int? userId;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final initializer = Initializing();
Timer? _timer;

Future<void> deleteAllHiveBoxes() async {
  await Hive.deleteFromDisk();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  deleteAllHiveBoxes();
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  tz.initializeTimeZones();
  await Hive.initFlutter();
  Hive.registerAdapter(PartnerAdapter());
  Hive.registerAdapter(ServiceJobsAdapter());
  Hive.registerAdapter(InstallingJobAdapter());
  Hive.registerAdapter(AssigneeAdapter());
  Hive.registerAdapter(UserAdapter());
  if (!Hive.isAdapterRegistered(UserModelAdapter().typeId)) {
    Hive.registerAdapter(UserModelAdapter());
  }
  Hive.registerAdapter(InstallerSignatureAdapter());
  Hive.registerAdapter(OwnerSignatureHiveAdapter());
  Hive.registerAdapter(ProductDetailAdapter());
  Hive.registerAdapter(ProjectDocumentsAdapter());
  Hive.registerAdapter(DocumentAdapter());
  Hive.registerAdapter(WorksheetAdapter());
  Hive.registerAdapter(HiveImageAdapter());
  Hive.registerAdapter(HiveSelfieAdapter());
  Hive.registerAdapter(SignatureDataAdapter());
  Hive.registerAdapter(ChecklistItemHiveAdapter());
  Hive.registerAdapter(OfflineChecklistItemAdapter());
  Hive.registerAdapter(NotificationModelAdapter());
  Hive.registerAdapter(NotificationEditAdapter());
  Hive.registerAdapter(OwnerSignatureEditDataAdapter());
  Hive.registerAdapter(QrCodeAdapter());
  Hive.registerAdapter(CachedProductAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(EditScanProductAdapter());
  Hive.registerAdapter(CategoryDetailAdapter());
  Hive.registerAdapter(CachedScannedProductAdapter());
  Hive.registerAdapter(ServiceChecklistItemHiveAdapter());
  Hive.registerAdapter(HiveServiceSelfieAdapter());
  Hive.registerAdapter(ServiceHiveImageAdapter());
  Hive.registerAdapter(OfflineServiceChecklistItemAdapter());
  Hive.registerAdapter(TaskJobAdapter());
  Hive.registerAdapter(FinishJobAdapter());
  Hive.registerAdapter(WorksheetDocumentAdapter());
  Hive.registerAdapter(ProjectCCEWDocumentAdapter());
  Hive.registerAdapter(SWMSDetailAdapter());
  Hive.registerAdapter(HazardQuestionAdapter());
  Hive.registerAdapter(RiskItemAdapter());
  Hive.registerAdapter(SafetyItemsAdapter());
  Hive.registerAdapter(HazardResponseAdapter());
  Hive.registerAdapter(QrCodeVisibleAdapter());
  Hive.registerAdapter(AttendanceAdapter());
  Hive.registerAdapter(AttendanceCheckoutAdapter());
  await Hive.openBox<OfflineChecklistItem>('offline_checklist');
  await Hive.openBox<HiveImage>('imagesBox');
  checkInternetAndInitialize();
  runApp(LoginApp());
}

class LoginApp extends StatefulWidget {
  @override
  _LoginAppState createState() => _LoginAppState();
}

class _LoginAppState extends State<LoginApp> {
  TimerManager _timerManager = TimerManager();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Page',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/calendar': (context) => CalenderPage(),
        '/service_jobs_list': (context) => ServiceJobsListview(),
        '/profile_main': (context) => ProfileMainPage(),
        '/profile': (context) => ProfilePage(),
        '/rewards': (context) => RewardsPage(),
        '/settings': (context) => SettingsPage(),
        '/privacy_policy': (context) => PrivacyPolicyPage(),
        '/terms_of_use': (context) => TermsOfUsePage(),
        '/installing_list_view': (context) => InstalledListView(),
        '/installing_form_view': (context) => FormViewScreen(),
        '/service_form_view': (context) => ServiceJobsFormView(),
        '/checklist': (context) => ChecklistPage(),
        '/service_checklist': (context) => ServiceChecklistPage(),
        '/notifications': (context) => NotificationsPage(),
      },
    );
  }
}

Future<void> _readNotification(int id) async {
  try {
    final response = await client?.callKw({
      'model': 'worksheet.notification',
      'method': 'write',
      'args': [
        [id],
        {
          'is_read': true,
        }
      ],
      'kwargs': {},
    });
    if (response == true) {
    } else {}
  } catch (e) {}
}

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/logo');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload != null) {
        try {
          final Map<String, dynamic> notificationJson =
              jsonDecode(response.payload!);
          final notificationItem = NotificationItem.fromJson(notificationJson);
          await _readNotification(notificationItem.id);
          showDialog(
            context: navigatorKey.currentState!.context,
            builder: (context) {
              return NotificationDetailsDialog(
                  notificationItem: notificationItem);
            },
          );
        } catch (e) {}
      }
    },
  );
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

  if (url.isEmpty || db.isEmpty || sessionId.isEmpty) {
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

  client = OdooClient(url, session);
}

Future<void> showNotification(int id, String title, String subject, String date,
    String body, String author) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    '1',
    'Beyond Solar Toolkit',
    channelDescription: 'Beyond Solar Rebates Application',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  Map<String, dynamic> notificationData = {
    'id': id,
    'title': title,
    'date': date,
    'body': body,
    'author': author,
    'isRead': true,
  };

  await flutterLocalNotificationsPlugin.show(
    id,
    title,
    date,
    platformChannelSpecifics,
    payload: jsonEncode(notificationData),
  );
}

final Set<int> notifiedEntryIds = {};

Future<void> fetchNewEntries() async {
  final prefs = await SharedPreferences.getInstance();
  userId = prefs.getInt('userId') ?? 0;
  _initializeOdooClient();
  try {
    final newEntries = await client?.callKw({
      'model': 'worksheet.notification',
      'method': 'search_read',
      'args': [
        [
          ['author_id', '=', userId],
        ],
      ],
      'kwargs': {'limit': 1, 'order': 'id desc'},
    });
    if (newEntries != null && newEntries is List && newEntries.isNotEmpty) {
      var entry = newEntries.first;
      int entryId = entry['id'];
      if (!notifiedEntryIds.contains(entryId)) {
        notifiedEntryIds.add(entryId);
        String title = entry['subject'] ?? 'New Entry';
        String body = entry['body'];
        String author = entry['author_id'][1];
        DateTime utcDateTime = DateTime.now();
        String formattedDateTime =
            DateFormat('yyyy-MM-dd hh:mm:ss a').format(utcDateTime);
        await showNotification(
            entryId, title, title, formattedDateTime, body, author);
      }
    }
  } catch (e) {}
}

class TimerManager {
  Timer? _timer;

  void startTimer(Function fetchNewEntries) {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {});
  }

  void stopTimer() {
    _timer?.cancel();
  }
}

Future<void> checkInternetAndInitialize() async {
  bool isFirstTime = true;

  Connectivity()
      .onConnectivityChanged
      .listen((ConnectivityResult result) async {
    if (isFirstTime) {
      isFirstTime = false;
      return;
    }
    if (result != ConnectivityResult.none) {
      await initializer.initialize();
    }
  });
}

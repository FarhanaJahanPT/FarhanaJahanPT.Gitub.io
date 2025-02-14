import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../barcode/product_view.dart';
import '../installation/checklist.dart';
import '../main.dart';
import '../notification/notification.dart';
import '../notification/notification_alert.dart';
import '../offline_db/checklist/checklist_item_hive.dart';
import '../offline_db/checklist/edit_checklist.dart';
import '../offline_db/installation_form/attendance.dart';
import '../offline_db/installation_form/attendance_checkout.dart';
import '../offline_db/installation_form/document.dart';
import '../offline_db/installation_form/owner_details.dart';
import '../offline_db/installation_form/product_category.dart';
import '../offline_db/installation_form/product_details.dart';
import '../offline_db/installation_form/project_document.dart';
import '../offline_db/installation_form/worksheet.dart';
import '../offline_db/installation_list/assignee.dart';
import '../offline_db/installation_list/installing_job.dart';
import '../offline_db/notification/notification.dart';
import '../offline_db/notification/notification_edit.dart';
import '../offline_db/product_scan/edit_scan_product.dart';
import '../offline_db/product_scan/product_sacn.dart';
import '../offline_db/profile/edit_user.dart';
import '../offline_db/profile/profile.dart';
import '../offline_db/project_ccew_document/project_ccew_document.dart';
import '../offline_db/qr/qr_code.dart';
import '../offline_db/selfies/hive_selfie.dart';
import '../offline_db/selfies/selfie_edit.dart';
import '../offline_db/selfies/service_hive_selfie.dart';
import '../offline_db/selfies/service_selfie_edit.dart';
import '../offline_db/service_checklist/checklist_item_hive.dart';
import '../offline_db/service_checklist/edit_checklist.dart';
import '../offline_db/service_list/service_job.dart';
import '../offline_db/signatures/installer_signature.dart';
import '../offline_db/signatures/installer_signature_edit.dart';
import '../offline_db/signatures/owner_signature.dart';
import '../offline_db/signatures/owner_signature_edit.dart';
import '../offline_db/start_finish_job/finish_job.dart';
import '../offline_db/start_finish_job/task_job.dart';
import '../offline_db/swms/hazard_question.dart';
import '../offline_db/swms/hazard_response.dart';
import '../offline_db/swms/risk_item.dart';
import '../offline_db/swms/safety_items.dart';
import '../offline_db/swms/swms_detail.dart';
import '../offline_db/worksheet_document/worksheet_document.dart';
import '../offline_to_odoo/calendar.dart';
import '../offline_to_odoo/checklist.dart';
import '../offline_to_odoo/documents.dart';
import '../offline_to_odoo/install_jobs.dart';
import '../offline_to_odoo/notification.dart';
import '../offline_to_odoo/owner_details.dart';
import '../offline_to_odoo/product_and_selfies.dart';
import '../offline_to_odoo/profile.dart';
import '../offline_to_odoo/qr_code.dart';
import '../offline_to_odoo/risk_assessment.dart';
import '../offline_to_odoo/service_jobs.dart';
import '../offline_to_odoo/signature.dart';

class BackgroundService {
  static final service = FlutterBackgroundService();
  static OdooClient? client;
  static String url = "";
  static int? userId;
  static String? _errorMessage;
  static int? worksheetId;
  static List<Map<String, dynamic>> productList = [];
  static List<ProductDetails> scannedProducts = [];
  static bool isNetworkAvailable = false;
  static bool isUploadingChecklist = false;
  static bool isServiceUploadingChecklist = false;
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static Timer? _syncTimer;
  static bool stopBackground = false;
  static Profile profile = Profile();
  static Calendar calendar = Calendar();
  static final ChecklistStorageService checklist = ChecklistStorageService();
  static NotificationOffline notification = NotificationOffline();
  static projectSignatures signatures = projectSignatures();
  static documentsList document = documentsList();
  static productsList product = productsList();
  static InstallJobsBackground installJobs = InstallJobsBackground();
  static ServiceJobsBackground serviceJobs = ServiceJobsBackground();
  static QrCodeGenerate qrcode = QrCodeGenerate();
  static PartnerDetails owner_details = PartnerDetails();
  static RiskAssessment risk_assessment = RiskAssessment();

  static Future<void> initializeHive() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    if (!Hive.isAdapterRegistered(UserModelAdapter().typeId)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(NotificationEditAdapter().typeId)) {
      Hive.registerAdapter(NotificationEditAdapter());
    }
    if (!Hive.isAdapterRegistered(SignatureDataAdapter().typeId)) {
      Hive.registerAdapter(SignatureDataAdapter());
    }
    if (!Hive.isAdapterRegistered(OwnerSignatureEditDataAdapter().typeId)) {
      Hive.registerAdapter(OwnerSignatureEditDataAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveImageAdapter().typeId)) {
      Hive.registerAdapter(HiveImageAdapter());
    }
    if (!Hive.isAdapterRegistered(EditScanProductAdapter().typeId)) {
      Hive.registerAdapter(EditScanProductAdapter());
    }
    if (!Hive.isAdapterRegistered(OfflineChecklistItemAdapter().typeId)) {
      Hive.registerAdapter(OfflineChecklistItemAdapter());
    }
    if (!Hive.isAdapterRegistered(DocumentAdapter().typeId)) {
      Hive.registerAdapter(DocumentAdapter());
    }
    if (!Hive.isAdapterRegistered(InstallingJobAdapter().typeId)) {
      Hive.registerAdapter(InstallingJobAdapter());
    }
    if (!Hive.isAdapterRegistered(PartnerAdapter().typeId)) {
      Hive.registerAdapter(PartnerAdapter());
    }
    if (!Hive.isAdapterRegistered(ServiceJobsAdapter().typeId)) {
      Hive.registerAdapter(ServiceJobsAdapter());
    }
    if (!Hive.isAdapterRegistered(AssigneeAdapter().typeId)) {
      Hive.registerAdapter(AssigneeAdapter());
    }
    if (!Hive.isAdapterRegistered(UserAdapter().typeId)) {
      Hive.registerAdapter(UserAdapter());
    }
    if (!Hive.isAdapterRegistered(InstallerSignatureAdapter().typeId)) {
      Hive.registerAdapter(InstallerSignatureAdapter());
    }
    if (!Hive.isAdapterRegistered(OwnerSignatureHiveAdapter().typeId)) {
      Hive.registerAdapter(OwnerSignatureHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(ProductDetailAdapter().typeId)) {
      Hive.registerAdapter(ProductDetailAdapter());
    }
    if (!Hive.isAdapterRegistered(ProjectDocumentsAdapter().typeId)) {
      Hive.registerAdapter(ProjectDocumentsAdapter());
    }
    if (!Hive.isAdapterRegistered(WorksheetAdapter().typeId)) {
      Hive.registerAdapter(WorksheetAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveSelfieAdapter().typeId)) {
      Hive.registerAdapter(HiveSelfieAdapter());
    }
    if (!Hive.isAdapterRegistered(ChecklistItemHiveAdapter().typeId)) {
      Hive.registerAdapter(ChecklistItemHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(NotificationModelAdapter().typeId)) {
      Hive.registerAdapter(NotificationModelAdapter());
    }
    if (!Hive.isAdapterRegistered(QrCodeAdapter().typeId)) {
      Hive.registerAdapter(QrCodeAdapter());
    }
    if (!Hive.isAdapterRegistered(CachedProductAdapter().typeId)) {
      Hive.registerAdapter(CachedProductAdapter());
    }
    if (!Hive.isAdapterRegistered(CategoryAdapter().typeId)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(CategoryDetailAdapter().typeId)) {
      Hive.registerAdapter(CategoryDetailAdapter());
    }
    if (!Hive.isAdapterRegistered(CachedScannedProductAdapter().typeId)) {
      Hive.registerAdapter(CachedScannedProductAdapter());
    }
    if (!Hive.isAdapterRegistered(ServiceChecklistItemHiveAdapter().typeId)) {
      Hive.registerAdapter(ServiceChecklistItemHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveServiceSelfieAdapter().typeId)) {
      Hive.registerAdapter(HiveServiceSelfieAdapter());
    }
    if (!Hive.isAdapterRegistered(ServiceHiveImageAdapter().typeId)) {
      Hive.registerAdapter(ServiceHiveImageAdapter());
    }
    if (!Hive.isAdapterRegistered(
        OfflineServiceChecklistItemAdapter().typeId)) {
      Hive.registerAdapter(OfflineServiceChecklistItemAdapter());
    }
    if (!Hive.isAdapterRegistered(TaskJobAdapter().typeId)) {
      Hive.registerAdapter(TaskJobAdapter());
    }
    if (!Hive.isAdapterRegistered(FinishJobAdapter().typeId)) {
      Hive.registerAdapter(FinishJobAdapter());
    }
    if (!Hive.isAdapterRegistered(WorksheetDocumentAdapter().typeId)) {
      Hive.registerAdapter(WorksheetDocumentAdapter());
    }
    if (!Hive.isAdapterRegistered(ProjectCCEWDocumentAdapter().typeId)) {
      Hive.registerAdapter(ProjectCCEWDocumentAdapter());
    }
    if (!Hive.isAdapterRegistered(SWMSDetailAdapter().typeId)) {
      Hive.registerAdapter(SWMSDetailAdapter());
    }
    if (!Hive.isAdapterRegistered(HazardQuestionAdapter().typeId)) {
      Hive.registerAdapter(HazardQuestionAdapter());
    }
    if (!Hive.isAdapterRegistered(RiskItemAdapter().typeId)) {
      Hive.registerAdapter(RiskItemAdapter());
    }
    if (!Hive.isAdapterRegistered(SafetyItemsAdapter().typeId)) {
      Hive.registerAdapter(SafetyItemsAdapter());
    }
    if (!Hive.isAdapterRegistered(HazardResponseAdapter().typeId)) {
      Hive.registerAdapter(HazardResponseAdapter());
    }
    if (!Hive.isAdapterRegistered(AttendanceAdapter().typeId)) {
      Hive.registerAdapter(AttendanceAdapter());
    }
    if (!Hive.isAdapterRegistered(AttendanceCheckoutAdapter().typeId)) {
      Hive.registerAdapter(AttendanceCheckoutAdapter());
    }
    initializeNotifications();
  }

  static Future<void> initializeService() async {
    print("ddddddddddddddddddddddddddddddddddddddddxxxxxxxxxxxsssssssssssss");
    await initializeHive();
    await Future.delayed(Duration(seconds: 2));
    tz.initializeTimeZones();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: false,
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<void> stopService() async {
    _syncTimer?.cancel();
    print("Sync Timer stopped");

    if (await service.isRunning()) {
      service.invoke("stopService");
      print("Background service stopped");
    }
  }

  static Future<void> handleLogout() async {
    await stopService();
    print("Logged out, background service stopped.");
  }

  static Future<void> _checkConnectivity() async {
    print("ffffffffffffffffffffdeeeerrrrr");
    var connectivityResult = await Connectivity().checkConnectivity();
    print(connectivityResult);
    isNetworkAvailable = connectivityResult != ConnectivityResult.none;
    print(isNetworkAvailable);
    Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      isNetworkAvailable = result != ConnectivityResult.none;
      if (isNetworkAvailable) {}
    });
  }

  static Future<void> _initializeOdooClient() async {
    print("88888888888888888");
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

  static Future<void> initializeNotifications() async {
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
            final notificationItem =
                NotificationItem.fromJson(notificationJson);
            await _readNotification(notificationItem.id);
            showDialog(
              context: navigatorKey.currentState!.context,
              builder: (context) {
                return NotificationDetailsDialog(
                    notificationItem: notificationItem);
              },
            );
          } catch (e) {
            print("Error decoding notification payload: $e");
          }
        }
      },
    );
    await requestNotificationPermission();

  }

  static Future<void> requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  static Future<void> showNotification(int id, String title, String subject, String date,
      String body, String author) async {
    print("55555555555555fffggggggggggggffffffffffffffffffffffff");
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

  static final Set<int> notifiedEntryIds = {};

  static Future<void> fetchNewEntries() async {
    print("ooooooooooooooooooooooooooooooohhhhhhhhhhhhhhhhhhhh");
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    _initializeOdooClient();
    try {
      print("555555555555555555555555555555ffffffffffffcccccccc");
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
      print(newEntries);
      print("newEntriesnewEntriesnewEntries");
      if (newEntries != null && newEntries is List && newEntries.isNotEmpty) {
        var entry = newEntries.first;
        int entryId = entry['id'];
        if (!notifiedEntryIds.contains(entryId)) {
          print("0000000000000000000000000000000000");
          notifiedEntryIds.add(entryId);
          print(notifiedEntryIds);
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
    } catch (e) {
      print("Failed to fetch entries: $e");
    }
  }


  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    await initializeHive();
    print("999999999999999999999999");
    bool isFirstRun = true;
    print("kkkkkkkkkkk$isFirstRun");
    // await _checkConnectivity();
    print("1111111111111111111111111111111111");
    await _initializeOdooClient();
    print("fffffffffffffffffffffffffffffffffffcf");
    await fetchNewEntries();
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Sync Service",
        content: "Background service initialized...",
      );
    }
    await profile.initializeOdooClient();
    await calendar.initializeOdooClient();
    await checklist.initializeOdooClient();
    await notification.initializeOdooClient();
    await signatures.initializeOdooClient();
    await document.initializeOdooClient();
    await product.initializeOdooClient();
    await installJobs.initializeOdooClient();
    await serviceJobs.initializeOdooClient();
    await qrcode.initializeOdooClient();
    await owner_details.initializeOdooClient();
    await risk_assessment.initializeOdooClient();
    _syncTimer = Timer.periodic(Duration(minutes: 30), (timer) async {
      service.on('stopService').listen((event) {
        service.stopSelf();
        timer.cancel();
      });
      print("-------------------------------dddddddddddddddd");
      await _checkConnectivity();
      await _initializeOdooClient();
      await fetchNewEntries();
      // await _attendanceAddOffline();
      // await _attendanceCheckoutOffline();
      // await _startJobOffline();
      // if (service is AndroidServiceInstance) {
      //   service.setForegroundNotificationInfo(
      //     title: "Sync Service",
      //     content: "Syncing offline database...",
      //   );
      // }
      print(isNetworkAvailable);
      print("isNetworkAvailableisNetworkAvailableisNetworkAvailable");
      if (isNetworkAvailable) {
        Timer.periodic(Duration(minutes: 30), (timer) async {
          print("fffffffffffffdddddddddddddfffffffffffffffffffffff");
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: "Sync Service",
              content: "Syncing offline database...",
            );
          }
          // await _attendanceAddOffline();
          await _processSavedImages();
          await _processServiceSavedImages();
          // await _startJobOffline();
          await uploadRiskItems();
          await uploadRequiredItemsForWork();
          await uploadHazardResponse();
          await _uploadProfileOffline();
          await _uploadNotificationOffline();
          await _uploadInstallerSignatureOffline();
          await _uploadOwnerSignatureOffline();
          await syncCachedProducts();
          await _uploadServiceChecklistOffline();
          await _uploadChecklistOffline();
          await _finishJobOffline();
          await initializer.initialize();
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: "Sync Service",
              content: "Offline database synchronized successfully...",
            );
          }
        });
        // }
      }
    });
  }

  static Future<void> _uploadServiceChecklistOffline() async {
    print("hhhhhhhhhhhhhhhhhhhhhhhhh");
    if (isServiceUploadingChecklist) {
      return;
    }

    isServiceUploadingChecklist = true;

    try {
      final box = await Hive.openBox<OfflineServiceChecklistItem>(
          'offline_service_checklist');
      var connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        return;
      }
      print(box);
      print("bbbbbbbbbbbbooooooooooooxxxxxxxxxx");
      if (box.isNotEmpty) {
        for (var entry in box.toMap().entries) {
          var compositeKey = entry.key as String;
          var item = entry.value as OfflineServiceChecklistItem;
          print(item);
          print("itemitemvvvvvvvvvvvvvvv");
          try {
            ChecklistItem checklistItem = ChecklistItem(
              key: item.checklistId,
              title: item.title,
              isMandatory: item.isMandatory,
              type: item.type,
              requiredImages: item.requiredImages,
              uploadedImages: item.uploadedImages
                  .map((imagePath) => File(imagePath))
                  .toList(),
            );

            int? worksheetId = int.tryParse(item.worksheetId);
            if (item.imageBase64.isNotEmpty) {
              for (var rec in item.imageBase64) {
                final imageBytes = base64Decode(rec);
                File? imageFile =
                    await _writeImageToFile(imageBytes, item.checklistId);

                if (item.type == 'img') {
                  print(item.position);
                  print("item.positionitem.positionitem.position");
                  await uploadServiceChecklist(
                      checklistItem, imageFile, worksheetId!, item.position,item.createTime);
                }
              }
            } else if (item.textContent != null) {
              await uploadServiceTextToChecklist(checklistItem,
                  item.textContent!, worksheetId!, item.position, item.createTime);
            }

            await box.delete(compositeKey);
          } catch (e) {}
        }
      } else {}
      await box.close();
    } finally {
      isServiceUploadingChecklist = false;
    }
  }

  static Future<void> _uploadChecklistOffline() async {
    print("hhhhhhhhhhhhhhhhhhhhhhhhh");
    if (isUploadingChecklist) {
      return;
    }

    isUploadingChecklist = true;

    try {
      final box = await Hive.openBox<OfflineChecklistItem>('offline_checklist');
      var connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        return;
      }
      print(box);
      print("bbbbbbbbbbbbooooooooooooxxxxxxxxxx");
      if (box.isNotEmpty) {
        for (var entry in box.toMap().entries) {
          var compositeKey = entry.key as String;
          var item = entry.value as OfflineChecklistItem;
          print(item);
          print("itemitemvvvvvvvvvvvvvvv");
          try {
            ChecklistItem checklistItem = ChecklistItem(
              key: item.checklistId,
              title: item.title,
              isMandatory: item.isMandatory,
              type: item.type,
              requiredImages: item.requiredImages,
              uploadedImages: item.uploadedImages
                  .map((imagePath) => File(imagePath))
                  .toList(),
            );

            int? worksheetId = int.tryParse(item.worksheetId);
            if (item.imageBase64.isNotEmpty) {
              for (var rec in item.imageBase64) {
                final imageBytes = base64Decode(rec);
                File? imageFile =
                    await _writeImageToFile(imageBytes, item.checklistId);

                if (item.type == 'img') {
                  print(item.position);
                  print("item.positionitem.positionitem.position");
                  await uploadChecklist(checklistItem, imageFile, worksheetId!,
                      item.position, item.createTime);
                }
              }
            } else if (item.textContent != null) {
              await uploadTextToChecklist(checklistItem, item.textContent!,
                  worksheetId!, item.position, item.createTime);
            }

            await box.delete(compositeKey);
          } catch (e) {
            print(
                "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee$e");
          }
        }
      } else {}
      await box.close();
    } finally {
      isUploadingChecklist = false;
    }
  }

  static Future<void> deleteAllHiveBoxes() async {
    await Hive.deleteFromDisk();
  }

  static Future<UserModel?> loadEditedProfileFromHive() async {
    Box<UserModel>? box;
    try {
      box = await Hive.openBox<UserModel>('userProfileBox');
      print("Box opened: $box");
      if (box.isEmpty) {
        return null;
      }
      print("Box contents: $box");
      UserModel? user = box.get('user');
      return user;
    } catch (e) {
      print("Error occurred while accessing Hive: $e");
      return null;
    } finally {
      if (box != null && box.isOpen) {
        await box.close();
        print("Box closed properly.");
      }
    }
  }

  static Future<void> _startJobOffline() async {
    final box = await Hive.openBox<TaskJob>('taskJobsBox');
    try {
      final taskJobs = box.values.toList();
      print(taskJobs);
      print("taskJobstaskJobs4444444444444444444444444");

      if (taskJobs.isEmpty) {
        debugPrint('No offline tasks to process.');
        return;
      }

      for (var task in taskJobs) {
        debugPrint('Processing Task ID: ${task.taskId}, Status');

        try {
          final response = await client?.callKw({
            'model': 'project.task',
            'method': 'write',
            'args': [
              [task.taskId],
              {
                'install_status': 'progress',
                'date_worksheet_start': task.date,
              },
            ],
            'kwargs': {},
          });

          if (response == true) {
            await box.delete(task.key);
            debugPrint(
                'Task ID: ${task.taskId} synced and removed from offline storage.');
          } else {
            debugPrint(
                'Failed to sync Task ID: ${task.taskId}. Keeping it offline.');
          }
        } catch (e) {
          debugPrint('Error syncing Task ID: ${task.taskId} - $e');
        }
      }

      await box.clear();
    } catch (e) {
      debugPrint('Error processing offline tasks: $e');
    } finally {
      await box.close();
      debugPrint('Closed the Hive box.');
    }
  }

  static Future<void> _attendanceAddOffline() async {
    print("fffffffffffffffffffffffffffffffffffffddddddd");
    var box = await Hive.openBox<Attendance>('attendance');
    try {
      final attendanceList = box.values.toList();
      print(attendanceList);
      print("cccccccccccccccccccccccccccccdddddd");

      if (attendanceList.isEmpty) {
        debugPrint('No offline attendanceList to process.');
        return;
      }

      for (var attendance in attendanceList) {
        debugPrint('Processing attendanceList ID: ${attendance.worksheetId}');

        try {
          final response = await client?.callKw({
            'model': 'worksheet.attendance',
            'method': 'create',
            'args': [
              {
                'type': 'check_in',
                'worksheet_id': attendance.worksheetId,
                'in_latitude': attendance.latitude,
                'in_longitude': attendance.longitude,
                'member_id': attendance.memberId,
                'date': attendance.date
              }
            ],
            'kwargs': {},
          });

          if (response == true) {
            await box.delete(attendance.worksheetId); // Use 'attendance.key' instead of 'task.key'
            debugPrint(
                'Attendance ID: ${attendance.worksheetId} synced and removed from offline storage.');
          } else {
            debugPrint(
                'Failed to sync Attendance ID: ${attendance.worksheetId}. Keeping it offline.');
          }
        } catch (e) {
          debugPrint('Error syncing Attendance ID: ${attendance.worksheetId} - $e');
        }
      }

      await box.clear();
    } catch (e) {
      debugPrint('Error processing offline tasks: $e');
    } finally {
      await box.close();
      debugPrint('Closed the Hive box.');
    }
  }

  static Future<void> _attendanceCheckoutOffline() async {
    var box = await Hive.openBox<AttendanceCheckout>('attendance_checkout');
    try {
      final taskAttendance = box.values.toList();
      print(taskAttendance);

      if (taskAttendance.isEmpty) {
        debugPrint('No offline tasks to process.');
        return;
      }

      for (var attendance in taskAttendance) {
        debugPrint('Processing Attendance ID: ${attendance.worksheetId}');

        try {
          final response = await client?.callKw({
            'model': 'worksheet.attendance',
            'method': 'create',
            'args': [
              {
                'type': 'check_out',
                'worksheet_id': attendance.worksheetId,
                'in_latitude': attendance.latitude,
                'in_longitude': attendance.longitude,
                'member_id': attendance.memberId,
                'date': attendance.date
              }
            ],
            'kwargs': {},
          });

          if (response == true) {
            await box.delete(attendance.worksheetId); // Use 'attendance.key' instead of 'task.key'
            debugPrint(
                'Attendance ID: ${attendance.worksheetId} synced and removed from offline storage.');
          } else {
            debugPrint(
                'Failed to sync Attendance ID: ${attendance.worksheetId}. Keeping it offline.');
          }
        } catch (e) {
          debugPrint('Error syncing Attendance ID: ${attendance.worksheetId} - $e');
        }
      }

      await box.clear(); // Ensure you want to clear the box after syncing
    } catch (e) {
      debugPrint('Error processing offline tasks: $e');
    } finally {
      await box.close();
      debugPrint('Closed the Hive box.');
    }
  }


  static Future<void> uploadRiskItems() async {
    final box = await Hive.openBox<RiskItem>('riskItems');
    print(box);
    try {
      final riskItems = box.values.toList();
      print(riskItems);
      print("taskJobstaskJobs444444......4444444444444444444");

      if (riskItems.isEmpty) {
        debugPrint('No offline tasks to process.');
        return;
      }

      for (var task in riskItems) {
        debugPrint('Processing Task ID: ${task.worksheetId}, Status');
        print(task.fieldValues);
        print("ddddddddddddddddddddddddddddddddddccccccccccccccc");
        var args = [
          task.worksheetId,
          task.fieldValues,
        ];
        try {
          final response = await client?.callKw({
            'model': 'task.worksheet',
            'method': 'write',
            'args': args,
            'kwargs': {},
          });

          if (response == true) {
            await box.delete(task.key);
            debugPrint(
                'Task ID: ${task.worksheetId} synced and removed from offline storage.');
          } else {
            debugPrint(
                'Failed to sync Task ID: ${task.worksheetId}. Keeping it offline.');
          }
        } catch (e) {
          debugPrint('Error syncing Task ID: ${task.worksheetId} - $e');
        }
      }
    } catch (e) {
      debugPrint('Error processing offline tasks: $e');
    } finally {
      await box.close();
      debugPrint('Closed the Hive box.');
    }
  }

  static Future<void> uploadRequiredItemsForWork() async {
    final box = await Hive.openBox<SafetyItems>('safetyItems');
    print(box);
    try {
      final riskItems = box.values.toList();
      print(riskItems);
      print("88888888888888888888888888888******************");

      if (riskItems.isEmpty) {
        debugPrint('No offline tasks to process.');
        return;
      }

      for (var task in riskItems) {
        debugPrint('Processing Task ID: ${task.worksheetId}, Status');
        print(task.fieldValues);
        print("3333333333333333ffffffffffffff");
        var args = [
          task.worksheetId,
          task.fieldValues,
        ];
        try {
          final response = await client?.callKw({
            'model': 'task.worksheet',
            'method': 'write',
            'args': args,
            'kwargs': {},
          });

          if (response == true) {
            await box.delete(task.worksheetId);
            debugPrint(
                'Task ID: ${task.worksheetId} syncecccccccccccccccd and removed from offline storage.');
          } else {
            debugPrint(
                'Failed to sync Task ID: ${task.worksheetId}. Keeping it offline.');
          }
        } catch (e) {
          debugPrint('Error syncing Task ID: ${task.worksheetId} - $e');
        }
      }
    } catch (e) {
      debugPrint('Error processing offline tasks: $e');
    } finally {
      await box.close();
      debugPrint('Closed the Hive box.');
    }
  }

  static Future<void> uploadHazardResponse() async {
    var box = await Hive.openBox<HazardResponse>('hazardResponsesBox');
    print(box);
    print("fffffffffffkkkkkkkkkkkffffff");

    try {
      var hazardResponses = box.values.toList();

      if (hazardResponses.isNotEmpty) {
        for (var response in hazardResponses) {
          print(response.memberId);
          print("ddddddddddddddddddddddxxxxxxxxxxxxs");
          List<Map<String, dynamic>> createData = [
            {
              'installation_question_id': response.installationQuestionId,
              'team_member_input': response.teamMemberInput,
              'worksheet_id': response.worksheetId,
              'member_id': response.memberId,
            }
          ];
          print("createDatacreateDatacreateData$createData");
          for (var data in createData) {
            try {
              print("dddddddddddddddddddcheckResponsecheckResponse");
              final checkResponse = await client?.callKw({
                'model': 'swms.team.member.input',
                'method': 'search_read',
                'args': [
                  [
                    [
                      'installation_question_id',
                      '=',
                      data['installation_question_id']
                    ],
                    ['worksheet_id', '=', data['worksheet_id']]
                  ],
                  ['id']
                ],
                'kwargs': {},
              });
              print(data['team_member_input']);
              print("dddddddddkkkkkkkkkkkkkkkkkkddddddddddd");
              if (checkResponse != null && checkResponse.isNotEmpty) {
                final existingRecordId = checkResponse[0]['id'];
                print("existingRecordIdexistingRecordId$existingRecordId");
                final updateResponse = await client?.callKw({
                  'model': 'swms.team.member.input',
                  'method': 'write',
                  'args': [
                    existingRecordId,
                    {
                      'team_member_input': data['team_member_input'],
                    }
                  ],
                  'kwargs': {},
                });

                if (updateResponse != null) {
                  print("Hazard response updated successfully");
                  await box.deleteAt(hazardResponses.indexOf(response));
                } else {
                  print("Failed to update hazard response");
                }
              } else {
                final createResponse = await client?.callKw({
                  'model': 'swms.team.member.input',
                  'method': 'create',
                  'args': [data],
                  'kwargs': {},
                });

                if (createResponse != null) {
                  print("Hazard response created successfully");
                  await box.deleteAt(hazardResponses.indexOf(response));
                } else {
                  print("Failed to create hazard response");
                }
              }
            } catch (e) {
              print("Error: $e");
            }
          }
        }
      } else {
        print('No offline hazard responses to upload.');
      }
    } catch (e) {
      debugPrint('Error processing offline tasks: $e');
    } finally {
      await box.close();
      debugPrint('Closed the Hive box.');
    }
  }

  static Future<void> _finishJobOffline() async {
    var box = await Hive.openBox<FinishJob>('finishJobsBox');
    try {
      final taskJobs = box.values.toList();
      print(taskJobs);
      print("taskJobstaskJobs4ssssssssssss444444444444444444444444");

      if (taskJobs.isEmpty) {
        debugPrint('No offline tasks to process.');
        return;
      }

      for (var task in taskJobs) {
        debugPrint('Processing Task ID: ${task.taskId}, Status');

        try {
          final response = await client?.callKw({
            'model': 'project.task',
            'method': 'write',
            'args': [
              [task.taskId],
              {
                'install_status': 'done',
              },
            ],
            'kwargs': {},
          });

          if (response == true) {
            await box.delete(task.key);
            debugPrint(
                'Task ID: ${task.taskId} synced and removed from offline storage.');
          } else {
            debugPrint(
                'Failed to sync Task ID: ${task.taskId}. Keeping it offline.');
          }
        } catch (e) {
          debugPrint('Error syncing Task ID: ${task.taskId} - $e');
        }
      }

      await box.clear();
    } catch (e) {
      debugPrint('Error processing offline tasks: $e');
    } finally {
      await box.close();
      debugPrint('Closed the Hive box.');
    }
  }

  static Future<void> _uploadProfileOffline() async {
    print("ddddddddddddddddddscdcewwcec");
    UserModel? userDetails = await loadEditedProfileFromHive();
    if (userDetails != null) {
      Map<String, dynamic> updatedDetails = {
        "name": userDetails.name,
        "email": userDetails.email,
        "phone": userDetails.phone,
        "contact_address_complete": userDetails.contactAddress,
      };
      bool success = await editProfileDetails(updatedDetails);
      if (!success) {}
    }
  }

  // static Future<void> _uploadNotificationOffline() async {
  //   var box = await Hive.openBox<NotificationEdit>('notificationsEdit');
  //   final notifications = box.values.toList();
  //   for (var notification in notifications) {
  //     bool success = await _readNotification(notification.id);
  //     if (!success) {
  //     } else {
  //       await box.delete(notification.id);
  //     }
  //   }
  //   await box.close();
  // }

  static Future<void> _uploadNotificationOffline() async {
    Box<NotificationEdit>? box;
    try {
      box = await Hive.openBox<NotificationEdit>('notificationsEdit');
      final notifications = box.values.toList();
      for (var notification in notifications) {
        bool success = await _readNotification(notification.id);
        if (success) {
          await box.delete(notification.id);
        }
      }
    } catch (e) {
      print("Error during notification upload: $e");
    } finally {
      if (box != null && box.isOpen) {
        await box.close();
        print("Box closed properly.");
      }
    }
  }

  static Future<bool> _readNotification(int id) async {
    try {
      final response = await client?.callKw({
        'model': 'worksheet.notification',
        'method': 'write',
        'args': [
          [id],
          {'is_read': true},
        ],
        'kwargs': {},
      });
      if (response == true) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // static Future<void> _uploadInstallerSignatureOffline() async {
  //   final box = await Hive.openBox<SignatureData>('signatureBox');
  //
  //   if (box.isNotEmpty) {
  //     final signatureDataList = box.values.toList();
  //     final futures = signatureDataList.map((signatureData) {
  //       return editSignatureDetails(
  //         signatureData.id,
  //         signatureData.installSignature,
  //         signatureData.witnessSignature,
  //         signatureData.name,
  //       );
  //     }).toList();
  //
  //     await Future.wait(futures);
  //     await box.clear();
  //   }
  //   await box.close();
  // }
  static Future<void> _uploadInstallerSignatureOffline() async {
    Box<SignatureData>? box;
    try {
      box = await Hive.openBox<SignatureData>('signatureBox');

      if (box.isNotEmpty) {
        final signatureDataList = box.values.toList();
        List<SignatureData> failedUploads = [];

        for (var signatureData in signatureDataList) {
          try {
            await editSignatureDetails(
              signatureData.id,
              signatureData.installSignature,
              signatureData.witnessSignature,
              signatureData.name,
            );
          } catch (e) {
            print("Failed to upload signature ID ${signatureData.id}: $e");
            failedUploads.add(signatureData);
          }
        }

        if (failedUploads.isEmpty) {
          await box.clear();
          print("All signature data uploaded and box cleared.");
        } else {
          await box.putAll(Map.fromIterable(
            failedUploads,
            key: (item) => (item as SignatureData).id,
            value: (item) => item,
          ));
          print("${failedUploads.length} signatures failed to upload and were retained in the box.");
        }
      }
    } catch (e) {
      print("Error during uploading installer signatures: $e");
    } finally {
      if (box != null && box.isOpen) {
        await box.close();
        print("Box closed properly.");
      }
    }
  }


  static Future<void> editSignatureDetails(int id, Uint8List installSignature,
      Uint8List witnessSignature, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    String base64installSignature = base64Encode(installSignature);
    String base64witnessSignature = base64Encode(witnessSignature);
    String formattedDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    int projectId = id;
    try {
      final response = await client?.callKw({
        'model': 'project.task',
        'method': 'write',
        'args': [
          [projectId],
          {
            'install_signature': base64installSignature,
            // 'witness_signature': base64witnessSignature,
            'date_worksheet_install': formattedDate,
            // 'witness_signature_date': formattedDate,
            // 'witness_name': name
          }
        ],
        'kwargs': {},
      });

      if (response == true) {
      } else {}
    } catch (e) {}
  }

  // static Future<void> _uploadOwnerSignatureOffline() async {
  //   var box =
  //       await Hive.openBox<OwnerSignatureEditData>('ownerSignatureEditBox');
  //
  //   if (box.isNotEmpty) {
  //     final signatureDataList = box.values.toList();
  //     final futures = signatureDataList.map((signatureData) {
  //       return editOwnerSignatureDetails(
  //           signatureData.id, signatureData.ownerSignature, signatureData.name);
  //     }).toList();
  //
  //     await Future.wait(futures);
  //     await box.clear();
  //   }
  //   await box.close();
  // }
  static Future<void> _uploadOwnerSignatureOffline() async {
    Box<OwnerSignatureEditData>? box;
    try {
      box = await Hive.openBox<OwnerSignatureEditData>('ownerSignatureEditBox');

      if (box.isNotEmpty) {
        final signatureDataList = box.values.toList();
        final futures = signatureDataList.map((signatureData) {
          return editOwnerSignatureDetails(
            signatureData.id,
            signatureData.ownerSignature,
            signatureData.name,
          );
        }).toList();

        await Future.wait(futures);
        await box.clear();
        print("Owner signatures uploaded and box cleared.");
      }
    } catch (e) {
      print("Error during uploading owner signatures: $e");
    } finally {
      if (box != null && box.isOpen) {
        await box.close();
        print("Box closed properly.");
      }
    }
  }

  static Future<void> editOwnerSignatureDetails(
      int id, Uint8List signature, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    String base64Signature = base64Encode(signature);
    String formattedDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    int projectId = id;

    try {
      final response = await client?.callKw({
        'model': 'project.task',
        'method': 'write',
        'args': [
          [projectId],
          {
            'customer_signature': base64Signature,
            'customer_name': name,
            'date_worksheet_client_signature': formattedDate,
          }
        ],
        'kwargs': {},
      });
      if (response == true) {
      } else {}
    } catch (e) {}
  }

  static Future<bool> editProfileDetails(
      Map<String, dynamic> updatedDetails) async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    try {
      final response = await client?.callKw({
        'model': 'team.member',
        'method': 'write',
        'args': [
          [1],
          updatedDetails,
        ],
        'kwargs': {},
      });
      if (response == true) {
        return true;
      } else {
        _errorMessage = "Something went wrong. Please try again later.";
        return false;
      }
    } catch (e) {
      _errorMessage = "Something went wrong. Please try again later.";
      return false;
    }
  }

  static Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    print(permission);
    print("dddddddddddddddddddddddddddzzzzzzzzzzzzdddd");
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  static Future<void> uploadServiceTextToChecklist(
      ChecklistItem item, String inputText, int worksheetId, position, date) async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    // Position position = await _getCurrentLocation();
    List<Placemark> placemarks = await placemarkFromCoordinates(
        position['latitude'], position['longitude']);
    Placemark place = placemarks.first;
    String locationDetails =
        "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
    try {
      final existingChecklist = await client?.callKw({
        'model': 'service.checklist.item',
        'method': 'search_read',
        'args': [
          [
            ['service_id', '=', int.parse(item.key)],
            ['worksheet_id', '=', worksheetId]
          ],
          ['id']
        ],
        'kwargs': {},
      });
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(date);

      if (existingChecklist != null &&
          existingChecklist is List &&
          existingChecklist.isNotEmpty) {
        final checklistId = existingChecklist.first['id'];
        await client?.callKw({
          'model': 'service.checklist.item',
          'method': 'write',
          'args': [
            [checklistId],
            {
              'text': inputText,
              'location': locationDetails,
              'date': formattedDate,
              'latitude': position['latitude'],
              'longitude': position['longitude']
            }
          ],
          'kwargs': {},
        });
      } else {
        await client?.callKw({
          'model': 'service.checklist.item',
          'method': 'create',
          'args': [
            {
              'user_id': userId,
              'worksheet_id': worksheetId,
              'service_id': item.key,
              'date': formattedDate,
              'text': inputText,
              'location': locationDetails,
              'latitude': position['latitude'],
              'longitude': position['longitude']
            }
          ],
          'kwargs': {},
        });
      }
      item.textContent = inputText;
    } catch (e) {}
  }

  static Future<void> uploadTextToChecklist(ChecklistItem item,
      String inputText, int worksheetId, position, date) async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    // Position position = await _getCurrentLocation();
    List<Placemark> placemarks = await placemarkFromCoordinates(
        position['latitude'], position['longitude']);
    Placemark place = placemarks.first;
    String locationDetails =
        "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
    try {
      final existingChecklist = await client?.callKw({
        'model': 'installation.checklist.item',
        'method': 'search_read',
        'args': [
          [
            ['checklist_id', '=', int.parse(item.key)],
            ['worksheet_id', '=', worksheetId]
          ],
          ['id']
        ],
        'kwargs': {},
      });
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
      if (existingChecklist != null &&
          existingChecklist is List &&
          existingChecklist.isNotEmpty) {
        final checklistId = existingChecklist.first['id'];
        await client?.callKw({
          'model': 'installation.checklist.item',
          'method': 'write',
          'args': [
            [checklistId],
            {
              'text': inputText,
              'location': locationDetails,
              'date': formattedDate,
              'latitude': position['latitude'],
              'longitude': position['longitude']
            }
          ],
          'kwargs': {},
        });
      } else {
        await client?.callKw({
          'model': 'installation.checklist.item',
          'method': 'create',
          'args': [
            {
              'user_id': userId,
              'worksheet_id': worksheetId,
              'checklist_id': item.key,
              'text': inputText,
              'date': formattedDate,
              'location': locationDetails,
              'latitude': position['latitude'],
              'longitude': position['longitude']
            }
          ],
          'kwargs': {},
        });
      }
      item.textContent = inputText;
    } catch (e) {

    }
  }

  static Future<void> createInstallingChecklist(
      int taskId, ChecklistItem item, File? imageFile, position, date) async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    if (imageFile != null) {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position['latitude'], position['longitude']);
      Placemark place = placemarks.first;
      String locationDetails =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
      print(userId);
      print(date);
      print("locationDetailslocationDetails");
      int? checklistId = int.tryParse(item.key.toString());
      int? worksheetIdInt = int.tryParse(taskId.toString());
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
      if (checklistId == null || worksheetIdInt == null) {
        return;
      }
      try {
        final checklist = await client?.callKw({
          'model': 'installation.checklist.item',
          'method': 'create',
          'args': [
            {
              'user_id': userId,
              'worksheet_id': worksheetIdInt,
              'checklist_id': checklistId,
              'image': base64Image,
              'date': formattedDate,
              'location': locationDetails,
              'latitude': position['latitude'],
              'longitude': position['longitude']
            }
          ],
          'kwargs': {},
        });
        print(checklist);
        print("checklistchecklistchecklistchecklistchecklist");
      } catch (e) {
        print("$e/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeffffffffffffffffffffff");
      }
    }
  }

  static Future<void> createChecklist(
      int taskId, ChecklistItem item, File? imageFile, position,date) async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    if (imageFile != null) {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position['latitude'], position['longitude']);
      Placemark place = placemarks.first;
      String locationDetails =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
      print(locationDetails);
      print("locationDetailslaaaaaaaaaaaaaaaocationDetails");
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
      print("formattedDateforddddddmattedDateformattedDate$formattedDate");
      int? checklistId = int.tryParse(item.key.toString());
      int? worksheetIdInt = int.tryParse(taskId.toString());
      if (checklistId == null || worksheetIdInt == null) {
        return;
      }
      try {
        final checklist = await client?.callKw({
          'model': 'service.checklist.item',
          'method': 'create',
          'args': [
            {
              'user_id': userId,
              'worksheet_id': worksheetIdInt,
              'service_id': checklistId,
              'date': formattedDate,
              'image': base64Image,
              'location': locationDetails,
              'latitude': position['latitude'],
              'longitude': position['longitude']
            }
          ],
          'kwargs': {},
        });
      } catch (e) {
        print("fffffffffffffffffeeeeeeeddddddddddddddddd$e");
      }
    }
  }

  static Future<void> uploadServiceChecklist(
      ChecklistItem item, File? imageFile, int worksheetId, position,date) async {
    final prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('userId') ?? 0;
    print(position);
    print(imageFile);
    print("88888888888888888888positionnnnnnnnnn");
    if (imageFile != null) {
      List<int> imageBytes = await imageFile.readAsBytes();
      print(imageBytes);
      String base64Image = base64Encode(imageBytes);
      print(base64Image);
      print("base64Imagebase64Imagebase64Image6666666666666");
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position['latitude'], position['longitude']);
      Placemark place = placemarks.first;
      String locationDetails =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
      print(placemarks);
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(date);

      try {
        print(locationDetails);
        print("locationDetailsloccccccccccccccccationDetails");
        await createChecklist(worksheetId, item, imageFile, position,date);
        int? checklistId = int.tryParse(
            item.key.toString()); // Ensures checklistId is an integer
        int? worksheetIdInt = int.tryParse(worksheetId.toString());
        if (checklistId == null || worksheetIdInt == null) {
          return;
        }
        final checklist = await client?.callKw({
          'model': 'service.checklist.item',
          'method': 'write',
          'args': [
            [worksheetIdInt],
            {
              'worksheet_id': worksheetIdInt,
              'user_id': userId,
              'service_id': checklistId,
              'image': base64Image,
              'date': formattedDate,
              'location': locationDetails,
              'latitude': position['latitude'],
              'longitude': position['longitude']
            }
          ],
          'kwargs': {},
        });
        print(checklist);
        print("gffffffffffffffffffffffffchecklist");
      } catch (e) {}
    }
  }

  static Future<void> uploadChecklist(ChecklistItem item, File? imageFile,
      int worksheetId, position, date) async {
    final prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('userId') ?? 0;
    print(position);
    print(imageFile);
    print("88888888888888888888positionnnnnnnnnn");
    if (imageFile != null) {
      List<int> imageBytes = await imageFile.readAsBytes();
      print(imageBytes);
      String base64Image = base64Encode(imageBytes);
      print(base64Image);
      print("base64Imagebase64Imagebase64Image6666666666666");
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position['latitude'], position['longitude']);
      Placemark place = placemarks.first;
      String locationDetails =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
      print(placemarks);

      try {
        print(locationDetails);
        print("locationDetailsloccccccccccccccccationDetails");
        await createInstallingChecklist(
            worksheetId, item, imageFile, position, date);
        int? checklistId = int.tryParse(item.key.toString());
        print(checklistId);
        print("checklistIdchecklistIdchecklistId");
        int? worksheetIdInt = int.tryParse(worksheetId.toString());
        final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
        print("worksheetIdIntworksheetIdIntworksheetIdInt$worksheetIdInt");
        if (checklistId == null || worksheetIdInt == null) {
          return;
        }
        final checklist = await client?.callKw({
          'model': 'installation.checklist.item',
          'method': 'write',
          'args': [
            [worksheetIdInt],
            {
              'worksheet_id': worksheetIdInt,
              'user_id': userId,
              'checklist_id': checklistId,
              'date': formattedDate,
              'image': base64Image,
              'location': locationDetails,
              'latitude': position['latitude'],
              'longitude': position['longitude']
            }
          ],
          'kwargs': {},
        });
        print(checklist);
        print("gffffffffffffffffffffffffchecklist");
      } catch (e) {}
    }
  }

  static Future<File> _writeImageToFile(
      Uint8List imageBytes, String checklistId) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$checklistId.png';
    final file = File(filePath);
    return file.writeAsBytes(imageBytes);
  }

  static bool onIosBackground(ServiceInstance service) {
    return true;
  }

  static Future<List<HiveImage>> _getSavedImagesFromHive() async {
    final box = await Hive.openBox<HiveImage>('imagesBox');
    print(box);
    print(box.values);
    print("hjbbvffffffffffffffffff");
    return box.values.toList();
  }

  static Future<List<ServiceHiveImage>> _getServiceSavedImagesFromHive() async {
    final box = await Hive.openBox<ServiceHiveImage>('serviceImagesBox');
    print(box);
    print(box.values);
    print("hjbbvffffffffffffffffff");
    return box.values.toList();
  }

  // static Future<void> _processSavedImages() async {
  //   final savedImages = await _getSavedImagesFromHive();
  //   print(savedImages);
  //   print("sssssssssssssssssssssssssssssaaaaaaaaa");
  //   for (var image in savedImages) {
  //     _offlineUploadSelfie(image.checklistType, image.base64Image,
  //         image.projectId, image.categIdList,image.position);
  //   }
  //   final box = await Hive.openBox<HiveImage>('imagesBox');
  //   await box.clear();
  //   await box.close();
  // }
  static Future<void> _processSavedImages() async {
    print("66666666666666666666666666666666666666666666666666666");
    Box<HiveImage>? box;
    bool allUploadsSuccessful = true;

    try {
      final savedImages = await _getSavedImagesFromHive();
      print(savedImages);
      print("sssssssssssssssssssssssssssssaaaaaaaaa");

      box = await Hive.openBox<HiveImage>('imagesBox');

      for (var image in savedImages) {
        try {
          await _offlineUploadSelfie(
            image.checklistType,
            image.base64Image,
            image.projectId,
            image.categIdList,
            image.position,
            image.timestamp,
          );
        } catch (e) {
          allUploadsSuccessful = false;
          print("Error uploading image: $e");
        }
      }

      if (allUploadsSuccessful) {
        await box.clear();
        print("Saved images processed and box cleared.");
      } else {
        print("Some images failed to upload. Box will not be cleared.");
      }

    } catch (e) {
      print("Error processing saved images: $e");
    } finally {
      if (box != null && box.isOpen) {
        await box.close();
        print("Box closed properly.");
      }
    }
  }

  // static Future<void> _processServiceSavedImages() async {
  //   final savedImages = await _getServiceSavedImagesFromHive();
  //   print(savedImages);
  //   print("sssssssssssssssssssssssssssssaaaaaaaaa");
  //   for (var image in savedImages) {
  //     _offlineServiceUploadSelfie(image.checklistType, image.base64Image,
  //         image.projectId, image.categIdList,image.position);
  //   }
  //   final box = await Hive.openBox<ServiceHiveImage>('serviceImagesBox');
  //   await box.clear();
  //   await box.close();
  // }
  static Future<void> _processServiceSavedImages() async {
    Box<ServiceHiveImage>? box;
    try {
      final savedImages = await _getServiceSavedImagesFromHive();
      print(savedImages);
      print("sssssssssssssssssssssssssssssaaaaaaaaa");

      // Process each saved image
      for (var image in savedImages) {
        _offlineServiceUploadSelfie(
          image.checklistType,
          image.base64Image,
          image.projectId,
          image.categIdList,
          image.position,
        );
      }

      // Open the Hive box
      box = await Hive.openBox<ServiceHiveImage>('serviceImagesBox');

      // Clear the box after processing
      await box.clear();
      print("Service images processed and box cleared.");
    } catch (e) {
      print("Error processing service saved images: $e");
    } finally {
      // Ensure the box is closed
      if (box != null && box.isOpen) {
        await box.close();
        print("Box closed properly.");
      }
    }
  }

  static void _offlineServiceUploadSelfie(String checklistType,
      String base64Image, int projectId, List categIdList, position) async {
    print(checklistType);
    print(base64Image);
    print(projectId);
    print(categIdList);
    print(position);
    try {
      final checklist = await client?.callKw({
        'model': 'service.checklist',
        'method': 'search_read',
        'args': [
          [
            ['category_ids', 'in', categIdList],
            ['selfie_type', '=', checklistType],
          ],
          ['id']
        ],
        'kwargs': {},
      });
      print(checklist);
      print("checklistchecklistchecklistchecklist");
      await _uploadServiceImage(
          checklist[0]['id'], base64Image, projectId, position);
    } catch (r) {
      print("hi derasssssssssssssssssssssssss");
    }
  }

  static Future<void> _offlineUploadSelfie(String checklistType, String base64Image,
      int projectId, List categIdList, position, date) async {
    print(checklistType);
    print(base64Image);
    print(projectId);
    print(categIdList);
    print(position);
    print("77777777777777777777777777777777777777");
    try {
      final checklist = await client?.callKw({
        'model': 'installation.checklist',
        'method': 'search_read',
        'args': [
          [
            ['category_ids', 'in', categIdList],
            ['selfie_type', '=', checklistType],
          ],
          ['id']
        ],
        'kwargs': {},
      });
      print(checklistType);
      print("checklistchecklicccccccccccccccccccccstchecklistchecklist");
      if(checklistType == 'check_in') {
        bool success = await _uploadImage(
            checklist[0]['id'], base64Image, projectId, position, date);
        if (success) {
          await _startJobOffline();
          await _attendanceAddOffline();
        }
      }
      if(checklistType == 'check_out') {
        bool success = await _uploadImage(
            checklist[0]['id'], base64Image, projectId, position, date);
        if (success) {
          await _attendanceCheckoutOffline();
        }
      }else{
        bool success = await _uploadImage(
            checklist[0]['id'], base64Image, projectId, position, date);
        if (success) {
          return;
        }
      }
    } catch (r) {
      print("hi derasssssssssssssssssssssssss$r");
    }
  }

  static Future<void> _uploadServiceImage(
      int id, String base64Image, int projectId, position) async {
    print(id);
    print(projectId);
    print("444444444jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj44444");
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    try {
      print("777777777777position");
      print(position);
      print("positionposition");
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position['latitude'], position['longitude']);
      Placemark place = placemarks.first;
      String locationDetails =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
      print(locationDetails);
      print(projectId);
      print("ooooooooooooooo");
      final worksheet = await client?.callKw({
        'model': 'task.worksheet',
        'method': 'search_read',
        'args': [
          [
            ['task_id', '=', projectId],
          ],
        ],
        'kwargs': {},
      });
      print(worksheet);
      print("worksheetworksheetsssssssssssssssss");
      if (worksheet != null && worksheet.isNotEmpty) {
        worksheetId = worksheet[0]['id'];
      }
      print(worksheetId);
      print("worksheetidddddddddddddddddddddd");
      final checklist = await client?.callKw({
        'model': 'service.checklist.item',
        'method': 'create',
        'args': [
          {
            'user_id': userId,
            'worksheet_id': worksheetId,
            'service_id': id,
            'image': base64Image,
            'location': locationDetails,
            'latitude': position['latitude'],
            'longitude': position['longitude']
          }
        ],
        'kwargs': {},
      });
      print(checklist);
    } catch (e) {}
  }

  static Future<bool> _uploadImage(
      int id, String base64Image, int projectId, position, date) async {
    print(id);
    print(projectId);
    print("444444444jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj44444");
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    try {
      print("777777777777position");
      print(position);
      print("positionposition");
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position['latitude'], position['longitude']);
      print(placemarks);
      print("hhhhhhhhhhhhhhhhhhhhhhhhhhhhh");
      Placemark place = placemarks.first;
      String locationDetails =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
      print(locationDetails);
      print(projectId);
      print("ooooooooooooooo");
      final worksheet = await client?.callKw({
        'model': 'task.worksheet',
        'method': 'search_read',
        'args': [
          [
            ['task_id', '=', projectId],
          ],
        ],
        'kwargs': {},
      });
      print(worksheet);
      print("worksheetworksheetsssssssssssssssss");
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
      if (worksheet != null && worksheet.isNotEmpty) {
        worksheetId = worksheet[0]['id'];
      }
      print(worksheetId);
      print("worksheetidddddddddddddddddddddd");
      final checklist = await client?.callKw({
        'model': 'installation.checklist.item',
        'method': 'create',
        'args': [
          {
            'user_id': userId,
            'worksheet_id': worksheetId,
            'checklist_id': id,
            'image': base64Image,
            'date': formattedDate,
            'location': locationDetails,
            'latitude': position['latitude'],
            'longitude': position['longitude']
          }
        ],
        'kwargs': {},
      });
      print(checklist);
      return checklist != null;
    } catch (e) {
      return false;
    }
  }

  // static Future<void> syncCachedProducts() async {
  //   final box = Hive.isBoxOpen('cachedProducts')
  //       ? Hive.box<EditScanProduct>('cachedProducts')
  //       : await Hive.openBox<EditScanProduct>('cachedProducts');
  //   final cachedProducts = box.toMap();
  //   print(cachedProducts);
  //   print("cachedProductscachedProductscachedProducts");
  //   if (cachedProducts.isNotEmpty) {
  //     for (var entry in cachedProducts.entries) {
  //       print("$entry/entryentryentryentryentryentryentry");
  //       final String barcode = entry.key;
  //       final EditScanProduct cachedProduct = entry.value;
  //       print(cachedProduct.position);
  //
  //       await _uploadScannedProducts(barcode, cachedProduct.imageData,
  //           cachedProduct.worksheetId, cachedProduct.type, cachedProduct.position);
  //       await box.delete(barcode);
  //     }
  //   } else {}
  //   await box.close();
  // }
  static Future<void> syncCachedProducts() async {
    Box<EditScanProduct>? box;
    try {
      // Open the Hive box
      box = Hive.isBoxOpen('cachedProducts')
          ? Hive.box<EditScanProduct>('cachedProducts')
          : await Hive.openBox<EditScanProduct>('cachedProducts');

      // Get all cached products from the box
      final cachedProducts = box.toMap();
      print(cachedProducts);
      print("cachedProductscachedProductscachedProducts");

      if (cachedProducts.isNotEmpty) {
        // Loop through each cached product and upload it
        for (var entry in cachedProducts.entries) {
          print("$entry/entryentryentryentryentryentryentry");
          final String barcode = entry.key;
          final EditScanProduct cachedProduct = entry.value;
          print(cachedProduct.position);

          // Upload the scanned product
          await _uploadScannedProducts(
              barcode,
              cachedProduct.imageData,
              cachedProduct.worksheetId,
              cachedProduct.type,
              cachedProduct.position);

          // Delete the product after upload
          await box.delete(barcode);
        }
      } else {
        print("No cached products to sync.");
      }
    } catch (e) {
      print("Error syncing cached products: $e");
    } finally {
      // Ensure the box is closed
      if (box != null && box.isOpen) {
        await box.close();
        print("Box closed properly.");
      }
    }
  }

  static Future<void> _uploadScannedProducts(String barcode,
      Uint8List? imageData, int worksheetId, String type, position) async {
    print("$position/positionpositionpositionpositionposition");
    try {
      // final productIds = await client!.callKw({
      //   'model': 'product.product',
      //   'method': 'search',
      //   'args': [
      //     [
      //       ['barcode', '=', barcode]
      //     ]
      //   ],
      //   'kwargs': {},
      // });
      final productIds = await client!.callKw({
        'model': 'stock.lot',
        'method': 'search_read',
        'args': [
          [
            ['name', '=', barcode]
          ]
        ],
        'kwargs': {
          'fields': ['product_id']
        },
      });

      if (productIds.isNotEmpty) {
        for (var productIdItem in productIds) {
          final lotId = productIdItem['id'];
          final productId = productIdItem['product_id'][0];
          final productData = await client!.callKw({
            'model': 'product.product',
            'method': 'read',
            'args': [
              productIds,
              ['name', 'standard_price', 'description_sale']
            ],
            'kwargs': {},
          });
          print("77777777777777777777777777777777777777");
          if (productData.isNotEmpty) {
            String fetchedProductName = productData[0]['name'];
            String unitPrice = productData[0]['standard_price'].toString();
            // final lotId = productData[0]['id'];
            // int productId = productData[0]['id'];
            await _addOrUpdateScannedProduct(
                barcode, fetchedProductName, unitPrice, productId, imageData);
            _uploadProductsToTaskWorksheet(lotId,worksheetId, type, position);
          }
        }
      } else {}
    } catch (e) {}
  }

  static Future<void> _addOrUpdateScannedProduct(
      String barcode,
      String productName,
      String unitPrice,
      int productId,
      Uint8List? imageData) async {
    print("55555555555555555555555555555555555555555555555555");
    final existingProduct = scannedProducts.firstWhere(
      (product) => product.serialNumber == barcode,
      orElse: () => ProductDetails(
        serialNumber: '',
        name: '',
        unitPrice: '',
        productId: 0,
        state: '',
      ),
    );
    if (existingProduct.serialNumber.isNotEmpty) {
      existingProduct.quantity++;
      existingProduct.imageData = imageData;
    } else {
      scannedProducts.add(ProductDetails(
        serialNumber: barcode,
        name: productName,
        unitPrice: unitPrice,
        imageData: imageData,
        quantity: 1,
        productId: productId,
        state: 'draft',
      ));
    }
  }

  static Future<void> _uploadProductsToTaskWorksheet(int lotId,
      int worksheetId, String type, position) async {
    print(position);
    print("4444444444444fffffffffffffffffffffffffffff");
    // Position position = await _getCurrentLocation();
    List<Placemark> placemarks = await placemarkFromCoordinates(
        position['latitude'], position['longitude']);
    // List<Placemark> placemarks =
    //     await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks.first;
    String locationDetails =
        "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    try {
      for (var product in scannedProducts) {
        Uint8List imageBytes =
            Uint8List.fromList(product.imageData as List<int>);
        String base64Image = base64Encode(imageBytes);
        String hiveType = "";
        if (type == "Panel Serials") hiveType = 'panel';
        if (type == "Inverter Serials") hiveType = 'inverter';
        if (type == "Battery Serials") hiveType = 'battery';
        final data = {
          'type': hiveType,
          'image': base64Image,
          'state': 'draft',
          'worksheet_id': worksheetId,
          'user_id': userId,
          'verification_time':
              DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          'location': locationDetails,
          'latitude': position['latitude'],
          'longitude': position['longitude'],
          'product_id': product.productId,
          'product_qty': product.quantity
        };
        await client!.callKw({
          'model': 'stock.lot',
          'method': 'write',
          'args': [[lotId],data],
          'kwargs': {},
        });
      }
    } catch (e) {}
  }
}

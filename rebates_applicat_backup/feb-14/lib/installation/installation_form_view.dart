import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../barcode/product_view.dart';
import '../navigation_bar/common_navigation_bar.dart';
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
import '../offline_db/installation_list/installing_job.dart';
import '../offline_db/project_ccew_document/project_ccew_document.dart';
import '../offline_db/qr/qr_code.dart';
import '../offline_db/qr/qr_code_visisble.dart';
import '../offline_db/selfies/hive_selfie.dart';
import '../offline_db/selfies/selfie_edit.dart';
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
import '../signature/installer_signature.dart';
import '../signature/owner_signature.dart';
import '../tasktypes/installation_details.dart';
import '../tasktypes/owner_details.dart';
import '../tasktypes/woeksheet_view.dart';
import '../timer_with_lock.dart';
import 'checklist.dart';
import 'package:http/http.dart' as http;

class FormViewScreen extends StatefulWidget {
  @override
  State<FormViewScreen> createState() => _FormViewScreenState();
}

class _FormViewScreenState extends State<FormViewScreen> {
  List<Map<String, dynamic>> attachments_append = [];
  File? imageFile;
  Uint8List? installerSignature;
  MemoryImage? installerSignatureImage;
  MemoryImage? ownerSignatureImage;
  Uint8List? installerSignatureImageBytes;
  Uint8List? ownerSignatureImageBytes;
  Uint8List? ownerSignature;
  String? installerName;
  String? ownerName;
  int? projectId;
  int? worksheetId;
  int? memberId;
  OdooClient? client;
  String url = "";
  String userName = "";
  int? userId;
  List<Map<String, String>> productDetailsList = [];
  MemoryImage? solarProductImage;
  MemoryImage? derRecieptDocumet;
  MemoryImage? ccewDocumet;
  MemoryImage? stcDocumet;
  MemoryImage? solarPanelDocumet;
  MemoryImage? switchBoardDocumet;
  MemoryImage? batteryLocationDocument;
  MemoryImage? inverterLocationDocumet;
  TextEditingController productNameController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  String newProductName = '';
  String quantity = '';
  bool _quantityValidate = false;
  bool _productNameValidate = false;
  List<String> product_items = [];
  List<Map<String, dynamic>> hazard_question_items = [];
  List<int> product_ids = [];
  int productValue = 0;
  String _errorMessage = '';
  bool finishJobStatus = false;
  bool _isfinishLoading = false;
  bool _isEditInfoLoading = false;
  bool progressChange = false;
  bool isLoading = true;

  bool isStartjob = true;
  bool isImageLoading = false;
  List<String> checklistTypes = [];
  DateTime? CheckIncreateTime;
  DateTime? MidcreateTime;
  DateTime? CheckOutcreateTime;
  String CheckInImagePath = "";
  String MidImagePath = "";
  String CheckOutImagePath = "";
  bool CheckinRequired = false;
  bool MidRequired = false;
  bool CheckoutRequired = false;
  List<dynamic> categIdList = [];
  List<dynamic> workTypeIdList = [];
  Duration? checkIndifference;
  Duration? Middifference;
  String premises = '';
  String storeys = '';
  String roof_type = '';
  String wall_type = '';
  String meterBoxPhase = '';
  String serviceType = '';
  String nmi = '';
  String installedOrNot = '';
  String switchBoardUsed = '';
  String expectedInverterLocation = '';
  String mountingWallType = '';
  String inverterLocationNotes = '';
  String expectedBatteryLocation = '';
  String mountingType = '';
  String description = '';
  String witnessName = '';
  List<Map<String, dynamic>> partner_items = [];
  List<Map<String, dynamic>> finalCategoryList = [];
  DateTime? installerDate;
  DateTime? customerDate;
  bool isUploadLoading = false;
  bool _employeeValidate = false;
  int panel_count = 0;
  int inverter_count = 0;
  int battery_count = 0;
  int totalBarcodeCount = 0;
  int scanned_panel_count = 0;
  int scanned_inverter_count = 0;
  int scanned_battery_count = 0;
  int checklist_total_count = 0;
  int checklistCurrentCount = 0;
  int scannedTotalCount = 0;
  final List<int> existingIds = [];
  late Timer _timer;
  int _counter = 0;
  ValueNotifier<DateTime> nowDateTimeNotifier =
      ValueNotifier(DateTime.now().toUtc());
  int employeeValue = 0;
  List<int> employee_ids = [];
  List<String> employee_items = [];
  Uint8List? generatedQrCode;
  String status_done = "";
  bool isNetworkAvailable = false;
  bool isQrVisible = false;
  List<Map<String, dynamic>> riskWorkItemsWithIds = [
    {"id": 1, "item": "Tower crane", "type": "cranes"},
    {"id": 2, "item": "Self-erecting tower crane", "type": "cranes"},
    {"id": 3, "item": "Derrick crane", "type": "cranes"},
    {"id": 4, "item": "Portal boom crane", "type": "cranes"},
    {"id": 5, "item": "Bridge and gantry crane", "type": "cranes"},
    {"id": 6, "item": "Vehicle loading crane", "type": "cranes"},
    {"id": 7, "item": "Non-slewing mobile crane", "type": "cranes"},
    {
      "id": 8,
      "item": "Slewing mobile crane – with a capacity up to 20 tonnes",
      "type": "cranes"
    },
    {
      "id": 9,
      "item": "Slewing mobile crane – with a capacity of up to 60 tonnes",
      "type": "cranes"
    },
    {
      "id": 10,
      "item": "Slewing mobile crane – with a capacity of up to 100 tonnes",
      "type": "cranes"
    },
    {
      "id": 11,
      "item": "Slewing mobile crane – with a capacity of over 100 tonnes",
      "type": "cranes"
    },
    {"id": 12, "item": "Materials hoist", "type": "hoists"},
    {"id": 13, "item": "Personnel and materials hoist", "type": "hoists"},
    {"id": 14, "item": "Boom-type elevating work platform", "type": "hoists"},
    {"id": 15, "item": "Concrete placing boom", "type": "hoists"},
    {"id": 16, "item": "Basic scaffolding", "type": "scaffolding"},
    {"id": 17, "item": "Intermediate scaffolding", "type": "scaffolding"},
    {"id": 18, "item": "Advanced scaffolding", "type": "scaffolding"},
    {"id": 19, "item": "Basic scaffolding", "type": "dogging_rigging"},
    {"id": 20, "item": "Intermediate scaffolding", "type": "dogging_rigging"},
    {"id": 21, "item": "Advanced scaffolding", "type": "dogging_rigging"},
    {"id": 22, "item": "Forklift", "type": "forklift"}
  ];
  List<String> allowedTypes = [
    "cranes",
    "hoists",
    "scaffolding",
    "forklift",
    "dogging_rigging"
  ];
  List<String> allowedRiskTypes = [
    "Hi-Vis",
    "Steel cap boots",
    "Gloves",
    "Eye protection",
    "Hearing protection",
    "Hard Hat",
    "Respirator",
    "Long Sleeve & Trousers"
  ];
  List<int> selectedIds = [];
  List<int> team_member_ids = [];
  Map<int, String> hazardResponses = {};
  List<Map<String, dynamic>> selectedDetails = [];
  bool success = false;
  String _errorOverviewMessage = "";
  List<Map<String, dynamic>> swmsDetails = [];
  Map<String, bool> selectedCheckboxes = {};
  Map<String, bool> selectedRiskItemCheckboxes = {};
  Map<String, String?> dropdownValues = {};
  Map<String, String?> dropdownRiskItemsValues = {};
  Map<String, String> specificTaskDetails = {};
  List<ChecklistItem> checklistItems = [];
  bool isSubmitLoading = false;
  Map<String, dynamic>? globalArgs;
  bool isAdmin = false;
  bool isSiteDetails = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkConnectivity();
    WidgetsBinding.instance!.addPostFrameCallback((_) async {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      globalArgs = args;
      if (args.containsKey('isQrVisible')) {
        isQrVisible = args['isQrVisible'];
        var addbox = await Hive.openBox<QrCodeVisible>(
            'qrVisible_${args['worksheetId']}');

        final qr =
            QrCodeVisible(worksheetId: args['worksheetId'], isQrVisible: true);
        await addbox.add(qr);
        print(addbox);
        print(
            "gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg");
        // await box.close();
      }

      var visiblebox =
          await Hive.openBox<QrCodeVisible>('qrVisible_${args['worksheetId']}');
      print(visiblebox);
      print("visibleboxvisibleboxvisiblebox");
      if (visiblebox.isNotEmpty) {
        print("heeyyyyyyyyyyy");
        isQrVisible = true;
      }
      print(isQrVisible);
      print("isQrVisibleisQrVisibleisQrVisible${args['team_member_ids']}");
      // progressChange = args['progressChange'];
      projectId = args['job_id'];
      status_done = args['install_status'];
      worksheetId = args['worksheetId'];
      memberId = args['memberId'];
      print(worksheetId);
      print(memberId);
      print("memberIdmemberIdmemberIdmemberIdmemberIddddddddddddddd");
      team_member_ids = List<int>.from(args['team_member_ids'] ?? []);
      final box = await Hive.openBox<TaskJob>('taskJobsBox');
      print(projectId);
      print(box.values);
      print("projectIdprojectIdprojectId");
      // if (!isNetworkAvailable) {
      // final taskJob = box.values.cast<TaskJob?>().firstWhere(
      //       (task) => task?.taskId == projectId,
      //       orElse: () => null,
      //     );
      // print(taskJob);
      // print("taskJobtaskJobtaskJobtaskJob");
      // if (taskJob != null) {
      //   progressChange = false;
      // }
      // }
      // await box.close();
      // await _initializeOdooClient();
      final worksheetbox = await Hive.openBox<Worksheet>('worksheets');

      Worksheet? worksheet = worksheetbox.get(worksheetId);

      if (worksheet != null) {
        totalBarcodeCount = (worksheet.panelCount ?? 0) +
            (worksheet.inverterCount ?? 0) +
            (worksheet.batteryCount ?? 0);

        scannedTotalCount = (worksheet.scannedPanelCount ?? 0) +
            (worksheet.scannedInverterCount ?? 0) +
            (worksheet.scannedBatteryCount ?? 0);

        checklist_total_count = worksheet.checklistCount ?? 0;
      } else {
        print("Worksheet not found for ID: $worksheetId");
      }
      getOwnerDetails();
      getProductDetails().then((_) {

        getProducts();
        // getHazardQuestions();
        getChecklist();
        getChecklistWithoutSelfies();
        _getSelfies();
        getCCEWDocuments();
        getDocuments();
        getInstallerSignatureDetails();
        getOwnerSignatureDetails();
        getOtherDocuments();
        // getEmployees();
        setState(() {
          isLoading = false;
        });
      });
      print("44444444444444444444444444ccccccccccccccccccccccccc");
      progressChange = args['progressChange'];
      final taskJob = box.values.cast<TaskJob?>().firstWhere(
            (task) => task?.taskId == projectId,
            orElse: () => null,
          );
      print(taskJob);
      print("taskJobtaskJobtaskJobtaskJob");
      if (taskJob != null) {
        progressChange = false;
        isStartjob = true;
        isQrVisible = true;
      }
      await box.close();
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      nowDateTimeNotifier.value = DateTime.now().toUtc();
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
        getProductDetails().then((_) {
          getInstallerSignatureDetails();
          getOwnerSignatureDetails();
          getOtherDocuments();
          setState(() {
            isLoading = false;
          });
        });
      }
    });
  }

  Future<void> reloadScanningCount() async {
    print("rddddddddddddddddddddddddd");

    // final args = ModalRoute.of(context)!.settings.arguments as Map;
    // worksheetId = args['worksheetId'];
    final prefs = await SharedPreferences.getInstance();
    final teamId = prefs.getInt('teamId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    print(
        "$worksheetId/fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffssssssssssssssss");
    // final lotData = await client?.callKw({
    //   'model': 'stock.lot',
    //   'method': 'search_read',
    //   'args': [
    //     [
    //       ['worksheet_id', '=', worksheetId],
    //       ['user_id', '=', userId],
    //     ],
    //   ],
    //   'kwargs': {
    //     'fields': ['type'],
    //   },
    // });
    // print("lllllllllllllllllll$lotData");
    // if (lotData != null && lotData.isNotEmpty) {
    final Uri url = Uri.parse('$baseUrl/rebates/stock_lot');
    final scanningProducts = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
          "worksheet": worksheetId,
          "teamId": teamId
        }
      }),
    );
    print(scanningProducts.body);
    print("fffffffffffffffffssssssssssssssssssffffccccccfffffmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm");
    final Map<String, dynamic> jsonScanningProductsResponse = json.decode(scanningProducts.body);
    print("3333333333333333333333$jsonScanningProductsResponse");
    if (jsonScanningProductsResponse['result']['status'] == 'success' && jsonScanningProductsResponse['result']['stock_lot'].isNotEmpty) {
      int panelCount = 0;
      int inverterCount = 0;
      int batteryCount = 0;

      for (var lot in jsonScanningProductsResponse['result']['stock_lot']) {
        switch (lot['type']) {
          case 'panel':
            panelCount++;
            break;
          case 'inverter':
            inverterCount++;
            break;
          case 'battery':
            batteryCount++;
            break;
          default:
            break;
        }
      }
      setState(() {
        scanned_panel_count = panelCount;
        scanned_inverter_count = inverterCount;
        scanned_battery_count = batteryCount;
        scannedTotalCount = (panelCount + inverterCount + batteryCount);
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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

  void loadDocumentsFromHive() async {
    final box = await Hive.openBox<ProjectDocuments>('projectDocumentsBox');
    final projectDocuments = box.get(projectId);

    if (projectDocuments != null) {
      setState(() {
        derRecieptDocumet = projectDocuments.derReceipt != null
            ? MemoryImage(projectDocuments.derReceipt!)
            : null;
        ccewDocumet = projectDocuments.ccewDoc != null
            ? MemoryImage(projectDocuments.ccewDoc!)
            : null;
        stcDocumet = projectDocuments.stcDoc != null
            ? MemoryImage(projectDocuments.stcDoc!)
            : null;
        solarPanelDocumet = projectDocuments.solarPanelDoc != null
            ? MemoryImage(projectDocuments.solarPanelDoc!)
            : null;
        switchBoardDocumet = projectDocuments.switchBoardDoc != null
            ? MemoryImage(projectDocuments.switchBoardDoc!)
            : null;
        inverterLocationDocumet = projectDocuments.inverterLocationDoc != null
            ? MemoryImage(projectDocuments.inverterLocationDoc!)
            : null;
        batteryLocationDocument = projectDocuments.batteryLocationDoc != null
            ? MemoryImage(projectDocuments.batteryLocationDoc!)
            : null;
      });
    }
    await box.close();
  }

  void loadCCEWDocumentsFromHive() async {
    final box =
        await Hive.openBox<ProjectCCEWDocument>('projectCCEWDocumentsBox');
    final ccewDocument = box.get(projectId);

    if (ccewDocument != null) {
      setState(() {
        ccewDocumet = ccewDocument.documentData != null
            ? ccewDocument.documentData
            : null;
      });
    }
    await box.close();
  }

  Future<void> getCCEWDocuments() async {
    if (!isNetworkAvailable) {
      loadCCEWDocumentsFromHive();
      return;
    } else {
      await createCCEW(worksheetId!);
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;
      final baseUrl = prefs.getString('url') ?? 0;
      try {
        print("dddddhjvhjvvvvvvvv");
        // final documentsFromProject = await client?.callKw({
        //   'model': 'task.worksheet',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       ['id', '=', worksheetId]
        //     ]
        //   ],
        //   'kwargs': {
        //     'fields': ['ccew_file'],
        //   },
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/task_worksheet');
        final documentsFromProject = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "worksheet_id": worksheetId,
            }
          }),
        );
        print(documentsFromProject);
        print("fffffffffffffffffffffddddddddddddd");
        final Map<String, dynamic> jsonWorksheetResponse = json.decode(documentsFromProject.body);
        print("3333333333333333333333$jsonWorksheetResponse");
        // if (documentsFromProject != null && documentsFromProject.isNotEmpty) {
        if (jsonWorksheetResponse['result']['status'] == 'success' && jsonWorksheetResponse['result']['worksheet_data'].isNotEmpty) {
          final ccewDoc = jsonWorksheetResponse['result']['worksheet_data'][0]['ccew_file'];
          print(ccewDoc);
          print("ccewDocccewDocccewDocssssssssssssssssssss");
          if (ccewDoc is String) {
            final ccewBase64 = ccewDoc as String;
            if (ccewBase64.isNotEmpty) {
              final ccewData = base64Decode(ccewBase64);
              setState(() {
                ccewDocumet = MemoryImage(Uint8List.fromList(ccewData));
              });
            }
          }
          print(ccewDocumet);
          print("ccewDocumetccewDocumetssssssssssssssssss");
        }
        await saveCCEWDocumentsToHive();
      } catch (e) {
        print("44444444444444444cccccccc444444444444$e");
        loadCCEWDocumentsFromHive();
        return;
      }
    }
  }

  Future<void> getDocuments() async {
    if (!isNetworkAvailable) {
      loadDocumentsFromHive();
      return;
    } else {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;
      final teamId = prefs.getInt('teamId') ?? 0;
      final baseUrl = prefs.getString('url') ?? 0;
      try {
        // final documentsFromProject = await client?.callKw({
        //   'model': 'project.task',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       // ['x_studio_proposed_team', '=', userId],
        //       ['id', '=', projectId],
        //       ['worksheet_id', '!=', false],
        //       ['team_lead_user_id', '=', userId],
        //     ]
        //   ],
        //   'kwargs': {
        //     'fields': [
        //       'x_studio_der_receipt',
        //       'x_studio_ccew',
        //       'x_studio_stc',
        //       'x_studio_solar_panel_layout',
        //       'x_studio_switch_board_photo',
        //       'x_studio_inverter_location_1',
        //       'x_studio_battery_location',
        //     ],
        //   },
        // });
        print("444444dddddddddddddddddddddddffffff4444444444");
        final Uri url = Uri.parse('$baseUrl/rebates/project_task');
        final documentsFromProject = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "team_id": teamId,
              "id": projectId

            }
          }),
        );
        final Map<String, dynamic> jsonDocumentsFromProjectResponse = json.decode(documentsFromProject.body);
        print("jsonDocumentsFromProjectResponsejsonDocumentsFromProjectResponse$jsonDocumentsFromProjectResponse");
        // if (documentsFromProject != null && documentsFromProject.isNotEmpty) {
        if (jsonDocumentsFromProjectResponse['result']['status'] == 'success' &&
            jsonDocumentsFromProjectResponse['result']['tasks'].isNotEmpty) {
          final derReceipt = jsonDocumentsFromProjectResponse['result']['tasks'][0]['x_studio_der_receipt'];
          final ccewDoc = jsonDocumentsFromProjectResponse['result']['tasks'][0]['x_studio_ccew'];
          final stcDoc = jsonDocumentsFromProjectResponse['result']['tasks'][0]['x_studio_stc'];
          final solarPanelDoc =
          jsonDocumentsFromProjectResponse['result']['tasks'][0]['x_studio_solar_panel_layout'];
          final switchBoardDoc =
          jsonDocumentsFromProjectResponse['result']['tasks'][0]['x_studio_switch_board_photo'];
          final inverterLocationDoc =
          jsonDocumentsFromProjectResponse['result']['tasks'][0]['x_studio_inverter_location_1'];
          final batteryLocationDoc =
          jsonDocumentsFromProjectResponse['result']['tasks'][0]['x_studio_battery_location'];
          if (derReceipt is String) {
            final derBase64 = derReceipt as String;
            if (derBase64.isNotEmpty) {
              final derData = base64Decode(derBase64);
              setState(() {
                derRecieptDocumet = MemoryImage(Uint8List.fromList(derData));
              });
            }
          }
          print(derRecieptDocumet);
          print(ccewDoc);
          print("x_studio_ccewx_studio_ccewx_studio_ccew");
          if (ccewDoc is String) {
            final ccewBase64 = ccewDoc as String;
            if (ccewBase64.isNotEmpty) {
              final ccewData = base64Decode(ccewBase64);
              setState(() {
                ccewDocumet = MemoryImage(Uint8List.fromList(ccewData));
              });
            }
          }
          if (stcDoc is String) {
            final stcBase64 = stcDoc as String;
            if (stcBase64.isNotEmpty) {
              final stcData = base64Decode(stcBase64);
              setState(() {
                stcDocumet = MemoryImage(Uint8List.fromList(stcData));
              });
            }
          }
          if (solarPanelDoc is String) {
            final solarPanelBase64 = solarPanelDoc as String;
            if (solarPanelBase64.isNotEmpty) {
              final solarPanelData = base64Decode(solarPanelBase64);
              setState(() {
                solarPanelDocumet =
                    MemoryImage(Uint8List.fromList(solarPanelData));
              });
            }
          }
          if (switchBoardDoc is String) {
            final switchBoardBase64 = switchBoardDoc as String;
            if (switchBoardBase64.isNotEmpty) {
              final switchBoardData = base64Decode(switchBoardBase64);
              setState(() {
                switchBoardDocumet =
                    MemoryImage(Uint8List.fromList(switchBoardData));
              });
            }
          }
          if (inverterLocationDoc is String) {
            final inverterLocationBase64 = inverterLocationDoc as String;
            if (inverterLocationBase64.isNotEmpty) {
              final inverterLocationData = base64Decode(inverterLocationBase64);
              setState(() {
                inverterLocationDocumet =
                    MemoryImage(Uint8List.fromList(inverterLocationData));
              });
            }
          }
          if (batteryLocationDoc is String) {
            final batteryLocationBase64 = batteryLocationDoc as String;
            if (batteryLocationBase64.isNotEmpty) {
              final batteryLocationData = base64Decode(batteryLocationBase64);
              setState(() {
                batteryLocationDocument =
                    MemoryImage(Uint8List.fromList(batteryLocationData));
              });
            }
          }
        }
        await saveDocumentsToHive();
      } catch (e) {
        loadDocumentsFromHive();
        return;
      }
    }
  }

  Future<void> saveDocumentsToHive() async {
    final box =
        await Hive.openBox<ProjectDocuments>('projectDocumentsBox_$projectId');

    final projectDocuments = ProjectDocuments(
      derReceipt: derRecieptDocumet?.bytes,
      ccewDoc: ccewDocumet?.bytes,
      stcDoc: stcDocumet?.bytes,
      solarPanelDoc: solarPanelDocumet?.bytes,
      switchBoardDoc: switchBoardDocumet?.bytes,
      inverterLocationDoc: inverterLocationDocumet?.bytes,
      batteryLocationDoc: batteryLocationDocument?.bytes,
    );

    await box.put('projectDocuments', projectDocuments);
    await box.close();
  }

  Future<void> saveCCEWDocumentsToHive() async {
    try {
      final box =
          await Hive.openBox<ProjectCCEWDocument>('projectCCEWDocumentsBox');

      final ccewDocument = ProjectCCEWDocument(
        documentData: ccewDocumet,
      );

      await box.put(projectId, ccewDocument);
      print('Document saved successfully to Hive for project $projectId');

      await box.close();
    } catch (e) {
      print("Error saving CCEW document to Hive: $e");
    }
  }

  Future<void> loadProductDetailsFromHive() async {
    try {
      var box = await Hive.openBox<List<dynamic>>('productDetailsBox');
      List<dynamic>? rawProductList = box.get(projectId);
      print(rawProductList);
      print("rawProductListrawProductList");
      if (rawProductList != null) {
        List<ProductDetail> productList =
            rawProductList.map((item) => item as ProductDetail).toList();

        setState(() {
          productDetailsList = productList
              .map((product) => {
                    'id': product.id,
                    'quantity': product.quantity,
                    'model': product.model,
                    'manufacturer': product.manufacturer,
                    'image': product.image,
                    'state': product.state,
                  })
              .toList();
          finalCategoryList.clear();
        });
      } else {}
    } catch (e) {}
  }

  Future<void> loadWorksheetDocumentFromHive() async {
    try {
      final box = await Hive.openBox<WorksheetDocument>('worksheetDocumentBox');
      WorksheetDocument? productInfo = box.get(projectId);

      if (productInfo != null) {
        premises = productInfo.premises!;
        storeys = productInfo.storeys!;
        wall_type = productInfo.wallType!;
        roof_type = productInfo.roofType!;
        meterBoxPhase = productInfo.meterBoxPhase!;
        serviceType = productInfo.serviceType!;
        nmi = productInfo.nmi!;
        expectedInverterLocation = productInfo.expectedInverterLocation!;
        mountingWallType = productInfo.mountingWallType!;
        inverterLocationNotes = productInfo.inverterLocationNotes!;
        expectedBatteryLocation = productInfo.expectedBatteryLocation!;
        mountingType = productInfo.mountingType!;
        switchBoardUsed = productInfo.switchBoardUsed!;
        installedOrNot = productInfo.installedOrNot!;
        description = productInfo.description!;

        debugPrint('Worksheet document loaded successfully.');
      } else {
        debugPrint('No worksheet document found for projectId: $projectId');
      }
    } catch (e) {
      debugPrint('Error loading product info from Hive: $e');
    }
  }

  Future<void> loadProductCategoriesFromHive() async {
    final box = await Hive.openBox<Worksheet>('worksheets');

    final worksheet = box.get(worksheetId);

    if (worksheet != null) {
      panel_count = worksheet.panelCount ?? 0;
      inverter_count = worksheet.inverterCount ?? 0;
      battery_count = worksheet.batteryCount ?? 0;
      scanned_panel_count = worksheet.scannedPanelCount ?? 0;
      scanned_inverter_count = worksheet.scannedInverterCount ?? 0;
      scanned_battery_count = worksheet.scannedBatteryCount ?? 0;

      print(worksheet.scannedPanelCount);
      print("panel_countpanel_countpanel_count");
    } else {
      print("Worksheet with ID $worksheetId not found.");
    }
  }

  Future<void> loadfinalCategList() async {
    try {
      final box = await Hive.openBox<List<dynamic>>('categories');
      final rawCategories = box.get(projectId) ?? [];
      print(rawCategories);
      finalCategoryList = rawCategories
          .map((category) => (category as Category).toMap())
          .toList();
    } catch (e) {
      finalCategoryList = [];
    }
  }

  // Future<void> loadCategIdList() async {
  //   try {
  //     final box = await Hive.openBox<List<CategoryDetail>>(
  //         'categoriesIdList_$projectId');
  //     print("333333333333333333333");
  //     print(box);
  //     print(box.get(projectId));
  //     print("gfffffffffffhsssssssssss");
  //     final categoriesList = box.get(projectId) ?? [];
  //     categIdList = categoriesList.map((category) => category.id).toList();
  //     categIdList = categIdList.toSet().toList();
  //     print(categIdList);
  //     print("categIdListcategIdListfffffffffffffffffffffcategIdList");
  //   } catch (e) {
  //     categIdList = [];
  //   }
  // }

  Future<void> loadCategIdList() async {
    Box<List<dynamic>>? box;

    try {
      box = await Hive.openBox<List<dynamic>>('categoriesIdList_$projectId');
      print("333333333333333333333");
      print(box);
      print(box.get(projectId));
      print("gfffffffffffhsssssssssss");

      final categoriesList =
          (box.get(projectId) as List<dynamic>?)?.cast<CategoryDetail>() ?? [];

      categIdList = categoriesList.map((category) => category.id).toList();
      categIdList = categIdList.toSet().toList();

      print(categIdList);
      print("categIdListcategIdListfffffffffffffffffffffcategIdList");
    } catch (e) {
      categIdList = [];
      print("Error while loading categories list: $e");
    } finally {
      // Close the Hive box if it's open
      if (box != null && box.isOpen) {
        await box.close();
        print('categoriesIdList_$projectId box closed successfully.');
      }
    }
  }

  Future<void> getProductDetails() async {
    if (!isNetworkAvailable) {
      loadProductDetailsFromHive();
      loadProductCategoriesFromHive();
      loadfinalCategList();
      loadCategIdList();
      loadWorksheetDocumentFromHive();
      return;
    } else {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;
      final baseUrl = prefs.getString('url') ?? 0;
      final teamId = prefs.getInt('teamId') ?? 0;
      print("ooooooooooooooooooooooooooojhgfd");
      try {
        // final productFromProject = await client?.callKw({
        //   'model': 'project.task',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       // ['x_studio_proposed_team', '=', userId],
        //       ['id', '=', projectId],
        //       ['worksheet_id', '!=', false],
        //       ['team_lead_user_id', '=', userId],
        //     ]
        //   ],
        //   'kwargs': {
        //     'fields': [
        //       'x_studio_product_list',
        //       'install_signed_by',
        //       'install_signature',
        //       'x_studio_3_type_of_premises',
        //       'x_studio_type_of_service',
        //       'description',
        //       'x_studio_customer_notes',
        //       'x_studio_nmi',
        //       'x_studio_how_many_storeys',
        //       'x_studio_exterior_wall_type',
        //       'x_studio_roof_type',
        //       'x_studio_meter_box_phase',
        //       'x_studio_has_existing_system_installed_1',
        //       'x_studio_switch_board_used_1',
        //       'x_studio_expected_inverter_location_inverter',
        //       'x_studio_inverter_mounting_wall_type',
        //       'x_studio_inverter_location_notes_1',
        //       'x_studio_expected_battery_location_1',
        //       'x_studio_mounting_type_1',
        //     ],
        //   },
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/project_task');
        final productFromProject = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "team_id": teamId,
              "id": projectId

            }
          }),
        );
        final Map<String, dynamic> jsonProductFromProjectResponse = json.decode(productFromProject.body);
        print(productFromProject);
        print("ooooooooooooo");
        // if (productFromProject != null && productFromProject.isNotEmpty) {
        if (jsonProductFromProjectResponse['result']['status'] == 'success' &&
            jsonProductFromProjectResponse['result']['tasks'].isNotEmpty) {
          print("o$productFromProject/oooooooooohhhoooooooooooooooojhgfd");
          // final worksheet = await client?.callKw({
          //   'model': 'task.worksheet',
          //   'method': 'search_read',
          //   'args': [
          //     [
          //       ['task_id', '=', productFromProject[0]['id']],
          //     ],
          //   ],
          //   'kwargs': {
          //     'fields': [
          //       'panel_count',
          //       'inverter_count',
          //       'battery_count',
          //       'checklist_count',
          //       'work_type_ids'
          //     ],
          //   },
          // });
          final Uri url = Uri.parse('$baseUrl/rebates/task_worksheet');
          final worksheet = await http.post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "jsonrpc": "2.0",
              "method": "call",
              "params": {
                "task_id": jsonProductFromProjectResponse['result']['tasks'][0]['id'],
              }
            }),
          );
          final Map<String, dynamic> jsonWorksheetResponse = json.decode(worksheet.body);
          List<dynamic>? checklist;
          if (jsonWorksheetResponse['result']['status'] == 'success' && jsonWorksheetResponse['result']['worksheet_data'].isNotEmpty) {
            workTypeIdList = jsonWorksheetResponse['result']['worksheet_data'][0]['work_type_ids'];
            print(workTypeIdList);
            print("workTypeIdListworkTypeIdListworkTypeIdList");
            // checklist = await client?.callKw({
            //   'model': 'installation.checklist.item',
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
            final Uri url = Uri.parse('$baseUrl/rebates/installation_checklist_item');
            final checklist = await http.post(
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
            panel_count = jsonWorksheetResponse['result']['worksheet_data'][0]['panel_count'];
            inverter_count = jsonWorksheetResponse['result']['worksheet_data'][0]['inverter_count'];
            battery_count = jsonWorksheetResponse['result']['worksheet_data'][0]['battery_count'];
            checklistCurrentCount = jsonWorksheetResponse['result']['worksheet_data'].length ?? 0;
            checklist_total_count = jsonWorksheetResponse['result']['worksheet_data'][0]['checklist_count'];
            totalBarcodeCount = (jsonWorksheetResponse['result']['worksheet_data'][0]['panel_count'] ?? 0) +
                (jsonWorksheetResponse['result']['worksheet_data'][0]['inverter_count'] ?? 0) +
                (jsonWorksheetResponse['result']['worksheet_data'][0]['battery_count'] ?? 0);
            // final lotData = await client?.callKw({
            //   'model': 'stock.lot',
            //   'method': 'search_read',
            //   'args': [
            //     [
            //       ['worksheet_id', '=', worksheet[0]['id']],
            //       ['user_id', '=', userId],
            //     ],
            //   ],
            //   'kwargs': {
            //     'fields': ['type'],
            //   },
            // });
            final Uri lotUrl = Uri.parse('$baseUrl/rebates/stock_lot');
            final lotData = await http.post(
              lotUrl,
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
            final Map<String, dynamic> jsonLotDataResponse = json.decode(lotData.body);
            // if (lotData != null && lotData.isNotEmpty) {
            if (jsonLotDataResponse['result']['status'] == 'success' && jsonLotDataResponse['result']['stock_lot'].isNotEmpty) {
              int panelCount = 0;
              int inverterCount = 0;
              int batteryCount = 0;

              for (var lot in jsonLotDataResponse['result']['stock_lot']) {
                switch (lot['type']) {
                  case 'panel':
                    panelCount++;
                    break;
                  case 'inverter':
                    inverterCount++;
                    break;
                  case 'battery':
                    batteryCount++;
                    break;
                  default:
                    break;
                }
              }
              scanned_panel_count = panelCount;
              scanned_inverter_count = inverterCount;
              scanned_battery_count = batteryCount;
              scannedTotalCount = (panelCount + inverterCount + batteryCount);
            }

            if (worksheetId != null) {
              Worksheet newWorksheet = Worksheet(
                  id: worksheetId!,
                  panelCount: panel_count,
                  inverterCount: inverter_count,
                  batteryCount: battery_count,
                  checklistCount: checklist_total_count,
                  scannedPanelCount: scanned_panel_count,
                  scannedInverterCount: scanned_inverter_count,
                  scannedBatteryCount: scanned_battery_count,
                  checklistCurrentCount: checklistCurrentCount);

              final box = await Hive.openBox<Worksheet>('worksheets');
              await box.put(newWorksheet.id, newWorksheet);
            }
          }
        }

        if (jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_3_type_of_premises'] is String) {
          premises = jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_3_type_of_premises'];
        }

        if (jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_how_many_storeys'] is String) {
          storeys = jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_how_many_storeys'];
        }

        if (jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_exterior_wall_type'] is String) {
          wall_type = jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_exterior_wall_type'];
        }

        if (jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_roof_type'] is String) {
          roof_type = jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_roof_type'];
        }

        if (jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_meter_box_phase'] is String) {
          meterBoxPhase = jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_meter_box_phase'];
        }

        if (jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_type_of_service'] is String) {
          serviceType = jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_type_of_service'];
        }

        if (jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_nmi'] is String) {
          nmi = jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_nmi'];
        }

        if (jsonProductFromProjectResponse['result']['tasks'][0]
            ['x_studio_expected_inverter_location_inverter'] is String) {
          expectedInverterLocation = jsonProductFromProjectResponse['result']['tasks'][0]
              ['x_studio_expected_inverter_location_inverter'];
        }

        if (jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_inverter_mounting_wall_type']
            is String) {
          mountingWallType =
          jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_inverter_mounting_wall_type'];
        }

        if (jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_inverter_location_notes_1']
            is String) {
          inverterLocationNotes =
          jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_inverter_location_notes_1'];
        }

        if (jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_expected_battery_location_1']
            is String) {
          expectedBatteryLocation =
          jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_expected_battery_location_1'];
        }

        if (jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_mounting_type_1'] is String) {
          mountingType = jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_mounting_type_1'];
        }

        if (jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_switch_board_used_1'] is String) {
          switchBoardUsed =
          jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_switch_board_used_1'];
        }

        if (jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_has_existing_system_installed_1']
            is String) {
          installedOrNot =
          jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_has_existing_system_installed_1'];
        }

        // if (productFromProject[0]['description'] is String) {
        //   description = productFromProject[0]['description']
        //       .replaceAll('<p>', '')
        //       .replaceAll('</p>', '')
        //       .replaceAll('<br>', '')
        //       .replaceAll('&amp;', '&');
        // }

        if (jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_customer_notes'] is String) {
          description = jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_customer_notes']
              .replaceAll('<p>', '')
              .replaceAll('</p>', '')
              .replaceAll('<br>', '')
              .replaceAll('&amp;', '&');
        }

        setState(() {
          isSiteDetails = true;
        });
        print("gfffffffffffffffff44444444444444");
        saveWorksheetDocumentsToHive();
        // if (productFromProject != null && productFromProject.isNotEmpty) {
        if (jsonProductFromProjectResponse['result']['status'] == 'success' && jsonProductFromProjectResponse['result']['tasks'].isNotEmpty) {
          if (jsonProductFromProjectResponse['result']['tasks'][0] is Map) {
            print("orderLineddddddddddddddddddd");
            final orderLine = jsonProductFromProjectResponse['result']['tasks'][0]['x_studio_product_list'];
            print(orderLine);
            print("orderLineorderLineorderLine");
            if (orderLine != null) {
              productDetailsList = [];
              for (var order in orderLine) {
                print("------------------------------$order");
                // final productDetails = await client?.callKw({
                //   'model': 'sale.order.line',
                //   'method': 'search_read',
                //   'args': [
                //     [
                //       ['id', '=', order],
                //     ]
                //   ],
                //   'kwargs': {
                //     'fields': [
                //       'product_id',
                //       'product_uom_qty',
                //       'name',
                //       'state'
                //     ],
                //   },
                // });
                final Uri url = Uri.parse('$baseUrl/rebates/order_line');
                final productDetails = await http.post(
                  url,
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "jsonrpc": "2.0",
                    "method": "call",
                    "params": {
                      "order": order,
                    }
                  }),
                );
                print("------------------------------$productDetails");
                final Map<String, dynamic> jsonProductDetailsResponse = json.decode(productDetails.body);
                print(jsonProductDetailsResponse);
                print("444444444444444444eeeeeeeeeeeee");
                var productIdData = jsonProductDetailsResponse['result']['order_line'][0]['product_id'];
                if (productIdData is List && productIdData.isNotEmpty) {
                  final productId = jsonProductDetailsResponse['result']['order_line'][0]['product_id'][0];
                  print(productId);
                  print("dddddddddddddddddddddddddddfffffffffffffffff");
                  // final productImage = await client?.callKw({
                  //   'model': 'product.product',
                  //   'method': 'search_read',
                  //   'args': [
                  //     [
                  //       ['id', '=', productId],
                  //     ]
                  //   ],
                  //   'kwargs': {
                  //     'fields': ['type', 'image_1920', 'name', 'categ_id'],
                  //   },
                  // });
                  final Uri url = Uri.parse('$baseUrl/rebates/product');
                  final productImage = await http.post(
                    url,
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode({
                      "jsonrpc": "2.0",
                      "method": "call",
                      "params": {
                        "productId": productId,
                        // "CategoryType": ['Inverters', 'Solar Panels', 'Storage']
                      }
                    }),
                  );
                  print("productImageproductImageproductImage$productImage");
                  final Map<String, dynamic> jsonProductImageResponse = json.decode(productImage.body);
                  print(jsonProductImageResponse);
                  // final productSerial = await client?.callKw({
                  //   'model': 'stock.lot',
                  //   'method': 'search_read',
                  //   'args': [
                  //     [
                  //       ['product_id', '=', productId],
                  //     ]
                  //   ],
                  //   'kwargs': {
                  //     'fields': ['name'],
                  //   },
                  // });
                  //
                  // print('productSerial  :  $productSerial');

                  // try {
                    // final productSerial = await client?.callKw({
                    //   'model': 'stock.lot',
                    //   'method': 'search_read',
                    //   'args': [
                    //     [
                    //       ['product_id', '=', productId],
                    //     ]
                    //   ],
                    //   'kwargs': {
                    //     'fields': ['name'],
                    //   },
                    // });


                    // final Uri url = Uri.parse('$baseUrl/rebates/stock_lot');
                    // final productSerial = await http.post(
                    //   url,
                    //   headers: {"Content-Type": "application/json"},
                    //   body: jsonEncode({
                    //     "jsonrpc": "2.0",
                    //     "method": "call",
                    //     "params": {
                    //       "productId": productId,
                    //       "worksheet": worksheetId
                    //     }
                    //   }),
                    // );
                    // print('productSerial  :  $productSerial');
                    // final Map<String, dynamic> jsonProductSerialResponse = json.decode(productSerial.body);
                    // print("jsonProductSerialResponsejsonProductSerialResponse$jsonProductSerialResponse");
                  if (jsonProductImageResponse['result']['status'] == 'success' && jsonProductImageResponse['result']['product_data'].isNotEmpty) {
                    var productIdData = jsonProductDetailsResponse['result']['order_line'][0]['product_id'];
                    if (productIdData is List && productIdData.isNotEmpty) {
                      // String productName = productIdData.length > 1
                      //     ? jsonProductImageResponse['result']['product_data'][0]['name']
                      // // productIdData[1].toString()
                      //     : 'Unknown Product';
                      final base64Image;
                      if (solarProductImage != null) {
                        final bytes = solarProductImage!.bytes;
                        base64Image = base64Encode(bytes);
                      } else {
                        base64Image = 'null';
                      }
                      // String productType =
                      //     jsonProductImageResponse['result']['product_data'][0]['type'] ??
                      //         'Unknown Type';
                      List<dynamic> filteredProducts = jsonProductImageResponse['result']['product_data']
                          .where((product) =>
                      product['categ_id'] is List &&
                          product['categ_id'].length > 1 &&
                          product['parent_id'] is List &&
                          product['parent_id'].length > 1 &&
                          (['Inverters', 'Solar Panels', 'Storage'].contains(product['categ_id'][1]) ||
                              ['Inverters', 'Solar Panels', 'Storage'].contains(product['parent_id'][1])))
                          .toList();

                      print('Filtered Products: $filteredProducts');
                      print(filteredProducts);
                      print("filteredProducts");
                      print("filteredProductsdddddd");
                      if (filteredProducts.isNotEmpty) {
                        String productName = filteredProducts[0]['name'] ?? 'Unknown Product';
                        String productType = filteredProducts[0]['type'] ?? 'Unknown Type';
                      // if (productSerial.isNotEmpty) {
                      // if (jsonProductSerialResponse['result']['status'] == 'success' && jsonProductSerialResponse.isNotEmpty) {
                      //   setState(() {
                      //     productDetailsList.add({
                      //       'id': jsonProductDetailsResponse['result']['order_line'][0]['id'].toString(),
                      //       'quantity':
                      //       jsonProductDetailsResponse['result']['order_line'][0]['product_uom_qty'].toString(),
                      //       'type': productType,
                      //       'model': productName,
                      //       'manufacturer': jsonProductDetailsResponse['result']['order_line'][0]['name'],
                      //       'image': base64Image ?? 'no image',
                      //       'state': jsonProductDetailsResponse['result']['order_line'][0]['sale'] ?? 'no state'
                      //     });
                      //   });
                      // }
                      // setState(() {
                      //   productDetailsList.add({
                      //     'id': jsonProductDetailsResponse['result']['order_line'][0]['id']
                      //         .toString(),
                      //     'quantity':
                      //     jsonProductDetailsResponse['result']['order_line'][0]['product_uom_qty']
                      //         .toString(),
                      //     'type': productType,
                      //     'model': productName,
                      //     'manufacturer': jsonProductDetailsResponse['result']['order_line'][0]['name'],
                      //     'image': base64Image ?? 'no image',
                      //     'state': jsonProductDetailsResponse['result']['order_line'][0]['sale'] ??
                      //         'no state'
                      //   });
                      // });
                        setState(() {
                          productDetailsList.add({
                            'id': jsonProductDetailsResponse['result']['order_line'][0]['id'].toString(),
                            'quantity': jsonProductDetailsResponse['result']['order_line'][0]['product_uom_qty'].toString(),
                            'type': productType,
                            'model': productName,
                            'manufacturer': jsonProductDetailsResponse['result']['order_line'][0]['name'],
                            'image': base64Image,
                            'state': jsonProductDetailsResponse['result']['order_line'][0]['sale'] ?? 'no state'
                          });
                        });
                      } else {
                        print("No matching products found in the given categories.");
                      }
                    } else {
                      print('product_id is not a list or is empty.');
                    }
                  // }

                  // if (productImage != null) {
                  // if (jsonProductImageResponse['result']['status'] == 'success' && jsonProductImageResponse.isNotEmpty) {
                    for (var product in jsonProductImageResponse['result']['product_data']) {
                      if (product['categ_id'] != null) {
                        categIdList.add(product['categ_id'][0]);
                        // final categoryDetails = await client?.callKw({
                        //   'model': 'product.category',
                        //   'method': 'search_read',
                        //   'args': [
                        //     [
                        //       ['id', '=', product['categ_id'][0]],
                        //     ]
                        //   ],
                        //   'kwargs': {
                        //     'fields': ['name', 'parent_id'],
                        //   },
                        // });
                        print("categIdListcategIdList$categIdList");
                        final Uri url = Uri.parse('$baseUrl/rebates/product_category');
                        final categoryDetails = await http.post(
                          url,
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            "jsonrpc": "2.0",
                            "method": "call",
                            "params": {
                              "id": product['categ_id'][0],
                            }
                          }),
                        );
                        print("******************************");
                        final Map<String, dynamic> jsonCategoryDetailsResponse = json.decode(categoryDetails.body);
                        // if (categoryDetails != null &&
                        //     categoryDetails.isNotEmpty) {
                        print("jsonCategoryDetailsResponsessss$jsonCategoryDetailsResponse");
                        if (jsonCategoryDetailsResponse['result']['status'] == 'success' && jsonCategoryDetailsResponse['result']['categories'].isNotEmpty) {
                          for (var category in jsonCategoryDetailsResponse['result']['categories']) {
                            final categoryName = category['name'];
                            final categoryId = category['id'];
                            String? parentCategoryName;
                            print(category['parent_id']);
                            print("category['parent_id']");
                            if (category['parent_id'] != null &&
                                category['parent_id'] is List &&
                                category['parent_id'].isNotEmpty) {
                              final parentCategoryId = category['parent_id'][0];
                              print(parentCategoryId);
                              print("parentCategoryIdparentCategoryIdparentCategoryId");
                              // final parentCategoryDetails =
                              //     await client?.callKw({
                              //   'model': 'product.category',
                              //   'method': 'search_read',
                              //   'args': [
                              //     [
                              //       ['id', '=', parentCategoryId],
                              //       [
                              //         'name',
                              //         'in',
                              //         ['Inverters', 'Solar Panels', 'Storage']
                              //       ],
                              //     ]
                              //   ],
                              //   'kwargs': {
                              //     'fields': ['name'],
                              //   },
                              // });
                              final Uri parentCategoryUrl = Uri.parse('$baseUrl/rebates/product_category');
                              final parentCategoryDetails = await http.post(
                                parentCategoryUrl,
                                headers: {"Content-Type": "application/json"},
                                body: jsonEncode({
                                  "jsonrpc": "2.0",
                                  "method": "call",
                                  "params": {
                                    "id": parentCategoryId,
                                    "name": ['Inverters', 'Solar Panels', 'Storage']
                                  }
                                }),
                              );
                              print("******************************");
                              final Map<String, dynamic> jsonParentCategoryDetailsResponse = json.decode(parentCategoryDetails.body);
                              print(jsonParentCategoryDetailsResponse['result']['categories']);
                              print("jsonParentCategoryDetailsResponse");
                              // if (parentCategoryDetails != null &&
                              //     parentCategoryDetails.isNotEmpty) {
                              print("jsonParentCategoryDetailsResponse['result']['categories']${jsonParentCategoryDetailsResponse['result']['categories']}");
                              if (jsonParentCategoryDetailsResponse['result']['status'] == 'success' && jsonParentCategoryDetailsResponse['result']['categories'].isNotEmpty) {
                                print("jsonParentCategoryDetailsResponse['result']['categories']jsonParentCategoryDetailsResponse['result']['categories']");
                                parentCategoryName =
                                jsonParentCategoryDetailsResponse['result']['categories'][0]['name'];
                                print(parentCategoryId);
                                print(parentCategoryName);
                                print("parentCategoryName");
                                if (['Inverters', 'Solar Panels', 'Storage']
                                    .contains(parentCategoryName)) {
                                  finalCategoryList.add({
                                    'id': parentCategoryId,
                                    'name': parentCategoryName,
                                  });
                                }
                              }
                            }
                            print("4444444444444444444dddddddddddddddddd");
                            if (['Inverters', 'Solar Panels', 'Storage']
                                .contains(categoryName)) {
                              if (categoryName != parentCategoryName) {
                                finalCategoryList.add({
                                  'name': categoryName,
                                  'id': categoryId,
                                });
                              }
                            }
                          }
                        }
                      }
                    }
                  }

                  // if (productImage != null && productImage.isNotEmpty) {
                  // if (jsonProductImageResponse['result']['status'] == 'success' && jsonProductImageResponse.isNotEmpty) {
                    final image = jsonProductImageResponse['result']['product_data'][0];
                    if (image['image'] is String) {
                      final imageBase64 = image['image'] as String;
                      if (imageBase64.isNotEmpty) {
                        final imageData = base64Decode(imageBase64);
                        setState(() {
                          solarProductImage =
                              MemoryImage(Uint8List.fromList(imageData));
                        });
                      }
                    } else {
                      setState(() {
                        solarProductImage = MemoryImage(Uint8List.fromList([]));
                      });
                    // }
                  }
                  // var productIdData = productDetails[0]['product_id'];
                  // if (productIdData is List && productIdData.isNotEmpty) {
                  //   String productName = productIdData.length > 1
                  //       ? productImage[0]['name']
                  //       : 'Unknown Product';
                  //   final base64Image;
                  //   if (solarProductImage != null) {
                  //     final bytes = solarProductImage!.bytes;
                  //     base64Image = base64Encode(bytes);
                  //   } else {
                  //     base64Image = 'null';
                  //   }
                  //   if (productSerial.isNotEmpty) {
                  //     setState(() {
                  //       productDetailsList.add({
                  //         'id': productDetails[0]['id'].toString(),
                  //         'quantity':
                  //             productDetails[0]['product_uom_qty'].toString(),
                  //         'model': productName,
                  //         'manufacturer': productDetails[0]['name'],
                  //         'image': base64Image,
                  //         'state': productDetails[0]['sale'] ?? '',
                  //       });
                  //     });
                  //   }
                  //   // setState(() {
                  //   //   productDetailsList.add({
                  //   //     'id': productDetails[0]['id'].toString(),
                  //   //     'quantity':
                  //   //         productDetails[0]['product_uom_qty'].toString(),
                  //   //     'model': productName,
                  //   //     'manufacturer': productDetails[0]['name'],
                  //   //     'image': base64Image,
                  //   //     'state': productDetails[0]['sale'] ?? '',
                  //   //   });
                  //   // });
                  // } else {}
                }
              }
            }
          } else {}
        } else {}

        await saveCategoryListToHive();
      } catch (e) {
        loadProductDetailsFromHive();
        loadProductCategoriesFromHive();
        loadfinalCategList();
        loadCategIdList();
        loadWorksheetDocumentFromHive();
        return;
      }
    }

  }

  Future<void> saveWorksheetDocumentsToHive() async {
    print("bbbbbbbbbbbbbbbbbbbbbbbbf");
    try {
      final box = await Hive.openBox<WorksheetDocument>('worksheetDocumentBox');
      await box.clear();

      WorksheetDocument productInfo = WorksheetDocument(
        premises: premises,
        storeys: storeys,
        wallType: wall_type,
        roofType: roof_type,
        meterBoxPhase: meterBoxPhase,
        serviceType: serviceType,
        nmi: nmi,
        expectedInverterLocation: expectedInverterLocation,
        mountingWallType: mountingWallType,
        inverterLocationNotes: inverterLocationNotes,
        expectedBatteryLocation: expectedBatteryLocation,
        mountingType: mountingType,
        switchBoardUsed: switchBoardUsed,
        installedOrNot: installedOrNot,
        description: description,
      );
      print("vgggggggggggggggggggggggggggggggg");
      await box.put(projectId, productInfo);
    } catch (e) {
      print("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee$e");
    }
  }

  Future<void> saveCategoryListToHive() async {
    try {
      final box = await Hive.openBox<Category>('categories_$projectId');
      await box.clear();

      for (var category in finalCategoryList) {
        final categoryModel = Category(
          id: category['id'] as int,
          name: category['name'] as String,
        );
        await box.put(categoryModel.id, categoryModel);
      }
    } catch (e) {}
  }

  Future<void> loadInstallerSignatureFromHive() async {
    final box = await Hive.openBox<InstallerSignature>(
        'installerSignatures_$projectId');

    final installerSignature = box.get(projectId);
    print(installerSignature?.witnessName);
    print("436666666666666666666666666665");
    if (installerSignature != null) {
      setState(() {
        witnessName = installerSignature.witnessName ?? '';
        installerName = installerSignature.installerName;
        installerDate = installerSignature.installerDate;
        installerSignatureImageBytes =
            installerSignature.installerSignatureImageBytes;
        installerSignatureImage = MemoryImage(installerSignatureImageBytes!);
      });
      print("$installerName/witnessNamewitnessNamewitnessName");
    } else {}
  }

  Future<void> getInstallerSignatureDetails() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    userName = prefs.getString('userName') ?? '';
    final teamId = prefs.getInt('teamId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    if (!isNetworkAvailable) {
      loadInstallerSignatureFromHive();
      return;
    } else {
      try {
        // final signatureFromProject = await client?.callKw({
        //   'model': 'project.task',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       // ['x_studio_proposed_team', '=', userId],
        //       ['id', '=', projectId],
        //       ['worksheet_id', '!=', false],
        //       ['team_lead_user_id', '=', userId],
        //     ]
        //   ],
        //   'kwargs': {
        //     'fields': [
        //       'install_signed_by',
        //       'install_signature',
        //       'date_worksheet_install',
        //       // 'witness_name'
        //     ],
        //   },
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/project_task');
        final signatureFromProject = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "team_id": teamId,
              "id": projectId,
            }
          }),
        );
        print(signatureFromProject);
        print("signatureFromProject");
        final Map<String, dynamic> jsonSignatureFromProjectResponse = json.decode(signatureFromProject.body);
        if (jsonSignatureFromProjectResponse['result']['status'] == 'success' &&
            jsonSignatureFromProjectResponse['result']['tasks'].isNotEmpty) {
        // if (signatureFromProject != null && signatureFromProject.isNotEmpty) {
          print(jsonSignatureFromProjectResponse);
          final installerSign = jsonSignatureFromProjectResponse['result']['tasks'][0];
          setState(() {
            // witnessName = signatureFromProject[0]['witness_name'];
            installerName = userName ?? '';
            installerDate =
                DateTime.tryParse(installerSign['date_worksheet_install']) ??
                    null;
            print(installerDate);
          });

          if (installerSign['install_signature'] is String) {
            final imageBase64 = installerSign['install_signature'] as String;
            if (imageBase64.isNotEmpty) {
              final imageData = base64Decode(imageBase64);
              setState(() {
                installerSignatureImageBytes = Uint8List.fromList(imageData);
                installerSignatureImage =
                    MemoryImage(installerSignatureImageBytes!);
              });
            }
          } else {}
          // await saveInstallerSignatureToHive();
        } else {}
      } catch (e) {
        loadInstallerSignatureFromHive();
        return;
      }
    }
  }

  Future<void> saveInstallerSignatureToHive() async {
    final box = await Hive.openBox<InstallerSignature>(
        'installerSignatures_$projectId');
    final installerSignature = InstallerSignature(
        witnessName: witnessName,
        installerName: installerName,
        installerDate: installerDate,
        installerSignatureImageBytes:
            installerSignatureImageBytes ?? Uint8List(0));
    await box.add(installerSignature);
  }

  void loadOwnerSignatureFromHive() async {
    final box = await Hive.openBox<OwnerSignatureHive>('ownerSignatures');
    final OwnerSignHive = box.get(projectId);
    print(OwnerSignHive);
    print(OwnerSignHive?.ownerName);
    if (OwnerSignHive != null) {
      // setState(() {
      //   ownerName = OwnerSignHive.ownerName;
      //   customerDate = OwnerSignHive.customerDate;
      //   ownerSignatureImageBytes = OwnerSignHive.ownerSignatureImageBytes;
      //   ownerSignatureImage = MemoryImage(ownerSignatureImageBytes!);
      // });
      setState(() {
        ownerName = OwnerSignHive.ownerName ?? "";
        customerDate = OwnerSignHive.customerDate ?? null;
        ownerSignatureImageBytes = OwnerSignHive.ownerSignatureImageBytes;

        if (ownerSignatureImageBytes != null) {
          ownerSignatureImage = MemoryImage(ownerSignatureImageBytes!);
        } else {
          ownerSignatureImage = null;
        }
      });
    } else {}
  }

  Future<void> getOwnerSignatureDetails() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    final teamId = prefs.getInt('teamId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    if (!isNetworkAvailable) {
      loadOwnerSignatureFromHive();
      return;
    } else {
      try {
        // final ownerSignatureFromProject = await client?.callKw({
        //   'model': 'project.task',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       // ['x_studio_proposed_team', '=', userId],
        //       ['id', '=', projectId],
        //       ['worksheet_id', '!=', false],
        //       ['team_lead_user_id', '=', userId],
        //     ]
        //   ],
        //   'kwargs': {
        //     'fields': [
        //       'partner_id',
        //       'customer_name',
        //       'customer_signature',
        //       'date_worksheet_client_signature',
        //     ],
        //   },
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/project_task');
        final ownerSignatureFromProject = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "team_id": teamId,
              "id": projectId,
            }
          }),
        );
        final Map<String, dynamic> jsonOwnerSignatureFromProjectResponse = json.decode(ownerSignatureFromProject.body);
        // if (ownerSignatureFromProject != null &&
        //     ownerSignatureFromProject.isNotEmpty) {
        if (jsonOwnerSignatureFromProjectResponse['result']['status'] == 'success' &&
            jsonOwnerSignatureFromProjectResponse['result']['tasks'].isNotEmpty) {
          final OwnerSign = jsonOwnerSignatureFromProjectResponse['result']['tasks'][0];
          setState(() {
            ownerName = OwnerSign['partner_id'][1] ?? '';
            customerDate = DateTime.tryParse(
                    OwnerSign['date_worksheet_client_signature']) ??
                null;
          });
          if (OwnerSign['customer_signature'] is String) {
            final imageBase64 = OwnerSign['customer_signature'] as String;
            if (imageBase64.isNotEmpty) {
              final imageData = base64Decode(imageBase64);
              setState(() {
                ownerSignatureImageBytes = Uint8List.fromList(imageData);
                ownerSignatureImage = MemoryImage(ownerSignatureImageBytes!);
              });
            }
          } else {}
          await saveOwnerSignatureToHive();
        } else {}
      } catch (e) {
        loadOwnerSignatureFromHive();
        return;
      }
    }
  }

  Future<void> saveOwnerSignatureToHive() async {
    final box =
        await Hive.openBox<OwnerSignatureHive>('ownerSignatures_$projectId');
    final ownerSign = OwnerSignatureHive(
      ownerName: ownerName,
      customerDate: customerDate,
      ownerSignatureImageBytes: ownerSignatureImageBytes,
    );
    await box.put('ownerSignatureKey', ownerSign);
  }

  Future<void> getOwnerDetails() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    final teamId = prefs.getInt('teamId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    if (!isNetworkAvailable) {
      loadOwnerDetailsFromHive();
      return;
    } else {
      try {
        // final partnerDetails = await client?.callKw({
        //   'model': 'project.task',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       // ['x_studio_proposed_team', '=', userId],
        //       ['id', '=', projectId],
        //       ['worksheet_id', '!=', false],
        //       ['team_lead_user_id', '=', userId],
        //     ]
        //   ],
        //   'kwargs': {
        //     'fields': ['partner_id'],
        //   },
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/project_task');
        final partnerDetails = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "team_id": teamId,
              "type": 'New Installation',
            }
          }),
        );
        final Map<String, dynamic> jsonPartnerDetailsResponse = json.decode(partnerDetails.body);
        // if (partnerDetails != null && partnerDetails.isNotEmpty) {
        if (jsonPartnerDetailsResponse['result']['status'] == 'success' &&
            jsonPartnerDetailsResponse['result']['tasks'].isNotEmpty) {
          final partnerId = jsonPartnerDetailsResponse['result']['tasks'][0]['partner_id'][0];
          final Uri url = Uri.parse('$baseUrl/rebates/res_partner');
          final partnerDetailsFromProject = await http.post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "jsonrpc": "2.0",
              "method": "call",
              "params": {
                "id": partnerId,
              }
            }),
          );
          final Map<String, dynamic> jsonPartnerDetailsFromProjectResponse = json.decode(partnerDetailsFromProject.body);

          // final partnerDetailsFromProject = await client?.callKw({
          //   'model': 'res.partner',
          //   'method': 'search_read',
          //   'args': [
          //     [
          //       ['id', '=', partnerId],
          //     ]
          //   ],
          //   'kwargs': {
          //     'fields': ['name', 'company_type', 'phone', 'email'],
          //   },
          // });
          if (jsonPartnerDetailsFromProjectResponse['result']['status'] == 'success' && jsonPartnerDetailsFromProjectResponse['result']['res_partner_data'].isNotEmpty) {
            partner_items.add(
                jsonPartnerDetailsFromProjectResponse['result']['res_partner_data'][0]);
          }
          print(partner_items);
          print("partner_itemspartner_itemspartner_items");
        } else {}
      } catch (e) {
        loadOwnerDetailsFromHive();
        return;
      }
    }
  }

  Future<void> loadOwnerDetailsFromHive() async {
    final box = await Hive.openBox<Partner>('partners');
    if (box.containsKey(projectId)) {
      final partner = box.get(projectId);
      if (partner != null) {
        partner_items.add({
          'name': partner.name,
          'company_type': partner.companyType,
          'phone': partner.phone,
          'email': partner.email,
        });
      } else {}
    } else {}
  }

  Future<void> getProducts() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    final teamId = prefs.getInt('teamId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    try {
      final Uri url = Uri.parse('$baseUrl/rebates/product');
      final productDetails = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {}
        }),
      );
      final Map<String, dynamic> jsonProductDetailsResponse = json.decode(productDetails.body);
      if (jsonProductDetailsResponse['result']['status'] == 'success' &&
          jsonProductDetailsResponse['result']['product_data'].isNotEmpty) {
        // final productDetails = await client?.callKw({
        //   'model': 'product.product',
        //   'method': 'search_read',
        //   'args': [[]],
        //   'kwargs': {
        //     'fields': [
        //       'id',
        //       'name',
        //     ],
        //   },
        // });
        for (var item in jsonProductDetailsResponse['result']['product_data']) {
          product_items.add(item['name']);
          product_ids.add(item['id']);
        }
      }
    } catch (e) {}
  }

  Future<void> getHazardQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    final teamId = prefs.getInt('teamId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    try {
      // final hazardQuestionDetails = await client?.callKw({
      //   'model': 'swms.risk.register',
      //   'method': 'search_read',
      //   'args': [[]],
      //   'kwargs': {
      //     'fields': [
      //       'id',
      //       'installation_question',
      //       'risk_control',
      //       'job_activity'
      //     ],
      //   },
      // });
      final Uri url = Uri.parse('$baseUrl/rebates/swms_risk_register');
      final hazardQuestionDetails = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {}
        }),
      );
      final Map<String, dynamic> jsonHazardQuestionDetailsResponse = json.decode(hazardQuestionDetails.body);

      // if (hazardQuestionDetails != null && hazardQuestionDetails.isNotEmpty) {
      if (jsonHazardQuestionDetailsResponse['result']['status'] == 'success' &&
          jsonHazardQuestionDetailsResponse['result']['swms_register_data'].isNotEmpty) {
        hazard_question_items =
            List<Map<String, dynamic>>.from(jsonHazardQuestionDetailsResponse['result']['swms_register_data']);
      } else {
        print("No hazard questions found.");
      }
    } catch (e) {
      print("Error fetching hazard questions: $e");
    }
  }

  Future<bool> _canTakeSelfie(
      String checklistType, Duration minDuration) async {
    final box = await Hive.openBox<HiveImage>('imagesBox');
    print(box.values);
    box.values.forEach((value) {
      print(
          'Checklist Type: ${value.checklistType}, Timestamp: ${value.timestamp}, Project ID: ${value.projectId}');
    });

    print(
        "Checking selfies with checklistType: $checklistType and projectId: $projectId");
    final selfies = box.values.where((selfie) =>
        selfie.checklistType == checklistType && selfie.projectId == projectId);

    if (selfies.isNotEmpty) {
      final lastSelfie = selfies.last;
      final timeDifference = DateTime.now().difference(lastSelfie.timestamp);

      setState(() {
        checkIndifference = timeDifference;
        Middifference = timeDifference;
      });

      return timeDifference >= minDuration;
    }
    return true;
  }

  Future<bool> _checkCameraPermission() async {
    PermissionStatus status = await Permission.camera.status;

    if (status.isDenied) {
      status = await Permission.camera.request();
      if (status.isDenied) {
        return false;
      }
    }

    if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }

    if (status.isGranted) {
      return true;
    }

    return false;
  }

  Future<bool> _getFromCamera(String checklistType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final teamId = prefs.getInt('teamId') ?? 0;
      final baseUrl = prefs.getString('url') ?? 0;

      bool hasPermission = await _checkCameraPermission();
      if (!hasPermission) {
        setState(() {
          isImageLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera permission is required to proceed.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      final box = await Hive.openBox<HiveImage>('imagesBox');
      HiveImage? existingImage = box.values.cast<HiveImage?>().firstWhere(
            (image) =>
                image != null &&
                image.checklistType == checklistType &&
                image.projectId == projectId,
            orElse: () => null,
          );
      if (existingImage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You already uploaded an image for this selfie.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxHeight: 1000,
        maxWidth: 1000,
      );
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        List<int> imageBytes = await imageFile.readAsBytes();
        String base64Image = base64Encode(imageBytes);
        Position? position = await _getCurrentLocation();
        if (position == null) {
          setState(() {
            isImageLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You must enable location permissions to proceed.'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        if (!isNetworkAvailable) {
          await _saveImageToHive(checklistType, base64Image, position);
          final box = await Hive.openBox<HiveImage>('imagesBox');
          final selfies = box.values
              .where((selfie) => selfie.checklistType == checklistType);
          if (selfies.isNotEmpty) {
            final lastSelfie = selfies.last;
            final timeDifference =
                DateTime.now().difference(lastSelfie.timestamp);
            setState(() {
              checkIndifference = timeDifference;
              Middifference = timeDifference;
              isQrVisible = true;
              setState(() {});
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Network unavailable. Image saved for later upload.'),
              backgroundColor: Colors.red,
            ),
          );
          return true;
        } else {
          try {
            print(categIdList);
            print(checklistType);
            print("categIdListcategdddddIdListcategIdList");

            final Uri url = Uri.parse('$baseUrl/rebates/installation_checklist');
            final checklist = await http.post(
              url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "jsonrpc": "2.0",
                "method": "call",
                "params": {
                  "categIdList": categIdList,
                  "workTypeIdList": workTypeIdList,
                  "selfie_type": checklistType
                }
              }),
            );
            print(checklist.body);
            print("jsonChecklistResponsessssssssss");
            final Map<String, dynamic> jsonChecklistResponse = json.decode(
                checklist.body);
            print(jsonChecklistResponse);
            if (jsonChecklistResponse['result']['status'] == 'success' &&
                jsonChecklistResponse['result']['installation_checklist']
                    .isNotEmpty) {
            print("checklistchecklistchecklist$checklist");
            // if (checklist != null && checklist.isNotEmpty) {
              // await _uploadImage(checklist[0]['id'], base64Image, position);
              // Navigator.popUntil(
              //     context, ModalRoute.withName('/installing_form_view'));
              // return true;
              bool uploadResult =
                  await _uploadImage(jsonChecklistResponse['result']['installation_checklist'][0]['id'], base64Image, position);
              print(uploadResult);
              print("uploadResultuploadResultuploadResult");
              return uploadResult;
            } else {
              throw Exception('Checklist not found');
            }
          } catch (r) {
            return false;
          }
        }
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }


  Future<void> _saveAttendanceCheckoutToHive(int worksheetId, position, formattedDate, int memberId) async {
    print('Attendance ssssssssssssssssssssaved to Hive');
    var box = await Hive.openBox<AttendanceCheckout>('attendance_checkout');
    await box.clear();
    print(position.latitude);
    final attendance = AttendanceCheckout(
      worksheetId: worksheetId,
      latitude: position.latitude,
      longitude: position.longitude,
      date: formattedDate,
      memberId: memberId,
    );
    await box.put(worksheetId,attendance);

    print('Attendance saved to Hive');
  }


  Future<void> _attendanceCheckoutAdd(int worksheetId, position, int memberId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    final String formattedDate =
    DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    if (!isNetworkAvailable) {
      await _saveAttendanceCheckoutToHive(worksheetId,position, formattedDate,memberId);
      // await _saveStartToHive(taskId, formattedDate);
      // setState(() {
      //   progressChange = false;
      //   isStartjob = true;
      // });
    } else {
      try {
        final formattedDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
        final response = await client?.callKw({
          'model': 'worksheet.attendance',
          'method': 'create',
          'args': [
            {
              'type': 'check_out',
              'worksheet_id': worksheetId,
              'in_latitude': position.latitude,
              'in_longitude': position.longitude,
              'member_id': memberId,
              'date': formattedDate
            }
          ],
          'kwargs': {},
        });
        if (response == true) {
          // setState(() {
          //   progressChange = false;
          //   isStartjob = true;
          // });

        } else {}
      } catch (e) {}
    }
  }

  // Future<void> _saveImageToHive(
  //     String checklistType, String base64Image, position) async {
  //   final imageEntry = HiveImage(
  //       checklistType: checklistType,
  //       base64Image: base64Image,
  //       projectId: projectId!,
  //       categIdList: categIdList,
  //       position: {
  //         'latitude': position.latitude,
  //         'longitude': position.longitude
  //       },
  //       timestamp: DateTime.now());
  //   final box = await Hive.openBox<HiveImage>('imagesBox');
  //   await box.add(imageEntry);
  //   await box.close();
  // }

  Future<void> _saveImageToHive(
      String checklistType, String base64Image, position) async {
    Box<HiveImage>? box;
    try {
      final imageEntry = HiveImage(
        checklistType: checklistType,
        base64Image: base64Image,
        projectId: projectId!,
        categIdList: categIdList,
        position: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        timestamp: DateTime.now(),
      );
      box = await Hive.openBox<HiveImage>('imagesBox');
      await box.add(imageEntry);
      print("Image saved successfully.");
    } catch (e) {
      print("Error saving image to Hive: $e");
    } finally {
      if (box != null && box.isOpen) {
        await box.close();
        print("Box closed properly.");
      }
    }
  }

  Future<bool> _uploadImage(int id, String base64Image, position) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('url') ?? 0;
    final teamId = prefs.getInt('teamId') ?? 0;
    print(id);
    print(base64Image);
    print(position);
    print(projectId);
    print("444444444444444444444444444444fffffffffff");
    print("F");
    setState(() {
      isImageLoading = true;
    });
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks.first;
      String locationDetails =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
      final formattedDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      print("projectIdprojectIdprojectId$projectId");
      // final worksheet = await client?.callKw({
      //   'model': 'task.worksheet',
      //   'method': 'search_read',
      //   'args': [
      //     [
      //       ['task_id', '=', projectId],
      //     ],
      //   ],
      //   'kwargs': {},
      // });
      // print("worksheetworksheet$worksheet/worksheetworksheet");
      // if (worksheet != null && worksheet.isNotEmpty) {
      //   worksheetId = worksheet[0]['id'];
      // }
      print("ffffffffffffffffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee");
      // final checklist = await client?.callKw({
      //   'model': 'installation.checklist.item',
      //   'method': 'create',
      //   'args': [
      //     {
      //       'user_id': userId,
      //       'worksheet_id': worksheetId,
      //       'checklist_id': id,
      //       'date': formattedDate,
      //       'image': base64Image,
      //       'location': locationDetails,
      //       'latitude': position.latitude,
      //       'longitude': position.longitude
      //     }
      //   ],
      //   'kwargs': {},
      // });
      final Uri url = Uri.parse('$baseUrl/rebates/installation_checklist_item/create');
      final checklist = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "teamId": teamId,
            "item": id,
            "taskId": worksheetId,
            "base64Image": base64Image,
            "formattedDate": formattedDate,
            "locationDetails": locationDetails,
            'latitude': position.latitude,
            'longitude': position.longitude
          }
        }),
      );
      final Map<String, dynamic> jsonChecklistCreateResponse = json.decode(checklist.body);

      print("$jsonChecklistCreateResponse/fffffffffffffffffddddddddddfffffffffffffffffff");
      // setState(() async {
      //   await _getSelfies();
      //   isImageLoading = false;
      //   print("ffffffffffffffffffffffffffffffffffff");
      //   isQrVisible = true;
      // });
      await _getSelfies();

      setState(() {
        isImageLoading = false;
        isQrVisible = true;
      });
      return true;
    } catch (e) {
      print("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee$e");
      isImageLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Info",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Please check your network connection.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
  }

  Future<void> loadSelfiesFromHive() async {
    try {
      final box = await Hive.openBox<HiveSelfie>('selfiesBox_$projectId');
      if (box.isEmpty) {
        return;
      }

      for (var selfie in box.values) {
        switch (selfie.selfieType) {
          case 'check_in':
            setState(() {
              CheckIncreateTime = selfie.createTime;
              CheckInImagePath = selfie.image;
              CheckinRequired = selfie.image.isNotEmpty;
            });
            break;

          case 'mid':
            setState(() {
              MidcreateTime = selfie.createTime;
              MidImagePath = selfie.image;
              MidRequired = selfie.image.isNotEmpty;
            });
            break;

          case 'check_out':
            setState(() {
              CheckOutcreateTime = selfie.createTime;
              CheckOutImagePath = selfie.image;
              CheckoutRequired = selfie.image.isNotEmpty;
            });
            break;
        }
      }
    } catch (e) {}
  }

  Future<void> _getSelfies() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('url') ?? 0;
    final teamId = prefs.getInt('teamId') ?? 0;
    if (!isNetworkAvailable) {
      loadSelfiesFromHive();
      return;
    } else {
      try {
        // final selfies = await client?.callKw({
        //   'model': 'installation.checklist',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       ['category_ids', 'in', categIdList],
        //       ['selfie_type', '!=', false],
        //       ['group_ids', 'in', workTypeIdList]
        //     ],
        //   ],
        //   'kwargs': {},
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/installation_checklist');
        final selfies = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "categIdList": categIdList,
              "workTypeIdList": workTypeIdList,
              "is_selfie": true
            }
          }),
        );
        final Map<String, dynamic> jsonSelfiesResponse = json.decode(selfies.body);
        print(jsonSelfiesResponse);
        print("fe333jsonSelfiesResponse");
        if (jsonSelfiesResponse['result']['status'] == 'success' && jsonSelfiesResponse['result']['installation_checklist'].isEmpty) {

        // if (selfies == null || selfies.isEmpty) {
          return;
        }
        List selfieItems = [];
        // final worksheet = await client?.callKw({
        //   'model': 'task.worksheet',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       ['task_id', '=', projectId],
        //     ],
        //   ],
        //   'kwargs': {},
        // });
        print("ddddddddssssssssssssssssssffffffffffffff");
        final Uri worksheetUrl = Uri.parse('$baseUrl/rebates/task_worksheet');
        final worksheet = await http.post(
          worksheetUrl,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "task_id": projectId,
            }
          }),
        );
        final Map<String, dynamic> jsonWorksheetResponse = json.decode(worksheet.body);
        print("dddjsonWorksheetResponse$jsonWorksheetResponse");
        if (jsonWorksheetResponse['result']['status'] == 'success' && jsonWorksheetResponse['result']['worksheet_data'].isNotEmpty) {
          // if (worksheet != null && worksheet.isNotEmpty) {
          print("worksheetworksheetworksheet$worksheet");
          setState(() {
            worksheetId = jsonWorksheetResponse['result']['worksheet_data'][0]['id'];
            print("sssssssssssssssss$worksheetId");
            if (jsonWorksheetResponse['result']['worksheet_data'][0]['team_lead_id'] is List && jsonWorksheetResponse['result']['worksheet_data'][0]['team_lead_id'].isNotEmpty) {
              memberId = jsonWorksheetResponse['result']['worksheet_data'][0]['team_lead_id'][0] as int;
            }
          });
          print("memberIdmemberIdmemberIdmemberId$memberId");
          final box = await Hive.openBox<HiveSelfie>('selfiesBox_$projectId');
          for (var selfie in jsonSelfiesResponse['result']['installation_checklist']) {
            print("ccccccccccccceesssssssssssssssssssssss$selfie");
            print(worksheetId);
            // final selfiesList = await client?.callKw({
            //   'model': 'installation.checklist.item',
            //   'method': 'search_read',
            //   'args': [
            //     [
            //       ['worksheet_id', '=', worksheetId],
            //       ['user_id', '=', userId],
            //       ['checklist_id', '=', selfie['id']],
            //     ],
            //   ],
            //   'kwargs': {},
            // });
            final Uri url = Uri.parse('$baseUrl/rebates/installation_checklist_item');
            final selfiesList = await http.post(
              url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "jsonrpc": "2.0",
                "method": "call",
                "params": {
                  "worksheet_id": worksheetId,
                  "teamId": teamId,
                  "checklist_id": selfie['id']
                }
              }),
            );
            final Map<String, dynamic> jsonSelfiesListResponse = json.decode(selfiesList.body);
            print(jsonSelfiesListResponse);
            print("jsonSelfiesListResponsejsonSelfiesListResponse");
            print(
                "${jsonSelfiesListResponse}/selfiesListselfiesListselfiesListselfiesList");
            // if (selfiesList == null || selfiesList.isEmpty) {
            if (jsonSelfiesListResponse['result']['status'] == 'success' &&
                jsonSelfiesListResponse['result']['installation_checklist_item_data'].isEmpty) {
              print("88888888888888888888xxxxx8888888");
              continue;
            }

            selfieItems.addAll(jsonSelfiesListResponse['result']['installation_checklist_item_data']);

            DateTime createTime =
                DateTime.parse(jsonSelfiesListResponse['result']['installation_checklist_item_data'][0]['date']).toLocal();
            print(createTime);
            var localCreateTime = createTime.toLocal();
            print(localCreateTime);
            print("localCreateTimelocalCreateTimelocalCreateTime");
            DateTime parsedDate =
                DateTime.parse(jsonSelfiesListResponse['result']['installation_checklist_item_data'][0]['date']).toLocal();
            String formattedDate =
                DateFormat('yyyy-MM-dd HH:mm:ss').format(parsedDate);
            for (var item in jsonSelfiesListResponse['result']['installation_checklist_item_data']) {
              DateTime createTime = DateTime.parse(item['date']).toLocal();
              final hiveSelfie = HiveSelfie(
                  id: item['id'],
                  image: item['image'],
                  selfieType: selfie['selfie_type'],
                  createTime: createTime,
                  worksheetId: worksheetId!);
              box.add(hiveSelfie);
            }
            print(selfie['selfie_type']);
            print("selfie['selfie_type']");
            if (selfie['selfie_type'] == 'check_in') {
              setState(() {
                CheckIncreateTime = localCreateTime;
                isQrVisible = true;
                CheckInImagePath = jsonSelfiesListResponse['result']['installation_checklist_item_data'][0]['image'];
                if (CheckInImagePath != null && CheckInImagePath.isNotEmpty) {
                  CheckinRequired = true;
                }
              });
            }

            if (selfie['selfie_type'] == 'mid') {
              setState(() {
                MidcreateTime = localCreateTime;
                MidImagePath = jsonSelfiesListResponse['result']['installation_checklist_item_data'][0]['image'];
                if (MidImagePath != null && MidImagePath.isNotEmpty) {
                  MidRequired = true;
                }
              });
            }

            if (selfie['selfie_type'] == 'check_out') {
              setState(() {
                CheckOutcreateTime = localCreateTime;
                CheckOutImagePath = jsonSelfiesListResponse['result']['installation_checklist_item_data'][0]['image'];
                if (CheckOutImagePath != null && CheckOutImagePath.isNotEmpty) {
                  CheckoutRequired = true;
                }
              });
            }
          }
        }
      } catch (e) {
        print("eerrrrrrrrrrrrrrrrrrrrrrrrr$e");
        loadSelfiesFromHive();
        return;
      }
    }
  }

  Future<Position?> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null; // Return null if permissions are still denied
      }
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Future<Position> _getCurrentLocation() async {
  //   LocationPermission permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       throw Exception('Location permissions are denied');
  //     }
  //   }
  //
  //   return await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high);
  // }

  void _pickFile() async {
    isUploadLoading = true;
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: false);

    if (result != null) {
      PlatformFile file = result.files.first;
      File fileToUpload = File(file.path!);
      String base64Content = base64Encode(await fileToUpload.readAsBytes());
      setState(() {
        attachments_append.add({'name': file.name, 'base64': base64Content});
      });
      _uploadDocumentToOdoo(file.name, base64Content);
    } else {}
  }

  void _uploadDocumentToOdoo(String filename, String base64Content) async {
    print("$projectId/444444444444444444444444444ffffffffffffffffff");
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    try {
      // final response = await client?.callKw({
      //   'model': 'ir.attachment',
      //   'method': 'create',
      //   'args': [
      //     {
      //       'name': filename,
      //       'type': 'binary',
      //       'datas': base64Content,
      //       'res_model': 'project.task',
      //       'res_id': projectId,
      //       'mimetype': 'application/pdf',
      //     }
      //   ],
      //   'kwargs': {},
      // });
      final Uri url = Uri.parse('$baseUrl/rebates/ir_attachment/create');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            'filename': filename,
            'type': 'binary',
            'datas': base64Content,
            'res_model': 'project.task',
            'res_id': projectId,
            'mimetype': 'application/pdf',
          }
        }),
      );
      final Map<String, dynamic> jsonCreateAttachmentResponse = json.decode(response.body);
      print("responseresponseffffffffffffffffffffffresponse$jsonCreateAttachmentResponse");
      // if (response is int && response > 0) {
      if (jsonCreateAttachmentResponse['result']['status'] == 'success') {
        setState(() {
          attachments_append.clear();
          getOtherDocuments();
        });
      } else {
        isUploadLoading = false;
      }
    } catch (e) {
      isUploadLoading = false;
    }
  }

  void deleteAttachments(int id, String fileName) async {
    try {
      final response = await client?.callKw({
        'model': 'documents.document',
        'method': 'unlink',
        'args': [
          [id],
        ],
        'kwargs': {},
      });
      if (response != null && response is List && response.isNotEmpty) {
        setState(() {
          getOtherDocuments();
        });
      } else {}
    } catch (e) {}
  }

  Future<void> loadOtherDocumentsFromHive() async {
    final box = await Hive.openBox<Document>('documents_$projectId');
    final documents = box.values.toList();
    print(documents);
    setState(() {
      attachments_append.clear();
      for (var document in documents) {
        attachments_append.add({
          'id': document.id,
          'name': document.name,
          'datas': document.datas,
        });
        print(attachments_append.length);
        print("5555555555555333333333333332222222222");
      }
    });
  }

  Future<void> getOtherDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    final teamId = prefs.getInt('teamId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    if (!isNetworkAvailable) {
      loadOtherDocumentsFromHive();
      return;
    } else {
      try {
        print("fffffffffffffffffffffccccccccccc");
        // final attachmentsFromProject = await client?.callKw({
        //   'model': 'project.task',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       // ['x_studio_proposed_team', '=', userId],
        //       ['id', '=', projectId],
        //       ['worksheet_id', '!=', false],
        //       ['team_lead_user_id', '=', userId],
        //     ]
        //   ],
        //   'kwargs': {
        //     'fields': ['document_ids'],
        //   },
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/project_task');
        final attachmentsFromProject = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "team_id": teamId,
              "id": projectId,
            }
          }),
        );
        final Map<String, dynamic> jsonAttachmentsFromProjectResponse = json.decode(attachmentsFromProject.body);
        print(jsonAttachmentsFromProjectResponse);
        print("attachmentsFromProjectattachmentsFromProject");
        // if (attachmentsFromProject != null &&
        //     attachmentsFromProject.isNotEmpty) {
        if (jsonAttachmentsFromProjectResponse['result']['status'] == 'success' && jsonAttachmentsFromProjectResponse['result']['tasks'].isNotEmpty) {
          final attachments = jsonAttachmentsFromProjectResponse['result']['tasks'][0];
          final documentIds = attachments['document_ids'] as List<dynamic>?;
          print(documentIds);
          print("documentIdsdocumentIds");
          if (documentIds != null && documentIds.isNotEmpty) {
            // final documentsResponse = await client?.callKw({
            //   'model': 'documents.document',
            //   'method': 'search_read',
            //   'args': [
            //     [
            //       ['id', 'in', documentIds]
            //     ]
            //   ],
            //   'kwargs': {
            //     'fields': ['id', 'name', 'datas'],
            //   },
            // });
            final Uri url = Uri.parse('$baseUrl/rebates/documents');
            final documentsResponse = await http.post(
              url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "jsonrpc": "2.0",
                "method": "call",
                "params": {
                  "docId": documentIds,
                }
              }),
            );
            final Map<String, dynamic> jsonDocumentsResponseResponse = json.decode(documentsResponse.body);
            if (jsonDocumentsResponseResponse['result']['status'] == 'success' && jsonDocumentsResponseResponse['result']['docs'].isNotEmpty) {
            // if (documentsResponse != null && documentsResponse.isNotEmpty) {
              for (var document in jsonDocumentsResponseResponse['result']['docs']) {
                setState(() {
                  attachments_append.add({
                    'id': document['id'],
                    'name': document['name'],
                    'datas': document['datas'],
                  });
                  isUploadLoading = false;
                });
              }
            } else {}
          } else {}
        } else {
          isUploadLoading = false;
        }
      } catch (e) {
        loadOtherDocumentsFromHive();
        isUploadLoading = false;
        return;
      }
    }
  }

  Future<void> saveOtherDocumentsToHive() async {
    final box = await Hive.openBox<Document>('documents_$projectId');
    for (var attachment in attachments_append) {
      final newDocument = Document(
        id: attachment['id'],
        name: attachment['name'],
        datas: attachment['datas'],
      );
      await box.put(newDocument.id, newDocument);
    }
  }

  void _showSignaturePopup(
      int projectId,
      String title,
      Function(Uint8List, Uint8List, String) onSignatureSubmitted,
      Uint8List? existingSignature,
      String? existingName,
      DateTime? installerDate) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        print(installerDate);
        print("installerDateinstallerDateinstallerDate");
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SignatureScreen(
            onSignatureSubmitted: (installSignature, witnessSignature, name) {
              witnessName = name;
              onSignatureSubmitted(installSignature, witnessSignature, name);
              editSignatureDetails(installSignature, witnessSignature, name);
              // Navigator.pop(context);
              Navigator.pop(context);
              if (!isNetworkAvailable)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Network unavailable. Image saved for later upload.'),
                    backgroundColor: Colors.red,
                  ),
                );
            },
            existingName: existingName ?? '',
            existingSignature: existingSignature,
            title: title,
            projectId: projectId,
            installDate: installerDate,
          ),
        );
      },
    );
  }

  void _showOwnerSignaturePopup(
      int projectId,
      String title,
      Function(Uint8List, String) onSignatureSubmitted,
      Uint8List? existingSignature,
      String? existingName,
      DateTime? customerDate) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: OwnerSignature(
              onSignatureSubmitted: (signature, name) {
                onSignatureSubmitted(signature, name);
                if (title == 'Owner')
                  editOwnerSignatureDetails(signature, name);
                if (title == 'Owner') editOwnerSignatureName(name);
                Navigator.pop(context);
                if (!isNetworkAvailable)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Network unavailable. Image saved for later upload.'),
                      backgroundColor: Colors.red,
                    ),
                  );
              },
              existingName: existingName ?? '',
              existingSignature: existingSignature,
              title: title,
              projectId: projectId,
              customerDate: customerDate),
        );
      },
    );
  }

  Future<void> editSignatureName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    try {
      final response = await client?.callKw({
        'model': 'project.task',
        'method': 'write',
        'args': [
          [projectId],
          {
            'install_signed_by': name,
          }
        ],
        'kwargs': {},
      });

      if (response == true) {
        setState(() {
          getInstallerSignatureDetails();
        });
      } else {}
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Info",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Please check your network connection.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> editOwnerSignatureName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;

    try {
      final response = await client?.callKw({
        'model': 'project.task',
        'method': 'write',
        'args': [
          [projectId],
          {
            'customer_name': name,
          }
        ],
        'kwargs': {},
      });

      if (response == true) {
        setState(() {
          getOwnerSignatureDetails();
        });
      } else {}
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Info",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Please check your network connection.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> editSignatureDetails(Uint8List installSignature,
      Uint8List witnessSignature, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    String base64installSignature = base64Encode(installSignature);
    String base64witnessSignature = base64Encode(witnessSignature);
    String formattedDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    userName = prefs.getString('userName') ?? '';
    try {
      // final response = await client?.callKw({
      //   'model': 'project.task',
      //   'method': 'write',
      //   'args': [
      //     [projectId],
      //     {
      //       'install_signed_by': userName,
      //       'install_signature': base64installSignature,
      //       'date_worksheet_install': formattedDate,
      //     }
      //   ],
      //   'kwargs': {},
      // });
      // print(response);
      // print("ffffffffffffffffffffffffffffresssssss");
      // if (response == true) {
      final Uri url = Uri.parse('$baseUrl/rebates/project_task/write');
      final worksheetDetails = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "task_id": projectId,
            "install_signed_by": userName,
            "install_signature": base64installSignature,
            "date_worksheet_install": formattedDate
          }
        }),
      );
      final Map<String, dynamic> jsonWorksheetDetailsResponse = json.decode(worksheetDetails.body);

      if (jsonWorksheetDetailsResponse['result']['status'] == 'success') {

        setState(() {
          getInstallerSignatureDetails();
        });
      } else {}
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Info",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Please check your network connection.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> editOwnerSignatureDetails(
      Uint8List signature, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;

    String base64Signature = base64Encode(signature);
    String formattedDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    try {
      // final response = await client?.callKw({
      //   'model': 'project.task',
      //   'method': 'write',
      //   'args': [
      //     [projectId],
      //     {
      //       'customer_signature': base64Signature,
      //       'customer_name': name,
      //       'date_worksheet_client_signature': formattedDate,
      //     }
      //   ],
      //   'kwargs': {},
      // });
      // if (response == true) {
      final Uri url = Uri.parse('$baseUrl/rebates/project_task/write');
      final worksheetDetails = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "task_id": projectId,
            "customer_signature": base64Signature,
            "customer_name": name,
            "date_worksheet_client_signature": formattedDate
          }
        }),
      );
      final Map<String, dynamic> jsonWorksheetDetailsResponse = json.decode(worksheetDetails.body);

      if (jsonWorksheetDetailsResponse['result']['status'] == 'success') {

        setState(() {
          getOwnerSignatureDetails();
        });
      } else {}
    } catch (e) {}
  }

  // Future<void> getEmployees() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   userId = prefs.getInt('userId') ?? 0;
  //
  //   try {
  //     // Fetch employee details
  //     final employeeDetails = await client?.callKw({
  //       'model': 'res.users',
  //       'method': 'search_read',
  //       'args': [
  //         [
  //           ['id', '=', userId]
  //         ]
  //       ],
  //       'kwargs': {
  //         'fields': ['id', 'name', 'groups_id'],
  //       },
  //     });
  //
  //     // Check if employeeDetails is not empty
  //     if (employeeDetails != null && employeeDetails.isNotEmpty) {
  //       final groups = employeeDetails[0]['groups_id'];
  //
  //       // Print the groups IDs to debug
  //       print(groups);
  //       print("Fetched groups from employee details");
  //
  //       // Loop through each group ID and fetch group details
  //       for (var groupId in groups) {
  //         final groupsResponse = await client?.callKw({
  //           'model': 'res.groups',
  //           'method': 'search_read',
  //           'args': [
  //             [
  //               ['id', '=', groupId],
  //               [
  //                 'name',
  //                 '=',
  //                 ['Beyond Worksheet Admin']
  //               ]
  //             ]
  //           ],
  //           'kwargs': {
  //             'fields': ['id', 'name'],
  //           },
  //         });
  //
  //         if (groupsResponse != null && groupsResponse.isNotEmpty) {
  //           print(groupsResponse);
  //           print("Fetched group details");
  //           setState(() {
  //             isAdmin = true;
  //           });
  //         } else {
  //           print("No group details found for group ID: $groupId");
  //         }
  //       }
  //     } else {
  //       print("No employee details found for userId: $userId");
  //     }
  //   } catch (e) {
  //     print("Error fetching employee details: $e");
  //   }
  // }

  void _openQrCodeGenerationPopup(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 300,
                    height: 300,
                    child: Image.memory(
                      base64Decode(imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 2.0,
                top: 0.0,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Future<bool> checkQrForEmployee(int employeeValue, int worksheetId) async {
  //   try {
  //     final response = await client?.callKw({
  //       'model': 'attendance.qr',
  //       'method': 'search_read',
  //       'args': [
  //         [
  //           ['user_id', '=', employeeValue],
  //           ['worksheet_id', '=', worksheetId]
  //         ],
  //       ],
  //       'kwargs': {},
  //     });
  //     if (response != null &&
  //         response.isNotEmpty &&
  //         response[0]['qr_code'] != null) {
  //       return true;
  //     } else {
  //       return false;
  //     }
  //   } catch (e) {
  //     _errorMessage = "Error checking QR code for the employee.";
  //     return false;
  //   }
  // }
  //
  // Future<bool> generateQrFromOdoo(Map<String, dynamic> user) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   userId = prefs.getInt('userId') ?? 0;
  //   try {
  //     final response = await client?.callKw({
  //       'model': 'attendance.qr',
  //       'method': 'create',
  //       'args': [
  //         user,
  //       ],
  //       'kwargs': {},
  //     });
  //     if (response != null) {
  //       return true;
  //     } else {
  //       _errorMessage = "Something went wrong. Please try again later.";
  //       return false;
  //     }
  //   } catch (e) {
  //     _errorMessage = "Something went wrong. Please try again later.";
  //     return false;
  //   }
  // }
  //
  // Future<String> fetchQrCodeFromOdoo(int employeeValue, int worksheetId) async {
  //   try {
  //     final response = await client?.callKw({
  //       'model': 'attendance.qr',
  //       'method': 'search_read',
  //       'args': [
  //         [
  //           ['user_id', '=', employeeValue],
  //           ['worksheet_id', '=', worksheetId]
  //         ],
  //       ],
  //       'kwargs': {},
  //     });
  //     if (response != null && response.isNotEmpty) {
  //       return response[0]['qr_code'] ?? '';
  //     } else {
  //       return '';
  //     }
  //   } catch (e) {
  //     _errorMessage = "Something went wrong while fetching the QR code.";
  //     return '';
  //   }
  // }

  Future<bool> _onWillPop() async {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
        (route) => false);
    // _controller.index = -1;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    bool checkin = false;
    bool mid = false;
    bool checkout = false;
    print(SharedState.progressData);
    print("SharedState.progressChangdddddddddddd");
    if (SharedState.progressData.isNotEmpty) {
      if (worksheetId == SharedState.progressData['worksheetId']) {
        progressChange = SharedState.progressData['progressChange'];
        isStartjob = SharedState.progressData['isStartjob'];
      }
    }
    print(CheckinRequired);
    print(MidRequired);
    print(CheckoutRequired);
    print(scannedTotalCount);
    print(totalBarcodeCount);
    print(checklist_total_count);
    // print(isStartjob);
    print("checklistCurrentCountchecklistCurrentCountdddddddddddddddd");
    if (CheckinRequired) {
      checkin = true;
    }
    if (MidRequired) {
      mid = true;
    }
    if (CheckoutRequired) {
      checkout = true;
    }
    bool? canFinishJob;
    if (isNetworkAvailable)
      canFinishJob = true;
    else
      canFinishJob = true;

    if (checkin) {
      canFinishJob = canFinishJob &&
          (scannedTotalCount >= totalBarcodeCount) &&
          (checklist_total_count <= checklistCurrentCount);
    }

    if (mid) {
      canFinishJob = canFinishJob &&
          (scannedTotalCount >= totalBarcodeCount) &&
          (checklist_total_count <= checklistCurrentCount);
    }

    if (checkout) {
      canFinishJob = canFinishJob &&
          (scannedTotalCount >= totalBarcodeCount) &&
          (checklist_total_count <= checklistCurrentCount);
    }

    if (!checkin && !mid && !checkout) {
      canFinishJob = canFinishJob &&
          (scannedTotalCount >= totalBarcodeCount) &&
          (checklist_total_count <= checklistCurrentCount);
    }

    print("canFinishJobcanFinishJobcanFinishJob$canFinishJob");

    final Phone = args['partner_phone'];
    final phoneValue = (Phone is String) ? Phone : '';
    final Email = args['partner_email'];
    final emailValue = (Email is String) ? Email : '';
    final addressValue = args['x_studio_site_address_1'];
    final status = args['install_status'];

    return WillPopScope(
      onWillPop: () async {
        setState(() {
          args['reloadInstalling']?.call();
        });
        _onWillPop();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    args['name'],
                    style: TextStyle(
                      fontSize: responsiveFontSize(context, 24.0, 22.0),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (isQrVisible)
              IconButton(
                icon: Icon(
                  Icons.qr_code,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await createQr(worksheetId!);
                },
              ),
          ],
          backgroundColor: Colors.green,
          automaticallyImplyLeading: false,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        body: Stack(
          children: [
            Opacity(
              // opacity: progressChange == true ? 0.3 : 1.0,
              opacity: isStartjob ? 1.0 : 0.3,
              child: SingleChildScrollView(
                child: Container(
                  color: Colors.green,
                  child: Padding(
                    padding: EdgeInsets.all(responsivePadding(context)),
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                // Curved top-left corner
                                topRight: Radius.circular(
                                    20), // Curved top-right corner
                              ),
                            ),
                            width: screenSize.width,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // _buildResidentialArea(),
                                if (addressValue is String &&
                                    addressValue.isNotEmpty)
                                  _buildSubHeader(context, addressValue)
                                else if (addressValue is bool)
                                  SizedBox(
                                    height: 10,
                                  ),
                                _buildLocationSection(context, screenSize),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("System Information",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          _buildSystemInfoCard(context),
                          SizedBox(
                            height: 10,
                          ),
                          _buildSelfieSection(context),
                          SizedBox(height: 16.0),
                          if (ccewDocumet != null) ...[
                            Text(
                              "Certificates",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            // if (derRecieptDocumet == null &&
                            //     ccewDocumet == null &&
                            //     stcDocumet == null &&
                            //     solarPanelDocumet == null &&
                            //     switchBoardDocumet == null &&
                            //     inverterLocationDocumet == null &&
                            //     batteryLocationDocument == null) ...[
                            // if (ccewDocumet == null) ...[
                            //   Center(
                            //       child: Text(
                            //     "No documents available",
                            //     style: TextStyle(
                            //         fontSize: 18.0,
                            //         color: Colors.grey[600],
                            //         fontWeight: FontWeight.bold),
                            //   )),
                            // ] else ...[
                            // if (derRecieptDocumet != null)
                            //   _buildPdfCertificateTile(
                            //     context,
                            //     "DER Receipt",
                            //     derRecieptDocumet,
                            //   ),
                            if (ccewDocumet != null)
                              _buildPdfCertificateTile(
                                context,
                                "CCEW Document",
                                ccewDocumet,
                              ),
                            // if (stcDocumet != null)
                            //   _buildPdfCertificateTile(
                            //     context,
                            //     "STC Document",
                            //     stcDocumet,
                            //   ),
                            // if (solarPanelDocumet != null)
                            //   _buildImageCertificateTile(
                            //     context,
                            //     "Solar Panel Layout",
                            //     solarPanelDocumet,
                            //   ),
                            // if (switchBoardDocumet != null)
                            //   _buildImageCertificateTile(
                            //     context,
                            //     "Switch Board Photo",
                            //     switchBoardDocumet,
                            //   ),
                            // if (inverterLocationDocumet != null)
                            //   _buildImageCertificateTile(
                            //     context,
                            //     "Inverter Location Photo",
                            //     inverterLocationDocumet,
                            //   ),
                            // if (batteryLocationDocument != null)
                            //   _buildImageCertificateTile(
                            //     context,
                            //     "Battery Location Photo",
                            //     batteryLocationDocument,
                            //   ),
                          ],
                          SizedBox(height: 16.0),
                          Text("Signatures",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          ListTile(
                              leading: Icon(
                                Icons.person,
                                color: Colors.green,
                              ),
                              title: Text(
                                "Installer & Designer",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      installerSignatureImage != null
                                          ? "Doc Submitted by $installerName"
                                          : "Not Submitted",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                  // Expanded(
                                  //   child: Text(
                                  //     installerSignatureImage != null
                                  //         ? "Doc Submitted by $installerName & $witnessName"
                                  //         : "Not Submitted",
                                  //     style: TextStyle(color: Colors.grey),
                                  //   ),
                                  // ),
                                  if (installerSignatureImage != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Done',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              // onTap: () async {
                              //   var box = await Hive.openBox<SignatureData>(
                              //       'signatureBox');
                              //   SignatureData? existingSignature = box.values
                              //       .cast<SignatureData?>()
                              //       .firstWhere(
                              //         (signatureData) =>
                              //             signatureData?.id == projectId,
                              //         orElse: () => null,
                              //       );
                              //   if (existingSignature != null) {
                              //     ScaffoldMessenger.of(context).showSnackBar(
                              //       SnackBar(
                              //         content: Text(
                              //             "You have already uploaded installer signature for this project."),
                              //         backgroundColor: Colors.red,
                              //       ),
                              //     );
                              //   } else {
                              //     if (status_done != 'done') {
                              //       if (progressChange == false) {
                              //         _showSignaturePopup(
                              //             projectId!, 'Installer & Designer',
                              //             (signature, witnessSignature, name) {
                              //           setState(() {
                              //             installerSignature = signature;
                              //           });
                              //         }, installerSignatureImageBytes,
                              //             installerName, installerDate);
                              //       }
                              //     }
                              //   }
                              // }
                              onTap: () async {
                                print(installerDate);
                                print(
                                    "installerDateinstallerDateinstallerDate");
                                try {
                                  SignatureData? existingSignature;

                                  if (!isNetworkAvailable) {
                                    var box = await Hive.openBox<SignatureData>(
                                        'signatureBox');
                                    existingSignature = box.values
                                        .cast<SignatureData?>()
                                        .firstWhere(
                                          (signatureData) =>
                                              signatureData?.id == projectId,
                                          orElse: () => null,
                                        );
                                  }
                                  print(
                                      "existingSignatureexistingSignature$existingSignature");
                                  if (existingSignature != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            "You have already uploaded installer signature for this project."),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } else {
                                    if (status_done != 'done') {
                                      if (progressChange == false) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SignatureScreen(
                                              onSignatureSubmitted:
                                                  (installSignature,
                                                      witnessSignature, name) {
                                                witnessName = name;
                                                // onSignatureSubmitted(installSignature, witnessSignature, name);
                                                editSignatureDetails(
                                                    installSignature,
                                                    witnessSignature,
                                                    name);
                                                // Navigator.pop(context);
                                                Navigator.pop(context);
                                                if (!isNetworkAvailable)
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'Network unavailable. Image saved for later upload.'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                              },
                                              existingName: installerName ?? '',
                                              existingSignature:
                                                  installerSignatureImageBytes,
                                              title: 'Installer & Designer',
                                              projectId: projectId!,
                                              installDate: installerDate,
                                            ),
                                          ),
                                        );
                                        // _showSignaturePopup(
                                        //     projectId!, 'Installer & Designer',
                                        //     (signature, witnessSignature, name) {
                                        //   setState(() {
                                        //     installerSignature = signature;
                                        //   });
                                        // }, installerSignatureImageBytes,
                                        //     installerName, installerDate);
                                      }
                                    }
                                  }
                                } catch (error) {
                                  print('error in catchea $error');
                                }
                              }),
                          ListTile(
                            leading: Icon(
                              Icons.person,
                              color: Colors.green,
                            ),
                            title: Text(
                              "Owner",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ownerSignatureImage != null
                                        ? "Doc Submitted by $ownerName"
                                        : "Not Submitted",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                if (ownerSignatureImage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Done',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () async {
                              OwnerSignatureEditData? existingSignature;
                              if (!isNetworkAvailable) {
                                var box =
                                    await Hive.openBox<OwnerSignatureEditData>(
                                        'ownerSignatureEditBox');
                                existingSignature = box.values
                                    .cast<OwnerSignatureEditData?>()
                                    .firstWhere(
                                      (signatureData) =>
                                          signatureData?.id == projectId,
                                      orElse: () => null,
                                    );
                              }
                              if (existingSignature != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "You have already uploaded owner signature for this project."),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else {
                                if (status_done != 'done') {
                                  if (progressChange == false) {
                                    _showOwnerSendPopup(context);
                                  }
                                }
                              }
                            },
                          ),
                          SizedBox(height: 16.0),
                          Text("Attachments",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          buildDocumentSection(),
                          if (worksheetId != null) SizedBox(height: 16.0),
                          // Text("CCEW",
                          //     style: TextStyle(
                          //         fontSize: 18, fontWeight: FontWeight.bold)),
                          // SizedBox(height: 10.0),
                          // GestureDetector(
                          //   onTap: () async {
                          //     if (!isNetworkAvailable) {
                          //       ScaffoldMessenger.of(context).showSnackBar(
                          //         SnackBar(
                          //           content: Text('Please check your network'),
                          //           backgroundColor: Colors.red,
                          //           duration: Duration(seconds: 2),
                          //         ),
                          //       );
                          //     } else {
                          //       await createCCEW(worksheetId!);
                          //       await fetchAndDownloadCCEW(worksheetId!);
                          //     }
                          //   },
                          //   child: Container(
                          //     padding: EdgeInsets.all(16.0),
                          //     decoration: BoxDecoration(
                          //       color: Colors.green.withOpacity(0.5),
                          //       borderRadius: BorderRadius.circular(8.0),
                          //     ),
                          //     child: Row(
                          //       mainAxisAlignment:
                          //           MainAxisAlignment.spaceBetween,
                          //       children: [
                          //         Text("CCEW Document",
                          //             style: TextStyle(
                          //                 color: Colors.white,
                          //                 fontWeight: FontWeight.bold,
                          //                 fontSize: 18)),
                          //         Icon(Icons.file_download,
                          //             color: Colors.white),
                          //       ],
                          //     ),
                          //   ),
                          // ),
                          // SizedBox(height: screenSize.height * 0.02),
                          // LayoutBuilder(
                          //   builder: (context, constraints) {
                          //     double screenWidth =
                          //         MediaQuery.of(context).size.width;
                          //     double screenHeight =
                          //         MediaQuery.of(context).size.height;
                          //     double containerHeight = phoneValue.length > 14 ||
                          //             emailValue.length > 14
                          //         ? screenHeight * 0.1
                          //         : screenHeight * 0.04;
                          //
                          //     return Container(
                          //       width: screenWidth,
                          //       height: containerHeight,
                          //       child: Row(
                          //         crossAxisAlignment: CrossAxisAlignment.center,
                          //         mainAxisAlignment:
                          //             MainAxisAlignment.spaceEvenly,
                          //         children: [
                          //           if (phoneValue.isNotEmpty)
                          //             GestureDetector(
                          //               onTap: () => _launchPhone(Phone),
                          //               child: Container(
                          //                 width: screenWidth * 0.4,
                          //                 child: Row(
                          //                   mainAxisAlignment:
                          //                       MainAxisAlignment.center,
                          //                   children: [
                          //                     Icon(Icons.phone,
                          //                         color: Colors.green),
                          //                     SizedBox(width: 8),
                          //                     Flexible(
                          //                       child: Text(
                          //                         Phone,
                          //                         style: TextStyle(
                          //                           fontWeight: FontWeight.bold,
                          //                           color: Colors.green,
                          //                           decoration: TextDecoration
                          //                               .underline,
                          //                         ),
                          //                         overflow:
                          //                             TextOverflow.visible,
                          //                       ),
                          //                     ),
                          //                   ],
                          //                 ),
                          //               ),
                          //             ),
                          //           SizedBox(height: 10),
                          //           if (emailValue.isNotEmpty)
                          //             GestureDetector(
                          //               onTap: () => _launchEmail(Email),
                          //               child: Container(
                          //                 width: screenWidth * 0.4,
                          //                 child: Row(
                          //                   mainAxisAlignment:
                          //                       MainAxisAlignment.center,
                          //                   children: [
                          //                     Icon(Icons.email,
                          //                         color: Colors.green),
                          //                     SizedBox(width: 8),
                          //                     Flexible(
                          //                       child: Text(
                          //                         Email,
                          //                         style: TextStyle(
                          //                           fontWeight: FontWeight.bold,
                          //                           color: Colors.green,
                          //                           decoration: TextDecoration
                          //                               .underline,
                          //                         ),
                          //                         overflow:
                          //                             TextOverflow.visible,
                          //                       ),
                          //                     ),
                          //                   ],
                          //                 ),
                          //               ),
                          //             ),
                          //         ],
                          //       ),
                          //     );
                          //   },
                          // ),
                          SizedBox(height: 20),
                          if (status != 'done' && !finishJobStatus)
                            ElevatedButton(
                              onPressed: canFinishJob
                                  ? () {
                                      _finishPopup(context);
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 50),
                                backgroundColor:
                                    canFinishJob ? Colors.green : Colors.grey,
                              ),
                              child: Text(
                                'Finish Job',
                                style: TextStyle(
                                  fontSize: 18,
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
              ),
            ),
            // if (progressChange == true)
            if (!isStartjob)
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    print(
                        "checklistTypeschecklistTypescccccchecklistTypes$checklistTypes");
                    if (checklistTypes.contains('check_in')) {
                      print(team_member_ids);
                      print("team_member_idsteam_member_ids");
                      selectedDetails.clear();
                      hazardResponses.clear();
                      showRiskAssessmentDialog(context);
                      setState(() {});
                      // if (team_member_ids.isNotEmpty) {
                      //   selectedDetails.clear();
                      //   hazardResponses.clear();
                      //   showRiskAssessmentDialog(context);
                      //   setState(() {});
                      // }
                      // else {
                      //   String checklistType = 'check_in';
                      //   bool result = await _getFromCamera(checklistType);
                      //   print("resultresultresultresult$result");
                      //   if (result) {
                      //     setState(() {
                      //       _startController(projectId);
                      //     });
                      //   }
                      //   setState(() {
                      //     isImageLoading = false;
                      //   });
                      //   // setState(() {
                      //   //   _startController(projectId);
                      //   // });
                      // }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.white),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Info",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      "The Check In selfie type is not added Please contact your admin to add it.",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(150, 50),
                    backgroundColor: Colors.green,
                  ),
                  child: Text(
                    'Start',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String formatDisplayText(String text) {
    return text
        .replaceAll('_', ' ') // Replace underscores with spaces
        .toUpperCase(); // Capitalize the text
  }

  void showRiskAssessmentDialog(BuildContext context) {
    selectedCheckboxes = {
      for (var item in allowedTypes) item: false,
    };
    selectedRiskItemCheckboxes = {
      for (var item in allowedRiskTypes) item: false,
    };
    dropdownValues = {
      for (var item in allowedTypes) item: null,
    };
    dropdownRiskItemsValues = {
      for (var item in allowedRiskTypes) item: null,
    };
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RiskAssessmentPage(
            args: globalArgs,
            allowedTypes: allowedTypes,
            selectedDetails: selectedDetails,
            worksheetId: worksheetId!,
            memberId: memberId!,
            categIdList: categIdList,
            workTypeIdList: workTypeIdList,
            projectId: projectId!,
            selectedCheckboxes: selectedCheckboxes,
            selectedRiskItemCheckboxes: selectedRiskItemCheckboxes,
            dropdownValues: dropdownValues,
            dropdownRiskItemsValues: dropdownRiskItemsValues,
            specificTaskDetails: specificTaskDetails,
            team_member_ids: team_member_ids,
            hazardResponses: hazardResponses),
      ),
    );
  }

  String capitalizeFirstLetter(String input) {
    if (input == null || input.isEmpty) {
      return input;
    }
    return input.split('_').map((word) {
      return word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '';
    }).join('');
  }


  Future<void> uploadTaskRiskResponse(
      List<Map<String, dynamic>> selectedDetails) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;

    print("$worksheetId / worksheetIdworksheetIdworksheetIdworksheetId");
    print("$selectedDetails / seddddddddddddddddlectedDetails");

    Map<String, List<int>> mappedData = {
      'cranes_ids': [],
      'hoists_ids': [],
      'scaffolding_ids': [],
      'dogging_rigging_ids': [],
      'forklift_ids': [],
    };

    for (var detail in selectedDetails) {
      print(detail);
      print(
          "detaildetaildetaildetaildetaildetaildetaildetaildetaildetaildetail");
      final type = detail['value'];
      print(type);
      if (type == null) continue;

      final swmslist = await client?.callKw({
        'model': 'swms.risk.work',
        'method': 'search_read',
        'args': [
          [
            ['type', '=', type],
          ]
        ],
        'kwargs': {},
      });

      if (swmslist != null) {
        print("Checklist for $type: $swmslist");

        List<int> ids = [];
        for (var item in swmslist) {
          if (item.containsKey('id')) {
            ids.add(item['id']);
          }
        }

        if (type == 'cranes') {
          mappedData['cranes_ids']?.addAll(ids);
        } else if (type == 'hoists') {
          mappedData['hoists_ids']?.addAll(ids);
        } else if (type == 'scaffolding') {
          mappedData['scaffolding_ids']?.addAll(ids);
        } else if (type == 'dogging_rigging') {
          mappedData['dogging_rigging_ids']?.addAll(ids);
        } else if (type == 'forklift') {
          mappedData['forklift_ids']?.addAll(ids);
        }
      }
    }

    mappedData.removeWhere((key, value) => value.isEmpty);

    try {
      final response = await client?.callKw({
        'model': 'task.worksheet',
        'method': 'write',
        'args': [
          [worksheetId],
          mappedData
        ],
        'kwargs': {},
      });

      if (response == true) {
        print("Update successful");
      } else {
        print("Update failed");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> loadSelectedRiskItems() async {
    print("$selectedDetails/sdfgggggggggggggggggggggggggggggggggggggggggg");
    final selectedTypes = selectedDetails.map((item) => item['value']).toList();

    final swmslist = await client?.callKw({
      'model': 'swms.risk.work',
      'method': 'search_read',
      'args': [
        [
          ['type', 'in', selectedTypes],
        ]
      ],
      'kwargs': {},
    });
    print(swmslist);
    print("swmslistswmslisteeeeeeeeeeeeeeeee");
    if (swmslist != null) {
      swmsDetails = swmslist.map<Map<String, dynamic>>((item) {
        return {'name': item['name'] ?? 'N/A', 'type': item['type'] ?? 'N/A'};
      }).toList();
      print(swmslist);
      print("ffffffffffffffffkkkkkkkkkkkkk");
    }
  }

  // Future<void> uploadHazardResponse(
  //     List<Map<String, dynamic>> responses) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final userId = prefs.getInt('userId') ?? 0;
  //   print("$team_member_ids / wodddddddddrksheetIdworksheetIdworksheetId");
  //   print("$responses / responses");
  //   for (var memberId in team_member_ids) {
  //     List<Map<String, dynamic>> createData = responses.map((response) {
  //       return {
  //         'installation_question_id': response['id'],
  //         'team_member_input': response['response'] == 'Yes'
  //             ? 'yes'
  //             : response['response'] == 'No'
  //                 ? 'no'
  //                 : response['response'],
  //         'worksheet_id': worksheetId,
  //         'member_id': memberId
  //       };
  //     }).toList();
  //
  //     try {
  //       final response = await client?.callKw({
  //         'model': 'swms.team.member.input',
  //         'method': 'create',
  //         'args': [createData],
  //         'kwargs': {},
  //       });
  //
  //       if (response != null) {
  //         print("Hazard responses uploaded successfully");
  //         success = true;
  //       } else {
  //         print("Failed to upload hazard responses");
  //       }
  //     } catch (e) {
  //       print("Error: $e");
  //     }
  //   }
  // }

  Future<void> uploadHazardResponse(
      List<Map<String, dynamic>> responses) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    print("$team_member_ids / wodddddddddrksheetIdworksheetIdworksheetId");
    print("$responses / responses");

    for (var memberId in team_member_ids) {
      List<Map<String, dynamic>> createData = responses.map((response) {
        return {
          'installation_question_id': response['id'],
          'team_member_input': response['response'] == 'Yes'
              ? 'yes'
              : response['response'] == 'No'
                  ? 'no'
                  : response['response'],
          'worksheet_id': worksheetId,
          'member_id': memberId
        };
      }).toList();

      for (var data in createData) {
        try {
          // final checkResponse = await client?.callKw({
          //   'model': 'swms.team.member.input',
          //   'method': 'search_read',
          //   'args': [
          //     [
          //       [
          //         'installation_question_id',
          //         '=',
          //         data['installation_question_id']
          //       ],
          //       ['worksheet_id', '=', data['worksheet_id']]
          //     ],
          //     ['id'] // Only fetch the 'id' to check existence
          //   ],
          //   'kwargs': {},
          // });
          final Uri url = Uri.parse('$baseUrl/rebates/swms_team_member_input');
          final checkResponse = await http.post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "jsonrpc": "2.0",
              "method": "call",
              "params": {
                "worksheetId": data['worksheet_id'],
                "installationQuestionId": data['installation_question_id']
              }
            }),
          );
          final Map<String, dynamic> jsonCheckResponseResponse = json.decode(checkResponse.body);

          // if (checkResponse != null && checkResponse.isNotEmpty) {
            // If a matching record exists, update it
          if (jsonCheckResponseResponse['result']['status'] == 'success' &&
              jsonCheckResponseResponse['result']['swms_team_member_input'].isNotEmpty) {
            final existingRecordId = jsonCheckResponseResponse['result']['swms_team_member_input'][0]['id'];
            // final updateResponse = await client?.callKw({
            //   'model': 'swms.team.member.input',
            //   'method': 'write', // Update the existing record
            //   'args': [
            //     existingRecordId,
            //     {
            //       'team_member_input': data['team_member_input'],
            //     }
            //   ],
            //   'kwargs': {},
            // });
            final Uri url = Uri.parse('$baseUrl/rebates/swms_team_member_input/write');
            final updateResponse = await http.post(
              url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "jsonrpc": "2.0",
                "method": "call",
                "params": {
                  "input_id": existingRecordId,
                  "team_member_input": data['team_member_input'],
                }
              }),
            );
            final Map<String, dynamic> jsonUpdateResponseResponse = json.decode(updateResponse.body);
            // if (updateResponse != null) {
            if (jsonUpdateResponseResponse['result']['status'] == 'success') {
              print("Hazard response updated successfully");
              success = true;
            } else {
              print("Failed to update hazard response");
            }
          } else {
            // final createResponse = await client?.callKw({
            //   'model': 'swms.team.member.input',
            //   'method': 'create',
            //   'args': [data],
            //   'kwargs': {},
            // });
            final Uri url = Uri.parse('$baseUrl/rebates/swms_team_member_input/create');
            final createResponse = await http.post(
              url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "jsonrpc": "2.0",
                "method": "call",
                "params": data
              }),
            );
            final Map<String, dynamic> jsonCreateResponseeResponse = json.decode(createResponse.body);
            // if (updateResponse != null) {
            if (jsonCreateResponseeResponse['result']['status'] == 'success') {

              // if (createResponse != null) {
              print("Hazard response created successfully");
              success = true;
            } else {
              print("Failed to create hazard response");
            }
          }
        } catch (e) {
          print("Error: $e");
        }
      }
    }
  }

  Future<void> _startController(taskId) async {
    print("vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv");
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    final String formattedDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    if (!isNetworkAvailable) {
      await _saveStartToHive(taskId, formattedDate);
      setState(() {
        progressChange = false;
        isStartjob = true;
        isQrVisible = true;
      });
    } else {
      try {
        final response = await client?.callKw({
          'model': 'project.task',
          'method': 'write',
          'args': [
            [taskId],
            {
              'install_status': 'progress',
              'date_worksheet_start':
                  DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())
            }
          ],
          'kwargs': {},
        });
        print(response);
        print("responseresponseresponse");
        if (response == true) {
          setState(() {
            progressChange = false;
            isStartjob = true;
          });
          final box = await Hive.openBox<InstallingJob>('installationListBox');
          final installJob = box.get(taskId);

          if (installJob != null) {
            final updatedServiceJob =
                installJob.copyWith(install_status: 'progress');
            await box.put(taskId, updatedServiceJob);
          }
        } else {}
      } catch (e) {}
    }
  }

  Future<void> _saveStartToHive(int taskId, String date) async {
    final box = await Hive.openBox<TaskJob>('taskJobsBox');
    try {
      final taskJob = TaskJob(taskId: taskId, date: date);

      await box.add(taskJob);
      print('TaskJob saved successfully!');
    } catch (e) {
      print('Error saving TaskJob to Hive: $e');
    } finally {
      await box.close();
    }
  }

  void _showOwnerSendPopup(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Please select a signature mode",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.app_registration, color: Colors.blue),
                title: Text("Sign in APP"),
                onTap: () {
                  {
                    if (progressChange == false) {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OwnerSignature(
                              onSignatureSubmitted: (signature, name) {
                                // onSignatureSubmitted(signature, name);
                                // if (title == 'Owner')
                                editOwnerSignatureDetails(signature, name);
                                // if (title == 'Owner') editOwnerSignatureName(name);
                                Navigator.pop(context);
                                if (!isNetworkAvailable)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Network unavailable. Image saved for later upload.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                              },
                              existingName: ownerName ?? '',
                              existingSignature: ownerSignatureImageBytes,
                              title: "Owner",
                              projectId: projectId!,
                              customerDate: customerDate),
                        ),
                      );
                      // _showOwnerSignaturePopup(projectId!, 'Owner',
                      //     (signature, name) {
                      //   setState(() {
                      //     ownerSignature = signature;
                      //   });
                      // }, ownerSignatureImageBytes, ownerName, customerDate);
                    }
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.sms, color: Colors.green),
                title: Text("Send by SMS"),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  String url = prefs.getString('url') ?? '';
                  String content = '$url/my/task/${projectId}/signature';
                  Share.share('Check out this link to sign: $content');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildDocumentSection() {
    var screenSize = MediaQuery.of(context).size;
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 70.0,
          width: double.infinity,
          color: Colors.white,
        ),
      );
    } else {
      return Column(
        children: [
          ListTile(
            leading: Icon(Icons.attachment, color: Colors.green),
            title: Text("Other Documents",
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Eg. JSA, invoices, reports, etc.",
                style: TextStyle(color: Colors.grey)),
            trailing: Icon(Icons.file_upload_outlined),
            onTap: () {
              if (progressChange == false) {
                if (!isNetworkAvailable) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please check your network'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  if (status_done != 'done') {
                    if (progressChange == false) {
                      _pickFile();
                    }
                  }
                }
              }
            },
          ),
          if (isUploadLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            )
          else if (attachments_append.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: attachments_append.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> attachment = entry.value;
                  String fileName = attachment['name'];
                  print("fffffffffffffilename$fileName");
                  String documentBase64 = attachment['datas'] ?? '';
                  return Visibility(
                    visible: documentBase64.isNotEmpty,
                    child: Container(
                      height: screenSize.height * 0.04,
                      child: Row(
                        children: [
                          Icon(Icons.insert_drive_file,
                              color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                if (documentBase64.isNotEmpty) {
                                  final documentData =
                                      base64Decode(documentBase64);
                                  final directory =
                                      await getApplicationDocumentsDirectory();
                                  final filePath =
                                      '${directory.path}/$fileName';
                                  final file = File(filePath);
                                  await file.writeAsBytes(documentData);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FileViewer(filePath: filePath),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                fileName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          // Visibility(
                          //   visible: isNetworkAvailable && isAdmin,
                          //   child: IconButton(
                          //     icon: Icon(Icons.close,
                          //         color: Colors.red, size: 15),
                          //     onPressed: () {
                          //       setState(() {
                          //         deleteAttachments(attachment['id'], fileName);
                          //         attachments_append.removeAt(index);
                          //       });
                          //     },
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      );
    }
  }

  void _finishPopup(BuildContext context) async {
    bool isCheckInImageSubmitted =
        CheckInImagePath != null && CheckInImagePath.isNotEmpty;
    bool isMidImageSubmitted = MidImagePath != null && MidImagePath.isNotEmpty;
    bool isCheckOutImageSubmitted =
        CheckOutImagePath != null && CheckOutImagePath.isNotEmpty;
    if (categIdList.isNotEmpty) if (!isCheckInImageSubmitted ||
        !isMidImageSubmitted ||
        !isCheckOutImageSubmitted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "On Site Selfies Required",
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
              height: MediaQuery.of(context).size.height * 0.15,
              width: MediaQuery.of(context).size.width * 0.95,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 15,
                    ),
                    Text(
                      "Please ensure that the check-in, mid, and end selfies are submitted before finishing the job.",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      );
      return;
    }
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Stack(
              children: [
                AlertDialog(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Finish Job",
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
                    height: MediaQuery.of(context).size.height * 0.09,
                    width: MediaQuery.of(context).size.width * 0.95,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 15,
                          ),
                          Text(
                            "Are you sure you want to Finish the Job?",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          )
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            _isfinishLoading = true;
                            var box = await Hive.openBox('finishJob');
                            await box.put(
                              'finishInstallingJob',
                              {
                                'projectId': projectId,
                              },
                            );
                            await finishJob(projectId!);
                            setState(() {
                              finishJobStatus = true;
                              _isfinishLoading = false;
                            });
                            Navigator.of(context).pop(true);
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.green),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          child: _isfinishLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "CONTINUE",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                        )),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> finishJob(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    if (!isNetworkAvailable) {
      await _saveFinishJobToHive(id);
      setState(() {
        finishJobStatus = true;
        _isfinishLoading = false;
      });
    } else {
      try {
        final response = await client?.callKw({
          'model': 'project.task',
          'method': 'write',
          'args': [
            [projectId],
            {'install_status': 'done'}
          ],
          'kwargs': {},
        });
        if (response == true) {
          setState(() {});
        } else {}
      } catch (e) {}
    }
  }

  Future<void> _saveFinishJobToHive(int taskId) async {
    var box = await Hive.openBox<FinishJob>('finishJobsBox');
    try {
      FinishJob finishJob = FinishJob(taskId: taskId, installStatus: 'done');

      await box.put(taskId, finishJob);

      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('lastSavedTaskId', taskId);
    } catch (e) {
      print('Error saving TaskJob to Hive: $e');
    } finally {
      await box.close();
    }
  }

  Future<void> createCCEW(int id) async {
    print("$id/444444444444444444444444444444444444");
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    try {
      final response = await client?.callKw({
        'model': 'task.worksheet',
        'method': 'action_create_ccew',
        'args': [
          [id]
        ],
        'kwargs': {},
      });
      print("Response Type: ${response.runtimeType}");
      print("Response Data: $response");
      if (response == true) {
        setState(() {});
      } else {}
    } catch (e) {
      print("rrrrrrrrrrrrrrrrrr4444444444444$e");
    }
  }

  Future<void> createQr(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;

    final existingQrCode = await readQrCode(id);

    if (existingQrCode != null) {
      _openQrCodeGenerationPopup(context, existingQrCode);
    } else {
      try {
        final Uri url = Uri.parse('$baseUrl/rebates/generate_qr_code');
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "worksheet_id": id
            }
          }),
        );
        final Map<String, dynamic> jsonGenerateQrResponse = json.decode(response.body);
        // if (response == true) {
        print("77777777777&&&&&&&&&&&&&&&&7jsonGenerateQrResponse$jsonGenerateQrResponse");
        if (jsonGenerateQrResponse['result']['status'] == 'success') {
          final newQrCode = await readQrCode(id);
          print(newQrCode);
          print("newQrCodenewQrCodenewQrCoded");
          if (newQrCode != null) {
            _openQrCodeGenerationPopup(context, newQrCode);
          } else {}
        } else {}
      } catch (e) {}
    }
  }

  Future<String?> readQrCode(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('url') ?? 0;
    if (!isNetworkAvailable) {
      final offlineQrCode = await _readQrCodeFromHive(id);
      return offlineQrCode;
    }
    try {
      // final response = await client?.callKw({
      //   'model': 'task.worksheet',
      //   'method': 'read',
      //   'args': [
      //     [id]
      //   ],
      //   'kwargs': {
      //     'fields': ['qr_code'],
      //   },
      // });
      final Uri url = Uri.parse('$baseUrl/rebates/task_worksheet');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "worksheet_id": id
          }
        }),
      );
      final Map<String, dynamic> jsonQrResponse = json.decode(response.body);
      print(jsonQrResponse);
      print("jsonQrResponsejsonQrResponse");
      if (jsonQrResponse['result']['status'] == 'success' && jsonQrResponse['result']['worksheet_data'].isNotEmpty) {
        // if (response != null && response.isNotEmpty) {
        String? qrCode = jsonQrResponse['result']['worksheet_data'][0]['qr_code'] as String?;
        if (qrCode != null) {
          await _saveQrCodeToHive(id, qrCode);
        }
        return qrCode;
      }
    } catch (e) {}
    return null;
  }

  Future<void> _saveQrCodeToHive(int id, String qrCode) async {
    final box = await Hive.openBox<Qr_Code>('qrCodes_$projectId');
    final qrCodeObject = Qr_Code(id: id, qrCode: qrCode);
    await box.put('qr_code_$id', qrCodeObject);
  }

  Future<String?> _readQrCodeFromHive(int id) async {
    final box = await Hive.openBox<Qr_Code>('qrCodes_$projectId');
    final qrCodeObject = box.get('qr_code_$id');
    return qrCodeObject?.qrCode;
  }

  Future<void> fetchAndDownloadCCEW(int worksheetId) async {
    try {
      var status = await Permission.storage.request();

      if (status.isGranted) {
        final response = await client?.callKw({
          'model': 'task.worksheet',
          'method': 'read',
          'args': [
            [worksheetId],
          ],
          'kwargs': {
            'fields': ['ccew_file'],
          },
        });

        if (response != null && response.isNotEmpty) {
          final ccewFileBase64 = response[0]['ccew_file'];

          if (ccewFileBase64 != null && ccewFileBase64.isNotEmpty) {
            final ccewFileBytes = base64Decode(ccewFileBase64);

            final downloadPath = Directory('/storage/emulated/0/Download');

            if (!await downloadPath.exists()) {
              await downloadPath.create(recursive: true);
            }

            final file =
                File('${downloadPath.path}/ccew_file_$worksheetId.pdf');

            await file.writeAsBytes(ccewFileBytes);

            await OpenFile.open(file.path);
          } else {}
        } else {}
      } else {}
    } catch (e) {}
  }

  // Widget _buildResidentialArea() {
  //   var screenSize = MediaQuery.of(context).size;
  //   double iconSize = screenSize.width * 0.08;
  //   double textFontSize = screenSize.width * 0.03;
  //   double containerWidth = screenSize.width * 0.28;
  //   IconData premisesIcon = Icons.home;
  //   String premisesName = 'Residential';
  //   switch (premises) {
  //     case 'Residential':
  //       premisesIcon = Icons.home;
  //       premisesName = 'Residential';
  //       break;
  //     case 'Commerical':
  //       premisesIcon = Icons.business;
  //       premisesName = 'Commercial';
  //       break;
  //     case 'Industrial':
  //       premisesIcon = Icons.factory;
  //       premisesName = 'Industrial';
  //       break;
  //     default:
  //       premisesIcon = Icons.person;
  //       premisesName = 'Owner Details';
  //   }
  //   String serviceType = 'New Installation';
  //   switch (serviceType) {
  //     case 'New Installation':
  //       serviceType = 'New Installation';
  //       break;
  //     case 'Replacement':
  //       serviceType = 'Replacement';
  //       break;
  //     case 'Service':
  //       serviceType = 'Service';
  //       break;
  //     default:
  //       serviceType = 'Unknown';
  //   }
  //   return Container(
  //     padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.04),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         GestureDetector(
  //           onTap: () async {
  //             if (progressChange == false) {
  //               final result = await Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => EditOwnerDetailsScreen(
  //                       premises: premisesName,
  //                       partner_items: partner_items,
  //                       project_id: projectId!),
  //                 ),
  //               );
  //               if (result == true) {
  //                 setState(() {
  //                   partner_items.clear();
  //                   getOwnerDetails();
  //                 });
  //               }
  //             }
  //           },
  //           child: Container(
  //             padding: EdgeInsets.symmetric(vertical: 10),
  //             decoration: BoxDecoration(
  //               color: Colors.grey.withOpacity(0.2),
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //             width: containerWidth,
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Container(
  //                   decoration: BoxDecoration(
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                   padding: EdgeInsets.only(top: 12.0, bottom: 5),
  //                   child:
  //                       Icon(premisesIcon, size: iconSize, color: Colors.green),
  //                 ),
  //                 SizedBox(height: 5),
  //                 Text(
  //                   premisesName,
  //                   style: TextStyle(
  //                     fontSize: textFontSize,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         // SizedBox(
  //         //   width: 20,
  //         // ),
  //         GestureDetector(
  //           onTap: () {
  //             if (progressChange == false) {
  //               Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                       builder: (context) => EditInstallationDetailsScreen(
  //                           serviceType: serviceType,
  //                           description: description)));
  //             }
  //           },
  //           child: Container(
  //             padding: EdgeInsets.symmetric(vertical: 10),
  //             decoration: BoxDecoration(
  //               color: Colors.grey.withOpacity(0.2),
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //             width: containerWidth,
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Container(
  //                   decoration: BoxDecoration(
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                   padding: EdgeInsets.only(top: 12.0, bottom: 5),
  //                   child: Icon(Icons.home_repair_service,
  //                       size: iconSize, color: Colors.blue),
  //                 ),
  //                 SizedBox(height: 5),
  //                 Text(
  //                   serviceType,
  //                   style: TextStyle(
  //                     fontSize: textFontSize,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         // SizedBox(
  //         //   width: 20,
  //         // ),
  //         GestureDetector(
  //           onTap: () {
  //             if (progressChange == false) {
  //               Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                       builder: (context) => WorksheetScreen(
  //                           project_id: projectId!)));
  //             }
  //           },
  //           child: Container(
  //             padding: EdgeInsets.symmetric(vertical: 10),
  //             decoration: BoxDecoration(
  //               color: Colors.grey.withOpacity(0.2),
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //             width: containerWidth,
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Container(
  //                   decoration: BoxDecoration(
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                   padding: EdgeInsets.only(top: 12.0, bottom: 5),
  //                   child: Icon(Icons.file_open,
  //                       size: iconSize, color: Colors.blue),
  //                 ),
  //                 SizedBox(height: 5),
  //                 Text(
  //                   "Documents",
  //                   style: TextStyle(
  //                     fontSize: textFontSize,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildResidentialArea() {
    var screenSize = MediaQuery.of(context).size;
    double iconSize = screenSize.width * 0.08;
    double textFontSize = screenSize.width * 0.03;
    double containerWidth = screenSize.width * 0.28;
    IconData premisesIcon = Icons.home;
    String premisesName = 'Residential';

    switch (premises) {
      case 'Residential':
        premisesIcon = Icons.home;
        premisesName = 'Residential';
        break;
      case 'Commerical':
        premisesIcon = Icons.business;
        premisesName = 'Commercial';
        break;
      case 'Industrial':
        premisesIcon = Icons.factory;
        premisesName = 'Industrial';
        break;
      default:
        premisesIcon = Icons.person;
        premisesName = 'Owner Details';
    }

    String serviceType = 'New Installation';
    switch (serviceType) {
      case 'New Installation':
        serviceType = 'New Installation';
        break;
      case 'Replacement':
        serviceType = 'Replacement';
        break;
      case 'Service':
        serviceType = 'Service';
        break;
      default:
        serviceType = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.04),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        // Adjusted to give space between containers
        children: [
          // Premises Container
          GestureDetector(
            onTap: () async {
              if (progressChange == false) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditOwnerDetailsScreen(
                        storeys: storeys,
                        wall_type: wall_type,
                        roof_type: roof_type,
                        meterBoxPhase: meterBoxPhase,
                        premises: premisesName,
                        partner_items: partner_items,
                        project_id: projectId!,
                        serviceType: serviceType,
                        description: description,
                        nmi: nmi,
                        installedOrNot: installedOrNot,
                        switchBoardUsed: switchBoardUsed,
                        expectedInverterLocation: expectedInverterLocation,
                        mountingWallType: mountingWallType,
                        inverterLocationNotes: inverterLocationNotes,
                        expectedBatteryLocation: expectedBatteryLocation,
                        mountingType: mountingType),
                  ),
                );
                if (result == true) {
                  setState(() {
                    partner_items.clear();
                    getOwnerDetails();
                  });
                }
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              width: containerWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.only(top: 12.0, bottom: 5),
                    child:
                        Icon(premisesIcon, size: iconSize, color: Colors.green),
                  ),
                  SizedBox(height: 5),
                  Text(
                    premisesName,
                    style: TextStyle(
                      fontSize: textFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Service Type Container
          GestureDetector(
            onTap: () {
              if (progressChange == false) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditInstallationDetailsScreen(
                      serviceType: serviceType,
                      description: description,
                      nmi: nmi,
                      installedOrNot: installedOrNot,
                    ),
                  ),
                );
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              width: containerWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.only(top: 12.0, bottom: 5),
                    child: Icon(Icons.home_repair_service,
                        size: iconSize, color: Colors.blue),
                  ),
                  SizedBox(height: 5),
                  Text(
                    serviceType,
                    style: TextStyle(
                      fontSize: textFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Documents Container
          GestureDetector(
            onTap: () {
              if (progressChange == false) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorksheetScreen(
                        project_id: projectId!,
                        switchBoardUsed: switchBoardUsed,
                        expectedInverterLocation: expectedInverterLocation,
                        mountingWallType: mountingWallType,
                        inverterLocationNotes: inverterLocationNotes,
                        expectedBatteryLocation: expectedBatteryLocation,
                        mountingType: mountingType),
                  ),
                );
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              width: containerWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.only(top: 12.0, bottom: 5),
                    child: Icon(Icons.file_open,
                        size: iconSize, color: Colors.blue),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Documents",
                    style: TextStyle(
                      fontSize: textFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfCertificateTile(
      BuildContext context, String title, MemoryImage? document) {
    return ListTile(
      leading: Icon(
        Icons.description,
        color: Colors.blueAccent,
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey,
        size: 15,
      ),
      onTap: () async {
        if (progressChange == false) {
          // fetchAndDownloadCCEW(worksheetId!);
          String? filePath = await downloadPdf(document);
          if (filePath != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PDFViewerPage(documentPath: filePath),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Document is not available')),
            );
          }
        }
      },
    );
  }

  Widget _buildImageCertificateTile(
      BuildContext context, String title, MemoryImage? document) {
    return ListTile(
      leading: Icon(
        Icons.description,
        color: Colors.blueAccent,
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey,
        size: 15,
      ),
      onTap: () async {
        if (progressChange == false) {
          String? filePath = await downloadImage(document);
          if (filePath != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageViewer(filePath: filePath),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Document is not available')),
            );
          }
        }
      },
    );
  }

  Future<String?> downloadPdf(MemoryImage? image) async {
    if (image == null) {
      return null;
    }
    final byteData = image.bytes;
    if (byteData == null) {
      return null;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/ccew_document_$worksheetId.pdf';
      print(filePath);
      print("filePathfilePathfilePath");
      final file = File(filePath);
      await file.writeAsBytes(byteData);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  Future<String?> downloadImage(MemoryImage? image) async {
    if (image == null) {
      return null;
    }
    final byteData = image.bytes;
    if (byteData == null) {
      return null;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();

      var uuid = Uuid();
      String uniqueId = uuid.v4();

      final filePath = '${directory.path}/document_$uniqueId.png';
      final file = File(filePath);
      await file.writeAsBytes(byteData);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  void _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  void _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch $email';
    }
  }

  Widget _buildSubHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: responsiveFontSize(context, 18.0, 16.0),
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              maxLines: null,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfieText(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 29.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: responsiveFontSize(context, 14.0, 16.0),
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  // Widget _buildLocationSection(BuildContext context, Size screenSize) {
  //   final args = ModalRoute.of(context)!.settings.arguments as Map;
  //   final partnerPhone = args['partner_phone'];
  //   final partnerEmail = args['partner_email'];
  //   final siteAddress = args['x_studio_site_address_1'];
  //   return Container(
  //     width: screenSize.width * 0.3,
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //       children: [
  //         if (partnerPhone != null && partnerPhone is String) ...[
  //           GestureDetector(
  //             onTap: () {
  //               if (progressChange == false) {
  //                 launch("tel:$partnerPhone");
  //               }
  //             },
  //             child: _buildIconWithLabel(context, Icons.phone, ''),
  //           ),
  //         ] else ...[
  //           GestureDetector(
  //             onTap: () {
  //               if (progressChange == false) {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(
  //                     content: Text('Phone number is not available'),
  //                     backgroundColor: Colors.red,
  //                   ),
  //                 );
  //               }
  //             },
  //             child: Icon(
  //               Icons.phone,
  //               color: Colors.grey,
  //             ),
  //           ),
  //         ],
  //         if (partnerEmail != null && partnerEmail is String) ...[
  //           GestureDetector(
  //             onTap: () {
  //               if (progressChange == false) {
  //                 launch("mailto:$partnerEmail");
  //               }
  //             },
  //             child: _buildIconWithLabel(context, Icons.email, ''),
  //           ),
  //         ] else ...[
  //           GestureDetector(
  //             onTap: () {
  //               if (progressChange == false) {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(
  //                     content: Text('Mail Address is not available'),
  //                     backgroundColor: Colors.red,
  //                   ),
  //                 );
  //               }
  //             },
  //             child: Icon(
  //               Icons.email,
  //               color: Colors.grey,
  //             ),
  //           ),
  //         ],
  //         if (siteAddress != null &&
  //             siteAddress is String &&
  //             siteAddress.isNotEmpty) ...[
  //           GestureDetector(
  //             onTap: () {
  //               if (progressChange == false) {
  //                 String fullAddress = siteAddress.replaceAll('\n', ', ');
  //                 launch(
  //                     "https://www.google.com/maps/search/?api=1&query=$fullAddress");
  //               }
  //             },
  //             child: Column(
  //               children: [
  //                 Image.asset(
  //                   'assets/send.png',
  //                   height: responsiveFontSize(context, 30.0, 24.0),
  //                   width: responsiveFontSize(context, 30.0, 24.0),
  //                   color: Colors.green,
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ] else ...[
  //           GestureDetector(
  //             onTap: () {
  //               if (progressChange == false) {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(
  //                     content: Text('Location is not available'),
  //                     backgroundColor: Colors.red,
  //                   ),
  //                 );
  //               }
  //             },
  //             child: Column(
  //               children: [
  //                 Image.asset(
  //                   'assets/send.png',
  //                   height: responsiveFontSize(context, 30.0, 24.0),
  //                   width: responsiveFontSize(context, 30.0, 24.0),
  //                   color: Colors.grey,
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ],
  //     ),
  //   );
  // }

  Widget _buildLocationSection(BuildContext context, Size screenSize) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final partnerPhone = args['partner_phone'];
    final partnerEmail = args['partner_email'];
    final siteAddress = args['x_studio_site_address_1'];

    return Container(
      width: screenSize.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Existing location information icons
          Container(
            width: screenSize.width * 0.3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (partnerPhone != null && partnerPhone is String) ...[
                  GestureDetector(
                    onTap: () {
                      if (progressChange == false) {
                        launch("tel:$partnerPhone");
                      }
                    },
                    child: _buildIconWithLabel(context, Icons.phone, ''),
                  ),
                ] else ...[
                  GestureDetector(
                    onTap: () {
                      if (progressChange == false) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Phone number is not available'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Icon(
                      Icons.phone,
                      color: Colors.grey,
                    ),
                  ),
                ],
                if (partnerEmail != null && partnerEmail is String) ...[
                  GestureDetector(
                    onTap: () {
                      if (progressChange == false) {
                        launch("mailto:$partnerEmail");
                      }
                    },
                    child: _buildIconWithLabel(context, Icons.email, ''),
                  ),
                ] else ...[
                  GestureDetector(
                    onTap: () {
                      if (progressChange == false) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Mail Address is not available'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Icon(
                      Icons.email,
                      color: Colors.grey,
                    ),
                  ),
                ],
                if (siteAddress != null &&
                    siteAddress is String &&
                    siteAddress.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () {
                      if (progressChange == false) {
                        String fullAddress = siteAddress.replaceAll('\n', ', ');
                        launch(
                            "https://www.google.com/maps/search/?api=1&query=$fullAddress");
                      }
                    },
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/send.png',
                          height: responsiveFontSize(context, 30.0, 24.0),
                          width: responsiveFontSize(context, 30.0, 24.0),
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  GestureDetector(
                    onTap: () {
                      if (progressChange == false) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Location is not available'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/send.png',
                          height: responsiveFontSize(context, 30.0, 24.0),
                          width: responsiveFontSize(context, 30.0, 24.0),
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isSiteDetails)
            TextButton(
              onPressed: () {
                var screenSize = MediaQuery.of(context).size;
                double iconSize = screenSize.width * 0.08;
                double textFontSize = screenSize.width * 0.03;
                double containerWidth = screenSize.width * 0.28;
                IconData premisesIcon = Icons.home;
                String premisesName = 'Residential';

                switch (premises) {
                  case 'Residential':
                    premisesIcon = Icons.home;
                    premisesName = 'Residential';
                    break;
                  case 'Commerical':
                    premisesIcon = Icons.business;
                    premisesName = 'Commercial';
                    break;
                  case 'Industrial':
                    premisesIcon = Icons.factory;
                    premisesName = 'Industrial';
                    break;
                  default:
                    premisesIcon = Icons.person;
                    premisesName = 'Owner Details';
                }

                String serviceType = 'New Installation';
                switch (serviceType) {
                  case 'New Installation':
                    serviceType = 'New Installation';
                    break;
                  case 'Replacement':
                    serviceType = 'Replacement';
                    break;
                  case 'Service':
                    serviceType = 'Service';
                    break;
                  default:
                    serviceType = 'Unknown';
                }
                if (progressChange == false) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditOwnerDetailsScreen(
                          storeys: storeys,
                          wall_type: wall_type,
                          roof_type: roof_type,
                          meterBoxPhase: meterBoxPhase,
                          premises: premisesName,
                          partner_items: partner_items,
                          project_id: projectId!,
                          serviceType: serviceType,
                          description: description,
                          nmi: nmi,
                          installedOrNot: installedOrNot,
                          switchBoardUsed: switchBoardUsed,
                          expectedInverterLocation: expectedInverterLocation,
                          mountingWallType: mountingWallType,
                          inverterLocationNotes: inverterLocationNotes,
                          expectedBatteryLocation: expectedBatteryLocation,
                          mountingType: mountingType),
                    ),
                  );
                }
              },
              child: Text(
                'Site Details',
                style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 17),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconWithLabel(
      BuildContext context, IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: responsiveFontSize(context, 30.0, 24.0),
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildSystemInfoCard(BuildContext context) {
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 70.0,
          width: double.infinity,
          color: Colors.white,
        ),
      );
    } else {
      if (productDetailsList == null || productDetailsList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20.0),
              Text(
                'No System Informations Available',
                style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }
      print("productDetailsListp.......roductDetailsList$productDetailsList");
      List<Map<String, dynamic>> removeDuplicateProducts(List<Map<String, dynamic>> products) {
        final seenIds = <int>{};
        return products.where((product) {
          final id = int.tryParse(product['id'].toString()) ?? 0;
          if (seenIds.contains(id)) {
            return false; // Skip duplicate
          } else {
            seenIds.add(id);
            return true; // Keep unique entry
          }
        }).toList();
      }
      return Container(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Column(
            children: removeDuplicateProducts(productDetailsList).map((product) {
              return _buildSystemInfoTile(
                context,
                product['id'] != null
                    ? int.tryParse(product['id'].toString()) ?? 0
                    : 0,
                '${product['quantity']}',
                product['model'] ?? '',
                product['manufacturer'] ?? '',
                product['image'],
                product['state'] ?? '',
              );
            }).toList(),
          ),
        ),
      );
    }
  }

  bool isValidBase64(String base64String) {
    final regex = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
    return base64String.isNotEmpty && regex.hasMatch(base64String);
  }

  Widget _buildSystemInfoTile(BuildContext context, int id, String firstTitle,
      String title, String subtitle, String? imageUrl, state) {
    var screenSize = MediaQuery.of(context).size;
    var isLargeScreen = screenSize.width > 600;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isLargeScreen ? 10.0 : 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30.0,
            backgroundColor: Colors.grey[350],
            child: ClipOval(
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.memory(
                      base64Decode(imageUrl),
                      fit: BoxFit.cover,
                      width: 80.0,
                      height: 80.0,
                      errorBuilder: (BuildContext context, Object exception,
                          StackTrace? stackTrace) {
                        return Icon(
                          Icons.solar_power,
                          size: 30,
                          color: Colors.black,
                        );
                      },
                    )
                  : Icon(Icons.solar_power, size: 30, color: Colors.black),
            ),
          ),
          SizedBox(width: isLargeScreen ? 16.0 : 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: responsiveFontSize(context, 18.0, 16.0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 6.0 : 4.0),
                Text(
                  '${firstTitle}x',
                  style: TextStyle(
                    fontSize: responsiveFontSize(context, 18.0, 16.0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadChecklist() async {
    final ChecklistBox = await Hive.openBox('ChecklistBox_$projectId');
    final checklist = ChecklistBox.get('checklistTypes');
    print("progressChangeprogressChangeprogressChange$checklist");
    if (checklistTypes != []) {
      setState(() {
        checklistTypes = checklist;
        if (progressChange) isStartjob = false;
      });
    }
  }

  Future<void> loadChecklistFromHive(int worksheetId) async {
    final boxName = 'checklistItems_$worksheetId';
    final box = await Hive.openBox<ChecklistItemHive>(boxName);
    print("checklistItemschecklistItemschecklistItems");
    List<ChecklistItem> loadedItems = box.values.map((hiveItem) {
      return ChecklistItem(
          title: hiveItem.title,
          key: hiveItem.key,
          isMandatory: hiveItem.isMandatory,
          uploadedImages:
              hiveItem.uploadedImagePaths.map((path) => File(path)).toList(),
          requiredImages: hiveItem.requiredImages,
          textContent: hiveItem.textContent,
          type: hiveItem.type,
          isUpload: hiveItem.isUpload);
    }).toList();

    setState(() {
      checklistItems = loadedItems;
      isLoading = false;
    });
    print("checklistItemschecklistItems$checklistItems");
    await box.close();
  }

  Future<void> getChecklistWithoutSelfies() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final prefs = await SharedPreferences.getInstance();
    final teamId = prefs.getInt('teamId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    if (!isNetworkAvailable) {
      loadChecklistFromHive(worksheetId!);
      return;
    } else {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;
      print(workTypeIdList);
      print("workTypeIdListworkTypeIdList");
      try {
        // final checklist = await client?.callKw({
        //   'model': 'installation.checklist',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       ['category_ids', 'in', categIdList],
        //       [
        //         'selfie_type',
        //         'not in',
        //         ['mid', 'check_out', 'check_in']
        //       ],
        //       ['group_ids', 'in', workTypeIdList]
        //     ]
        //   ],
        //   'kwargs': {},
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/installation_checklist');
        final checklist = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "categIdList": categIdList,
              "workTypeIdList": workTypeIdList,
            }
          }),
        );
        print(checklist.body);
        print("jsonChecklistResponsessssssssss");
        final Map<String, dynamic> jsonChecklistResponse = json.decode(
            checklist.body);
        print(jsonChecklistResponse);
        if (jsonChecklistResponse['result']['status'] == 'success' &&
            jsonChecklistResponse['result']['installation_checklist']
                .isNotEmpty) {
          print("555555555555555555555checklist$jsonChecklistResponse['result']['installation_checklist']");
          // if (checklist != null && checklist is List) {
          List<ChecklistItem> fetchedChecklistItems = [];
          for (var item in jsonChecklistResponse['result']['installation_checklist']) {
            // final imagesOrText = await client?.callKw({
            //   'model': 'installation.checklist.item',
            //   'method': 'search_read',
            //   'args': [
            //     [
            //       ['checklist_id', '=', item['id']],
            //       ['worksheet_id', '=', worksheetId]
            //     ]
            //   ],
            //   'kwargs': {},
            // });
            final Uri url = Uri.parse(
                '$baseUrl/rebates/installation_checklist_item');
            final imagesOrText = await http.post(
              url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "jsonrpc": "2.0",
                "method": "call",
                "params": {
                  "worksheet_id": worksheetId,
                  "checklist_id": item['id']
                }
              }),
            );
            final Map<String, dynamic> jsonImagesOrTextResponse = json.decode(
                imagesOrText.body);

            List<File> uploadedImages = [];
            String? textContent;
            print("imagesOrTextimagesOrTsssssssssextimagesOrText${jsonImagesOrTextResponse['result']}");
            if (jsonImagesOrTextResponse['result']['status'] == 'success' &&
                jsonImagesOrTextResponse['result']['installation_checklist_item_data']
                    .isNotEmpty) {
              print("fffffffffffffffffffffff");
              // if (imagesOrText != null &&
              //   imagesOrText is List &&
              //   imagesOrText.isNotEmpty) {
              for (var entry in jsonImagesOrTextResponse['result']['installation_checklist_item_data']) {
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
            print("item['name']item['name']item['name']${item['name']}");
            fetchedChecklistItems.add(ChecklistItem(
                title: item['name'] ?? 'Unnamed',
                key: item['id'].toString() ?? '0',
                isMandatory: item['compulsory'] ?? false,
                uploadedImages: item['type'] == 'img' ? uploadedImages : [],
                requiredImages: item['min_qty'] ?? 1,
                textContent: item['type'] == 'text'
                    ? textContent ?? ''
                    : null,
                type: item['type'] ?? '',
                isUpload: item['is_upload'] ?? false));
          }
          setState(() {
            checklistItems = fetchedChecklistItems;
            print(checklistItems);
            print("checklistItemschecklistItemschecklistItemsddd");
            isLoading = false;
          });
          saveChecklistToHive(worksheetId!);
        } else {
          isLoading = false;
        }
      } catch (e) {
        loadChecklistFromHive(worksheetId!);
        return;
        // isLoading = false;
      }
    }
  }

  Future<void> saveChecklistToHive(int worksheetId) async {
    final boxName = 'checklistItems_$worksheetId';
    final box = await Hive.openBox<ChecklistItemHive>(boxName);
    await box.clear();
    List<ChecklistItemHive> checklistHiveItems = checklistItems.map((item) {
      return ChecklistItemHive(
          title: item.title,
          key: item.key,
          isMandatory: item.isMandatory,
          uploadedImagePaths:
              item.uploadedImages.map((file) => file.path).toList(),
          requiredImages: item.requiredImages,
          textContent: item.textContent,
          type: item.type,
          isUpload: item.isUpload);
    }).toList();
    await box.clear();
    await box.addAll(checklistHiveItems);
    await box.close();
  }

  Future<void> getChecklist() async {
    if (!isNetworkAvailable) {
      loadChecklist();
      return;
    } else {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      final teamId = prefs.getInt('teamId') ?? 0;
      final baseUrl = prefs.getString('url') ?? 0;
      try {
        // final checklist = await client?.callKw({
        //   'model': 'installation.checklist',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       ['category_ids', 'in', categIdList],
        //       [
        //         'selfie_type',
        //         'in',
        //         ['check_in', 'mid', 'check_out']
        //       ],
        //       ['group_ids', 'in', workTypeIdList]
        //     ]
        //   ],
        //   'kwargs': {},
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/installation_checklist');
        final checklist = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "categIdList": categIdList,
              "workTypeIdList": workTypeIdList,
              "is_selfie": true
            }
          }),
        );
        final Map<String, dynamic> jsonChecklistResponse = json.decode(checklist.body);
        print("jsonChecklistResponsejsonChecklistResponse$jsonChecklistResponse");
        if (jsonChecklistResponse['result']['status'] == 'success' && jsonChecklistResponse['result']['installation_checklist'].isNotEmpty) {
          checklistTypes = (jsonChecklistResponse['result']['installation_checklist'] as List)
              .map((item) => item['selfie_type'] as String)
              .toList();}
          print("progressChangeprogressChangeprogressChange$progressChange");
          if (progressChange) isStartjob = false;
          final checklistTypesBox = await Hive.openBox('ChecklistBox');
          await checklistTypesBox.put('checklistTypes', checklistTypes);
        // }
      } catch (e) {
        loadChecklist();
        // isLoading = false;
        return;
      }
    }
  }

  Widget _buildSelfieSection(BuildContext context) {
    final finalMap = Map<String, Map<String, dynamic>>.fromIterable(
      finalCategoryList,
      key: (item) => item['name'],
      value: (item) => item,
    ).values.toList();
    finalCategoryList = finalMap;
    double itemHeight = 50.0;
    int itemCount = finalCategoryList.length;
    print(itemCount);
    print(finalCategoryList);
    print("itemCountitemCount55555555555555555");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Product Verification",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 10,
        ),
        _buildProductVerificationList(),
        // Container(
        //     height: isLoading ? itemHeight * 1 : itemHeight * itemCount,
        //     child: isLoading
        //         ? _buildShimmerEffect(itemHeight)
        //         : itemCount == 0
        //             ? Center(
        //                 child: Text(
        //                   "No verification item present",
        //                   style: TextStyle(
        //                       fontSize: 16,
        //                       fontWeight: FontWeight.bold,
        //                       color: Colors.grey),
        //                 ),
        //               )
        //             : Column(
        //                 children: finalCategoryList.map((category) {
        //                   String displayName = category['name'];
        //                   int categId = category['id'];
        //                   int? displayTotalCount;
        //                   int displayCount = 0;
        //                   switch (displayName) {
        //                     case 'Solar Panels':
        //                       displayName = 'Panel Serials';
        //                       displayTotalCount = panel_count;
        //                       displayCount = scanned_panel_count;
        //                       break;
        //                     case 'Inverters':
        //                       displayName = 'Inverter Serials';
        //                       displayTotalCount = inverter_count;
        //                       displayCount = scanned_inverter_count;
        //                       break;
        //                     case 'Storage':
        //                       displayName = 'Battery Serials';
        //                       displayTotalCount = battery_count;
        //                       displayCount = scanned_battery_count;
        //                       break;
        //                     default:
        //                       displayName = category['name'];
        //                       displayTotalCount = 0;
        //                       displayCount = 0;
        //                   }
        //                   return _buildProductListTile(
        //                     context,
        //                     displayName,
        //                     categId,
        //                     projectId!,
        //                     worksheetId ?? 0,
        //                     status_done,
        //                     displayTotalCount,
        //                     displayCount,
        //                   );
        //                 }).toList(),
        //               )
        // ),
        if (checklistTypes.contains('mid'))
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSelfieText(context, 'On-site Selfies'),
                _buildSelfieTile(
                    context, 'Mid Installation Selfie', MidImagePath),
              ],
            ),
          ),
        SizedBox(
          height: 10,
        ),
        Text(
          "Checklists",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 10,
        ),
        _buildChecklistList(),
        if (checklistTypes.contains('check_out'))
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSelfieText(context, 'On-site Selfies'),
                _buildSelfieTile(
                    context, 'End-of-installation Selfie', CheckOutImagePath),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildShimmerEffect(double itemHeight) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 70.0,
        width: double.infinity,
        color: Colors.white,
      ),
    );
  }

  Future<void> _pickImageFromGallery(ChecklistItem item) async {
    try {
      if (item.uploadedImages.length >= item.requiredImages) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'You have already uploaded the required number of images.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      bool hasPermission = await _checkCameraPermission();
      if (!hasPermission) {
        setState(() {
          item.isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera permission is required to proceed.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;
      final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
      String worksheetIdString = worksheetId.toString() ?? 'unknown';
      String compositeKey = "$worksheetIdString-${item.key}";

      final box = await Hive.openBox<OfflineChecklistItem>('offline_checklist');
      OfflineChecklistItem? existingItem = await box.get(compositeKey);

      int existingImagesCount = existingItem?.uploadedImages.length ?? 0;

      if (existingImagesCount >= item.requiredImages) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You have already uploaded the required number of images.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        setState(() {
          item.isUploading = true;
        });
        item.uploadedImages.add(imageFile);
        Position? position = await _getCurrentLocation();
        if (position == null) {
          setState(() {
            item.isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You must enable location permissions to proceed.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        await saveChecklistItemOffline(item, position!, imageFile: imageFile);
        await uploadChecklist(item, imageFile, position);
        setState(() {
          item.isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        item.isUploading = false;
      });
    }
  }

  Widget _buildChecklistList() {
    return Container(
      child: isLoading
          ? Column(
              children: List.generate(
                  2, (index) => _buildShimmerListTile()), // Dummy shimmer tiles
            )
          : checklistItems.length == 0
              ? Center(
                  child: Text(
                    "No checklist item present",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                )
              : Column(
                  children: checklistItems.map((item) {
                    print(item.isUpload);
                    print("444444444444444itemitem");
                    return ListTile(
                      title: Row(
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: item.title ?? 'Unnamed',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                if (item.isMandatory)
                                  const TextSpan(
                                    text: ' *',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 25,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      subtitle: item.type == 'img'
                          ? (item.isUploading
                              ? Row(
                                  children: const [
                                    CircularProgressIndicator(),
                                    SizedBox(width: 10),
                                    Text(
                                      'Uploading...',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                )
                              : Text(
                                  '${item.uploadedImages.length}/${item.requiredImages} uploaded',
                                  style: const TextStyle(color: Colors.black),
                                ))
                          : Text(
                              item.textContent != null &&
                                      item.textContent!.isNotEmpty
                                  ? 'Text updated'
                                  : 'Text input required',
                              style: TextStyle(
                                color: item.textContent != null &&
                                        item.textContent!.isNotEmpty
                                    ? Colors.black
                                    : Colors.black,
                              ),
                            ),
                      // trailing: item.type == 'img'
                      //     ? IconButton(
                      //         icon: const Icon(Icons.add_a_photo),
                      //         onPressed: () {
                      //           if (status_done != 'done') {
                      //             _pickImages(item);
                      //           }
                      //         },
                      //       )
                      trailing: item.isUploading
                          ? null
                          : item.type == 'img'
                              ? IconButton(
                                  icon: Icon(
                                    item.isUpload
                                        ? Icons.add_photo_alternate
                                        : Icons.add_a_photo,
                                    color: item.isUpload
                                        ? Colors.black
                                        : Colors.black,
                                  ),
                                  onPressed: () {
                                    if (progressChange == false) {
                                      if (status_done != 'done') {
                                        if (item.isUpload) {
                                          _pickImageFromGallery(item);
                                        } else {
                                          _pickImages(item);
                                        }
                                      }
                                    }
                                  },
                                )
                              : IconButton(
                                  icon: const Icon(Icons.text_fields,color: Colors.black,),
                                  onPressed: () {
                                    if (progressChange == false) {
                                      if (status_done != 'done') {
                                        _showTextInputDialog(context, item);
                                      }
                                    }
                                  },
                                ),
                      onTap: () {
                        if (progressChange == false) {
                          if (item.type == 'img') {
                            _showUploadedImages(context, item.uploadedImages);
                          } else if (item.type == 'text') {
                            _showTextDialog(context, item);
                          }
                        }
                      },
                    );
                  }).toList(),
                ),
    );
  }

  Widget _buildProductVerificationList() {
    print("finalCategoryListfinalCategoryList$finalCategoryList");
    final finalMap = Map<String, Map<String, dynamic>>.fromIterable(
      finalCategoryList,
      key: (item) => item['name'],
      value: (item) => item,
    ).values.toList();
    finalCategoryList = finalMap;
    double itemHeight = 50.0;
    int itemCount = finalCategoryList.length;
    print(itemCount);
    print("ggitemmmmmmmmmmmmmmmmmmmmm");

    if (isLoading) {
      return Container(
        height: isLoading ? itemHeight * 1 : itemHeight * itemCount,
        child: _buildShimmerEffect(itemHeight),
      );
    }

    if (finalCategoryList.isEmpty) {
      return Center(
        child: Text(
          'No verification item present',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      );
    }

    return Container(
      child: Column(
        children: finalCategoryList.map((category) {
          String displayName = category['name'];
          int categId = category['id'];
          int? displayTotalCount;
          int displayCount = 0;

          switch (displayName) {
            case 'Solar Panels':
              displayName = 'Panel Serials';
              displayTotalCount = panel_count;
              displayCount = scanned_panel_count;
              break;
            case 'Inverters':
              displayName = 'Inverter Serials';
              displayTotalCount = inverter_count;
              displayCount = scanned_inverter_count;
              break;
            case 'Storage':
              displayName = 'Battery Serials';
              displayTotalCount = battery_count;
              displayCount = scanned_battery_count;
              break;
            default:
              displayName = category['name'];
              displayTotalCount = 0;
              displayCount = 0;
          }

          return _buildProductListTile(
            context,
            displayName,
            categId,
            projectId!,
            worksheetId ?? 0,
            status_done,
            displayTotalCount,
            displayCount,
          );
        }).toList(),
      )
    );
  }

  Widget _buildShimmerListTile() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListTile(
        title: Container(
          height: 20.0,
          width: double.infinity,
          color: Colors.grey[300],
        ),
        subtitle: Container(
          height: 15.0,
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10.0),
          color: Colors.grey[300],
        ),
        trailing: CircleAvatar(
          radius: 20.0,
          backgroundColor: Colors.grey[300],
        ),
      ),
    );
  }

  void _showUploadedImages(BuildContext context, List<File>? images) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Uploaded Images",
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
          content: SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width * 0.95,
            child: images == null || images.isEmpty
                ? Center(
                    child: Text(
                      'No images available',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.file(
                          images[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  void _showTextDialog(BuildContext context, ChecklistItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Text for ${item.title}",
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
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
              minWidth: MediaQuery.of(context).size.width * 0.95,
            ),
            child: SingleChildScrollView(
              child: item.textContent != null && item.textContent!.isNotEmpty
                  ? Center(
                      child: Text(
                        item.textContent!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    )
                  : Center(
                      child: Text(
                        'No text available',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  void _showTextInputDialog(BuildContext context, ChecklistItem item) {
    final TextEditingController controller =
        TextEditingController(text: item.textContent);
    bool isSubmitLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Stack(
              children: [
                AlertDialog(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Add Text for ${item.title}",
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
                  content: TextField(
                    controller: controller,
                    decoration:
                        InputDecoration(hintText: "Enter your text here"),
                  ),
                  actions: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          String inputText = controller.text;
                          if (inputText.isNotEmpty) {
                            setState(() {
                              isSubmitLoading = true;
                            });
                            Position? position = await _getCurrentLocation();
                            if (position == null) {
                              setState(() {
                                isSubmitLoading = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'You must enable location permissions to proceed.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            await uploadTextToChecklist(
                                item, inputText, position);
                            setState(() {
                              isSubmitLoading = false;
                            });
                            Navigator.of(context).pop(true);
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.green),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        child: Text(
                          "SUBMIT",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isSubmitLoading)
                  Positioned.fill(
                    child: Container(
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> uploadTextToChecklist(
      ChecklistItem item, String inputText, position) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('url') ?? 0;
    final teamId = prefs.getInt('teamId') ?? 0;
    print("ddddddddddddddssssssssssssssssssssss");
    if (!isNetworkAvailable) {
      item.textContent = inputText;
      saveChecklistItemOffline(
        item,
        position,
        textContent: inputText,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;
      final baseUrl = prefs.getString('url') ?? 0;
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks.first;
      String locationDetails =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
      final formattedDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      try {
        // final existingChecklist = await client?.callKw({
        //   'model': 'installation.checklist.item',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       ['checklist_id', '=', int.parse(item.key)],
        //       ['worksheet_id', '=', worksheetId]
        //     ],
        //     ['id']
        //   ],
        //   'kwargs': {},
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/installation_checklist_item');
        final existingChecklist = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "checklist_id": int.parse(item.key),
              "worksheet_id": worksheetId
            }
          }),
        );
        final Map<String, dynamic> jsonExistingChecklistResponse = json.decode(existingChecklist.body);
        print(jsonExistingChecklistResponse);
        print("jsonExistinjsonExistingChecklistResponsegChecklistResponse");
        // if (existingChecklist != null &&
        //     existingChecklist is List &&
        //     existingChecklist.isNotEmpty) {
        if (jsonExistingChecklistResponse['result']['status'] == 'success' &&
            jsonExistingChecklistResponse['result']['installation_checklist_item_data'].isNotEmpty) {
          final checklistId = jsonExistingChecklistResponse['result']['installation_checklist_item_data'][0]['id'];
          // await client?.callKw({
          //   'model': 'installation.checklist.item',
          //   'method': 'write',
          //   'args': [
          //     [checklistId],
          //     {
          //       'text': inputText,
          //       'date': formattedDate,
          //       'location': locationDetails,
          //       'latitude': position.latitude,
          //       'longitude': position.longitude
          //     }
          //   ],
          //   'kwargs': {},
          // });
          final Uri url = Uri.parse('$baseUrl/rebates/installation_checklist_item/write');
          final checklist = await http.post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "jsonrpc": "2.0",
              "method": "call",
              "params": {
                "id": checklistId,
                "inputText": inputText,
                "formattedDate": formattedDate,
                "locationDetails": locationDetails,
                'latitude': position.latitude,
                'longitude': position.longitude
              }
            }),
          );
        } else {
          // await client?.callKw({
          //   'model': 'installation.checklist.item',
          //   'method': 'create',
          //   'args': [
          //     {
          //       'user_id': userId,
          //       'worksheet_id': worksheetId,
          //       'checklist_id': item.key,
          //       'date': formattedDate,
          //       'text': inputText,
          //       'location': locationDetails,
          //       'latitude': position.latitude,
          //       'longitude': position.longitude
          //     }
          //   ],
          //   'kwargs': {},
          // });
          print("444444444444444ddddddddddddddddddddd");
          final Uri url = Uri.parse('$baseUrl/rebates/installation_checklist_item/create');
          final checklist = await http.post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "jsonrpc": "2.0",
              "method": "call",
              "params": {
                "teamId": teamId,
                "taskId": worksheetId,
                "item": item.key,
                "formattedDate": formattedDate,
                "locationDetails": locationDetails,
                'latitude': position.latitude,
                'longitude': position.longitude
              }
            }),
          );
        }
        setState(() {
          item.textContent = inputText;
        });
      } catch (e) {}
    }
  }

  Future<void> _pickImages(ChecklistItem item) async {
    try {
      if (item.uploadedImages.length >= item.requiredImages) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'You have already uploaded the required number of images.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      bool hasPermission = await _checkCameraPermission();
      if (!hasPermission) {
        setState(() {
          item.isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera permission is required to proceed.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;
      final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
      String worksheetIdString = worksheetId.toString() ?? 'unknown';
      String compositeKey = "$worksheetIdString-${item.key}";

      final box = await Hive.openBox<OfflineChecklistItem>('offline_checklist');
      OfflineChecklistItem? existingItem = await box.get(compositeKey);

      int existingImagesCount = existingItem?.uploadedImages.length ?? 0;

      if (existingImagesCount >= item.requiredImages) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You have already uploaded the required number of images.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxHeight: 1000,
        maxWidth: 1000,
      );
      if (pickedFile != null) {
        imageFile = File(pickedFile.path);
        setState(() {
          item.isUploading = true;
        });
        item.uploadedImages.add(imageFile!);
        Position? position = await _getCurrentLocation();
        if (position == null) {
          setState(() {
            item.isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You must enable location permissions to proceed.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        await saveChecklistItemOffline(item, position!, imageFile: imageFile);
        await uploadChecklist(item, imageFile, position);
        setState(() {
          item.isUploading = false;
        });
      }
      Navigator.popUntil(context, ModalRoute.withName('/installing_form_view'));
    } catch (e) {
      setState(() {
        item.isUploading = false;
      });
    }
  }

  Future<void> uploadChecklist(
      ChecklistItem item, File? imageFile, position) async {
    print("cccccccccccccccccccccccccccccccccc");
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('url') ?? 0;
    final teamId = prefs.getInt('teamId') ?? 0;
    userId = prefs.getInt('userId') ?? 0;
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    if (imageFile != null) {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks.first;
      String locationDetails =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
      final formattedDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      print(
          "${DateTime.now()}formattedDateformformattedDateattedDateformattedDate");
      print(formattedDate);
      try {
        await createChecklist(worksheetId!, item, imageFile);
        // final checklist = await client?.callKw({
        //   'model': 'installation.checklist.item',
        //   'method': 'write',
        //   'args': [
        //     [worksheetId],
        //     {
        //       'worksheet_id': worksheetId,
        //       'user_id': userId,
        //       'checklist_id': item.key,
        //       'date': formattedDate,
        //       'image': base64Image,
        //       'location': locationDetails,
        //       'latitude': position.latitude,
        //       'longitude': position.longitude
        //     }
        //   ],
        //   'kwargs': {},
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/installation_checklist_item/write');
        final checklist = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "teamId": teamId,
              "item": item.key,
              "taskId": worksheetId,
              "base64Image": base64Image,
              "formattedDate": formattedDate,
              "locationDetails": locationDetails,
              'latitude': position.latitude,
              'longitude': position.longitude
            }
          }),
        );
        setState(() {});
      } catch (e) {}
    }
  }

  Future<void> createChecklist(
      int taskId, ChecklistItem item, File? imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('url') ?? 0;
    final teamId = prefs.getInt('teamId') ?? 0;
    if (imageFile != null) {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      Position? position = await _getCurrentLocation();
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position!.latitude, position.longitude);
      Placemark place = placemarks.first;
      String locationDetails =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
      print(
          "44444444444444444aaaaaaaaaaaaaaaaaa444444444444444444444444444444dddddddddddddddd");
      final formattedDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      try {
        // final checklist = await client?.callKw({
        //   'model': 'installation.checklist.item',
        //   'method': 'create',
        //   'args': [
        //     {
        //       'user_id': userId,
        //       'worksheet_id': taskId,
        //       'checklist_id': item.key,
        //       'date': formattedDate,
        //       'image': base64Image,
        //       'location': locationDetails,
        //       'latitude': position.latitude,
        //       'longitude': position.longitude
        //     }
        //   ],
        //   'kwargs': {},
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/installation_checklist_item/create');
        final checklist = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "teamId": teamId,
              "taskId": taskId,
              "item": item.key,
              "base64Image": base64Image,
              "formattedDate": formattedDate,
              "locationDetails": locationDetails,
              'latitude': position.latitude,
              'longitude': position.longitude
            }
          }),
        );
        final Map<String, dynamic> jsonChecklistResponse = json.decode(checklist.body);
        print(jsonChecklistResponse);
      } catch (e) {
        print(
            "fffffffffffffffffffffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee$e");
      }
    }
  }

  Future<void> saveChecklistItemOffline(
    ChecklistItem item,
    Position position, {
    String? textContent,
    File? imageFile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;

    final String worksheetIdString = worksheetId.toString() ?? "unknown";

    final String compositeKey = "$worksheetIdString-${item.key}";

    List<String> base64Images = [];
    if (imageFile != null) {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      base64Images.add(base64Image);
    }

    List<String> uploadedImagesBase64 = [];
    for (var file in item.uploadedImages) {
      final bytes = await file.readAsBytes();
      uploadedImagesBase64.add(base64Encode(bytes));
    }

    final offlineItem = OfflineChecklistItem(
        userId: userId,
        worksheetId: worksheetIdString,
        checklistId: item.key,
        title: item.title,
        isMandatory: item.isMandatory,
        type: item.type,
        requiredImages: item.requiredImages,
        uploadedImages: uploadedImagesBase64,
        textContent: textContent,
        imageBase64: base64Images,
        position: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        createTime: DateTime.now());

    final box = await Hive.openBox<OfflineChecklistItem>('offline_checklist');

    try {
      final existingItem = box.get(compositeKey);

      if (existingItem != null) {
        existingItem.uploadedImages.addAll(
          uploadedImagesBase64
              .where((image) => !existingItem.uploadedImages.contains(image)),
        );
        existingItem.textContent = textContent ?? existingItem.textContent;

        if (imageFile != null) {
          existingItem.imageBase64!.addAll(
            base64Images
                .where((base64) => !existingItem.imageBase64!.contains(base64)),
          );
        }
        await box.put(compositeKey, existingItem);
      } else {
        await box.put(compositeKey, offlineItem);
      }

      if (mounted) {
        setState(() {
          isSubmitLoading = false;
        });
      }
    } catch (e) {
    } finally {
      await box.close();
    }
  }

  Widget _buildVerificationTile(
      BuildContext context, String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (progressChange == false) {
          if (title == 'Checklist') {
            Navigator.pushNamed(context, '/checklist', arguments: {
              'task_id': projectId,
              'worksheet_id': worksheetId,
              'category_ids': categIdList,
              'status_done': status_done
            });
          } else if (title == 'Product Verification') {
            _showScanProductPopup(worksheetId);
          }
        }
      },
      child: Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.green[800],
            ),
            SizedBox(width: 50),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelfieTile(
      BuildContext context, String title, String? imagePath) {
    // if (!isNetworkAvailable) {
    return FutureBuilder<Box<HiveImage>>(
      future: Hive.openBox<HiveImage>('imagesBox'),
      builder: (context, AsyncSnapshot<Box<HiveImage>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print('Error loading data: ${snapshot.error}');
          return Center(child: Text('Error loading data: ${snapshot.error}'));
        }

        final box = snapshot.data!;
        print(box.values);
        print("dddddddddddzzzzzzzzzzzzzzzzzzzz");
        DateTime? tempCheckInTime, tempMidTime, tempCheckOutTime;

        if (box.values.isNotEmpty) {
          for (var selfie in box.values) {
            if (selfie == null) continue;
            print(selfie.checklistType);
            if (selfie.projectId == projectId) {
              switch (selfie.checklistType) {
                case 'check_in':
                  tempCheckInTime = selfie.timestamp;
                  CheckIncreateTime = tempCheckInTime ?? DateTime.now();
                  break;
                case 'mid':
                  tempMidTime = selfie.timestamp;
                  MidcreateTime = tempMidTime ?? DateTime.now();
                  break;
                case 'check_out':
                  tempCheckOutTime = selfie.timestamp;
                  CheckOutcreateTime = tempCheckOutTime ?? DateTime.now();
                  break;
              }
            }
          }
        }
        return _buildSelfieTileContent(context, title, imagePath);
      },
    );
    // }
    // return _buildSelfieTileContent(context, title, imagePath);
  }

  Widget _buildSelfieTileContent(
      BuildContext context, String title, String? imagePath) {
    print("CheckIncreateTimeCheckIncreateTime$CheckIncreateTime");
    return ValueListenableBuilder<DateTime>(
      valueListenable: nowDateTimeNotifier,
      builder: (context, nowDateTime, _) {
        String formattedNowDateTime = "";
        if (!isNetworkAvailable) {
          formattedNowDateTime =
              DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now().toLocal());
          print(formattedNowDateTime);
          print("44444444444444formattedNowDateTime");
        } else {
          formattedNowDateTime =
              DateFormat('yyyy-MM-dd HH:mm').format(nowDateTime.toLocal());
          print(formattedNowDateTime);
          print("44444444444444formattedNowDateTime");
        }
        DateTime nowTime =
            DateFormat('yyyy-MM-dd HH:mm').parse(formattedNowDateTime);
        Duration? countdownDuration;
        bool isLocked = false;
        if (title == 'Mid Installation Selfie') {
          if (CheckIncreateTime != null) {
            print("dddddddddddddddddddddddddddddddd");
            String formattedDateTimeMid =
                DateFormat('yyyy-MM-dd HH:mm').format(CheckIncreateTime!);
            print(formattedDateTimeMid);
            print("formattedDateTimeMid");
            DateTime checkInDateTime =
                DateFormat('yyyy-MM-dd HH:mm').parse(formattedDateTimeMid);
            print(checkInDateTime);
            print(nowTime);
            checkIndifference = nowTime.difference(checkInDateTime).abs();
            print(checkIndifference);
            if (checkIndifference! < Duration(minutes: 60)) {
              print("ffffffffffffffffffffffffffffffffffffffff");
              countdownDuration = Duration(minutes: 60) - checkIndifference!;
              print(CheckIncreateTime);
              print("countdownDurationcountdownDuration");
              isLocked = true;
            }
          } else {}
        }
        print(MidcreateTime);
        print("MidcreateTimeMidcreateTime");
        if (title == 'End-of-installation Selfie') {
          if (MidcreateTime != null) {
            String formattedDateTimeMid =
                DateFormat('yyyy-MM-dd HH:mm').format(MidcreateTime!);
            DateTime midDateTime =
                DateFormat('yyyy-MM-dd HH:mm').parse(formattedDateTimeMid);
            Middifference = nowTime.difference(midDateTime).abs();
            if (Middifference! < Duration(minutes: 60)) {
              countdownDuration = Duration(minutes: 60) - Middifference!;
              isLocked = true;
            }
          } else {}
        }
        print("fffffffffffffdddddddddddddwwwwwwwwwwwwwwwwwww");
        print(CheckIncreateTime);
        return Padding(
          padding: const EdgeInsets.only(top: 2.0, left: 5, bottom: 14),
          child: GestureDetector(
            onTap: () async {
              if (progressChange == false) {
                if (status_done != 'done') {
                  String checklistType = '';
                  if (title == 'Check-in Selfie') {
                    checklistType = 'check_in';
                    if (CheckIncreateTime == null) {
                      print(
                          "dddddddddddddddddddddddddddddddddddddddddddddddddddddvvvvvvvvvv");
                      _getFromCamera(checklistType);
                      isImageLoading = false;
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('You already added a Check-In selfie.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else if (title == 'Mid Installation Selfie') {
                    checklistType = 'mid';
                    if (isNetworkAvailable) {
                      if (MidcreateTime == null) {
                        if (CheckIncreateTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Please take a check-in selfie before taking a mid-installation selfie.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          DateTime now = DateTime.now();
                          String formattedDateTime =
                              DateFormat('yyyy-MM-dd HH:mm').format(now);

                          DateTime currentDateTime =
                              DateFormat('yyyy-MM-dd HH:mm')
                                  .parse(formattedDateTime);
                          String formattedDateTimeMid =
                              DateFormat('yyyy-MM-dd HH:mm')
                                  .format(CheckIncreateTime!);
                          print(currentDateTime);
                          print(formattedDateTimeMid);
                          print("ffffffffffffffffCheckIncreateTime");
                          DateTime midDateTime = DateFormat('yyyy-MM-dd HH:mm')
                              .parse(formattedDateTimeMid);

                          Duration difference =
                              currentDateTime.difference(midDateTime).abs();

                          if (difference.inMinutes > 60) {
                            isImageLoading = true;
                            _getFromCamera(checklistType);
                            isImageLoading = false;
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'You must wait at least 60 minutes after check-in to take a Mid-Installation selfie.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'You already added a Mid-Installation selfie.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      if (await _canTakeSelfie(
                          'check_in', Duration(minutes: 60))) {
                        await _getFromCamera(checklistType);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'You must wait at least 60 minutes to take an Mid-Installation selfie.'),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  } else if (title == 'End-of-installation Selfie') {
                    checklistType = 'check_out';
                    if (isNetworkAvailable) {
                      if (CheckOutcreateTime == null) {
                        if (MidcreateTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Please take a mid-installation selfie before taking an end-installation selfie.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          DateTime now = DateTime.now();
                          String formattedDateTime =
                              DateFormat('yyyy-MM-dd HH:mm').format(now);

                          DateTime currentDateTime =
                              DateFormat('yyyy-MM-dd HH:mm')
                                  .parse(formattedDateTime);
                          String formattedDateTimeCheckOut =
                              DateFormat('yyyy-MM-dd HH:mm')
                                  .format(MidcreateTime!);
                          DateTime checkOutDateTime =
                              DateFormat('yyyy-MM-dd HH:mm')
                                  .parse(formattedDateTimeCheckOut);
                          Duration difference = currentDateTime
                              .difference(checkOutDateTime)
                              .abs();
                          if (difference.inMinutes > 60) {
                            isImageLoading = true;
                            // _getFromCamera(checklistType);
                            bool result = await _getFromCamera(checklistType);
                            if (result) {
                              Position? position = await _getCurrentLocation();
                              setState(() {
                                _attendanceCheckoutAdd(worksheetId!,position,memberId!);
                              });
                            }
                            isImageLoading = false;
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'You must wait at least 60 minutes to take an End-Installation selfie.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('You already added a Check-Out selfie.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      if (await _canTakeSelfie('mid', Duration(minutes: 60))) {
                        await _getFromCamera(checklistType);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'You must wait at least 60 minutes to take an End-Installation selfie.'),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  }
                }
              }
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.green[800],
                    size: responsiveFontSize(context, 30.0, 25.0),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: responsiveFontSize(context, 16.0, 14.0),
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  if (isImageLoading)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (imagePath != null && imagePath.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.visibility, color: Colors.blue),
                      onPressed: () {
                        _showSelfieDialog(context, imagePath);
                      },
                    )
                  else if (title == 'Mid Installation Selfie' &&
                      checkIndifference != null &&
                      checkIndifference! < Duration(minutes: 60))
                    // Icon(Icons.lock, color: Colors.grey)
                    StopwatchWithLock(
                      duration: countdownDuration!,
                      isLocked: isLocked,
                      size: 30.0,
                    )
                  else if (title == 'End-of-installation Selfie' &&
                      (checkIndifference != null &&
                              checkIndifference! < Duration(minutes: 60) ||
                          Middifference != null &&
                              Middifference! < Duration(minutes: 60)))
                    // Icon(Icons.lock, color: Colors.grey)
                    if (countdownDuration != null)
                      StopwatchWithLock(
                        duration: countdownDuration!,
                        isLocked: isLocked,
                        size: 30.0,
                      )
                    else
                      Icon(Icons.lock, color: Colors.grey)
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSelfieDialog(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.memory(base64Decode(imagePath)),
                ],
              ),
              Positioned(
                right: 8.0,
                top: 8.0,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double responsiveFontSize(
      BuildContext context, double largeSize, double smallSize) {
    var screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 600 ? largeSize : smallSize;
  }

  double responsivePadding(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * 0.01;
  }

  void _showScanProductPopup(int? worksheetId) async {
    final finalMap = Map<String, Map<String, dynamic>>.fromIterable(
      finalCategoryList,
      key: (item) => item['name'],
      value: (item) => item,
    ).values.toList();
    finalCategoryList = finalMap;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            const double itemHeight = 50.0;
            double dialogHeight = MediaQuery.of(context).size.height *
                (finalCategoryList.length == 1
                    ? 0.15
                    : 0.1 * finalCategoryList.length);
            return Stack(
              children: [
                AlertDialog(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Scan Products",
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
                    height: dialogHeight,
                    width: MediaQuery.of(context).size.width * 0.95,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.01),
                        Text(
                          "Please Choose a Serial",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 17),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03),
                        Expanded(
                          child: ListView(
                              children: finalCategoryList.map((category) {
                            String displayName = category['name'];
                            int categId = category['id'];
                            int? displayTotalCount;
                            int displayCount = 0;
                            switch (displayName) {
                              case 'Solar Panels':
                                displayName = 'Panel Serials';
                                displayTotalCount = panel_count;
                                displayCount = scanned_panel_count;
                                break;
                              case 'Inverters':
                                displayName = 'Inverter Serials';
                                displayTotalCount = inverter_count;
                                displayCount = scanned_inverter_count;
                                break;
                              case 'Storage':
                                displayName = 'Battery Serials';
                                displayTotalCount = battery_count;
                                displayCount = scanned_battery_count;
                                break;
                              default:
                                displayName = category['name'];
                                displayTotalCount = 0;
                                displayCount = 0;
                            }
                            return _buildProductListTile(
                                context,
                                displayName,
                                categId,
                                projectId!,
                                worksheetId ?? 0,
                                status_done,
                                displayTotalCount,
                                displayCount);
                          }).toList()),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProductListTile(
      BuildContext context,
      String productName,
      int categId,
      int projectId,
      int worksheetId,
      String status_done,
      int displayTotalCount,
      int displayCount) {
    return GestureDetector(
      onTap: () async {
        // Navigator.of(context).pop();
        // Navigator.of(context).push(MaterialPageRoute(
        //   builder: (context) => ProductView(
        //     categId: categId,
        //     productName: productName,
        //     projectId: projectId,
        //     worksheetId: worksheetId,
        //     status_done: status_done,
        //   ),
        // ));
        if (progressChange == false) {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductView(
                  categId: categId,
                  productName: productName,
                  projectId: projectId,
                  worksheetId: worksheetId,
                  status_done: status_done,
                  reloadScanningCount: reloadScanningCount),
            ),
          );

          if (result == true) {
            getProductDetails();
          }
        }
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey[200],
        ),
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Row(
          children: [
            SizedBox(width: 10),
            Image.asset(
              'assets/barcode.png',
              width: 24,
              height: 24,
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              productName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Text('$displayCount/$displayTotalCount')
          ],
        ),
      ),
    );
  }
}

class PDFViewerPage extends StatelessWidget {
  final String documentPath;

  PDFViewerPage({required this.documentPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PDF Viewer',
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
      body: PDFView(
        filePath: documentPath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageSnap: true,
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading PDF')),
          );
        },
        onPageError: (page, error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading page $page')),
          );
        },
      ),
    );
  }
}

class ImageViewer extends StatelessWidget {
  final String filePath;

  ImageViewer({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Document Viewer',
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
        child: Image.file(
          File(filePath),
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 60),
                Text(
                  'Error loading document',
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
              ],
            );
          },
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

class RiskAssessmentPage extends StatefulWidget {
  final List<String> allowedTypes;
  final List<dynamic> categIdList;
  final List<dynamic> workTypeIdList;
  final List<Map<String, dynamic>> selectedDetails;
  final int worksheetId;
  final int memberId;
  final int projectId;
  final Map<String, bool> selectedCheckboxes;
  final Map<String, bool> selectedRiskItemCheckboxes;
  Map<String, String?> dropdownValues = {};
  Map<String, String?> dropdownRiskItemsValues = {};
  Map<String, String> specificTaskDetails = {};
  List<int> team_member_ids = [];
  Map<int, String> hazardResponses = {};
  var args;

  RiskAssessmentPage({
    required this.args,
    required this.allowedTypes,
    required this.categIdList,
    required this.workTypeIdList,
    required this.selectedDetails,
    required this.worksheetId,
    required this.memberId,
    required this.projectId,
    required this.selectedCheckboxes,
    required this.selectedRiskItemCheckboxes,
    required this.dropdownValues,
    required this.dropdownRiskItemsValues,
    required this.specificTaskDetails,
    required this.team_member_ids,
    required this.hazardResponses,
  });

  @override
  _RiskAssessmentPageState createState() => _RiskAssessmentPageState();
}

class _RiskAssessmentPageState extends State<RiskAssessmentPage> {
  Map<String, bool> selectedCheckboxes = {};
  Map<String, bool> selectedRiskItemCheckboxes = {};
  Map<String, String?> dropdownValues = {};
  Map<String, String?> dropdownRiskItemsValues = {};
  List<Map<String, dynamic>> swmsDetails = [];
  OdooClient? client;
  String url = "";
  String taskDetails = "";
  List<Map<String, dynamic>> hazard_question_items = [];
  int? userId;
  bool isNetworkAvailable = false;
  Map<String, String> taskDetailsMap = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkConnectivity();
    // _initializeOdooClient();
    getHazardQuestions();
    loadSelectedRiskItems();
    selectedCheckboxes = {
      for (var item in widget.allowedTypes) item: false,
    };
    dropdownValues = {
      for (var item in widget.allowedTypes) item: null,
    };
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

  // Future<void> getHazardQuestions() async {
  //   if (isNetworkAvailable) {
  //     final prefs = await SharedPreferences.getInstance();
  //     userId = prefs.getInt('userId') ?? 0;
  //     try {
  //       print(widget.categIdList);
  //       print("fffffffffffffffffffffffffffwidgettttttttttt");
  //       for (var item in widget.categIdList) {
  //         print(item);
  //         print("ygggggggggggggggggggggg");
  //         final categoryDetails = await client?.callKw({
  //           'model': 'product.category',
  //           'method': 'search_read',
  //           'args': [
  //             [
  //               ['id', '=', item],
  //             ]
  //           ],
  //           'kwargs': {
  //             'fields': ['name', 'parent_id'],
  //           },
  //         });
  //         print(categoryDetails);
  //         print("fffffffffffffffffffffffffhhhhhhhhhhhhhhh");
  //       }
  //       final hazardQuestionDetails = await client?.callKw({
  //         'model': 'swms.risk.register',
  //         'method': 'search_read',
  //         'args': [[]],
  //         'kwargs': {
  //           'fields': [
  //             'id',
  //             'installation_question',
  //             'risk_control',
  //             'category_id'
  //           ],
  //         },
  //       });
  //       if (hazardQuestionDetails != null && hazardQuestionDetails.isNotEmpty) {
  //         hazard_question_items =
  //             List<Map<String, dynamic>>.from(hazardQuestionDetails);
  //       } else {
  //         print("No hazard questions found.");
  //       }
  //     } catch (e) {
  //       print("Error fetching hazard questions: $e");
  //     }
  //   } else {
  //     loadHazardQuestion(widget.projectId);
  //   }
  // }
  Future<void> getHazardQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final teamId = prefs.getInt('teamId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    if (isNetworkAvailable) {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;

      try {
        List<int> categoryIds = [];

        print(widget.categIdList);
        print("Start fetching category details");

        for (var item in widget.categIdList) {
          print("Fetching category for ID: $item");

          // final categoryDetails = await client?.callKw({
          //   'model': 'product.category',
          //   'method': 'search_read',
          //   'args': [
          //     [
          //       ['id', '=', item],
          //     ]
          //   ],
          //   'kwargs': {
          //     'fields': ['id', 'parent_id'],
          //   },
          // });
          final Uri url = Uri.parse('$baseUrl/rebates/product_category');
          final categoryDetails = await http.post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "jsonrpc": "2.0",
              "method": "call",
              "params": {
                "id": item,

              }
            }),
          );
          final Map<String, dynamic> jsonCategoryDetailsResponse = json.decode(categoryDetails.body);
          // if (categoryDetails != null && categoryDetails.isNotEmpty) {
          if (jsonCategoryDetailsResponse['result']['status'] == 'success' &&
              jsonCategoryDetailsResponse['result']['categories'].isNotEmpty) {
            for (var detail in jsonCategoryDetailsResponse['result']['categories']) {
              if (detail['id'] != null) categoryIds.add(detail['id']);
              if (detail['parent_id'] != null && detail['parent_id'] is List) {
                categoryIds.add(detail['parent_id']
                    [0]); // Assuming parent_id is in [id, name] format
              }
            }
          }

          print("Fetched category details: $categoryDetails");
        }

        print("All category IDs and parent IDs: $categoryIds");

        // final hazardQuestionDetails = await client?.callKw({
        //   'model': 'swms.risk.register',
        //   'method': 'search_read',
        //   'args': [[]],
        //   'kwargs': {
        //     'fields': [
        //       'id',
        //       'installation_question',
        //       'job_activity',
        //       'risk_control',
        //       'category_id'
        //     ],
        //   },
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/swms_risk_register');
        final hazardQuestionDetails = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {}
          }),
        );
        print(hazardQuestionDetails);
        print(hazardQuestionDetails.body);
        print("hazardQuestionDetailshazardQuestionDetails");
        final Map<String, dynamic> jsonHazardQuestionDetailsResponse = json.decode(hazardQuestionDetails.body);
        // if (hazardQuestionDetails != null && hazardQuestionDetails.isNotEmpty) {
        print(jsonHazardQuestionDetailsResponse);
        print("jsonHazardQuestionDetailsResponsejsonHazardQuestionDetailsResponse");
        if (jsonHazardQuestionDetailsResponse['result']['status'] == 'success' &&
            jsonHazardQuestionDetailsResponse['result']['swms_register_data'].isNotEmpty) {
          print("Fetched hazard questions: $hazardQuestionDetails");

          // Filter hazard questions where category_id is in categoryIds
          hazard_question_items = List<Map<String, dynamic>>.from(
              jsonHazardQuestionDetailsResponse['result']['swms_register_data'].where((question) {
            final categoryId = question['category_id'];
            if (categoryId != null && categoryId is List) {
              return categoryIds.contains(categoryId[
                  0]); // Assuming category_id is in [id, name] format
            }
            return false;
          }));

          print("Filtered hazard questions: $hazard_question_items");
        } else {
          print("No hazard questions found.");
        }
      } catch (e) {
        print("Error fetching hazard questions: $e");
      }
    } else {
      loadHazardQuestion(widget.projectId);
    }
  }

  Future<void> loadHazardQuestion(int projectId) async {
    try {
      var box =
          await Hive.openBox<HazardQuestion>('hazardQuestions_$projectId');
      if (box.isEmpty) {
        print("No hazard questions found for project ID: $projectId");
        return;
      }
      List<HazardQuestion> hazardQuestions = box.values.toList();
      List<Map<String, dynamic>> hazardQuestionMaps =
          hazardQuestions.map((question) {
        return {
          'id': question.id,
          'installation_question': question.installationQuestion,
          'job_activity': question.job_activity,
          'risk_control': question.riskControl,
          'category_id': question.categoryId,
        };
      }).toList();
      print(
          "Loaded hazard questions for project ID $projectId: $hazardQuestionMaps");

      hazard_question_items = hazardQuestionMaps;
    } catch (e) {
      print("Error while loading hazard questions from Hive: $e");
    }
  }

  Future<void> _initializeOdooClient() async {
    print("clientssssssssssssssssssss");
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

  Future<void> loadSelectedRiskItems() async {
    final prefs = await SharedPreferences.getInstance();
    final teamId = prefs.getInt('teamId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    if (isNetworkAvailable) {
      print("Selectexxxxxxxxxxxxxxxxxd Details:xxxxxxxxxxxxxxxx ${widget.selectedDetails}");
      final selectedTypes =
          widget.selectedDetails.map((item) => item['value']).toList();
      print("$client/ddddddddddddddddddddddddddddddddddddd");
      print(selectedTypes);
      print("selectedTypesselectedTypes");
      try {
        // final swmslist = await client?.callKw({
        //   'model': 'swms.risk.work',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       ['type', 'in', selectedTypes],
        //     ]
        //   ],
        //   'kwargs': {},
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/swms_risk_work');
        final swmslist = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "type": selectedTypes,

            }
          }),
        );
        final Map<String, dynamic> jsonSWMSListResponse = json.decode(swmslist.body);
        print(jsonSWMSListResponse);
        print("jsonSWMSListResponsejsonSWMSListResponse");
        // if (productFromProject != null && productFromProject.isNotEmpty) {
        if (jsonSWMSListResponse['result']['status'] == 'success' &&
            jsonSWMSListResponse['result']['swms_risk_work_data'].isNotEmpty) {
          print(swmslist);
          print("swmslistswmslistswmslistswmslist");
          if (jsonSWMSListResponse['result']['swms_risk_work_data'] != null) {
            setState(() {
              swmsDetails = jsonSWMSListResponse['result']['swms_risk_work_data'].map<Map<String, dynamic>>((item) {
                return {
                  'name': item['name'] ?? 'N/A',
                  'type': item['type'] ?? 'N/A',
                };
              }).toList();
            });
            print("Fetched swmsDetails: $swmsDetails");
          }
        }
      } catch (e) {
        print("Error loading SWMS details: $e");
      }
    } else {
      List<Map<String, dynamic>> hiveSWMSDetails =
          await loadSWMSDetailsFromHive();
      setState(() {
        swmsDetails = hiveSWMSDetails.map<Map<String, dynamic>>((item) {
          return {
            'name': item['name'] ?? 'N/A',
            'type': item['type'] ?? 'N/A',
          };
        }).toList();
      });
    }
  }

  Future<List<Map<String, dynamic>>> loadSWMSDetailsFromHive() async {
    try {
      var box = await Hive.openBox<SWMSDetail>('swmsDetailsBox');
      List<SWMSDetail> swmsList = box.values.toList();
      print("Loaded SWMS Details from Hive: $swmsList");

      List<Map<String, dynamic>> swmsDetails = swmsList
          .map((item) => {
                'name': item.name,
                'type': item.type,
              })
          .toList();

      List<Map<String, dynamic>> uniqueDetails = swmsDetails
          .map((item) => '${item['name']}-${item['type']}')
          .toSet()
          .map((uniqueKey) {
        List<String> parts = uniqueKey.split('-');
        return {'name': parts[0], 'type': parts[1]};
      }).toList();

      print("Unique SWMS Details: $uniqueDetails");
      return uniqueDetails;
    } catch (e) {
      print("Error while loading SWMS details from Hive: $e");
      return [];
    }
  }

  List<String> allowedRiskTypes = [
    "Hi-Vis",
    "Steel cap boots",
    "Gloves",
    "Eye protection",
    "Hearing protection",
    "Hard Hat",
    "Respirator",
    "Long Sleeve & Trousers"
  ];

  Widget _getIconForType(String type) {
    switch (type) {
      case 'cranes':
        return Image.asset(
          'assets/cranes.png',
          height: 24,
          width: 24,
          fit: BoxFit.cover,
          color: Colors.blue,
        );
      case 'hoists':
        return Image.asset(
          'assets/hoists.png',
          height: 24,
          width: 24,
          fit: BoxFit.cover,
          color: Colors.blue,
        );
      case 'scaffolding':
        return Image.asset(
          'assets/scaffolding.png',
          height: 24,
          width: 24,
          fit: BoxFit.cover,
          color: Colors.blue,
        );
      case 'forklift':
        return Image.asset(
          'assets/forklift.png',
          height: 24,
          width: 24,
          fit: BoxFit.cover,
          color: Colors.blue,
        );
      case 'dogging_rigging':
        return Image.asset(
          'assets/dogging_rigging.png',
          height: 24,
          width: 24,
          fit: BoxFit.cover,
          color: Colors.blue,
        );
      default:
        return Icon(Icons.device_unknown, color: Colors.grey, size: 24);
    }
  }

  Widget _getIconForRiskType(String riskType) {
    switch (riskType) {
      case 'Hi-Vis':
        return Image.asset(
          'assets/hi-vis.png',
          height: 24,
          width: 24,
          fit: BoxFit.cover,
          color: Colors.blue,
        );
      case 'Steel cap boots':
        return Image.asset(
          'assets/steel_cap_boots.png',
          height: 24,
          width: 24,
          fit: BoxFit.cover,
          color: Colors.blue,
        );
      case 'Gloves':
        return Image.asset(
          'assets/gloves.png',
          height: 24,
          width: 24,
          fit: BoxFit.cover,
          color: Colors.blue,
        );
      case 'Eye protection':
        return Image.asset(
          'assets/eye_protection.png',
          height: 24,
          width: 24,
          fit: BoxFit.cover,
          color: Colors.blue,
        );
      case 'Hearing protection':
        return Image.asset(
          'assets/hearing_protection.png',
          height: 24,
          width: 24,
          fit: BoxFit.cover,
          color: Colors.blue,
        );
      case 'Hard Hat':
        return Image.asset(
          'assets/hard_hat.png',
          height: 24,
          width: 24,
          fit: BoxFit.cover,
          color: Colors.blue,
        );
      case 'Respirator':
        return Image.asset(
          'assets/respirator.png',
          height: 24,
          width: 24,
          fit: BoxFit.cover,
          color: Colors.blue,
        );
      case 'Long Sleeve & Trousers':
        return Image.asset(
          'assets/long_sleeve_&_trousers.png',
          height: 24,
          width: 24,
          fit: BoxFit.cover,
          color: Colors.blue,
        );
      default:
        return Icon(Icons.device_unknown, color: Colors.grey, size: 24);
    }
  }

  Future<bool> _onWillPop() async {
    print(widget.args);
    var newargs = Map<String, dynamic>.from(widget.args);
    Navigator.popAndPushNamed(
      context,
      '/installing_form_view',
      arguments: newargs,
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    print(
        "SelectopenBox<SWMSDetail>('swmsDetailsBoed Details: ${widget.selectedDetails}");
    return WillPopScope(
      onWillPop: () async {
        _onWillPop();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.green[100],
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: Text(
            "Risk Assessment",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
          ),
          // centerTitle: true,
          automaticallyImplyLeading: false,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          elevation: 5,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Material Handling and Lifting Systems",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[600],
                    ),
                  ),
                ),
                Card(
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    children: widget.allowedTypes.map((type) {
                      String formattedType =
                          type.replaceAll('_', ' ').toUpperCase();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            title: Row(
                              children: [
                                _getIconForType(type),
                                SizedBox(width: 10),
                                Text(
                                  formattedType,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            value: widget.selectedCheckboxes[type],
                            onChanged: (bool? value) async {
                              if (value == true) {
                                widget.selectedDetails.add({'value': type});
                                await loadSelectedRiskItems();
                                print(
                                    "$swmsDetails/swmsDetailsswmsDetailsswmsDetails");
                              } else {
                                widget.selectedDetails.removeWhere(
                                    (detail) => detail['value'] == type);
                                widget.dropdownValues[type] = null;
                              }

                              setState(() {
                                widget.selectedCheckboxes[type] =
                                    value ?? false;
                              });

                              print(
                                  "Selected Details: ${widget.selectedDetails}");
                            },
                          ),
                          if (widget.selectedCheckboxes[type] == true)
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText:
                                            "Select an Option for $formattedType",
                                        border: OutlineInputBorder(),
                                      ),
                                      value: widget.dropdownValues[type],
                                      items: swmsDetails
                                          .where((item) => item['type'] == type)
                                          .map((dropdownItem) =>
                                              DropdownMenuItem<String>(
                                                value: dropdownItem['name'],
                                                child:
                                                    Text(dropdownItem['name']),
                                              ))
                                          .toList(),
                                      onChanged: (String? value) {
                                        setState(() {
                                          widget.dropdownValues[type] = value;
                                        });
                                        print(
                                            "Dropdown value for $type: ${widget.dropdownValues[type]}");
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          SizedBox(height: 20),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Safety Equipments",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[600],
                    ),
                  ),
                ),
                Card(
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    children: allowedRiskTypes.map((riskType) {
                      String formattedRiskType =
                          riskType.replaceAll('_', ' ').toUpperCase();
                      Widget icon = _getIconForRiskType(riskType);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            title: Row(
                              children: [
                                icon,
                                SizedBox(width: 10),
                                Text(
                                  formattedRiskType,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            value:
                                widget.selectedRiskItemCheckboxes[riskType] ??
                                    false,
                            onChanged: (bool? value) async {
                              if (value == true) {
                                widget.selectedDetails.add({'value': riskType});
                                widget.dropdownRiskItemsValues[riskType] ??=
                                    'site_entry';
                              } else {
                                widget.selectedDetails.removeWhere(
                                    (detail) => detail['value'] == riskType);
                                widget.dropdownRiskItemsValues[riskType] = null;
                                widget.specificTaskDetails[riskType] = "";
                              }

                              setState(() {
                                widget.selectedRiskItemCheckboxes[riskType] =
                                    value ?? false;
                              });
                            },
                          ),
                          if (widget.selectedRiskItemCheckboxes[riskType] ==
                              true)
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText:
                                            "Select an Option for $formattedRiskType",
                                        border: OutlineInputBorder(),
                                      ),
                                      value: widget.dropdownRiskItemsValues[
                                              riskType] ??
                                          'site_entry',
                                      items: [
                                        {
                                          'display': 'Required for Site Entry',
                                          'value': 'site_entry'
                                        },
                                        {
                                          'display':
                                              'Required for Specific Task',
                                          'value': 'specific_task'
                                        },
                                      ]
                                          .map((option) =>
                                              DropdownMenuItem<String>(
                                                value: option['value'],
                                                child: Text(
                                                    option['display'] ?? ""),
                                              ))
                                          .toList(),
                                      onChanged: (String? value) {
                                        setState(() {
                                          widget.dropdownRiskItemsValues[
                                              riskType] = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (widget.selectedRiskItemCheckboxes[riskType] ==
                                  true &&
                              widget.dropdownRiskItemsValues[riskType] ==
                                  'specific_task')
                            SizedBox(height: 10),
                          if (widget.selectedRiskItemCheckboxes[riskType] ==
                                  true &&
                              widget.dropdownRiskItemsValues[riskType] ==
                                  'specific_task')
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText:
                                      'Enter details for the specific task',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (text) {
                                  setState(() {
                                    widget.specificTaskDetails[riskType] = text;
                                  });
                                },
                              ),
                            ),
                          SizedBox(height: 20),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              bool anyCheckboxSelected = widget.selectedCheckboxes.values
                  .any((isSelected) => isSelected);
              bool allSelectedDropdownsChosen =
                  widget.selectedCheckboxes.entries.every((entry) {
                if (entry.value == true) {
                  return widget.dropdownValues[entry.key] != null;
                }
                return true;
              });
              if (!anyCheckboxSelected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Info",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "Please select at least one risk type.",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 3),
                  ),
                );
              } else if (!allSelectedDropdownsChosen) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Info",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "Please select a value for all selected risk types.",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 3),
                  ),
                );
              } else {
                List<Map<String, String>> selectedNamesWithType =
                    widget.dropdownValues.entries
                        .where((entry) => entry.value != null)
                        .map((entry) => {
                              'name': entry.value!,
                              'type': entry.key,
                            })
                        .toList();
                if (widget.team_member_ids.isNotEmpty) {
                  if (hazard_question_items.isNotEmpty)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HazardsPage(
                                args: widget.args,
                                worksheetId: widget.worksheetId,
                                memberId: widget.memberId,
                                hazardQuestionItems: hazard_question_items,
                                selectedNamesWithType: selectedNamesWithType,
                                allowedTypes: widget.allowedTypes,
                                selectedDetailes: widget.selectedDetails,
                                categIdList: widget.categIdList,
                                workTypeIdList: widget.workTypeIdList,
                                projectId: widget.projectId,
                                selectedCheckboxes: widget.selectedCheckboxes,
                                selectedRiskItemCheckboxes:
                                widget.selectedRiskItemCheckboxes,
                                dropdownValues: widget.dropdownValues,
                                dropdownRiskItemsValues: widget
                                    .dropdownRiskItemsValues,
                                specificTaskDetails: widget.specificTaskDetails,
                                team_member_ids: widget.team_member_ids,
                                taskDetails: taskDetails,
                                hazardResponses: widget.hazardResponses),
                      ),
                    );
                }
                else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RiskAssessmentOverviewWithoutHazardsPage(
                            args: widget.args,
                            worksheetId: widget.worksheetId,
                            memberId: widget.memberId,
                            selectedNamesWithType: selectedNamesWithType,
                            selectedDetails: widget.selectedDetails,
                            allowedTypes: widget.allowedTypes,
                            categIdList: widget.categIdList,
                            workTypeIdList: widget.workTypeIdList,
                            projectId: widget.projectId,
                            selectedCheckboxes: widget.selectedCheckboxes,
                            selectedRiskItemCheckboxes: widget
                                .selectedRiskItemCheckboxes,
                            dropdownValues: widget.dropdownValues,
                            dropdownRiskItemsValues: widget
                                .dropdownRiskItemsValues,
                            specificTaskDetails: widget.specificTaskDetails,
                            team_member_ids: widget.team_member_ids,
                          ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Continue",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HazardsPage extends StatefulWidget {
  final List<Map<String, dynamic>> hazardQuestionItems;
  final int worksheetId;
  final int memberId;
  final int projectId;
  final List<Map<String, String>> selectedNamesWithType;
  final List<String> allowedTypes;
  final List<dynamic> categIdList;
  final List<dynamic> workTypeIdList;
  final List<Map<String, dynamic>> selectedDetailes;
  final Map<String, bool> selectedCheckboxes;
  final Map<String, bool> selectedRiskItemCheckboxes;
  Map<String, String?> dropdownValues = {};
  Map<String, String?> dropdownRiskItemsValues = {};
  Map<String, String> specificTaskDetails = {};
  List<int> team_member_ids = [];
  Map<int, String> hazardResponses = {};
  var args;
  String taskDetails;

  HazardsPage(
      {required this.args,
      required this.hazardQuestionItems,
      required this.worksheetId,
      required this.memberId,
      required this.projectId,
      required this.selectedNamesWithType,
      required this.allowedTypes,
      required this.categIdList,
      required this.workTypeIdList,
      required this.selectedDetailes,
      required this.selectedCheckboxes,
      required this.selectedRiskItemCheckboxes,
      required this.dropdownValues,
      required this.dropdownRiskItemsValues,
      required this.specificTaskDetails,
      required this.team_member_ids,
      required this.hazardResponses,
      required this.taskDetails});

  @override
  _HazardsPageState createState() => _HazardsPageState();
}

class _HazardsPageState extends State<HazardsPage> {
  Map<int, String> hazardResponses = {};
  OdooClient? client;
  String url = "";
  bool success = false;
  bool isLoading = false;

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       backgroundColor: Colors.green,
  //       title: Text(
  //         "Hazards",
  //         style: TextStyle(
  //             fontWeight: FontWeight.bold,
  //             fontSize: 22,
  //             color: Colors.white
  //         ),
  //       ),
  //         // centerTitle: true,
  //         automaticallyImplyLeading: true,
  //         iconTheme: const IconThemeData(
  //           color: Colors.white,
  //         ),
  //         elevation: 5,
  //     ),
  //     body: widget.hazardQuestionItems.isEmpty
  //         ? Expanded(
  //             child: Center(
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Icon(
  //                     Icons.question_answer,
  //                     color: Colors.black,
  //                     size: 92,
  //                   ),
  //                   SizedBox(height: 20),
  //                   Text(
  //                     "There are no Hazard Questions available to display",
  //                     style: TextStyle(
  //                       fontSize: 16.0,
  //                       color: Colors.black,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           )
  //         : SingleChildScrollView(
  //             child: Padding(
  //               padding: const EdgeInsets.symmetric(horizontal: 16.0),
  //               child: Column(
  //                 children: [
  //                   ListView.builder(
  //                     physics: NeverScrollableScrollPhysics(),
  //                     shrinkWrap: true,
  //                     itemCount: widget.hazardQuestionItems.length,
  //                     itemBuilder: (context, index) {
  //                       final questionId =
  //                           widget.hazardQuestionItems[index]['id'];
  //                       final questionText = widget.hazardQuestionItems[index]
  //                           ['installation_question'];
  //                       final questionControlText =
  //                           widget.hazardQuestionItems[index]['risk_control'];
  //                       final slNumber = index + 1;
  //                       return Padding(
  //                         padding: const EdgeInsets.symmetric(vertical: 8.0),
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.center,
  //                           children: [
  //                             Text(
  //                               "$slNumber.  $questionText",
  //                               textAlign: TextAlign.center,
  //                               style: TextStyle(
  //                                 color: Colors.red,
  //                                 fontWeight: FontWeight.bold,
  //                                 fontSize: 18,
  //                               ),
  //                             ),
  //                             SizedBox(height: 8),
  //                             Text(
  //                               "($questionControlText)",
  //                               textAlign: TextAlign.center,
  //                               style: TextStyle(
  //                                 color: Colors.black,
  //                                 fontWeight: FontWeight.bold,
  //                                 fontSize: 16,
  //                               ),
  //                             ),
  //                             SizedBox(height: 20),
  //                             Row(
  //                               mainAxisAlignment: MainAxisAlignment.center,
  //                               children: [
  //                                 _buildCustomButton(
  //                                   text: "Yes",
  //                                   isSelected:
  //                                       widget.hazardResponses[questionId] ==
  //                                           "Yes",
  //                                   onTap: () {
  //                                     setState(() {
  //                                       widget.hazardResponses[questionId] =
  //                                           "Yes";
  //                                     });
  //                                   },
  //                                 ),
  //                                 SizedBox(width: 16),
  //                                 _buildCustomButton(
  //                                   text: "No",
  //                                   isSelected:
  //                                       widget.hazardResponses[questionId] ==
  //                                           "No",
  //                                   onTap: () {
  //                                     setState(() {
  //                                       widget.hazardResponses[questionId] =
  //                                           "No";
  //                                     });
  //                                   },
  //                                 ),
  //                               ],
  //                             ),
  //                             SizedBox(height: 20),
  //                           ],
  //                         ),
  //                       );
  //                     },
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //     bottomNavigationBar: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: ElevatedButton(
  //         onPressed: () async {
  //           print("gggggggggggggg${widget.taskDetails}");
  //           List<int> unansweredQuestions = [];
  //           print(widget.hazardQuestionItems);
  //           for (var question in widget.hazardQuestionItems) {
  //             print("fffffffffffffffff");
  //             final questionId = question['id'];
  //             print(questionId);
  //             if (!widget.hazardResponses.containsKey(questionId)) {
  //               unansweredQuestions.add(questionId);
  //             }
  //           }
  //
  //           if (unansweredQuestions.isNotEmpty) {
  //             final unansweredText = unansweredQuestions.join(", ");
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               SnackBar(
  //                 content: Row(
  //                   children: [
  //                     Icon(Icons.warning, color: Colors.white),
  //                     SizedBox(width: 8),
  //                     Expanded(
  //                       child: Column(
  //                         mainAxisSize: MainAxisSize.min,
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Text(
  //                             "Info",
  //                             style: TextStyle(
  //                               fontWeight: FontWeight.bold,
  //                               color: Colors.white,
  //                               fontSize: 16,
  //                             ),
  //                           ),
  //                           Text(
  //                             "Please answer the following question(s): $unansweredText",
  //                             style: TextStyle(color: Colors.white),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 backgroundColor: Colors.red,
  //                 behavior: SnackBarBehavior.floating,
  //                 duration: Duration(seconds: 3),
  //               ),
  //             );
  //             return;
  //           }
  //
  //           List<Map<String, dynamic>> responses = [];
  //           widget.hazardResponses.forEach((questionId, response) {
  //             responses.add({
  //               'id': questionId,
  //               'response': response,
  //             });
  //           });
  //           print("wddddddddddddddddddddd${widget.hazardResponses}");
  //           await uploadRiskItems();
  //           await uploadRequiredItemsForWork();
  //           await uploadHazardResponse(responses);
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(
  //               builder: (context) => RiskAssessmentOverviewPage(
  //                 args: widget.args,
  //                 responses: responses,
  //                 hazardResponses: widget.hazardResponses,
  //                 hazard_question_items: widget.hazardQuestionItems,
  //                 worksheetId: widget.worksheetId,
  //                 selectedNamesWithType: widget.selectedNamesWithType,
  //                 selectedDetails: widget.selectedDetailes,
  //                 allowedTypes: widget.allowedTypes,
  //                 categIdList: widget.categIdList,
  //                 projectId: widget.projectId,
  //                 selectedCheckboxes: widget.selectedCheckboxes,
  //                 selectedRiskItemCheckboxes: widget.selectedRiskItemCheckboxes,
  //                 dropdownValues: widget.dropdownValues,
  //                 dropdownRiskItemsValues: widget.dropdownRiskItemsValues,
  //                 specificTaskDetails: widget.specificTaskDetails,
  //                 team_member_ids: widget.team_member_ids,
  //               ),
  //             ),
  //           );
  //         },
  //
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: Colors.green,
  //         ),
  //         child: Text(
  //           "Submit Responses",
  //           style: TextStyle(
  //             color: Colors.white,
  //             fontWeight: FontWeight.bold,
  //             fontSize: 15,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    final uniqueHazardQuestionItems = widget.hazardQuestionItems
        .fold<List<Map<String, dynamic>>>([], (uniqueList, item) {
      if (!uniqueList.any(
          (q) => q['installation_question'] == item['installation_question'])) {
        uniqueList.add(item);
      }
      return uniqueList;
    });
    return Scaffold(
      backgroundColor: Colors.green[100],
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "Hazards",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        elevation: 5,
      ),
      body: uniqueHazardQuestionItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.question_answer,
                    color: Colors.green,
                    size: 92,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "There are no Hazard Questions available to display",
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: uniqueHazardQuestionItems.length,
                          itemBuilder: (context, index) {
                            // final questionId =
                            //     widget.hazardQuestionItems[index]['id'];
                            // final questionText = widget.hazardQuestionItems[index]
                            //     ['installation_question'];
                            // final questionControlText =
                            //     widget.hazardQuestionItems[index]['risk_control'];
                            final questionId =
                                uniqueHazardQuestionItems[index]['id'];
                            final activityText =
                                uniqueHazardQuestionItems[index]
                                    ['job_activity'];
                            final questionControlText =
                                uniqueHazardQuestionItems[index]
                                    ['risk_control'];

                            final slNumber = index + 1;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "$slNumber.   $activityText",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "$questionControlText",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _buildCustomButton(
                                            text: "Yes",
                                            icon: Icons.check_circle,
                                            isSelected: widget.hazardResponses[
                                                    questionId] ==
                                                "Yes",
                                            onTap: () {
                                              setState(() {
                                                widget.hazardResponses[
                                                    questionId] = "Yes";
                                              });
                                            },
                                          ),
                                          SizedBox(width: 16),
                                          _buildCustomButton(
                                            text: "No",
                                            icon: Icons.cancel,
                                            isSelected: widget.hazardResponses[
                                                    questionId] ==
                                                "No",
                                            onTap: () {
                                              setState(() {
                                                widget.hazardResponses[
                                                    questionId] = "No";
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (isLoading)
                  Center(
                    child:
                        CircularProgressIndicator(), // Loading spinner in the center
                  ),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () async {
            List<int> unansweredQuestions = [];
            for (var question in widget.hazardQuestionItems) {
              final questionId = question['id'];
              if (!widget.hazardResponses.containsKey(questionId)) {
                unansweredQuestions.add(questionId);
              }
            }

            if (unansweredQuestions.isNotEmpty) {
              final unansweredText = unansweredQuestions.join(", ");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Info",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Please answer the following question(s): $unansweredText",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 3),
                ),
              );
              return;
            }

            List<Map<String, dynamic>> responses = [];
            widget.hazardResponses.forEach((questionId, response) {
              responses.add({
                'id': questionId,
                'response': response,
              });
            });
            setState(() {
              isLoading = true;
            });
            await uploadRiskItems();
            await uploadRequiredItemsForWork();
            await uploadHazardResponse(responses);
            setState(() {
              isLoading = false;
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RiskAssessmentOverviewPage(
                  args: widget.args,
                  responses: responses,
                  hazardResponses: widget.hazardResponses,
                  hazard_question_items: widget.hazardQuestionItems,
                  worksheetId: widget.worksheetId,
                  memberId: widget.memberId,
                  selectedNamesWithType: widget.selectedNamesWithType,
                  selectedDetails: widget.selectedDetailes,
                  allowedTypes: widget.allowedTypes,
                  categIdList: widget.categIdList,
                  workTypeIdList: widget.workTypeIdList,
                  projectId: widget.projectId,
                  selectedCheckboxes: widget.selectedCheckboxes,
                  selectedRiskItemCheckboxes: widget.selectedRiskItemCheckboxes,
                  dropdownValues: widget.dropdownValues,
                  dropdownRiskItemsValues: widget.dropdownRiskItemsValues,
                  specificTaskDetails: widget.specificTaskDetails,
                  team_member_ids: widget.team_member_ids,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              "Submit Responses",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> uploadRiskItems() async {
    // await _initializeOdooClient();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;

    var dropdownValues = widget.dropdownValues;

    var cranesId = await getIdFromName(dropdownValues['cranes']);
    var hoistsId = await getIdFromName(dropdownValues['hoists']);
    var scaffoldingId = await getIdFromName(dropdownValues['scaffolding']);
    var forkliftId = await getIdFromName(dropdownValues['forklift']);
    var doggingRiggingId =
        await getIdFromName(dropdownValues['dogging_rigging']);
    var fieldValues = {
      'worksheet_id': widget.worksheetId,
      'cranes_ids': cranesId != null ? [cranesId] : [],
      'hoists_ids': hoistsId != null ? [hoistsId] : [],
      'scaffolding_ids': scaffoldingId != null ? [scaffoldingId] : [],
      'forklift_ids': forkliftId != null ? [forkliftId] : [],
      'dogging_rigging_ids': doggingRiggingId != null ? [doggingRiggingId] : [],
    };

    print("Field valuessssssssssss: $fieldValues");

    var args = [
      widget.worksheetId,
      fieldValues,
    ];
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      try {
        final box = await Hive.openBox<RiskItem>('riskItems');
        final riskItem =
            RiskItem(worksheetId: widget.worksheetId, fieldValues: fieldValues);
        await box.put(widget.worksheetId, riskItem);
        print(
            '${box.values.toList()} Data stored in Hive since network is unavailable');
        await box.close();
        print('Hive box closed');
      } catch (e) {
        print('Failed to store data in Hive: $e');
      }
    } else {
      try {
        // final worksheetDetails = await client?.callKw({
        //   'model': 'task.worksheet',
        //   'method': 'write',
        //   'args': args,
        //   'kwargs': {},
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/task_worksheet/write');
        final worksheetDetails = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": fieldValues
          }),
        );
        final Map<String, dynamic> jsonWorksheetDetailsResponse = json.decode(worksheetDetails.body);

        if (jsonWorksheetDetailsResponse['result']['status'] == 'success') {
        // if (worksheetDetails != null) {
          print('Worksheet updated successfully: $worksheetDetails');
        } else {
          print('Failed to update worksheet');
        }
      } catch (e) {
        print('Error occurred during write operation: $e');
      }
    }
  }

  // Future<void> uploadRequiredItemsForWork() async {
  //   await _initializeOdooClient();
  //
  //   var dropdownRiskItemsValues = widget.dropdownRiskItemsValues;
  //   print(dropdownRiskItemsValues);
  //   print("dropdownRiskItemsValuesdropdownRiskItemsValuesdropdownRiskItemsValues");
  //   //
  //   var hi_vis = dropdownRiskItemsValues['Hi-Vis'];
  //   var steel_cap_boots = dropdownRiskItemsValues['Steel cap boots'];
  //   var gloves = dropdownRiskItemsValues['Gloves'];
  //   print(gloves);
  //   print("llllllllllllllllllllllllllllllllllllllllllllll");
  //   var eye_protection = dropdownRiskItemsValues['Eye protection'];
  //   var hearing_protection = dropdownRiskItemsValues['Hearing protection'];
  //   var hard_hat = dropdownRiskItemsValues['Hard Hat'];
  //   var respirator = dropdownRiskItemsValues['Respirator'];
  //   var long_sleeve_trousers = dropdownRiskItemsValues['Long Sleeve & Trousers'];
  //   var fieldValues = {
  //     'hi_vis': hi_vis ?? null,
  //     'steel_cap_boots': steel_cap_boots ?? null,
  //     'gloves': gloves ?? null,
  //     'eye_protection': eye_protection ?? null,
  //     'hearing_protection': hearing_protection ?? null,
  //     'hard_hat': hard_hat ?? null,
  //     'respirator': respirator ?? null,
  //     'long_sleeve_trousers': long_sleeve_trousers ?? null,
  //   };
  //
  //
  //   print("Field valuessssssssssss: $fieldValues");
  //
  //   var args = [
  //     widget.worksheetId,
  //     fieldValues,
  //   ];
  //
  //   try {
  //     final worksheetDetails = await client?.callKw({
  //       'model': 'task.worksheet',
  //       'method': 'write',
  //       'args': args,
  //       'kwargs': {},
  //     });
  //
  //     if (worksheetDetails != null) {
  //       print('Worksheet updatedddddddddddddddddddddddddddddddddd successfully: $worksheetDetails');
  //     } else {
  //       print('Failed to update worksheet');
  //     }
  //   } catch (e) {
  //     print('Error occurred during write operation: $e');
  //   }
  // }
  Future<void> uploadRequiredItemsForWork() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('url') ?? 0;

    var dropdownRiskItemsValues = widget.dropdownRiskItemsValues;
    print(dropdownRiskItemsValues);
    print(
        "dropdownRiskItemsValuesdropdownRiskItemsValuesdropdownRiskItemsValues");

    var hi_vis = dropdownRiskItemsValues['Hi-Vis'];
    var steel_cap_boots = dropdownRiskItemsValues['Steel cap boots'];
    var gloves = dropdownRiskItemsValues['Gloves'];
    print(gloves);
    print("llllllllllllllllllllllllllllllllllllllllllllll");
    var eye_protection = dropdownRiskItemsValues['Eye protection'];
    var hearing_protection = dropdownRiskItemsValues['Hearing protection'];
    var hard_hat = dropdownRiskItemsValues['Hard Hat'];
    var respirator = dropdownRiskItemsValues['Respirator'];
    var long_sleeve_trousers =
        dropdownRiskItemsValues['Long Sleeve & Trousers'];

    var hi_vis_text = widget.specificTaskDetails['Hi-Vis'];
    var steel_cap_boots_text = widget.specificTaskDetails['Steel cap boots'];
    var gloves_text = widget.specificTaskDetails['Gloves'];
    var eye_protection_text = widget.specificTaskDetails['Eye protection'];
    var hearing_protection_text =
        widget.specificTaskDetails['Hearing protection'];
    var hard_hat_text = widget.specificTaskDetails['Hard Hat'];
    var respirator_text = widget.specificTaskDetails['Respirator'];
    var long_sleeve_trousers_text =
        widget.specificTaskDetails['Long Sleeve & Trousers'];

    var fieldValues = {
      'worksheet_id': widget.worksheetId,
      'hi_vis': hi_vis ?? null,
      'hi_vis_text': (hi_vis != null &&
              dropdownRiskItemsValues['Hi-Vis'] == 'specific_task')
          ? hi_vis_text
          : null,
      'steel_cap_boots': steel_cap_boots ?? null,
      'steel_cap_boots_text': (steel_cap_boots != null &&
              dropdownRiskItemsValues['Steel cap boots'] == 'specific_task')
          ? steel_cap_boots_text
          : null,
      'gloves': gloves ?? null,
      'gloves_text': (gloves != null &&
              dropdownRiskItemsValues['Gloves'] == 'specific_task')
          ? gloves_text
          : null,
      'eye_protection': eye_protection ?? null,
      'eye_protection_text': eye_protection_text ?? null,
      'hearing_protection': hearing_protection ?? null,
      'hearing_protection_text': hearing_protection_text ?? null,
      'hard_hat': hard_hat ?? null,
      'hard_hat_text': hard_hat_text ?? null,
      'respirator': respirator ?? null,
      'respirator_text': respirator_text ?? null,
      'long_sleeve_trousers': long_sleeve_trousers ?? null,
      'long_sleeve_trousers_text': long_sleeve_trousers_text ?? null,
    };

    print("Field valuessssssssssss: $fieldValues");

    var args = [
      widget.worksheetId,
      fieldValues,
    ];
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      try {
        final box = await Hive.openBox<SafetyItems>('safetyItems');
        final safetyItem = SafetyItems(
            worksheetId: widget.worksheetId, fieldValues: fieldValues);
        await box.put(widget.worksheetId, safetyItem);
        print(
            '${box.values.toList()} Data stored in Hive since network is unavailable');
        await box.close();
        print('Hive box closed');
      } catch (e) {
        print('Failed to store data in Hive: $e');
      }
    } else {
      try {
        // final worksheetDetails = await client?.callKw({
        //   'model': 'task.worksheet',
        //   'method': 'write',
        //   'args': args,
        //   'kwargs': {},
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/task_worksheet/write');
        final worksheetDetails = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": fieldValues
          }),
        );
        final Map<String, dynamic> jsonWorksheetDetailsResponse = json.decode(worksheetDetails.body);

        if (jsonWorksheetDetailsResponse['result']['status'] == 'success') {

          // if (worksheetDetails != null) {
          print(
              'Worksheet updatedddddddddddddddddddddddddddddddddd successfully: $worksheetDetails');
        } else {
          print('Failed to update worksheet');
        }
      } catch (e) {
        print('Error occurred during write operation: $e');
      }
    }
  }

  List<Map<String, dynamic>> riskWorkItemsWithIds = [
    {"id": 1, "item": "Tower crane", "type": "cranes"},
    {"id": 2, "item": "Self-erecting tower crane", "type": "cranes"},
    {"id": 3, "item": "Derrick crane", "type": "cranes"},
    {"id": 4, "item": "Portal boom crane", "type": "cranes"},
    {"id": 5, "item": "Bridge and gantry crane", "type": "cranes"},
    {"id": 6, "item": "Vehicle loading crane", "type": "cranes"},
    {"id": 7, "item": "Non-slewing mobile crane", "type": "cranes"},
    {
      "id": 8,
      "item": "Slewing mobile crane – with a capacity up to 20 tonnes",
      "type": "cranes"
    },
    {
      "id": 9,
      "item": "Slewing mobile crane – with a capacity of up to 60 tonnes",
      "type": "cranes"
    },
    {
      "id": 10,
      "item": "Slewing mobile crane – with a capacity of up to 100 tonnes",
      "type": "cranes"
    },
    {
      "id": 11,
      "item": "Slewing mobile crane – with a capacity of over 100 tonnes",
      "type": "cranes"
    },
    {"id": 12, "item": "Materials hoist", "type": "hoists"},
    {"id": 13, "item": "Personnel and materials hoist", "type": "hoists"},
    {"id": 14, "item": "Boom-type elevating work platform", "type": "hoists"},
    {"id": 15, "item": "Concrete placing boom", "type": "hoists"},
    {"id": 16, "item": "Basic scaffolding", "type": "scaffolding"},
    {"id": 17, "item": "Intermediate scaffolding", "type": "scaffolding"},
    {"id": 18, "item": "Advanced scaffolding", "type": "scaffolding"},
    {"id": 19, "item": "Basic scaffolding", "type": "dogging_rigging"},
    {"id": 20, "item": "Intermediate scaffolding", "type": "dogging_rigging"},
    {"id": 21, "item": "Advanced scaffolding", "type": "dogging_rigging"},
    {"id": 22, "item": "Forklift", "type": "forklift"}
  ];

  Future<int?> getIdFromName(String? name) async {
    final prefs = await SharedPreferences.getInstance();
    final teamId = prefs.getInt('teamId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    print(client);
    print("namenamenamenameedeeeeeeeeeee");
    if (name == null || name.isEmpty) return null;

    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        final localResult = riskWorkItemsWithIds.firstWhere(
          (item) => item['item'] == name,
          orElse: () => {},
        );
        if (localResult != null) {
          print('ID found locally for name $name: ${localResult['id']}');
          return localResult['id'];
        }
      } else {
        // final result = await client?.callKw({
        //   'model': 'swms.risk.work',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       ['name', '=', name],
        //     ]
        //   ],
        //   'kwargs': {
        //     'fields': ['id']
        //   },
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/swms_risk_register');
        final result = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "name": name
            }
          }),
        );
        final Map<String, dynamic> jsonResultsResponse = json.decode(result.body);
        print("resultresultresult$result");
        // if (result != null && result.isNotEmpty) {
        if (jsonResultsResponse['result']['status'] == 'success' &&
            jsonResultsResponse['result']['swms_register_data'].isNotEmpty) {
          return jsonResultsResponse['result']['swms_register_data'][0]['id'];
        }
      }
    } catch (e) {
      print('Error fetching ID for name $name: $e');
    }
    return null;
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

  Future<void> uploadHazardResponse(
      List<Map<String, dynamic>> responses) async {
    final prefs = await SharedPreferences.getInstance();
    final teamId = prefs.getInt('teamId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    // await _initializeOdooClient();
    print(
        "${widget.team_member_ids} / wodddddddddrksheetIdworksheetIdworksheetId");
    print("$responses / responses");
    final connectivityResult = await (Connectivity().checkConnectivity());
    bool isNetworkAvailable = connectivityResult != ConnectivityResult.none;

    if (!isNetworkAvailable) {
      await _storeInHive(responses, widget.team_member_ids);
    } else {
      for (var memberId in widget.team_member_ids) {
        List<Map<String, dynamic>> createData = responses.map((response) {
          return {
            'installation_question_id': response['id'],
            'team_member_input': response['response'] == 'Yes'
                ? 'yes'
                : response['response'] == 'No'
                    ? 'no'
                    : response['response'],
            'worksheet_id': widget.worksheetId,
            'member_id': memberId
          };
        }).toList();

        for (var data in createData) {
          try {
            // final checkResponse = await client?.callKw({
            //   'model': 'swms.team.member.input',
            //   'method': 'search_read',
            //   'args': [
            //     [
            //       [
            //         'installation_question_id',
            //         '=',
            //         data['installation_question_id']
            //       ],
            //       ['worksheet_id', '=', data['worksheet_id']]
            //     ],
            //     ['id']
            //   ],
            //   'kwargs': {},
            // });
            final Uri url = Uri.parse('$baseUrl/rebates/swms_team_member_input');
            final checkResponse = await http.post(
              url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "jsonrpc": "2.0",
                "method": "call",
                "params": {
                  "worksheetId": data['worksheet_id'],
                  "installationQuestionId": data['installation_question_id']
                }
              }),
            );
            final Map<String, dynamic> jsonCheckResponseResponse = json.decode(checkResponse.body);
            print("jsonCheckResponseResponse$jsonCheckResponseResponse");
            // if (checkResponse != null && checkResponse.isNotEmpty) {
            if (jsonCheckResponseResponse['result']['status'] == 'success' &&
                jsonCheckResponseResponse['result']['swms_team_member_input'].isNotEmpty) {
              final existingRecordId = jsonCheckResponseResponse['result']['swms_team_member_input'][0]['id'];
              // final updateResponse = await client?.callKw({
              //   'model': 'swms.team.member.input',
              //   'method': 'write',
              //   'args': [
              //     existingRecordId,
              //     {
              //       'team_member_input': data['team_member_input'],
              //     }
              //   ],
              //   'kwargs': {},
              // });

              final Uri url = Uri.parse('$baseUrl/rebates/swms_team_member_input/write');
              final updateResponse = await http.post(
                url,
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "jsonrpc": "2.0",
                  "method": "call",
                  "params": {
                    "input_id": existingRecordId,
                    "team_member_input": data['team_member_input'],
                  }
                }),
              );
              final Map<String, dynamic> jsonUpdateResponseResponse = json.decode(updateResponse.body);
              // if (updateResponse != null) {
              if (jsonUpdateResponseResponse['result']['status'] == 'success') {
                print("Hazard response updated successfully");
                success = true;
              } else {
                print("Failed to update hazard response");
              }
            } else {
              // final createResponse = await client?.callKw({
              //   'model': 'swms.team.member.input',
              //   'method': 'create',
              //   'args': [data],
              //   'kwargs': {},
              // });
              final Uri url = Uri.parse('$baseUrl/rebates/swms_team_member_input/create');
              final createResponse = await http.post(
                url,
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "jsonrpc": "2.0",
                  "method": "call",
                  "params": data
                }),
              );
              final Map<String, dynamic> jsonCreateResponseeResponse = json.decode(createResponse.body);

              // if (createResponse != null) {
              if (jsonCreateResponseeResponse['result']['status'] == 'success') {
                print("Hazard response created successfully");
                success = true;
              } else {
                print("Failed to create hazard response");
              }
            }
          } catch (e) {
            print("Error: $e");
          }
        }
      }
    }
  }

  Future<void> _storeInHive(
      List<Map<String, dynamic>> responses, List<int> team_member_ids) async {
    var box = await Hive.openBox<HazardResponse>('hazardResponsesBox');

    for (var response in responses) {
      print("responseresponseresponse$response");
      for (var memberId in team_member_ids) {
        var hazardResponse = HazardResponse(
          installationQuestionId: response['id'],
          teamMemberInput: response['response'] == 'Yes'
              ? 'yes'
              : response['response'] == 'No'
                  ? 'no'
                  : response['response'],
          worksheetId: widget.worksheetId,
          memberId: memberId,
        );
        await box.add(hazardResponse);
      }
    }

    print("Responses stored in Hive due to no network connection.");
    await box.close();
    print("Hive box closed.");
  }

  // Widget _buildCustomButton({
  //   required String text,
  //   required IconData icon,
  //   required bool isSelected,
  //   required VoidCallback onTap,
  // }) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       padding: EdgeInsets.symmetric(vertical: 12, horizontal: 29),
  //       decoration: BoxDecoration(
  //         color: isSelected ? Colors.green : Colors.grey[300],
  //         borderRadius: BorderRadius.circular(24),
  //         boxShadow: isSelected
  //             ? [
  //                 BoxShadow(
  //                   color: Colors.green.withOpacity(0.5),
  //                   blurRadius: 8,
  //                   spreadRadius: 2,
  //                 ),
  //               ]
  //             : [],
  //       ),
  //       child: Text(
  //         text,
  //         style: TextStyle(
  //           color: isSelected ? Colors.white : Colors.black,
  //           fontWeight: FontWeight.bold,
  //           fontSize: 16,
  //         ),
  //       ),
  //     ),
  //   );
  //
  // }
  Widget _buildCustomButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    Color buttonColor = Colors.grey[200]!;
    Color textColor = Colors.green;
    Color iconColor = Colors.green;

    if (text == "Yes") {
      buttonColor = isSelected ? Colors.green : Colors.grey[200]!;
      textColor = isSelected ? Colors.white : Colors.green;
      iconColor = isSelected ? Colors.white : Colors.green;
    } else if (text == "No") {
      buttonColor = isSelected ? Colors.red : Colors.grey[200]!;
      textColor = isSelected ? Colors.white : Colors.red;
      iconColor = isSelected ? Colors.white : Colors.red;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: textColor, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RiskAssessmentOverviewPage extends StatefulWidget {
  final List<Map<String, dynamic>> responses;
  final Map<int, String> hazardResponses;
  final List<Map<String, dynamic>> hazard_question_items;
  final int worksheetId;
  final int memberId;
  final int projectId;
  final List<Map<String, String>> selectedNamesWithType;
  final List<String> allowedTypes;
  final List<dynamic> categIdList;
  final List<dynamic> workTypeIdList;
  final List<Map<String, dynamic>> selectedDetails;
  final Map<String, bool> selectedCheckboxes;
  final Map<String, bool> selectedRiskItemCheckboxes;
  Map<String, String?> dropdownValues = {};
  Map<String, String?> dropdownRiskItemsValues = {};
  Map<String, String> specificTaskDetails = {};
  List<int> team_member_ids = [];
  var args;

  RiskAssessmentOverviewPage({
    required this.args,
    required this.responses,
    required this.hazardResponses,
    required this.hazard_question_items,
    required this.worksheetId,
    required this.memberId,
    required this.projectId,
    required this.selectedNamesWithType,
    required this.allowedTypes,
    required this.categIdList,
    required this.workTypeIdList,
    required this.selectedDetails,
    required this.selectedCheckboxes,
    required this.selectedRiskItemCheckboxes,
    required this.dropdownValues,
    required this.dropdownRiskItemsValues,
    required this.specificTaskDetails,
    required this.team_member_ids,
  });

  @override
  _RiskAssessmentOverviewPageState createState() =>
      _RiskAssessmentOverviewPageState();
}

class _RiskAssessmentOverviewPageState
    extends State<RiskAssessmentOverviewPage> {
  late List<Map<String, dynamic>> swmsDetails;
  OdooClient? client;
  String url = "";
  String userName = "";
  int? userId;
  bool isNetworkAvailable = false;
  bool isQrVisible = false;
  Duration? checkIndifference;
  Duration? Middifference;
  bool progressChange = false;

  bool isStartjob = false;
  bool isImageLoading = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    // _initializeOdooClient();
    // getSWMSDetails();
    swmsDetails = [];
  }

  Future<void> _initialize() async {
    await _checkConnectivity();
    // _initializeOdooClient();
    getSWMSDetails();
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
        getSWMSDetails();
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

  Future<void> getSWMSDetails() async {
    print("wiiiiiiiiiiiiiiiiiiiiiiiiidddddddd${widget.selectedNamesWithType}");
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    try {
      // final worksheetDetails = await client?.callKw({
      //   'model': 'task.worksheet',
      //   'method': 'search_read',
      //   'args': [
      //     [
      //       ['id', '=', widget.worksheetId]
      //     ]
      //   ],
      //   'kwargs': {
      //     'fields': [
      //       'hoists_ids',
      //       'cranes_ids',
      //       'scaffolding_ids',
      //       'dogging_rigging_ids',
      //       'forklift_ids'
      //     ],
      //   },
      // });
      final Uri url = Uri.parse('$baseUrl/rebates/task_worksheet');
      final worksheetDetails = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "worksheet_id": widget.worksheetId
          }
        }),
      );
      final Map<String, dynamic> jsonWorksheetDetailsResponse = json.decode(worksheetDetails.body);
      // if (worksheetDetails != null && worksheetDetails.isNotEmpty) {
      if (jsonWorksheetDetailsResponse['result']['status'] == 'success' &&
          jsonWorksheetDetailsResponse['result']['worksheet_data'].isNotEmpty) {
        print("Worksheet Details: $worksheetDetails");
      } else {
        print("No worksheet details found.");
      }
    } catch (e) {
      print("Error fetching hazard questions: $e");
    }
  }

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    text = text.replaceAll('_', ' ');
    return text[0].toUpperCase() + text.substring(1);
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.green[200],
  //     appBar: AppBar(
  //       backgroundColor: Colors.green,
  //       title: const Text(
  //         "Risk Assessment Overview",
  //         style: TextStyle(
  //             fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
  //       ),
  //       centerTitle: true,
  //       automaticallyImplyLeading: true,
  //       iconTheme: const IconThemeData(
  //         color: Colors.white,
  //       ),
  //       elevation: 5,
  //     ),
  //     body: Padding(
  //       padding: const EdgeInsets.all(12.0),
  //       child: SingleChildScrollView(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             _buildSectionCard(
  //               title: "Material Handling and Lifting Systems",
  //             icon: 'assets/handle-with-care.png',
  //               child: widget.selectedNamesWithType.isNotEmpty
  //                   ? _buildGroupedItems(widget.selectedNamesWithType)
  //                   : _emptyMessage("No items selected."),
  //             ),
  //             const SizedBox(height: 20),
  //             _buildSectionCard(
  //               title: "Hazard Responses",
  //               icon: "assets/shield.png",
  //               child: widget.hazardResponses.isNotEmpty
  //                   ? _buildHazardResponses()
  //                   : _emptyMessage("No responses recorded."),
  //             ),
  //             const SizedBox(height: 20),
  //             _buildSectionCard(
  //               title: "Safety Measures",
  //               icon: "assets/safety.png",
  //               child: _buildSafetyMeasures(),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //     bottomNavigationBar: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //         children: [
  //           _buildGradientButton(
  //             label: "Edit",
  //             icon: Icons.edit,
  //             colors: [Colors.redAccent, Colors.red[900]!],
  //             onPressed: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => RiskAssessmentPage(
  //                       args: widget.args,
  //                       allowedTypes: widget.allowedTypes,
  //                       selectedDetails: widget.selectedDetails,
  //                       worksheetId: widget.worksheetId!,
  //                       categIdList: widget.categIdList,
  //                       projectId: widget.projectId,
  //                       selectedCheckboxes: widget.selectedCheckboxes,
  //                       selectedRiskItemCheckboxes:
  //                           widget.selectedRiskItemCheckboxes,
  //                       dropdownValues: widget.dropdownValues,
  //                       dropdownRiskItemsValues: widget.dropdownRiskItemsValues,
  //                       specificTaskDetails: widget.specificTaskDetails,
  //                       team_member_ids: widget.team_member_ids,
  //                       hazardResponses: widget.hazardResponses),
  //                 ),
  //               );
  //             },
  //           ),
  //           _buildGradientButton(
  //             label: "Done",
  //             icon: Icons.check_circle,
  //             colors: [Colors.greenAccent[700]!, Colors.green[900]!],
  //             onPressed: () {
  //               _getFromCamera("check_in");
  //               setState(() {
  //                 isImageLoading = false;
  //               });
  //               setState(() {
  //                 _startController(widget.projectId);
  //               });
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    print(isImageLoading);
    print("ffffffffffffffisimageloading");
    return Scaffold(
      backgroundColor: Colors.green[200],
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "Risk Assessment Overview",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        elevation: 5,
      ),
      body: Stack(
        // Use Stack to overlay the loading indicator
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: "Material Handling and Lifting Systems",
                    icon: 'assets/handle-with-care.png',
                    child: widget.selectedNamesWithType.isNotEmpty
                        ? _buildGroupedItems(widget.selectedNamesWithType)
                        : _emptyMessage("No items selected."),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: "Hazard Responses",
                    icon: "assets/shield.png",
                    child: widget.hazardResponses.isNotEmpty
                        ? _buildHazardResponses()
                        : _emptyMessage("No responses recorded."),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: "Safety Measures",
                    icon: "assets/safety.png",
                    child: _buildSafetyMeasures(),
                  ),
                ],
              ),
            ),
          ),
          if (isImageLoading)
            Center(
              child: CircularProgressIndicator(), // This will be centered
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildGradientButton(
              label: "Edit",
              icon: Icons.edit,
              colors: [Colors.redAccent, Colors.red[900]!],
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RiskAssessmentPage(
                        args: widget.args,
                        allowedTypes: widget.allowedTypes,
                        selectedDetails: widget.selectedDetails,
                        worksheetId: widget.worksheetId!,
                        memberId: widget.memberId!,
                        categIdList: widget.categIdList,
                        workTypeIdList: widget.workTypeIdList,
                        projectId: widget.projectId,
                        selectedCheckboxes: widget.selectedCheckboxes,
                        selectedRiskItemCheckboxes:
                            widget.selectedRiskItemCheckboxes,
                        dropdownValues: widget.dropdownValues,
                        dropdownRiskItemsValues: widget.dropdownRiskItemsValues,
                        specificTaskDetails: widget.specificTaskDetails,
                        team_member_ids: widget.team_member_ids,
                        hazardResponses: widget.hazardResponses),
                  ),
                );
              },
            ),
            _buildGradientButton(
              label: "Agree\nAnd Take Selfie",
              icon: Icons.check_circle,
              colors: [Colors.greenAccent[700]!, Colors.green[900]!],
              onPressed: () async {
                setState(() {
                  isImageLoading = true;
                });
                print(
                    "/isImageLoadingisImageLoadingisImageLoading$isImageLoading");
                await _getFromCamera("check_in");
                // setState(() {
                //   _startController(widget.projectId);
                // });
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildSectionCard({
  //   required String title,
  //   required IconData icon,
  //   required Widget child,
  // }) {
  //   return Card(
  //     elevation: 6,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //     shadowColor: Colors.grey.shade300,
  //     child: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               Icon(icon, size: 26, color: Colors.blueAccent),
  //               const SizedBox(width: 10),
  //               Text(
  //                 title,
  //                 style: const TextStyle(
  //                   fontSize: 20,
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.black87,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const Divider(height: 20, thickness: 1.2),
  //           child,
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSectionCard({
    required String title,
    required String icon,
    required Widget child,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.grey.shade300,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  icon,
                  width: 26,
                  height: 26,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1.2),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedItems(List<Map<String, dynamic>> items) {
    final groupedItems =
        items.fold<Map<String, List<Map<String, dynamic>>>>({}, (acc, item) {
      String type = item['type'] ?? 'Unknown Type';
      acc[type] = [...(acc[type] ?? []), item];
      return acc;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedItems.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  capitalizeFirstLetter(entry.key),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/${entry.key.toLowerCase().replaceAll(" ", "_")}.png',
                  // Assuming image file naming follows this pattern
                  height: 24,
                  width: 24,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...entry.value.map((item) => Row(
                  children: [
                    Text(
                      "•   ",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item['name'],
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                )),
            const Divider(),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHazardResponses() {
    if (widget.hazardResponses.isEmpty) {
      return const Text(
        "No hazard responses available.",
        style: TextStyle(fontSize: 16, color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.hazardResponses.entries.map((entry) {
        // final question = widget.hazard_question_items.firstWhere(
        //   (item) => item['id'] == entry.key,
        //   orElse: () => {
        //     "installation_question": "Unknown Question",
        //     "risk_control": "",
        //   },
        // );
        final question = widget.hazard_question_items.firstWhere(
          (item) => item['id'] == entry.key,
          orElse: () => {
            "installation_question": "Unknown Question",
            "risk_control": "",
            "job_activity": "Unknown Activity"
          } as Map<String, Object>, // Type cast to Map<String, Object>
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: RichText(
            text: TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(
                    entry.value.toLowerCase() == 'yes'
                        ? Icons.check_circle
                        : Icons.cancel,
                    size: 20,
                    color: entry.value.toLowerCase() == 'yes'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                TextSpan(
                  text: "   ${question['job_activity']} ",
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if ((question['risk_control'] ?? '').isNotEmpty)
                  TextSpan(
                    text: "(${question['risk_control']}):  ",
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                TextSpan(
                  text: entry.value,
                  style: TextStyle(
                    fontSize: 17,
                    color: entry.value.toLowerCase() == 'yes'
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSafetyMeasures() {
    final groupedItems = widget.dropdownRiskItemsValues.entries.fold(
      <String, List<String>>{},
      (acc, entry) {
        final key = entry.value ?? 'Unknown';
        final value = entry.key ?? 'Unknown';

        if (key != 'Unknown' && value != 'Unknown') {
          acc.putIfAbsent(key, () => []).add(value);
        }
        return acc;
      },
    );
    print(groupedItems);
    print("groupedItemsgroupedItems");
    if (groupedItems.isEmpty) {
      return Center(
        child: Text(
          "No safety measures available",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      );
    }
    return Column(
      children: groupedItems.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              capitalizeFirstLetter(entry.key),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            ...entry.value.map(
              (item) => Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Row(
                  children: [
                    Text(
                      "•   ",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Image.asset(
                      'assets/${item.toLowerCase().replaceAll(" ", "_")}.png',
                      // Assuming image file naming follows this pattern
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: widget.specificTaskDetails.containsKey(item) &&
                              widget.specificTaskDetails[item] != null
                          ? Text(
                              "$item : ${widget.specificTaskDetails[item] ?? 'No data'}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            )
                          : Text(
                              "$item",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _emptyMessage(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onPressed,
  }) {
    // return Container(
    //   decoration: BoxDecoration(
    //     gradient: LinearGradient(colors: colors),
    //     borderRadius: BorderRadius.circular(12),
    //     boxShadow: [
    //       BoxShadow(
    //         color: Colors.grey.withOpacity(0.3),
    //         blurRadius: 5,
    //         offset: const Offset(0, 3),
    //       ),
    //     ],
    //   ),
    //   child: ElevatedButton.icon(
    //     onPressed: onPressed,
    //     style: ElevatedButton.styleFrom(
    //       backgroundColor: Colors.transparent,
    //       shadowColor: Colors.transparent,
    //       minimumSize: const Size(150, 50),
    //     ),
    //     icon: Icon(icon, color: Colors.white),
    //     label: Text(
    //       label,
    //       style: const TextStyle(
    //           fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
    //     ),
    //   ),
    // );
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize: const Size(150, 50),
          ),
          icon: Icon(icon, color: Colors.white),
          label: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

// Helper method to capitalize first letter
//   String capitalizeFirstLetter(String input) {
//     return input.isEmpty ? input : input[0].toUpperCase() + input.substring(1);
//   }

  // @override
  // Widget build(BuildContext context) {
  //   print(widget.specificTaskDetails);
  //   print(widget.dropdownRiskItemsValues);
  //   print("dropdownRiskItemsValuesdropdownRiskItemsValues");
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text(
  //         "Risk Assessment Overview",
  //         style: TextStyle(fontWeight: FontWeight.bold),
  //       ),
  //     ),
  //     body: Padding(
  //       padding: EdgeInsets.all(16.0),
  //       child: SingleChildScrollView(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               "Selected Risk Items:",
  //               style: TextStyle(
  //                 fontWeight: FontWeight.bold,
  //                 fontSize: 20,
  //                 color: Colors.black,
  //               ),
  //             ),
  //             SizedBox(height: 8),
  //             if (widget.selectedNamesWithType.isNotEmpty)
  //               Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   ...widget.selectedNamesWithType
  //                       .fold<Map<String, List<Map<String, dynamic>>>>({},
  //                           (acc, item) {
  //                         String type = item['type'] ?? 'Unknown Type';
  //
  //                         if (acc.containsKey(type)) {
  //                           acc[type]?.add(item);
  //                         } else {
  //                           acc[type] = [item];
  //                         }
  //                         return acc;
  //                       })
  //                       .entries
  //                       .map((entry) {
  //                         return Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             Text(
  //                               capitalizeFirstLetter(entry.key),
  //                               style: TextStyle(
  //                                 fontSize: 18,
  //                                 fontWeight: FontWeight.bold,
  //                                 color: Colors.blue,
  //                               ),
  //                             ),
  //                             SizedBox(height: 10),
  //                             ...entry.value.map((item) {
  //                               return Text(
  //                                 "- ${item['name']}",
  //                                 style: TextStyle(fontSize: 16),
  //                               );
  //                             }).toList(),
  //                             SizedBox(height: 10),
  //                           ],
  //                         );
  //                       })
  //                       .toList(),
  //                   ...widget.dropdownRiskItemsValues.entries
  //                       .fold<Map<String, List<Map<String, dynamic>>>>({}, (acc, entry) {
  //                     String? type = entry.value;
  //                     String name = entry.key;
  //
  //                     if (type != null && type.isNotEmpty) {
  //                       if (acc.containsKey(type)) {
  //                         acc[type]?.add({'name': name});
  //                       } else {
  //                         acc[type] = [{'name': name}];
  //                       }
  //                     }
  //                     return acc;
  //                   })
  //                       .entries
  //                       .expand((entry) => [
  //                     Text(
  //                       capitalizeFirstLetter(entry.key),
  //                       style: TextStyle(
  //                         fontSize: 18,
  //                         fontWeight: FontWeight.bold,
  //                         color: Colors.blue,
  //                       ),
  //                     ),
  //                     SizedBox(height: 10),
  //                     ...entry.value.map((item) {
  //                       String displayText = item['name'];
  //
  //                       if (widget.specificTaskDetails.containsKey(item['name'])) {
  //                         displayText = '${item['name']} - ${widget.specificTaskDetails[item['name']] ?? 'No value'}';
  //                       }
  //
  //                       return Text(
  //                         displayText,
  //                         style: TextStyle(fontSize: 16),
  //                       );
  //                     }).toList(),
  //
  //                     SizedBox(height: 10),
  //                   ])
  //                       .toList()
  //
  //                 ],
  //               )
  //             else
  //               Text(
  //                 "No items selected.",
  //                 style: TextStyle(fontSize: 16, color: Colors.grey),
  //               ),
  //             SizedBox(height: 20),
  //             Text(
  //               "Hazard Responses:",
  //               style: TextStyle(
  //                 fontWeight: FontWeight.bold,
  //                 fontSize: 20,
  //                 color: Colors.black,
  //               ),
  //             ),
  //             SizedBox(height: 8),
  //             if (widget.hazardResponses.isNotEmpty)
  //               Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: widget.hazardResponses.entries.map((entry) {
  //                   Map<String, dynamic> question;
  //                   if (isNetworkAvailable) {
  //                     question = widget.hazard_question_items.firstWhere(
  //                       (item) => item['id'] == entry.key,
  //                       orElse: () => {
  //                         "installation_question": "Unknown Question",
  //                         "risk_control": ""
  //                       },
  //                     );
  //                   } else {
  //                     question = widget.hazard_question_items.firstWhere(
  //                       (item) => item['id'] == entry.key,
  //                       orElse: () => {
  //                         "installation_question": "Unknown Question",
  //                         "risk_control": "",
  //                       } as Map<String, Object>,
  //                     );
  //                   }
  //                   return RichText(
  //                     text: TextSpan(
  //                       children: [
  //                         TextSpan(
  //                           text: "• ",
  //                           style: TextStyle(
  //                               fontSize: 20,
  //                               color: Colors.black,
  //                               fontWeight: FontWeight.bold),
  //                         ),
  //                         TextSpan(
  //                           text: "${question['installation_question']} ",
  //                           style: TextStyle(
  //                               fontSize: 17,
  //                               color: Colors.blue,
  //                               fontWeight: FontWeight.bold),
  //                         ),
  //                         TextSpan(
  //                           text: "(${question['risk_control']}):  ",
  //                           style: TextStyle(fontSize: 16, color: Colors.black),
  //                         ),
  //                         TextSpan(
  //                           text: " ${entry.value}",
  //                           style: TextStyle(
  //                               fontSize: 17,
  //                               color: Colors.red,
  //                               fontWeight: FontWeight.bold),
  //                         ),
  //                       ],
  //                     ),
  //                   );
  //                 }).toList(),
  //               )
  //             else
  //               Text(
  //                 "No responses recorded.",
  //                 style: TextStyle(fontSize: 16, color: Colors.grey),
  //               ),
  //           ],
  //         ),
  //       ),
  //     ),
  //     bottomNavigationBar: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           ElevatedButton(
  //             onPressed: () {
  //               print("Edit button pressed${widget.responses}");
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => RiskAssessmentPage(
  //                       args: widget.args,
  //                       allowedTypes: widget.allowedTypes,
  //                       selectedDetails: widget.selectedDetails,
  //                       worksheetId: widget.worksheetId!,
  //                       categIdList: widget.categIdList,
  //                       projectId: widget.projectId,
  //                       selectedCheckboxes: widget.selectedCheckboxes,
  //                       selectedRiskItemCheckboxes: widget.selectedRiskItemCheckboxes,
  //                       dropdownValues: widget.dropdownValues,
  //                       dropdownRiskItemsValues: widget.dropdownRiskItemsValues,
  //                       specificTaskDetails: widget.specificTaskDetails,
  //                       team_member_ids: widget.team_member_ids,
  //                       hazardResponses: widget.hazardResponses),
  //                 ),
  //               );
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.red,
  //               minimumSize: Size(160, 50),
  //             ),
  //             child: Text(
  //               "Edit",
  //               style: TextStyle(
  //                 color: Colors.white,
  //                 fontWeight: FontWeight.bold,
  //                 fontSize: 15,
  //               ),
  //             ),
  //           ),
  //           SizedBox(
  //             width: 20,
  //           ),
  //           ElevatedButton(
  //             onPressed: () async {
  //               print("Done button pressed");
  //               _getFromCamera("check_in");
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.green,
  //               minimumSize: Size(160, 50),
  //             ),
  //             child: Text(
  //               "Done",
  //               style: TextStyle(
  //                 color: Colors.white,
  //                 fontWeight: FontWeight.bold,
  //                 fontSize: 15,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Future<bool> _checkCameraPermission() async {
    PermissionStatus status = await Permission.camera.status;

    if (status.isDenied) {
      status = await Permission.camera.request();
      if (status.isDenied) {
        return false;
      }
    }

    if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }

    if (status.isGranted) {
      return true;
    }

    return false;
  }

  Future<void> _getFromCamera(String checklistType) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('url') ?? 0;
    print("dddddddddddddddddddddddddddddddddddddwwwwwwwwwwwwwwdddddddddddddddddddddd");

    try {
      bool hasPermission = await _checkCameraPermission();
      if (!hasPermission) {
        setState(() {
          isImageLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera permission is required to proceed.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // final box = await Hive.openBox<HiveImage>('imagesBox');
      // HiveImage? existingImage = box.values.cast<HiveImage?>().firstWhere(
      //       (image) =>
      //           image != null &&
      //           image.checklistType == checklistType &&
      //           image.projectId == widget.projectId,
      //       orElse: () => null,
      //     );
      // if (existingImage != null) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('You already uploaded an image for this selfie.'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      //   return;
      // }
      if (!isNetworkAvailable) {
        final box = await Hive.openBox<HiveImage>('imagesBox');
        HiveImage? existingImage = box.values.cast<HiveImage?>().firstWhere(
              (image) =>
                  image != null &&
                  image.checklistType == checklistType &&
                  image.projectId == widget.projectId,
              orElse: () => null,
            );
        if (existingImage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You already uploaded an image for this selfie.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      print("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
      XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxHeight: 1000,
        maxWidth: 1000,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        List<int> imageBytes = await imageFile.readAsBytes();
        String base64Image = base64Encode(imageBytes);
        try {
          // Position position = await _getCurrentLocation();
          Position? position = await _getCurrentLocation();
          if (position == null) {
            setState(() {
              isImageLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('You must enable location permissions to proceed.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          print(widget.workTypeIdList);
          print("fffffffffffwidget.workTypeIdList");
          if (widget.workTypeIdList.isEmpty) {
            setState(() {
              isImageLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    "Work Type is empty. You can't continue the checkin process."),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          if (!isNetworkAvailable) {
            print("hjjjjjjjjjjjjjjjjjjjjjjjjjjj");
            await _saveImageToHive(checklistType, base64Image, position);
            final box = await Hive.openBox<HiveImage>('imagesBox');
            final selfies = box.values
                .where((selfie) => selfie.checklistType == checklistType);
            if (selfies.isNotEmpty) {
              final lastSelfie = selfies.last;
              final timeDifference =
                  DateTime.now().difference(lastSelfie.timestamp);
              setState(() {
                checkIndifference = timeDifference;
                Middifference = timeDifference;
                isQrVisible = true;
                setState(() {});
              });
            }
            print("5555555555555555555dddddddddddddddddddd");
            var newargs = Map<String, dynamic>.from(widget.args);
            newargs['isQrVisible'] = true;
            setState(() {
              isImageLoading = false;
            });
            await _attendanceAdd(widget.worksheetId,position,widget.memberId);
            setState(() {
              _startController(widget.projectId);
            });
            Navigator.popAndPushNamed(
              context,
              '/installing_form_view',
              arguments: newargs,
            );
            print("ggggggggggggggggggggggggggggggggggggggggggggggg");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Network unavailable. Image saved for later upload.'),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            try {
              await _saveImageToHive(checklistType, base64Image, position);
              print(widget.categIdList);
              print(checklistType);
              print(widget.workTypeIdList);
              print("categIdListcategdddddIdListcategIdList");
              // final checklist = await client?.callKw({
              //   'model': 'installation.checklist',
              //   'method': 'search_read',
              //   'args': [
              //     [
              //       ['category_ids', 'in', widget.categIdList],
              //       ['selfie_type', '=', checklistType],
              //       ['group_ids', 'in', widget.workTypeIdList]
              //     ],
              //     ['id']
              //   ],
              //   'kwargs': {},
              // });
              final Uri url = Uri.parse('$baseUrl/rebates/installation_checklist');
              final checklist = await http.post(
                url,
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "jsonrpc": "2.0",
                  "method": "call",
                  "params": {
                    "categIdList": widget.categIdList,
                    "workTypeIdList": widget.workTypeIdList,
                    "selfie_type": checklistType
                  }
                }),
              );
              final Map<String, dynamic> jsonChecklistResponse = json.decode(checklist.body);
              print(
                  "checklistchddddddddddddddddddddddegggggggggggggggvvvvvvvvvvvgggggggggcklistchecklist$checklist");
              print(
                  "checklistcheckdddddddddddddddddddddddddddddddddlistchecklist$progressChange");
              print(jsonChecklistResponse['result']['installation_checklist'][0]['id']);
              print(base64Image);
              print(position);
              // await _uploadImage(checklist[0]['id'], base64Image, position);
              // await _startController(widget.projectId);
              bool success = await _uploadImage(jsonChecklistResponse['result']['installation_checklist'][0]['id'], base64Image, position);
              print("successsuccess$success");
              if (success) {
                await _attendanceAdd(widget.worksheetId,position,widget.memberId);
                await _startController(widget.projectId);
                print("Image uploaded successfully.");
                Map<String, dynamic> progressData = {
                  'worksheetId': widget.worksheetId,
                  'progressChange': progressChange,
                  'isStartjob': true
                };
                setState(() {
                  SharedState.progressData = progressData;
                });
                print(SharedState.progressData);
                print("SharedState.progressChange");
                var newargs = Map<String, dynamic>.from(widget.args);

                newargs['isQrVisible'] = true;
                setState(() {
                  isImageLoading = false;
                });
                Navigator.popAndPushNamed(
                  context,
                  '/installing_form_view',
                  arguments: newargs,
                );
              } else {
                print("Image upload failed.");
                var newargs = Map<String, dynamic>.from(widget.args);
                setState(() {
                  isImageLoading = false;
                });
                Navigator.popAndPushNamed(
                  context,
                  '/installing_form_view',
                  arguments: newargs,
                );
              }
              setState(() {});
              // print("fffffffffffffffffffffffffff$progressChange");
              // Map<String, dynamic> progressData = {
              //   'worksheetId': widget.worksheetId,
              //   'progressChange': progressChange,
              //   'isStartjob': true
              // };
              // setState(() {
              //   SharedState.progressData = progressData;
              // });
              // print(SharedState.progressData);
              // print("SharedState.progressChange");
              // var newargs = Map<String, dynamic>.from(widget.args);
              //
              // newargs['isQrVisible'] = true;
              // setState(() {
              //   isImageLoading = false;
              // });
              // Navigator.popAndPushNamed(
              //   context,
              //   '/installing_form_view',
              //   arguments: newargs,
              // );
            } catch (r) {
              print("rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr$r");
            }
          }
        } catch (t) {
          print("tttttttttttttttttttttttttttttt$t");
        }
      }
    } catch (e) {}
  }

  Future<void> _saveImageToHive(
      String checklistType, String base64Image, position) async {
    Box<HiveImage>? box;
    try {
      final imageEntry = HiveImage(
        checklistType: checklistType,
        base64Image: base64Image,
        projectId: widget.projectId,
        categIdList: widget.categIdList,
        position: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        timestamp: DateTime.now(),
      );

      box = await Hive.openBox<HiveImage>('imagesBox');
      await box.add(imageEntry);
      print("Image saved successfully.${box.values}");
    } catch (e) {
      print("Error saving image to Hive: $e");
    } finally {
      if (box != null && box.isOpen) {
        try {
          await box.close();
          print("Box closed properly.");
        } catch (e) {
          print("Error closing box: $e");
        }
      }
    }
  }

  // Future<void> _saveImageToHive(
  //     String checklistType, String base64Image, position) async {
  //   Box<HiveImage>? box;
  //   print("555555555555%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%");
  //   try {
  //     final imageEntry = HiveImage(
  //       checklistType: checklistType,
  //       base64Image: base64Image,
  //       projectId: widget.projectId,
  //       categIdList: widget.categIdList,
  //       position: {
  //         'latitude': position.latitude,
  //         'longitude': position.longitude,
  //       },
  //       timestamp: DateTime.now(),
  //     );
  //     box = await Hive.openBox<HiveImage>('imagesBox');
  //     await box.add(imageEntry);
  //     print(box.isOpen);
  //     print("Idfggggggggggggggggggmage saved successfully.");
  //   } catch (e) {
  //     print("Error saving image to Hive: $e");
  //   } finally {
  //     if (box != null && box.isOpen) {
  //       box.close();
  //       print("Box closeeeeeeeeeeeeed properly.");
  //     }
  //   }
  // }

  Future<void> _saveStartToHive(int taskId, String date) async {
    final box = await Hive.openBox<TaskJob>('taskJobsBox');
    try {
      final taskJob = TaskJob(taskId: taskId, date: date);

      await box.add(taskJob);
      print('TaskJob saved successfully!');
    } catch (e) {
      print('Error saving TaskJob to Hive: $e');
    } finally {
      await box.close();
    }
  }


  Future<void> _saveAttendanceToHive(int worksheetId, position, formattedDate, int memberId) async {
    print('Attendance ssssssssssssssssssssaved to Hive');
    var box = await Hive.openBox<Attendance>('attendance');
    await box.clear();
    print(position.latitude);
    final attendance = Attendance(
      worksheetId: worksheetId,
      latitude: position.latitude,
      longitude: position.longitude,
      date: formattedDate,
      memberId: memberId,
    );
    await box.put(worksheetId,attendance);

    print('Attendance saved to Hive');
  }


  Future<void> _attendanceAdd(int worksheetId, position, int memberId) async {
    print("ddddddddddddddddddddddddsssssssssssssssssss");
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    final String formattedDate =
    DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final baseUrl = prefs.getString('url') ?? 0;

    if (!isNetworkAvailable) {
      await _saveAttendanceToHive(worksheetId,position, formattedDate,memberId);
      // await _saveStartToHive(taskId, formattedDate);
      // setState(() {
      //   progressChange = false;
      //   isStartjob = true;
      // });
    } else {
      try {
        final formattedDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
        // final response = await client?.callKw({
        //   'model': 'worksheet.attendance',
        //   'method': 'create',
        //   'args': [
        //     {
        //       'type': 'check_in',
        //       'worksheet_id': worksheetId,
        //       'in_latitude': position.latitude,
        //       'in_longitude': position.longitude,
        //       'member_id': memberId,
        //       'date': formattedDate
        //     }
        //   ],
        //   'kwargs': {},
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/worksheet_attendance/create');
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "type": 'check_in',
              "worksheet_id": worksheetId,
              "in_latitude": position.latitude,
              "in_longitude": position.longitude,
              "member_id": memberId,
              "date": formattedDate
            }
          }),
        );

        final Map<String, dynamic> jsonAttendanceCreateResponse = json.decode(response.body);
        print("jsonAttendanceCreateResponsejsonAttendanceCreateResponse$jsonAttendanceCreateResponse");
        // if (response == true) {
        if (jsonAttendanceCreateResponse['result']['status'] == 'success') {
          // setState(() {
          //   progressChange = false;
          //   isStartjob = true;
          // });

        } else {}
      } catch (e) {}
    }
  }

  Future<void> _startController(taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    final String formattedDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    if (!isNetworkAvailable) {
      await _saveStartToHive(taskId, formattedDate);
      setState(() {
        progressChange = false;
        isStartjob = true;
      });
    } else {
      try {
        // final response = await client?.callKw({
        //   'model': 'project.task',
        //   'method': 'write',
        //   'args': [
        //     [taskId],
        //     {
        //       'install_status': 'progress',
        //       'date_worksheet_start':
        //           DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())
        //     }
        //   ],
        //   'kwargs': {},
        // });
        final Uri url = Uri.parse('$baseUrl/rebates/project_task/write');
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "task_id": taskId,
              "install_status": 'progress',
              "date_worksheet_start": DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
            }
          }),
        );
        final Map<String, dynamic> jsonStartJobResponse = json.decode(response.body);
        print("jsonStartJobResponsejsonStartJobResponsejsonStartJobResponse$jsonStartJobResponse");
        // if (response == true) {
        if (jsonStartJobResponse['result']['status'] == 'success') {
          setState(() {
            progressChange = false;
            isStartjob = true;
          });
          final box = await Hive.openBox<InstallingJob>('installationListBox');
          final installJob = box.get(taskId);

          if (installJob != null) {
            final updatedServiceJob =
                installJob.copyWith(install_status: 'progress');
            await box.put(taskId, updatedServiceJob);
          }
        } else {}
      } catch (e) {}
    }
  }

  // Future<Position> _getCurrentLocation() async {
  //   print("pppppppppppppppppppppppppppppppppppppp");
  //   LocationPermission permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       permission = await Geolocator.requestPermission();
  //       // throw Exception('Location permissions are denied');
  //     }
  //   }
  //   return await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high);
  // }

  Future<Position?> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null; // Return null if permissions are still denied
      }
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Future<void> _uploadImage(int id, String base64Image, position) async {
  //   print(id);
  //   print(base64Image);
  //   print(position);
  //   print(
  //       "444444444444444444444ccccccccccccccccccccccccccccccc444444444fffffffffff");
  //   print("F");
  //   // setState(() {
  //   //   isImageLoading = true;
  //   // });
  //   try {
  //     List<Placemark> placemarks =
  //         await placemarkFromCoordinates(position.latitude, position.longitude);
  //     Placemark place = placemarks.first;
  //     String locationDetails =
  //         "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
  //     // final worksheet = await client?.callKw({
  //     //   'model': 'task.worksheet',
  //     //   'method': 'search_read',
  //     //   'args': [
  //     //     [
  //     //       ['task_id', '=', projectId],
  //     //     ],
  //     //   ],
  //     //   'kwargs': {},
  //     // });
  //     // if (worksheet != null && worksheet.isNotEmpty) {
  //     //   worksheetId = worksheet[0]['id'];
  //     // }
  //     print(
  //         "${DateTime.now()}ffffffffffffffffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee");
  //     final formattedDate =
  //         DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  //
  //     final checklist = await client?.callKw({
  //       'model': 'installation.checklist.item',
  //       'method': 'create',
  //       'args': [
  //         {
  //           'user_id': userId,
  //           'worksheet_id': widget.worksheetId,
  //           'checklist_id': id,
  //           'date': formattedDate,
  //           'image': base64Image,
  //           'location': locationDetails,
  //           'latitude': position.latitude,
  //           'longitude': position.longitude
  //         }
  //       ],
  //       'kwargs': {},
  //     });
  //     print("fffffffffffffffffddddddddddfffffffffffffffffff");
  //     // setState(() async {
  //     //   await _getSelfies();
  //     //   isImageLoading = false;
  //     //   print("ffffffffffffffffffffffffffffffffffff");
  //     //   isQrVisible = true;
  //     //   setState(() {});
  //     // });
  //   } catch (e) {
  //     // isImageLoading = false;
  //   }
  // }
  Future<bool> _uploadImage(int id, String base64Image, position) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('url') ?? 0;
    final teamId = prefs.getInt('teamId') ?? 0;
    print(id);
    print(base64Image);
    print(position);
    print(
        "444444444444kkkkkkkkkkkkkkkkkkkk444444444ccccccccccccccccccccccccccccccc444444444fffffffffff");
    print("F");
    // setState(() {
    //   isImageLoading = true;
    // });
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks.first;
      String locationDetails =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
      // final worksheet = await client?.callKw({
      //   'model': 'task.worksheet',
      //   'method': 'search_read',
      //   'args': [
      //     [
      //       ['task_id', '=', projectId],
      //     ],
      //   ],
      //   'kwargs': {},
      // });
      // if (worksheet != null && worksheet.isNotEmpty) {
      //   worksheetId = worksheet[0]['id'];
      // }
      print(
          "${DateTime.now()}ffffffffffffffffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee");
      final formattedDate =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // final checklist = await client?.callKw({
      //   'model': 'installation.checklist.item',
      //   'method': 'create',
      //   'args': [
      //     {
      //       'user_id': userId,
      //       'worksheet_id': widget.worksheetId,
      //       'checklist_id': id,
      //       'date': formattedDate,
      //       'image': base64Image,
      //       'location': locationDetails,
      //       'latitude': position.latitude,
      //       'longitude': position.longitude
      //     }
      //   ],
      //   'kwargs': {},
      // });
      final Uri url = Uri.parse('$baseUrl/rebates/installation_checklist_item/create');
      final checklist = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "teamId": teamId,
            "item": id,
            "taskId": widget.worksheetId,
            "base64Image": base64Image,
            "formattedDate": formattedDate,
            "locationDetails": locationDetails,
            'latitude': position.latitude,
            'longitude': position.longitude
          }
        }),
      );
      final Map<String, dynamic> jsonChecklistCreateResponse = json.decode(checklist.body);
      print("$jsonChecklistCreateResponse/fffffffffffffffffddddddddddfffffffffffffffffff");
      // if (checklist != null && checklist is int) {
      if (jsonChecklistCreateResponse['result']['status'] == "success") {
        print("Upload successful, checklist item ID: $checklist");
        return true;
      } else {
        print("Upload failed: Invalid response.");
        // isImageLoading = false;
        return false;
      }
      // setState(() async {
      //   await _getSelfies();
      //   isImageLoading = false;
      //   print("ffffffffffffffffffffffffffffffffffff");
      //   isQrVisible = true;
      //   setState(() {});
      // });
    } catch (e) {
      // isImageLoading = false;
      return false;
    }
  }
}

class RiskAssessmentOverviewWithoutHazardsPage extends StatefulWidget {
  final int worksheetId;
  final int memberId;
  final int projectId;
  final List<Map<String, String>> selectedNamesWithType;
  final List<String> allowedTypes;
  final List<dynamic> categIdList;
  final List<dynamic> workTypeIdList;
  final List<Map<String, dynamic>> selectedDetails;
  final Map<String, bool> selectedCheckboxes;
  final Map<String, bool> selectedRiskItemCheckboxes;
  Map<String, String?> dropdownValues = {};
  Map<String, String?> dropdownRiskItemsValues = {};
  Map<String, String> specificTaskDetails = {};
  List<int> team_member_ids = [];
  var args;

  RiskAssessmentOverviewWithoutHazardsPage({
    required this.args,
    required this.worksheetId,
    required this.memberId,
    required this.projectId,
    required this.selectedNamesWithType,
    required this.allowedTypes,
    required this.categIdList,
    required this.workTypeIdList,
    required this.selectedDetails,
    required this.selectedCheckboxes,
    required this.selectedRiskItemCheckboxes,
    required this.dropdownValues,
    required this.dropdownRiskItemsValues,
    required this.specificTaskDetails,
    required this.team_member_ids,
  });

  @override
  _RiskAssessmentOverviewWithoutHazardsPageState createState() =>
      _RiskAssessmentOverviewWithoutHazardsPageState();
}

class _RiskAssessmentOverviewWithoutHazardsPageState
    extends State<RiskAssessmentOverviewWithoutHazardsPage> {
  late List<Map<String, dynamic>> swmsDetails;
  OdooClient? client;
  String url = "";
  String userName = "";
  int? userId;
  bool isNetworkAvailable = false;
  bool isQrVisible = false;
  Duration? checkIndifference;
  Duration? Middifference;
  bool progressChange = false;

  bool isStartjob = false;
  bool isImageLoading = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    // _initializeOdooClient();
    // getSWMSDetails();
    swmsDetails = [];
  }

  Future<void> _initialize() async {
    await _checkConnectivity();
    _initializeOdooClient();
    getSWMSDetails();
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
        getSWMSDetails();
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

  Future<void> getSWMSDetails() async {
    print("wiiiiiiiiiiiiiiiiiiiiiiiiidddddddd${widget.selectedNamesWithType}");
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    final baseUrl = prefs.getString('url') ?? 0;
    try {
      // final worksheetDetails = await client?.callKw({
      //   'model': 'task.worksheet',
      //   'method': 'search_read',
      //   'args': [
      //     [
      //       ['id', '=', widget.worksheetId]
      //     ]
      //   ],
      //   'kwargs': {
      //     'fields': [
      //       'hoists_ids',
      //       'cranes_ids',
      //       'scaffolding_ids',
      //       'dogging_rigging_ids',
      //       'forklift_ids'
      //     ],
      //   },
      // });
      final Uri worksheetUrl = Uri.parse('$baseUrl/rebates/task_worksheet');
      final worksheetDetails = await http.post(
        worksheetUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "worksheet_id": widget.worksheetId,
          }
        }),
      );
      final Map<String, dynamic> jsonWorksheetDetailsResponse = json.decode(worksheetDetails.body);
      // if (worksheetDetails != null && worksheetDetails.isNotEmpty) {
      if (jsonWorksheetDetailsResponse['result']['status'] == 'success' && jsonWorksheetDetailsResponse['result']['worksheet_data'].isEmpty) {
        print("Worksheet Details: $worksheetDetails");
      } else {
        print("No worksheet details found.");
      }
    } catch (e) {
      print("Error fetching hazard questions: $e");
    }
  }

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    text = text.replaceAll('_', ' ');
    return text[0].toUpperCase() + text.substring(1);
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.green[200],
  //     appBar: AppBar(
  //       backgroundColor: Colors.green,
  //       title: const Text(
  //         "Risk Assessment Overview",
  //         style: TextStyle(
  //             fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
  //       ),
  //       centerTitle: true,
  //       automaticallyImplyLeading: true,
  //       iconTheme: const IconThemeData(
  //         color: Colors.white,
  //       ),
  //       elevation: 5,
  //     ),
  //     body: Padding(
  //       padding: const EdgeInsets.all(12.0),
  //       child: SingleChildScrollView(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             _buildSectionCard(
  //               title: "Material Handling and Lifting Systems",
  //             icon: 'assets/handle-with-care.png',
  //               child: widget.selectedNamesWithType.isNotEmpty
  //                   ? _buildGroupedItems(widget.selectedNamesWithType)
  //                   : _emptyMessage("No items selected."),
  //             ),
  //             const SizedBox(height: 20),
  //             _buildSectionCard(
  //               title: "Hazard Responses",
  //               icon: "assets/shield.png",
  //               child: widget.hazardResponses.isNotEmpty
  //                   ? _buildHazardResponses()
  //                   : _emptyMessage("No responses recorded."),
  //             ),
  //             const SizedBox(height: 20),
  //             _buildSectionCard(
  //               title: "Safety Measures",
  //               icon: "assets/safety.png",
  //               child: _buildSafetyMeasures(),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //     bottomNavigationBar: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //         children: [
  //           _buildGradientButton(
  //             label: "Edit",
  //             icon: Icons.edit,
  //             colors: [Colors.redAccent, Colors.red[900]!],
  //             onPressed: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => RiskAssessmentPage(
  //                       args: widget.args,
  //                       allowedTypes: widget.allowedTypes,
  //                       selectedDetails: widget.selectedDetails,
  //                       worksheetId: widget.worksheetId!,
  //                       categIdList: widget.categIdList,
  //                       projectId: widget.projectId,
  //                       selectedCheckboxes: widget.selectedCheckboxes,
  //                       selectedRiskItemCheckboxes:
  //                           widget.selectedRiskItemCheckboxes,
  //                       dropdownValues: widget.dropdownValues,
  //                       dropdownRiskItemsValues: widget.dropdownRiskItemsValues,
  //                       specificTaskDetails: widget.specificTaskDetails,
  //                       team_member_ids: widget.team_member_ids,
  //                       hazardResponses: widget.hazardResponses),
  //                 ),
  //               );
  //             },
  //           ),
  //           _buildGradientButton(
  //             label: "Done",
  //             icon: Icons.check_circle,
  //             colors: [Colors.greenAccent[700]!, Colors.green[900]!],
  //             onPressed: () {
  //               _getFromCamera("check_in");
  //               setState(() {
  //                 isImageLoading = false;
  //               });
  //               setState(() {
  //                 _startController(widget.projectId);
  //               });
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    print(isImageLoading);
    print("ffffffffffffffisimageloading");
    return Scaffold(
      backgroundColor: Colors.green[200],
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "Risk Assessment Overview",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        elevation: 5,
      ),
      body: Stack(
        // Use Stack to overlay the loading indicator
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: "Material Handling and Lifting Systems",
                    icon: 'assets/handle-with-care.png',
                    child: widget.selectedNamesWithType.isNotEmpty
                        ? _buildGroupedItems(widget.selectedNamesWithType)
                        : _emptyMessage("No items selected."),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: "Safety Measures",
                    icon: "assets/safety.png",
                    child: _buildSafetyMeasures(),
                  ),
                ],
              ),
            ),
          ),
          if (isImageLoading)
            Center(
              child: CircularProgressIndicator(), // This will be centered
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildGradientButton(
              label: "Edit",
              icon: Icons.edit,
              colors: [Colors.redAccent, Colors.red[900]!],
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RiskAssessmentPage(
                        args: widget.args,
                        allowedTypes: widget.allowedTypes,
                        selectedDetails: widget.selectedDetails,
                        worksheetId: widget.worksheetId!,
                        memberId: widget.memberId!,
                        categIdList: widget.categIdList,
                        workTypeIdList: widget.workTypeIdList,
                        projectId: widget.projectId,
                        selectedCheckboxes: widget.selectedCheckboxes,
                        selectedRiskItemCheckboxes:
                            widget.selectedRiskItemCheckboxes,
                        dropdownValues: widget.dropdownValues,
                        dropdownRiskItemsValues: widget.dropdownRiskItemsValues,
                        specificTaskDetails: widget.specificTaskDetails,
                        team_member_ids: widget.team_member_ids,
                        hazardResponses: {}),
                  ),
                );
              },
            ),
            _buildGradientButton(
              label: "Agree\nAnd Take Selfie",
              icon: Icons.check_circle,
              colors: [Colors.greenAccent[700]!, Colors.green[900]!],
              onPressed: () async {
                setState(() {
                  isImageLoading = true;
                });
                print(
                    "/isImageLoadingisImageLoadingisImageLoading$isImageLoading");
                await _getFromCamera("check_in");
                // setState(() {
                //   _startController(widget.projectId);
                // });
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildSectionCard({
  //   required String title,
  //   required IconData icon,
  //   required Widget child,
  // }) {
  //   return Card(
  //     elevation: 6,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //     shadowColor: Colors.grey.shade300,
  //     child: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               Icon(icon, size: 26, color: Colors.blueAccent),
  //               const SizedBox(width: 10),
  //               Text(
  //                 title,
  //                 style: const TextStyle(
  //                   fontSize: 20,
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.black87,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const Divider(height: 20, thickness: 1.2),
  //           child,
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSectionCard({
    required String title,
    required String icon,
    required Widget child,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.grey.shade300,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  icon,
                  width: 26,
                  height: 26,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1.2),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedItems(List<Map<String, dynamic>> items) {
    final groupedItems =
        items.fold<Map<String, List<Map<String, dynamic>>>>({}, (acc, item) {
      String type = item['type'] ?? 'Unknown Type';
      acc[type] = [...(acc[type] ?? []), item];
      return acc;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedItems.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  capitalizeFirstLetter(entry.key),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/${entry.key.toLowerCase().replaceAll(" ", "_")}.png',
                  // Assuming image file naming follows this pattern
                  height: 24,
                  width: 24,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...entry.value.map((item) => Row(
                  children: [
                    Text(
                      "•   ",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item['name'],
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                )),
            const Divider(),
          ],
        );
      }).toList(),
    );
  }


  Widget _buildSafetyMeasures() {
    final groupedItems = widget.dropdownRiskItemsValues.entries.fold(
      <String, List<String>>{},
      (acc, entry) {
        final key = entry.value ?? 'Unknown';
        final value = entry.key ?? 'Unknown';

        if (key != 'Unknown' && value != 'Unknown') {
          acc.putIfAbsent(key, () => []).add(value);
        }
        return acc;
      },
    );
    print(groupedItems);
    print("groupedItemsgroupedItems");
    if (groupedItems.isEmpty) {
      return Center(
        child: Text(
          "No safety measures available",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      );
    }
    return Column(
      children: groupedItems.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              capitalizeFirstLetter(entry.key),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            ...entry.value.map(
              (item) => Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Row(
                  children: [
                    Text(
                      "•   ",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Image.asset(
                      'assets/${item.toLowerCase().replaceAll(" ", "_")}.png',
                      // Assuming image file naming follows this pattern
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: widget.specificTaskDetails.containsKey(item) &&
                              widget.specificTaskDetails[item] != null
                          ? Text(
                              "$item : ${widget.specificTaskDetails[item] ?? 'No data'}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            )
                          : Text(
                              "$item",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _emptyMessage(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onPressed,
  }) {
    // return Container(
    //   decoration: BoxDecoration(
    //     gradient: LinearGradient(colors: colors),
    //     borderRadius: BorderRadius.circular(12),
    //     boxShadow: [
    //       BoxShadow(
    //         color: Colors.grey.withOpacity(0.3),
    //         blurRadius: 5,
    //         offset: const Offset(0, 3),
    //       ),
    //     ],
    //   ),
    //   child: ElevatedButton.icon(
    //     onPressed: onPressed,
    //     style: ElevatedButton.styleFrom(
    //       backgroundColor: Colors.transparent,
    //       shadowColor: Colors.transparent,
    //       minimumSize: const Size(150, 50),
    //     ),
    //     icon: Icon(icon, color: Colors.white),
    //     label: Text(
    //       label,
    //       style: const TextStyle(
    //           fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
    //     ),
    //   ),
    // );
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize: const Size(150, 50),
          ),
          icon: Icon(icon, color: Colors.white),
          label: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );

  }

// Helper method to capitalize first letter
//   String capitalizeFirstLetter(String input) {
//     return input.isEmpty ? input : input[0].toUpperCase() + input.substring(1);
//   }

  // @override
  // Widget build(BuildContext context) {
  //   print(widget.specificTaskDetails);
  //   print(widget.dropdownRiskItemsValues);
  //   print("dropdownRiskItemsValuesdropdownRiskItemsValues");
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text(
  //         "Risk Assessment Overview",
  //         style: TextStyle(fontWeight: FontWeight.bold),
  //       ),
  //     ),
  //     body: Padding(
  //       padding: EdgeInsets.all(16.0),
  //       child: SingleChildScrollView(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               "Selected Risk Items:",
  //               style: TextStyle(
  //                 fontWeight: FontWeight.bold,
  //                 fontSize: 20,
  //                 color: Colors.black,
  //               ),
  //             ),
  //             SizedBox(height: 8),
  //             if (widget.selectedNamesWithType.isNotEmpty)
  //               Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   ...widget.selectedNamesWithType
  //                       .fold<Map<String, List<Map<String, dynamic>>>>({},
  //                           (acc, item) {
  //                         String type = item['type'] ?? 'Unknown Type';
  //
  //                         if (acc.containsKey(type)) {
  //                           acc[type]?.add(item);
  //                         } else {
  //                           acc[type] = [item];
  //                         }
  //                         return acc;
  //                       })
  //                       .entries
  //                       .map((entry) {
  //                         return Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             Text(
  //                               capitalizeFirstLetter(entry.key),
  //                               style: TextStyle(
  //                                 fontSize: 18,
  //                                 fontWeight: FontWeight.bold,
  //                                 color: Colors.blue,
  //                               ),
  //                             ),
  //                             SizedBox(height: 10),
  //                             ...entry.value.map((item) {
  //                               return Text(
  //                                 "- ${item['name']}",
  //                                 style: TextStyle(fontSize: 16),
  //                               );
  //                             }).toList(),
  //                             SizedBox(height: 10),
  //                           ],
  //                         );
  //                       })
  //                       .toList(),
  //                   ...widget.dropdownRiskItemsValues.entries
  //                       .fold<Map<String, List<Map<String, dynamic>>>>({}, (acc, entry) {
  //                     String? type = entry.value;
  //                     String name = entry.key;
  //
  //                     if (type != null && type.isNotEmpty) {
  //                       if (acc.containsKey(type)) {
  //                         acc[type]?.add({'name': name});
  //                       } else {
  //                         acc[type] = [{'name': name}];
  //                       }
  //                     }
  //                     return acc;
  //                   })
  //                       .entries
  //                       .expand((entry) => [
  //                     Text(
  //                       capitalizeFirstLetter(entry.key),
  //                       style: TextStyle(
  //                         fontSize: 18,
  //                         fontWeight: FontWeight.bold,
  //                         color: Colors.blue,
  //                       ),
  //                     ),
  //                     SizedBox(height: 10),
  //                     ...entry.value.map((item) {
  //                       String displayText = item['name'];
  //
  //                       if (widget.specificTaskDetails.containsKey(item['name'])) {
  //                         displayText = '${item['name']} - ${widget.specificTaskDetails[item['name']] ?? 'No value'}';
  //                       }
  //
  //                       return Text(
  //                         displayText,
  //                         style: TextStyle(fontSize: 16),
  //                       );
  //                     }).toList(),
  //
  //                     SizedBox(height: 10),
  //                   ])
  //                       .toList()
  //
  //                 ],
  //               )
  //             else
  //               Text(
  //                 "No items selected.",
  //                 style: TextStyle(fontSize: 16, color: Colors.grey),
  //               ),
  //             SizedBox(height: 20),
  //             Text(
  //               "Hazard Responses:",
  //               style: TextStyle(
  //                 fontWeight: FontWeight.bold,
  //                 fontSize: 20,
  //                 color: Colors.black,
  //               ),
  //             ),
  //             SizedBox(height: 8),
  //             if (widget.hazardResponses.isNotEmpty)
  //               Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: widget.hazardResponses.entries.map((entry) {
  //                   Map<String, dynamic> question;
  //                   if (isNetworkAvailable) {
  //                     question = widget.hazard_question_items.firstWhere(
  //                       (item) => item['id'] == entry.key,
  //                       orElse: () => {
  //                         "installation_question": "Unknown Question",
  //                         "risk_control": ""
  //                       },
  //                     );
  //                   } else {
  //                     question = widget.hazard_question_items.firstWhere(
  //                       (item) => item['id'] == entry.key,
  //                       orElse: () => {
  //                         "installation_question": "Unknown Question",
  //                         "risk_control": "",
  //                       } as Map<String, Object>,
  //                     );
  //                   }
  //                   return RichText(
  //                     text: TextSpan(
  //                       children: [
  //                         TextSpan(
  //                           text: "• ",
  //                           style: TextStyle(
  //                               fontSize: 20,
  //                               color: Colors.black,
  //                               fontWeight: FontWeight.bold),
  //                         ),
  //                         TextSpan(
  //                           text: "${question['installation_question']} ",
  //                           style: TextStyle(
  //                               fontSize: 17,
  //                               color: Colors.blue,
  //                               fontWeight: FontWeight.bold),
  //                         ),
  //                         TextSpan(
  //                           text: "(${question['risk_control']}):  ",
  //                           style: TextStyle(fontSize: 16, color: Colors.black),
  //                         ),
  //                         TextSpan(
  //                           text: " ${entry.value}",
  //                           style: TextStyle(
  //                               fontSize: 17,
  //                               color: Colors.red,
  //                               fontWeight: FontWeight.bold),
  //                         ),
  //                       ],
  //                     ),
  //                   );
  //                 }).toList(),
  //               )
  //             else
  //               Text(
  //                 "No responses recorded.",
  //                 style: TextStyle(fontSize: 16, color: Colors.grey),
  //               ),
  //           ],
  //         ),
  //       ),
  //     ),
  //     bottomNavigationBar: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           ElevatedButton(
  //             onPressed: () {
  //               print("Edit button pressed${widget.responses}");
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => RiskAssessmentPage(
  //                       args: widget.args,
  //                       allowedTypes: widget.allowedTypes,
  //                       selectedDetails: widget.selectedDetails,
  //                       worksheetId: widget.worksheetId!,
  //                       categIdList: widget.categIdList,
  //                       projectId: widget.projectId,
  //                       selectedCheckboxes: widget.selectedCheckboxes,
  //                       selectedRiskItemCheckboxes: widget.selectedRiskItemCheckboxes,
  //                       dropdownValues: widget.dropdownValues,
  //                       dropdownRiskItemsValues: widget.dropdownRiskItemsValues,
  //                       specificTaskDetails: widget.specificTaskDetails,
  //                       team_member_ids: widget.team_member_ids,
  //                       hazardResponses: widget.hazardResponses),
  //                 ),
  //               );
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.red,
  //               minimumSize: Size(160, 50),
  //             ),
  //             child: Text(
  //               "Edit",
  //               style: TextStyle(
  //                 color: Colors.white,
  //                 fontWeight: FontWeight.bold,
  //                 fontSize: 15,
  //               ),
  //             ),
  //           ),
  //           SizedBox(
  //             width: 20,
  //           ),
  //           ElevatedButton(
  //             onPressed: () async {
  //               print("Done button pressed");
  //               _getFromCamera("check_in");
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.green,
  //               minimumSize: Size(160, 50),
  //             ),
  //             child: Text(
  //               "Done",
  //               style: TextStyle(
  //                 color: Colors.white,
  //                 fontWeight: FontWeight.bold,
  //                 fontSize: 15,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Future<bool> _checkCameraPermission() async {
    PermissionStatus status = await Permission.camera.status;

    if (status.isDenied) {
      status = await Permission.camera.request();
      if (status.isDenied) {
        return false;
      }
    }

    if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }

    if (status.isGranted) {
      return true;
    }

    return false;
  }

  Future<void> _getFromCamera(String checklistType) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('url') ?? 0;
    try {
      bool hasPermission = await _checkCameraPermission();
      if (!hasPermission) {
        setState(() {
          isImageLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera permission is required to proceed.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      print("dddddddddddddddddddddddddddddddddddddd");
      // final box = await Hive.openBox<HiveImage>('imagesBox');
      // HiveImage? existingImage = box.values.cast<HiveImage?>().firstWhere(
      //       (image) =>
      //           image != null &&
      //           image.checklistType == checklistType &&
      //           image.projectId == widget.projectId,
      //       orElse: () => null,
      //     );
      // if (existingImage != null) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('You already uploaded an image for this selfie.'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      //   return;
      // }
      if (!isNetworkAvailable) {
        final box = await Hive.openBox<HiveImage>('imagesBox');
        HiveImage? existingImage = box.values.cast<HiveImage?>().firstWhere(
              (image) =>
                  image != null &&
                  image.checklistType == checklistType &&
                  image.projectId == widget.projectId,
              orElse: () => null,
            );
        if (existingImage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You already uploaded an image for this selfie.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      print("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
      XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxHeight: 1000,
        maxWidth: 1000,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        List<int> imageBytes = await imageFile.readAsBytes();
        String base64Image = base64Encode(imageBytes);
        try {
          // Position position = await _getCurrentLocation();
          Position? position = await _getCurrentLocation();
          if (position == null) {
            setState(() {
              isImageLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('You must enable location permissions to proceed.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          print(widget.workTypeIdList);
          print("fffffffffffwidget.workTypeIdList");
          if (widget.workTypeIdList.isEmpty) {
            setState(() {
              isImageLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    "Work Type is empty. You can't continue the checkin process."),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          if (!isNetworkAvailable) {
            print("hjjjjjjjjjjjjjjjjjjjjjjjjjjj");
            await _saveImageToHive(checklistType, base64Image, position);
            final box = await Hive.openBox<HiveImage>('imagesBox');
            final selfies = box.values
                .where((selfie) => selfie.checklistType == checklistType);
            if (selfies.isNotEmpty) {
              final lastSelfie = selfies.last;
              final timeDifference =
                  DateTime.now().difference(lastSelfie.timestamp);
              setState(() {
                checkIndifference = timeDifference;
                Middifference = timeDifference;
                isQrVisible = true;
                setState(() {});
              });
            }
            print("5555555555555555555dddddddddddddddddddd");
            var newargs = Map<String, dynamic>.from(widget.args);
            newargs['isQrVisible'] = true;
            setState(() {
              isImageLoading = false;
            });
            await _attendanceAdd(widget.worksheetId,position,widget.memberId);
            setState(() {
              _startController(widget.projectId);
            });
            Navigator.popAndPushNamed(
              context,
              '/installing_form_view',
              arguments: newargs,
            );
            print("ggggggggggggggggggggggggggggggggggggggggggggggg");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Network unavailable. Image saved for later upload.'),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            try {
              await _saveImageToHive(checklistType, base64Image, position);
              print(widget.categIdList);
              print(checklistType);
              print(widget.workTypeIdList);
              print("categIdListcategdddddIdListcategIdList");
              // final checklist = await client?.callKw({
              //   'model': 'installation.checklist',
              //   'method': 'search_read',
              //   'args': [
              //     [
              //       ['category_ids', 'in', widget.categIdList],
              //       ['selfie_type', '=', checklistType],
              //       ['group_ids', 'in', widget.workTypeIdList]
              //     ],
              //     ['id']
              //   ],
              //   'kwargs': {},
              // });
              final Uri url = Uri.parse('$baseUrl/rebates/installation_checklist');
              final checklist = await http.post(
                url,
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "jsonrpc": "2.0",
                  "method": "call",
                  "params": {
                    "categIdList": widget.categIdList,
                    "workTypeIdList": widget.workTypeIdList,
                    "selfie_type": checklistType
                  }
                }),
              );
              final Map<String, dynamic> jsonChecklistResponse = json.decode(checklist.body);
              print(
                  "checklistchegggggggggggggggvvvvvvvvvvvgggggggggcklistchecklist$checklist");
              print(
                  "checklistcheckdddddddddddddddddddddddddddddddddlistchecklist$progressChange");
              print(jsonChecklistResponse['result']['installation_checklist'][0]['id']);
              print(base64Image);
              print(position);
              // await _uploadImage(checklist[0]['id'], base64Image, position);
              // await _startController(widget.projectId);
              bool success = await _uploadImage(jsonChecklistResponse['result']['installation_checklist'][0]['id'], base64Image, position);
              if (success) {
                await _attendanceAdd(widget.worksheetId,position,widget.memberId);
                await _startController(widget.projectId);
                print("Image uploaded successfully.");
                Map<String, dynamic> progressData = {
                  'worksheetId': widget.worksheetId,
                  'progressChange': progressChange,
                  'isStartjob': true
                };
                setState(() {
                  SharedState.progressData = progressData;
                });
                print(SharedState.progressData);
                print("SharedState.progressChange");
                var newargs = Map<String, dynamic>.from(widget.args);

                newargs['isQrVisible'] = true;
                setState(() {
                  isImageLoading = false;
                });
                Navigator.popAndPushNamed(
                  context,
                  '/installing_form_view',
                  arguments: newargs,
                );
              } else {
                print("Image upload failed.");
                var newargs = Map<String, dynamic>.from(widget.args);
                setState(() {
                  isImageLoading = false;
                });
                Navigator.popAndPushNamed(
                  context,
                  '/installing_form_view',
                  arguments: newargs,
                );
              }
              setState(() {});
              print("fffffffffffffffffffffffffff$progressChange");
              // Map<String, dynamic> progressData = {
              //   'worksheetId': widget.worksheetId,
              //   'progressChange': progressChange,
              //   'isStartjob': true
              // };
              // setState(() {
              //   SharedState.progressData = progressData;
              // });
              // print(SharedState.progressData);
              // print("SharedState.progressChange");
              // var newargs = Map<String, dynamic>.from(widget.args);
              //
              // newargs['isQrVisible'] = true;
              // setState(() {
              //   isImageLoading = false;
              // });
              // Navigator.popAndPushNamed(
              //   context,
              //   '/installing_form_view',
              //   arguments: newargs,
              // );
            } catch (r) {
              print("rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr$r");
            }
          }
        } catch (t) {
          print("tttttttttttttttttttttttttttttt$t");
        }
      }
    } catch (e) {}
  }

  Future<void> _saveImageToHive(
      String checklistType, String base64Image, position) async {
    Box<HiveImage>? box;
    try {
      final imageEntry = HiveImage(
        checklistType: checklistType,
        base64Image: base64Image,
        projectId: widget.projectId,
        categIdList: widget.categIdList,
        position: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        timestamp: DateTime.now(),
      );

      box = await Hive.openBox<HiveImage>('imagesBox');
      await box.add(imageEntry);
      print("Image saved successfully.${box.values}");
    } catch (e) {
      print("Error saving image to Hive: $e");
    } finally {
      if (box != null && box.isOpen) {
        try {
          await box.close();
          print("Box closed properly.");
        } catch (e) {
          print("Error closing box: $e");
        }
      }
    }
  }

  // Future<void> _saveImageToHive(
  //     String checklistType, String base64Image, position) async {
  //   Box<HiveImage>? box;
  //   print("555555555555%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%");
  //   try {
  //     final imageEntry = HiveImage(
  //       checklistType: checklistType,
  //       base64Image: base64Image,
  //       projectId: widget.projectId,
  //       categIdList: widget.categIdList,
  //       position: {
  //         'latitude': position.latitude,
  //         'longitude': position.longitude,
  //       },
  //       timestamp: DateTime.now(),
  //     );
  //     box = await Hive.openBox<HiveImage>('imagesBox');
  //     await box.add(imageEntry);
  //     print(box.isOpen);
  //     print("Idfggggggggggggggggggmage saved successfully.");
  //   } catch (e) {
  //     print("Error saving image to Hive: $e");
  //   } finally {
  //     if (box != null && box.isOpen) {
  //       box.close();
  //       print("Box closeeeeeeeeeeeeed properly.");
  //     }
  //   }
  // }

  Future<void> _saveStartToHive(int taskId, String date) async {
    final box = await Hive.openBox<TaskJob>('taskJobsBox');
    try {
      final taskJob = TaskJob(taskId: taskId, date: date);

      await box.add(taskJob);
      print('TaskJob saved successfully!');
    } catch (e) {
      print('Error saving TaskJob to Hive: $e');
    } finally {
      await box.close();
    }
  }

  Future<void> _startController(taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    final String formattedDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    if (!isNetworkAvailable) {
      await _saveStartToHive(taskId, formattedDate);
      setState(() {
        progressChange = false;
        isStartjob = true;
      });
    } else {
      try {
        final response = await client?.callKw({
          'model': 'project.task',
          'method': 'write',
          'args': [
            [taskId],
            {
              'install_status': 'progress',
              'date_worksheet_start':
                  DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())
            }
          ],
          'kwargs': {},
        });
        if (response == true) {
          setState(() {
            progressChange = false;
            isStartjob = true;
          });
          final box = await Hive.openBox<InstallingJob>('installationListBox');
          final installJob = box.get(taskId);

          if (installJob != null) {
            final updatedServiceJob =
                installJob.copyWith(install_status: 'progress');
            await box.put(taskId, updatedServiceJob);
          }
        } else {}
      } catch (e) {}
    }
  }

  Future<void> _saveAttendanceToHive(int worksheetId, position, formattedDate, int memberId) async {
    print('Attendance ssssssssssssssssssssaved to Hive');
    var box = await Hive.openBox<Attendance>('attendance');
    await box.clear();
    print(position.latitude);
    final attendance = Attendance(
      worksheetId: worksheetId,
      latitude: position.latitude,
      longitude: position.longitude,
      date: formattedDate,
      memberId: memberId,
    );
    await box.put(worksheetId,attendance);

    print('Attendance saved to Hive');
  }

  Future<void> _attendanceAdd(int worksheetId, position, int memberId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    final String formattedDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    if (!isNetworkAvailable) {
      await _saveAttendanceToHive(worksheetId,position, formattedDate,memberId);

    } else {
      try {
        final formattedDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
        final response = await client?.callKw({
          'model': 'worksheet.attendance',
          'method': 'create',
          'args': [
            {
              'type': 'check_in',
              'worksheet_id': worksheetId,
              'in_latitude': position.latitude,
              'in_longitude': position.longitude,
              'member_id': memberId,
              'date': formattedDate
            }
          ],
          'kwargs': {},
        });
        if (response == true) {
          // setState(() {
          //   progressChange = false;
          //   isStartjob = true;
          // });

        } else {}
      } catch (e) {}
    }
  }

  // Future<Position> _getCurrentLocation() async {
  //   print("pppppppppppppppppppppppppppppppppppppp");
  //   LocationPermission permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       permission = await Geolocator.requestPermission();
  //       // throw Exception('Location permissions are denied');
  //     }
  //   }
  //   return await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high);
  // }

  Future<Position?> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null; // Return null if permissions are still denied
      }
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Future<void> _uploadImage(int id, String base64Image, position) async {
  //   print(id);
  //   print(base64Image);
  //   print(position);
  //   print(
  //       "444444444444444444444ccccccccccccccccccccccccccccccc444444444fffffffffff");
  //   print("F");
  //   // setState(() {
  //   //   isImageLoading = true;
  //   // });
  //   try {
  //     List<Placemark> placemarks =
  //         await placemarkFromCoordinates(position.latitude, position.longitude);
  //     Placemark place = placemarks.first;
  //     String locationDetails =
  //         "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
  //     // final worksheet = await client?.callKw({
  //     //   'model': 'task.worksheet',
  //     //   'method': 'search_read',
  //     //   'args': [
  //     //     [
  //     //       ['task_id', '=', projectId],
  //     //     ],
  //     //   ],
  //     //   'kwargs': {},
  //     // });
  //     // if (worksheet != null && worksheet.isNotEmpty) {
  //     //   worksheetId = worksheet[0]['id'];
  //     // }
  //     print(
  //         "${DateTime.now()}ffffffffffffffffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee");
  //     final formattedDate =
  //         DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  //
  //     final checklist = await client?.callKw({
  //       'model': 'installation.checklist.item',
  //       'method': 'create',
  //       'args': [
  //         {
  //           'user_id': userId,
  //           'worksheet_id': widget.worksheetId,
  //           'checklist_id': id,
  //           'date': formattedDate,
  //           'image': base64Image,
  //           'location': locationDetails,
  //           'latitude': position.latitude,
  //           'longitude': position.longitude
  //         }
  //       ],
  //       'kwargs': {},
  //     });
  //     print("fffffffffffffffffddddddddddfffffffffffffffffff");
  //     // setState(() async {
  //     //   await _getSelfies();
  //     //   isImageLoading = false;
  //     //   print("ffffffffffffffffffffffffffffffffffff");
  //     //   isQrVisible = true;
  //     //   setState(() {});
  //     // });
  //   } catch (e) {
  //     // isImageLoading = false;
  //   }
  // }

  Future<bool> _uploadImage(int id, String base64Image, position) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('url') ?? 0;
    final teamId = prefs.getInt('teamId') ?? 0;
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks.first;
      String locationDetails =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";

      final formattedDate =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // final response = await client?.callKw({
      //   'model': 'installation.checklist.item',
      //   'method': 'create',
      //   'args': [
      //     {
      //       'user_id': userId,
      //       'worksheet_id': widget.worksheetId,
      //       'checklist_id': id,
      //       'date': formattedDate,
      //       'image': base64Image,
      //       'location': locationDetails,
      //       'latitude': position.latitude,
      //       'longitude': position.longitude
      //     }
      //   ],
      //   'kwargs': {},
      // });

      // if (response != null && response is int) {
      final Uri url = Uri.parse('$baseUrl/rebates/installation_checklist_item/create');
      final checklist = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "teamId": teamId,
            "item": id,
            "taskId": widget.worksheetId,
            "base64Image": base64Image,
            "formattedDate": formattedDate,
            "locationDetails": locationDetails,
            'latitude': position.latitude,
            'longitude': position.longitude
          }
        }),
      );
      final Map<String, dynamic> jsonChecklistCreateResponse = json.decode(checklist.body);
      print("$jsonChecklistCreateResponse/fffffffffffffffffddddddddddfffffffffffffffffff");
      // if (checklist != null && checklist is int) {
      if (jsonChecklistCreateResponse['result']['status'] == "success") {
        print("Upload successful, checklist item ID: $jsonChecklistCreateResponse");
        return true;
      } else {
        print("Upload failed: Invalid response.");
        // isImageLoading = false;
        return false;
      }
    } catch (e) {
      print("Error uploading image: $e");
      // isImageLoading = false;
      return false;
    }
  }

}

class SharedState {
  static Map<String, dynamic> progressData = {};
}

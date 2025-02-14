import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../offline_db/signatures/installer_signature.dart';
import '../offline_db/signatures/owner_signature.dart';

class projectSignatures {

  int? userId;
  List<int> categoryIds = [];
  List<int> worksheetIds = [];
  OdooClient? client;
  String url = "";
  String userName = "";
  String witnessName = '';
  String? installerName;
  DateTime? installerDate;
  Uint8List? installerSignatureImageBytes;
  MemoryImage? installerSignatureImage;
  String? ownerName;
  DateTime? customerDate;
  Uint8List? ownerSignatureImageBytes;
  MemoryImage? ownerSignatureImage;
  Set<int> newInstallingWorksheetIds = {};
  Set<int> newOwnerWorksheetIds = {};

  Future<void> initializeOdooClient() async {
    print('initializeOdooClient');
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
    print('koli mp');
    getAllInstallerSignatures();
    getAllOwnerSignatures();
  }


  Future<void> getAllInstallerSignatures() async {
    print("444444444444444444444444444444444444");
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    userName = prefs.getString('userName') ?? '';

    try {
      final signaturesFromProjects = await client?.callKw({
        'model': 'project.task',
        'method': 'search_read',
        'args': [
          [
            // ['x_studio_proposed_team', '=', userId],
            ['team_lead_user_id', '=', userId],
            ['worksheet_id', '!=', null]
          ]
        ],
        'kwargs': {
          'fields': [
            'id',
            'install_signed_by',
            'install_signature',
            'date_worksheet_install',
            // 'witness_name'
          ],
        },
      });
      print(signaturesFromProjects);
      print("signaturesFromProjects");
      if (signaturesFromProjects != null && signaturesFromProjects.isNotEmpty) {
        for (final installerSign in signaturesFromProjects) {
          print(installerSign);
          print("installerSigninstallerSign");
          final projectId = installerSign['id'];
          if (!newInstallingWorksheetIds.contains(projectId)) {
            newInstallingWorksheetIds.add(projectId);
            print(newInstallingWorksheetIds);
            print("newJobIdsnewJobIdsnewJobIds555555555555");
          } else {
            print("Task $projectId already processed. Skipping...");
            continue;
          }
          // witnessName = installerSign['witness_name'] is String
          //     ? installerSign['witness_name']
          //     : '';
          installerName = userName ?? '';
          var dateValue = installerSign['date_worksheet_install'];
          print("$dateValue/dateValuedateValuedateValuedateValue");
          if (dateValue is String && dateValue.isNotEmpty) {
            installerDate = DateTime.tryParse(dateValue);
          } else if (dateValue is bool) {
            print('Boolean value encountered: $dateValue');
            installerDate = null;
          } else {
            installerDate = null;
          }
          // witnessName = installerSign['witness_name'] ?? '';
          // installerName = userName;
          // installerDate = DateTime.tryParse(installerSign['date_worksheet_install'] ?? '');


          print("4444444444444444444444444444444444444444444");
          if (installerSign['install_signature'] is String) {
            final imageBase64 = installerSign['install_signature'] as String;
            if (imageBase64.isNotEmpty) {
              final imageData = base64Decode(imageBase64);
              installerSignatureImageBytes = Uint8List.fromList(imageData);
              installerSignatureImage = MemoryImage(installerSignatureImageBytes!);
              await saveInstallerSignatureToHive(projectId);
            }
          }


        }
        print('All installer signatures have been saved to Hive.');
      } else {
        print('No signatures found for any projects.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> saveInstallerSignatureToHive(int projectId) async {
    print("888888876543456789");
    print(witnessName);
    print(installerName);
    print(projectId);
    final box = await Hive.openBox<InstallerSignature>('installerSignatures_$projectId');
    final installerSignature = InstallerSignature(
      witnessName: witnessName,
      installerName: installerName,
      installerDate: installerDate,
      installerSignatureImageBytes: installerSignatureImageBytes ?? Uint8List(0),
    );

    await box.put(projectId, installerSignature);
    print('Installer signature for project $projectId saved to Hive');
  }

  Future<void> getAllOwnerSignatures() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    try {
      final ownerSignatureFromProject = await client?.callKw({
        'model': 'project.task',
        'method': 'search_read',
        'args': [
          [
            // ['x_studio_proposed_team', '=', userId],
            ['team_lead_user_id', '=', userId],
            ['worksheet_id', '!=', null]
          ]
        ],
        'kwargs': {
          'fields': [
            'partner_id',
            'customer_name',
            'customer_signature',
            'date_worksheet_client_signature',
          ],
        },
      });
      if (ownerSignatureFromProject != null &&
          ownerSignatureFromProject.isNotEmpty) {
        for (final ownerSign in ownerSignatureFromProject) {
          final projectId = ownerSign['id'];
          if (!newOwnerWorksheetIds.contains(projectId)) {
            newOwnerWorksheetIds.add(projectId);
            print(newOwnerWorksheetIds);
            print("newJobIdsnewJobIdsnewJobIds555555555555");
          } else {
            print("Task $projectId already processed. Skipping...");
            continue;
          }
          ownerName = ownerSign['partner_id'][1] is String
              ? ownerSign['partner_id'][1]
              : '';
          var dateValue = ownerSign['date_worksheet_client_signature'];
          if (dateValue is String && dateValue.isNotEmpty) {
            customerDate = DateTime.tryParse(dateValue);
          } else if (dateValue is bool) {
            customerDate = null;
          } else {
            customerDate = null;
          }
          // ownerName = ownerSign['partner_id'][1] ?? '';
          // customerDate = DateTime.tryParse(
          //     ownerSign['date_worksheet_client_signature']) ??
          //     null;
          if (ownerSign['customer_signature'] is String) {
            final imageBase64 = ownerSign['customer_signature'] as String;
            if (imageBase64.isNotEmpty) {
              final imageData = base64Decode(imageBase64);
              ownerSignatureImageBytes = Uint8List.fromList(imageData);
              ownerSignatureImage = MemoryImage(ownerSignatureImageBytes!);
              await saveOwnerSignatureToHive(projectId);
            }
          } else {
            print('Install signature is not a valid string.');
          }
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> saveOwnerSignatureToHive(int projectId) async {
    final box = await Hive.openBox<OwnerSignatureHive>('ownerSignatures');
    final ownerSign = OwnerSignatureHive(
      ownerName: ownerName,
      customerDate: customerDate,
      ownerSignatureImageBytes: ownerSignatureImageBytes,
    );
      await box.put(projectId, ownerSign);
    }
    // final existingOwnerSign = box.get(projectId);
    //
    //
    // print("Saving owner signature for project $projectId:");
    // print("New Owner Name: ${ownerSign.ownerName}");
    // print("New Customer Date: ${ownerSign.customerDate}");
    // print("New Owner Signature Image Bytes: ${ownerSign.ownerSignatureImageBytes?.length} bytes");
    //
    // if (existingOwnerSign != null) {
    //   print("Existing owner signature found for project $projectId:");
    //   print("Existing Owner Name: ${existingOwnerSign.ownerName}");
    //   print("Existing Customer Date: ${existingOwnerSign.customerDate}");
    //   print("Existing Owner Signature Image Bytes: ${existingOwnerSign.ownerSignatureImageBytes?.length} bytes");
    // } else {
    //   print("No existing owner signature found for project $projectId.");
    // }
    //
    // if (existingOwnerSign == null || _areOwnerSignaturesDifferent(existingOwnerSign, ownerSign)) {
    //   await box.put(projectId, ownerSign);
    //   print("Owner signature saved to Hive for project $projectId.");
    // } else {
    //   print("Owner signature is identical to the existing one. Skipping storage.");
    // }
  // }


  bool _areOwnerSignaturesDifferent(OwnerSignatureHive existing, OwnerSignatureHive newSignature) {
    return existing.ownerName != newSignature.ownerName ||
        existing.customerDate != newSignature.customerDate ||
        !listEquals(existing.ownerSignatureImageBytes, newSignature.ownerSignatureImageBytes);
  }

}

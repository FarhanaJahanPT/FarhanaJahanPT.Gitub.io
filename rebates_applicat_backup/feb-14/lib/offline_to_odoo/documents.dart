import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../offline_db/installation_form/project_document.dart';

class documentsList {
  int? userId;
  List<int> categoryIds = [];
  List<int> worksheetIds = [];
  OdooClient? client;
  String url = "";
  MemoryImage? derRecieptDocumet;
  MemoryImage? ccewDocumet;
  MemoryImage? stcDocumet;
  MemoryImage? solarPanelDocumet;
  MemoryImage? switchBoardDocumet;
  MemoryImage? batteryLocationDocument;
  MemoryImage? inverterLocationDocumet;
  Set<int> newDocumentIds = {};

  Future<void> initializeOdooClient() async {
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
    getDocuments();
  }

  Future<void> getDocuments() async {
    print("000000000000000ffffcccccccccccccccccccccccffffffff000000000dddddddd");
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    try {
      final documentsFromProject = await client?.callKw({
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
            'x_studio_der_receipt',
            'x_studio_ccew',
            'x_studio_stc',
            'x_studio_solar_panel_layout',
            'x_studio_switch_board_photo',
            'x_studio_inverter_location_1',
            'x_studio_battery_location',
          ],
        },
      });
      print("ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd");
      if (documentsFromProject != null && documentsFromProject.isNotEmpty) {
        for (final document in documentsFromProject) {
          int documentId = document['id'];

          if (!newDocumentIds.contains(documentId)) {
            newDocumentIds.add(documentId);
            print(newDocumentIds);
            print("newJobIdsnewJobIdbbbbbbbbbbbbbbsnewJobIds555555555555");
          } else {
            print("Task $documentId already processed. Skipping...");
            continue;
          }
          final projectId = document['id'];
          final derReceipt = document['x_studio_der_receipt'];
          final ccewDoc = document['x_studio_ccew'];
          final stcDoc = document['x_studio_stc'];
          final solarPanelDoc = document['x_studio_solar_panel_layout'];
          final switchBoardDoc = document['x_studio_switch_board_photo'];
          final inverterLocationDoc = document['x_studio_inverter_location_1'];
          final batteryLocationDoc = document['x_studio_battery_location'];
          if (derReceipt is String) {
            final derBase64 = derReceipt as String;
            if (derBase64.isNotEmpty) {
              final derData = base64Decode(derBase64);
              derRecieptDocumet = MemoryImage(Uint8List.fromList(derData));
            }
          }
          else{
            derRecieptDocumet = null;
          }
          if (ccewDoc is String) {
            final ccewBase64 = ccewDoc as String;
            if (ccewBase64.isNotEmpty) {
              final ccewData = base64Decode(ccewBase64);
              ccewDocumet = MemoryImage(Uint8List.fromList(ccewData));
            }
          }
          else{
            ccewDocumet = null;
          }
          if (stcDoc is String) {
            final stcBase64 = stcDoc as String;
            if (stcBase64.isNotEmpty) {
              final stcData = base64Decode(stcBase64);
              stcDocumet = MemoryImage(Uint8List.fromList(stcData));
            }
          }
          else{
            stcDocumet = null;
          }
          if (solarPanelDoc is String) {
            final solarPanelBase64 = solarPanelDoc as String;
            if (solarPanelBase64.isNotEmpty) {
              final solarPanelData = base64Decode(solarPanelBase64);
              solarPanelDocumet =
                  MemoryImage(Uint8List.fromList(solarPanelData));
            }
          }
          else{
            solarPanelDocumet = null;
          }
          if (switchBoardDoc is String) {
            final switchBoardBase64 = switchBoardDoc as String;
            if (switchBoardBase64.isNotEmpty) {
              final switchBoardData = base64Decode(switchBoardBase64);
              switchBoardDocumet =
                  MemoryImage(Uint8List.fromList(switchBoardData));
            }
          }
          else{
            switchBoardDocumet = null;
          }
          if (inverterLocationDoc is String) {
            final inverterLocationBase64 = inverterLocationDoc as String;
            if (inverterLocationBase64.isNotEmpty) {
              final inverterLocationData = base64Decode(inverterLocationBase64);
              inverterLocationDocumet =
                  MemoryImage(Uint8List.fromList(inverterLocationData));
            }
          }
          else{
            inverterLocationDocumet = null;
          }
          if (batteryLocationDoc is String) {
            final batteryLocationBase64 = batteryLocationDoc as String;
            if (batteryLocationBase64.isNotEmpty) {
              final batteryLocationData = base64Decode(batteryLocationBase64);
              batteryLocationDocument =
                  MemoryImage(Uint8List.fromList(batteryLocationData));
            }
          }
          else{
            batteryLocationDocument = null;
          }
          await saveDocumentsToHive(projectId);
        }
      }
    } catch (e) {
      print("444444444444444444444ffffffffffffffffffffwwwwwwwwwwwwwwwwwwwwweeeeeeeeeeeeeeeeeeeee$e");
    }
  }

  Future<void> saveDocumentsToHive(int projectId) async {
    print("zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz");
    final box = await Hive.openBox<ProjectDocuments>('projectDocumentsBox');

    final projectDocuments = ProjectDocuments(
      derReceipt: derRecieptDocumet?.bytes,
      ccewDoc: ccewDocumet?.bytes,
      stcDoc: stcDocumet?.bytes,
      solarPanelDoc: solarPanelDocumet?.bytes,
      switchBoardDoc: switchBoardDocumet?.bytes,
      inverterLocationDoc: inverterLocationDocumet?.bytes,
      batteryLocationDoc: batteryLocationDocument?.bytes,
    );
    final existingDocuments = box.get(projectId);

    if (existingDocuments == null) {
      await box.put(projectId, projectDocuments);
      print("New documents saved for projectId $projectId");
    } else {
      if (_areDocumentsDifferent(existingDocuments, projectDocuments)) {
        await box.put(projectId, projectDocuments);
        print("Documents updated for projectId $projectId");
      } else {
        print("No changes detected, skipping storage for projectId $projectId");
      }
    }

    await box.close();
  }


  bool _areDocumentsDifferent(ProjectDocuments existing, ProjectDocuments newDoc) {
    return !_areByteArraysEqual(existing.derReceipt, newDoc.derReceipt) ||
        !_areByteArraysEqual(existing.ccewDoc, newDoc.ccewDoc) ||
        !_areByteArraysEqual(existing.stcDoc, newDoc.stcDoc) ||
        !_areByteArraysEqual(existing.solarPanelDoc, newDoc.solarPanelDoc) ||
        !_areByteArraysEqual(existing.switchBoardDoc, newDoc.switchBoardDoc) ||
        !_areByteArraysEqual(existing.inverterLocationDoc, newDoc.inverterLocationDoc) ||
        !_areByteArraysEqual(existing.batteryLocationDoc, newDoc.batteryLocationDoc);
  }


  bool _areByteArraysEqual(Uint8List? existingBytes, Uint8List? newBytes) {
    if (existingBytes == null && newBytes == null) return true;
    if (existingBytes == null || newBytes == null) return false;
    if (existingBytes.length != newBytes.length) return false;
    for (int i = 0; i < existingBytes.length; i++) {
      if (existingBytes[i] != newBytes[i]) return false;
    }

    return true;
  }
// await box.put(projectId, projectDocuments);
// await box.close();
// }
}

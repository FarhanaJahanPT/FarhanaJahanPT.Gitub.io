import 'package:hive/hive.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../offline_db/swms/swms_detail.dart';

class RiskAssessment {
  int? userId;
  List<int> categoryIds = [];
  List<int> worksheetIds = [];
  OdooClient? client;
  String url = "";
  Set<int> newNotificationIds = {};
  List<Map<String, dynamic>> swmsDetails = [];

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
    getRiskItems();
  }


  Future<void> getRiskItems() async {
    print("------------------------------------------dddddddd");
    final swmslist = await client?.callKw({
      'model': 'swms.risk.work',
      'method': 'search_read',
      'args': [
        [
        ]
      ],
      'kwargs': {},
    });
    print(swmslist);
    print("swmslistswmslisteeeeedddddddddddddddddeeeeeeeeeeee");
    if (swmslist != null) {
      swmsDetails = swmslist.map<Map<String, dynamic>>((item) {
        return {'name': item['name'] ?? 'N/A', 'type': item['type'] ?? 'N/A'};
      }).toList();
      print(swmslist);
      print("ffffffffffffffffkkkkkkkkkkkkk");
    }
    await saveSWMSDetailsToHive(swmsDetails);
  }

  Future<void> saveSWMSDetailsToHive(List<Map<String, dynamic>> swmsDetails) async {
    try {
      var box = await Hive.openBox<SWMSDetail>('swmsDetailsBox');
      List<SWMSDetail> swmsList = swmsDetails.map((item) {
        return SWMSDetail(name: item['name'], type: item['type']);
      }).toList();

      await box.addAll(swmsList);
      print("SWMS Details saved to Hive.");
    } catch (e) {
      print("Error while saving service jobs to Hive: $e");
    }
  }


}

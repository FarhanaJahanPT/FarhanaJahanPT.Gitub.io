import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

import '../installation/checklist.dart';
import '../offline_db/checklist/checklist_item_hive.dart';
import '../offline_db/installation_form/owner_details.dart';

class PartnerDetails {

  int? userId;
  List<int> categoryIds = [];
  List<int> worksheetIds = [];
  OdooClient? client;
  String url = "";
  Map<DateTime, List<Map<String, String>>> _events = {};
  Set<int> newProjectIds = {};

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
    getOwnerDetails();
  }

  Future<void> getOwnerDetails() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;

    try {
      final partnerDetails = await client?.callKw({
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
          'fields': ['id', 'partner_id'],
        },
      });

      if (partnerDetails != null && partnerDetails.isNotEmpty) {
        // Open Hive box to store partner details
        final box = await Hive.openBox<Partner>('partners');

        for (var project in partnerDetails) {
          final projectId = project['id']; // Get the project ID
          final partnerId = project['partner_id'][0];
          if (!newProjectIds.contains(projectId)) {
            newProjectIds.add(projectId);
            print(newProjectIds);
            print("newJobIdsnewJobIdsnewJobIds555555555555");
          } else {
            print("Task $projectId already processed. Skipping...");
            continue;
          }
          // Fetch details for each partner
          final partnerDetailsFromProject = await client?.callKw({
            'model': 'res.partner',
            'method': 'search_read',
            'args': [
              [
                ['id', '=', partnerId],
              ]
            ],
            'kwargs': {
              'fields': ['name', 'company_type', 'phone', 'email'],
            },
          });

          if (partnerDetailsFromProject != null && partnerDetailsFromProject.isNotEmpty) {
            final partner = Partner(
              id: partnerId,
              name: partnerDetailsFromProject[0]['name'],
              companyType: partnerDetailsFromProject[0]['company_type'],
              phone: partnerDetailsFromProject[0]['phone'],
              email: partnerDetailsFromProject[0]['email'],
            );


            await box.put(projectId, partner);
            print('Partner details saved for project ID $projectId');
          }
        }
        print('All partner details have been saved to Hive using project IDs.');
      } else {
        print('No partner details found for the projects.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}

import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../offline_db/qr/qr_code.dart';

class QrCodeGenerate {
  String? url;
  OdooClient? client;
  int userId = 0;
  Set<int> newWorksheetIds = {};

  Future<void> initializeOdooClient() async {
    final prefs = await SharedPreferences.getInstance();
    url = prefs.getString('url') ?? '';
    final db = prefs.getString('selectedDatabase') ?? '';
    final sessionId = prefs.getString('sessionId') ?? '';
    final serverVersion = prefs.getString('serverVersion') ?? '';
    final userLang = prefs.getString('userLang') ?? '';
    final companyId = prefs.getInt('companyId');
    final allowedCompaniesStringList = prefs.getStringList('allowedCompanies') ?? [];
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

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return;
    }
    createQr();
  }

  Future<void> createQr() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    final filter = [
      ['x_studio_type_of_service', 'in', ['New Installation', 'Service']]
    ];

    try {
      final response = await client?.callKw({
        'model': 'task.worksheet',
        'method': 'search',
        'args': [filter],
        'kwargs': {},
      });

      if (response != null && response is List && response.isNotEmpty) {
        for (final id in response) {
          if (!newWorksheetIds.contains(id)) {
            newWorksheetIds.add(id);
          } else {
            continue;
          }
          final existingQrCode = await readQrCode(id);
          if (existingQrCode == null) {
            try {
              final generateResponse = await client?.callKw({
                'model': 'task.worksheet',
                'method': 'action_generate_qr_code',
                'args': [id],
                'kwargs': {},
              });

              if (generateResponse == true) {
                final newQrCode = await readQrCode(id);
                if (newQrCode != null) {
                } else {
                }
              } else {
              }
            } catch (e) {
            }
          } else {
          }
        }
      } else {
      }
    } catch (e) {
    }
  }

  Future<String?> readQrCode(int id) async {
    try {
      final response = await client?.callKw({
        'model': 'task.worksheet',
        'method': 'read',
        'args': [
          [id]
        ],
        'kwargs': {
          'fields': ['qr_code','task_id'],
        },
      });
      if (response != null && response.isNotEmpty) {
        String? qrCode = response[0]['qr_code'] as String?;
        int projectId = (response[0]['task_id'] as List).first;
        if (qrCode != null) {
          await _saveQrCodeToHive(id, qrCode,projectId);
        }
        return qrCode;
      }
    } catch (e) {
    }
    return null;
  }

  Future<void> _saveQrCodeToHive(int id, String qrCode,int projectId) async {
    final box = await Hive.openBox<Qr_Code>('qrCodes_$projectId');
    final qrCodeObject = Qr_Code(id: id, qrCode: qrCode);
    final existingQrCode = box.get('qr_code_$id');
    if (existingQrCode == null || _areQrCodesDifferent(existingQrCode, qrCodeObject)) {
      await box.put('qr_code_$id', qrCodeObject);
    } else {
    }
  }

  bool _areQrCodesDifferent(Qr_Code existing, Qr_Code newQrCode) {
    return existing.qrCode != newQrCode.qrCode;
  }
}

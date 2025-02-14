import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../offline_db/profile/profile.dart';

class Profile {
  String? url;
  OdooClient? client;
  int userId = 0;
  List<Map<String, dynamic>> userLicenseDetails = [];

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
    getUserProfile();
  }


  Future<void> getUserProfile() async {
    if (!Hive.isBoxOpen('user')) {
      await Hive.openBox('user');
    }
    final userBox = Hive.box('user');

    if (!await _isNetworkAvailable()) {
      await loadProfileFromHive();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    print("44444444444444fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
    try {
      final userDetails = await client?.callKw({
        'model': 'team.member',
        'method': 'search_read',
        'args': [
          [
            ['id', '=', 1]
          ]
        ],
        'kwargs': {
          'fields': [
            'name',
            'mobile',
            'contract_license_ids',
            'email',
            'active',
            'address',
            'image_1920'
          ],
        },
      });
      print(userDetails);
      print("userDetailsuserDetailsuserDetails");
      if (userDetails != null && userDetails.isNotEmpty) {
        final response = await client?.callKw({
          'model': 'electrical.contract.license',
          'method': 'search_read',
          'args': [
            [
              ['id', 'in', userDetails[0]['contract_license_ids']]
            ]
          ],
          'kwargs': {
            'fields': [
              'expiry_date',
              'number',
              'team_id',
              'type_id',
              'document'
            ],
          },
        });
        if (response != null) {
            userLicenseDetails = List<Map<String, dynamic>>.from(response);
        }
        final user = _parseUser(userDetails[0]);
        await saveUserToHive(user);
        try {
          final tasks = await client?.callKw({
            'model': 'project.task',
            'method': 'search_read',
            'args': [
              [
                // ['x_studio_proposed_team', '=', userId],
                ['team_lead_user_id', '=', userId],
                ['worksheet_id', '!=', false]
              ]
            ],
            'kwargs': {
              'fields': ['install_status'],
            },
          });

          int newTaskCount = 0;
          int completedTaskCount = 0;

          if (tasks != null) {
            for (var task in tasks) {
              var status = task['install_status'];
              if (status == 'progress') {
                newTaskCount++;
              } else if (status == 'done') {
                completedTaskCount++;
              }
            }
          }

          await userBox.put('userData', {
            'name': userDetails[0]['name'],
            'email': userDetails[0]['email'],
            'installingJobs': newTaskCount,
            'completedJobs': completedTaskCount,
            'image': userDetails[0]['image_1920'],
          });

        } catch (e) {
        }
      }
    } catch (e) {
    }
    finally{
    }
  }


  User _parseUser(Map<String, dynamic> user) {
    return User(
      name: user['name'] ?? "None",
      phone: (user['phone'] ?? "").toString(),
      email: user['email'] ?? "None",
      state: user['state'] ?? "Inactive",
      userLicenseDetails: userLicenseDetails ?? [],
      // signupExpiration: (user['signup_expiration'] == false || user['signup_expiration'] == null)
      //     ? "None"
      //     : user['signup_expiration'].toString(),
      // licensedNumber: (user['x_studio_act_electrical_licence_number'] == false || user['x_studio_act_electrical_licence_number'] == null)
      //     ? "None"
      //     : user['x_studio_act_electrical_licence_number'].toString(),
      contactAddressComplete: user['contact_address_complete'] ?? "None",
      imageBase64: user['image_1920'] is String ? user['image_1920'] : '',
    );
  }



  Future<void> saveUserToHive(User user) async {
    final box = await Hive.openBox<User>('userBox');
    final existingUser = box.get('currentUser');
    print(existingUser?.name);
    print("ooooooooooooooooooooooooooooooooooooooo");
    if (existingUser == null || !_isUserEqual(existingUser, user)) {
      await box.put('currentUser', user);
    } else {
    }
    await box.close();
  }


  bool _isUserEqual(User existingUser, User newUser) {
    return existingUser.name == newUser.name &&
        existingUser.phone == newUser.phone &&
        existingUser.email == newUser.email &&
        existingUser.state == newUser.state &&
        // existingUser.signupExpiration == newUser.signupExpiration &&
        existingUser.userLicenseDetails == newUser.userLicenseDetails &&
        existingUser.contactAddressComplete == newUser.contactAddressComplete &&
        existingUser.imageBase64 == newUser.imageBase64;
  }


  Future<void> loadProfileFromHive() async {
    final box = await Hive.openBox<User>('userBox');
    final user = box.get('currentUser');

    if (user != null) {
    } else {
    }
    await box.close();
  }


  Future<bool> _isNetworkAvailable() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi;
  }
}

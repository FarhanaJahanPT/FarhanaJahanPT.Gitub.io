import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../background/background_service.dart';
import '../offline_db/installation_form/owner_details.dart';
import '../offline_db/installation_form/project_document.dart';
import '../offline_db/installation_form/worksheet.dart';
import '../offline_db/installation_list/installing_job.dart';
import '../offline_db/notification/notification.dart';
import '../offline_db/profile/profile.dart';
import '../offline_db/service_list/service_job.dart';
import '../offline_db/worksheet_document/worksheet_document.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController userLoginController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool _newPasswordValidate = false;
  bool _userLoginValidate = false;
  bool _passwordValidate = false;
  bool _isTwoFactorEnabled = false;
  bool _useLocalAuth = false;
  bool isPasswordLoading = false;
  bool _isTwoFactorLoading = false;
  bool isLogoutLoading = false;
  String newPassword = '';
  String userLogin = '';
  String password = '';
  OdooClient? client;
  String? url;
  late int user_id;
  bool isNetworkAvailable = false;

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
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _initializeOdooClient();
    await _checkConnectivity();
    _fetchTwoFactorValue();
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
        _fetchTwoFactorValue();
      }
    });
  }

  _fetchTwoFactorValue() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isTwoFactorEnabled = prefs.getBool('useLocalAuth') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Security',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 20),
              _buildSettingOption(
                icon: Icons.lock,
                label: 'Change Password',
                onTap: () {
                  if(isNetworkAvailable) {
                    userLoginController.clear();
                    newPasswordController.clear();
                    _changePasswordPopup(context);
                  }else{
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
                                    "You are not able to change password during offline.",
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
              ),
              SizedBox(height: 30),
              _buildTwoFactorAuthOption(),
              SizedBox(height: 40),
              // Align(
              //   alignment: Alignment.centerLeft,
              //   child: Text(
              //     'Account',
              //     style: TextStyle(
              //       fontWeight: FontWeight.bold,
              //       fontSize: 18.0,
              //       color: Colors.black,
              //     ),
              //   ),
              // ),
              // SizedBox(height: 20),
              // _buildSettingOption(
              //   icon: Icons.delete_forever,
              //   label: 'Delete Account',
              //   onTap: () {
              //     _deleteAccountPopup(context);
              //   },
              // ),
              // SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 20),
              _buildSettingOption(
                icon: Icons.privacy_tip,
                label: 'Privacy Policy',
                onTap: () {
                  Navigator.pushNamed(context, '/privacy_policy');
                },
              ),
              SizedBox(height: 20),
              _buildSettingOption(
                icon: Icons.description,
                label: 'Terms of Use',
                onTap: () {
                  Navigator.pushNamed(context, '/terms_of_use');
                },
              ),
              SizedBox(height: 40),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingOption(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
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
          children: [
            Icon(icon, color: Colors.green[800]),
            SizedBox(width: 50),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoFactorAuthOption() {
    return Row(
      children: [
        SizedBox(width: 7),
        Column(
          children: [
            Icon(
              Icons.security,
              color: Colors.green[800],
            ),
          ],
        ),
        SizedBox(width: 16.0),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6.0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SwitchListTile(
              title: Text(
                'Two-Factor Authentication',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
              value: _isTwoFactorEnabled,
              onChanged: (bool value) async {
                if (value) {
                  _showTwoFactorPasswordPopup();
                } else {
                  final prefs = await SharedPreferences.getInstance();
                  setState(() {
                    _isTwoFactorEnabled = value;
                  });
                  await prefs.setBool('useLocalAuth', _isTwoFactorEnabled);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildTwoFactorAuthOption() {
  //   return Container(
  //     padding: EdgeInsets.all(8.0),
  //     decoration: BoxDecoration(
  //       color: Colors.grey[200],
  //       borderRadius: BorderRadius.circular(12.0),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.1),
  //           blurRadius: 6.0,
  //           offset: Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: SwitchListTile(
  //       title: Text(
  //         'Two-Factor Authentication',
  //         style: TextStyle(
  //           fontWeight: FontWeight.bold,
  //           color: Colors.black,
  //           fontSize: 14,
  //         ),
  //       ),
  //       value: _isTwoFactorEnabled,
  //       onChanged: (bool value) async {
  //         if (value) {
  //           _showTwoFactorPasswordPopup();
  //         } else {
  //           final prefs = await SharedPreferences.getInstance();
  //           setState(() {
  //             _isTwoFactorEnabled = value;
  //           });
  //           await prefs.setBool('useLocalAuth', _isTwoFactorEnabled);
  //         }
  //       },
  //       secondary: Icon(
  //         Icons.security,
  //         color: Colors.green[800],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: EdgeInsets.symmetric(vertical: 16.0),
        ),
        onPressed: () {
          if(isNetworkAvailable) {
            _logoutPopup(context);
          }else{
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
                            "You are not able to logout during offline.",
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
          // Navigator.pushNamedAndRemoveUntil(
          //     context, '/login', (route) => false);
        },
        child: Text(
          'Logout',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
      ),
    );
  }

  Future<void> _changePasswordPopup(BuildContext context) async {
    TextEditingController currentPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();
    bool _currentPasswordValidate = false;
    bool _newPasswordValidate = false;
    bool _confirmPasswordValidate = false;
    bool _incorrectCurrentPassword = false;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedPassword = prefs.getString('pass');

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
                          "Change Password",
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
                    height: MediaQuery.of(context).size.height * 0.28,
                    width: MediaQuery.of(context).size.width * 0.95,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.03),
                          Text(
                            "Current Password",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: currentPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              errorText: _currentPasswordValidate
                                  ? 'Please enter your current password'
                                  : _incorrectCurrentPassword
                                      ? 'Incorrect current password'
                                      : null,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10.0),
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.03),
                          Text(
                            "New Password",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: newPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              errorText: _newPasswordValidate
                                  ? 'Please enter a new password'
                                  : null,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10.0),
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.02),
                          Text(
                            "Confirm New Password",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: confirmPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              errorText: _confirmPasswordValidate
                                  ? 'Passwords do not match'
                                  : null,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if(isNetworkAvailable) {
                            isPasswordLoading = true;
                            setState(() {
                              _currentPasswordValidate =
                                  currentPasswordController.text.isEmpty;
                              _newPasswordValidate =
                                  newPasswordController.text.isEmpty;
                              _confirmPasswordValidate =
                                  newPasswordController.text !=
                                      confirmPasswordController.text;
                              _incorrectCurrentPassword =
                                  savedPassword !=
                                      currentPasswordController.text;
                              isPasswordLoading = false;
                            });

                            if (!_currentPasswordValidate &&
                                !_newPasswordValidate &&
                                !_confirmPasswordValidate &&
                                !_incorrectCurrentPassword) {
                              bool success = await changeUserPassword(
                                currentPasswordController.text,
                                newPasswordController.text,
                                confirmPasswordController.text,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? 'Password changed successfully!'
                                      : 'Failed to change password.'),
                                  backgroundColor:
                                  success ? Colors.green : Colors.red,
                                ),
                              );

                              if (success) {
                                isPasswordLoading = false;
                                await prefs.clear();
                                Navigator.of(context)
                                    .pushReplacementNamed('/login');
                              } else {
                                isPasswordLoading = false;
                              }
                            }
                          }else{
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("You can't change password during offline"),
                                backgroundColor: Colors.red,
                              ),
                            );
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
                        child: isPasswordLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                "CONTINUE",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> changeUserPassword(
      String oldPassword, String newPassword, String confirmPassword) async {
    try {
      if (newPassword != confirmPassword) {
        return false;
      }
      final result = await client!.callKw({
        'model': 'res.users',
        'method': 'change_password',
        'args': [oldPassword, newPassword],
        'kwargs': {},
      });
      if (result == true) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('pass', newPassword);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  void _deleteAccountPopup(BuildContext context) async {
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
                          "Delete Account",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
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
                    height: MediaQuery.of(context).size.height * 0.10,
                    width: MediaQuery.of(context).size.width * 0.95,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            "Are you sure you want to delete your account?",
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
                        onPressed: () async {},
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.red),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        child: Text(
                          "CONTINUE",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _logoutPopup(BuildContext context) async {
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
                          "Logout",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
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
                            "Are you sure you want to Logout?",
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
                          isLogoutLoading = true;
                          await BackgroundService.handleLogout();
                          final prefs = await SharedPreferences.getInstance();
                          print("prefsprefs$prefs");
                          await prefs.clear();
                          // var eventsBox = Hive.box('eventsBox');
                          // final documentBox = await Hive.openBox<ProjectDocuments>('projectDocumentsBox');
                          // final installingBox = await Hive.openBox<InstallingJob>('installationListBox');
                          // final notificationBox = await Hive.openBox<NotificationModel>('notificationsBox');
                          // final partnerBox = await Hive.openBox<Partner>('partners');
                          // final worksheetBox = await Hive.openBox<Worksheet>('worksheets');
                          // final worksheetDocumentBox = await Hive.openBox<WorksheetDocument>('worksheetDocumentBox');
                          // final checklistBox = await Hive.openBox('ChecklistBox');
                          // final categoriesBox = await Hive.openBox<List<dynamic>>('categories');
                          // final productDetailsBox = await Hive.openBox<List<dynamic>>('productDetailsBox');
                          // final userBox = Hive.box('user');
                          // final cachedData = userBox.get('userData');
                          // final userDetailsBox = await Hive.openBox<User>('userBox');
                          // final serviceBox = await Hive.openBox<ServiceJobs>('serviceListBox');
                          // await eventsBox.clear();
                          // await documentBox.clear();
                          // await installingBox.clear();
                          // await notificationBox.clear();
                          // await partnerBox.clear();
                          // await worksheetBox.clear();
                          // await cachedData.clear();
                          // await userDetailsBox.clear();
                          // await serviceBox.clear();
                          // await worksheetDocumentBox.clear();
                          // await checklistBox.clear();
                          // await categoriesBox.clear();
                          // await productDetailsBox.clear();

                          isLogoutLoading = false;
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.red),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        child: isLogoutLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                "CONTINUE",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTwoFactorPasswordPopup() async {
    bool? updatedStatus = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Security Control",
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
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              content: Container(
                height: MediaQuery.of(context).size.height * 0.19,
                width: MediaQuery.of(context).size.width * 0.95,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03),
                      Text(
                        "Please enter your password to confirm you own this account",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03),
                      TextField(
                        controller: newPasswordController,
                        obscureText: true, // Hide the password
                        onChanged: (value) {
                          newPassword = value;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          errorText: _newPasswordValidate
                              ? 'Please enter a valid password'
                              : null,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      _isTwoFactorLoading = true;
                      final prefs = await SharedPreferences.getInstance();
                      String storedPassword = prefs.getString('pass') ?? '';

                      if (newPassword.isEmpty) {
                        setState(() {
                          _newPasswordValidate = true;
                          _isTwoFactorLoading = false;
                        });
                        return;
                      } else {
                        setState(() {
                          _newPasswordValidate = false;
                        });
                      }

                      if (newPassword == storedPassword) {
                        // Password matches, proceed with updating useLocalAuth
                        bool newStatus = !_isTwoFactorEnabled;
                        await prefs.setBool('useLocalAuth', newStatus);
                        setState(() {
                          _isTwoFactorEnabled = newStatus;
                          _isTwoFactorLoading = false;
                        });

                        Navigator.of(context)
                            .pop(newStatus); // Return new status
                      } else {
                        // Password doesn't match, show an error
                        setState(() {
                          _newPasswordValidate = true;
                          _isTwoFactorLoading = false;
                        });
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    child: _isTwoFactorLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "CONTINUE",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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

    if (updatedStatus != null) {
      setState(() {
        _isTwoFactorEnabled = updatedStatus;
      });
    }
  }
}

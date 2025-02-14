import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;

import '../background/background_service.dart';
import '../main.dart';
import '../navigation_bar/common_navigation_bar.dart';
import '../offline_to_odoo/calendar.dart';
import '../offline_to_odoo/checklist.dart';
import '../offline_to_odoo/documents.dart';
import '../offline_to_odoo/install_jobs.dart';
import '../offline_to_odoo/notification.dart';
import '../offline_to_odoo/owner_details.dart';
import '../offline_to_odoo/product_and_selfies.dart';
import '../offline_to_odoo/profile.dart';
import '../offline_to_odoo/qr_code.dart';
import '../offline_to_odoo/service_jobs.dart';
import '../offline_to_odoo/signature.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _urlController = TextEditingController(text: "http://10.0.20.118:8017/");
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isUrlValid = false;
  bool _isLoading = false;
  List<DropdownMenuItem<String>> _dropdownItems = [];
  String? _selectedItem;
  String? _errorMessage;
  OdooClient? client;
  String? baseUrl;
  Profile profile = Profile();
  Calendar calendar = Calendar();
  final ChecklistStorageService checklist = ChecklistStorageService();
  NotificationOffline notification = NotificationOffline();
  projectSignatures signatures = projectSignatures();
  documentsList document = documentsList();
  productsList product = productsList();
  InstallJobsBackground installJobs = InstallJobsBackground();
  ServiceJobsBackground serviceJobs = ServiceJobsBackground();
  QrCodeGenerate qrcode = QrCodeGenerate();
  PartnerDetails owner_details = PartnerDetails();
  bool isNetworkAvailable = false;

  @override
  void initState() {
    super.initState();

    _initialize();
    _urlController.addListener(() {
      setState(() {
        _isUrlValid = _urlController.text.isNotEmpty;
        _dropdownItems.clear();
        _selectedItem = null;
        _errorMessage = null;
      });

      if (_isUrlValid) {
        _fetchDatabaseList();
      }
      FlutterNativeSplash.remove();
    });
  }


  Future<void> _initialize() async {
    await _checkConnectivity();
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

    });
  }

  Future<void> _fetchDatabaseList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await client!.callRPC('/web/database/list', 'call', {});
      print(response.body);
      print("responseresponseresponseresponse");
      final dbList = response as List<dynamic>;
      setState(() {
        _dropdownItems = dbList
            .map((db) => DropdownMenuItem<String>(
          child: Text(db),
          value: db,
        ))
            .toList();
        _errorMessage = null;
      });
    } catch (e) {
      print("ghjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj$e");
      setState(() {
        _errorMessage = 'Error fetching database list: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String encryptText(String text) {
    final key = encrypt.Key.fromUtf8("my32lengthsupersecretnooneknows!");
    final iv = encrypt.IV.fromLength(16);
    // final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: "PKCS7"),
    );
    final encrypted = encrypter.encrypt(text, iv: iv);
    // return base64.encode(encrypted.bytes);
    return base64.encode(iv.bytes + encrypted.bytes);
  }


  Future<void> _login() async {
    print("ioiugfcddddddddddddddddddddddddd");
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      String baseUrl = _urlController.text.trim();
      final Uri url = Uri.parse('$baseUrl/rebates/login');
      String encryptedUsername = encryptText(_usernameController.text.trim());
      String encryptedPassword = encryptText(_passwordController.text.trim());

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "username": encryptedUsername,
            "password": encryptedPassword
          }
        }),
      );
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      String status = jsonResponse['result']['status'];
      print(jsonResponse);
      print("Status: $status");
      if (status == "success"){
        await _saveSessionWithoutAnUser(jsonResponse);
        await addShared();
        if (isNetworkAvailable) {
          BackgroundService.initializeService();
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(),
          ),
        );
      }else{
        String errorMessage = jsonResponse['result']['message'];
        setState(() {
                _isLoading = false;
                _errorMessage = errorMessage;
              });
      }
      // else {
      //   try {
      //     print("dddddddddddddddddddddddddddddddddddddddd");
      //     client = OdooClient(_urlController.text.trim());
      //     print(client);
      //     var session = await client!.authenticate(
      //       // _selectedItem!,
      //       // 'beyond-sep3',
      //       'beyond_local',
      //       _usernameController.text.trim(),
      //       _passwordController.text.trim(),
      //     );
      //     print(session);
      //     print("333333333333333333sessionnnnnnnnnnn");
      //     if (session != null) {
      //       await _saveSession(session);
      //       await addShared();
      //       // BackgroundService.initializeService();
      //
      //       if (isNetworkAvailable) {
      //         // await profile.initializeOdooClient();
      //         // await calendar.initializeOdooClient();
      //         // await notification.initializeOdooClient();
      //         // await signatures.initializeOdooClient();
      //         // await document.initializeOdooClient();
      //         // await product.initializeOdooClient();
      //         // await installJobs.initializeOdooClient();
      //         // await serviceJobs.initializeOdooClient();
      //         // await qrcode.initializeOdooClient();
      //         // await owner_details.initializeOdooClient();
      //         // print("successsssssssssssssssssssssisFirstRunisFirstRunsssssssssssss");
      //         // await checklist.initializeOdooClient();
      //         BackgroundService.initializeService();
      //       }
      //       Navigator.pushReplacement(
      //         context,
      //         MaterialPageRoute(
      //           builder: (context) => MainScreen(),
      //         ),
      //       );
      //     } else {
      //       setState(() {
      //         _errorMessage = 'Authentication failed: No session returned.';
      //       });
      //     }
      //   } on OdooException catch (e) {
      //     print("eeeeeeeeeeeeeeeeeeeeeeerrrrrrffffffffffffffff$e");
      //     setState(() {
      //       _errorMessage = 'Please check your Username and Password';
      //     });
      //   } on FormatException catch (e) {
      //     setState(() {
      //       _errorMessage = 'Invalid input format';
      //     });
      //   } catch (e) {
      //     print("eeeeeeeeeeeeeeeeeee$e");
      //     setState(() {
      //       _errorMessage = 'Please check your network connection';
      //     });
      //   } finally {
      //     setState(() {
      //       _isLoading = false;
      //     });
      //   }
      // }
    }
  }

  Future<void> addShared() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('selectedDatabase', 'beyond_local');
    // await prefs.setString('selectedDatabase', _selectedItem!);
    await prefs.setString('url', _urlController.text.trim());
  }

  Future<void> _saveSessionWithoutAnUser(jsonResponse) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('userName', jsonResponse['result']['name']?? '');
    // await prefs.setString(
    //     'userLogin', session.userLogin?.toString() ?? '');
    await prefs.setInt('teamId', jsonResponse['result']['team_id'] ?? 0);
    await prefs.setString('sessionId', jsonResponse['result']['access_token']);
    await prefs.setString('pass', _passwordController.text.trim());

    // await prefs.setString(
    //     'serverVersion', session.serverVersion ?? '');
    // await prefs.setString('userLang', session.userLang ?? '');
    // await prefs.setInt(
    //     'partnerId', session.partnerId ?? 0);
    // await prefs.setBool('isSystem', session.isSystem ?? false);
    // await prefs.setString('userTimezone', session.userTz);
  }


  Future<void> _saveSession(OdooSession session) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('userName', session.userName ?? '');
    await prefs.setString(
        'userLogin', session.userLogin?.toString() ?? '');
    await prefs.setInt('userId', session.userId ?? 0);
    await prefs.setString('sessionId', session.id);
    await prefs.setString('pass', _passwordController.text.trim());

    await prefs.setString(
        'serverVersion', session.serverVersion ?? '');
    await prefs.setString('userLang', session.userLang ?? '');
    await prefs.setInt(
        'partnerId', session.partnerId ?? 0);
    await prefs.setBool('isSystem', session.isSystem ?? false);
    await prefs.setString('userTimezone', session.userTz);
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var screenHeight = screenSize.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/login_background.png',
              fit: BoxFit.cover,
            ),
          ), SingleChildScrollView(
            child: Container(
              height: screenHeight,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.9),
                              blurRadius: 10.0,
                              spreadRadius: 5.0,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo.png',
                          height: 200.0,
                          width: 200.0,
                        ),
                      ),
                    ),
                    SizedBox(height: 30.0),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _urlController,
                            validator: (url) {
                              if (url == null || url.isEmpty) {
                                return 'Enter your base URL';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Base URL',
                              labelStyle: TextStyle(
                                color: Colors.white,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              prefixIcon: Icon(Icons.public, color: Colors.white),
                              contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                            ),
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 16.0),
                          _isLoading
                              ? Center(child: CircularProgressIndicator())
                              : DropdownButtonFormField<String>(
                            hint: Text(
                              'Select a database',
                              style: TextStyle(color: Colors.white),
                            ),
                            value: _selectedItem,
                            items: _dropdownItems,
                            onChanged: _isUrlValid
                                ? (item) {
                              setState(() {
                                _selectedItem = item;
                              });
                            }
                                : null,
                            decoration: InputDecoration(
                              labelStyle: TextStyle(
                                color: Colors.white,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              prefixIcon: Icon(Icons.storage, color: Colors.white),
                              contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                            ),
                            iconEnabledColor: Colors.white,
                            dropdownColor: Colors.black,
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 16.0),
                          TextFormField(
                            controller: _usernameController,
                            validator: (username) {
                              if (username == null || username.isEmpty) {
                                return 'Enter your username';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Username',
                              labelStyle: TextStyle(
                                color: Colors.white,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              prefixIcon: Icon(Icons.person, color: Colors.white),
                              contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                            ),
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 16.0),
                          TextFormField(
                            controller: _passwordController,
                            validator: (pass) {
                              if (pass == null || pass.isEmpty) {
                                return 'Enter your password';
                              }
                              return null;
                            },
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(
                                color: Colors.white,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              prefixIcon: Icon(Icons.lock, color: Colors.white),
                              contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                            ),
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 16.0),
                          if (_errorMessage != null) ...[
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16.0),
                          ],
                          Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _login,
                                  child: Text(
                                    'Sign-in',
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: EdgeInsets.symmetric(vertical: 16.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                  ),
                                ),
                              ),
                              if (_isLoading) ...[
                                Positioned(
                                  top: 2,
                                  left: 3,
                                  right: 3,
                                  child: LinearProgressIndicator(
                                    backgroundColor: Colors.white.withOpacity(0.5),
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.green),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'dart:convert';
//
// import 'package:flutter/material.dart';
// import 'package:odoo_rpc/odoo_rpc.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   _LoginScreenState createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _urlController =
//       TextEditingController(text: "http://10.0.20.89:8017/");
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   bool _isUrlValid = false;
//   bool _isLoading = false;
//   List<DropdownMenuItem<String>> _dropdownItems = [];
//   String? _selectedItem;
//   String? _errorMessage;
//   OdooClient? client;
//   String? baseUrl;
//
//   @override
//   void initState() {
//     super.initState();
//     _urlController.addListener(() {
//       setState(() {
//         _isUrlValid = _urlController.text.isNotEmpty;
//         _dropdownItems.clear();
//         _selectedItem = null;
//         _errorMessage = null;
//       });
//
//       if (_isUrlValid) {
//         _fetchDatabaseList();
//       }
//     });
//   }
//
//   Future<void> _fetchDatabaseList() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       baseUrl = _urlController.text.trim();
//       // client = OdooClient(baseUrl);
//
//       final response = await client!.callRPC('/web/database/list', 'call', {});
//       final dbList = response as List<dynamic>;
//       setState(() {
//         _dropdownItems = dbList
//             .map((db) => DropdownMenuItem<String>(
//                   child: Text(db),
//                   value: db,
//                 ))
//             .toList();
//         _errorMessage = null;
//       });
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error fetching database list: $e';
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _login() async {
//     if (_formKey.currentState?.validate() ?? false) {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = null;
//       });
//
//       try {
//         client = OdooClient(_urlController.text.trim());
//         var session = await client!.authenticate(
//           'flutte_mobile_app', // selected database
//           _usernameController.text.trim(),
//           _passwordController.text.trim(),
//         );
//         if (session != null) {
//
//
//             if (session.companyId != null && session.allowedCompanies != null) {
//               await _saveSession(session);
//               await addShared();
//           }
//
//           Navigator.pushReplacementNamed(context, '/installing_list_view');
//           // Navigator.pushReplacementNamed(context, '/dashboard');
//         } else {
//           setState(() {
//             _errorMessage = 'Authentication failed: No session returned.';
//           });
//         }
//       } on OdooException catch (e) {
//         setState(() {
//           _errorMessage = 'Please check your Username and Password';
//         });
//       } on FormatException catch (e) {
//         setState(() {
//           _errorMessage = 'Invalid input format';
//         });
//       } catch (e) {
//         setState(() {
//           _errorMessage = 'An unexpected error occurred';
//         });
//       } finally {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   Future<void> addShared() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('isLoggedIn', true);
//     await prefs.setString('selectedDatabase', 'flutte_mobile_app');
//     await prefs.setString('url', _urlController.text.trim());
//   }
//
//   Future<void> _saveSession(OdooSession session) async {
//     final prefs = await SharedPreferences.getInstance();
//
//     await prefs.setString('userName', session.userName ?? '');
//     await prefs.setString('userLogin', session.userLogin?.toString() ?? '');
//     await prefs.setInt('userId', session.userId ?? 0);
//     await prefs.setString('sessionId', session.id);
//     await prefs.setString('pass', _passwordController.text.trim());
//     await prefs.setString('serverVersion', session.serverVersion ?? '');
//     await prefs.setString('userLang', session.userLang ?? '');
//     await prefs.setInt('partnerId', session.partnerId ?? 0);
//     await prefs.setBool('isSystem', session.isSystem ?? false);
//     await prefs.setInt('companyId', session.companyId);
//
//     try {
//       if (session.allowedCompanies.isNotEmpty) {
//         List<String> jsonStringList = session.allowedCompanies.map((company) => jsonEncode(company.toJson())).toList();
//         await prefs.setStringList('allowedCompanies', jsonStringList);
//       } else {
//         await prefs.remove('allowedCompanies');
//       }
//     } catch (e) {
//       print('Error encoding allowedCompanies: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var screenSize = MediaQuery.of(context).size;
//     var screenHeight = screenSize.height;
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Container(
//           height: screenHeight,
//           padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
//           child: Center(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Center(
//                   child: Image.asset(
//                     'assets/logo.png',
//                     height: 120.0,
//                     width: 120.0,
//                   ),
//                 ),
//                 SizedBox(height: 15.0),
//                 Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       TextFormField(
//                         controller: _usernameController,
//                         validator: (username) {
//                           if (username == null || username.isEmpty) {
//                             return 'Enter your username';
//                           }
//                           return null;
//                         },
//                         decoration: InputDecoration(
//                           labelText: 'Username',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10.0),
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderSide: BorderSide(color: Colors.green),
//                             borderRadius: BorderRadius.circular(10.0),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderSide: BorderSide(color: Colors.green),
//                             borderRadius: BorderRadius.circular(10.0),
//                           ),
//                           prefixIcon: Icon(Icons.person, color: Colors.green),
//                           contentPadding: EdgeInsets.symmetric(vertical: 16.0),
//                         ),
//                       ),
//                       SizedBox(height: 16.0),
//                       TextFormField(
//                         controller: _passwordController,
//                         validator: (pass) {
//                           if (pass == null || pass.isEmpty) {
//                             return 'Enter your password';
//                           }
//                           return null;
//                         },
//                         obscureText: true,
//                         decoration: InputDecoration(
//                           labelText: 'Password',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10.0),
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderSide: BorderSide(color: Colors.green),
//                             borderRadius: BorderRadius.circular(10.0),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderSide: BorderSide(color: Colors.green),
//                             borderRadius: BorderRadius.circular(10.0),
//                           ),
//                           prefixIcon: Icon(Icons.lock, color: Colors.green),
//                           contentPadding: EdgeInsets.symmetric(vertical: 16.0),
//                         ),
//                       ),
//                       SizedBox(height: 16.0),
//                       if (_errorMessage != null) ...[
//                         Text(
//                           _errorMessage!,
//                           style: TextStyle(color: Colors.red),
//                         ),
//                         SizedBox(height: 16.0),
//                       ],
//                       Stack(
//                         alignment: Alignment.topCenter,
//                         children: [
//                           // Elevated button with text
//                           SizedBox(
//                             width: double.infinity,
//                             child: ElevatedButton(
//                               onPressed: _login,
//                               child: Text(
//                                 'Sign-in',
//                                 style: TextStyle(
//                                   fontSize: 18.0,
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.green,
//                                 padding: EdgeInsets.symmetric(vertical: 16.0),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(10.0),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           if (_isLoading) ...[
//                             Positioned(
//                               top: 2,
//                               left: 3,
//                               right: 3,
//                               child: LinearProgressIndicator(
//                                 backgroundColor: Colors.white.withOpacity(0.5),
//                                 // Adjust opacity if needed
//                                 valueColor:
//                                     AlwaysStoppedAnimation<Color>(Colors.green),
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

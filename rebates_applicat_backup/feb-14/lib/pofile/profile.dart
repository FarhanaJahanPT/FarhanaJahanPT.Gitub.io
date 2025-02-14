import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../offline_db/profile/edit_user.dart';
import '../offline_db/profile/profile.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  String name = "";
  String saaNumber = "";
  String url = "";
  bool isLoadingImage = false;
  int installingJobs = 15;
  int completedJobs = 15;
  int currentPoints = 120;
  TextEditingController userNameController = TextEditingController();
  TextEditingController saaNumberController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController licensedNumController = TextEditingController();
  TextEditingController effectiveDateController = TextEditingController();
  TextEditingController expiryDateController = TextEditingController();
  TextEditingController statusController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  OdooClient? client;
  MemoryImage? profilePicUrl;
  MemoryImage? documentPicUrl;
  Color? statusTextColor;
  String? newUserName;
  String? newEmail;
  String? newPhone;
  String? newAddress;
  String? _errorMessage;
  XFile? pickedFile;
  String fileName = '';
  String filePath = '';
  bool checkfile = false;
  int? userId;
  bool isLoading = false;
  bool isFailedView = false;
  bool isProfileLoading = false;
  bool isNetworkAvailable = false;
  String? imageBase64;
  List<Map<String, dynamic>> userLicenseDetails = [];

  @override
  void initState() {
    super.initState();
    // _initializeOdooClient();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkConnectivity();
    getUserProfile();
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
        await getUserProfile();
      }
    });
  }

  Future<UserModel?> loadEditedProfileFromHive() async {
    var box = await Hive.openBox<UserModel>('userProfileBox');
    return box.get('user');
  }

  Future<void> _initializeOdooClient() async {
    final prefs = await SharedPreferences.getInstance();
    userId =  prefs.getInt('userId') ?? 0;
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

  Future<void> getUserProfile() async {
    isLoading = true;
    if (!isNetworkAvailable) {
      print("dddddddddddddddddddjjjjjjjjjjjjjjjjjjjjjjjjjjjjjdd");
      User? cachedUser = await loadProfileFromHive();
      if (cachedUser != null) {

        setState(() {
          userNameController.text = cachedUser.name;
          emailController.text = cachedUser.email ?? "None";
          phoneController.text = cachedUser.phone ?? "None";
          userLicenseDetails = cachedUser.userLicenseDetails ?? [];
          // expiryDateController.text = cachedUser.signupExpiration ?? "None";
          addressController.text = cachedUser.contactAddressComplete ?? "Inactive";
          statusController.text = cachedUser.state == "active" ? "Active" : "Inactive";
          statusTextColor = cachedUser.state == "active" ? Colors.green : Colors.red;
          profilePicUrl = cachedUser.imageBase64.isNotEmpty
              ? MemoryImage(base64Decode(cachedUser.imageBase64))
              : null;
          imageBase64 = cachedUser.imageBase64;
          isLoading = false;
        });

        return;
      }
    } else {
      print("77777777777777777777777");
      final prefs = await SharedPreferences.getInstance();


      final teamId = prefs.getInt('teamId') ?? 0;
      final baseUrl = prefs.getString('url') ?? 0;
      try {
        final Uri url = Uri.parse('$baseUrl/rebates/team_members');
        final userDetails = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "teamId": teamId,
            }
          }),
        );
        print("ddddddddddddddddddddinsktallingccccCalendarDetailsinsktallingCalendarDetailsinsktallingCalendarDetails");
        final Map<String, dynamic> jsonUserDetailsResponse = json.decode(userDetails.body);
        print("3333333333333333333333$jsonUserDetailsResponse");
        // print("userDetailsuserDetailsuserDetails${jsonUserDetailsResponse['result']['team_member_data'][0]['name']}");
        if (jsonUserDetailsResponse['result']['status'] == 'success' && jsonUserDetailsResponse['result']['team_member_data'].isNotEmpty) {
          //   final userDetails = await client?.callKw({
          //   'model': 'team.member',
          //   'method': 'search_read',
          //   'args': [
          //     [
          //       ['id', '=', 1]
          //     ]
          //   ],
          //   'kwargs': {
          //     'fields': [
          //       'name',
          //       'mobile',
          //       'contract_license_ids',
          //       'email',
          //       'active',
          //       'address',
          //       'image_1920'
          //     ],
          //   },
          // });
          print(
              jsonUserDetailsResponse['result']['team_member_data'][0]['active']);
          print("userDetailsuserDetails");
          isLoading = false;
          setState(() {
            userNameController.text =
                jsonUserDetailsResponse['result']['team_member_data'][0]['name'] ??
                    "";
          });
          // if (userDetails != null && userDetails.isNotEmpty) {
          final user = jsonUserDetailsResponse['result']['team_member_data'][0];
          final imageBase64 = user['image_1920'] is String
              ? user['image_1920']
              : null;
          if (imageBase64 != null && imageBase64 != 'false') {
            final imageData = base64Decode(imageBase64);
            setState(() {
              profilePicUrl = MemoryImage(Uint8List.fromList(imageData));
            });
          }
          // final response = await client?.callKw({
          //   'model': 'electrical.contract.license',
          //   'method': 'search_read',
          //   'args': [
          //     [
          //       ['id', 'in', jsonUserDetailsResponse['result']['team_member_data'][0]['contract_license_ids']]
          //     ]
          //   ],
          //   'kwargs': {
          //     'fields': [
          //       'expiry_date',
          //       'number',
          //       'team_id',
          //       'type_id',
          //       'document'
          //     ],
          //   },
          // });
          // if (response != null) {
          print("44444444444444444ddddddddddddddddddsssssssssssssssssss");
          if (jsonUserDetailsResponse['result']['team_member_data'][0]['contract_license_ids'].isNotEmpty){
            final Uri url = Uri.parse('$baseUrl/rebates/contract_license');
            final response = await http.post(
              url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "jsonrpc": "2.0",
                "method": "call",
                "params": {
                  "id": jsonUserDetailsResponse['result']['team_member_data'][0]['contract_license_ids'],
                }
              }),
            );
            print(
                "ddddddddddddddddddddinsktallincccccccccccccccgccccCalendarDetailsinsktallingCalendarDetailsinsktallingCalendarDetails");
            final Map<String, dynamic> jsonLicenceResponse = json.decode(
                response.body);
            print(jsonLicenceResponse);
            // print("3333333333333333333333$jsonUserDetailsResponse");
            // print("userDetailsuserDetailsuserDetails${jsonUserDetailsResponse['result']['team_member_data'][0]['name']}");
            if (jsonLicenceResponse['result']['status'] == 'success' &&
                jsonLicenceResponse['result']['contract_license'].isNotEmpty) {
              print("44fddddddddddddddxxxxxxxxxxxxxx");
              setState(() {
                userLicenseDetails = List<Map<String, dynamic>>.from(
                    jsonLicenceResponse['result']['contract_license']);
              });
            }
          }
          print("iiiiiiiiiiiiiiiidddddddddddddddddd$userLicenseDetails");
          // final userToSave = User(
          //   name: user['name'] ?? "None",
          //   phone: (user['mobile'] ?? false).toString(), // Convert to String
          //   email: user['email'] ?? "None",
          //   state: user['active'] ?? "Inactive",
          //   userLicenseDetails: userLicenseDetails ?? [],
          //   contactAddressComplete: user['address'] ?? "None",
          //   imageBase64: imageBase64 ?? '',
          // );
          //
          // print(userToSave);
          print("userToSaveuserToSave");
          // await saveUserToHive(userToSave);
          setState(() {
            if (jsonUserDetailsResponse['result']['team_member_data'][0]['email'] is String &&
                jsonUserDetailsResponse['result']['team_member_data'][0]['email'].isNotEmpty) {
              emailController.text = jsonUserDetailsResponse['result']['team_member_data'][0]['email'];
            } else {
              emailController.text = "None";
            }
            print("8888888888888888888888d");
            if (jsonUserDetailsResponse['result']['team_member_data'][0]['mobile'] is String &&
                jsonUserDetailsResponse['result']['team_member_data'][0]['mobile'].isNotEmpty) {
              print("ffffffffffffffffffffffsssssssssssss");
              phoneController.text = jsonUserDetailsResponse['result']['team_member_data'][0]['mobile'];
            } else {
              phoneController.text = "None";
            }
            // if (userDetails[0]['x_studio_act_electrical_licence_number']
            //         is String &&
            //     userDetails[0]['x_studio_act_electrical_licence_number']
            //         .isNotEmpty) {
            //   licensedNumController.text =
            //       userDetails[0]['x_studio_act_electrical_licence_number'];
            // } else {
            //   licensedNumController.text = "None";
            // }

            // if (userDetails[0]['signup_expiration'] is String &&
            //     userDetails[0]['signup_expiration'].isNotEmpty) {
            //   expiryDateController.text = userDetails[0]['signup_expiration'];
            // } else {
            //   expiryDateController.text = "None";
            // }
            print(jsonUserDetailsResponse['result']['team_member_data'][0]['active']);
            print("userDetails[0]['activecccc']ssssssssssssssssssss");
            // if (userDetails[0]['active'] is String &&
            //     userDetails[0]['active'].isNotEmpty) {
            //   print("ddddddddddddddddddddssssssssssssssssss");
            //   statusController.text =
            //   userDetails[0]['active'] == "active" ? "Active" : "Inactive";
            //   statusTextColor =
            //   userDetails[0]['active'] == "active" ? Colors.green : Colors.red;
            // } else {
            //   statusController.text = "Inactive";
            //   statusTextColor = Colors.red;
            // }
            if (jsonUserDetailsResponse['result']['team_member_data'][0]['active'] == true) {
              statusController.text = "Active";
              statusTextColor = Colors.green;
            } else {
              statusController.text = "Inactive";
              statusTextColor = Colors.red;
            }

            if (jsonUserDetailsResponse['result']['team_member_data'][0]['address'] is String &&
                jsonUserDetailsResponse['result']['team_member_data'][0]['address'].isNotEmpty) {
              addressController.text = jsonUserDetailsResponse['result']['team_member_data'][0]['address'];
            } else {
              addressController.text = "None";
            }
          });
        }
        // setState(() {
        //   if (userDetails[0]['email'] is String &&
        //       userDetails[0]['email'].isNotEmpty) {
        //     emailController.text = userDetails[0]['email'];
        //   } else {
        //     emailController.text = "None";
        //   }
        //   print("8888888888888888888888d");
        //   if (userDetails[0]['mobile'] is String &&
        //       userDetails[0]['mobile'].isNotEmpty) {
        //     print("ffffffffffffffffffffffsssssssssssss");
        //     phoneController.text = userDetails[0]['mobile'];
        //   } else {
        //     phoneController.text = "None";
        //   }
        //   // if (userDetails[0]['x_studio_act_electrical_licence_number']
        //   //         is String &&
        //   //     userDetails[0]['x_studio_act_electrical_licence_number']
        //   //         .isNotEmpty) {
        //   //   licensedNumController.text =
        //   //       userDetails[0]['x_studio_act_electrical_licence_number'];
        //   // } else {
        //   //   licensedNumController.text = "None";
        //   // }
        //
        //   // if (userDetails[0]['signup_expiration'] is String &&
        //   //     userDetails[0]['signup_expiration'].isNotEmpty) {
        //   //   expiryDateController.text = userDetails[0]['signup_expiration'];
        //   // } else {
        //   //   expiryDateController.text = "None";
        //   // }
        //
        //   if (userDetails[0]['active'] is String &&
        //       userDetails[0]['active'].isNotEmpty) {
        //     statusController.text =
        //         userDetails[0]['active'] == "active" ? "Active" : "Inactive";
        //     statusTextColor =
        //         userDetails[0]['active'] == "active" ? Colors.green : Colors.red;
        //   } else {
        //     statusController.text = "Inactive";
        //     statusTextColor = Colors.red;
        //   }
        //
        //   if (userDetails[0]['address'] is String &&
        //       userDetails[0]['address'].isNotEmpty) {
        //     addressController.text = userDetails[0]['address'];
        //   } else {
        //     addressController.text = "None";
        //   }
        // });
      } catch (e) {
        print("44444444444444444444444edddddddddddd$e");
        User? cachedUser = await loadProfileFromHive();
        if (cachedUser != null) {

          setState(() {
            userNameController.text = cachedUser.name;
            emailController.text = cachedUser.email ?? "None";
            phoneController.text = cachedUser.phone ?? "None";
            userLicenseDetails = cachedUser.userLicenseDetails ?? [];
            // expiryDateController.text = cachedUser.signupExpiration ?? "None";
            addressController.text = cachedUser.contactAddressComplete ?? "Inactive";
            statusController.text = cachedUser.state == "active" ? "Active" : "Inactive";
            statusTextColor = cachedUser.state == "active" ? Colors.green : Colors.red;
            profilePicUrl = cachedUser.imageBase64.isNotEmpty
                ? MemoryImage(base64Decode(cachedUser.imageBase64))
                : null;
            imageBase64 = cachedUser.imageBase64;
            isLoading = false;
          });

          return;
        }
        // isLoading = false;
        // isFailedView = true;
        print('Error: $e');
      }
    }
  }

  Future<void> saveUserToHive(User user) async {
    final userBox = await Hive.openBox<User>('userBox');
    await userBox.clear();
    await userBox.put('currentUser', user);
  }

  // Future<void> loadProfileFromHive() async {
  //   try {
  //     final userBox = await Hive.openBox<User>('userBox');
  //     final userModel = userBox.get('currentUser');
  //
  //     print(userBox.values);
  //     print("Loading userModel from Hive...");
  //
  //     if (userModel != null) {
  //       setState(() async {
  //         userNameController.text = userModel.name;
  //         emailController.text = userModel.email;
  //         phoneController.text = userModel.phone;
  //         licensedNumController.text = userModel.licensedNumber;
  //         expiryDateController.text = userModel.signupExpiration;
  //         statusController.text =
  //             userModel.state == "active" ? "Active" : "Inactive";
  //         statusTextColor =
  //             userModel.state == "active" ? Colors.green : Colors.red;
  //         addressController.text = userModel.contactAddressComplete;
  //         if (userModel.imageBase64.isNotEmpty &&
  //             userModel.imageBase64 != 'false') {
  //           final imageData = base64Decode(userModel.imageBase64);
  //           profilePicUrl = MemoryImage(Uint8List.fromList(imageData));
  //         } else {
  //           profilePicUrl = null;
  //         }
  //         isLoading = false;
  //       });
  //     } else {
  //       print("User profile not found in Hive.");
  //       isLoading = false;
  //     }
  //   } catch (e) {
  //     print("Error loading profile from Hive: $e");
  //     isLoading = false;
  //   }
  // }
  Future<User?> loadProfileFromHive() async {
    try {
      final userBox = await Hive.openBox<User>('userBox');
      final userModel = userBox.get('currentUser');

      if (userModel != null) {
        print('status  : ${userModel.state}');
        return userModel;
      } else {
        print("User profile not found in Hive.");
        return null;
      }
    } catch (e) {
      print("Error loading profile from Hive: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;

    return WillPopScope(
      onWillPop: () async {
        args['getProfile']?.call();
        return true;
      },
      child: Scaffold(
        body: isLoading
            ? _buildShimmerLoading()
            : _buildProfileContent(),
      ),
    );
  }

  Widget _buildProfileContent() {
    print(phoneController.text);
    print("phoneController.texphoneController.tex");
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () async {
                  if (!isNetworkAvailable) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Please check your network'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    await _pickImage(userId!);
                  }
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: profilePicUrl != null
                          ? profilePicUrl!
                          : AssetImage('assets/profile.jpg') as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              if (!isFailedView && !isLoading)
                Positioned(
                  bottom: -20,
                  right: 10,
                  child: CircleAvatar(
                    backgroundColor: Colors.red[600],
                    radius: 25,
                    child: IconButton(
                      icon: Icon(Icons.edit, color: Colors.white, size: 19),
                      onPressed: () {
                        _editProfilePopup(context);
                      },
                    ),
                  ),
                ),
              Positioned(
                bottom: 16,
                left: 16,
                child: Text(
                  userNameController.text,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8.0,
                        color: Colors.black.withOpacity(0.8),
                        offset: Offset(2, 2),
                      ),
                      Shadow(
                        blurRadius: 16.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: Offset(4, 4),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildProfileInfoRow(
                    Icons.email, "Email", emailController.text),
                SizedBox(height: 15),
                _buildProfileInfoRow(
                    Icons.phone, "Phone", phoneController.text),
                // SizedBox(height: 15),
                // _buildProfileInfoRow(
                //     Icons.badge, "License Number", licensedNumController.text),
                // SizedBox(height: 15),
                // _buildProfileInfoRow(
                //     Icons.date_range, "Expiry Date", expiryDateController.text),
                SizedBox(height: 15),
                _buildProfileInfoRow(
                    Icons.check_circle, "Status", statusController.text,
                    textColor: statusTextColor),
                SizedBox(height: 15),
                _buildProfileInfoRow(
                    Icons.location_on, "Address", addressController.text),
                SizedBox(height: 15),
                if (userLicenseDetails.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      "Licence & Accreditations",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  ...userLicenseDetails.map((license) {
                    final imageBase64 = license['document'] is String ? license['document'] : null;
                    if (imageBase64 != null && imageBase64 != 'false') {
                      final imageData = base64Decode(imageBase64);
                      setState(() {
                        documentPicUrl = MemoryImage(Uint8List.fromList(imageData));
                      });
                    }
                    return Card(
                      color: Colors.green[100],
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileInfoRow(
                              Icons.badge, "License Type",
                              license['type_id'] != null ? license['type_id'][1] : "N/A",
                            ),
                            SizedBox(height: 10),
                            _buildProfileInfoRow(
                              Icons.confirmation_number, "License Number",
                              license['number'] ?? "N/A",
                            ),
                            SizedBox(height: 10),
                            _buildProfileInfoRow(
                              Icons.date_range, "Expiry Date",
                              license['expiry_date'] ?? "N/A",
                            ),
                            SizedBox(height: 10),
                            _buildProfileDocumentInfoRow(
                              Icons.file_present,
                              "Document",
                              documentPicUrl,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],

                // _buildProfileInfoRow(
                //     Icons.badge, "License Number", licensedNumController.text),
                // SizedBox(height: 15),
                // _buildProfileInfoRow(
                //     Icons.date_range, "Expiry Date", expiryDateController.text),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDocumentInfoRow(IconData icon, String label, dynamic document) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green),
              SizedBox(width: 12.0),
              Text(
                "$label:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
            ],
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                print(document);
                if ((document is String && document.isNotEmpty) || (document is MemoryImage)) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocumentViewerScreen(document: document), // Use named parameter
                    ),
                  );
                } else {
                  print("No document available to view");
                }
              },
              child: Text(
                "View Document",
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: (document is String && document.isNotEmpty) || (document is MemoryImage)
                      ? Colors.blue
                      : Colors.grey,
                  decoration: (document is String && document.isNotEmpty) || (document is MemoryImage)
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
            SizedBox(height: 16.0),
            Container(
              width: 150,
              height: 24,
              color: Colors.grey[300],
            ),
            SizedBox(height: 8.0),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
            ),
            SizedBox(height: 24.0),
            Divider(thickness: 1.0),
            _buildShimmerRow(),
            _buildShimmerRow(),
            _buildShimmerRow(),
            _buildShimmerRow(),
            _buildShimmerRow(),
            _buildShimmerRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerRow() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            color: Colors.grey[300],
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: Container(
              height: 16,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value,
      {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green),
              SizedBox(width: 12.0),
              Text(
                "$label:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
            ],
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: textColor ?? Colors.black.withOpacity(0.5),
              ),
              overflow: TextOverflow.visible,
              maxLines: null,
            ),
          ),
        ],
      ),
    );
  }

  void _editProfilePopup(BuildContext context) async {
    TextEditingController tempUserNameController =
        TextEditingController(text: userNameController.text);
    TextEditingController tempEmailController =
        TextEditingController(text: emailController.text);
    TextEditingController tempPhoneController =
        TextEditingController(text: phoneController.text);
    TextEditingController tempAddressController =
        TextEditingController(text: addressController.text);
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
                          "Edit Profile",
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
                    height: MediaQuery.of(context).size.height * 0.50,
                    width: MediaQuery.of(context).size.width * 0.95,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_errorMessage != null)
                            Text(
                              _errorMessage ?? '',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.02),
                          Text(
                            "User Name",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: tempUserNameController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              // errorText: _userLoginValidate
                              //     ? 'Please enter User Login'
                              //     : null,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10.0),
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.03),
                          Text(
                            "Email",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: tempEmailController,
                            onChanged: (valueTime) {
                              newEmail = valueTime;
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10.0),
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.03),
                          Text(
                            "Phone",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: tempPhoneController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10.0),
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.03),
                          Text(
                            "Address",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.01),
                          TextField(
                            controller: tempAddressController,
                            maxLines: null,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 10.0),
                            ),
                            onChanged: (value) {
                              newAddress = value;
                            },
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
                          isProfileLoading = true;
                          Map<String, dynamic> updatedDetails = {
                            "name": tempUserNameController.text,
                            "email": tempEmailController.text,
                            "mobile": tempPhoneController.text,
                            "address":
                                newAddress ?? tempAddressController.text,
                          };
                          if (!isNetworkAvailable) {
                            await saveProfileToHive(updatedDetails);
                            Navigator.of(context).pop();
                            setState(() {
                              isProfileLoading = false;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Network unavailable. Your changes will be saved when you are back online.',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            });
                          } else {
                            bool success =
                                await editProfileDetails(updatedDetails);

                            if (success) {
                              setState(() {
                                isProfileLoading = false;
                                _errorMessage = null;
                              });
                              Navigator.of(context).pop();
                              userNameController.text =
                                  tempUserNameController.text;
                              emailController.text = tempEmailController.text;
                              phoneController.text = tempPhoneController.text;
                              addressController.text =
                                  tempAddressController.text;
                              getUserProfile();
                            } else {
                              setState(() {
                                _errorMessage = "Failed to update profile.";
                                isProfileLoading = false;
                              });
                            }
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
                        child: isProfileLoading
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
  Future<void> saveProfileToHive(Map<String, dynamic> updatedDetails) async {
    print("Saving profile to Hive...");
    Box<UserModel>? box;
    try {
      box = await Hive.openBox<UserModel>('userProfileBox');
      UserModel user = UserModel(
        name: updatedDetails["name"],
        email: updatedDetails["email"],
        phone: updatedDetails["mobile"],
        contactAddress: updatedDetails["contact_address_complete"],
      );
      await box.put('user', user);
      print("Saved user: ${box.get('user')}");
    } catch (e) {
      print("Error occurred while saving profile to Hive: $e");
    } finally {
      if (box != null && box.isOpen) {
        await box.close();
        print("Box closed properly.");
      }
    }
  }


  Future<bool> editProfileDetails(Map<String, dynamic> updatedDetails) async {
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
      // final response = await client?.callKw({
      //   'model': 'res.users',
      //   'method': 'write',
      //   'args': [
      //     [userId],
      //     updatedDetails,
      //   ],
      //   'kwargs': {},
      // });
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

  Future<void> _pickImage(int id) async {
    isLoadingImage = true;
    XFile? file = await uploadFile(context);

    if (file != null) {
      String filePath = file.path;
      String fileName = file.name;

      setState(() async {
        pickedFile = file;
        this.fileName = fileName;
        this.filePath = filePath;
        checkfile = true;
        Map<String, dynamic> updatedDetails = {
          "id": id,
        };

        await updateEmployeeImage(
          updatedDetails,
          checkfile,
          fileName,
          filePath,
        );
      });
    }
  }

  Future<String?> convertImageToBase64(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      return base64Encode(bytes);
    } on PlatformException catch (e) {
      return null;
    }
  }

  Future<void> updateEmployeeImage(Map<String, dynamic> updatedDetails,
      bool checkFile, String fileName, String filePath) async {
    try {
      String? base64Image = await convertImageToBase64(filePath);

      if (base64Image != null) {
        updatedDetails["image_1920"] = base64Image;
      }
      final response = await client?.callKw({
        'model': 'team.member',
        'method': 'write',
        'args': [
          [1],
          updatedDetails,
        ],
        'kwargs': {},
      });
      // final response = await client?.callKw({
      //   'model': 'res.users',
      //   'method': 'write',
      //   'args': [
      //     [userId],
      //     updatedDetails,
      //   ],
      //   'kwargs': {},
      // });
      if (response == true) {
        setState(() {
          isLoadingImage = false;
        });
        getUserProfile();
      } else {
        _errorMessage = "Something went wrong. Please try again later.";
      }
    } catch (e) {
      _errorMessage = "Something went wrong. Please try again later.";
    }
  }

  Future<XFile?> uploadFile(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return pickedFile;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
          'No image selected',
          style: TextStyle(color: Colors.white),
        )),
      );
      return null;
    }
  }
}


class DocumentViewerScreen extends StatelessWidget {
  final dynamic document;

  DocumentViewerScreen({required this.document});

  @override
  Widget build(BuildContext context) {
    Uint8List? imageData;

    if (document is String) {
      try {
        imageData = base64Decode(document);
      } catch (e) {
        print("Error decoding base64: $e");
      }
    } else if (document is MemoryImage) {
      imageData = document.bytes;
    }

    return Scaffold(
      appBar: AppBar(title: Text("View Document",
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
        child: imageData != null
            ? Image.memory(imageData)
            : Text("Invalid document"),
      ),
    );
  }
}
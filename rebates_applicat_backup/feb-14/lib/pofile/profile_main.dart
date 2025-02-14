import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:hive/hive.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;

class ProfileMainPage extends StatefulWidget {
  @override
  State<ProfileMainPage> createState() => _ProfileMainPageState();
}

class _ProfileMainPageState extends State<ProfileMainPage>
    with SingleTickerProviderStateMixin {
  String profilePicUrl = "";
  String name = "";
  String userMail = "";
  String url = "";
  String userName = "";
  bool isLoadingImage = false;
  int installingJobs = 0;
  int completedJobs = 0;
  int currentPoints = 120;
  final NotchBottomBarController _controller = NotchBottomBarController();
  MemoryImage? userImage;
  OdooClient? client;
  bool isFailedView = false;
  bool isLoading = false;
  bool isNetworkAvailable = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkConnectivity();
    await Hive.openBox('user');
    _initializeOdooClient();
    getProfile();
  }

  @override
  // void initState() {
  //   super.initState();
  //   _initializeHiveAndClient();
  //   // _initializeOdooClient();
  //   // getProfile();
  // }
  //
  // Future<void> _initializeHiveAndClient() async {
  //   await Hive.openBox('user');
  //   _initializeOdooClient();
  //   getProfile();
  // }

  Future<bool> _onWillPop() async {
    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
    _controller.index = -1;
    return false;
  }


  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    print(connectivityResult);
    print("fffffffffffffffffffffffdddddddddddddd");
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
        await getProfile();
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
    setState(() {
      getProfile();
    });
  }

  // Future<void> getProfile() async {
  //   if (!isNetworkAvailable) {
  //     final userBox = Hive.box('user');
  //     final cachedData = userBox.get('userData');
  //     if (cachedData != null) {
  //       setState(() {
  //         userName = cachedData['name'];
  //         userMail = cachedData['email'];
  //         installingJobs = cachedData['installingJobs'] ?? 0;
  //         completedJobs = cachedData['completedJobs'] ?? 0;
  //         if (cachedData['image'] != null && cachedData['image'] is String) {
  //           final imageBytes = base64Decode(cachedData['image']);
  //           userImage = MemoryImage(Uint8List.fromList(imageBytes));
  //         }
  //         isLoading = false;
  //       });
  //     }
  //     return;
  //   } else {
  //     print("ffffffffffffffffffffffffffssssssss");
  //     final userBox = Hive.box('user');
  //     isLoading = true;
  //     final prefs = await SharedPreferences.getInstance();
  //     final userId = prefs.getInt('userId') ?? 0;
  //     print("66666666666666666666666666666666666666666");
  //     try {
  //       final userDetails = await client?.callKw({
  //         'model': 'res.users',
  //         'method': 'search_read',
  //         'args': [
  //           [
  //             ['id', '=', userId]
  //           ]
  //         ],
  //         'kwargs': {
  //           'fields': ['name', 'email', 'image_1920'],
  //         },
  //       });
  //
  //       Uint8List? imageData;
  //       print(userDetails);
  //       print("userDetailsuserDetailsuserDetailsuserDetails");
  //       if (userDetails != null && userDetails.isNotEmpty) {
  //         final user = userDetails[0];
  //         final imageBase64 = user['image_1920']?.toString();
  //
  //         if (imageBase64 != null && imageBase64 != 'false') {
  //           imageData = base64Decode(imageBase64);
  //           setState(() {
  //             userImage = MemoryImage(imageData!);
  //           });
  //         }
  //
  //         setState(() {
  //           userName = user['name'];
  //           userMail = user['email'];
  //         });
  //       }
  //
  //       final tasks = await client?.callKw({
  //         'model': 'project.task',
  //         'method': 'search_read',
  //         'args': [
  //           [
  //             ['x_studio_proposed_team', '=', userId],
  //             ['worksheet_id', '!=', false]
  //           ]
  //         ],
  //         'kwargs': {
  //           'fields': ['install_status'],
  //         },
  //       });
  //
  //       int newTaskCount = 0;
  //       int completedTaskCount = 0;
  //
  //       if (tasks != null) {
  //         for (var task in tasks) {
  //           var status = task['install_status'];
  //           if (status == 'progress') {
  //             newTaskCount++;
  //           } else if (status == 'done') {
  //             completedTaskCount++;
  //           }
  //         }
  //       }
  //       setState(() {
  //         installingJobs = newTaskCount;
  //         completedJobs = completedTaskCount;
  //         isLoading = false;
  //       });
  //
  //     } catch (e) {
  //       final userBox = Hive.box('user');
  //       final cachedData = userBox.get('userData');
  //       if (cachedData != null) {
  //         setState(() {
  //           userName = cachedData['name'];
  //           userMail = cachedData['email'];
  //           installingJobs = cachedData['installingJobs'] ?? 0;
  //           completedJobs = cachedData['completedJobs'] ?? 0;
  //           if (cachedData['image'] != null && cachedData['image'] is String) {
  //             final imageBytes = base64Decode(cachedData['image']);
  //             userImage = MemoryImage(Uint8List.fromList(imageBytes));
  //           }
  //           isLoading = false;
  //           isFailedView == null;
  //         });
  //       }
  //       return;
  //       // setState(() {
  //       //   isLoading = false;
  //       //   isFailedView == null;
  //       // });
  //       // print("Error fetching profile data: $e");
  //     }
  //   }
  // }

  Future<void> getProfile() async {
    print("444444444444444444444444ddddddddddddddddddddddddddddd$isNetworkAvailable");
    final userBox = Hive.box('user');
    final cachedData = userBox.get('userData');

    if (cachedData != null) {
      setState(() {
        userName = cachedData['name'];
        userMail = cachedData['email'];
        installingJobs = cachedData['installingJobs'] ?? 0;
        completedJobs = cachedData['completedJobs'] ?? 0;
        if (cachedData['image'] != null && cachedData['image'] is String) {
          final imageBytes = base64Decode(cachedData['image']);
          userImage = MemoryImage(Uint8List.fromList(imageBytes));
        }
        isLoading = false;
      });
    }


    if (isNetworkAvailable) {
      try {
        isLoading = true;
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('userId') ?? 0;

        final teamId = prefs.getInt('teamId') ?? 0;
        final baseUrl = prefs.getString('url') ?? 0;
        print("userDetailsuserDetailsuserDetailsdddddddddddd$teamId");
        // final userDetails = await client!.callRPC('/rebates/team_members'', 'call', {});
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
        // final userDetails = await client?.callKw({
        //   'model': 'team.member',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       ['id', '=', 1]
        //     ]
        //   ],
        //   'kwargs': {
        //     'fields': ['name', 'email', 'image_1920'],
        //   },
        // });

        Uint8List? imageData;

        print(userDetails.body);
        print("userDetailsuserDetaijjjjjjjjlsuserDetails");
        final Map<String, dynamic> jsonResponse = json.decode(userDetails.body);

        if (jsonResponse['result']['status'] == 'success' && jsonResponse['result']['team_member_data'].isNotEmpty) {
          final user = jsonResponse['result']['team_member_data'][0];
          print("useruseruseruseruseruseruseruseruser$user");
          final imageBase64 = user['image_1920']?.toString();

          if (imageBase64 != null && imageBase64 != 'false') {
            imageData = base64Decode(imageBase64);
            setState(() {
              userImage = MemoryImage(imageData!);
            });
          }

          setState(() {
            userName = user['name'];
            userMail = user['email'];
          });


          userBox.put('userData', {
            'name': user['name'],
            'email': user['email'],
            'image': imageBase64,
            'installingJobs': installingJobs,
            'completedJobs': completedJobs,
          });
        }

        final Uri projectUrl = Uri.parse('$baseUrl/rebates/project_task');
        final tasks = await http.post(
          projectUrl,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "team_id": teamId,
            }
          }),
        );
        print(tasks.body);
        print("bosyydyyyyyyyyyyyyyyyyyyyy");
        final Map<String, dynamic> jsonProjectResponse = json.decode(tasks.body);
        print("sssssssssssss${jsonProjectResponse.length}");
        // final tasks = await client?.callKw({
        //   'model': 'project.task',
        //   'method': 'search_read',
        //   'args': [
        //     [
        //       // ['x_studio_proposed_team', '=', userId],
        //       ['team_lead_user_id', '=', userId],
        //       ['worksheet_id', '!=', false]
        //     ]
        //   ],
        //   'kwargs': {
        //     'fields': ['install_status'],
        //   },
        // });

        int newTaskCount = 0;
        int completedTaskCount = 0;

        if (jsonProjectResponse['result']['status'] == 'success') {
          for (var task in jsonProjectResponse['result']['tasks']) {
            var status = task['install_status'];
            if (status == 'progress') {
              newTaskCount++;
            } else if (status == 'done') {
              completedTaskCount++;
            }
          }
        }

        setState(() {
          installingJobs = newTaskCount;
          completedJobs = completedTaskCount;
          isLoading = false;
        });


        userBox.put('userData', {
          'name': userName,
          'email': userMail,
          'image': cachedData?['image'],
          'installingJobs': newTaskCount,
          'completedJobs': completedTaskCount,
        });

      } catch (e) {
        print("Error fetching profile data: $e");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 400,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 40),
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 80,
            margin: EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        SizedBox(height: 30),
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 80,
            margin: EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileContent() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(top: 80, bottom: 80),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[100]!, Colors.green],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              if (isLoadingImage)
                CircleAvatar(
                  radius: 60.0,
                  backgroundColor: Colors.transparent,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                CircleAvatar(
                  radius: 60.0,
                  backgroundColor: Colors.grey[350],
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipOval(
                          child: userImage != null
                              ? Image(
                            image: userImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (BuildContext context,
                                Object exception,
                                StackTrace? stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 54,
                                color: Colors.black,
                              );
                            },
                          )
                              : Icon(Icons.person,
                              size: 54, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 10),
              Text(
                userName,
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                userMail,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        '$installingJobs',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 23,
                          color: Colors.red[700],
                        ),
                      ),
                      Text(
                        'Installing Jobs',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '$completedJobs',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 23,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Completed Jobs',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 40),
        Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/profile',
                      arguments: {'getProfile': getProfile});
                },
                child: Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey[200]!,
                        blurRadius: 6.0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person,
                        color: Colors.green[800],
                        size: 31,
                      ),
                      SizedBox(width: 50),
                      Expanded(
                        child: Text(
                          'Profile',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 20),
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
              ),
              SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
                child: Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey[200]!,
                        blurRadius: 6.0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.settings,
                        color: Colors.green[800],
                        size: 31,
                      ),
                      SizedBox(width: 50),
                      Expanded(
                        child: Text(
                          'Settings',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 20),
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              isLoading ? _buildShimmerLoading() : _buildProfileContent(),
            ],
          ),
          // Back button overlay
          Positioned(
            top: 40.0,
            left: 16.0,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
//
// @override
// Widget build(BuildContext context) {
//   final args = ModalRoute.of(context)!.settings.arguments as Map;
//   return WillPopScope(
//     onWillPop: () async {
//       setState(() {
//         args['reloadProfile']?.call();
//       });
//       return true;
//     },
//   child: Scaffold(
//     appBar: AppBar(
//       title: const Text(
//         '',
//         style: TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       backgroundColor: Colors.green,
//       automaticallyImplyLeading: true,
//       iconTheme: const IconThemeData(
//         color: Colors.white,
//       ),
//     ),
//     body: isLoading
//         ? _buildShimmerLoading()
//         : isFailedView
//             ? Center(
//                 child: Text(
//                   "Something went wrong. Please try again later.",
//                   style: TextStyle(
//                     color: Colors.red,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               )
//             : _buildProfileContent(),
//     ),
//   );
// }
//
// Widget _buildShimmerLoading() {
//   return SingleChildScrollView(
//     padding: const EdgeInsets.all(16.0),
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Shimmer.fromColors(
//           baseColor: Colors.grey[300]!,
//           highlightColor: Colors.grey[100]!,
//           child: CircleAvatar(
//             radius: 60.0,
//             backgroundColor: Colors.grey[300],
//           ),
//         ),
//         SizedBox(height: 30),
//         Column(
//           children: [
//             Shimmer.fromColors(
//               baseColor: Colors.grey[300]!,
//               highlightColor: Colors.grey[100]!,
//               child: Container(
//                 width: 80,
//                 height: 20,
//                 color: Colors.grey[300],
//               ),
//             ),
//             SizedBox(height: 10),
//             Shimmer.fromColors(
//               baseColor: Colors.grey[300]!,
//               highlightColor: Colors.grey[100]!,
//               child: Container(
//                 width: 80,
//                 height: 20,
//                 color: Colors.grey[300],
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: 40),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             Column(
//               children: [
//                 Shimmer.fromColors(
//                   baseColor: Colors.grey[300]!,
//                   highlightColor: Colors.grey[100]!,
//                   child: Text(
//                     '$installingJobs',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                       color: Colors.red,
//                     ),
//                   ),
//                 ),
//                 Text(
//                   'Installing Jobs',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                     color: Colors.red,
//                   ),
//                 ),
//               ],
//             ),
//             Column(
//               children: [
//                 Shimmer.fromColors(
//                   baseColor: Colors.grey[300]!,
//                   highlightColor: Colors.grey[100]!,
//                   child: Text(
//                     '$completedJobs',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                       color: Colors.green[700],
//                     ),
//                   ),
//                 ),
//                 Text(
//                   'Completed Jobs',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                     color: Colors.green[700],
//                   ),
//                 ),
//               ],
//             ),
//             // Uncomment if you decide to use currentPoints later
//             // Column(
//             //   children: [
//             //     Shimmer.fromColors(
//             //       baseColor: Colors.grey[300]!,
//             //       highlightColor: Colors.grey[100]!,
//             //       child: Text(
//             //         '$currentPoints',
//             //         style: TextStyle(
//             //           fontWeight: FontWeight.bold,
//             //           fontSize: 18,
//             //           color: Colors.black,
//             //         ),
//             //       ),
//             //     ),
//             //     Text(
//             //       'Current Points',
//             //       style: TextStyle(
//             //         fontWeight: FontWeight.bold,
//             //         fontSize: 14,
//             //         color: Colors.black,
//             //       ),
//             //     ),
//             //   ],
//             // ),
//           ],
//         ),
//         SizedBox(height: 40),
//         Container(
//           padding: EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               GestureDetector(
//                 onTap: () {
//                   Navigator.pushNamed(context, '/profile',
//                       arguments: {'getProfile': getProfile});
//                 },
//                 child: Container(
//                   padding: EdgeInsets.all(8.0),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[200],
//                     borderRadius: BorderRadius.circular(12.0),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey[200]!,
//                         blurRadius: 6.0,
//                         offset: Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         Icons.person,
//                         color: Colors.green[800],
//                       ),
//                       SizedBox(width: 50),
//                       Expanded(
//                         child: Text(
//                           'Profile',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black,
//                           ),
//                         ),
//                       ),
//                       Icon(
//                         Icons.arrow_forward_ios,
//                         color: Colors.grey,
//                         size: 15,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(height: 30),
//               GestureDetector(
//                 onTap: () {
//                   Navigator.pushNamed(context, '/settings');
//                 },
//                 child: Container(
//                   padding: EdgeInsets.all(8.0),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[200],
//                     borderRadius: BorderRadius.circular(12.0),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey[200]!,
//                         blurRadius: 6.0,
//                         offset: Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         Icons.settings,
//                         color: Colors.green[800],
//                       ),
//                       SizedBox(width: 50),
//                       Expanded(
//                         child: Text(
//                           'Settings',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black,
//                           ),
//                         ),
//                       ),
//                       Icon(
//                         Icons.arrow_forward_ios,
//                         color: Colors.grey,
//                         size: 15,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     ),
//   );
// }
//
// Widget _buildProfileContent() {
//   var screenSize = MediaQuery.of(context).size;
//   var paddingHeight = screenSize.height * 0.2;
//   return SingleChildScrollView(
//     child: Padding(
//       padding: EdgeInsets.only(left: 16.0, right: 16, top: paddingHeight),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           if (isLoadingImage)
//             CircleAvatar(
//               radius: 60.0,
//               backgroundColor: Colors.transparent,
//               child: Center(
//                 child: CircularProgressIndicator(),
//               ),
//             )
//           else
//             CircleAvatar(
//               radius: 60.0,
//               backgroundColor: Colors.grey[350],
//               child: Stack(
//                 children: [
//                   Positioned.fill(
//                     child: ClipOval(
//                       child: userImage != null
//                           ? Image(
//                               image: userImage!,
//                               fit: BoxFit.cover,
//                               errorBuilder: (BuildContext context,
//                                   Object exception, StackTrace? stackTrace) {
//                                 return Icon(
//                                   Icons.person,
//                                   size: 54,
//                                   color: Colors.black,
//                                 );
//                               },
//                             )
//                           : Icon(Icons.person, size: 54, color: Colors.black),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           SizedBox(height: 30),
//           Column(
//             children: [
//               Text(
//                 userName,
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 20,
//                   color: Colors.black,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(
//                 height: 10,
//               ),
//               Text(
//                 userMail,
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 15,
//                   color: Colors.black.withOpacity(0.5),
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//           SizedBox(height: 40),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               Column(
//                 children: [
//                   Text(
//                     '$installingJobs',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                       color: Colors.red,
//                     ),
//                   ),
//                   Text(
//                     'Installing Jobs',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 14,
//                       color: Colors.red,
//                     ),
//                   ),
//                 ],
//               ),
//               Column(
//                 children: [
//                   Text(
//                     '$completedJobs',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                       color: Colors.green[700],
//                     ),
//                   ),
//                   Text(
//                     'Completed Jobs',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 14,
//                       color: Colors.green[700],
//                     ),
//                   ),
//                 ],
//               ),
//               // Column(
//               //   children: [
//               //     Text(
//               //       '$currentPoints',
//               //       style: TextStyle(
//               //         fontWeight: FontWeight.bold,
//               //         fontSize: 18,
//               //         color: Colors.black,
//               //       ),
//               //     ),
//               //     Text(
//               //       'Current Points',
//               //       style: TextStyle(
//               //         fontWeight: FontWeight.bold,
//               //         fontSize: 14,
//               //         color: Colors.black,
//               //       ),
//               //     ),
//               //   ],
//               // ),
//             ],
//           ),
//           SizedBox(height: 40),
//           Container(
//             padding: EdgeInsets.all(16.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 GestureDetector(
//                   onTap: () {
//                     Navigator.pushNamed(context, '/profile',
//                         arguments: {'getProfile': getProfile});
//                   },
//                   child: Container(
//                     padding: EdgeInsets.all(8.0),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(12.0),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.grey[200]!,
//                           blurRadius: 6.0,
//                           offset: Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           Icons.person,
//                           color: Colors.green[800],
//                         ),
//                         SizedBox(width: 50),
//                         Expanded(
//                           child: Text(
//                             'Profile',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                         Icon(
//                           Icons.arrow_forward_ios,
//                           color: Colors.grey,
//                           size: 15,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 30),
//                 GestureDetector(
//                   onTap: () {
//                     Navigator.pushNamed(context, '/settings');
//                   },
//                   child: Container(
//                     padding: EdgeInsets.all(8.0),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(12.0),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.grey[200]!,
//                           blurRadius: 6.0,
//                           offset: Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           Icons.settings,
//                           color: Colors.green[800],
//                         ),
//                         SizedBox(width: 50),
//                         Expanded(
//                           child: Text(
//                             'Settings',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                         Icon(
//                           Icons.arrow_forward_ios,
//                           color: Colors.grey,
//                           size: 15,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
// }

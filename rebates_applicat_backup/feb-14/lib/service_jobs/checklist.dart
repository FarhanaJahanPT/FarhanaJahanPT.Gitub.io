import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:shimmer/shimmer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';

import '../installation/checklist.dart';
import '../offline_db/checklist/checklist_item_hive.dart';
import '../offline_db/checklist/edit_checklist.dart';
import '../offline_db/service_checklist/checklist_item_hive.dart';
import '../offline_db/service_checklist/edit_checklist.dart';

class ServiceChecklistItem {
  final String title;
  final String key;
  final bool isMandatory;
  final List<File> uploadedImages;
  final int requiredImages;
  String? textContent;
  final String type;
  bool isUploading;

  ServiceChecklistItem({
    required this.title,
    required this.key,
    required this.isMandatory,
    required this.uploadedImages,
    required this.requiredImages,
    this.textContent,
    required this.type,
    this.isUploading = false,
  });

}

class ServiceChecklistPage extends StatefulWidget {
  @override
  State<ServiceChecklistPage> createState() => _ServiceChecklistPageState();
}

class _ServiceChecklistPageState extends State<ServiceChecklistPage> {
  File? imageFile;
  OdooClient? client;
  String url = "";
  int? userId;
  List<ServiceChecklistItem> checklistItems = [];
  bool isLoading = true;
  bool isSubmitLoading = false;
  bool isPickImageLoading = false;
  String status_done = "";
  bool isNetworkAvailable = false;
  int? taskId;
  String? imageId;

  @override
  void initState() {
    super.initState();
    _initializeOdooClient();
    _initialize();
    // WidgetsBinding.instance!.addPostFrameCallback((_) {
    //   final args =
    //       ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    //   status_done = args['status_done'];
    //   print(status_done);
    //   print("status_donestatus_done");
    //   _initializeOdooClient();
    //   getChecklist();
    // });
  }

  Future<void> _initialize() async {
    await _checkConnectivity();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      final args =
      ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      status_done = args['status_done'];
      taskId = args['task_id'];
      getChecklist();
    });
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
        await getChecklist();
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
  }

  Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> createChecklist(
      int taskId, ServiceChecklistItem item, File? imageFile) async {
    if (imageFile != null) {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      Position position = await _getCurrentLocation();
      // String location = '${position.latitude}, ${position.longitude}';
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks.first;
      String locationDetails =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";

      try {
        final checklist = await client?.callKw({
          'model': 'service.checklist.item',
          'method': 'create',
          'args': [
            {
              'user_id': userId,
              'worksheet_id': taskId,
              'service_id': item.key,
              'image': base64Image,
              'location': locationDetails,
              'latitude': position.latitude,
              'longitude': position.longitude
            }
          ],
          'kwargs': {},
        });
      } catch (e) {
        print('Error creating checklist: $e');
      }
    }
  }

  Future<void> uploadChecklist(
      ServiceChecklistItem item, File? imageFile, position) async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    if (imageFile != null) {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      // Position position = await _getCurrentLocation();
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks.first;
      String locationDetails =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
      try {
        await createChecklist(args['worksheet_id'], item, imageFile);
        final checklist = await client?.callKw({
          'model': 'service.checklist.item',
          'method': 'write',
          'args': [
            [args['worksheet_id']],
            {
              'worksheet_id': args['worksheet_id'],
              'user_id': userId,
              'service_id': item.key,
              'image': base64Image,
              'location': locationDetails,
              'latitude': position.latitude,
              'longitude': position.longitude
            }
          ],
          'kwargs': {},
        });
        setState(() {});
      } catch (e) {
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
                        "Please check your network connection.",
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
        print('Error uploading checklist: $e');
      }
    }
  }

  Future<void> loadChecklistFromHive(int worksheetId) async {
    print('entered the loadChecklistFromHive');
    final boxName = 'checklistServiceItems_$worksheetId';
    final box = await Hive.openBox<ServiceChecklistItemHive>(boxName);
    print("$box/ccccccccccccccccdddddddddddddd");
    List<ServiceChecklistItem> loadedItems = box.values.map((hiveItem) {
      return ServiceChecklistItem(
        title: hiveItem.title,
        key: hiveItem.key,
        isMandatory: hiveItem.isMandatory,
        uploadedImages:
        hiveItem.uploadedImagePaths.map((path) => File(path)).toList(),
        requiredImages: hiveItem.requiredImages,
        textContent: hiveItem.textContent,
        type: hiveItem.type,
      );
    }).toList();

    setState(() {
      checklistItems = convertToServiceChecklistItems(loadedItems);
      isLoading = false;
    });
    await box.close();
  }

  List<ServiceChecklistItem> convertToServiceChecklistItems(List<ServiceChecklistItem> items) {
    return items.map((item) {
      return ServiceChecklistItem(
        title: item.title,
        key: item.key,
        isMandatory: item.isMandatory,
        uploadedImages: item.uploadedImages,
        requiredImages: item.requiredImages,
        textContent: item.textContent,
        type: item.type,
      );
    }).toList();
  }


  Future<void> getChecklist() async {
    final args = ModalRoute
        .of(context)!
        .settings
        .arguments as Map;
    if (!isNetworkAvailable) {
      print('not internet is connected ${args['worksheet_id']}');
      loadChecklistFromHive(args['worksheet_id']);
      return;
    } else {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;
      try {
        final checklist = await client?.callKw({
          'model': 'service.checklist',
          'method': 'search_read',
          'args': [
            [
              ['category_ids', 'in', args['category_ids']],
              [
                'selfie_type',
                'not in',
                ['mid', 'check_out', 'check_in']
              ],
            ]
          ],
          'kwargs': {},
        });
        if (checklist != null && checklist is List) {
          List<ServiceChecklistItem> fetchedChecklistItems = [];
          for (var item in checklist) {
            final imagesOrText = await client?.callKw({
              'model': 'service.checklist.item',
              'method': 'search_read',
              'args': [
                [
                  ['service_id', '=', item['id']],
                  ['worksheet_id', '=', args['worksheet_id']]
                ]
              ],
              'kwargs': {},
            });

            List<File> uploadedImages = [];
            String? textContent;
            if (imagesOrText != null &&
                imagesOrText is List &&
                imagesOrText.isNotEmpty) {
              for (var entry in imagesOrText) {
                if (item['type'] == 'img') {
                  String base64String = entry['image'].toString();
                  if (base64String != null && base64String != 'false') {
                    Uint8List bytes = base64Decode(base64String);
                    Directory appDocDir =
                    await getApplicationDocumentsDirectory();
                    String filePath =
                        '${appDocDir.path}/image_${entry['id']}.jpg';
                    File file = File(filePath);
                    await file.writeAsBytes(bytes);
                    uploadedImages.add(file);
                  } else {}
                  // Uint8List bytes = base64Decode(base64String);
                  // Directory appDocDir = await getApplicationDocumentsDirectory();
                  // String filePath = '${appDocDir
                  //     .path}/image_${entry['id']}.jpg';
                  // File file = File(filePath);
                  // await file.writeAsBytes(bytes);
                  // uploadedImages.add(file);
                } else if (item['type'] == 'text') {
                  if (entry['text'] != null && entry['text'] is String) {
                    textContent = entry['text'];
                  }
                }
              }
            }
            fetchedChecklistItems.add(ServiceChecklistItem(
              title: item['name'] ?? 'Unnamed',
              key: item['id'].toString() ?? '0',
              isMandatory: item['compulsory'] ?? false,
              uploadedImages: item['type'] == 'img' ? uploadedImages : [],
              requiredImages: item['min_qty'] ?? 1,
              textContent: item['type'] == 'text' ? textContent ?? '' : null,
              type: item['type'] ?? '',
            ));
          }
          setState(() {
            checklistItems = fetchedChecklistItems;
            isLoading = false;
          });
          // saveChecklistToHive(args['worksheet_id']);
        } else {
          isLoading = false;
        }
      } catch (e) {
        loadChecklistFromHive(args['worksheet_id']);
        return;
      }
    }
  }

  // Future<void> saveChecklistToHive(int worksheetId) async {
  //   final boxName = 'checklistItems_$worksheetId';
  //   final box = await Hive.openBox<ChecklistItemHive>(boxName);
  //   await box.clear();
  //   List<ChecklistItemHive> checklistHiveItems = checklistItems.map((item) {
  //     return ChecklistItemHive(
  //       title: item.title,
  //       key: item.key,
  //       isMandatory: item.isMandatory,
  //       uploadedImagePaths:
  //       item.uploadedImages.map((file) => file.path).toList(),
  //       requiredImages: item.requiredImages,
  //       textContent: item.textContent,
  //       type: item.type,
  //         isUpload: item.isUpload
  //     );
  //   }).toList();
  //   await box.clear();
  //   await box.addAll(checklistHiveItems);
  //   await box.close();
  // }

  Future<void> _pickImages(ServiceChecklistItem item) async {
    try {
      if (item.uploadedImages.length >= item.requiredImages) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'You have already uploaded the required number of images.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;
      final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
      String worksheetId = args['worksheet_id']?.toString() ?? 'unknown';
      String compositeKey = "$worksheetId-${item.key}";

      final box = await Hive.openBox<OfflineServiceChecklistItem>('offline_service_checklist');
      OfflineServiceChecklistItem? existingItem = await box.get(compositeKey);


      int existingImagesCount = existingItem?.uploadedImages.length ?? 0;

      if (existingImagesCount >= item.requiredImages) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You have already uploaded the required number of images.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxHeight: 1000,
        maxWidth: 1000,
      );

      if (pickedFile != null) {
        imageFile = File(pickedFile.path);
        setState(() {
          item.isUploading = true;
        });
        item.uploadedImages.add(imageFile!);
        Position position = await _getCurrentLocation();
        await saveChecklistItemOffline(item, position, imageFile: imageFile);
        await uploadChecklist(item, imageFile, position);

        setState(() {
          item.isUploading = false;
        });
      }
      Navigator.popUntil(context, ModalRoute.withName('/service_checklist'));
    } catch (e) {
      setState(() {
        item.isUploading = false;
      });
    }
  }


  // Future<void> saveChecklistItemOffline(
  //     ServiceChecklistItem item,
  //     position, {
  //       String? textContent,
  //       File? imageFile,
  //     }) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   userId = prefs.getInt('userId') ?? 0;
  //
  //   final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
  //
  //   String worksheetId = args['worksheet_id']?.toString() ?? 'unknown';
  //   String compositeKey = "$worksheetId-${item.key}"; // Create composite key
  //
  //   List<String> base64Images = [];
  //   if (imageFile != null) {
  //     List<int> imageBytes = await imageFile.readAsBytes();
  //     String base64Image = base64Encode(imageBytes);
  //     base64Images.add(base64Image);
  //     imageId = Uuid().v4();
  //   }
  //
  //   List<String> uploadedImagesBase64 = [];
  //   for (var file in item.uploadedImages) {
  //     List<int> bytes = await file.readAsBytes();
  //     uploadedImagesBase64.add(base64Encode(bytes));
  //   }
  //
  //   final offlineItem = OfflineServiceChecklistItem(
  //     userId: userId!,
  //     worksheetId: worksheetId,
  //     checklistId: item.key,
  //     title: item.title,
  //     isMandatory: item.isMandatory,
  //     type: item.type,
  //     requiredImages: item.requiredImages,
  //     uploadedImages: uploadedImagesBase64,
  //     textContent: textContent,
  //     imageBase64: base64Images,
  //     position: {
  //       'latitude': position.latitude,
  //       'longitude': position.longitude
  //     },
  //   );
  //
  //   final box = await Hive.openBox<OfflineServiceChecklistItem>('offline_service_checklist');
  //   final existingItem = box.get(compositeKey);
  //
  //   if (existingItem != null) {
  //     existingItem.uploadedImages.addAll(uploadedImagesBase64.where(
  //           (image) => !existingItem.uploadedImages.contains(image),
  //     ));
  //     existingItem.textContent = textContent ?? existingItem.textContent;
  //
  //     if (imageFile != null) {
  //       existingItem.imageBase64!.addAll(
  //         base64Images
  //             .where((base64) => !existingItem.imageBase64!.contains(base64)),
  //       );
  //     }
  //     await box.put(compositeKey, existingItem);
  //   } else {
  //     await box.put(compositeKey, offlineItem);
  //   }
  //
  //   if (mounted) {
  //     setState(() {
  //       isSubmitLoading = false;
  //     });
  //   }
  //   await box.close();
  // }

  Future<void> saveChecklistItemOffline(
      ServiceChecklistItem item,
      Position position, {
        String? textContent,
        File? imageFile,
      }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;

    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final String worksheetId = args['worksheet_id']?.toString() ?? 'unknown';

    final String compositeKey = "$worksheetId-${item.key}";

    List<String> base64Images = [];
    if (imageFile != null) {
      final imageBytes = await imageFile.readAsBytes();
      base64Images.add(base64Encode(imageBytes));
    }

    List<String> uploadedImagesBase64 = [];
    for (var file in item.uploadedImages) {
      final bytes = await file.readAsBytes();
      uploadedImagesBase64.add(base64Encode(bytes));
    }

    final offlineItem = OfflineServiceChecklistItem(
      userId: userId,
      worksheetId: worksheetId,
      checklistId: item.key,
      title: item.title,
      isMandatory: item.isMandatory,
      type: item.type,
      requiredImages: item.requiredImages,
      uploadedImages: uploadedImagesBase64,
      textContent: textContent,
      imageBase64: base64Images,
      position: {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
        createTime: DateTime.now()
    );

    final box = await Hive.openBox<OfflineServiceChecklistItem>('offline_service_checklist');

    try {
      final existingItem = box.get(compositeKey);

      if (existingItem != null) {
        existingItem.uploadedImages.addAll(uploadedImagesBase64.where(
              (image) => !existingItem.uploadedImages.contains(image),
        ));
        existingItem.textContent = textContent ?? existingItem.textContent;

        if (imageFile != null) {
          existingItem.imageBase64!.addAll(
            base64Images.where((base64) => !existingItem.imageBase64!.contains(base64)),
          );
        }

        await box.put(compositeKey, existingItem);
      } else {
        await box.put(compositeKey, offlineItem);
      }
      if (mounted) {
        setState(() {
          isSubmitLoading = false;
        });
      }
    } catch (e) {
    } finally {
      await box.close();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checklist',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? _buildShimmerLoading()
            : checklistItems.isEmpty
                ? _buildNoChecklistMessage()
                : _buildChecklistList(),
      ),
    );
  }

  Widget _buildChecklistList() {
    return ListView.builder(
      itemCount: checklistItems.length,
      itemBuilder: (context, index) {
        final item = checklistItems[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: null,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),

                if (item.isMandatory)
                  Text(
                    "*",
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 25),
                  ),
              ],
            ),
            subtitle: item.type == 'img'
                ? (item.isUploading
                    ? Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 10),
                          Text(
                            'Uploading...',
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      )
                    : Text(
                        '${item.uploadedImages.length}/${item.requiredImages} uploaded'))
                : Text(item.textContent!.isNotEmpty
                    ? 'Text updated'
                    : 'Text input required'),
            trailing: item.type == 'img'
                ? IconButton(
                    icon: Icon(Icons.add_a_photo),
                    onPressed: () {
                      if (status_done != 'done') {
                        _pickImages(item);
                      }
                    },
                  )
                : IconButton(
                    icon: Icon(Icons.text_fields),
                    onPressed: () {
                      if (status_done != 'done') {
                        _showTextInputDialog(context, item);
                      }
                    },
                  ),
            onTap: () {
              if (item.type == 'img') {
                _showUploadedImages(context, item.uploadedImages);
              } else if (item.type == 'text') {
                _showTextDialog(context, item);
              }
            },
          ),
        );
      },
    );
  }

  void _showTextDialog(BuildContext context, ServiceChecklistItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Text for ${item.title}",
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
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
              minWidth: MediaQuery.of(context).size.width * 0.95,
            ),
            child: SingleChildScrollView(
              child: item.textContent != null && item.textContent!.isNotEmpty
                  ? Center(
                      child: Text(
                        item.textContent!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    )
                  : Center(
                      child: Text(
                        'No text available',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  void _showTextInputDialog(BuildContext context, ServiceChecklistItem item) {
    final TextEditingController controller =
        TextEditingController(text: item.textContent);
    bool isSubmitLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Stack(
              children: [
                AlertDialog(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Add Text for ${item.title}",
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
                  content: TextField(
                    controller: controller,
                    decoration:
                        InputDecoration(hintText: "Enter your text here"),
                  ),
                  actions: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          String inputText = controller.text;
                          if (inputText.isNotEmpty) {
                            setState(() {
                              isSubmitLoading = true;
                            });
                            await uploadTextToChecklist(item, inputText);
                            setState(() {
                              isSubmitLoading = false;
                            });
                            Navigator.of(context).pop(true);
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
                        child: Text(
                          "SUBMIT",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isSubmitLoading)
                  Positioned.fill(
                    child: Container(
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.green),
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
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Container(
                width: double.infinity,
                height: 20.0,
                color: Colors.white,
              ),
              subtitle: Container(
                width: double.infinity,
                height: 15.0,
                color: Colors.white,
              ),
              trailing: Icon(Icons.add_a_photo, color: Colors.transparent),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoChecklistMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist,
            color: Colors.black,
            size: 92,
          ),
          SizedBox(height: 20),
          Text(
            "No checklist is available for this project",
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadedImages(BuildContext context, List<File>? images) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Uploaded Images",
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
          content: SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width * 0.95,
            child: images == null || images.isEmpty
                ? Center(
                    child: Text(
                      'No images available',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.file(
                          images[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Future<void> uploadTextToChecklist(
      ServiceChecklistItem item, String inputText) async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    Position position = await _getCurrentLocation();
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks.first;
    String locationDetails =
        "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";

    try {
      final existingChecklist = await client?.callKw({
        'model': 'service.checklist.item',
        'method': 'search_read',
        'args': [
          [
            ['service_id', '=', int.parse(item.key)],
            ['worksheet_id', '=', args['worksheet_id']]
          ],
          ['id']
        ],
        'kwargs': {},
      });
      if (existingChecklist != null &&
          existingChecklist is List &&
          existingChecklist.isNotEmpty) {
        final checklistId = existingChecklist.first['id'];
        await client?.callKw({
          'model': 'service.checklist.item',
          'method': 'write',
          'args': [
            [checklistId],
            {'text': inputText, 'location': locationDetails,
              'latitude': position.latitude,
              'longitude': position.longitude}
          ],
          'kwargs': {},
        });
      } else {
        await client?.callKw({
          'model': 'service.checklist.item',
          'method': 'create',
          'args': [
            {
              'user_id': userId,
              'worksheet_id': args['worksheet_id'],
              'service_id': item.key,
              'text': inputText,
              'location': locationDetails,
              'latitude': position.latitude,
              'longitude': position.longitude
            }
          ],
          'kwargs': {},
        });
      }
      setState(() {
        item.textContent = inputText;
      });
    } catch (e) {
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
                      "Please check your network connection.",
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
      print('Error uploading text to checklist: $e');
    }
  }
}

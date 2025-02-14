import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:hive/hive.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';

import '../offline_db/installation_form/project_document.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class WorksheetScreen extends StatefulWidget {
  final int project_id;
  final String switchBoardUsed;
  final String expectedInverterLocation;
  final String mountingWallType;
  final String inverterLocationNotes;
  final String expectedBatteryLocation;
  final String mountingType;

  WorksheetScreen({
    required this.project_id,
    required this.switchBoardUsed,
    required this.expectedInverterLocation,
    required this.mountingWallType,
    required this.inverterLocationNotes,
    required this.expectedBatteryLocation,
    required this.mountingType,
  });

  @override
  _WorksheetScreenState createState() => _WorksheetScreenState();
}

class _WorksheetScreenState extends State<WorksheetScreen> {
  MemoryImage? solarProductImage;
  MemoryImage? derRecieptDocumet;
  MemoryImage? ccewDocumet;
  MemoryImage? stcDocumet;
  MemoryImage? solarPanelDocumet;
  MemoryImage? switchBoardDocumet;
  MemoryImage? batteryLocationDocument;
  MemoryImage? inverterLocationDocumet;
  OdooClient? client;
  int? userId;
  bool isNetworkAvailable = false;
  String url = "";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _initializeOdooClient();
    await _checkConnectivity();
    getDocuments();
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
        getDocuments();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getDocuments() async {
    if (!isNetworkAvailable) {
      loadDocumentsFromHive();
      return;
    } else {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;
      try {
        print(userId);
        print(widget.project_id);
        print("ffffffffffffffffffffffffffffffff");
        final documentsFromProject = await client?.callKw({
          'model': 'project.task',
          'method': 'search_read',
          'args': [
            [
              // ['x_studio_proposed_team', '=', userId],
              ['team_lead_user_id', '=', userId],
              ['id', '=', widget.project_id],
              ['worksheet_id', '!=', false]
            ]
          ],
          'kwargs': {
            'fields': [
              'x_studio_inverter_location_1',
              'x_studio_battery_location',
              'x_studio_solar_panel_layout',
              'x_studio_switch_board_photo'
            ],
          },
        });
        print("documentsFromProjectdocumentsFromProject$documentsFromProject");
        if (documentsFromProject != null && documentsFromProject.isNotEmpty) {
          final derReceipt = documentsFromProject[0]['x_studio_der_receipt'];
          final ccewDoc = documentsFromProject[0]['x_studio_ccew'];
          final stcDoc = documentsFromProject[0]['x_studio_stc'];
          final solarPanelDoc =
              documentsFromProject[0]['x_studio_solar_panel_layout'];
          final switchBoardDoc =
              documentsFromProject[0]['x_studio_switch_board_photo'];
          final inverterLocationDoc =
              documentsFromProject[0]['x_studio_inverter_location_1'];
          final batteryLocationDoc =
              documentsFromProject[0]['x_studio_battery_location'];
          if (derReceipt is String) {
            final derBase64 = derReceipt as String;
            if (derBase64.isNotEmpty) {
              final derData = base64Decode(derBase64);
              setState(() {
                derRecieptDocumet = MemoryImage(Uint8List.fromList(derData));
              });
            }
          }
          if (ccewDoc is String) {
            final ccewBase64 = ccewDoc as String;
            if (ccewBase64.isNotEmpty) {
              final ccewData = base64Decode(ccewBase64);
              setState(() {
                ccewDocumet = MemoryImage(Uint8List.fromList(ccewData));
              });
            }
          }
          if (stcDoc is String) {
            final stcBase64 = stcDoc as String;
            if (stcBase64.isNotEmpty) {
              final stcData = base64Decode(stcBase64);
              setState(() {
                stcDocumet = MemoryImage(Uint8List.fromList(stcData));
              });
            }
          }
          if (solarPanelDoc is String) {
            final solarPanelBase64 = solarPanelDoc as String;
            if (solarPanelBase64.isNotEmpty) {
              final solarPanelData = base64Decode(solarPanelBase64);
              setState(() {
                solarPanelDocumet =
                    MemoryImage(Uint8List.fromList(solarPanelData));
              });
            }
          }
          if (switchBoardDoc is String) {
            final switchBoardBase64 = switchBoardDoc as String;
            if (switchBoardBase64.isNotEmpty) {
              final switchBoardData = base64Decode(switchBoardBase64);
              setState(() {
                switchBoardDocumet =
                    MemoryImage(Uint8List.fromList(switchBoardData));
              });
            }
          }
          if (inverterLocationDoc is String) {
            final inverterLocationBase64 = inverterLocationDoc as String;
            if (inverterLocationBase64.isNotEmpty) {
              final inverterLocationData = base64Decode(inverterLocationBase64);
              setState(() {
                inverterLocationDocumet =
                    MemoryImage(Uint8List.fromList(inverterLocationData));
              });
            }
          }
          if (batteryLocationDoc is String) {
            final batteryLocationBase64 = batteryLocationDoc as String;
            if (batteryLocationBase64.isNotEmpty) {
              final batteryLocationData = base64Decode(batteryLocationBase64);
              setState(() {
                batteryLocationDocument =
                    MemoryImage(Uint8List.fromList(batteryLocationData));
              });
            }
          }
        }
        await saveDocumentsToHive();
      } catch (e) {
        loadDocumentsFromHive();
        return;
      }
    }
  }

  void loadDocumentsFromHive() async {
    final box = await Hive.openBox<ProjectDocuments>('projectDocumentsBox');
    final projectDocuments = box.get(widget.project_id);

    if (projectDocuments != null) {
      setState(() {
        derRecieptDocumet = projectDocuments.derReceipt != null
            ? MemoryImage(projectDocuments.derReceipt!)
            : null;
        ccewDocumet = projectDocuments.ccewDoc != null
            ? MemoryImage(projectDocuments.ccewDoc!)
            : null;
        stcDocumet = projectDocuments.stcDoc != null
            ? MemoryImage(projectDocuments.stcDoc!)
            : null;
        solarPanelDocumet = projectDocuments.solarPanelDoc != null
            ? MemoryImage(projectDocuments.solarPanelDoc!)
            : null;
        switchBoardDocumet = projectDocuments.switchBoardDoc != null
            ? MemoryImage(projectDocuments.switchBoardDoc!)
            : null;
        inverterLocationDocumet = projectDocuments.inverterLocationDoc != null
            ? MemoryImage(projectDocuments.inverterLocationDoc!)
            : null;
        batteryLocationDocument = projectDocuments.batteryLocationDoc != null
            ? MemoryImage(projectDocuments.batteryLocationDoc!)
            : null;
      });
    }
    await box.close();
  }

  Future<void> saveDocumentsToHive() async {
    final box = await Hive.openBox<ProjectDocuments>(
        'projectDocumentsBox_${widget.project_id}');

    final projectDocuments = ProjectDocuments(
      derReceipt: derRecieptDocumet?.bytes,
      ccewDoc: ccewDocumet?.bytes,
      stcDoc: stcDocumet?.bytes,
      solarPanelDoc: solarPanelDocumet?.bytes,
      switchBoardDoc: switchBoardDocumet?.bytes,
      inverterLocationDoc: inverterLocationDocumet?.bytes,
      batteryLocationDoc: batteryLocationDocument?.bytes,
    );

    await box.put('projectDocuments', projectDocuments);
    await box.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Worksheet Documents',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(29.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text('Panel',
              //     style: TextStyle(
              //         color: Colors.black,
              //         fontWeight: FontWeight.bold,
              //         fontSize: 18)),
              // SizedBox(height: 20),
              // Padding(
              //   padding: EdgeInsets.all(6.0),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Text('PV Panel Model:  ',
              //           style: TextStyle(
              //               color: Colors.black, fontWeight: FontWeight.bold)),
              //       SizedBox(width: 8),
              //       Expanded(
              //         child: Text(
              //           widget.switchBoardUsed?.isNotEmpty == true
              //               ? widget.switchBoardUsed!
              //               : "None",
              //           style: TextStyle(
              //             color: Colors.black,
              //           ),
              //           overflow: TextOverflow.visible,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // SizedBox(height: 20),
              Text('Inverter',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.all(6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Switch Board Used:  ',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.switchBoardUsed?.isNotEmpty == true
                            ? widget.switchBoardUsed!
                            : "None",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.all(6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Expected Inverter Location:  ',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.expectedInverterLocation?.isNotEmpty == true
                            ? widget.expectedInverterLocation!
                            : "None",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.all(6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Inverter Mounting Wall Type:  ',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.mountingWallType?.isNotEmpty == true
                            ? widget.mountingWallType!
                            : "None",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.all(6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Inverter Location Notes:  ',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.inverterLocationNotes?.isNotEmpty == true
                            ? widget.inverterLocationNotes!
                            : "None",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text('Battery',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.all(6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Expected Battery Location:  ',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.expectedBatteryLocation?.isNotEmpty == true
                            ? widget.expectedBatteryLocation!
                            : "None",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.all(6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mounting Type:  ',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.mountingType?.isNotEmpty == true
                            ? widget.mountingType!
                            : "None",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              if (inverterLocationDocumet != null ||
                  switchBoardDocumet != null ||
                  solarPanelDocumet != null)
                ...[
                  Text(
                    'Documents',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (inverterLocationDocumet != null)
                    Padding(
                      padding: EdgeInsets.all(6.0),
                      child: _buildPdfCertificateTile(
                          context, "Inverter Location Photo", inverterLocationDocumet),
                    ),
                  if (switchBoardDocumet != null)
                    Padding(
                      padding: EdgeInsets.all(6.0),
                      child: _buildPdfCertificateTile(
                          context, "Switch Board Photo", switchBoardDocumet),
                    ),
                  if (solarPanelDocumet != null)
                    Padding(
                      padding: EdgeInsets.all(6.0),
                      child: _buildPdfCertificateTile(
                          context, "Solar Panel Layout", solarPanelDocumet),
                    ),
                ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfCertificateTile(
      BuildContext context, String title, MemoryImage? document) {
    return ListTile(
      leading: Icon(Icons.description, color: Colors.blueAccent),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 15),
      onTap: () async {
        if (document != null) {
          String? filePath = await downloadPdf(document);
          if (filePath != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FileViewer(filePath: filePath),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Document is not available')),
            );
          }
        }
      },
    );
  }

  Future<String?> downloadPdf(MemoryImage? image) async {
    if (image == null) return null;
    final byteData = image.bytes;

    try {
      final mimeType = lookupMimeType('', headerBytes: byteData);
      final fileExtension = mimeType?.split('/').last ?? 'dat';

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/document.$fileExtension';
      final file = File(filePath);
      await file.writeAsBytes(byteData);
      print('File saved at $filePath');
      return filePath;
    } catch (e) {
      print('Error writing file: $e');
      return null;
    }
  }
}

class ImageViewer extends StatelessWidget {
  final String filePath;

  ImageViewer({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Document Viewer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Center(
        child: Image.file(
          File(filePath),
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 60),
                Text(
                  'Error loading document',
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class FileViewer extends StatelessWidget {
  final String filePath;

  FileViewer({required this.filePath});

  @override
  Widget build(BuildContext context) {
    final fileExtension = filePath.split('.').last.toLowerCase();
    switch (fileExtension) {
      case 'pdf':
        return PDFViewerPage(documentPath: filePath);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return ImageViewer(filePath: filePath);
      case 'docx':
        return _openFile(filePath);
      default:
        return _openFile(filePath);
    }
  }

  Widget _openFile(String filePath) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Open File',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            requestPermissions();
            final result = await OpenFile.open(filePath);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: Text(
            'Open ${filePath.split('.').last.toUpperCase()} File',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    if (await Permission.manageExternalStorage.request().isGranted) {
    } else {}
  }
}

class PDFViewerPage extends StatelessWidget {
  final String documentPath;

  PDFViewerPage({required this.documentPath});

  @override
  Widget build(BuildContext context) {
    final file = File(documentPath);

    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File does not exist or is corrupted')),
      );
      return Scaffold(
        body: Center(child: Text('Error: File does not exist')),
      );
    }

    print("Valid PDF path: $documentPath");

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PDF Viewer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: PDFView(
        filePath: documentPath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageSnap: true,
        onError: (error) {
          print(error);
          print("444444444444444444444444444444dddddddd");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error loading PDF',
                    style: TextStyle(color: Colors.red))),
          );
        },
        onPageError: (page, error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error loading page $page',
                    style: TextStyle(color: Colors.red))),
          );
        },
      ),
    );
  }
}

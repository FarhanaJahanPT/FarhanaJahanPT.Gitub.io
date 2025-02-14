import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../barcode/product_view.dart';
import '../offline_db/installation_form/product_category.dart';
import '../offline_db/installation_form/product_details.dart';
import '../offline_db/installation_form/project_document.dart';
import '../offline_db/installation_form/worksheet.dart';
import '../offline_db/product_scan/product_sacn.dart';
import '../offline_db/selfies/hive_selfie.dart';
import 'package:intl/intl.dart';

import '../offline_db/selfies/service_hive_selfie.dart';
import '../offline_db/swms/hazard_question.dart';
import '../offline_db/worksheet_document/worksheet_document.dart';

class productsList {
  int? userId;
  List<int> categoryIds = [];
  List<int> worksheetIds = [];
  OdooClient? client;
  String url = "";
  int panel_count = 0;
  int inverter_count = 0;
  int battery_count = 0;
  int totalBarcodeCount = 0;
  int scanned_panel_count = 0;
  int scanned_inverter_count = 0;
  int scanned_battery_count = 0;
  int checklist_total_count = 0;
  int checklistCurrentCount = 0;
  int scannedTotalCount = 0;
  int? worksheetId;
  String premises = '';
  String storeys = '';
  String roof_type = '';
  String wall_type = '';
  String meterBoxPhase = '';
  String serviceType = '';
  String nmi = '';
  String installedOrNot = '';
  String switchBoardUsed = '';
  String expectedInverterLocation = '';
  String mountingWallType = '';
  String inverterLocationNotes = '';
  String expectedBatteryLocation = '';
  String mountingType = '';
  String description = '';
  List<Map<String, String>> productDetailsList = [];
  List<dynamic> categIdList = [];
  List<Map<String, dynamic>> finalCategoryList = [];
  MemoryImage? solarProductImage;
  DateTime? CheckIncreateTime;
  DateTime? MidcreateTime;
  DateTime? CheckOutcreateTime;
  String CheckInImagePath = "";
  String MidImagePath = "";
  String CheckOutImagePath = "";
  bool CheckinRequired = false;
  bool MidRequired = false;
  bool CheckoutRequired = false;
  List<Map<String, dynamic>> productList = [];
  List<ProductDetails> scannedProducts = [];
  Set<int> newProjectIds = {};
  List<Map<String, dynamic>> hazard_question_items = [];
  int uniqueCategId = 0;
  List<dynamic> workTypeIdList = [];

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
    await getProductDetails();
  }

  Future<void> getProductDetails() async {
    print("gggggffffffffffffffffffffff");
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    List<String> productNames = [
      "Panel Serials",
      "Inverter Serials",
      "Battery Serials"
    ];

    try {
      final productFromProject = await client?.callKw({
        'model': 'project.task',
        'method': 'search_read',
        'args': [
          [
            [
              'x_studio_type_of_service',
              'in',
              ['New Installation', 'Service']
            ],
            // ['x_studio_proposed_team', '=', userId],
            ['team_lead_user_id', '=', userId],
            ['worksheet_id', '!=', null]
          ]
        ],
        'kwargs': {
          'fields': [
            'x_studio_product_list',
            'install_signed_by',
            'install_signature',
            'x_studio_3_type_of_premises',
            'x_studio_type_of_service',
            'description',
            'x_studio_customer_notes',
            'x_studio_nmi',
            'x_studio_how_many_storeys',
            'x_studio_exterior_wall_type',
            'x_studio_roof_type',
            'x_studio_meter_box_phase',
            'x_studio_has_existing_system_installed_1',
            'x_studio_switch_board_used_1',
            'x_studio_expected_inverter_location_inverter',
            'x_studio_inverter_mounting_wall_type',
            'x_studio_inverter_location_notes_1',
            'x_studio_expected_battery_location_1',
            'x_studio_mounting_type_1',
          ],
        },
      });
      print("productFromProjectproductFromProjectproductFromProject$productFromProject");
      if (productFromProject != null && productFromProject.isNotEmpty) {
        for (final project in productFromProject) {
          final projectId = project['id'];
          final serviceType = project['x_studio_type_of_service'];

          print('not projectId then $projectId');
          if (!newProjectIds.contains(projectId)) {
            newProjectIds.add(projectId);

            if (serviceType == 'New Installation') {
              print('New Installation serviceType $projectId');
              await _getSelfies(projectId);
            }

            else if (serviceType == 'Service') {
              await _getServiceSelfies(projectId);
              print('Service serviceType $projectId');
            }

          } else {
            continue;
          }
          final worksheet = await client?.callKw({
            'model': 'task.worksheet',
            'method': 'search_read',
            'args': [
              [
                [
                  'x_studio_type_of_service',
                  'in',
                  ['New Installation', 'Service']
                ],
                ['task_id', '=', project['id']],
              ],
            ],
            'kwargs': {
              'fields': [
                'panel_count',
                'inverter_count',
                'battery_count',
                'checklist_count',
                'work_type_ids'
              ],
            },
          });
          print("worksheetworksheetworksheet$worksheet");
          List<dynamic>? checklist;
          List<dynamic>? Servicechecklist;
          if (worksheet.isNotEmpty) {
            workTypeIdList = worksheet[0]['work_type_ids'];
            print(workTypeIdList);
            print("workTypeIdListworkTypeIdListworkTypeIdList");
            for (String productName in productNames) {
              print(productName);
              print("ddddddddddddddddddddddddddddddwwwwwwwwwwwwwwwwwwwwwwwwdddddddddddddd");
              String type = '';
              if (productName == "Panel Serials") type = 'panel';
              if (productName == "Inverter Serials") type = 'inverter';
              if (productName == "Battery Serials") type = 'battery';
              print(type);
              print(worksheet[0]['id']);
              print(userId);
              print(client);
              print("typetypetypetypetypetype");
              try {
                final scanningProducts = await client?.callKw({
                  'model': 'stock.lot',
                  'method': 'search_read',
                  'args': [
                    [
                      ['worksheet_id', '=', worksheet[0]['id']],
                      ['type', '=', type],
                      ['user_id', '=', userId],
                    ],
                  ],
                  'kwargs': {},
                });
                print(
                    "scanningProductsscanningProductsscanningProducts$scanningProducts");
                if (scanningProducts != null && scanningProducts.isNotEmpty) {
                  List<CachedScannedProduct> cacheProducts = [];

                  for (var product in scanningProducts) {
                    String serialNumber = product['name'];
                    String name = product['product_id'][1];
                    int productId = product['product_id'][0];
                    int categId = product['categ_id'][0];
                    print("hiiiiiiiiiiiiiiiiiiiiiiiiiiiiiicccc");
                    final parentCategList = await client?.callKw({
                      'model': 'product.category',
                      'method': 'search_read',
                      'args': [
                        [
                          ['id', '=', categId],
                          ['parent_id', '!=', false]
                        ],
                      ],
                      'kwargs': {
                        'fields': ['id', 'parent_id']
                      },
                    });
                    print(parentCategList);
                    print("parentCategListparentCategListparentCategList");
                    int parentCategId = 0;
                    if (parentCategList != null && parentCategList.isNotEmpty) {
                      final parentCateg = parentCategList[0];
                      if (parentCateg.containsKey('parent_id') &&
                          parentCateg['parent_id'] != null &&
                          parentCateg['parent_id'] is List &&
                          parentCateg['parent_id'].isNotEmpty) {
                        parentCategId = parentCateg['parent_id'][0];
                      }
                    }
                    uniqueCategId = 0;
                    if (parentCategId == 1) {
                      uniqueCategId = categId;
                    } else {
                      uniqueCategId = parentCategId;
                    }
                    int? previousScannedCategId;
                    if (uniqueCategId != previousScannedCategId) {
                      // scannedProducts.clear();
                      previousScannedCategId = uniqueCategId;
                    }
                    int quantity = product['product_qty'].toInt();
                    Uint8List imageData = base64Decode(product['image']);
                    String unitPrice = product.containsKey('unit_price')
                        ? product['unit_price'].toString()
                        : '0.0';
                    String state = product['state'];
                    scannedProducts.add(ProductDetails(
                      serialNumber: serialNumber,
                      name: name,
                      unitPrice: unitPrice,
                      imageData: imageData,
                      quantity: quantity,
                      productId: productId,
                      state: state,
                    ));

                    cacheProducts.add(CachedScannedProduct(
                      serialNumber: serialNumber,
                      name: name,
                      unitPrice: unitPrice,
                      state: state,
                      imageData: imageData,
                      quantity: quantity,
                      productId: productId,
                    ));
                    // await saveScannedProductListToHive(
                    //     worksheet[0]['id'], type, uniqueCategId);
                  }

                  await saveScannedProductListToHive(
                      worksheet[0]['id'], type, uniqueCategId);
                  scannedProducts.clear();
                } else {}
              }catch(r){
                print("rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrcccccccccccccccccc$r");
              }
            }
            checklist = await client?.callKw({
              'model': 'installation.checklist.item',
              'method': 'search_read',
              'args': [
                [
                  ['worksheet_id', '=', worksheet[0]['id']],
                ],
              ],
              'kwargs': {
                'fields': ['id', 'display_name'],
              },
            });
            Servicechecklist = await client?.callKw({
              'model': 'service.checklist.item',
              'method': 'search_read',
              'args': [
                [
                  ['worksheet_id', '=', worksheet[0]['id']],
                ],
              ],
              'kwargs': {
                'fields': ['id', 'display_name'],
              },
            });
            panel_count = worksheet[0]['panel_count'];
            inverter_count = worksheet[0]['inverter_count'];
            battery_count = worksheet[0]['battery_count'];
            checklistCurrentCount = checklist?.length ?? Servicechecklist?.length??0;
            checklist_total_count = worksheet[0]['checklist_count'];
            totalBarcodeCount = (worksheet[0]['panel_count'] ?? 0) +
                (worksheet[0]['inverter_count'] ?? 0) +
                (worksheet[0]['battery_count'] ?? 0);
            final lotData = await client?.callKw({
              'model': 'stock.lot',
              'method': 'search_read',
              'args': [
                [
                  ['worksheet_id', '=', worksheet[0]['id']],
                  ['user_id', '=', userId],
                ],
              ],
              'kwargs': {
                'fields': ['type'],
              },
            });

            if (lotData != null && lotData.isNotEmpty) {
              int panelCount = 0;
              int inverterCount = 0;
              int batteryCount = 0;

              for (var lot in lotData) {
                switch (lot['type']) {
                  case 'panel':
                    panelCount++;
                    break;
                  case 'inverter':
                    inverterCount++;
                    break;
                  case 'battery':
                    batteryCount++;
                    break;
                  default:
                    break;
                }
              }
              scanned_panel_count = panelCount;
              scanned_inverter_count = inverterCount;
              scanned_battery_count = batteryCount;
              scannedTotalCount = (panelCount + inverterCount + batteryCount);
            } else{
              scanned_panel_count = 0;
              scanned_inverter_count = 0;
              scanned_battery_count = 0;
              scannedTotalCount = 0;
            }
            Worksheet newWorksheet = Worksheet(
              id: worksheet[0]['id'],
              panelCount: panel_count ?? 0,
              inverterCount: inverter_count ?? 0,
              batteryCount: battery_count ?? 0,
              checklistCount: checklist_total_count ?? 0,
              scannedPanelCount: scanned_panel_count ?? 0,
              scannedInverterCount: scanned_inverter_count ?? 0,
              scannedBatteryCount: scanned_battery_count ?? 0,
              checklistCurrentCount: checklistCurrentCount ?? 0,
            );
            final box = await Hive.openBox<Worksheet>('worksheets');
            await box.put(newWorksheet.id, newWorksheet);
          }


          if (productFromProject[0]['x_studio_3_type_of_premises'] is String) {
            premises = productFromProject[0]['x_studio_3_type_of_premises'];
          }

          if (productFromProject[0]['x_studio_how_many_storeys'] is String) {
            storeys = productFromProject[0]['x_studio_how_many_storeys'];
          }

          if (productFromProject[0]['x_studio_exterior_wall_type'] is String) {
            wall_type = productFromProject[0]['x_studio_exterior_wall_type'];
          }

          if (productFromProject[0]['x_studio_roof_type'] is String) {
            roof_type = productFromProject[0]['x_studio_roof_type'];
          }

          if (productFromProject[0]['x_studio_meter_box_phase'] is String) {
            meterBoxPhase = productFromProject[0]['x_studio_meter_box_phase'];
          }

          // if (productFromProject[0]['x_studio_type_of_service'] is String) {
          //   serviceType = productFromProject[0]['x_studio_type_of_service'];
          // }

          if (productFromProject[0]['x_studio_nmi'] is String) {
            nmi = productFromProject[0]['x_studio_nmi'];
          }

          if (productFromProject[0]
          ['x_studio_expected_inverter_location_inverter'] is String) {
            expectedInverterLocation = productFromProject[0]
            ['x_studio_expected_inverter_location_inverter'];
          }

          if (productFromProject[0]['x_studio_inverter_mounting_wall_type']
          is String) {
            mountingWallType =
            productFromProject[0]['x_studio_inverter_mounting_wall_type'];
          }

          if (productFromProject[0]['x_studio_inverter_location_notes_1']
          is String) {
            inverterLocationNotes =
            productFromProject[0]['x_studio_inverter_location_notes_1'];
          }

          if (productFromProject[0]['x_studio_expected_battery_location_1']
          is String) {
            expectedBatteryLocation =
            productFromProject[0]['x_studio_expected_battery_location_1'];
          }

          if (productFromProject[0]['x_studio_mounting_type_1'] is String) {
            mountingType = productFromProject[0]['x_studio_mounting_type_1'];
          }

          if (productFromProject[0]['x_studio_switch_board_used_1'] is String) {
            switchBoardUsed =
            productFromProject[0]['x_studio_switch_board_used_1'];
          }

          if (productFromProject[0]['x_studio_has_existing_system_installed_1']
          is String) {
            installedOrNot =
            productFromProject[0]['x_studio_has_existing_system_installed_1'];
          }

          // if (productFromProject[0]['description'] is String) {
          //   description = productFromProject[0]['description']
          //       .replaceAll('<p>', '')
          //       .replaceAll('</p>', '')
          //       .replaceAll('<br>', '')
          //       .replaceAll('&amp;', '&');
          // }

          if (productFromProject[0]['x_studio_customer_notes'] is String) {
            description = productFromProject[0]['x_studio_customer_notes']
                .replaceAll('<p>', '')
                .replaceAll('</p>', '')
                .replaceAll('<br>', '')
                .replaceAll('&amp;', '&');
          }
          if (productFromProject != null && productFromProject.isNotEmpty) {
            if (project is Map) {
              final orderLine = project['x_studio_product_list'];
              if (orderLine != null && orderLine.isNotEmpty) {
                productDetailsList = [];
                try {
                  for (var order in orderLine) {
                    final productDetails = await client?.callKw({
                      'model': 'sale.order.line',
                      'method': 'search_read',
                      'args': [
                        [
                          ['id', '=', order],
                        ]
                      ],
                      'kwargs': {
                        'fields': [
                          'product_id',
                          'product_uom_qty',
                          'name',
                          'state'
                        ],
                      },
                    });

                    if (productDetails != null && productDetails.isNotEmpty) {
                      var productIdData = productDetails[0]['product_id'];
                      if (productIdData is List && productIdData.isNotEmpty) {
                        final productId = productDetails[0]['product_id'][0];

                        final productImage = await client?.callKw({
                          'model': 'product.product',
                          'method': 'search_read',
                          'args': [
                            [
                              ['id', '=', productId],
                            ]
                          ],
                          'kwargs': {
                            'fields': ['image_1920', 'name', 'categ_id','type'],
                          },
                        });
                        final productSerial = await client?.callKw({
                          'model': 'stock.lot',
                          'method': 'search_read',
                          'args': [
                            [
                              ['product_id', '=', productId],
                            ]
                          ],
                          'kwargs': {
                            'fields': ['name'],
                          },
                        });

                        print('productSerial  :  $productSerial');
                        if (productImage != null && productImage.isNotEmpty) {
                          final type = productImage[0]['type'];
                          final image = productImage[0];
                          if (image['image_1920'] is String) {
                            final imageBase64 = image['image_1920'] as String;
                            if (imageBase64.isNotEmpty) {
                              final imageData = base64Decode(imageBase64);
                              solarProductImage =
                                  MemoryImage(Uint8List.fromList(imageData));
                            }
                          } else {
                            solarProductImage =
                                MemoryImage(Uint8List.fromList([]));
                          }

                          if (image['categ_id'] != null) {
                            if (!categIdList.contains(image['categ_id'][0])) {
                              categIdList.add(image['categ_id'][0]);
                            }
                            final categoryDetails = await client?.callKw({
                              'model': 'product.category',
                              'method': 'search_read',
                              'args': [
                                [
                                  ['id', '=', image['categ_id'][0]],
                                ]
                              ],
                              'kwargs': {
                                'fields': ['name', 'parent_id']
                              },
                            });

                            if (categoryDetails != null &&
                                categoryDetails.isNotEmpty) {
                              for (var category in categoryDetails) {
                                final categoryName = category['name'];
                                final categoryId = category['id'];
                                String? parentCategoryName;

                                if (category['parent_id'] != null &&
                                    category['parent_id'] is List &&
                                    category['parent_id'].isNotEmpty) {
                                  final parentCategoryId =
                                  category['parent_id'][0];
                                  final parentCategoryDetails =
                                  await client?.callKw({
                                    'model': 'product.category',
                                    'method': 'search_read',
                                    'args': [
                                      [
                                        ['id', '=', parentCategoryId],
                                        [
                                          'name',
                                          'in',
                                          [
                                            'Inverters',
                                            'Solar Panels',
                                            'Storage'
                                          ]
                                        ],
                                      ]
                                    ],
                                    'kwargs': {
                                      'fields': ['name']
                                    },
                                  });

                                  if (parentCategoryDetails != null &&
                                      parentCategoryDetails.isNotEmpty) {
                                    parentCategoryName =
                                    parentCategoryDetails[0]['name'];
                                    if (['Inverters', 'Solar Panels', 'Storage']
                                        .contains(parentCategoryName)) {
                                      finalCategoryList.add({
                                        'id': parentCategoryId,
                                        'name': parentCategoryName,
                                      });
                                    }
                                  }
                                }
                                if (['Inverters', 'Solar Panels', 'Storage']
                                    .contains(categoryName)) {
                                  if (categoryName != parentCategoryName) {
                                    finalCategoryList.add({
                                      'name': categoryName,
                                      'id': categoryId,
                                    });
                                  }
                                }
                              }
                            }
                          }

                          String productName = productIdData.length > 1
                              ? productImage[0]['name']
                              : 'Unknown Product';
                          final base64Image = solarProductImage != null
                              ? base64Encode(solarProductImage!.bytes)
                              : 'null';
                          print("444444444eddddddddddd$projectId");
                          if (productSerial.isNotEmpty) {
                            productDetailsList.add({
                              'id': productDetails[0]['id'].toString(),
                              'quantity':
                              productDetails[0]['product_uom_qty'].toString(),
                              'model': productName,
                              'type': type,
                              'manufacturer': productDetails[0]['name'],
                              'image': base64Image,
                              'state': productDetails[0]['state'] ?? '',
                            });
                          }
                        }
                        final productCategoryId =
                        productImage[0]['categ_id'] != null
                            ? productImage[0]['categ_id'][0]
                            : 0;
                        final categoryScanningDetails = await client?.callKw({
                          'model': 'product.category',
                          'method': 'search_read',
                          'args': [
                            [
                              '|',
                              ['id', '=', productCategoryId],
                              ['parent_id', '=', productCategoryId]
                            ]
                          ],
                          'kwargs': {
                            'fields': ['name', 'parent_id'],
                          },
                        });
                        if (categoryScanningDetails != null &&
                            categoryScanningDetails.isNotEmpty) {
                          final categoryId = categoryScanningDetails[0]['id'];
                          final parentCategoryId =
                          categoryScanningDetails[0]['parent_id'] != null &&
                              categoryScanningDetails[0]['parent_id']
                              is List
                              ? categoryScanningDetails[0]['parent_id'][0]
                              : null;
                          bool categoryMatch = finalCategoryList.any(
                                  (category) =>
                              category['id'] == categoryId ||
                                  category['id'] == parentCategoryId);
                          int uniqueCategId = 0;
                          if (parentCategoryId == null ||
                              parentCategoryId == 1) {
                            uniqueCategId = categoryId;
                          } else {
                            uniqueCategId = parentCategoryId ?? 0;
                          }
                          int? previousCategId;
                          if (uniqueCategId != previousCategId) {
                            productList.clear();
                            previousCategId = uniqueCategId;
                          }
                          if (categoryMatch) {
                            productList.add({
                              'image': productImage[0]['image_1920'],
                              'name': productImage[0]['name'],
                              'description': productImage[0]['description'],
                              'default_code': productImage[0]['default_code'],
                              'qty_product': productDetails[0]
                              ['product_uom_qty']
                            });
                            print(productList);
                            print(finalCategoryList);
                            print("finalCategoryListfinalCategoryListfinalCategoryListfinalCategoryListfinalCategoryList");
                          }
                          await saveProductListToHive(
                              project['id'], uniqueCategId);
                          await saveWorksheetDocumentsToHive(project['id']);
                        }
                      }
                    }
                  }
                } catch (e) {
                }
              }
            } else {}
          } else {}
          await saveCategoryListToHive(projectId);
          await saveSelfieCategoryListToHive(projectId);
          await saveProductDetailsToHive(projectId);
          await getChecklist(projectId);
          await getHazardQuestions(projectId);
          await getServiceChecklist(projectId);
        }
      }
      print('end the game');
    } catch (e) {
      print("tttttttttttttttttttttttttttttttttttttttt$e");
    }
  }

  Future<void> saveWorksheetDocumentsToHive(int projectId) async {
    print("Starting to save worksheet document...");
    Box<WorksheetDocument>? box;
    try {
      // Open the Hive box for worksheet documents
      box = await Hive.openBox<WorksheetDocument>('worksheetDocumentBox');

      // Clear previous data
      await box.clear();

      // Create a WorksheetDocument object with the required data
      WorksheetDocument productInfo = WorksheetDocument(
        premises: premises,
        storeys: storeys,
        wallType: wall_type,
        roofType: roof_type,
        meterBoxPhase: meterBoxPhase,
        serviceType: serviceType,
        nmi: nmi,
        expectedInverterLocation: expectedInverterLocation,
        mountingWallType: mountingWallType,
        inverterLocationNotes: inverterLocationNotes,
        expectedBatteryLocation: expectedBatteryLocation,
        mountingType: mountingType,
        switchBoardUsed: switchBoardUsed,
        installedOrNot: installedOrNot,
        description: description,
      );

      print("Saving worksheet document to box...");
      // Save the worksheet document to the box
      await box.put(projectId, productInfo);
      print("Worksheet document saved successfully.");
    } catch (e) {
      print("Error while saving worksheet document: $e");
    } finally {
      // Ensure the box is always closed, even if an error occurs
      if (box != null && box.isOpen) {
        await box.close();
        print("Hive box closed successfully.");
      }
    }
  }


  // Future<void> saveWorksheetDocumentsToHive(int projectId) async {
  //   print("bbbbbbbbbbbbbbbbbbbbbbbbf");
  //   try {
  //     final box = await Hive.openBox<WorksheetDocument>('worksheetDocumentBox');
  //     await box.clear();
  //
  //     WorksheetDocument productInfo = WorksheetDocument(
  //       premises: premises,
  //       storeys: storeys,
  //       wallType: wall_type,
  //       roofType: roof_type,
  //       meterBoxPhase: meterBoxPhase,
  //       serviceType: serviceType,
  //       nmi: nmi,
  //       expectedInverterLocation: expectedInverterLocation,
  //       mountingWallType: mountingWallType,
  //       inverterLocationNotes: inverterLocationNotes,
  //       expectedBatteryLocation: expectedBatteryLocation,
  //       mountingType: mountingType,
  //       switchBoardUsed: switchBoardUsed,
  //       installedOrNot: installedOrNot,
  //       description: description,
  //     );
  //     print("vgggggggggggggggggggggggggggggggg");
  //     await box.put(projectId,productInfo);
  //   } catch (e) {
  //     print("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee$e");
  //   }
  // }

  Future<void> saveScannedProductListToHive(
      int worksheetId, String type, int categId) async {
    print('categId  $categId');
    try {

      final box = await Hive.openBox<CachedScannedProduct>(
          'cachedScannedProductsBox_${worksheetId}_${type}_${categId}');

      if (scannedProducts.isEmpty) {
        return;
      }


      for (var product in scannedProducts) {
        final productKey = product.serialNumber;

        if (box.containsKey(productKey)) {
          continue;
        }

        final cachedProduct = CachedScannedProduct(
          serialNumber: product.serialNumber,
          name: product.name,
          unitPrice: product.unitPrice,
          state: product.state,
          imageData: product.imageData != null ? Uint8List.fromList(product.imageData!) : null,
          quantity: product.quantity,
          productId: product.productId,
        );

        await box.put(productKey, cachedProduct);
      }

    } catch (e) {
      print('Caught an error while saving products: $e');
    }
  }

  // Future<void> saveScannedProductListToHive(
  //     int projectId, String type, int categId) async {
  //   try {
  //     final box = await Hive.openBox<CachedScannedProduct>(
  //         'cachedScannedProductsBox_${projectId}_${type}_${categId}');
  //
  //     if (scannedProducts.isEmpty) {
  //       return;
  //     }
  //
  //     for (var product in scannedProducts) {
  //       final productKey = product.productId;
  //
  //       if (box.containsKey(productKey)) {
  //         continue;
  //       }
  //
  //       final cachedProduct = CachedScannedProduct(
  //         serialNumber: product.serialNumber,
  //         name: product.name,
  //         unitPrice: product.unitPrice,
  //         state: product.state,
  //         imageData: product.imageData?.toList(),
  //         quantity: product.quantity,
  //         productId: product.productId,
  //       );
  //
  //       await box.put(productKey, cachedProduct);
  //     }
  //   } catch (e) {
  //   }
  // }


  Future<void> getChecklist(projectId) async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    final checklistBox = await Hive.openBox('ChecklistBox');

    try {
      final checklist = await client?.callKw({
        'model': 'installation.checklist',
        'method': 'search_read',
        'args': [
          [
            ['category_ids', 'in', categIdList],
            [
              'selfie_type',
              'in',
              ['check_in', 'mid', 'check_out']
            ],
            ['group_ids','in', workTypeIdList]
          ]
        ],
        'kwargs': {},
      });
      final checklistTypes = (checklist as List)
          .map((item) => item['selfie_type'] as String)
          .toList();
      print("progressChangeprogressChangeprogressChange$checklistTypes");
      final checklistTypesBox = await Hive.openBox('ChecklistBox_$projectId');
      await checklistTypesBox.put('checklistTypes', checklistTypes);
    } catch (e) {}
  }

  // Future<void> getHazardQuestions(int projectId) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   userId = prefs.getInt('userId') ?? 0;
  //   try {
  //     print(categIdList);
  //     print("fffffffffcccffffffffffffffffffwidgettttttttttt");
  //     final hazardQuestionDetails = await client?.callKw({
  //       'model': 'swms.risk.register',
  //       'method': 'search_read',
  //       'args': [[]],
  //       'kwargs': {
  //         'fields': [
  //           'id',
  //           'installation_question',
  //           'risk_control',
  //           'category_id'
  //         ],
  //       },
  //     });
  //     print("hazardQuestionDetailshazardQuestionDetails$hazardQuestionDetails");
  //     if (hazardQuestionDetails != null && hazardQuestionDetails.isNotEmpty) {
  //
  //       hazard_question_items =
  //       List<Map<String, dynamic>>.from(hazardQuestionDetails);
  //       saveHazardQuestion(hazard_question_items,projectId);
  //     } else {
  //       print("No hazard questions found.");
  //     }
  //   } catch (e) {
  //     print("Error fetching hazard questions: $e");
  //   }
  // }

  Future<void> getHazardQuestions(int projectId) async {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;

      try {
        List<int> categoryIds = [];

        print(categIdList);
        print("Start fetching category details");

        for (var item in categIdList) {
          print("Fetching category for ID: $item");

          final categoryDetails = await client?.callKw({
            'model': 'product.category',
            'method': 'search_read',
            'args': [
              [
                ['id', '=', item],
              ]
            ],
            'kwargs': {
              'fields': ['id', 'parent_id'],
            },
          });

          if (categoryDetails != null && categoryDetails.isNotEmpty) {
            for (var detail in categoryDetails) {
              if (detail['id'] != null) categoryIds.add(detail['id']);
              if (detail['parent_id'] != null && detail['parent_id'] is List) {
                categoryIds.add(detail['parent_id'][0]);
              }
            }
          }

          print("Fetched category details: $categoryDetails");
        }

        print("All category IDs and parent IDs: $categoryIds");

        final hazardQuestionDetails = await client?.callKw({
          'model': 'swms.risk.register',
          'method': 'search_read',
          'args': [[]],
          'kwargs': {
            'fields': ['id', 'installation_question', 'risk_control', 'category_id', 'job_activity'],
          },
        });

        if (hazardQuestionDetails != null && hazardQuestionDetails.isNotEmpty) {
          print("Fetched hazard questions: $hazardQuestionDetails");

          hazard_question_items = List<Map<String, dynamic>>.from(hazardQuestionDetails.where((question) {
            final categoryId = question['category_id'];
            if (categoryId != null && categoryId is List) {
              return categoryIds.contains(categoryId[0]);
            }
            return false;
          }));
          saveHazardQuestion(hazard_question_items,projectId);

          print("Filtered hazard questions: $hazard_question_items");
        } else {
          print("No hazard questions found.");
        }

      } catch (e) {
        print("Error fetching hazard questions: $e");
      }
  }

  // Future<void> saveHazardQuestion(List<Map<String, dynamic>> hazardQuestionItems, int projectId) async {
  //   try {
  //     var box = await Hive.openBox<HazardQuestion>('hazardQuestions_$projectId');
  //     for (var item in hazardQuestionItems) {
  //       int categoryId = (item['category_id'] is List) ? item['category_id'][0] : item['category_id'];
  //
  //       HazardQuestion hazardQuestion = HazardQuestion(
  //         id: item['id'],
  //         installationQuestion: item['installation_question'],
  //         riskControl: item['risk_control'],
  //         categoryId: categoryId,
  //       );
  //       await box.add(hazardQuestion);
  //     }
  //     print("Hazard questions saved to Hive successfully.");
  //   } catch (e) {
  //     print("Error while saving hazard questions to Hive: $e");
  //   }
  // }

  Future<void> saveHazardQuestion(List<Map<String, dynamic>> hazardQuestionItems, int projectId) async {
    Box<HazardQuestion>? box;

    try {
      // Open the Hive box
      box = await Hive.openBox<HazardQuestion>('hazardQuestions_$projectId');

      for (var item in hazardQuestionItems) {
        int categoryId = (item['category_id'] is List) ? item['category_id'][0] : item['category_id'];

        HazardQuestion hazardQuestion = HazardQuestion(
          id: item['id'],
          installationQuestion: item['installation_question'],
          job_activity: item['job_activity'],
          riskControl: item['risk_control'],
          categoryId: categoryId,
        );
        await box.add(hazardQuestion);
      }

      print("Hazard questions saved to Hive successfully.");
    } catch (e) {
      print("Error while saving hazard questions to Hive: $e");
    } finally {
      // Close the Hive box if it's open
      if (box != null && box.isOpen) {
        await box.close();
        print('hazardQuestions_$projectId box closed successfully.');
      }
    }
  }

  Future<void> getServiceChecklist(projectId) async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    final checklistBox = await Hive.openBox('ChecklistBox');

    try {
      final checklist = await client?.callKw({
        'model': 'service.checklist',
        'method': 'search_read',
        'args': [
          [
            ['category_ids', 'in', categIdList],
            [
              'selfie_type',
              'in',
              ['check_in', 'mid', 'check_out']
            ],
            ['group_ids','in', workTypeIdList]
          ]
        ],
        'kwargs': {},
      });
      final checklistTypes = (checklist as List)
          .map((item) => item['selfie_type'] as String)
          .toList();
      final checklistTypesBox = await Hive.openBox('ServiceChecklistBox_$projectId');
      await checklistTypesBox.put('checklistTypes', checklistTypes);
    } catch (e) {}
  }

  Future<void> saveCategoryListToHive(int projectId) async {
    Box<List<dynamic>>? box;
    try {
      box = await Hive.openBox<List<dynamic>>('categories');

      List<Category> categoryList = finalCategoryList.map((category) {
        return Category(
          id: category['id'] as int,
          name: category['name'] as String,
        );
      }).toList();

      await box.put(projectId, categoryList);
    } catch (e) {
      print("Error: $e");
    } finally {
      if (box != null && box.isOpen) {
        await box.close();
      }
    }
  }


  // Future<void> saveCategoryListToHive(int projectId) async {
  //   try {
  //     final box = await Hive.openBox<List<dynamic>>('categories');
  //     List<Category> categoryList = finalCategoryList.map((category) {
  //       return Category(
  //         id: category['id'] as int,
  //         name: category['name'] as String,
  //       );
  //     }).toList();
  //     await box.put(projectId, categoryList);
  //   } catch (e) {
  //   }
  // }

  Future<void> saveSelfieCategoryListToHive(int projectId) async {
    try {
      final box = await Hive.openBox<List<CategoryDetail>>('categoriesIdList_$projectId');
      print("categIdListeeeeeeeeeeeeeeeeeeeee/$projectId");

      List<CategoryDetail> categoryList = categIdList.map((categoryId) {
        return CategoryDetail(
          id: categoryId,
          name: 'Category $categoryId',
        );
      }).toList();

      categoryList = categoryList.toSet().toList();

      await box.put(projectId, categoryList);

      print(box.values);
      print("hiiiiiiiiiiiiiiii");
    } catch (e) {
      print("Error: $e");
    } finally {
      await Hive.close();
    }
  }


  // Future<void> saveProductDetailsToHive(int projectId) async {
  //   print('hi in saveProductDetailsToHive');
  //   try {
  //     var box = await Hive.openBox<List<dynamic>>('productDetailsBox');
  //     print(projectId);
  //     print(productDetailsList);
  //     print("productDetailsListproductDetailsListffff");
  //     List<ProductDetail> productList = productDetailsList.map((product) {
  //       return ProductDetail(
  //         id: product['id'] ?? '',
  //         quantity: product['quantity'] ?? '',
  //         type: product['type'] ?? '',
  //         model: product['model'] ?? '',
  //         manufacturer: product['manufacturer'] ?? '',
  //         image: product['image'] ?? '',
  //         state: product['state'] ?? '',
  //       );
  //     }).toList();
  //     await box.put(projectId, productList);
  //   } catch (e) {
  //     print('saveProductDetailsToHive error catch $e');
  //   }
  // }

  Future<void> saveProductDetailsToHive(int projectId) async {
    print('Starting to save product details to Hive...');
    Box<List<dynamic>>? box;
    try {
      box = await Hive.openBox<List<dynamic>>('productDetailsBox');
      print('Project ID: $projectId');
      print('Product details list: $productDetailsList');

      List<ProductDetail> productList = productDetailsList.map((product) {
        return ProductDetail(
          id: product['id'] ?? '',
          quantity: product['quantity'] ?? '',
          type: product['type'] ?? '',
          model: product['model'] ?? '',
          manufacturer: product['manufacturer'] ?? '',
          image: product['image'] ?? '',
          state: product['state'] ?? '',
        );
      }).toList();

      print("Mapped product list: $productList");
      await box.put(projectId, productList);
      print('Product details saved successfully.');
    } catch (e) {
      print('Error while saving product details to Hive: $e');
    } finally {
      // Ensure the box is always closed, even if an error occurs
      if (box != null && box.isOpen) {
        await box.close();
        print('Hive box closed successfully.');
      }
    }
  }

  Future<void> _getSelfies(int projectId) async {
    try {
      final selfies = await client?.callKw({
        'model': 'installation.checklist',
        'method': 'search_read',
        'args': [
          [
            ['category_ids', 'in', categIdList],
            ['selfie_type', '!=', false],
            ['group_ids','in', workTypeIdList]
          ],
        ],
        'kwargs': {},
      });
      if (selfies == null || selfies.isEmpty) {
        return;
      }
      List selfieItems = [];
      final worksheet = await client?.callKw({
        'model': 'task.worksheet',
        'method': 'search_read',
        'args': [
          [
            ['task_id', '=', projectId],
          ],
        ],
        'kwargs': {},
      });
      if (worksheet != null && worksheet.isNotEmpty) {
        worksheetId = worksheet[0]['id'];
        final box = await Hive.openBox<HiveSelfie>('selfiesBox_$projectId');
        for (var selfie in selfies) {
          final selfiesList = await client?.callKw({
            'model': 'installation.checklist.item',
            'method': 'search_read',
            'args': [
              [
                ['worksheet_id', '=', worksheetId],
                ['user_id', '=', userId],
                ['checklist_id', '=', selfie['id']],
              ],
            ],
            'kwargs': {},
          });
          if (selfiesList == null || selfiesList.isEmpty) {
            continue;
          }
          print(selfiesList);
          print("selfiesListselfiesListselfiesList");
          selfieItems.addAll(selfiesList);

          DateTime createTime =
          DateTime.parse(selfiesList[0]['create_date']).toLocal();
          var localCreateTime = createTime.toLocal();
          DateTime parsedDate =
          DateTime.parse(selfiesList[0]['create_date']).toLocal();
          String formattedDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(parsedDate);
          for (var item in selfiesList) {
            DateTime createTime = DateTime.parse(item['create_date']).toLocal();

            final hiveSelfie = HiveSelfie(
                id: item['id'],
                image: item['image'],
                selfieType: selfie['selfie_type'],
                createTime: createTime,
                worksheetId: worksheetId!
            );
            box.add(hiveSelfie);
          }
          if (selfie['selfie_type'] == 'check_in') {
            CheckIncreateTime = localCreateTime;
            CheckInImagePath = selfiesList[0]['image'];
            if (CheckInImagePath != null && CheckInImagePath.isNotEmpty) {
              CheckinRequired = true;
            }
          }

          if (selfie['selfie_type'] == 'mid') {
            MidcreateTime = localCreateTime;
            MidImagePath = selfiesList[0]['image'];
            if (MidImagePath != null && MidImagePath.isNotEmpty) {
              MidRequired = true;
            }
          }

          if (selfie['selfie_type'] == 'check_out') {
            CheckOutcreateTime = localCreateTime;
            CheckOutImagePath = selfiesList[0]['image'];
            if (CheckOutImagePath != null && CheckOutImagePath.isNotEmpty) {
              CheckoutRequired = true;
            }
          }
        }
      }
    } catch (e) {}
  }


  Future<void> _getServiceSelfies(int projectId) async {
    try {
      final selfies = await client?.callKw({
        'model': 'service.checklist',
        'method': 'search_read',
        'args': [
          [
            ['category_ids', 'in', categIdList],
            ['selfie_type', '!=', false],
            ['group_ids','in', workTypeIdList]
          ],
        ],
        'kwargs': {},
      });
      print(selfies);
      print("selfiesselfiehhhhhhhhhhhhhhhhhsselfies");
      if (selfies == null || selfies.isEmpty) {
        return;
      }
      List selfieItems = [];
      final worksheet = await client?.callKw({
        'model': 'task.worksheet',
        'method': 'search_read',
        'args': [
          [
            ['task_id', '=', projectId],
          ],
        ],
        'kwargs': {},
      });
      if (worksheet != null && worksheet.isNotEmpty) {
        worksheetId = worksheet[0]['id'];
        final box = await Hive.openBox<HiveServiceSelfie>('selfiesBox_$projectId');
        for (var selfie in selfies) {
          print(selfie);
          print("75666666666666666666666666");
          final selfiesList = await client?.callKw({
            'model': 'service.checklist.item',
            'method': 'search_read',
            'args': [
              [
                ['worksheet_id', '=', worksheetId],
                ['user_id', '=', userId],
                ['service_id', '=', selfie['id']],
              ],
            ],
            'kwargs': {},
          });
          print("89999999999999999999999999999994444444444444");
          if (selfiesList == null || selfiesList.isEmpty) {
            continue;
          }

          selfieItems.addAll(selfiesList);
          print(selfiesList);
          print("selfiesselfiesListListselfiesList");
          DateTime createTime =
          DateTime.parse(selfiesList[0]['create_date']).toLocal();
          print("$createTime/cgvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv");
          var localCreateTime = createTime.toLocal();
          DateTime parsedDate =
          DateTime.parse(selfiesList[0]['create_date']).toLocal();
          String formattedDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(parsedDate);
          for (var item in selfiesList) {
            print('item,mmmmmmmmmmmmmmmmmmmmm$item');
            DateTime createTime = DateTime.parse(item['create_date']).toLocal();
            print("$createTime/fghhhhhhhhhhhhhhhhhh");
            final hiveSelfie = HiveServiceSelfie(
                id: item['id'],
                image: item['image'],
                selfieType: selfie['selfie_type'],
                createTime: createTime,
                worksheetId: worksheetId!
            );
            box.add(hiveSelfie);
            print(box);
            // print(box.values);
            print("iiiiiiiiiiiiiiiiiiiiiiii");
          }
          if (selfie['selfie_type'] == 'check_in') {
            CheckIncreateTime = localCreateTime;
            CheckInImagePath = selfiesList[0]['image'];
            if (CheckInImagePath != null && CheckInImagePath.isNotEmpty) {
              CheckinRequired = true;
            }
          }

          if (selfie['selfie_type'] == 'mid') {
            MidcreateTime = localCreateTime;
            MidImagePath = selfiesList[0]['image'];
            if (MidImagePath != null && MidImagePath.isNotEmpty) {
              MidRequired = true;
            }
          }

          if (selfie['selfie_type'] == 'check_out') {
            CheckOutcreateTime = localCreateTime;
            CheckOutImagePath = selfiesList[0]['image'];
            if (CheckOutImagePath != null && CheckOutImagePath.isNotEmpty) {
              CheckoutRequired = true;
            }
          }
        }
      }
    } catch (e) {}
  }

  Future<void> saveProductListToHive(int projectId, int categId) async {
    Box<CachedProduct>? box;
    try {
      // Open the Hive box for the specific product list
      box = await Hive.openBox<CachedProduct>('barcode_product_${projectId}_${categId}');

      for (var product in productList) {
        final productKey = product['default_code'] ?? product['name'];

        // Skip if the product already exists in the box
        if (box.containsKey(productKey)) {
          continue;
        }

        final productModel = CachedProduct(
          image: product['image'] is String ? product['image'] : '',
          name: product['name'] is String ? product['name'] : '',
          description: product['description'] is String ? product['description'] : '',
          defaultCode: product['default_code'] is String ? product['default_code'] : '',
          qtyProduct: (product['qty_product'] is num ? product['qty_product'] : 0).toDouble(),
        );

        await box.put(productKey, productModel);
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      // Close the box, ensuring no resources are left open
      if (box != null && box.isOpen) {
        await box.close();
      }
    }
  }

  // Future<void> saveProductListToHive(int projectId, int categId) async {
  //   try {
  //     final box = await Hive.openBox<CachedProduct>(
  //         'barcode_product_${projectId}_${categId}');
  //
  //     for (var product in productList) {
  //       final productKey = product['default_code'] ?? product['name'];
  //
  //       if (box.containsKey(productKey)) {
  //         continue;
  //       }
  //
  //       final productModel = CachedProduct(
  //         image: product['image'] is String ? product['image'] : '',
  //         name: product['name'] is String ? product['name'] : '',
  //         description:
  //         product['description'] is String ? product['description'] : '',
  //         defaultCode:
  //         product['default_code'] is String ? product['default_code'] : '',
  //         qtyProduct:
  //         (product['qty_product'] is num ? product['qty_product'] : 0)
  //             .toDouble(),
  //       );
  //
  //       await box.put(productKey, productModel);
  //     }
  //   } catch (e) {
  //   }
  // }

}

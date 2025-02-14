import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../offline_db/installation_form/worksheet.dart';
import '../offline_db/product_scan/edit_scan_product.dart';
import '../offline_db/product_scan/product_sacn.dart';
import 'add_manually.dart';
import 'barcode.dart';

class ProductView extends StatefulWidget {
  final String productName;
  final String status_done;
  final int categId;
  final int projectId;
  final int worksheetId;
  final Future<void> Function() reloadScanningCount;


  ProductView({
    required this.productName,
    required this.status_done,
    required this.categId,
    required this.projectId,
    required this.worksheetId,
    required this.reloadScanningCount,
  });

  @override
  State<ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends State<ProductView> {
  String _scanBarcode = 'Unknown';
  OdooClient? client;
  String url = "";
  List<ProductDetails> scannedProducts = [];
  List<ProductDetails> cacheProducts = [];
  String productName = 'Unknown Product';
  String productDescription = '';
  String productPrice = '';
  String Quantity = '';
  bool isProductLoading = false;
  bool isScanningLoading = true;
  int? userId;
  List<Map<String, dynamic>> productList = [];
  int count = 0;

  String status_done = "";
  bool isNetworkAvailable = false;
  late Box<CachedProduct> productBox;
  late Box<CachedScannedProduct> scannedProductBox;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkConnectivity();
    await _initializeOdooClient();
    getProductDetails().then((_) {
      _getScanningProducts();
      _getWorksheets();
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
        getProductDetails().then((_) {
          _getScanningProducts();
          _getWorksheets();
        });
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

    client = OdooClient(url, session);
  }

  Future<void> _getScanningProducts() async {
    try {
      if (!isNetworkAvailable) {
        await _loadCachedScannedProducts();
        return;
      }

      String type = '';
      if (widget.productName == "Panel Serials") type = 'panel';
      if (widget.productName == "Inverter Serials") type = 'inverter';
      if (widget.productName == "Battery Serials") type = 'battery';
      print(
          "scanningProductsscanningProductsscanningProductsscanningProductsscanningProductsscanningProductsscanningProductsd");
      print(type);
      print(widget.worksheetId);
      print(userId);
      final scanningProducts = await client?.callKw({
        'model': 'stock.lot',
        'method': 'search_read',
        'args': [
          [
            ['worksheet_id', '=', widget.worksheetId],
            ['type', '=', type],
            ['user_id', '=', userId],
          ],
        ],
        'kwargs': {},
      });
      print("555555555555555555555555555555555555555555");
      print(scanningProducts);
      print("scanningProductsscanningProducts");
      if (scanningProducts != null && scanningProducts.isNotEmpty) {
        scannedProducts.clear();
        // List<CachedScannedProduct> cacheProducts = [];

        for (var product in scanningProducts) {
          String serialNumber = product['name'];
          String name = product['product_id'][1];
          int productId = product['product_id'][0];
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

          //   cacheProducts.add(CachedScannedProduct(
          //     serialNumber: serialNumber,
          //     name: name,
          //     unitPrice: unitPrice,
          //     state: state,
          //     imageData: imageData,
          //     quantity: quantity,
          //     productId: productId,
          //   ));
        }
      } else {}

      setState(() {
        isScanningLoading = false;
      });
    } catch (e) {
      print("j$e");
      setState(() {
        isScanningLoading = false;
      });
    }
  }

  Future<void> saveScannedProductListToHive() async {
    try {
      final box = await Hive.openBox<CachedScannedProduct>(
          'cachedScannedProductsBox_${widget.projectId}${widget.categId}');

      await box.clear();

      if (scannedProducts.isEmpty) {
        return;
      }

      final cachedProducts = scannedProducts
          .map((product) => CachedScannedProduct(
                serialNumber: product.serialNumber,
                name: product.name,
                unitPrice: product.unitPrice,
                state: product.state,
                imageData: product.imageData?.toList(),
                quantity: product.quantity,
                productId: product.productId,
              ))
          .toList();

      await box.addAll(cachedProducts);
    } catch (e) {}
  }

  Future<void> _loadCachedScannedProducts() async {
    try {
      String type = '';
      if (widget.productName == "Panel Serials") type = 'panel';
      if (widget.productName == "Inverter Serials") type = 'inverter';
      if (widget.productName == "Battery Serials") type = 'battery';
      final box = await Hive.openBox<CachedScannedProduct>(
          'cachedScannedProductsBox_${widget.worksheetId}_${type}_${widget.categId}');
      final cachedProducts = box.values.toList();

      scannedProducts = cachedProducts.map((product) {
        return ProductDetails(
          serialNumber: product.serialNumber,
          name: product.name,
          unitPrice: product.unitPrice,
          state: product.state,
          imageData: Uint8List.fromList(product.imageData ?? []),
          quantity: product.quantity,
          productId: product.productId,
        );
      }).toList();

      setState(() {
        isScanningLoading = false;
      });
    } catch (e) {}
  }

  Future<void> _getWorksheets() async {
    try {
      if (!isNetworkAvailable) {
        await loadWorksheetsFromHive();
        setState(() {
          isScanningLoading = false;
        });
        return;
      }

      final response = await client?.callKw({
        'model': 'task.worksheet',
        'method': 'search_read',
        'args': [
          [
            ['id', '=', widget.worksheetId],
          ],
        ],
        'kwargs': {
          'fields': ['panel_count', 'inverter_count', 'battery_count']
        },
      });
      print(response);
      print("responseresponseresponseresponseresponseresponseresponseresponseresponse");
      final worksheets = (response as List).cast<Map<String, dynamic>>();

      if (worksheets.isNotEmpty) {
        setState(() {
          if (widget.productName == "Panel Serials") {
            count = worksheets[0]['panel_count'] ?? 0;
          } else if (widget.productName == "Inverter Serials") {
            count = worksheets[0]['inverter_count'] ?? 0;
          } else if (widget.productName == "Battery Serials") {
            count = worksheets[0]['battery_count'] ?? 0;
          }
        });
        await saveWorksheetsToHive(worksheets);
      }

      setState(() {
        isScanningLoading = false;
      });
    } catch (e) {
      setState(() {
        isScanningLoading = false;
      });
    }
  }

  Future<void> saveWorksheetsToHive(
      List<Map<String, dynamic>> worksheets) async {
    try {
      final box = await Hive.openBox<Worksheet>(
          'worksheetBox_${widget.projectId}${widget.categId}');
      await box.clear();

      for (var worksheet in worksheets) {
        final worksheetModel = Worksheet(
          id: worksheet['id'],
          panelCount: worksheet['panel_count'] ?? 0,
          inverterCount: worksheet['inverter_count'] ?? 0,
          batteryCount: worksheet['battery_count'] ?? 0,
          checklistCount: 0,
          scannedPanelCount: 0,
          scannedInverterCount: 0,
          scannedBatteryCount: 0,
          checklistCurrentCount: 0,
        );

        await box.put(worksheet['id'], worksheetModel);
      }
    } catch (e) {}
  }

  Future<void> loadWorksheetsFromHive() async {
    try {
      final box = await Hive.openBox<Worksheet>(
          'worksheetBox_${widget.projectId}${widget.categId}');
      final worksheets = box.values.toList();

      if (worksheets.isNotEmpty) {
        setState(() {
          if (widget.productName == "Panel Serials") {
            count = worksheets[0].panelCount ?? 0;
          } else if (widget.productName == "Inverter Serials") {
            count = worksheets[0].inverterCount ?? 0;
          } else if (widget.productName == "Battery Serials") {
            count = worksheets[0].batteryCount ?? 0;
          }
        });
      } else {
        await loadProductCategoriesFromHive();
      }
    } catch (e) {
      await loadProductCategoriesFromHive();
    }
  }

  Future<void> loadProductCategoriesFromHive() async {
    try {
      final box = await Hive.openBox<Worksheet>('worksheets');
      final worksheet = box.get(widget.worksheetId);

      if (worksheet != null) {
        setState(() {
          if (widget.productName == "Panel Serials") {
            count = worksheet.panelCount ?? 0;
          } else if (widget.productName == "Inverter Serials") {
            count = worksheet.inverterCount ?? 0;
          } else if (widget.productName == "Battery Serials") {
            count = worksheet.batteryCount ?? 0;
          }
        });
      } else {}
    } catch (e) {}
  }

  Future<void> getProductDetails() async {
    isProductLoading = true;

    if (!isNetworkAvailable) {
      await loadProductFromHive();
      isProductLoading = false;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;

    try {
      final productFromProject = await client?.callKw({
        'model': 'project.task',
        'method': 'search_read',
        'args': [
          [
            // ['x_studio_proposed_team', '=', userId],
            ['id', '=', widget.projectId],
            ['worksheet_id', '!=', false],
            ['team_lead_user_id', '=', userId],
          ]
        ],
        'kwargs': {
          'fields': ['x_studio_product_list'],
        },
      });

      if (productFromProject != null && productFromProject.isNotEmpty) {
        if (productFromProject[0] is Map) {
          final orderLine = productFromProject[0]['x_studio_product_list'];
          if (orderLine != null) {
            productList = [];
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
                  'fields': ['product_id', 'product_uom_qty'],
                },
              });

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
                    'fields': [
                      'image_1920',
                      'name',
                      'description',
                      'default_code',
                      'categ_id'
                    ],
                  },
                });
                if (productImage != null && productImage.isNotEmpty) {
                  final productCategoryId = productImage[0]['categ_id'][0];
                  final categoryDetails = await client?.callKw({
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
                  if (categoryDetails != null && categoryDetails.isNotEmpty) {
                    final categoryId = categoryDetails[0]['id'];
                    final parentCategoryId =
                        categoryDetails[0]['parent_id'] != null &&
                                categoryDetails[0]['parent_id'] is List
                            ? categoryDetails[0]['parent_id'][0]
                            : null;
                    if (categoryId == widget.categId ||
                        parentCategoryId == widget.categId) {
                      productList.add({
                        'image': productImage[0]['image_1920'],
                        'name': productImage[0]['name'],
                        'description': productImage[0]['description'],
                        'default_code': productImage[0]['default_code'],
                        'qty_product': productDetails[0]['product_uom_qty']
                      });
                      setState(() {
                        isProductLoading = false;
                      });
                    }
                  }
                }
              }
            }
          }
        }
      } else {
        isProductLoading = false;
      }
    } catch (e) {
      isProductLoading = false;
    } finally {
      log('productList  :  $productList');
      isProductLoading = false;
      setState(() {});
    }
  }

  Future<void> loadProductFromHive() async {
    try {
      final box = await Hive.openBox<CachedProduct>(
          'barcode_product_${widget.projectId}_${widget.categId}');
      productList = box.values.map((product) => product.toMap()).toList();
    } catch (e) {
      productList = [];
    }
  }

  Future<void> saveProductListToHive() async {
    try {
      final box = await Hive.openBox<CachedProduct>(
          'barcode_product_${widget.projectId}_${widget.categId}');
      await box.clear();

      for (var product in productList) {
        log('product  :   ${product['default_code']}');

        final productModel = CachedProduct(
          image: product['image'] is String ? product['image'] : '',
          name: product['name'] is String ? product['name'] : '',
          description:
              product['description'] is String ? product['description'] : '',
          defaultCode:
              product['default_code'] is String ? product['default_code'] : '',
          qtyProduct:
              (product['qty_product'] is num ? product['qty_product'] : 0)
                  .toDouble(),
        );

        await box.put(product['default_code'] ?? product['name'], productModel);
      }
    } catch (e) {}
  }

  Future<void> scanBarcode() async {
    if (scannedProducts.length < count) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BarcodeScreen(),
        ),
      ).then((result) {
        if (result != null) {
          String? scannedCode = result['scannedResult'];
          Uint8List? imageData = result['scannedImage'];
          _scanBarcode = scannedCode ?? 'Unknown';
          if (imageData != null) {
            _fetchProductFromOdoo(_scanBarcode, imageData);
          }
        }
      });
    } else {
      _showLimitReachedSnackBar();
    }
  }

  // Future<void> _fetchProductFromOdoo(
  //     String barcode, Uint8List? imageData) async {
  //   Position position = await _getCurrentLocation();
  //   setState(() {
  //     isLoading = true;
  //   });
  //   if (!isNetworkAvailable) {
  //     await _cacheProductOffline(barcode, imageData,position);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content:
  //         Text('Product cached offline. Will sync when online.'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return;
  //   }
  //   if (client == null) {
  //     _showErrorSnackbar('Odoo client not initialized');
  //     return;
  //   }
  //
  //   try {
  //     final productIds = await client!.callKw({
  //       'model': 'product.product',
  //       'method': 'search',
  //       'args': [
  //         [
  //           ['barcode', '=', barcode]
  //         ]
  //       ],
  //       'kwargs': {},
  //     });
  //
  //     if (productIds.isNotEmpty) {
  //       final productData = await client!.callKw({
  //         'model': 'product.product',
  //         'method': 'read',
  //         'args': [
  //           productIds,
  //           ['name', 'standard_price', 'description_sale']
  //         ],
  //         'kwargs': {},
  //       });
  //
  //       if (productData.isNotEmpty) {
  //         log('productData  :  $productData');
  //         String fetchedProductName = productData[0]['name'];
  //         String unitPrice = productData[0]['standard_price'].toString();
  //         int productId = productData[0]['id'];
  //         bool productExistsInProject = productList.any((product) =>
  //         product['name'] == fetchedProductName);
  //
  //         if (productExistsInProject) {
  //           setState(() {
  //             productName = fetchedProductName;
  //           });
  //           await _addOrUpdateScannedProduct(barcode, fetchedProductName, unitPrice, productId, imageData);
  //           await _uploadProductsToTaskWorksheet(widget.worksheetId,position);
  //           setState(() {
  //             isLoading = false;
  //           });
  //           _showSuccessSnackbar('Product added successfully');
  //         } else {
  //           setState(() {
  //             isLoading = false;
  //           });
  //           _showErrorSnackbar('Product not found in the ${widget.productName}');
  //         }
  //       }
  //     } else {
  //       _showErrorSnackbar('Product not found in Odoo');
  //       setState(() {
  //         productName = 'Product not found';
  //         productPrice = '';
  //         productDescription = '';
  //         isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       isLoading = false;
  //     });
  //     _showErrorSnackbar('Error fetching product from Odoo');
  //   }
  // }

  Future<void> _fetchProductFromOdoo(
      String barcode, Uint8List? imageData) async {
    Position position = await _getCurrentLocation();
    setState(() {
      isLoading = true;
    });
    final alreadyScanned =
        scannedProducts.any((product) => product.serialNumber == barcode);
    if (alreadyScanned) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This product has already been scanned.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!isNetworkAvailable) {
      await _cacheProductOffline(barcode, imageData, position);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product cached offline. Will sync when online.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (client == null) {
      _showErrorSnackbar('Odoo client not initialized');
      return;
    }

    try {
      // final productIds = await client!.callKw({
      //   'model': 'product.product',
      //   'method': 'search',
      //   'args': [
      //     [
      //       ['barcode', '=', barcode]
      //     ]
      //   ],
      //   'kwargs': {},
      // });
      print("888888888888888888888888*************");
      print(barcode);
      final productIds = await client!.callKw({
        'model': 'stock.lot',
        'method': 'search_read',
        'args': [
          [
            ['name', '=', barcode]
          ]
        ],
        'kwargs': {
          'fields': ['product_id']
        },
      });
      print(productIds);
      print(scannedProducts);
      print("productIdsproductIds");
      if (productIds.isNotEmpty) {
        for (var productIdItem in productIds) {
          final lotId = productIdItem['id'];
          final productId = productIdItem['product_id'][0];
          print("dddddddddddddddddddproductIdproductIdproductId$lotId");
          final existingProduct = productList.firstWhere(
            (product) =>
                product['product_id'] != null &&
                product['product_id'][0] == productId,
            orElse: () => {},
          );
          if (existingProduct != null) {
            final productData = await client!.callKw({
              'model': 'product.product',
              'method': 'read',
              'args': [
                [productId],
                ['name', 'standard_price', 'description_sale']
              ],
              'kwargs': {},
            });

            if (productData.isNotEmpty) {
              log('productData  :  $productData');
              String fetchedProductName = productData[0]['name'];
              String unitPrice = productData[0]['standard_price'].toString();
              int productId = productData[0]['id'];
              bool productExistsInProject = productList
                  .any((product) => product['name'] == fetchedProductName);

              if (productExistsInProject) {
                setState(() {
                  productName = fetchedProductName;
                });
                await _addOrUpdateScannedProduct(barcode, fetchedProductName,
                    unitPrice, productId, imageData);
                bool result = await _uploadProductsToTaskWorksheet(
                    lotId, widget.worksheetId, position);
                if(result) {
                  setState(() {
                    isLoading = false;
                  });
                  _showSuccessSnackbar('Product added successfully');
                }else{
                  setState(() {
                    isLoading = false;
                  });
                  _showErrorSnackbar('Error uploading products to task worksheet');
                }
              } else {
                setState(() {
                  isLoading = false;
                });
                _showErrorSnackbar(
                    'Product not found in the ${widget.productName}');
              }
            }
          }
        }
      } else {
        _showErrorSnackbar('Product not found in Odoo');
        setState(() {
          productName = 'Product not found';
          productPrice = '';
          productDescription = '';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackbar('Error fetching product from Odoo');
    }
  }

  void _addProductOffline(String barcode, Uint8List? imageData) {
    final existingProduct = scannedProducts.firstWhere(
      (product) => product.serialNumber == barcode,
      orElse: () => ProductDetails(
        serialNumber: '',
        name: '',
        unitPrice: '',
        productId: 0,
        state: '',
      ),
    );

    if (existingProduct.serialNumber.isNotEmpty) {
      setState(() {
        existingProduct.quantity++;
        existingProduct.imageData = imageData;
      });
    } else {
      setState(() {
        scannedProducts.add(ProductDetails(
          serialNumber: barcode,
          name: 'Offline Product',
          unitPrice: '0',
          imageData: imageData,
          quantity: 1,
          productId: 0,
          state: 'draft',
        ));
      });
    }
  }

  // Future<void> _cacheProductOffline(String barcode, Uint8List? imageData,position) async {
  //   final box = await Hive.openBox<EditScanProduct>('cachedProducts');
  //   final cachedProduct = EditScanProduct(
  //     barcode: barcode,
  //     imageData: imageData,
  //     worksheetId: widget.worksheetId,
  //     type: widget.productName,
  //     timestamp: DateTime.now().toIso8601String(),
  //     position: {
  //       'latitude': position.latitude,
  //       'longitude': position.longitude
  //     },
  //   );
  //   await box.put(barcode, cachedProduct);
  //   await box.close();
  // }
  Future<void> _cacheProductOffline(
      String barcode, Uint8List? imageData, position) async {
    Box<EditScanProduct>? box;
    try {
      // Open the Hive box
      box = await Hive.openBox<EditScanProduct>('cachedProducts');

      // Create the cached product entry
      final cachedProduct = EditScanProduct(
        barcode: barcode,
        imageData: imageData,
        worksheetId: widget.worksheetId,
        type: widget.productName,
        timestamp: DateTime.now().toIso8601String(),
        position: {
          'latitude': position.latitude,
          'longitude': position.longitude
        },
      );

      // Save the product to the box
      await box.put(barcode, cachedProduct);
      print("Cached product for barcode $barcode");
    } catch (e) {
      print("Error caching product: $e");
    } finally {
      // Ensure the box is closed properly
      if (box != null && box.isOpen) {
        await box.close();
        print("Box closed properly.");
      }
    }
  }

  Future<void> _addOrUpdateScannedProduct(String barcode, String productName,
      String unitPrice, int productId, Uint8List? imageData) async {
    final existingProduct = scannedProducts.firstWhere(
      (product) => product.serialNumber == barcode,
      orElse: () => ProductDetails(
        serialNumber: '',
        name: '',
        unitPrice: '',
        productId: 0,
        state: '',
      ),
    );

    if (existingProduct.serialNumber.isNotEmpty) {
      print('if case satisfied');
      setState(() {
        existingProduct.quantity++;
        existingProduct.imageData = imageData;
      });
    } else {
      print('else case satisfied');
      setState(() {
        cacheProducts.add(ProductDetails(
          serialNumber: barcode,
          name: productName,
          unitPrice: unitPrice,
          imageData: imageData,
          quantity: 1,
          productId: productId,
          state: 'draft',
        ));
      });
    }

    log('existingProduct  :  ${existingProduct.name}');
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

  Future<bool> _uploadProductsToTaskWorksheet(
      int lotId, int worksheetId, position) async {
    print("${position.latitude}/dddddddddddddddddddddddddddccccddddddddddddd");
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks.first;
    String locationDetails =
        "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";

    try {
      for (var product in cacheProducts) {
        Uint8List imageBytes =
            Uint8List.fromList(product.imageData as List<int>);
        String base64Image = base64Encode(imageBytes);
        String type = "";
        if (widget.productName == "Panel Serials") type = 'panel';
        if (widget.productName == "Inverter Serials") type = 'inverter';
        if (widget.productName == "Battery Serials") type = 'battery';
        final data = {
          'type': type,
          'image': base64Image,
          'state': 'draft',
          'worksheet_id': worksheetId,
          'user_id': userId,
          'verification_time':
              DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          'location': locationDetails,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'product_id': product.productId,
          'product_qty': product.quantity
        };
        print(worksheetId);
        print(userId);
        print(type);
        print("datadatadatadatadatadatadatadatadatadata");
        try {
          final lot = await client!.callKw({
            'model': 'stock.lot',
            'method': 'write',
            'args': [
              [lotId],
              data
            ],
            'kwargs': {},
          });
          print("lotlotlotlotlot$lot");
          _getScanningProducts();
        } catch (e, stackTrace) {
          print("ttttttttttttttttttttt$e");
          return false;
        }
      }
      _showSuccessSnackbar('Products uploaded successfully to task worksheet');
      cacheProducts.clear();
      return true;
    } catch (e) {
      _showErrorSnackbar('Error uploading products to task worksheet');
      return false;
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(context);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          setState(() {
            widget.reloadScanningCount();
          });
          return true;
        },
        child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          widget.productName,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16),
                        _buildPanelInfo(),
                        SizedBox(height: 16),
                        _buildPanelSerialNumbers(),
                        SizedBox(height: 16),
                        if (widget.productName == "Panel Serials")
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(""),
                              ),
                              // SizedBox(width: 16),
                              // _buildSpvCheck(),
                            ],
                          ),
                        SizedBox(height: 16),
                        Center(
                          child: _buildSerialList(),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLoading) _buildBottomButtons(widget.status_done),
            ],
          ),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
        ),
    );
  }

  Widget _buildSpvCheck() {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        'SPV Check',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPanelInfo() {
    if (isProductLoading) {
      return Column(
        children: List.generate(2, (index) => _buildShimmer()).toList(),
      );
    } else {
      return Column(
        children: productList.map((product) {
          final imageBase64 = product['image'];
          final hasValidImage = imageBase64 is String && imageBase64.isNotEmpty;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              hasValidImage
                  ? CircleAvatar(
                      radius: 30.0,
                      backgroundColor: Colors.grey[350],
                      child: ClipOval(
                        child: imageBase64.isNotEmpty
                            ? Image.memory(
                                base64Decode(imageBase64),
                                fit: BoxFit.cover,
                                width: 80.0,
                                height: 80.0,
                                errorBuilder: (BuildContext context,
                                    Object exception, StackTrace? stackTrace) {
                                  return Icon(
                                    Icons.solar_power,
                                    size: 30,
                                    color: Colors.black,
                                  );
                                },
                              )
                            : Icon(Icons.solar_power,
                                size: 30, color: Colors.black),
                      ),
                    )
                  : CircleAvatar(
                      radius: 30.0,
                      backgroundColor: Colors.grey[350],
                      child: Icon(Icons.solar_power,
                          size: 30, color: Colors.black)),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${product['qty_product']}x',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    Text(
                      product['name'] ?? 'Unknown',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product['default_code'] ?? 'Unknown',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      );
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30.0,
            backgroundColor: Colors.grey[350],
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60.0,
                  height: 20.0,
                  color: Colors.grey[300],
                ),
                SizedBox(height: 10),
                Container(
                  width: 100.0,
                  height: 20.0,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelSerialNumbers() {
    String serialNumber = "";
    if (widget.productName == "Panel Serials")
      serialNumber = 'Panel Serial Numbers';
    if (widget.productName == "Inverter Serials")
      serialNumber = 'Inverter Serial Numbers';
    if (widget.productName == "Battery Serials")
      serialNumber = 'Battery Serial Numbers';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(serialNumber, style: TextStyle(fontSize: 16)),
            Text('${scannedProducts.length}/$count',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        // Row(
        //   children: [
        //     Column(
        //       crossAxisAlignment: CrossAxisAlignment.end,
        //       children: [
        //         Text('Invalid: 0', style: TextStyle(fontSize: 16)),
        //         Text('Verified: 30',
        //             style:
        //             TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        //       ],
        //     ),
        //   ],
        // ),
      ],
    );
  }

  Widget _buildSerialList() {
    print(scannedProducts);
    print("4444444444444444444444444ffffffffff");
    if (isScanningLoading) {
      return Column(
        children: List.generate(10, (index) => _buildShimmer()).toList(),
      );
    }
    if (scannedProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber,
              color: Colors.black,
              size: 92,
            ),
            SizedBox(height: 20),
            Text(
              "No scanned products available",
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
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: scannedProducts.length,
      itemBuilder: (context, index) {
        final product = scannedProducts[index];
        Color getStateColor(String state) {
          switch (state) {
            case 'draft':
              return Colors.blue;
            case 'invalid':
              return Colors.red[100]!;
            case 'verifying':
              return Colors.orange[100]!;
            case 'verified':
              return Colors.green[100]!;
            default:
              return Colors.grey[300]!;
          }
        }

        String getStateText(String state) {
          switch (state) {
            case 'draft':
              return 'Draft';
            case 'invalid':
              return 'Invalid';
            case 'verifying':
              return 'Verifying';
            case 'verified':
              return 'Verified';
            default:
              return 'Unknown';
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              product.imageData != null
                  ? Image.memory(
                      product.imageData!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.image, color: Colors.grey[600]),
                        );
                      },
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.image, color: Colors.grey[600]),
                    ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.serialNumber,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      'Name: ${product.name}',
                      style: TextStyle(color: Colors.grey[600]),
                      maxLines: null,
                      overflow: TextOverflow.visible,
                      softWrap: true,
                    ),
                    Text('Quantity: ${product.quantity}',
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: getStateColor(product.state).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  getStateText(product.state),
                  style: TextStyle(
                      color: getStateColor(product.state).withOpacity(0.8),
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomButtons(String status_done) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildIconButton(
            Icons.add,
            'Add Manually',
            onTap: () async {
              final box = await Hive.openBox<EditScanProduct>('cachedProducts');
              // EditScanProduct? existingImage = box.values.cast<EditScanProduct?>().firstWhere(
              //       (image) => image != null &&
              //       image.type == widget.productName &&
              //       image.worksheetId == widget.worksheetId,
              //   orElse: () => null,
              // );
              List<EditScanProduct> existingImages = box.values
                  .where((image) => image != null) // Remove null values
                  .cast<EditScanProduct>() // Cast to non-nullable type
                  .where(
                    (image) =>
                        image.type == widget.productName &&
                        image.worksheetId == widget.worksheetId,
                  )
                  .toList();

              print(count);
              print("ggggggggggggggggggggggggg");
              if (existingImages.length >= count) {
                print("Maximum item limit reached. Cannot add more items.");
                _showLimitReachedSnackBar();
                return;
              } else {
                if (status_done != 'done') {
                  _addManually();
                }
              }
            },
          ),
          _buildImageButton(
            Image.asset(
              'assets/barcode.png',
              width: 24,
              height: 24,
            ),
            'Scan Barcode',
            onTap: () async {
              final box = await Hive.openBox<EditScanProduct>('cachedProducts');
              // EditScanProduct? existingImage = box.values.cast<EditScanProduct?>().firstWhere(
              //       (image) => image != null &&
              //       image.type == widget.productName &&
              //       image.worksheetId == widget.worksheetId,
              //   orElse: () => null,
              // );
              // print(box.length);
              // print(count);
              // print("ggggggggggggggggggggggggg");
              // if (box.length >= count) {
              List<EditScanProduct> existingImages = box.values
                  .where((image) => image != null) // Remove null values
                  .cast<EditScanProduct>() // Cast to non-nullable type
                  .where(
                    (image) =>
                        image.type == widget.productName &&
                        image.worksheetId == widget.worksheetId,
                  )
                  .toList();

              print(widget.productName);
              print("ggggggggggggggggggggggggg");
              if (existingImages.length >= count) {
                print("Maximum item limit reached. Cannot add more items.");
                _showLimitReachedSnackBar();
                return;
              }
              // if (existingImage != null) {
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     SnackBar(
              //       content: Text('You already scanned barcode for this product.'),
              //       backgroundColor: Colors.red,
              //     ),
              //   );
              //   print("Item already added for this product and worksheet.");
              //   return;
              // }
              else {
                if (status_done != 'done') {
                  scanBarcode();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showLimitReachedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Your Serial Numbers reached its maximum limit',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addManually() async {
    if (scannedProducts.length < count) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddManually(),
        ),
      ).then((result) {
        if (result != null) {
          String? manuallyAddedCode = result['manuallyAddedCode'];
          Uint8List? imageData = result['manuallyAddedImage'];
          _scanBarcode = manuallyAddedCode ?? 'Unknown';
          if (imageData != null) {
            _fetchProductFromOdoo(_scanBarcode, imageData);
          }
        }
      });
    } else {
      _showLimitReachedSnackBar();
    }
  }

  Widget _buildImageButton(Widget icon, String label,
      {required Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
            child: icon, // Use the passed widget here
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label,
      {required Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
            child: Icon(icon, size: 24),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class ProductDetails {
  final String serialNumber;
  final String name;
  final String unitPrice;
  final String state;
  Uint8List? imageData;
  int quantity;
  var productId;

  String get totalPrice =>
      (double.parse(unitPrice) * quantity).toStringAsFixed(2);

  ProductDetails({
    required this.serialNumber,
    required this.name,
    required this.unitPrice,
    required this.state,
    this.imageData,
    this.quantity = 1,
    required this.productId,
  });
}

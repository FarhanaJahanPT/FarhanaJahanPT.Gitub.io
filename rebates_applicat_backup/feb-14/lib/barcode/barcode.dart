import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:typed_data';

class BarcodeScreen extends StatefulWidget {
  @override
  _BarcodeScreenState createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: true,
    facing: CameraFacing.back,
  );

  bool isBarcodeMode = true;
  bool isFlashOn = false;
  final ImagePicker _picker = ImagePicker();

  Future<bool> _onWillPop() async {
    Navigator.pop(context);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.green,
          title: Text(
            'Scanner',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  MobileScanner(
                    placeholderBuilder: (context, m) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    controller: cameraController,
                    onDetect: (barcodeCapture) {
                      final List<Barcode> barcodes = barcodeCapture.barcodes;
                      final Uint8List? image = barcodeCapture.image;

                      if (barcodes.isNotEmpty) {
                        final barcode = barcodes.first;
                        final String? code = barcode.rawValue;

                        if (code != null) {
                          if (isBarcodeMode) {
                            if (barcode.format != BarcodeFormat.qrCode) {
                              Navigator.pop(context, {
                                'scannedResult': code,
                                'scannedImage': image,
                              });
                            }
                          } else {
                            if (barcode.format == BarcodeFormat.qrCode) {
                              Navigator.pop(context, {
                                'scannedResult': code,
                                'scannedImage': image,
                              });
                            }
                          }
                        }
                      }
                    },
                    errorBuilder: (context, error, child) {
                      cameraController.stop();
                      cameraController.start();
                      return Container();
                    },
                    overlayBuilder: (context, camera) {
                      return Center(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green, width: 3),
                          ),
                          child: isBarcodeMode
                              ? Container(
                                  width: 280,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.green, width: 3),
                                  ),
                                )
                              : Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.green, width: 3),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(Icons.switch_camera, color: Colors.white),
                    onPressed: () {
                      cameraController.switchCamera();
                    },
                    tooltip: 'Switch Camera',
                  ),
                  IconButton(
                    icon: Icon(
                      isFlashOn ? Icons.flash_off : Icons.flash_on,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      cameraController.toggleTorch();
                      setState(() {
                        isFlashOn = !isFlashOn;
                      });
                    },
                    tooltip: 'Toggle Flash',
                  ),
                  IconButton(
                    icon: Icon(
                      isBarcodeMode ? Icons.qr_code : Icons.view_column,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        isBarcodeMode = !isBarcodeMode;
                      });
                    },
                    tooltip: isBarcodeMode
                        ? 'Switch to QR Code'
                        : 'Switch to Barcode',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

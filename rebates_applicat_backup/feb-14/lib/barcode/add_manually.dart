import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'dart:async';

import 'package:image_picker/image_picker.dart';

class AddManually extends StatefulWidget {
  @override
  _AddManuallyState createState() => _AddManuallyState();
}

class _AddManuallyState extends State<AddManually> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  int _cameraIndex = 0;
  bool _isFlashOn = false;
  bool _isQrMode = false;
  TextEditingController _serialNumberController = TextEditingController();
  File? _capturedImage;
  bool _isScanning = false;
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _captureImage() async {
    if (!_controller!.value.isInitialized) {
      return;
    }
    try {
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImage = File(image.path);
      });
      _showCapturedImage();
    } catch (e) {
    }
  }

  Future<void> _startContinuousBarcodeScanning() async {
    setState(() {
      _isScanning = true;
    });

    await _controller!.startImageStream((CameraImage image) async {
      if (!_isScanning) return;

      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize =
          Size(image.width.toDouble(), image.height.toDouble());

      final InputImageRotation imageRotation = InputImageRotation.rotation0deg;
      final InputImageFormat inputImageFormat = InputImageFormat.nv21;

      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final InputImage inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );

      final List<Barcode> barcodes =
          await _barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty) {
        final barcodeType = barcodes.first.format;

        if (_isQrMode && barcodeType == BarcodeFormat.qrCode) {
          setState(() {
            _isScanning = false;
          });
          await _controller!.stopImageStream();
          _serialNumberController.text = barcodes.first.rawValue ?? '';
          await _captureImage();
        } else if (!_isQrMode && barcodeType != BarcodeFormat.qrCode) {
          setState(() {
            _isScanning = false;
          });
          await _controller!.stopImageStream();
          _serialNumberController.text = barcodes.first.rawValue ?? '';
          await _captureImage();
        }
      }
    });
  }

  void _returnData() {
    Navigator.of(context).pop({
      'manuallyAddedCode': _serialNumberController.text,
      'manuallyAddedImage':
          _capturedImage != null ? _capturedImage!.readAsBytesSync() : null,
    });
  }

  void _showCapturedImage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(_capturedImage!),
            SizedBox(height: 10),
            Text('Serial Number: ${_serialNumberController.text}'),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Retake'),
            onPressed: () {
              _serialNumberController.clear();
              Navigator.of(context).pop();
              setState(() {
                _capturedImage = null;
              });
              _isScanning = true;
              _startContinuousBarcodeScanning();
            },
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () {
              Navigator.of(context).pop();
              _returnData();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    _controller = CameraController(cameras[_cameraIndex], ResolutionPreset.max);
    await _controller!.initialize();
    if (mounted) {
      setState(() {});
      _startContinuousBarcodeScanning();
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _capturedImage = File(image.path);
      });

      _showCapturedImage();
    }
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
      _controller?.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    });
  }

  void _switchCamera() {
    setState(() {
      _cameraIndex = (_cameraIndex + 1) % cameras.length;
      _initializeCamera();
    });
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(context);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final cameraViewHeight = screenHeight * 0.4;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: cameraViewHeight,
                    child: CameraPreview(_controller!),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: cameraViewHeight * 0.25),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _buildCornerMarkers(),
                    ),
                  ),
                ],
              ),
              Container(
                height: screenHeight * 0.43,
                width: double.infinity,
                color: Colors.black.withOpacity(0.8),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          left: screenWidth * 0.05,
                          right: screenWidth * 0.05,
                          top: 10),
                      child: TextField(
                        controller: _serialNumberController,
                        decoration: InputDecoration(
                          hintText:
                              'Serial number will appear here after scanning',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide(
                              color: Colors.grey.shade400,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 10),
                        ),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildControlBar(),
      ),
    );
  }

  Widget _buildCornerMarkers() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green, width: 3),
      ),
      child: !_isQrMode
          ? Container(
              width: 280,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(),
                  ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Container(),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(),
                  ),
                ],
              ),
            )
          : Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(),
                  ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Container(),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      color: Colors.green,
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(Icons.switch_camera, color: Colors.white),
            onPressed: _switchCamera,
          ),
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_off : Icons.flash_on,
                color: Colors.white),
            onPressed: _toggleFlash,
          ),
          FloatingActionButton(
            backgroundColor: Colors.white,
            child: Icon(Icons.camera_alt, color: Colors.green),
            onPressed: _captureImage,
          ),
          IconButton(
            icon: Icon(
              _isQrMode ? Icons.qr_code : Icons.barcode_reader,
              // Show the correct icon
              color: Colors.white,
            ),
            onPressed: _toggleScanMode, // Toggle between QR and barcode mode
          ),
          IconButton(
            icon: Icon(Icons.photo_library, color: Colors.white),
            onPressed: _pickImageFromGallery,
          ),
        ],
      ),
    );
  }

  void _toggleScanMode() {
    setState(() {
      _isQrMode = !_isQrMode;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    // _timer?.cancel();
    _barcodeScanner.close();
    super.dispose();
  }
}

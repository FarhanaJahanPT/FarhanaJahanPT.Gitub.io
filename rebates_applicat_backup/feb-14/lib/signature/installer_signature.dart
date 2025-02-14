import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:signature/signature.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../offline_db/signatures/installer_signature_edit.dart';

class SignatureScreen extends StatefulWidget {
  final Function(Uint8List, Uint8List, String) onSignatureSubmitted;
  final Uint8List? existingSignature;
  final String existingName;
  final String title;
  final int projectId;
  final DateTime? installDate;

  SignatureScreen({
    required this.onSignatureSubmitted,
    this.existingSignature,
    required this.existingName,
    required this.title,
    required this.projectId,
    required this.installDate,
  });

  @override
  _SignatureScreenState createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  late SignatureController _installerController;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  ui.Image? _signatureImage;
  bool _signatureModified = false;
  late String baseUrl = '';
  bool isResigning = false;

  @override
  void initState() {
    print(widget.existingName);
    print("existingNameexistingNameexistingName");
    super.initState();
    _installerController = SignatureController(
      penColor: Colors.black,
      penStrokeWidth: 5,
    );
    if (widget.existingSignature != null) {
      _loadExistingSignature();
    }
    _nameController.text = widget.existingName;
  }

  Future<void> _loadExistingSignature() async {
    if (widget.existingSignature != null) {
      final ByteData data = ByteData.sublistView(widget.existingSignature!);
      final ui.Codec codec =
          await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      setState(() {
        _signatureImage = frameInfo.image;
      });
    }
  }

  @override
  void dispose() {
    _installerController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    print(widget.installDate);
    print("vvvvvvvvvvvvvvvvvvvvvvvvvv");
    String installDateString = widget.installDate != null
        ? DateFormat('yyyy-MM-dd').format(widget.installDate!)
        : 'No date available';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        // toolbarHeight: 100,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  height: screenSize.height * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.grey.withOpacity(.3),
                      width: 2,
                    ),
                  ),
                  child: _signatureImage != null
                      ? CustomPaint(
                          painter: _SignaturePainter(_signatureImage!),
                          child: Container(),
                        )
                      : isResigning
                          ? Signature(
                              controller: _installerController,
                              backgroundColor: Colors.white,
                            )
                          : Signature(
                              controller: _installerController,
                              backgroundColor: Colors.white,
                            ),
                ),
                if (_signatureImage == null || isResigning)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        _installerController.clear();
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(
                            color: Colors.lightGreen.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Signature of the \nInstaller & Designer:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(
                  width: 50,
                ),
                Flexible(
                  child: Text(
                    '${widget.existingName}',
                    maxLines: null,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Signature Date:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(installDateString, style: TextStyle(color: Colors.black)),
              ],
            ),
            SizedBox(height: 10),
            // if (widget.existingSignature == null || isResigning) ...[
            //   RichText(
            //     text: TextSpan(
            //       children: [
            //         TextSpan(
            //             text: 'Please select your witness ',
            //             style: TextStyle(color: Colors.black)),
            //         TextSpan(
            //             text: '(Must be onsite)',
            //             style: TextStyle(color: Colors.red)),
            //       ],
            //     ),
            //   ),
            // ],
            // SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (widget.existingSignature == null || isResigning) ...[
                  // Expanded(
                  //   child: OutlinedButton(
                  //     onPressed: () {},
                  //     style: OutlinedButton.styleFrom(
                  //       side: BorderSide(color: Colors.green),
                  //     ),
                  //     child: Text('Owner',
                  //         style: TextStyle(
                  //             color: Colors.green,
                  //             fontWeight: FontWeight.bold)),
                  //   ),
                  // ),
                  // SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final installerData =
                            await _installerController.toPngBytes();
                        if (_installerController.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please sign before done.',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        _saveSignature(installerData);
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => InstallerDesignerSignature(
                        //       project_id: widget.projectId,
                        //         title: widget.title,
                        //         installerData: installerData,
                        //         onSignatureSubmitted:
                        //             widget.onSignatureSubmitted),
                        //   ),
                        // );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Done',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                if (widget.existingSignature != null && !isResigning) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isResigning = true;
                          _signatureImage = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Re-sign',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSignature(installerData) async {
    print("project_idproject_idproject_id");

    final _witnessNameController = TextEditingController();
    final data = installerData;
    final installSignature = installerData;

    if (installSignature != null && data != null) {
      widget.onSignatureSubmitted(
          installSignature, data, _witnessNameController.text);

      Box<SignatureData>? box;
      try {
        box = await Hive.openBox<SignatureData>('signatureBox');
        await box.put(
          'signatureData',
          SignatureData(
            id: widget.projectId,
            installSignature: installSignature,
            witnessSignature: data,
            name: _witnessNameController.text,
          ),
        );
        print("Signature saved successfully.");
      } catch (e) {
        print("Error saving signature: $e");
      } finally {
        if (box != null && box.isOpen) {
          await box.close();
          print("Box closed properly.");
        }
      }
    }
  }
}

class _SignaturePainter extends CustomPainter {
  final ui.Image image;

  _SignaturePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    final double imageWidth = image.width.toDouble();
    final double imageHeight = image.height.toDouble();

    final double imageAspectRatio = imageWidth / imageHeight;
    final double containerAspectRatio = size.width / size.height;

    double scaleFactor;
    Offset offset;

    if (containerAspectRatio > imageAspectRatio) {
      scaleFactor = size.height / imageHeight;
      final double scaledImageWidth = imageWidth * scaleFactor;
      final double horizontalMargin = (size.width - scaledImageWidth) / 2;
      offset = Offset(horizontalMargin, 0);
    } else {
      scaleFactor = size.width / imageWidth;
      final double scaledImageHeight = imageHeight * scaleFactor;
      final double verticalMargin = (size.height - scaledImageHeight) / 2;
      offset = Offset(0, verticalMargin);
    }

    canvas.scale(scaleFactor);

    canvas.drawImage(image, offset / scaleFactor, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class InstallerDesignerSignature extends StatefulWidget {
  final int project_id;
  final String title;
  late Uint8List? installerData;
  final Function(Uint8List, Uint8List, String) onSignatureSubmitted;

  InstallerDesignerSignature(
      {required this.project_id,required this.title,
      required this.installerData,
      required this.onSignatureSubmitted});
  @override
  _InstallerDesignerSignatureState createState() =>
      _InstallerDesignerSignatureState();
}

class _InstallerDesignerSignatureState
    extends State<InstallerDesignerSignature> {
  final SignatureController _witnessController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  final TextEditingController _witnessNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '* ', // Asterisk in red color
                    style: TextStyle(color: Colors.red),
                  ),
                  TextSpan(
                    text: 'Witness', // Witness in black color
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),

            SizedBox(height: 8),
            // TextField for witness name
            TextField(
              controller: _witnessNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter witness name',
              ),
              maxLines: 1,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  height: MediaQuery.of(context).size.height * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.grey.withOpacity(.3),
                      width: 2,
                    ),
                  ),
                  child: Signature(
                    controller: _witnessController,
                    backgroundColor: Colors.white,
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      _witnessController.clear();
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: Colors.lightGreen.shade800,
                        fontWeight: FontWeight.bold, // Bold text
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Signature Date:',
                  style: TextStyle(fontWeight: ui.FontWeight.bold),
                ),
                Text('${DateTime.now().toString().split(' ')[0]}'),
              ],
            ),

            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_witnessController.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please sign before saving.',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  _saveSignature();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Save',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Future<void> _saveSignature() async {
  //   print(widget.project_id);
  //   print("project_idproject_idproject_id");
  //   final data = await _witnessController.toPngBytes();
  //   final installSignature = widget.installerData;
  //   if (installSignature != null && data != null) {
  //     widget.onSignatureSubmitted(
  //         installSignature, data, _witnessNameController.text);
  //     var box = await Hive.openBox<SignatureData>('signatureBox');
  //     await box.put(
  //       'signatureData',
  //       SignatureData(
  //         id: widget.project_id,
  //         installSignature: installSignature,
  //         witnessSignature: data,
  //         name: _witnessNameController.text,
  //       ),
  //     );
  //     await box.close();
  //   }
  // }
  Future<void> _saveSignature() async {
    print(widget.project_id);
    print("project_idproject_idproject_id");
    final data = await _witnessController.toPngBytes();
    final installSignature = widget.installerData;

    if (installSignature != null && data != null) {
      widget.onSignatureSubmitted(
          installSignature, data, _witnessNameController.text);

      Box<SignatureData>? box;
      try {
        box = await Hive.openBox<SignatureData>('signatureBox');
        await box.put(
          'signatureData',
          SignatureData(
            id: widget.project_id,
            installSignature: installSignature,
            witnessSignature: data,
            name: _witnessNameController.text,
          ),
        );
        print("Signature saved successfully.");
      } catch (e) {
        print("Error saving signature: $e");
      } finally {
        if (box != null && box.isOpen) {
          await box.close();
          print("Box closed properly.");
        }
      }
    }
  }


  @override
  void dispose() {
    _witnessController.dispose();
    _witnessNameController.dispose();
    super.dispose();
  }
}

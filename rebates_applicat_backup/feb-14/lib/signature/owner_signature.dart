import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';

import '../offline_db/signatures/owner_signature_edit.dart';


class OwnerSignature extends StatefulWidget {
  final Function(Uint8List, String) onSignatureSubmitted;
  final Uint8List? existingSignature;
  final String existingName;
  final String title;
  final int projectId;
  final DateTime? customerDate;

  OwnerSignature({
    required this.onSignatureSubmitted,
    this.existingSignature,
    required this.existingName,
    required this.title,
    required this.projectId,
    required this.customerDate,
  });

  @override
  _OwnerSignatureState createState() => _OwnerSignatureState();
}

class _OwnerSignatureState extends State<OwnerSignature> {
  late SignatureController _controller;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  ui.Image? _signatureImage;
  bool _signatureModified = false;
  late String baseUrl = '';
  bool isResigning = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    String ownerDateString = widget.customerDate != null
        ? DateFormat('yyyy-MM-dd').format(widget.customerDate!)
        : 'No date available';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        // toolbarHeight: 90,
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
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: screenSize.height * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                        color: Colors.grey.withOpacity(.3), width: 2),
                  ),
                  child: _signatureImage != null
                      ? CustomPaint(
                          painter: _SignaturePainter(_signatureImage!),
                          child: Container(),
                        )
                      : isResigning
                          ? Signature(
                              controller: _controller,
                              backgroundColor: Colors.white,
                            )
                          : Signature(
                              controller: _controller,
                              backgroundColor: Colors.white,
                            ),
                ),
                if (_signatureImage == null || isResigning)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        _controller.clear();
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
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Signed By:',
                  style: TextStyle(fontWeight: ui.FontWeight.bold),
                ),
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
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Signature Date:',
                  style: TextStyle(fontWeight: ui.FontWeight.bold),
                ),
                Text(ownerDateString),
              ],
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (widget.existingSignature == null || isResigning) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_controller.isEmpty) {
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
                      child: Text('Save',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ),
                  ),
                ],
                if (widget.existingSignature != null && !isResigning) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isResigning = true;
                          // _controller.clear();
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

  // Future<void> _saveSignature() async {
  //   print(widget.projectId);
  //   final data = await _controller.toPngBytes();
  //   if (data != null) {
  //     widget.onSignatureSubmitted(data, _nameController.text);
  //     var box = await Hive.openBox<OwnerSignatureEditData>('ownerSignatureEditBox');
  //     await box.put(
  //       'ownerSignatureEditData',
  //       OwnerSignatureEditData(
  //         id: widget.projectId,
  //         ownerSignature: data,
  //         name: _nameController.text,
  //       ),
  //     );
  //     await box.close();
  //   }
  // }
  Future<void> _saveSignature() async {
    print(widget.projectId);
    final data = await _controller.toPngBytes();

    if (data != null) {
      widget.onSignatureSubmitted(data, _nameController.text);

      Box<OwnerSignatureEditData>? box;
      try {
        box = await Hive.openBox<OwnerSignatureEditData>('ownerSignatureEditBox');
        await box.put(
          'ownerSignatureEditData',
          OwnerSignatureEditData(
            id: widget.projectId,
            ownerSignature: data,
            name: _nameController.text,
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

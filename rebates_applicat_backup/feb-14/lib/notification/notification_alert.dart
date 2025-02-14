import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../installation/installation_form_view.dart';
import 'notification.dart';

class NotificationDetailsDialog extends StatelessWidget {
  final NotificationItem notificationItem;

  NotificationDetailsDialog({required this.notificationItem});

  @override
  Widget build(BuildContext context) {
    print("notificationItemnotificationItemnotificationItem$notificationItem");
    String formattedDate = notificationItem.date != null
        ? DateFormat('yyyy-MM-dd').format(notificationItem.date)
        : 'No Date';
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              notificationItem.title ?? 'No Subject',
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Date:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(formattedDate),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Author:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Text(
                  notificationItem.author ?? 'Unknown',
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Body:',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.1,
                width: MediaQuery.of(context).size.width * 0.6,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  // Scroll vertically
                  child: Text(
                    notificationItem.body,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
        automaticallyImplyLeading: false,
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

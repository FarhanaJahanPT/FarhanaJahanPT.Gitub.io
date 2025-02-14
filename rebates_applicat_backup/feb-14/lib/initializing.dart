import 'package:hive/hive.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';

import '../offline_to_odoo/calendar.dart';
import '../offline_to_odoo/documents.dart';
import '../offline_to_odoo/install_jobs.dart';
import '../offline_to_odoo/notification.dart';
import '../offline_to_odoo/owner_details.dart';
import '../offline_to_odoo/product_and_selfies.dart';
import '../offline_to_odoo/profile.dart';
import '../offline_to_odoo/qr_code.dart';
import '../offline_to_odoo/service_jobs.dart';
import '../offline_to_odoo/signature.dart';
import 'offline_to_odoo/checklist.dart';

class Initializing {
  final InstallJobsBackground installJobsBackground = InstallJobsBackground();
  final ServiceJobsBackground serviceJobsBackground = ServiceJobsBackground();
  final Calendar calendar = Calendar();
  final productsList product = productsList();
  final Profile profile = Profile();
  final NotificationOffline notification = NotificationOffline();
  final documentsList document = documentsList();
  final PartnerDetails partner = PartnerDetails();
  final QrCodeGenerate qrcode = QrCodeGenerate();
  final projectSignatures signatures = projectSignatures();
  final ChecklistStorageService checklist = ChecklistStorageService();

  Future<void> initialize() async {
    try {
      await installJobsBackground.initializeOdooClient();
      await serviceJobsBackground.initializeOdooClient();
      await calendar.initializeOdooClient();
      await product.initializeOdooClient();
      await profile.initializeOdooClient();
      await notification.initializeOdooClient();
      await document.initializeOdooClient();
      await partner.initializeOdooClient();
      await qrcode.initializeOdooClient();
      await signatures.initializeOdooClient();
      await checklist.initializeOdooClient();

      print("Initialization completccccccced successfully.");
    } catch (e) {
      print("Error during initialization: $e");
    }
  }
}

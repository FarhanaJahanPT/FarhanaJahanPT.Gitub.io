import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../background/background_service.dart';
import '../navigation_bar/common_navigation_bar.dart';
import '../offline_to_odoo/calendar.dart';
import '../offline_to_odoo/checklist.dart';
import '../offline_to_odoo/documents.dart';
import '../offline_to_odoo/install_jobs.dart';
import '../offline_to_odoo/owner_details.dart';
import '../offline_to_odoo/product_and_selfies.dart';
import '../offline_to_odoo/profile.dart';
import '../offline_to_odoo/notification.dart';
import '../offline_to_odoo/qr_code.dart';
import '../offline_to_odoo/service_jobs.dart';
import '../offline_to_odoo/signature.dart';
import 'login.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final LocalAuthentication auth = LocalAuthentication();
  bool? _isLoggedIn;
  bool? _useLocalAuth;
  bool _isAuthenticating = false;
  final Profile profile = Profile();
  final ChecklistStorageService checklist = ChecklistStorageService();
  Calendar calendar = Calendar();
  NotificationOffline notification = NotificationOffline();
  projectSignatures signatures = projectSignatures();
  documentsList document = documentsList();
  productsList product = productsList();
  InstallJobsBackground installJobs = InstallJobsBackground();
  ServiceJobsBackground serviceJobs = ServiceJobsBackground();
  QrCodeGenerate qrcode = QrCodeGenerate();
  PartnerDetails owner_details = PartnerDetails();
  bool isNetworkAvailable = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    _checkLoginStatus();
  }

  Future<void> _initialize() async {
    await _checkConnectivity();
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
    });
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _useLocalAuth = prefs.getBool('useLocalAuth') ?? false;
    setState(() {});
  }

  @override
  void dispose() {
    auth.stopAuthentication();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn == null || _useLocalAuth == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLoggedIn!) {
      if (_useLocalAuth!) {
        return FutureBuilder<AuthenticationResult>(
          future: _authenticateWithBiometrics(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            } else {
              switch (authSnapshot.data) {
                case AuthenticationResult.success:
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await _handleSuccessfulLogin();
                  });
                  return Container(
                    color: Colors.white,
                  );
                case AuthenticationResult.unavailable:
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await _handleSuccessfulLogin();
                  });
                  return Container(
                    color: Colors.white,
                  );
                case AuthenticationResult.error:
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await _handleSuccessfulLogin();
                  });
                  return Container(
                    color: Colors.white,
                  );

                default:
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(),
                      ),
                    );
                  });
                  return Container(
                    color: Colors.white,
                  );
              }
            }
          },
        );
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _handleSuccessfulLogin();
        });
        return Container(
          color: Colors.white,
        );
      }
    } else {
      return const LoginScreen();
    }
  }

  Future<void> _handleSuccessfulLogin() async {
    if (isNetworkAvailable) {
      BackgroundService.initializeService();
      // await profile.initializeOdooClient();
      // await calendar.initializeOdooClient();
      // await notification.initializeOdooClient();
      // await signatures.initializeOdooClient();
      // await document.initializeOdooClient();
      // await product.initializeOdooClient();
      // await installJobs.initializeOdooClient();
      // await serviceJobs.initializeOdooClient();
      // await qrcode.initializeOdooClient();
      // await owner_details.initializeOdooClient();
      // await checklist.initializeOdooClient();
      print('kolilolipop');
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(),
      ),
    );
  }

  Future<AuthenticationResult> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return AuthenticationResult.error;

    _isAuthenticating = true;

    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      List<BiometricType> availableBiometrics =
      await auth.getAvailableBiometrics();

      if (canCheckBiometrics && availableBiometrics.isNotEmpty) {
        try {
          final authenticate = await auth.authenticate(
            localizedReason: 'Authenticate to access the app',
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: true,
            ),
          );

          _isAuthenticating = false;

          if (authenticate) {
            return AuthenticationResult.success;
          } else {
            return AuthenticationResult.failure;
          }
        } catch (authError) {
          _isAuthenticating = false;
          return AuthenticationResult.error;
        }
      } else {
        _isAuthenticating = false;
        return AuthenticationResult.unavailable;
      }
    } catch (e) {
      _isAuthenticating = false;
      return AuthenticationResult.error;
    }
  }
}

enum AuthenticationResult {
  success,
  failure,
  error,
  unavailable,
}
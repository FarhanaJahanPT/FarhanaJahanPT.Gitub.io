import 'package:flutter/material.dart';

class RewardsPage extends StatefulWidget {
  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage>
    with SingleTickerProviderStateMixin {
  String profilePicUrl = "";
  String name = "";
  String saaNumber = "";
  bool isLoadingImage = false;
  int installingJobs = 15;
  int completedJobs = 15;
  int currentPoints = 120;
  TextEditingController userNameController = TextEditingController(text: "abc");
  TextEditingController saaNumberController =
      TextEditingController(text: "123");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isLoadingImage)
              CircleAvatar(
                radius: 60.0,
                backgroundColor: Colors.transparent,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else
              CircleAvatar(
                radius: 60.0,
                backgroundColor: Colors.grey[350],
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipOval(
                        child: Image.network(
                          "https://en.wikipedia.org/wiki/Image#/media/File:Image_created_with_a_mobile_phone.png",
                          fit: BoxFit.cover,
                          errorBuilder: (BuildContext context, Object exception,
                              StackTrace? stackTrace) {
                            return Icon(Icons.person, size: 54);
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () async {
                          // await _pickImage(employee_details['id']);
                        },
                        child: CircleAvatar(
                          radius: 20.0,
                          backgroundColor: Colors.green,
                          child: Icon(
                            Icons.camera_alt,
                            size: 20.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 20),
            // Name and SAA Number Section
            Column(
              children: [
                Text(
                  userNameController.text,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "SAA No: ${saaNumberController.text}",
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

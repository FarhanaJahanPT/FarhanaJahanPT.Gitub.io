import 'package:flutter/material.dart';

class EditInstallationDetailsScreen extends StatefulWidget {
  final String serviceType;
  final String description;
  final String nmi;
  final String installedOrNot;

  EditInstallationDetailsScreen(
      {required this.serviceType,
      required this.description,
      required this.nmi,
      required this.installedOrNot});

  @override
  _EditInstallationDetailsScreenState createState() =>
      _EditInstallationDetailsScreenState();
}

class _EditInstallationDetailsScreenState
    extends State<EditInstallationDetailsScreen> {
  late String selectedInstallationType;
  late TextEditingController additionalInfoController;

  @override
  void initState() {
    super.initState();
    selectedInstallationType = widget.serviceType;
    additionalInfoController = TextEditingController(text: widget.description);
  }

  @override
  void dispose() {
    additionalInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.serviceType);
    print("widget.serviceTypewidget.serviceType");
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.serviceType == "Service"
                ? 'Service Details'
                : 'Installation Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Installation Type',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['New Installation', 'Replacement', 'Service']
                          .map((type) => ChoiceChip(
                                label: Text(type),
                                selected: selectedInstallationType == type,
                                // onSelected: (selected) {
                                //   setState(() {
                                //     selectedInstallationType = type;
                                //   });
                                // },
                                onSelected: null,
                                selectedColor: Colors.green,
                                labelStyle: TextStyle(
                                    color: selectedInstallationType == type
                                        ? Colors.white
                                        : Colors.black),
                              ))
                          .toList(),
                    ),
                    SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Meter box phase',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Text(
                          widget.installedOrNot?.isNotEmpty == true
                              ? widget.installedOrNot!
                              : "None",
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                            child: Text('Additional/Upgrade System Information',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold))),
                        Icon(Icons.info_outline, size: 16),
                      ],
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: additionalInfoController,
                      maxLines: 5,
                      maxLength: 4000,
                      decoration: InputDecoration(
                        hintText: 'Additional system information',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                            child: Text('NMI',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold))),
                        SizedBox(width: 8),
                        // Space between the label and the NMI value
                        Text(
                            widget.nmi?.isNotEmpty == true
                                ? widget.nmi!
                                : "None",
                            style: TextStyle(
                              color: Colors.black,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              // child: SingleChildScrollView(
              //   padding: EdgeInsets.all(16.0),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Text('Installation Type',
              //           style: TextStyle(
              //               color: Colors.black, fontWeight: FontWeight.bold)),
              //       SizedBox(height: 8),
              //       Wrap(
              //         spacing: 8,
              //         children: ['New Installation', 'Replacement', 'Service']
              //             .map((type) => ChoiceChip(
              //                   label: Text(type),
              //                   selected: selectedInstallationType == type,
              //                   // onSelected: (selected) {
              //                   //   setState(() {
              //                   //     selectedInstallationType = type;
              //                   //   });
              //                   // },
              //                   onSelected: null,
              //                   selectedColor: Colors.green,
              //                   labelStyle: TextStyle(
              //                       color: selectedInstallationType == type
              //                           ? Colors.white
              //                           : Colors.black),
              //                 ))
              //             .toList(),
              //       ),
              //       SizedBox(height: 25),
              //       Row(
              //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //         children: [
              //           Text('Meter box phase',
              //               style: TextStyle(
              //                   color: Colors.black,
              //                   fontWeight: FontWeight.bold)),
              //           SizedBox(width: 8),
              //           Text(
              //             widget.installedOrNot?.isNotEmpty == true
              //                 ? widget.installedOrNot!
              //                 : "None",
              //             style: TextStyle(
              //               color: Colors.black,),
              //           ),
              //         ],
              //       ),
              //       SizedBox(height: 25),
              //       Row(
              //         children: [
              //           Expanded(
              //               child:
              //                   Text('Additional/Upgrade System Information',
              //                       style: TextStyle(
              //                           color: Colors.black,
              //                           fontWeight: FontWeight.bold))),
              //           Icon(Icons.info_outline, size: 16),
              //         ],
              //       ),
              //       SizedBox(height: 8),
              //       TextField(
              //         controller: additionalInfoController,
              //         maxLines: 5,
              //         maxLength: 4000,
              //         decoration: InputDecoration(
              //           hintText: 'Additional system information',
              //           border: OutlineInputBorder(),
              //         ),
              //       ),
              //       SizedBox(height: 25),
              //       Row(
              //         children: [
              //           Expanded(child: Text('NMI',
              //               style: TextStyle(
              //                   color: Colors.black,
              //                   fontWeight: FontWeight.bold))),
              //           SizedBox(width: 8), // Space between the label and the NMI value
              //           Text(widget.nmi?.isNotEmpty == true
              //               ? widget.nmi!
              //               : "None", style: TextStyle(
              //             color: Colors.black,)),
              //         ],
              //       ),
              //     ],
              //   ),
              // ),
            ),
            // Padding(
            //   padding: EdgeInsets.all(16.0),
            //   child: SizedBox(
            //     width: double.infinity,
            //     child: ElevatedButton(
            //       child: Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            //       onPressed: () {
            //         // Save logic here
            //       },
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: Colors.green,
            //         padding: EdgeInsets.symmetric(vertical: 16),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

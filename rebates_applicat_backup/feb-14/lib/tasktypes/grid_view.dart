import 'package:flutter/material.dart';

class GridConnectedScreen extends StatefulWidget {
  @override
  _GridConnectedScreenState createState() => _GridConnectedScreenState();
}

class _GridConnectedScreenState extends State<GridConnectedScreen> {
  bool isOnGrid = true;
  TextEditingController nationalMeterController = TextEditingController();
  TextEditingController gridConnectionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grid-Connected',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Connect Type',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      child: Text('On-Grid'),
                      onPressed: () => setState(() => isOnGrid = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isOnGrid ? Colors.green : Colors.grey[300],
                        foregroundColor: isOnGrid ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      child: Text('Off-Grid'),
                      onPressed: () => setState(() => isOnGrid = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            !isOnGrid ? Colors.green : Colors.grey[300],
                        foregroundColor:
                            !isOnGrid ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text('National Meter Identifier',
                  style: TextStyle(color: Colors.red)),
              TextField(
                controller: nationalMeterController,
                decoration: InputDecoration(
                  hintText: '4311111111',
                  suffixIcon: Icon(Icons.info_outline),
                ),
              ),
              SizedBox(height: 16),
              Text('Grid connection Application Ref No.'),
              TextField(
                controller: gridConnectionController,
                decoration: InputDecoration(
                  suffixIcon: Icon(Icons.info_outline),
                ),
              ),
              Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text('Save'),
                  onPressed: () {
                    // Implement save functionality
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

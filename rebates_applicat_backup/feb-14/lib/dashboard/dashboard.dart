import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final NotchBottomBarController _controller =
      NotchBottomBarController(index: -1);
  final int maxCount = 3;
  final List<String> bottomBarPages = [
    'Solar Installation',
    'Calendar',
    'Service Jobs'
  ];
  int unreadCount = 0;

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var padding = screenSize.width * 0.04;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/notifications');
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_rounded,
                    color: Colors.white, size: 35),
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: Colors.green[700],
            radius: 24,
            child: IconButton(
              icon: Icon(
                Icons.person,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/profile_main');
              },
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenSize.height * 0.05),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                      'Scheduled', '12', Colors.red, Icons.schedule),
                ),
                SizedBox(width: padding),
                Expanded(
                  child: _buildStatCard(
                      'Installed', '16', Colors.green, Icons.solar_power),
                ),
              ],
            ),
            SizedBox(height: screenSize.height * 0.03),
            Text(
              'Job Status',
              style: TextStyle(
                fontSize: responsiveFontSize(28.0, 20.0),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: padding),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 20),
              height: screenSize.height * 0.4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: Colors.grey[200],
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[200]!,
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: _buildBarChart(),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: (bottomBarPages.length <= maxCount)
          ? AnimatedNotchBottomBar(
              notchBottomBarController: _controller,
              color: Colors.green,
              showLabel: true,
              notchColor: Colors.green,
              kBottomRadius: 28.0,
              kIconSize: 24.0,
              removeMargins: false,
              bottomBarWidth: MediaQuery.of(context).size.width * 0.1,
              durationInMilliSeconds: 300,
              bottomBarItems: [
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.solar_power,
                    color: Colors.white,
                  ),
                  activeItem: Icon(
                    Icons.solar_power,
                    color: Colors.white,
                  ),
                  itemLabelWidget:
                      _buildLabelWidget('Installation', Colors.white),
                ),
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                  ),
                  activeItem: Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                  ),
                  itemLabelWidget: _buildLabelWidget('Calendar', Colors.white),
                ),
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.build,
                    color: Colors.white,
                  ),
                  activeItem: Icon(
                    Icons.build,
                    color: Colors.white,
                  ),
                  itemLabelWidget:
                      _buildLabelWidget('Service Jobs', Colors.white),
                ),
              ],
              onTap: (index) async {
                switch (index) {
                  case 0:
                    Navigator.pushNamed(context, '/installing_list_view');
                    break;
                  case 1:
                    Navigator.pushNamed(context, '/calendar');
                    break;
                  case 2:
                    Navigator.pushNamed(context, '/service_jobs_list');
                    break;
                }
              },
            )
          : null,
    );
  }

  Widget _buildLabelWidget(String labelText, Color color) {
    return Text(
      labelText,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 9,
      ),
    );
  }

  // Widget _buildStatCard(String headerText, String valueText, Color color, IconData icon) {
  //   var screenWidth = MediaQuery.of(context).size.width;
  //   return Container(
  //     height: screenWidth * 0.4,
  //     width: screenWidth * 0.4,
  //     decoration: BoxDecoration(
  //       color: Colors.grey[200],
  //       borderRadius: BorderRadius.circular(15.0),
  //     ),
  //     child: Padding(
  //       padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
  //       child: Center(
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             // Icon(
  //             //   icon,
  //             //   size: 50.0, // Adjust the size as needed
  //             //   color: headerText == 'Total Installed \nJobs?' ? Colors.black54 : Colors.blue,
  //             // ),
  //             // SizedBox(height: MediaQuery.of(context).size.height * 0.01),
  //             Text(
  //               headerText,
  //               style: TextStyle(
  //                 fontSize: responsiveFontSize(16.0, 16.0),
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.black,
  //               ),
  //               textAlign: TextAlign.center,
  //             ),
  //             SizedBox(height: MediaQuery.of(context).size.height * 0.008),
  //             Text(
  //               valueText,
  //               style: TextStyle(
  //                 fontSize: responsiveFontSize(25.0, 25.0),
  //                 fontWeight: FontWeight.bold,
  //                 color: color,
  //               ),
  //               textAlign: TextAlign.center,
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildStatCard(
      String headerText, String valueText, Color color, IconData icon) {
    var screenWidth = MediaQuery.of(context).size.width;
    return Container(
      height: screenWidth * 0.4,
      width: screenWidth * 0.4,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 100.0,
                color: Colors.orange.withOpacity(0.1),
              ),
            ),
          ),
          // Foreground content (Text)
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    headerText,
                    style: TextStyle(
                      fontSize: responsiveFontSize(16.0, 16.0),
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.008),
                  Text(
                    valueText,
                    style: TextStyle(
                      fontSize: responsiveFontSize(25.0, 25.0),
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double responsiveFontSize(double largeSize, double smallSize) {
    var screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 600 ? largeSize : smallSize;
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 50,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: _getBottomTitles,
            ),
          ),
        ),
        barGroups: _getBarGroups(),
        borderData: FlBorderData(
          show: false,
        ),
        gridData: FlGridData(show: false),
      ),
    );
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    const titles = ['Scheduled', 'Installing', 'Unqualified', 'Installed'];
    String text = titles[value.toInt()];
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(text,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    return [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(toY: 21, color: Colors.blue, width: 20),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(toY: 42, color: Colors.blue, width: 20),
        ],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(toY: 34, color: Colors.blue, width: 20),
        ],
      ),
      BarChartGroupData(
        x: 3,
        barRods: [
          BarChartRodData(toY: 18, color: Colors.blue, width: 20),
        ],
      ),
    ];
  }
}

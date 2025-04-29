import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapwise/admin/controller.dart';

class Sidebar extends StatelessWidget {
  final VoidCallback onLogout;
  final String currentScreen;

  const Sidebar({
    super.key,
    required this.onLogout,
    required this.currentScreen,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 250,
          height: screenHeight * 0.82,
          decoration: const BoxDecoration(
            color: Color(0xFF1A2A44),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'sachinv@edh.com',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 40),
                  _buildNavItem(icon: Icons.dashboard, title: 'ACTIVITY LOGS'),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: InkWell(
                      onTap: onLogout,
                      child: const Row(
                        children: [
                          Icon(Icons.logout, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Logout',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: -40,
                left: 0,
                right: 0,
                child: Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                      'https://tse1.mm.bing.net/th?id=OIP.brmotDoTzzPa59L82D2vigHaHa&pid=Api&P=0&h=220',
                    ),
                    onBackgroundImageError: (error, stackTrace) {
                      // Optional: Handle image loading errors
                      print('Failed to load avatar image: $error');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  String _selectedTimePeriod = 'Last 30 days';

  final List<String> _timePeriods = [
    'Last 24 hours',
    'Last 7 days',
    'Last 30 days',
    'Last 3 months',
    'Last 6 months',
    'Last year',
  ];
  final _controller = Get.put(Controller());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.withOpacity(0.1),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        backgroundColor: Colors.grey.shade200,
        title: Row(
          children: [
            Image.asset('assets/logo.png', width: 80, height: 80),
            const Text(
              'SnapWise',
              style: TextStyle(
                color: Color.fromARGB(255, 3, 30, 53),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          Sidebar(
            onLogout: () {
              Navigator.pushReplacementNamed(context, '/admin-login');
            },
            currentScreen: 'activity_logs',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 60, right: 30, left: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Obx(() {
                      Future.delayed(Duration(seconds: 1));
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            title: 'Total User',
                            value: _controller.totalUsers.toString(),
                            // change: '+ 20% this month',
                            iconImagePath: 'assets/totalusers.jpg',
                            iconColor: Colors.green,
                          ),
                          VerticalDivider(
                            color: Colors.grey.shade200,
                            thickness: 1,
                            width: 20,
                          ),
                          _buildStatItem(
                            title: 'Online',
                            value: _controller.totalActiveUsers.toString(),
                            // change: '+ 20% this month',
                            iconImagePath: 'assets/online.jpg',
                            iconColor: Colors.green,
                          ),
                          VerticalDivider(
                            color: Colors.grey.shade200,
                            thickness: 1,
                            width: 20,
                          ),
                          _buildStatItem(
                            title: 'Offline',
                            value: _controller.totalInactiveUsers.toString(),
                            // change: '+ 11% this month',
                            iconImagePath: 'assets/offline.jpg',
                            iconColor: Colors.red,
                          ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  // Activity Logs Section
                  Container(
                    height: 450,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Activity Logs',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedTimePeriod,
                                style: const TextStyle(color: Colors.black),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedTimePeriod = newValue;
                                    });
                                    // Here you can add logic to fetch data for the selected time period
                                    // For example: _controller.fetchDataForPeriod(_selectedTimePeriod);
                                  }
                                },
                                items:
                                    _timePeriods.map<DropdownMenuItem<String>>((
                                      String value,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SizedBox(
                              width: double.infinity,
                              child: Obx(() {
                                _controller.fetchData();

                                return DataTable(
                                  columnSpacing: 10,
                                  dataRowHeight: 60,
                                  columns: const [
                                    DataColumn(
                                      label: Expanded(
                                        child: Text(
                                          'User',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // DataColumn(
                                    //   label: Expanded(
                                    //     child: Text(
                                    //       'Phone Number',
                                    //       style: TextStyle(
                                    //         fontWeight: FontWeight.bold,
                                    //       ),
                                    //     ),
                                    //   ),
                                    // ),
                                    DataColumn(
                                      label: Expanded(
                                        child: Text(
                                          'Email',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Expanded(
                                        child: Text(
                                          'Country',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Expanded(
                                        child: Text(
                                          'Status',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows:
                                      _controller.data.map((log) {
                                        return _buildDataRow(
                                          user: log['displayName'].toString(),

                                          email: log['email'].toString(),
                                          ip: log['country'].toString(),
                                          status: log['status'].toString(),
                                          statusColor:
                                              log['status'] == 'active'
                                                  ? Colors.green
                                                  : Colors.red,
                                        );
                                      }).toList(),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    // required String change,
    required Color iconColor,
    required String iconImagePath,
  }) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.2),
          radius: 40,
          child: Container(
            padding: const EdgeInsets.all(5),
            child: Image.asset(iconImagePath, width: 40, height: 40),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            // Text(change, style: TextStyle(fontSize: 15, color: iconColor)),
          ],
        ),
      ],
    );
  }

  DataRow _buildDataRow({
    required String user,

    required String email,
    required String ip,
    required String status,
    required Color statusColor,
  }) {
    return DataRow(
      cells: [
        DataCell(Text(user)),

        DataCell(Text(email)),
        DataCell(Text(ip)),
        DataCell(
          Container(
            width: 100,
            height: 35,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

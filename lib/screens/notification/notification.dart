// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> notifications = [
    {
      "title": "Shopping Budget has exceeded",
      "description": "Your Shopping budget has exceeded the limit",
      "time": "10:30 AM",
      "icon": Icons.shopping_bag,
      "color": Colors.orange,
      "isRead": false,
    },
    {
      "title": "Utilities Budget has exceeded",
      "description": "Your Utilities budget has exceeded the limit",
      "time": "Yesterday",
      "icon": Icons.bolt,
      "color": Colors.blue,
      "isRead": false,
    },
    {
      "title": "Shopping Budget has exceeded",
      "description": "Your Shopping budget has exceeded the limit",
      "time": "10:30 AM",
      "icon": Icons.shopping_bag,
      "color": Colors.orange,
      "isRead": false,
    },
  ];

  bool get isTablet {
    final data = MediaQueryData.fromView(WidgetsBinding.instance.window);
    return data.size.shortestSide > 600;
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification["isRead"] = true;
      }
    });
  }

  void _removeAllNotifications() {
    setState(() {
      notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        title: Text(
          "Notifications", 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: isTablet ? 24 : 20
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            padding: EdgeInsets.only(right: isTablet ? 25 : 15),
            icon: Icon(
              Icons.more_horiz, 
              color: Colors.black,
              size: isTablet ? 28 : 24,
            ),
            color: Colors.grey.shade100,
            onSelected: (value) {
              if (value == 'mark_all_read') {
                _markAllAsRead();
              } else if (value == 'remove_all') {
                _removeAllNotifications();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  padding: EdgeInsets.only(left: isTablet ? 20 : 15),
                  value: 'mark_all_read',
                  child: Text(
                    'Mark all as read',
                    style: TextStyle(fontSize: isTablet ? 18 : 14),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'remove_all',
                  child: Text(
                    'Remove all',
                    style: TextStyle(fontSize: isTablet ? 18 : 14),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                "There are no notifications",
                style: TextStyle(fontSize: isTablet ? 20 : 16),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 30 : 20, 
                vertical: isTablet ? 20 : 10
              ),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                var notification = notifications[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: isTablet ? 15 : 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isTablet ? 15 : 10),
                      border: Border.all(
                        color: notification["isRead"] 
                            ? Colors.transparent 
                            : Colors.blue.withOpacity(0.3),
                        width: isTablet ? 2 : 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isTablet ? 20 : 15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isTablet ? 12 : 8),
                            decoration: BoxDecoration(
                              color: notification["color"].withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              notification["icon"],
                              color: notification["color"],
                              size: isTablet ? 30 : 24,
                            ),
                          ),
                          SizedBox(width: isTablet ? 20 : 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification["title"],
                                  style: TextStyle(
                                    fontSize: isTablet ? 20 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: notification["isRead"] 
                                        ? Colors.black 
                                        : Colors.blue,
                                  ),
                                ),
                                SizedBox(height: isTablet ? 8 : 5),
                                Text(
                                  notification["description"],
                                  style: TextStyle(
                                    fontSize: isTablet ? 16 : 14,
                                    color: notification["isRead"]
                                        ? Colors.grey.shade600
                                        : Colors.blue.withOpacity(0.8),
                                  ),
                                ),
                                SizedBox(height: isTablet ? 8 : 5),
                                Text(
                                  notification["time"],
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: isTablet ? 14 : 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!notification["isRead"])
                            Container(
                              width: isTablet ? 10 : 8,
                              height: isTablet ? 10 : 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
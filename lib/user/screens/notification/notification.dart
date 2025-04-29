// ignore_for_file: deprecated_member_use
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapwise/user/screens/notification/notification_controller.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationController _controller = Get.put(NotificationController());

  bool get isTablet {
    final data = MediaQueryData.fromView(WidgetsBinding.instance.window);
    return data.size.shortestSide > 600;
  }

  void _markAllAsRead() {
    _controller.markAllAsRead();
  }

  void _removeAllNotifications() {
    _controller.removeAllNotifications();
  }

  String _formatTime(DateTime timestamp) {
    return timeago.format(timestamp, allowFromNow: true);
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await _controller.fetchNotifications();
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
            fontSize: isTablet ? 24 : 20,
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
      body: Obx(
        () =>
            _controller.notifications.isEmpty
                ? Center(
                  child: Text(
                    "There are no notifications",
                    style: TextStyle(fontSize: isTablet ? 20 : 16),
                  ),
                )
                : ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 30 : 20,
                    vertical: isTablet ? 20 : 10,
                  ),
                  itemCount: _controller.notifications.length,
                  itemBuilder: (context, index) {
                    var notification = _controller.notifications[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: isTablet ? 15 : 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            isTablet ? 15 : 10,
                          ),
                          border: Border.all(
                            color:
                                notification["isRead"]
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
                                        color:
                                            notification["isRead"]
                                                ? Colors.black
                                                : Colors.blue,
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 8 : 5),
                                    Text(
                                      notification["description"],
                                      style: TextStyle(
                                        fontSize: isTablet ? 16 : 14,
                                        color:
                                            notification["isRead"]
                                                ? Colors.grey.shade600
                                                : Colors.blue.withOpacity(0.8),
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 8 : 5),
                                    Text(
                                      _formatTime(
                                        notification["timestamp"].toDate(),
                                      ),
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
      ),
    );
  }
}

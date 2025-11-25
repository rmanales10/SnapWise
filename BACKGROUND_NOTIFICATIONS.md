# Background Notification System Implementation

## Overview
This implementation enables **SMS and Push Notifications** to be sent even when the SnapWise app is **not currently opened or running**. It also includes a robust **duplicate prevention system** to ensure the same notification is not sent multiple times.

## Key Features

### 1. **Background Execution**
- Uses **WorkManager** to run periodic background tasks every 15 minutes
- Checks for notifications that need to be sent (budget alerts, payment reminders)
- Works even when the app is completely closed

### 2. **Duplicate Prevention**
- Tracks all sent notifications with timestamps in local storage
- Prevents duplicate notifications within a 24-hour window
- Uses a unique key system: `{userId}_{notificationType}_{notificationKey}`
- Automatically cleans up old notification records

### 3. **Notification Types Supported**
- **Budget Exceeded Alerts** (Overall & Category)
- **Payment Due Today** (with SMS)
- **Payment Due Soon** (1-3 days)
- **Payment Overdue** (with SMS)
- **Income Alerts**
- **Expense Added**

## Implementation Details

### Files Created/Modified

#### 1. **background_notification_service.dart** (NEW)
- Core background service implementation
- Handles WorkManager initialization and task scheduling
- Implements duplicate prevention logic
- Checks budget alerts and payment reminders in background

#### 2. **notification_service.dart** (MODIFIED)
- Integrated with BackgroundNotificationService
- Uses centralized duplicate prevention
- Marks notifications as sent after successful delivery

#### 3. **main.dart** (MODIFIED)
- Initializes BackgroundNotificationService on app startup
- Only runs on mobile platforms (not web)

#### 4. **AndroidManifest.xml** (MODIFIED)
- Added required permissions:
  - `RECEIVE_BOOT_COMPLETED` - Start background tasks after device reboot
  - `WAKE_LOCK` - Keep device awake for background tasks
  - `SCHEDULE_EXACT_ALARM` - Schedule exact notification times
  - `POST_NOTIFICATIONS` - Show notifications (Android 13+)
  - `FOREGROUND_SERVICE` - Run foreground services
  - `INTERNET` - Network access for Firebase/SMS

## How It Works

### Background Task Flow
```
1. App starts → Initialize BackgroundNotificationService
2. WorkManager schedules periodic task (every 15 minutes)
3. Background task runs:
   a. Initialize Firebase in background isolate
   b. Clean up old notification history (>24 hours)
   c. Check for budget alerts
   d. Check for payment reminders
   e. Send notifications if conditions met
   f. Mark notifications as sent
4. Repeat every 15 minutes
```

### Duplicate Prevention Flow
```
1. Before sending notification:
   a. Generate unique key: {userId}_{type}_{key}
   b. Check if notification was sent in last 24 hours
   c. If yes → Skip notification
   d. If no → Send notification
2. After sending:
   a. Mark notification as sent with timestamp
   b. Store in GetStorage for persistence
3. Periodic cleanup:
   a. Remove records older than 24 hours
```

## Usage Examples

### Sending a Budget Alert (Automatic)
```dart
// The background service automatically checks every 15 minutes
// No manual intervention needed

// If you want to trigger manually:
final notificationService = Get.find<NotificationService>();
await notificationService.showOverallBudgetExceeded(
  totalExpenses: 5000,
  budgetLimit: 4000,
  exceededAmount: 1000,
);
```

### Checking Notification History
```dart
// Check if notification was sent
final wasSent = await BackgroundNotificationService.wasNotificationSent(
  userId: 'user123',
  notificationType: 'budget_exceeded',
  notificationKey: 'budget_4000',
);

// Clean up old history
await BackgroundNotificationService.cleanupOldHistory();
```

### Canceling Background Tasks
```dart
// Stop all background notification checks
await BackgroundNotificationService.cancelAll();
```

## Configuration

### Adjust Background Task Frequency
Edit `background_notification_service.dart`:
```dart
await Workmanager().registerPeriodicTask(
  PERIODIC_TASK_NAME,
  TASK_NAME,
  frequency: const Duration(minutes: 15), // Change this value
  constraints: Constraints(
    networkType: NetworkType.connected,
  ),
);
```

### Adjust Duplicate Prevention Window
Edit `background_notification_service.dart`:
```dart
static const Duration DUPLICATE_WINDOW = Duration(hours: 24); // Change this value
```

## Testing

### Test Background Notifications
1. **Close the app completely**
2. **Wait 15 minutes** (or adjust frequency for testing)
3. **Create a condition** that triggers a notification:
   - Exceed your budget
   - Have a payment due today
4. **Check if notification appears** even with app closed

### Test Duplicate Prevention
1. **Trigger a notification** (e.g., exceed budget)
2. **Try to trigger the same notification again**
3. **Verify** that duplicate is prevented
4. **Wait 24 hours** and try again
5. **Verify** that notification is sent after window expires

## Troubleshooting

### Notifications Not Appearing
1. **Check permissions**: Ensure all permissions are granted in device settings
2. **Check battery optimization**: Disable battery optimization for SnapWise
3. **Check logs**: Look for error messages in console
4. **Verify Firebase**: Ensure Firebase is properly initialized

### Duplicate Notifications Still Appearing
1. **Check GetStorage**: Ensure GetStorage is initialized
2. **Check notification keys**: Verify unique keys are being generated
3. **Clear storage**: Try clearing app data and testing again

### Background Tasks Not Running
1. **Check WorkManager**: Ensure WorkManager is initialized
2. **Check constraints**: Verify network is available
3. **Check Android version**: Some manufacturers restrict background tasks
4. **Check battery saver**: Disable battery saver mode

## Performance Considerations

### Battery Usage
- Background tasks run every 15 minutes (minimal battery impact)
- Tasks are lightweight (only check conditions, don't process heavy data)
- Uses WorkManager which is battery-optimized

### Storage Usage
- Notification history is stored locally
- Automatic cleanup prevents storage bloat
- Maximum 24 hours of history stored

### Network Usage
- Only makes network calls when notifications need to be sent
- SMS only sent for critical notifications (payment due, overdue)
- Firestore queries are optimized with indexes

## Future Enhancements

1. **User-configurable frequency**: Let users choose how often to check
2. **Smart scheduling**: Check more frequently during business hours
3. **Notification priority**: Different frequencies for different notification types
4. **Analytics**: Track notification delivery rates
5. **A/B testing**: Test different notification strategies

## Dependencies

```yaml
dependencies:
  workmanager: ^0.7.0
  flutter_local_notifications: ^19.2.1
  get_storage: ^2.1.1
  firebase_core: ^3.13.0
  cloud_firestore: ^5.6.6
  firebase_auth: ^5.5.2
```

## Security Considerations

- User phone numbers are stored securely in Firebase
- SMS API key is hardcoded (consider using environment variables)
- Notification history is stored locally (consider encryption)
- Background tasks only run for authenticated users

## Compliance

- **GDPR**: Users can disable notifications in settings
- **Privacy**: No personal data is sent to third parties (except SMS provider)
- **Permissions**: All permissions are clearly explained to users

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the implementation code
3. Check Firebase console for errors
4. Review device logs for detailed error messages

---

**Last Updated**: November 25, 2025
**Version**: 1.0.0
**Author**: SnapWise Development Team

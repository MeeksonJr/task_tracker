import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task_model.dart';

// service for task due date reminders & local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // initialize plugin and timezone database
  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings: initSettings,
    );

    // request notification and alarm permissions on Android
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    _initialized = true;
  }

  // standard notification channel for tasks
  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Notifications for upcoming task deadlines',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
  }

  // schedule reminder for a task at its due date
  Future<void> scheduleTaskReminder(Task task) async {
    await init();

    // cancel any previous notification for this task
    await cancelTaskReminder(task.id);

    // don't schedule if task is already completed or in the past
    if (task.status == TaskStatus.completed) return;
    if (task.dueDate.isBefore(DateTime.now())) return;

    final scheduledDate = tz.TZDateTime.from(task.dueDate, tz.local);

    try {
      await _notifications.zonedSchedule(
        id: task.id.hashCode,
        title: 'Task Due: ${task.title}',
        body: 'Priority: ${task.priority.name.toUpperCase()} • Assigned to: ${task.assigneeName}',
        scheduledDate: scheduledDate,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: task.id,
      );
    } catch (_) {
      // fallback in case exact alarms aren't allowed
      try {
        await _notifications.zonedSchedule(
          id: task.id.hashCode,
          title: 'Task Due: ${task.title}',
          body: 'Priority: ${task.priority.name.toUpperCase()}',
          scheduledDate: scheduledDate,
          notificationDetails: _notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: task.id,
        );
      } catch (_) {}
    }
  }

  // cancel reminder for a task
  Future<void> cancelTaskReminder(String taskId) async {
    await _notifications.cancel(id: taskId.hashCode);
  }

  // show an immediate notification (useful for testing or instant alerts)
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(),
      payload: payload,
    );
  }
}

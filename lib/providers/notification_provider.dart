import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

// provides singleton instance of NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

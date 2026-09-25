import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// types of activity on a task
enum ActivityType {
  created,
  statusChanged,
  assigned,
  updated,
  commentAdded;

  String get label {
    switch (this) {
      case ActivityType.created:
        return 'Created';
      case ActivityType.statusChanged:
        return 'Status Changed';
      case ActivityType.assigned:
        return 'Reassigned';
      case ActivityType.updated:
        return 'Updated';
      case ActivityType.commentAdded:
        return 'Commented';
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityType.created:
        return Icons.add_circle_outline;
      case ActivityType.statusChanged:
        return Icons.check_circle_outline;
      case ActivityType.assigned:
        return Icons.person_pin_outlined;
      case ActivityType.updated:
        return Icons.edit_outlined;
      case ActivityType.commentAdded:
        return Icons.chat_bubble_outline;
    }
  }

  static ActivityType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'statuschanged':
      case 'status_changed':
        return ActivityType.statusChanged;
      case 'assigned':
        return ActivityType.assigned;
      case 'updated':
        return ActivityType.updated;
      case 'commentadded':
      case 'comment_added':
        return ActivityType.commentAdded;
      case 'created':
      default:
        return ActivityType.created;
    }
  }
}

// audit trail record
class TaskActivity {
  final String id;
  final String taskId;
  final String userId;
  final String userName;
  final ActivityType type;
  final String details;
  final DateTime timestamp;

  const TaskActivity({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.userName,
    required this.type,
    required this.details,
    required this.timestamp,
  });

  // convert to firestore map
  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'userId': userId,
      'userName': userName,
      'type': type.name,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // parse from firestore doc
  factory TaskActivity.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return TaskActivity.fromMap(doc.data() ?? {}, doc.id);
  }

  // parse from map
  factory TaskActivity.fromMap(Map<String, dynamic> data, [String id = '']) {
    final rawDate = data['timestamp'];
    DateTime timestampDate;
    if (rawDate is Timestamp) {
      timestampDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      timestampDate = rawDate;
    } else {
      timestampDate = DateTime.now();
    }

    return TaskActivity(
      id: id,
      taskId: data['taskId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'User',
      type: ActivityType.fromString(data['type'] as String?),
      details: data['details'] as String? ?? '',
      timestamp: timestampDate,
    );
  }
}

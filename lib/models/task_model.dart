import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// task priority levels
enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }

  static TaskPriority fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'low':
        return TaskPriority.low;
      case 'high':
        return TaskPriority.high;
      case 'urgent':
        return TaskPriority.urgent;
      case 'medium':
      default:
        return TaskPriority.medium;
    }
  }
}

// task status states
enum TaskStatus {
  todo,
  inProgress,
  completed;

  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  static TaskStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'inprogress':
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'todo':
      default:
        return TaskStatus.todo;
    }
  }
}

// main task model
class Task {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime dueDate;
  final String creatorId;
  final String creatorName;
  final String assigneeId;
  final String assigneeName;
  final List<String> attachmentUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.creatorId,
    required this.creatorName,
    required this.assigneeId,
    required this.assigneeName,
    this.attachmentUrls = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => status == TaskStatus.completed;

  bool get isOverdue {
    if (isCompleted) return false;
    return dueDate.isBefore(DateTime.now());
  }

  // copy with new fields
  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    String? creatorId,
    String? creatorName,
    String? assigneeId,
    String? assigneeName,
    List<String>? attachmentUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // convert to firestore map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'priority': priority.name,
      'status': status.name,
      'dueDate': Timestamp.fromDate(dueDate),
      'creatorId': creatorId,
      'creatorName': creatorName,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'attachmentUrls': attachmentUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // parse from firestore doc
  factory Task.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final dueTs = data['dueDate'] as Timestamp?;
    final createdTs = data['createdAt'] as Timestamp?;
    final updatedTs = data['updatedAt'] as Timestamp?;

    return Task(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      priority: TaskPriority.fromString(data['priority'] as String?),
      status: TaskStatus.fromString(data['status'] as String?),
      dueDate: dueTs?.toDate() ?? DateTime.now().add(const Duration(days: 1)),
      creatorId: data['creatorId'] as String? ?? '',
      creatorName: data['creatorName'] as String? ?? 'Unknown',
      assigneeId: data['assigneeId'] as String? ?? '',
      assigneeName: data['assigneeName'] as String? ?? 'Unassigned',
      attachmentUrls: List<String>.from(data['attachmentUrls'] as List? ?? []),
      createdAt: createdTs?.toDate() ?? DateTime.now(),
      updatedAt: updatedTs?.toDate() ?? DateTime.now(),
    );
  }
}

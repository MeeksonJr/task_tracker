import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/task_model.dart';

void main() {
  group('Task Model Tests', () {
    test('Task correctly identifies overdue status', () {
      final pastDueTask = Task(
        id: '1',
        title: 'Past Task',
        description: 'Test',
        priority: TaskPriority.high,
        status: TaskStatus.todo,
        dueDate: DateTime.now().subtract(const Duration(hours: 2)),
        creatorId: 'user1',
        creatorName: 'User One',
        assigneeId: 'user2',
        assigneeName: 'User Two',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final completedPastTask = pastDueTask.copyWith(
        status: TaskStatus.completed,
      );

      final futureTask = pastDueTask.copyWith(
        dueDate: DateTime.now().add(const Duration(days: 2)),
      );

      expect(pastDueTask.isOverdue, isTrue);
      expect(completedPastTask.isOverdue, isFalse);
      expect(futureTask.isOverdue, isFalse);
    });

    test('TaskPriority parses strings accurately', () {
      expect(TaskPriority.fromString('low'), TaskPriority.low);
      expect(TaskPriority.fromString('medium'), TaskPriority.medium);
      expect(TaskPriority.fromString('high'), TaskPriority.high);
      expect(TaskPriority.fromString('urgent'), TaskPriority.urgent);
      expect(TaskPriority.fromString(null), TaskPriority.medium);
    });

    test('TaskStatus parses strings accurately', () {
      expect(TaskStatus.fromString('todo'), TaskStatus.todo);
      expect(TaskStatus.fromString('inProgress'), TaskStatus.inProgress);
      expect(TaskStatus.fromString('in_progress'), TaskStatus.inProgress);
      expect(TaskStatus.fromString('completed'), TaskStatus.completed);
      expect(TaskStatus.fromString(null), TaskStatus.todo);
    });
  });
}

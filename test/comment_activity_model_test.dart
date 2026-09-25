import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/activity_model.dart';
import 'package:task_tracker/models/comment_model.dart';

void main() {
  group('Comment & Activity Model Tests', () {
    test('Comment model serializes to and from map', () {
      final now = DateTime.now();
      final comment = Comment(
        id: 'c1',
        taskId: 't1',
        authorId: 'u1',
        authorName: 'Alice',
        content: 'Looks good!',
        createdAt: now,
      );

      final map = comment.toMap();
      expect(map['taskId'], 't1');
      expect(map['authorName'], 'Alice');
      expect(map['content'], 'Looks good!');

      final restored = Comment.fromMap(map, 'c1');
      expect(restored.id, 'c1');
      expect(restored.authorName, 'Alice');
      expect(restored.content, 'Looks good!');
    });

    test('ActivityType parses correctly from strings', () {
      expect(ActivityType.fromString('created'), ActivityType.created);
      expect(ActivityType.fromString('statusChanged'), ActivityType.statusChanged);
      expect(ActivityType.fromString('commentAdded'), ActivityType.commentAdded);
      expect(ActivityType.fromString('updated'), ActivityType.updated);
      expect(ActivityType.fromString('unknown_type'), ActivityType.updated);
    });

    test('TaskActivity serializes to and from map', () {
      final now = DateTime.now();
      final activity = TaskActivity(
        id: 'a1',
        taskId: 't1',
        userId: 'u1',
        userName: 'Alice',
        type: ActivityType.commentAdded,
        details: 'Added a comment',
        timestamp: now,
      );

      final map = activity.toMap();
      expect(map['taskId'], 't1');
      expect(map['type'], 'commentAdded');

      final restored = TaskActivity.fromMap(map, 'a1');
      expect(restored.id, 'a1');
      expect(restored.type, ActivityType.commentAdded);
      expect(restored.details, 'Added a comment');
    });
  });
}

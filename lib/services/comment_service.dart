import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_model.dart';
import '../models/comment_model.dart';

// service to manage task comments and activity log
class CommentService {
  final FirebaseFirestore _firestore;

  CommentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _commentsRef(String taskId) =>
      _firestore.collection('tasks').doc(taskId).collection('comments');

  CollectionReference<Map<String, dynamic>> _activitiesRef(String taskId) =>
      _firestore.collection('tasks').doc(taskId).collection('activities');

  // stream comments ordered by time
  Stream<List<Comment>> commentsStream(String taskId) {
    return _commentsRef(taskId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    });
  }

  // add comment and log to activity
  Future<void> addComment({
    required String taskId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    final now = DateTime.now();

    final comment = Comment(
      id: '',
      taskId: taskId,
      authorId: authorId,
      authorName: authorName,
      content: content.trim(),
      createdAt: now,
    );

    // save comment
    await _commentsRef(taskId).add(comment.toMap());

    // log comment activity
    final activity = TaskActivity(
      id: '',
      taskId: taskId,
      userId: authorId,
      userName: authorName,
      type: ActivityType.commentAdded,
      details: 'Added a comment',
      timestamp: now,
    );
    await _activitiesRef(taskId).add(activity.toMap());
  }

  // stream activity audit trail
  Stream<List<TaskActivity>> activitiesStream(String taskId) {
    return _activitiesRef(taskId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskActivity.fromFirestore(doc))
          .toList();
    });
  }

  // log any task event (create, update, complete)
  Future<void> logActivity({
    required String taskId,
    required String userId,
    required String userName,
    required ActivityType type,
    required String details,
  }) async {
    final activity = TaskActivity(
      id: '',
      taskId: taskId,
      userId: userId,
      userName: userName,
      type: type,
      details: details,
      timestamp: DateTime.now(),
    );
    await _activitiesRef(taskId).add(activity.toMap());
  }
}

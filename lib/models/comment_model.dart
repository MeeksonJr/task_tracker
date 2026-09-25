import 'package:cloud_firestore/cloud_firestore.dart';

// comment on a task
class Comment {
  final String id;
  final String taskId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  // convert to firestore map
  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // parse from firestore doc
  factory Comment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Comment.fromMap(doc.data() ?? {}, doc.id);
  }

  // parse from map
  factory Comment.fromMap(Map<String, dynamic> data, [String id = '']) {
    final rawDate = data['createdAt'];
    DateTime createdAtDate;
    if (rawDate is Timestamp) {
      createdAtDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      createdAtDate = rawDate;
    } else {
      createdAtDate = DateTime.now();
    }

    return Comment(
      id: id,
      taskId: data['taskId'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Anonymous',
      content: data['content'] as String? ?? '',
      createdAt: createdAtDate,
    );
  }
}

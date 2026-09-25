import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_model.dart';
import '../models/task_model.dart';

// service to handle firestore task operations
class TaskService {
  final FirebaseFirestore _firestore;

  TaskService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      _firestore.collection('tasks');

  // stream all tasks real-time
  Stream<List<Task>> tasksStream() {
    return _tasksRef
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  // add a new task and log created activity
  Future<String> createTask(Task task) async {
    final now = DateTime.now();
    final taskToSave = task.copyWith(
      createdAt: now,
      updatedAt: now,
    );
    final docRef = await _tasksRef.add(taskToSave.toMap());

    // log creation activity
    await docRef.collection('activities').add(
          TaskActivity(
            id: '',
            taskId: docRef.id,
            userId: task.creatorId,
            userName: task.creatorName,
            type: ActivityType.created,
            details: 'Created task and assigned to ${task.assigneeName}',
            timestamp: now,
          ).toMap(),
        );

    return docRef.id;
  }

  // update existing task and log activity
  Future<void> updateTask(Task task, {String? updaterId, String? updaterName}) async {
    final now = DateTime.now();
    final taskToUpdate = task.copyWith(updatedAt: now);
    await _tasksRef.doc(task.id).update(taskToUpdate.toMap());

    // log update activity
    await _tasksRef.doc(task.id).collection('activities').add(
          TaskActivity(
            id: '',
            taskId: task.id,
            userId: updaterId ?? task.creatorId,
            userName: updaterName ?? task.creatorName,
            type: ActivityType.updated,
            details: 'Updated task details',
            timestamp: now,
          ).toMap(),
        );
  }

  // quick toggle between completed and todo
  Future<void> toggleTaskStatus(Task task, {String? userId, String? userName}) async {
    final newStatus = task.isCompleted ? TaskStatus.todo : TaskStatus.completed;
    final now = DateTime.now();
    final updated = task.copyWith(
      status: newStatus,
      updatedAt: now,
    );
    await _tasksRef.doc(task.id).update(updated.toMap());

    // log status change activity
    await _tasksRef.doc(task.id).collection('activities').add(
          TaskActivity(
            id: '',
            taskId: task.id,
            userId: userId ?? task.creatorId,
            userName: userName ?? task.creatorName,
            type: ActivityType.statusChanged,
            details: newStatus == TaskStatus.completed
                ? 'Marked task as completed'
                : 'Reopened task',
            timestamp: now,
          ).toMap(),
        );
  }

  // delete task by id
  Future<void> deleteTask(String taskId) async {
    await _tasksRef.doc(taskId).delete();
  }
}

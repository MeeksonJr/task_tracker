import 'package:cloud_firestore/cloud_firestore.dart';
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

  // add a new task
  Future<String> createTask(Task task) async {
    final now = DateTime.now();
    final taskToSave = task.copyWith(
      createdAt: now,
      updatedAt: now,
    );
    final docRef = await _tasksRef.add(taskToSave.toMap());
    return docRef.id;
  }

  // update existing task
  Future<void> updateTask(Task task) async {
    final now = DateTime.now();
    final taskToUpdate = task.copyWith(updatedAt: now);
    await _tasksRef.doc(task.id).update(taskToUpdate.toMap());
  }

  // quick toggle between completed and todo
  Future<void> toggleTaskStatus(Task task) async {
    final newStatus = task.isCompleted ? TaskStatus.todo : TaskStatus.completed;
    final updated = task.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    await _tasksRef.doc(task.id).update(updated.toMap());
  }

  // delete task by id
  Future<void> deleteTask(String taskId) async {
    await _tasksRef.doc(taskId).delete();
  }
}

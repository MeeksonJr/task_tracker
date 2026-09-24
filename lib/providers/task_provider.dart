import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'auth_provider.dart';

// task tabs for dashboard
enum TaskTab {
  myTasks,
  assignedByMe,
  completed;

  String get label {
    switch (this) {
      case TaskTab.myTasks:
        return 'My Tasks';
      case TaskTab.assignedByMe:
        return 'Assigned by Me';
      case TaskTab.completed:
        return 'Completed';
    }
  }
}

// task service provider
final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService();
});

// stream all tasks
final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final service = ref.watch(taskServiceProvider);
  return service.tasksStream();
});

// tab notifier
class TaskTabNotifier extends Notifier<TaskTab> {
  @override
  TaskTab build() => TaskTab.myTasks;
  void setTab(TaskTab tab) => state = tab;
}

final taskTabProvider =
    NotifierProvider<TaskTabNotifier, TaskTab>(TaskTabNotifier.new);

// search query notifier
class TaskSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
}

final taskSearchQueryProvider =
    NotifierProvider<TaskSearchNotifier, String>(TaskSearchNotifier.new);

// priority filter notifier
class TaskPriorityFilterNotifier extends Notifier<TaskPriority?> {
  @override
  TaskPriority? build() => null;
  void setPriority(TaskPriority? priority) => state = priority;
}

final taskPriorityFilterProvider =
    NotifierProvider<TaskPriorityFilterNotifier, TaskPriority?>(
        TaskPriorityFilterNotifier.new);

// filtered tasks for active tab & search
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  final allTasks = tasksAsync.value ?? [];
  final activeTab = ref.watch(taskTabProvider);
  final searchQuery = ref.watch(taskSearchQueryProvider).trim().toLowerCase();
  final priorityFilter = ref.watch(taskPriorityFilterProvider);
  final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';

  // filter by selected tab
  List<Task> tabTasks = [];
  switch (activeTab) {
    case TaskTab.myTasks:
      tabTasks = allTasks
          .where((t) => t.assigneeId == currentUserId && !t.isCompleted)
          .toList();
      break;
    case TaskTab.assignedByMe:
      tabTasks = allTasks
          .where((t) => t.creatorId == currentUserId && !t.isCompleted)
          .toList();
      break;
    case TaskTab.completed:
      tabTasks = allTasks.where((t) => t.isCompleted).toList();
      break;
  }

  // apply search query filter
  if (searchQuery.isNotEmpty) {
    tabTasks = tabTasks.where((t) {
      final titleMatch = t.title.toLowerCase().contains(searchQuery);
      final descMatch = t.description.toLowerCase().contains(searchQuery);
      final assigneeMatch = t.assigneeName.toLowerCase().contains(searchQuery);
      return titleMatch || descMatch || assigneeMatch;
    }).toList();
  }

  // apply priority filter
  if (priorityFilter != null) {
    tabTasks = tabTasks.where((t) => t.priority == priorityFilter).toList();
  }

  return tabTasks;
});

// counts for tab badges
final taskCountsProvider = Provider<Map<TaskTab, int>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  final allTasks = tasksAsync.value ?? [];
  final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';

  return {
    TaskTab.myTasks: allTasks
        .where((t) => t.assigneeId == currentUserId && !t.isCompleted)
        .length,
    TaskTab.assignedByMe: allTasks
        .where((t) => t.creatorId == currentUserId && !t.isCompleted)
        .length,
    TaskTab.completed: allTasks.where((t) => t.isCompleted).length,
  };
});

// controller for task actions
class TaskController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  TaskService get _service => ref.read(taskServiceProvider);

  Future<bool> createTask(Task task) async {
    state = const AsyncValue.loading();
    try {
      await _service.createTask(task);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateTask(Task task) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateTask(task);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> toggleTaskStatus(Task task) async {
    try {
      await _service.toggleTaskStatus(task);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> deleteTask(String taskId) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteTask(taskId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final taskControllerProvider =
    NotifierProvider<TaskController, AsyncValue<void>>(TaskController.new);

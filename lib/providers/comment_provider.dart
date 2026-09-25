import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_model.dart';
import '../models/comment_model.dart';
import '../services/comment_service.dart';
import 'auth_provider.dart';

// comment service provider
final commentServiceProvider = Provider<CommentService>((ref) {
  return CommentService();
});

// stream comments for a task
final commentsStreamProvider =
    StreamProvider.family<List<Comment>, String>((ref, taskId) {
  final service = ref.watch(commentServiceProvider);
  return service.commentsStream(taskId);
});

// stream activities for a task
final activitiesStreamProvider =
    StreamProvider.family<List<TaskActivity>, String>((ref, taskId) {
  final service = ref.watch(commentServiceProvider);
  return service.activitiesStream(taskId);
});

// controller to post new comments
class CommentController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> addComment(String taskId, String content) async {
    final currentUser = ref.read(currentUserProfileProvider).value;
    if (currentUser == null) return false;

    state = const AsyncValue.loading();
    try {
      await ref.read(commentServiceProvider).addComment(
            taskId: taskId,
            authorId: currentUser.id,
            authorName: currentUser.displayName,
            content: content,
          );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final commentControllerProvider =
    NotifierProvider<CommentController, AsyncValue<void>>(CommentController.new);

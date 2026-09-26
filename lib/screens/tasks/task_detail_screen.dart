import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/task_provider.dart';
import 'task_form_screen.dart';

// task details screen with comments thread and activity log
class TaskDetailScreen extends ConsumerStatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // send comment
  Future<void> _sendComment(String taskId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();
    final success = await ref
        .read(commentControllerProvider.notifier)
        .addComment(taskId, text);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to post comment. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // open full-screen image viewer
  void _openFullScreen(BuildContext context, List<String> urls, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(urls: urls, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProfileProvider).value;
    final dateFormat = DateFormat('EEE, MMM d, yyyy · h:mm a');
    final timeFormat = DateFormat('MMM d, h:mm a');

    // listen to live task updates in case status/details changed
    final allTasks = ref.watch(tasksStreamProvider).value ?? [];
    final liveTask = allTasks.firstWhere(
      (t) => t.id == widget.task.id,
      orElse: () => widget.task,
    );

    final canManage = currentUser != null &&
        (currentUser.isAdmin || liveTask.creatorId == currentUser.id);

    final commentsAsync = ref.watch(commentsStreamProvider(liveTask.id));
    final activitiesAsync = ref.watch(activitiesStreamProvider(liveTask.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (action) async {
                if (action == 'edit') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TaskFormScreen(taskToEdit: liveTask),
                    ),
                  );
                } else if (action == 'delete') {
                  final navigator = Navigator.of(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Task'),
                      content: Text('Are you sure you want to delete "${liveTask.title}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: FilledButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref.read(taskControllerProvider.notifier).deleteTask(liveTask.id);
                    navigator.pop();
                  }
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Task'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Task', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // task overview card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // status & priority row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: liveTask.priority.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 4,
                                backgroundColor: liveTask.priority.color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${liveTask.priority.label} Priority',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: liveTask.priority.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            ref
                                .read(taskControllerProvider.notifier)
                                .toggleTaskStatus(
                                  liveTask,
                                );
                          },
                          icon: Icon(
                            liveTask.isCompleted
                                ? Icons.restart_alt
                                : Icons.check_circle_outline,
                            size: 16,
                          ),
                          label: Text(
                            liveTask.isCompleted ? 'Reopen' : 'Complete',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // title
                    Text(
                      liveTask.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration:
                            liveTask.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (liveTask.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        liveTask.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const Divider(height: 24),

                    // meta info: Due Date, Creator, Assignee
                    Row(
                      children: [
                        Icon(
                          liveTask.isOverdue
                              ? Icons.warning_amber_rounded
                              : Icons.schedule,
                          size: 16,
                          color: liveTask.isOverdue ? Colors.red : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Due: ${dateFormat.format(liveTask.dueDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  liveTask.isOverdue ? FontWeight.bold : FontWeight.normal,
                              color: liveTask.isOverdue
                                  ? Colors.red
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_pin_outlined, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Assignee: ${liveTask.assigneeName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.edit_note, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Creator: ${liveTask.creatorName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // attachment thumbnail strip (if any)
          if (liveTask.attachmentUrls.isNotEmpty)
            Container(
              height: 80,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: liveTask.attachmentUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final url = liveTask.attachmentUrls[i];
                  return GestureDetector(
                    // open full-screen viewer on tap
                    onTap: () => _openFullScreen(context, liveTask.attachmentUrls, i),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: url.startsWith('http://') || url.startsWith('https://')
                          ? Image.network(
                              url,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(url),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, size: 24),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),

          // tab bar for Comments & Activity History
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                text: 'Comments (${commentsAsync.value?.length ?? 0})',
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
              ),
              Tab(
                text: 'Activity Log (${activitiesAsync.value?.length ?? 0})',
                icon: const Icon(Icons.history, size: 18),
              ),
            ],
          ),

          // tab view
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. comments list tab
                Column(
                  children: [
                    Expanded(
                      child: commentsAsync.when(
                        data: (comments) {
                          if (comments.isEmpty) {
                            return Center(
                              child: Text(
                                'No comments yet. Start the conversation!',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              final isMe = comment.authorId == currentUser?.id;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: isMe
                                          ? theme.colorScheme.primaryContainer
                                          : theme.colorScheme.surfaceContainerHighest,
                                      child: Text(
                                        comment.authorName.isNotEmpty
                                            ? comment.authorName[0].toUpperCase()
                                            : 'U',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isMe
                                              ? theme.colorScheme.onPrimaryContainer
                                              : theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? theme.colorScheme.primaryContainer
                                                  .withValues(alpha: 0.3)
                                              : theme.colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  comment.authorName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Text(
                                                  timeFormat.format(comment.createdAt),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: theme.colorScheme.outline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              comment.content,
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error: $err')),
                      ),
                    ),

                    // comment input box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border(
                          top: BorderSide(color: theme.colorScheme.outlineVariant),
                        ),
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  hintText: 'Add a comment...',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                onSubmitted: (_) => _sendComment(liveTask.id),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              icon: const Icon(Icons.send, size: 18),
                              onPressed: () => _sendComment(liveTask.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // 2. activity log tab
                activitiesAsync.when(
                  data: (activities) {
                    if (activities.isEmpty) {
                      return Center(
                        child: Text(
                          'No activity recorded yet.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: activities.length,
                      separatorBuilder: (context, index) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final item = activities[index];

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              item.type.icon,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: theme.textTheme.bodyMedium,
                                      children: [
                                        TextSpan(
                                          text: item.userName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(text: ' • ${item.details}'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    timeFormat.format(item.timestamp),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// swipe-able full-screen image viewer
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.urls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _pageController;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageController = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.urls.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (ctx, i) => InteractiveViewer(
          child: Center(
            child: widget.urls[i].startsWith('http://') ||
                    widget.urls[i].startsWith('https://')
                ? Image.network(
                    widget.urls[i],
                    fit: BoxFit.contain,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                  )
                : Image.file(
                    File(widget.urls[i]),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white, size: 48),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

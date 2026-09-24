import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../tasks/task_form_screen.dart';
import '../tasks/widgets/task_card.dart';

// main dashboard screen with task tabs, search, and filters
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final activeTab = ref.watch(taskTabProvider);
    final counts = ref.watch(taskCountsProvider);
    final filteredTasks = ref.watch(filteredTasksProvider);
    final selectedPriority = ref.watch(taskPriorityFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Collaborative Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // show current user role and logout button
          userProfileAsync.whenOrNull(
                data: (profile) => profile != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(
                            profile.role == UserRole.admin
                                ? 'Admin'
                                : 'Member',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          avatar: Icon(
                            profile.role == UserRole.admin
                                ? Icons.admin_panel_settings
                                : Icons.badge,
                            size: 16,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign Out',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(authControllerProvider.notifier).signOut();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // search input field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search tasks by title or assignee...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (val) {
                  ref.read(taskSearchQueryProvider.notifier).setQuery(val);
                },
              ),
            ),

            // priority filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Priorities'),
                    selected: selectedPriority == null,
                    onSelected: (selected) {
                      if (selected) {
                        ref
                            .read(taskPriorityFilterProvider.notifier)
                            .setPriority(null);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ...TaskPriority.values.map((priority) {
                    final isSelected = selectedPriority == priority;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(priority.label),
                        selected: isSelected,
                        avatar: CircleAvatar(
                          radius: 4,
                          backgroundColor: priority.color,
                        ),
                        onSelected: (selected) {
                          ref
                              .read(taskPriorityFilterProvider.notifier)
                              .setPriority(selected ? priority : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // segmented tabs: My Tasks, Assigned by Me, Completed
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SegmentedButton<TaskTab>(
                segments: [
                  ButtonSegment(
                    value: TaskTab.myTasks,
                    label: Text('Mine (${counts[TaskTab.myTasks] ?? 0})'),
                    icon: const Icon(Icons.assignment_ind_outlined),
                  ),
                  ButtonSegment(
                    value: TaskTab.assignedByMe,
                    label:
                        Text('Assigned (${counts[TaskTab.assignedByMe] ?? 0})'),
                    icon: const Icon(Icons.outbox_outlined),
                  ),
                  ButtonSegment(
                    value: TaskTab.completed,
                    label: Text('Done (${counts[TaskTab.completed] ?? 0})'),
                    icon: const Icon(Icons.check_circle_outline),
                  ),
                ],
                selected: {activeTab},
                onSelectionChanged: (newSelection) {
                  ref
                      .read(taskTabProvider.notifier)
                      .setTab(newSelection.first);
                },
              ),
            ),
            const Divider(height: 16),

            // real-time task list
            Expanded(
              child: ref.watch(tasksStreamProvider).when(
                    data: (_) {
                      if (filteredTasks.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  activeTab == TaskTab.completed
                                      ? Icons.done_all
                                      : Icons.task_alt,
                                  size: 48,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  activeTab == TaskTab.completed
                                      ? 'No completed tasks yet'
                                      : activeTab == TaskTab.assignedByMe
                                          ? 'No tasks assigned by you'
                                          : 'No tasks assigned to you',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap the "+" button below to create a new task.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          return TaskCard(task: filteredTasks[index]);
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (err, _) => Center(
                      child: Text('Error loading tasks: $err'),
                    ),
                  ),
            ),
          ],
        ),
      ),

      // create new task button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TaskFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }
}

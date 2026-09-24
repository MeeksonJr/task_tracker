import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';

// screen to create or edit a task
class TaskFormScreen extends ConsumerStatefulWidget {
  final Task? taskToEdit;

  const TaskFormScreen({super.key, this.taskToEdit});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late TaskPriority _selectedPriority;
  late DateTime _selectedDueDate;
  String? _selectedAssigneeId;
  String? _selectedAssigneeName;

  bool get _isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    final task = widget.taskToEdit;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    _selectedPriority = task?.priority ?? TaskPriority.medium;
    _selectedDueDate =
        task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _selectedAssigneeId = task?.assigneeId;
    _selectedAssigneeName = task?.assigneeName;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // pick date and time
  Future<void> _pickDueDateTime() async {
    final now = DateTime.now();
    final initialDate =
        _selectedDueDate.isBefore(now) ? now : _selectedDueDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDueDate),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  // save task
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProfileProvider).value;
    if (currentUser == null) return;

    // default assignee to creator if none selected
    final assigneeId = _selectedAssigneeId ?? currentUser.id;
    final assigneeName = _selectedAssigneeName ?? currentUser.displayName;

    final task = Task(
      id: widget.taskToEdit?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _selectedPriority,
      status: widget.taskToEdit?.status ?? TaskStatus.todo,
      dueDate: _selectedDueDate,
      creatorId: widget.taskToEdit?.creatorId ?? currentUser.id,
      creatorName: widget.taskToEdit?.creatorName ?? currentUser.displayName,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      attachmentUrls: widget.taskToEdit?.attachmentUrls ?? const [],
      createdAt: widget.taskToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = _isEditing
        ? await ref.read(taskControllerProvider.notifier).updateTask(task)
        : await ref.read(taskControllerProvider.notifier).createTask(task);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Task updated!' : 'Task created!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(allUsersProvider);
    final isSaving = ref.watch(taskControllerProvider).isLoading;
    final dateFormat = DateFormat('EEE, MMM d, yyyy · h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // task title
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Task Title *',
                    hintText: 'e.g. Design wireframes for mobile',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // task description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Add details or context for the task...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),

                // priority picker
                Text(
                  'Priority',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: TaskPriority.values.map((priority) {
                    final isSelected = _selectedPriority == priority;
                    return ChoiceChip(
                      label: Text(priority.label),
                      selected: isSelected,
                      avatar: CircleAvatar(
                        radius: 5,
                        backgroundColor: priority.color,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedPriority = priority;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // due date selector
                Text(
                  'Due Date & Time',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDueDateTime,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dateFormat.format(_selectedDueDate),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // assignee picker
                Text(
                  'Assign To',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                usersAsync.when(
                  data: (users) {
                    final currentUid =
                        ref.watch(authStateProvider).value?.uid;

                    // set initial assignee to self if null
                    if (_selectedAssigneeId == null && users.isNotEmpty) {
                      final self = users.firstWhere(
                        (u) => u.id == currentUid,
                        orElse: () => users.first,
                      );
                      _selectedAssigneeId = self.id;
                      _selectedAssigneeName = self.displayName;
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedAssigneeId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: users.map((u) {
                        final isSelf = u.id == currentUid;
                        return DropdownMenuItem<String>(
                          value: u.id,
                          child: Text(
                            '${u.displayName} (${u.role.label})${isSelf ? ' - You' : ''}',
                          ),
                        );
                      }).toList(),
                      onChanged: (newId) {
                        if (newId == null) return;
                        final matched = users.firstWhere((u) => u.id == newId);
                        setState(() {
                          _selectedAssigneeId = matched.id;
                          _selectedAssigneeName = matched.displayName;
                        });
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (err, _) => const Text('Could not load user list'),
                ),
                const SizedBox(height: 32),

                // save button
                FilledButton(
                  onPressed: isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Create Task',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

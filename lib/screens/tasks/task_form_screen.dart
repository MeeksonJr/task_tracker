import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../providers/attachment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../utils/image_picker_helper.dart';

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

  // existing remote URLs (from edit) + newly picked local files
  final List<String> _existingUrls = [];
  final List<File> _newFiles = [];

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
    // load existing attachment URLs when editing
    if (task != null) _existingUrls.addAll(task.attachmentUrls);
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

  // pick a new image from camera or gallery
  Future<void> _pickImage() async {
    final file = await ImagePickerHelper.pickImage(context);
    if (file != null && mounted) {
      setState(() => _newFiles.add(file));
    }
  }

  // save task, uploading new attachments first
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProfileProvider).value;
    if (currentUser == null) return;

    final assigneeId = _selectedAssigneeId ?? currentUser.id;
    final assigneeName = _selectedAssigneeName ?? currentUser.displayName;

    // create a placeholder task to get/use the ID for upload paths
    final taskId = widget.taskToEdit?.id ?? '';

    // upload any new local files
    final uploadedUrls = <String>[];
    for (final file in _newFiles) {
      final url = await ref
          .read(attachmentUploadProvider.notifier)
          .upload(taskId: taskId.isNotEmpty ? taskId : 'tmp', file: file);
      if (url != null) uploadedUrls.add(url);
    }

    final allUrls = [..._existingUrls, ...uploadedUrls];

    final task = Task(
      id: taskId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _selectedPriority,
      status: widget.taskToEdit?.status ?? TaskStatus.todo,
      dueDate: _selectedDueDate,
      creatorId: widget.taskToEdit?.creatorId ?? currentUser.id,
      creatorName: widget.taskToEdit?.creatorName ?? currentUser.displayName,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      attachmentUrls: allUrls,
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
                const SizedBox(height: 20),

                // attachments section
                Text(
                  'Attachments',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _AttachmentGrid(
                  existingUrls: _existingUrls,
                  newFiles: _newFiles,
                  onRemoveExisting: (url) {
                    setState(() => _existingUrls.remove(url));
                  },
                  onRemoveNew: (file) {
                    setState(() => _newFiles.remove(file));
                  },
                  onAdd: _pickImage,
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

// grid showing existing remote images + newly picked local images + add button
class _AttachmentGrid extends StatelessWidget {
  final List<String> existingUrls;
  final List<File> newFiles;
  final void Function(String url) onRemoveExisting;
  final void Function(File file) onRemoveNew;
  final VoidCallback onAdd;

  const _AttachmentGrid({
    required this.existingUrls,
    required this.newFiles,
    required this.onRemoveExisting,
    required this.onRemoveNew,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final items = existingUrls.length + newFiles.length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // existing images (either local path or url)
        for (final url in existingUrls)
          _ThumbTile(
            child: url.startsWith('http://') || url.startsWith('https://')
                ? Image.network(url, fit: BoxFit.cover)
                : Image.file(
                    File(url),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, size: 24),
                    ),
                  ),
            onRemove: () => onRemoveExisting(url),
          ),

        // newly picked local images
        for (final file in newFiles)
          _ThumbTile(
            child: Image.file(file, fit: BoxFit.cover),
            onRemove: () => onRemoveNew(file),
          ),

        // add button — max 5 attachments
        if (items < 5)
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined),
            ),
          ),
      ],
    );
  }
}

// single thumbnail tile with a remove X button
class _ThumbTile extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;

  const _ThumbTile({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

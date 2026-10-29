import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF267A68);
    return MaterialApp(
      title: 'Task Mate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          surface: const Color(0xFFF7F9F6),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9F6),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF7F9F6)),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDCE5DE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: green, width: 2),
          ),
        ),
      ),
      home: const TaskMateSplash(),
    );
  }
}

class TaskMateSplash extends StatefulWidget {
  const TaskMateSplash({super.key});

  @override
  State<TaskMateSplash> createState() => _TaskMateSplashState();
}

class _TaskMateSplashState extends State<TaskMateSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _titleSlide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    _timer = Timer(const Duration(seconds: 2), _openDashboard);
  }

  void _openDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const TaskMateDashboard(),
        transitionDuration: const Duration(milliseconds: 420),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF348B73), Color(0xFF1F6658)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: const Icon(
                        Icons.task_alt_rounded,
                        size: 58,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: Text(
                      'Task Mate',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _fade,
                  child: Text(
                    'Make room for what matters today.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
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

enum _TaskFilter { all, pending, completed }

class TaskMateDashboard extends StatefulWidget {
  const TaskMateDashboard({super.key});

  @override
  State<TaskMateDashboard> createState() => _TaskMateDashboardState();
}

class _TaskMateDashboardState extends State<TaskMateDashboard> {
  static const _storageKey = 'task_mate_tasks_v1';

  final List<_Task> _tasks = [];
  _TaskFilter _filter = _TaskFilter.all;
  bool _isLoading = true;
  bool _storageAvailable = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedTasks = preferences.getString(_storageKey);
      final loadedTasks = <_Task>[];

      if (savedTasks != null) {
        final decoded = jsonDecode(savedTasks);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              try {
                loadedTasks.add(_Task.fromJson(Map<String, dynamic>.from(item)));
              } on FormatException {
                // Skip an invalid task and keep the remaining saved tasks.
              } on TypeError {
                // Skip an invalid task and keep the remaining saved tasks.
              }
            }
          }
        } else {
          await preferences.remove(_storageKey);
        }
      }

      if (!mounted) return;
      setState(() {
        _tasks
          ..clear()
          ..addAll(loadedTasks);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _storageAvailable = false;
      });
    }
  }

  Future<void> _saveTasks() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encodedTasks = jsonEncode(_tasks.map((task) => task.toJson()).toList());
      final saved = await preferences.setString(_storageKey, encodedTasks);
      if (!saved && mounted) {
        setState(() => _storageAvailable = false);
      }
    } catch (_) {
      if (mounted) setState(() => _storageAvailable = false);
    }
  }

  Future<void> _openTaskEditor({_Task? task}) async {
    final editedTask = await showDialog<_Task>(
      context: context,
      builder: (context) => _TaskEditorDialog(task: task),
    );
    if (editedTask == null || !mounted) return;

    setState(() {
      if (task == null) {
        _tasks.insert(0, editedTask);
      } else {
        task
          ..title = editedTask.title
          ..subject = editedTask.subject
          ..dueDate = editedTask.dueDate;
      }
    });
    unawaited(_saveTasks());
    _showMessage(task == null ? 'Task added.' : 'Task updated.');
  }

  void _toggleTask(_Task task, bool isCompleted) {
    setState(() => task.isCompleted = isCompleted);
    unawaited(_saveTasks());
    _showMessage(isCompleted ? 'Task completed. Nice work!' : 'Task marked pending.');
  }

  Future<void> _deleteTask(_Task task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Delete this task?'),
        content: Text('“${task.title}” will be removed from your list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    setState(() => _tasks.remove(task));
    unawaited(_saveTasks());
    _showMessage('Task deleted.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<_Task> get _visibleTasks {
    switch (_filter) {
      case _TaskFilter.pending:
        return _tasks.where((task) => !task.isCompleted).toList();
      case _TaskFilter.completed:
        return _tasks.where((task) => task.isCompleted).toList();
      case _TaskFilter.all:
        return List<_Task>.of(_tasks);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _tasks.where((task) => !task.isCompleted).length;
    final completedCount = _tasks.length - pendingCount;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth > 700 ? 32.0 : 20.0;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    24,
                    horizontalPadding,
                    36,
                  ),
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 28),
                    Text(
                      'Welcome back!',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Let’s make progress on your studies.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF65736B),
                          ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        key: const Key('add-task-button'),
                        onPressed: () => _openTaskEditor(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add task'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    LayoutBuilder(
                      builder: (context, summaryConstraints) {
                        final width = summaryConstraints.maxWidth;
                        final columns = width >= 660 ? 3 : 2;
                        final cardWidth = (width - (columns - 1) * 12) / columns;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: _SummaryCard(
                                label: 'Total tasks',
                                count: _tasks.length,
                                icon: Icons.checklist_rounded,
                                color: const Color(0xFF267A68),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _SummaryCard(
                                label: 'Pending',
                                count: pendingCount,
                                icon: Icons.schedule_rounded,
                                color: const Color(0xFFB36B27),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _SummaryCard(
                                label: 'Completed',
                                count: completedCount,
                                icon: Icons.task_alt_rounded,
                                color: const Color(0xFF267A68),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    if (!_storageAvailable) ...[
                      const SizedBox(height: 16),
                      const _StorageNotice(),
                    ],
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Your tasks',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '${_visibleTasks.length} shown',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF65736B),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<_TaskFilter>(
                      key: const Key('task-filters'),
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: _TaskFilter.all,
                          label: Text('All'),
                        ),
                        ButtonSegment(
                          value: _TaskFilter.pending,
                          label: Text('Pending'),
                        ),
                        ButtonSegment(
                          value: _TaskFilter.completed,
                          label: Text('Completed'),
                        ),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (selection) {
                        setState(() => _filter = selection.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_visibleTasks.isEmpty)
                      _EmptyTasksMessage(filter: _filter)
                    else
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: Column(
                          children: [
                            for (final task in _visibleTasks) ...[
                              _TaskCard(
                                key: ValueKey(task.id),
                                task: task,
                                onChanged: (value) => _toggleTask(task, value),
                                onEdit: () => _openTaskEditor(task: task),
                                onDelete: () => _deleteTask(task),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE2F0E7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.task_alt_rounded, color: Color(0xFF267A68)),
        ),
        const SizedBox(width: 12),
        Text(
          'Task Mate',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _Task {
  _Task({
    required this.title,
    required this.subject,
    required this.dueDate,
    this.isCompleted = false,
    String? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  String title;
  String subject;
  DateTime dueDate;
  bool isCompleted;

  Map<String, Object> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'dueDate': dueDate.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory _Task.fromJson(Map<String, dynamic> json) {
    return _Task(
      id: json['id'] as String?,
      title: (json['title'] as String).trim(),
      subject: (json['subject'] as String).trim(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class _TaskEditorDialog extends StatefulWidget {
  const _TaskEditorDialog({this.task});

  final _Task? task;

  @override
  State<_TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<_TaskEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _subjectController;
  DateTime? _dueDate;
  bool _showDateError = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _subjectController = TextEditingController(text: widget.task?.subject ?? '');
    _dueDate = widget.task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final today = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? today,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selectedDate == null) return;
    setState(() {
      _dueDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      _showDateError = false;
    });
  }

  void _save() {
    final isValid = _formKey.currentState?.validate() ?? false;
    setState(() => _showDateError = _dueDate == null);
    if (!isValid || _dueDate == null) return;

    Navigator.of(context).pop(
      _Task(
        id: widget.task?.id,
        title: _titleController.text.trim(),
        subject: _subjectController.text.trim(),
        dueDate: _dueDate!,
        isCompleted: widget.task?.isCompleted ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit task' : 'Add a task'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('task-title-field'),
                  controller: _titleController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a task title.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('task-subject-field'),
                  controller: _subjectController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Subject or category',
                    prefixIcon: Icon(Icons.book_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a subject or category.'
                      : null,
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  key: const Key('choose-due-date-button'),
                  onPressed: _chooseDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    _dueDate == null
                        ? 'Choose due date'
                        : 'Due ${_formatDate(_dueDate!)}',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.centerLeft,
                  ),
                ),
                if (_showDateError) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Choose a due date.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('save-task-button'),
          onPressed: _save,
          child: Text(isEditing ? 'Save changes' : 'Save task'),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBE6)),
        boxShadow: const [
          BoxShadow(color: Color(0x0B18311E), blurRadius: 16, offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF65736B),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    super.key,
    required this.task,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final _Task task;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final deadline = _deadlineFor(task);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBE6)),
        boxShadow: const [
          BoxShadow(color: Color(0x0918311E), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            key: Key('task-checkbox-${task.id}'),
            value: task.isCompleted,
            onChanged: (value) => onChanged(value ?? false),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isCompleted
                              ? const Color(0xFF7C8780)
                              : const Color(0xFF24332B),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.subject,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF65736B),
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: deadline.color,
                      ),
                      Text(
                        _formatDate(task.dueDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: deadline.color,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      _StatusPill(
                        label: deadline.label,
                        color: deadline.color,
                        background: deadline.background,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Task actions',
            onSelected: (action) {
              if (action == 'edit') onEdit();
              if (action == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _DeadlineInfo {
  const _DeadlineInfo(this.label, this.color, this.background);

  final String label;
  final Color color;
  final Color background;
}

_DeadlineInfo _deadlineFor(_Task task) {
  if (task.isCompleted) {
    return const _DeadlineInfo(
      'Completed',
      Color(0xFF267A68),
      Color(0xFFE5F2E9),
    );
  }

  final today = DateTime.now();
  final due = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
  final dateToday = DateTime(today.year, today.month, today.day);
  if (due.isBefore(dateToday)) {
    return const _DeadlineInfo(
      'Overdue',
      Color(0xFFB64236),
      Color(0xFFFBEAE7),
    );
  }
  if (due == dateToday) {
    return const _DeadlineInfo(
      'Due today',
      Color(0xFFB36B27),
      Color(0xFFFFF1DF),
    );
  }
  return const _DeadlineInfo(
    'Pending',
    Color(0xFF65736B),
    Color(0xFFF0F3F0),
  );
}

class _EmptyTasksMessage extends StatelessWidget {
  const _EmptyTasksMessage({required this.filter});

  final _TaskFilter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      _TaskFilter.all => "You're all caught up! Add a task above to get started.",
      _TaskFilter.pending => 'No pending tasks. Great job!',
      _TaskFilter.completed => 'Completed tasks will appear here.',
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBE6)),
      ),
      child: Column(
        children: [
          const Icon(Icons.task_alt_rounded, size: 42, color: Color(0xFF267A68)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: const Color(0xFF536259)),
          ),
        ],
      ),
    );
  }
}

class _StorageNotice extends StatelessWidget {
  const _StorageNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1DF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF9A5A1F)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Local saving is unavailable right now. Tasks will remain until you close the app.',
              style: TextStyle(color: Color(0xFF70451F)),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}
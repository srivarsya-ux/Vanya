import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../native/oneir_protection.dart';

/// A real, full task list -- separate from Home's fixed 3-task "Today's
/// Adventure" preview card (which stays as-is, already functional). This
/// is where "Tasks" on Home actually leads: add, complete, and remove
/// tasks, genuinely persisted.
class TasksScreen extends StatefulWidget {
  /// True when this screen was opened from the Vanya Daily Check-in
  /// widget's "+ Add task" button (see OneirWidgetService.OneirWidgetLaunch
  /// .quickAddTask) -- puts the cursor straight in the add-task field so
  /// the tap-to-typing path has no extra step in between.
  final bool autoFocusAdd;

  const TasksScreen({super.key, this.autoFocusAdd = false});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;
  final _controller = TextEditingController();
  final _addFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.autoFocusAdd) {
      // Requested post-frame: the field isn't in the tree yet during
      // initState, and grabbing focus before the first frame paints can
      // be a no-op on some Android keyboard/IME timings.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _addFieldFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _addFieldFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final tasks = await OneirProtection.loadTaskList();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await OneirProtection.saveTaskList(_tasks);
  }

  void _addTask() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _tasks.add({'label': text, 'done': false}));
    _controller.clear();
    _persist();
  }

  void _toggle(int i) {
    setState(() => _tasks[i]['done'] = !(_tasks[i]['done'] as bool));
    _persist();
  }

  void _remove(int i) {
    setState(() => _tasks.removeAt(i));
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OneirColors.background,
      appBar: AppBar(
        backgroundColor: OneirColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: OneirColors.text), onPressed: () => Navigator.of(context).pop()),
        title: Text('Tasks', style: OneirText.title.copyWith(fontSize: 18)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: OneirColors.accent))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(OneirSpace.xl, OneirSpace.sm, OneirSpace.xl, OneirSpace.md),
                  child: Row(children: [
                    Expanded(
                      child: OneirTextField(
                        controller: _controller,
                        hintText: 'Add a task...',
                        onSubmitted: (_) => _addTask(),
                      ),
                    ),
                    const SizedBox(width: OneirSpace.sm + 2),
                    Material(
                      color: OneirColors.accent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _addTask,
                        child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.add, color: Colors.white, size: 20)),
                      ),
                    ),
                  ]),
                ),
                Expanded(
                  child: _tasks.isEmpty
                      ? Center(
                          child: Text('No tasks yet -- add one above.', style: OneirText.bodySmall.copyWith(color: OneirColors.textFaint)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(OneirSpace.xl, 0, OneirSpace.xl, OneirSpace.xl),
                          itemCount: _tasks.length,
                          itemBuilder: (context, i) {
                            final task = _tasks[i];
                            final done = task['done'] as bool;
                            return Container(
                              margin: const EdgeInsets.only(bottom: OneirSpace.sm),
                              padding: const EdgeInsets.symmetric(horizontal: OneirSpace.md + 2, vertical: 2),
                              decoration: BoxDecoration(
                                color: OneirColors.surface,
                                borderRadius: BorderRadius.circular(OneirRadius.md),
                                border: Border.all(color: OneirColors.border),
                              ),
                              child: Row(children: [
                                Checkbox(
                                  value: done,
                                  onChanged: (_) => _toggle(i),
                                  activeColor: OneirColors.accent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                ),
                                Expanded(
                                  child: Text(
                                    task['label'] as String,
                                    style: (done ? OneirText.bodyStrong.copyWith(color: OneirColors.textFaint) : OneirText.bodyStrong).copyWith(
                                      decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18, color: OneirColors.textFaint),
                                  onPressed: () => _remove(i),
                                ),
                              ]),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

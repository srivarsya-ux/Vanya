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
        title: const Text('Tasks', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, color: OneirColors.text)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _addFieldFocusNode,
                        onSubmitted: (_) => _addTask(),
                        style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: OneirColors.text),
                        decoration: InputDecoration(
                          hintText: 'Add a task...',
                          filled: true,
                          fillColor: OneirColors.inputFill,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                          child: Text('No tasks yet -- add one above.', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: OneirColors.textFaint)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: _tasks.length,
                          itemBuilder: (context, i) {
                            final task = _tasks[i];
                            final done = task['done'] as bool;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(color: OneirColors.cardNeutral, borderRadius: BorderRadius.circular(14)),
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
                                    style: TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 14,
                                      color: done ? OneirColors.textFaint : OneirColors.text,
                                      decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, size: 18, color: OneirColors.textFaint),
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

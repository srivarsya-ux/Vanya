import 'package:flutter/material.dart';

import '../../../models/vanya_task.dart';

/// Plain Material form for creating/editing a task — deliberately
/// unstyled placeholder UI, not the Vanya design system. Returns the new
/// or updated [VanyaTask] via `Navigator.pop`, or null if cancelled.
class AddEditTaskSheet extends StatefulWidget {
  const AddEditTaskSheet({super.key, this.existing});

  final VanyaTask? existing;

  static Future<VanyaTask?> show(BuildContext context, {VanyaTask? existing}) {
    return showModalBottomSheet<VanyaTask>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddEditTaskSheet(existing: existing),
    );
  }

  @override
  State<AddEditTaskSheet> createState() => _AddEditTaskSheetState();
}

class _AddEditTaskSheetState extends State<AddEditTaskSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    final now = DateTime.now();
    _date = existing?.date ?? DateTime(now.year, now.month, now.day);
    _startTime = existing?.startTime ?? TimeOfDay.fromDateTime(now);
    _endTime = existing?.endTime ??
        TimeOfDay.fromDateTime(now.add(const Duration(minutes: 30)));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final now = DateTime.now();
    final existing = widget.existing;
    final task = VanyaTask(
      id: existing?.id ?? '${now.microsecondsSinceEpoch}',
      title: title,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      date: _date,
      startTime: _startTime,
      endTime: _endTime,
      completed: existing?.completed ?? false,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null ? 'New task' : 'Edit task',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            autofocus: widget.existing == null,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            trailing: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
            onTap: _pickDate,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Start time'),
            trailing: Text(_startTime.format(context)),
            onTap: () => _pickTime(isStart: true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('End time'),
            trailing: Text(_endTime.format(context)),
            onTap: () => _pickTime(isStart: false),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _save,
            child: Text(widget.existing == null ? 'Add task' : 'Save changes'),
          ),
        ],
      ),
    );
  }
}

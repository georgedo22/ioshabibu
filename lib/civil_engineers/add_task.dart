import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// كلاس إضافة المهمة
class AddTaskScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const AddTaskScreen({
    Key? key,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

// حالة كلاس إضافة المهمة
class _AddTaskScreenState extends State<AddTaskScreen> {
  TextEditingController expectedCompletionController = TextEditingController();
  TextEditingController taskNameController = TextEditingController();
  String selectedTaskStatus = 'progress'; // Default status
  List<Map<String, dynamic>> tasks = [];
  @override
  void initState() {
    super.initState();
    fetchProjectTasks();
  }

  @override
  void dispose() {
    expectedCompletionController.dispose();
    taskNameController.dispose();
    super.dispose();
  }

  // Add this method to fetch tasks
  Future<void> fetchProjectTasks() async {
    try {
      final projectId = widget.projectId ?? widget.projectId;
      final response = await http.post(
        Uri.parse(
            'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_project_tasks.php'),
        body: {'project_id': projectId.toString()},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          tasks = List<Map<String, dynamic>>.from(data);
          print('Tasks fetched successfully: $tasks');
        });
      }
    } catch (e) {
      print('Error fetching tasks: $e');
    }
  }

  // Add this method to add new task
  Future<void> addTask(
      String taskName, String status, String expectedCompletionDate) async {
    try {
      final projectId = widget.projectId ?? widget.projectId;
      final response = await http.post(
        Uri.parse(
            'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/add_project_task.php'),
        body: {
          'project_id': projectId.toString(),
          'task_name': taskName,
          'status': status,
          'expected_completion_time': expectedCompletionDate,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          fetchProjectTasks(); // Refresh tasks list
          taskNameController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task added successfully')),
          );
        }
      }
    } catch (e) {
      print('Error adding task: $e');
    }
  }

  // Add this method after addTask
  Future<void> updateTaskStatus(int taskId, String newStatus) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/update_task_status.php'),
        body: {
          'task_id': taskId.toString(),
          'status': newStatus,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          await fetchProjectTasks(); // Refresh the tasks list
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task status updated successfully')),
          );
        }
      }
    } catch (e) {
      print('Error updating task status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task status')),
      );
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'complete':
        return Colors.green;
      case 'onhold':
        return Colors.orange;
      case 'progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // سيتم إضافة واجهة المستخدم لاحقاً
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Task to ${widget.projectName}'),
      ),
      body: Center(
        child: _buildTasksSection(),
      ),
    );
  }

  // In your build method, add this after the existing cards
  Widget _buildTasksSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Project Tasks',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  onPressed: _showAddTaskDialog,
                ),
              ],
            ),
            SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(task['task_name'] ?? ''),
                    subtitle: Text(
                        'expected completion time: ${task['expected_completion_time'] ?? ''}'),
                    trailing: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Update Task Status'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ...['progress', 'complete', 'onhold'].map(
                                  (status) => ListTile(
                                    title: Text(status.toUpperCase()),
                                    tileColor: status == task['status']
                                        ? Colors.grey[200]
                                        : null,
                                    onTap: () {
                                      Navigator.pop(context);
                                      updateTaskStatus(
                                          int.parse(task['task_id'].toString()),
                                          status);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(task['status']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          task['status']?.toUpperCase() ?? '',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

// Add this method to show add task dialog
  void _showAddTaskDialog() {
    expectedCompletionController.text = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: taskNameController,
              decoration: InputDecoration(labelText: 'Task Name'),
            ),
            SizedBox(height: 16),
            // Add date picker field
            TextField(
              controller: expectedCompletionController,
              decoration: InputDecoration(
                labelText: 'Expected Completion Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    expectedCompletionController.text =
                        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                  });
                }
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedTaskStatus,
              decoration: InputDecoration(labelText: 'Status'),
              items: ['progress', 'complete', 'onhold']
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedTaskStatus = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (taskNameController.text.isNotEmpty) {
                addTask(taskNameController.text, selectedTaskStatus,
                    expectedCompletionController.text);
                Navigator.pop(context);
              }
            },
            child: Text('Add Task'),
          ),
        ],
      ),
    );
  }
}

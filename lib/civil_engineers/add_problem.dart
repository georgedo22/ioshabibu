import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// كلاس إضافة المهمة
class AddProblemScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const AddProblemScreen({
    Key? key,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  _AddProblemScreenState createState() => _AddProblemScreenState();
}

// حالة كلاس إضافة المهمة
class _AddProblemScreenState extends State<AddProblemScreen> {
  TextEditingController expectedCompletionController = TextEditingController();
  TextEditingController taskNameController = TextEditingController();
  String selectedTaskStatus = 'progress'; // Default status

  List<Map<String, dynamic>> problems = [];
  @override
  void initState() {
    super.initState();
    _fetchProblems();
  }

  @override
  void dispose() {
    expectedCompletionController.dispose();
    taskNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchProblems() async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_problem_project.php'),
        body: {
          'project_id': widget.projectId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          problems = List<Map<String, dynamic>>.from(data);
          print('Fetched problems: $problems');
        });
      }
    } catch (e) {
      print('Error fetching problems: $e');
    }
  }

  // Add this method to add new task
  Future<void> _addProblem(String description) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/add_problem.php'),
        body: {
          'problem_title': description,
          'project_id': widget.projectId.toString(),
        },
      );

      if (response.statusCode == 200) {
        await _fetchProblems();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Problem added successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding problem: $e')),
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
        child: _buildProblemsSection(),
      ),
    );
  }

  // In your build method, add this after the existing cards
  Widget _buildProblemsSection() {
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
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Current Problems',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  onPressed: _showAddProblemDialog,
                  tooltip: 'Add New Problem',
                ),
              ],
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: problems.length,
              itemBuilder: (context, index) {
                return _buildProblemItem(problems[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemItem(Map<String, dynamic> problem) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: Colors.orange,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  problem['problem_title'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                if (problem['created_at'] != null) ...[
                  SizedBox(height: 4),
                  Text(
                    'created_at: ${problem['created_at']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _deleteProblem(problem['id']),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProblem(dynamic problemId) async {
    if (!mounted) return;

    // Show confirmation dialog first
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Confirm Delete'),
            ],
          ),
          content: Text('Are you sure you want to delete this problem?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    // If user confirmed deletion
    if (confirmDelete == true) {
      try {
        String idString = problemId.toString();
        print('Attempting to delete problem with ID: $idString');

        final response = await http.post(
          Uri.parse(
              'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/delete_problem.php'),
          body: {
            'id': idString,
          },
        );

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          print('Server response: $result');

          if (result['success'] == true) {
            await _fetchProblems();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Problem deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            throw Exception(result['message'] ?? 'Failed to delete problem');
          }
        } else {
          throw Exception('Server returned ${response.statusCode}');
        }
      } catch (e) {
        print('Error deleting problem: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting problem: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

// Add this method to show add task dialog
  void _showAddProblemDialog() {
    final _problemController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Problem'),
        content: TextField(
          controller: _problemController,
          decoration: InputDecoration(
            labelText: 'Problem Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_problemController.text.isNotEmpty) {
                print('Adding problem: ${_problemController.text}');
                _addProblem(_problemController.text);
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}

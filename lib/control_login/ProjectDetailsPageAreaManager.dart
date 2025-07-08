import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

class ProjectDetailsPageAreaManager extends StatefulWidget {
  final Map<String, dynamic> project;

  ProjectDetailsPageAreaManager({required this.project});

  @override
  _ProjectDetailsPageAreaManagerState createState() =>
      _ProjectDetailsPageAreaManagerState();
}

class _ProjectDetailsPageAreaManagerState
    extends State<ProjectDetailsPageAreaManager> {
  final _materialFormKey = GlobalKey<FormState>();
  final _materialNameController = TextEditingController();
  final _requiredQuantityController = TextEditingController();
  final _receivedQuantityController = TextEditingController();
  final _unitController = TextEditingController();

  Map<String, dynamic>? projectDetails;
  bool isLoading = true;
  bool hasError = false;
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> materials = [];
  TextEditingController taskNameController = TextEditingController();
  String selectedTaskStatus = 'progress'; // Default status
  // Add these controllers at the top of your _ProjectDetailsPageAreaManagerState class
  TextEditingController nameController = TextEditingController();
  TextEditingController budgetController = TextEditingController();
  TextEditingController ContractValueController = TextEditingController();

  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  TextEditingController expectedCompletionController = TextEditingController();
  String? selectedStatus;

  // Add these variables for image handling
  PlatformFile? projectImage;
  PlatformFile? contractImage;
  bool isUploadingProjectImage = false;
  bool isUploadingContractImage = false;
  @override
  void initState() {
    super.initState();
    fetchProjectDetails();
    fetchProjectTasks(); // Add this
    print("widget.project['id'] ${widget.project['project_id']}");
    getMaterial();
    _fetchProblems(); // إضافة هذا السطر
  }

// Add these methods after your existing methods

// Method to pick files
  Future<void> _pickFile(bool isProjectImage) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          if (isProjectImage) {
            projectImage = result.files.first;
            isUploadingProjectImage = true;
          } else {
            contractImage = result.files.first;
            isUploadingContractImage = true;
          }
        });

        // Upload the file
        await _uploadFile(result.files.first, isProjectImage);
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image')),
      );
    }
  }

// Method to upload files
  Future<void> _uploadFile(PlatformFile file, bool isProjectImage) async {
    try {
      final projectId =
          widget.project['project_id'] ?? widget.project['project_id'];

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/update_project_image.php'),
      );

      // Add fields
      request.fields['project_id'] = projectId.toString();
      //request.fields['image_type'] = isProjectImage ? 'project' : 'contract';

      // Add file - handle differently for web and mobile
      if (kIsWeb) {
        // For web platform, use bytes
        request.files.add(
          await http.MultipartFile.fromBytes(
            isProjectImage
                ? 'project_image'
                : 'contract_image', // ← اسم الحقل المناسب
            file.bytes!,
            filename: file.name,
          ),
        );
      } else {
        // For mobile platforms, use path
        request.files.add(
          await http.MultipartFile.fromPath(
            isProjectImage
                ? 'project_image'
                : 'contract_image', // ← اسم الحقل المناسب
            file.path!,
            filename: file.name,
          ),
        );
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      setState(() {
        if (isProjectImage) {
          isUploadingProjectImage = false;
        } else {
          isUploadingContractImage = false;
        }
      });

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          fetchProjectDetails(); // Refresh project details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(isProjectImage
                    ? 'Project image updated successfully'
                    : 'Contract image updated successfully.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Image update failed. ${result['message'] ?? ''}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image update failed. Server error.')),
        );
      }
    } catch (e) {
      setState(() {
        if (isProjectImage) {
          isUploadingProjectImage = false;
        } else {
          isUploadingContractImage = false;
        }
      });
      print('Error uploading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading the image.')),
      );
    }
  }

// Add this method to show the edit dialog
  void _showEditProjectDialog() {
    // Initialize controllers with current values
    nameController.text = projectDetails?['project_name'] ?? '';
    budgetController.text = projectDetails?['budget']?.toString() ?? '';
    ContractValueController.text =
        projectDetails?['contract_value']?.toString() ?? '';
    startDateController.text = projectDetails?['start_date'] ?? '';
    endDateController.text = projectDetails?['end_date'] ?? '';
    // Make sure selectedStatus matches one of the dropdown items
    String currentStatus = projectDetails?['status'] ?? 'Active';
    // Check if the current status is in our list, if not default to 'Active'
    List<String> statusOptions = [
      'in progress',
      'completed',
      'on hold',
      'not started'
    ];
    selectedStatus =
        statusOptions.contains(currentStatus) ? currentStatus : 'in progress';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Project Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Project Name'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: budgetController,
                decoration: InputDecoration(labelText: 'Budget'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextField(
                controller: ContractValueController,
                decoration: InputDecoration(labelText: 'Contract Value'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              // Modified dropdown
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(labelText: 'Status'),
                items: statusOptions
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value;
                  });
                },
              ),
              SizedBox(height: 16),
              TextField(
                controller: startDateController,
                decoration: InputDecoration(
                  labelText: 'Start Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      startDateController.text =
                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    });
                  }
                },
              ),
              SizedBox(height: 16),
              TextField(
                controller: endDateController,
                decoration: InputDecoration(
                  labelText: 'End Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      endDateController.text =
                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              updateProjectDetails();
              setState(() {
                widget.project['name'] = nameController.text;
                widget.project['budget'] = budgetController.text;
                widget.project['contract_value'] = ContractValueController.text;
                widget.project['start_date'] = startDateController.text;
                widget.project['end_date'] = endDateController.text;
                widget.project['status'] = selectedStatus;
              });
              Navigator.pop(context);
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

// Add this method to update project details
  Future<void> updateProjectDetails() async {
    try {
      final projectId =
          widget.project['project_id'] ?? widget.project['project_id'];
      final response = await http.post(
        Uri.parse(
            'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/update_project_details.php'),
        body: {
          'project_id': projectId.toString(),
          'project_name': nameController.text,
          'budget': budgetController.text,
          'contract_value': ContractValueController.text,
          'status': selectedStatus,
          'start_date': startDateController.text,
          'end_date': endDateController.text,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          fetchProjectDetails(); // Refresh project details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Project details updated successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update project details')),
          );
        }
      }
    } catch (e) {
      print('Error updating project details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating project details')),
      );
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

// Add this method to fetch tasks
  Future<void> fetchProjectTasks() async {
    try {
      final projectId = widget.project['id'] ?? widget.project['project_id'];
      final response = await http.post(
        Uri.parse(
            'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_project_tasks.php'),
        body: {'project_id': projectId.toString()},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          tasks = List<Map<String, dynamic>>.from(data);
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
      final projectId = widget.project['id'] ?? widget.project['project_id'];
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

  Future<void> fetchProjectDetails() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      // Replace with your actual API endpoint and project ID key
      final projectId =
          widget.project['project_id'] ?? widget.project['project_id'];
      final url = Uri.parse(
        'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_project_details.php?project_id=$projectId',
      );
      final response = await http.post(
        url,
        body: {
          'project_id': projectId.toString(),
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          projectDetails = json.decode(response.body);
          print("project id $projectId");
          print("project iamge ${projectDetails!['project_image']}");
          print("details project id $projectDetails");
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> getMaterial() async {
    try {
      final projectId = widget.project['project_id'];
      final response = await http.post(
        Uri.parse(
            'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_material_by_projectid.php'),
        body: {'project_id': projectId.toString()},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          materials = List<Map<String, dynamic>>.from(data);
          print("materails ${materials}");
        });
      }
    } catch (e) {
      print('Error fetching tasks: $e');
    }
  }

  @override
  void dispose() {
    _materialNameController.dispose();
    _requiredQuantityController.dispose();
    _receivedQuantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          projectDetails?['name'] ??
              widget.project['name'] ??
              'Project Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Return true as result to indicate refresh is needed
            Navigator.pop(context, true);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading project details...',
                        style: TextStyle(fontSize: 16)),
                  ],
                ),
              )
            : hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 48),
                        SizedBox(height: 12),
                        Text('Failed to load project details',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  )
                : ListView(
                    children: [
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.business,
                                          color:
                                              Theme.of(context).primaryColor),
                                      SizedBox(width: 8),
                                      Text(
                                        projectDetails?['name'] ?? '',
                                        style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit,
                                        color: Theme.of(context).primaryColor),
                                    onPressed: _showEditProjectDialog,
                                    tooltip: 'Edit Project Details',
                                  ),
                                ],
                              ),
                              Divider(height: 28, thickness: 1.2),
                              Row(
                                children: [
                                  Icon(Icons.location_city,
                                      color: Colors.grey[700]),
                                  SizedBox(width: 8),
                                  Text('City:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(width: 4),
                                  Text('${projectDetails?['cityname'] ?? ''}'),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.person, color: Colors.grey[700]),
                                  SizedBox(width: 8),
                                  Text('Supervisor:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(width: 4),
                                  Text(
                                      '${projectDetails?['supervisor_name'] ?? ''}'),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.grey[700]),
                                  SizedBox(width: 8),
                                  Text('Status:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(width: 4),
                                  Text('${projectDetails?['status'] ?? ''}'),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.attach_money,
                                      color: Colors.grey[700]),
                                  SizedBox(width: 8),
                                  Text('Budget:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(width: 4),
                                  Text('${projectDetails?['budget'] ?? ''}'),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.attach_money,
                                      color: Colors.grey[700]),
                                  SizedBox(width: 8),
                                  Text('Contract Value:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(width: 4),
                                  Text(
                                      '${projectDetails?['contract_value'] ?? ''}'),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.date_range,
                                      color: Colors.grey[700]),
                                  SizedBox(width: 8),
                                  Text('Start:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(width: 4),
                                  Text(
                                      '${projectDetails?['start_date'] ?? ''}'),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.event, color: Colors.grey[700]),
                                  SizedBox(width: 8),
                                  Text('End:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(width: 4),
                                  Text('${projectDetails?['end_date'] ?? ''}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      if (projectDetails?['project_image'] != null &&
                              projectDetails!['project_image']
                                  .toString()
                                  .isNotEmpty ||
                          (projectDetails?['contract_image'] != null &&
                              projectDetails!['contract_image']
                                  .toString()
                                  .isNotEmpty))
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Project and contract images.',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit_outlined,
                                              color: Theme.of(context)
                                                  .primaryColor),
                                          onPressed: () => _pickFile(true),
                                          tooltip: 'Project image update.',
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.edit_note,
                                              color: Theme.of(context)
                                                  .primaryColor),
                                          onPressed: () => _pickFile(false),
                                          tooltip: 'Contract image update.',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => Dialog(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  child: InteractiveViewer(
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                      child: projectImage !=
                                                              null
                                                          ? kIsWeb
                                                              ? Image.memory(
                                                                  projectImage!
                                                                      .bytes!,
                                                                  fit: BoxFit
                                                                      .contain,
                                                                )
                                                              : Image.file(
                                                                  File(projectImage!
                                                                      .path!),
                                                                  fit: BoxFit
                                                                      .contain,
                                                                )
                                                          : Image.network(
                                                              'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/image_proxy.php?url=https://antiquewhite-cobra-422929.hostingersite.com/georgecode/${projectDetails!['project_image']}',
                                                              fit: BoxFit
                                                                  .contain,
                                                              errorBuilder:
                                                                  (context,
                                                                      error,
                                                                      stackTrace) {
                                                                return Container(
                                                                  height: 300,
                                                                  color: Colors
                                                                          .grey[
                                                                      300],
                                                                  child: Icon(
                                                                      Icons
                                                                          .broken_image,
                                                                      size: 100,
                                                                      color: Colors
                                                                          .grey),
                                                                );
                                                              },
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: isUploadingProjectImage
                                                  ? Center(
                                                      child:
                                                          CircularProgressIndicator())
                                                  : projectImage != null
                                                      ? kIsWeb
                                                          ? Image.memory(
                                                              projectImage!
                                                                  .bytes!,
                                                              height: 180,
                                                              width: double
                                                                  .infinity,
                                                              fit: BoxFit.cover,
                                                            )
                                                          : Image.file(
                                                              File(projectImage!
                                                                  .path!),
                                                              height: 180,
                                                              width: double
                                                                  .infinity,
                                                              fit: BoxFit.cover,
                                                            )
                                                      : Image.network(
                                                          'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/image_proxy.php?url=https://antiquewhite-cobra-422929.hostingersite.com/georgecode/${projectDetails!['project_image']}}',
                                                          height: 180,
                                                          width:
                                                              double.infinity,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) {
                                                            return Container(
                                                              height: 180,
                                                              color: Colors
                                                                  .grey[300],
                                                              child: Icon(
                                                                  Icons
                                                                      .broken_image,
                                                                  size: 80,
                                                                  color: Colors
                                                                      .grey),
                                                            );
                                                          },
                                                        ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            left: 8,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.7),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'Project Image',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => Dialog(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  child: InteractiveViewer(
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                      child: contractImage !=
                                                              null
                                                          ? kIsWeb
                                                              ? Image.memory(
                                                                  contractImage!
                                                                      .bytes!,
                                                                  fit: BoxFit
                                                                      .contain,
                                                                )
                                                              : Image.file(
                                                                  File(contractImage!
                                                                      .path!),
                                                                  fit: BoxFit
                                                                      .contain,
                                                                )
                                                          : Image.network(
                                                              'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/image_proxy.php?url=https://antiquewhite-cobra-422929.hostingersite.com/georgecode/${projectDetails!['contract_image']}',
                                                              fit: BoxFit
                                                                  .contain,
                                                              errorBuilder:
                                                                  (context,
                                                                      error,
                                                                      stackTrace) {
                                                                return Container(
                                                                  height: 300,
                                                                  color: Colors
                                                                          .grey[
                                                                      300],
                                                                  child: Icon(
                                                                      Icons
                                                                          .broken_image,
                                                                      size: 100,
                                                                      color: Colors
                                                                          .grey),
                                                                );
                                                              },
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: isUploadingContractImage
                                                  ? Center(
                                                      child:
                                                          CircularProgressIndicator())
                                                  : contractImage != null
                                                      ? kIsWeb
                                                          ? Image.memory(
                                                              contractImage!
                                                                  .bytes!,
                                                              height: 180,
                                                              width: double
                                                                  .infinity,
                                                              fit: BoxFit.cover,
                                                            )
                                                          : Image.file(
                                                              File(
                                                                  contractImage!
                                                                      .path!),
                                                              height: 180,
                                                              width: double
                                                                  .infinity,
                                                              fit: BoxFit.cover,
                                                            )
                                                      : Image.network(
                                                          'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/image_proxy.php?url=https://antiquewhite-cobra-422929.hostingersite.com/georgecode/${projectDetails!['contract_image']}',
                                                          height: 180,
                                                          width:
                                                              double.infinity,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) {
                                                            return Container(
                                                              height: 180,
                                                              color: Colors
                                                                  .grey[300],
                                                              child: Icon(
                                                                  Icons
                                                                      .broken_image,
                                                                  size: 80,
                                                                  color: Colors
                                                                      .grey),
                                                            );
                                                          },
                                                        ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            left: 8,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.7),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'Contract Image',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: 24),
                      _buildTasksSection(),
                      SizedBox(height: 24),
                      _buildMaterialsSection(),
                      SizedBox(height: 24),
                      _buildProblemsSection(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildMaterialsSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        color: Theme.of(context).primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Materials and quantities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  onPressed: _showAddMaterialDialog,
                  tooltip: 'Add New Material',
                ),
              ],
            ),
            SizedBox(height: 16),

            // استخدام LayoutBuilder للتحقق من عرض الشاشة
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  // تصميم للشاشات الصغيرة (الهواتف)
                  return _buildMobileMaterialsList();
                } else {
                  // تصميم للشاشات الكبيرة (الحاسوب)
                  return _buildDesktopMaterialsTable();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // أضف هذه الدالة للإضافة
  Future<void> _addMaterial() async {
    try {
      final projectId = widget.project['project_id'];

      final response = await http.post(
        Uri.parse(
            'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/add_material.php'),
        body: {
          'project_id': projectId.toString(),
          'material_name': _materialNameController.text,
          'required_quantity': _requiredQuantityController.text,
          'received_quantity': _receivedQuantityController.text,
          'unit': _unitController.text,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          // تحديث قائمة المواد
          await getMaterial();
          // إغلاق الـ dialog
          Navigator.pop(context);
          // عرض رسالة نجاح
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Material added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // مسح الحقول
          _clearMaterialForm();
        } else {
          throw Exception(result['message'] ?? 'Failed to add material');
        }
      } else {
        throw Exception('Server error');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding material: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// دالة مساعدة لمسح النموذج
  void _clearMaterialForm() {
    _materialNameController.clear();
    _requiredQuantityController.clear();
    _receivedQuantityController.clear();
    _unitController.clear();
  }

  void _showAddMaterialDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Material'),
        content: Form(
          key: _materialFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _materialNameController,
                  decoration: InputDecoration(
                    labelText: 'Material Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter material name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _requiredQuantityController,
                  decoration: InputDecoration(
                    labelText: 'Required Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter required quantity';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _receivedQuantityController,
                  decoration: InputDecoration(
                    labelText: 'Received Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter received quantity';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _unitController,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. ton, kg, piece',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter unit';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearMaterialForm();
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_materialFormKey.currentState!.validate()) {
                _addMaterial();
              }
            },
            child: Text('Add Material'),
          ),
        ],
      ),
    );
  }

// تصميم للهواتف
  Widget _buildMobileMaterialsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: materials.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        final material = materials[index];
        // Parse quantities for status calculation
        int requiredQty =
            int.tryParse(material['required_quantity']?.toString() ?? '0') ?? 0;
        int receivedQty =
            int.tryParse(material['received_quantity']?.toString() ?? '0') ?? 0;
        String status = _calculateStatus(requiredQty, receivedQty);

        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        material['material_name']?.toString() ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getMaterialStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getMaterialStatusColor(status),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(status),
                            size: 16,
                            color: _getMaterialStatusColor(status),
                          ),
                          SizedBox(width: 4),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: _getMaterialStatusColor(status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Required',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${material['required_quantity']?.toString() ?? '0'} ${material['unit']?.toString() ?? ''}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey[300],
                      margin: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Received',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${material['received_quantity']?.toString() ?? '0'} ${material['unit']?.toString() ?? ''}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// تصميم للحاسوب
  Widget _buildDesktopMaterialsTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Table(
          border: TableBorder.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          columnWidths: const {
            0: FlexColumnWidth(1), // Material Name
            1: FlexColumnWidth(1), // Required Quantity
            2: FlexColumnWidth(1), // Received Quantity
            3: FlexColumnWidth(1), // Status
          },
          children: [
            // عنوان الجدول
            TableRow(
              decoration: BoxDecoration(
                color: Colors.grey[100],
              ),
              children: [
                _buildHeaderCell('Material Name'),
                _buildHeaderCell('Required Quantity'),
                _buildHeaderCell('Received Quantity'),
                _buildHeaderCell('Status'),
              ],
            ),
            // صفوف البيانات
            ...materials.map((material) {
              // التحقق من القيم وتحويلها إلى أرقام صحيحة
              int requiredQty =
                  int.tryParse(material['required_quantity'].toString()) ?? 0;
              int receivedQty =
                  int.tryParse(material['received_quantity'].toString()) ?? 0;

              return TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                children: [
                  _buildTableCell(Text(material['material_name'] ?? '')),
                  _buildTableCell(
                      Text('$requiredQty ${material['unit'] ?? ''}')),
                  _buildTableCell(
                      Text('$receivedQty ${material['unit'] ?? ''}')),
                  _buildTableCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(
                              _calculateStatus(requiredQty, receivedQty)),
                          color: _getMaterialStatusColor(
                              _calculateStatus(requiredQty, receivedQty)),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(_calculateStatus(requiredQty, receivedQty)
                            .toUpperCase()),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        );
      },
    );
  }

  // دالة مساعدة لحساب الحالة
  String _calculateStatus(int required, int received) {
    if (received == required) {
      return 'complete';
    } else if (received > required) {
      return 'warning';
    } else {
      return 'shortage';
    }
  }

  TableRow _buildTableRow(
      String name, String required, String received, String status) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      children: [
        _buildTableCell(Text(name)),
        _buildTableCell(Text(required)),
        _buildTableCell(Text(received)),
        /*_buildTableCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(status),
                color: _getMaterialStatusColor(status),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(status.toUpperCase()),
            ],
          ),
        ),*/
      ],
    );
  }

  Widget _buildTableCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  // تعديل _buildMaterialRow أيضاً لتتناسب مع العرض الكامل
  DataRow _buildMaterialRow(
      String name, String required, String received, String status) {
    return DataRow(
      cells: [
        DataCell(
          Container(
            child: Text(name),
          ),
        ),
        DataCell(
          Container(
            child: Text(required),
          ),
        ),
        DataCell(
          Container(
            child: Text(received),
          ),
        ),
        DataCell(
          Container(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getMaterialStatusColor(status),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(status.toUpperCase()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'shortage':
        return Icons.cancel_outlined;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'complete':
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline;
    }
  }

  Color _getMaterialStatusColor(String status) {
    switch (status) {
      case 'shortage':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'complete':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // في نفس الملف ProjectDetailsPageAreaManager.dart

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

// أضف هذه المتغيرات في بداية الكلاس
  List<Map<String, dynamic>> problems = [];

// أضف هذه الدوال للتعامل مع المشاكل
  Future<void> _addProblem(String description) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/add_problem.php'),
        body: {
          'problem_title': description,
          'project_id': widget.project['project_id'].toString(),
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

  Future<void> _fetchProblems() async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_problem_project.php'),
        body: {
          'project_id': widget.project['project_id'].toString(),
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
}

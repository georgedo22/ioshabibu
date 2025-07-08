import 'dart:convert';

import 'package:habibuios/civil_engineers/add_problem.dart';
import 'package:habibuios/civil_engineers/add_task.dart';
import 'package:habibuios/main.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

class CivilEngineer extends StatefulWidget {
  final String username;
  final String fullName;
  final int user_id;

  CivilEngineer(
      {required this.username, required this.fullName, required this.user_id});

  @override
  _CivilEngineerState createState() => _CivilEngineerState();
}

class _CivilEngineerState extends State<CivilEngineer> {
  int _selectedIndex = 0;

  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;
  //project index for editing or viewing details
  var projectIndex;
  List<Map<String, dynamic>> _mockMachinery = [];
  List<dynamic> projects_name = [];

  @override
  void initState() {
    super.initState();
    _fetchProjects();
    fetchvehicle();
    fetchProjects(); //fetch all projects
  }

  // دالة جلب المشاريع
  Future<void> _fetchProjects() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
          Uri.parse(
              'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_project_eng.php'),
          body: {
            'supervisor_id': widget.user_id.toString(),
          });
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _projects = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
          print("projects: $_projects");
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading projects: $e')),
      );
    }
  }

  Future<void> fetchProjects() async {
    setState(() {
      _isLoading = true; // Add this loading state variable to the class
    });
    try {
      final response = await http.get(
        Uri.parse(
            'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_all_projects.php?t=${DateTime.now().millisecondsSinceEpoch}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          projects_name = data;
          print("Projects Name: $projects_name");
        });
      }
    } catch (e) {
      print('Error fetching projects: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load projects. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        drawer: !isSmallScreen ? null : _buildDrawer(),
        body: Row(
          children: [
            if (!isSmallScreen)
              Container(
                width: 280,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: _buildDrawer(),
              ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isSmallScreen)
                          IconButton(
                            icon: Icon(Icons.menu),
                            onPressed: () {
                              _scaffoldKey.currentState?.openDrawer();
                            },
                          ),
                        Expanded(
                          child: Text(
                            'Civil Engineer Dashboard',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 600
                                  ? 20
                                  : 24,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            if (MediaQuery.of(context).size.width >= 600)
                              Text(
                                widget.fullName,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildBody(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsSection() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 60, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No Projects Found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchProjects,
              child: Text('Refresh'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchProjects,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _projects.length,
        itemBuilder: (context, index) {
          final project = _projects[index];
          projectIndex = project;
          return _buildProjectCard(project);
        },
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final dateFormat = DateFormat('MMM yyyy');
    final startDate = DateTime.parse(project['start_date']);
    final endDate = DateTime.parse(project['end_date']);
    final duration = _calculateDuration(startDate, endDate);

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showProjectDetails(project),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project['project_name'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    onSelected: (value) {
                      if (value == 'task') {
                        _addTask(project);
                      } else if (value == 'problem') {
                        _addProblem(project);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        value: 'task',
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 20, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('add Task'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'problem',
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 20, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('add Problem'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    project['cityname'],
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    'Supervisor: ${project['supervisor_name']}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        dateFormat.format(startDate),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Duration',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        duration,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'End Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        dateFormat.format(endDate),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildStatusBadge(project['status']),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateDuration(DateTime start, DateTime end) {
    final months = (end.difference(start).inDays / 30);
    if (months < 1) {
      return 'Less than 1 month';
    } else if (months < 12) {
      return '${months.round()} months';
    } else {
      final years = (months / 12).floor();
      final remainingMonths = (months % 12).round();
      if (remainingMonths == 0) {
        return '$years ${years == 1 ? 'year' : 'years'}';
      } else {
        return '$years ${years == 1 ? 'year' : 'years'} $remainingMonths months';
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'on hold':
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case 'in progress':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'completed':
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case 'not started':
        bgColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
    }

    return InkWell(
      onTap: () => _showStatusUpdateDialog(status),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: textColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getStatusIcon(status),
              size: 12,
              color: textColor,
            ),
            SizedBox(width: 6),
            Text(
              status,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'on hold':
        return Icons.pause_circle_outline;
      case 'in progress':
        return Icons.play_circle_outline;
      case 'completed':
        return Icons.check_circle_outline;
      case 'not started':
        return Icons.error_outline;
      default:
        return Icons.help_outline;
    }
  }

  void _showStatusUpdateDialog(String currentStatus) {
    String selectedStatus = currentStatus;
    final List<String> statusOptions = [
      'On Hold',
      'In Progress',
      'Completed',
      'Not Started'
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Status'),
          content: Container(
            width: double.minPositive,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current Status: $currentStatus'),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      items: statusOptions.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Row(
                            children: [
                              Icon(
                                _getStatusIcon(status),
                                size: 18,
                                color: _getStatusColor(status),
                              ),
                              SizedBox(width: 8),
                              Text(status),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedStatus = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Update'),
              onPressed: () {
                // TODO: Implement status update API call
                _updateProjectStatus(selectedStatus);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'on hold':
        return Colors.orange[800]!;
      case 'in progress':
        return Colors.green[800]!;
      case 'completed':
        return Colors.blue[800]!;
      case 'not started':
        return Colors.red[800]!;
      default:
        return Colors.grey[800]!;
    }
  }

  void _showProjectDetails(Map<String, dynamic> project) {
    // تنفيذ عرض تفاصيل المشروع
  }

  void _addTask(Map<String, dynamic> project) {
    // تنفيذ تعديل المشروع
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(
          projectId: project['project_id'],
          projectName: project['project_name'],
        ),
      ),
    );
  }

  //اضافة مشكلة للمشروع
  void _addProblem(Map<String, dynamic> project) {
    // تنفيذ تعديل المشروع
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProblemScreen(
          projectId: project['project_id'],
          projectName: project['project_name'],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildProjectsSection();
      // case 1:
      // return _buildInvoicesSection();
      //  return InvoicesHomePage(user_id:widget.user_id); //InvoicesSection(user_id:widget.user_id);
      //case 2:
      //return _buildEmployeesSection();
      case 1:
        return _buildMachinerySection();
      // case 4:
      //return MainMenuScreen();
      default:
        return Center(child: Text('Section not found'));
    }
    return Center(
      child: Text(
        'Welcome to the Civil Engineer Dashboard',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDrawer() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return NavigationDrawer(
      backgroundColor: Colors.white,
      elevation: 1,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        // Add this callback
        setState(() {
          _selectedIndex = index;
          if (isSmallScreen) {
            Navigator.pop(context); // Close drawer on small screens
          }
        });
      },
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: isSmallScreen ? 35 : 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    widget.fullName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  widget.fullName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.username,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        NavigationDrawerDestination(
          icon: Icon(Icons.work),
          label: Text('Projects'),
          selectedIcon: Icon(Icons.work, color: Theme.of(context).primaryColor),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.precision_manufacturing),
          label: Text('Machinery'),
          selectedIcon: Icon(Icons.precision_manufacturing,
              color: Theme.of(context).primaryColor),
        ),
        const Divider(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Settings',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ListTile(
          leading: Icon(Icons.logout, color: Colors.red),
          title: Text('Logout'),
          onTap: () {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Confirm Logout'),
                    content: Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                        },
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => LoginPage()),
                          );
                        },
                        child: Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  );
                });
          },
        ),
      ],
    );
  }

  Future<void> _updateProjectStatus(String newStatus) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/update_project_status.php'),
        body: {
          'project_id': projectIndex['project_id'].toString(),
          'status': newStatus,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          // Refresh projects list
          _fetchProjects();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status updated successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to update status: ${result['message']}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  ///machin section from here
  Widget _buildMachinerySection() {
    return RefreshIndicator(
      onRefresh: () => fetchvehicle(),
      color: Colors.blue,
      backgroundColor: Colors.white,
      child: _mockMachinery.isEmpty && !_isLoading
          ? _buildEmptyState()
          : _buildMachineryList(),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.precision_manufacturing_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Machinery Found',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Start by adding your first machine to monitor and manage your equipment',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> fetchvehicle() async {
    setState(() {
      _isLoading = true; // Add this loading state variable to the class
    });
    try {
      final response = await http.post(
        Uri.parse(
            'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/fetch_machin.php?t=${DateTime.now().millisecondsSinceEpoch}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("Machinery Data: $data"); // Add this to debug
        setState(() {
          _mockMachinery = data
              .map<Map<String, dynamic>>((vehicle) => {
                    'vehicle_id': vehicle['vehicle_id'],
                    'name': vehicle['vehicle_type'],
                    'status': vehicle['status'],
                    'vehicle_number': vehicle['vehicle_number'],
                    'location': vehicle['current_location'],
                    'vehicle_id ': vehicle['vehicle_id '],
                    'created_at': vehicle['created_at'],
                    'updated_at': vehicle['updated_at']
                  })
              .toList();
          _isLoading = false;
          // Set loading state to false after data is fetched
        });
      } else {
        print('Error fetching machinery: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching machinery: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load machinery. Please try again.')),
      );
    }
  }

  Widget _buildMachineryList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_isLoading)
          Container(
            height: MediaQuery.of(context).size.height * 0.5,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading machinery...'),
                ],
              ),
            ),
          )
        else
          ...List.generate(
            _mockMachinery.length,
            (index) => _buildMachineCard(_mockMachinery[index]),
          ),

        // Extra space at bottom
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildMachineCard(Map<String, dynamic> machine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          /*onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MachineDetailPageMechanical(machine: machine),
              ),
            );
          },*/
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusMachineColor(machine['status'])
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.precision_manufacturing,
                        color: _getStatusMachineColor(machine['status']),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            machine['name'] ?? 'Unknown Machine',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${machine['vehicle_number'] ?? 'N/A'}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Machine Details
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              String selectedProject = '';
                              return AlertDialog(
                                title: Text('Select Project Location'),
                                content: Container(
                                  width: double.minPositive,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DropdownButtonFormField<String>(
                                        hint: Text('Select Project'),
                                        items: projects_name.map((project) {
                                          return DropdownMenuItem<String>(
                                            value: project['project_name'],
                                            child:
                                                Text(project['project_name']),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          selectedProject = value ?? '';
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    child: Text('Cancel'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                  ElevatedButton(
                                    child: Text('Update'),
                                    onPressed: () async {
                                      if (selectedProject.isNotEmpty) {
                                        try {
                                          final response = await http.post(
                                            Uri.parse(
                                                'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/update_machine_location.php'),
                                            body: {
                                              'vehicle_id':
                                                  machine['vehicle_id']
                                                      .toString(),
                                              'current_location':
                                                  selectedProject,
                                            },
                                          );

                                          if (response.statusCode == 200) {
                                            Navigator.of(context).pop();
                                            setState(() {
                                              machine['location'] =
                                                  selectedProject;
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Location updated successfully')),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Error updating location: $e')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: _buildInfoChip(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: machine['location'] ?? 'Unknown',
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showStatusDialog(machine),
                        child: _buildStatusChip(machine['status']),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusMachineColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'stop':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(Map<String, dynamic> machine) {
    final currentStatus = machine['status']?.toLowerCase() ?? '';
    String selectedStatus = currentStatus;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.settings, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Update Status',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Machine: ${machine['name']}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select new status:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Status Options
                  ...['active', 'maintenance', 'stop'].map((status) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedStatus = status;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selectedStatus == status
                                ? _getStatusMachineColor(status)
                                    .withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedStatus == status
                                  ? _getStatusMachineColor(status)
                                  : Colors.grey.shade300,
                              width: selectedStatus == status ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getStatusMachineIcon(status),
                                color: _getStatusMachineColor(status),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _getStatusMachineText(status),
                                style: TextStyle(
                                  fontWeight: selectedStatus == status
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: selectedStatus == status
                                      ? _getStatusMachineColor(status)
                                      : Colors.grey.shade700,
                                ),
                              ),
                              const Spacer(),
                              if (selectedStatus == status)
                                Icon(
                                  Icons.check_circle,
                                  color: _getStatusMachineColor(status),
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedStatus != currentStatus
                      ? () {
                          _updateMachineStatus(machine, selectedStatus);
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String? status) {
    final statusColor = _getStatusMachineColor(status);
    final statusText = _getStatusMachineText(status);
    final statusIcon = _getStatusMachineIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.edit, size: 14, color: Colors.white.withOpacity(0.8)),
        ],
      ),
    );
  }

  IconData _getStatusMachineIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Icons.play_circle_filled;
      case 'maintenance':
        return Icons.build_circle;
      case 'stop':
        return Icons.stop_circle;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusMachineText(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'maintenance':
        return 'Maintenance';
      case 'stop':
        return 'Stopped';
      default:
        return 'Unknown';
    }
  }

// دالة محدثة لتحديث حالة الآلة مع API
  void _updateMachineStatus(
      Map<String, dynamic> machine, String newStatus) async {
    // Show loading indicator
    _showLoadingDialog();

    try {
      // استدعاء API لتحديث الحالة
      final response = await updateMachineStatusAPI(
        machine['vehicle_id']?.toString() ?? machine['id']?.toString() ?? '',
        newStatus,
      );

      // إخفاء مؤشر التحميل
      Navigator.of(context).pop();

      if (response['success'] == true) {
        // تحديث الحالة محلياً عند نجاح العملية
        setState(() {
          machine['status'] = newStatus;
        });

        // عرض رسالة نجاح
        _showSuccessSnackBar(newStatus);
      } else {
        // عرض رسالة خطأ
        _showErrorSnackBar(response['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      // إخفاء مؤشر التحميل
      Navigator.of(context).pop();

      // عرض رسالة خطأ
      _showErrorSnackBar('An error occurred: $e');
    }
  }

// دالة API لتحديث حالة الآلة
  Future<Map<String, dynamic>> updateMachineStatusAPI(
      String vehicleId, String status) async {
    const String baseUrl =
        'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/update_machine_status.php';

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'vehicle_id': vehicleId,
          'status': status,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

// عرض رسالة نجاح
  void _showSuccessSnackBar(String newStatus) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Status updated to ${_getStatusMachineText(newStatus)} successfully!',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: _getStatusMachineColor(newStatus),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

// عرض رسالة خطأ
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            // يمكن إضافة منطق إعادة المحاولة هنا
          },
        ),
      ),
    );
  }

// عرض مؤشر التحميل
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(width: 16),
                Text(
                  'Updating status...',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:file_picker/file_picker.dart';
import 'package:habibuios/InventoryApp/main_menu_screen.dart';
import 'package:habibuios/control_login/ProjectDetailsPageAreaManager.dart';
import 'package:habibuios/control_login/gotoInv.dart';
import 'package:habibuios/machines/MachineDetailsPage.dart';
import 'package:habibuios/main.dart';
import 'package:habibuios/workshop/EditDriverScreen.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // مهم
import 'package:intl/intl.dart';

class GMDashboard extends StatefulWidget {
  final String username;
  final String fullName;
  final int user_id;

  GMDashboard(
      {required this.username, required this.fullName, required this.user_id});

  @override
  _GMDashboardState createState() => _GMDashboardState();
}

class _GMDashboardState extends State<GMDashboard> {
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;
  bool _isLoading = false;

  //ValueNotifier<double> uploadProgress = ValueNotifier<double>(0);
  final nameController = TextEditingController();
  final costController = TextEditingController();
  final contractvalueController = TextEditingController();
  final cityController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  PlatformFile? projectImage;
  PlatformFile? contractImage;
  //String? constructImage;
  //String? projectImage;

  List<Map<String, dynamic>> supervisors = [];
  List<Map<String, dynamic>> governorate = [];

  int? selectedSupervisor;
  String? selectedSupervisorName;

  int? governorate_id;
  String? selectedStatus;
  final List<String> statusList = [
    'in progress',
    'on hold',
    'completed',
    'not started'
  ];

  String? Selectstatusvehicle;
  final List<String> statusvehicle = ['active', 'maintenance', 'stop'];

  List<dynamic> projects_name = [];
  String? Selectprojects_name;

  final vehicle_name_Controller = TextEditingController();
  final vehicle_model_Controller = TextEditingController();
  final vehicle_num_Controller = TextEditingController();

  List<Map<String, dynamic>> _mockProjects = [];

  List<Invoice> invioces = [];
  List<Invoice> filteredInvoices = [];
  bool isLoading = true;

  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  Timer? _debounce;
  String searchQuery = '';
  String filter = 'all';
  String sortField = 'inv_num';
  bool sortAsc = true;

  final List<Map<String, dynamic>> _mockInvoices = [
    {'id': 'INV-001', 'amount': 5000, 'status': 'Paid', 'date': '2024-02-20'},
    {
      'id': 'INV-002',
      'amount': 3500,
      'status': 'Pending',
      'date': '2024-02-18'
    },
    {
      'id': 'INV-003',
      'amount': 7500,
      'status': 'Overdue',
      'date': '2024-02-15'
    },
  ];

  final List<Map<String, dynamic>> _mockEmployees = [
    {'name': 'John Doe', 'position': 'Engineer', 'department': 'Technical'},
    {'name': 'Jane Smith', 'position': 'Manager', 'department': 'Operations'},
    {
      'name': 'Mike Johnson',
      'position': 'Technician',
      'department': 'Maintenance'
    },
  ];

  List<Map<String, dynamic>> _mockMachinery = [];

  Future<void> pickProjectImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // مهم: نحمل البايتات
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        projectImage = result.files.first;
      });
    }
  }

  // دالة اختيار صورة العقد
  Future<void> pickContractImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image, // تحديد نوع الملفات المسموح بها (صور فقط)
      withData: true, // مهم: نحمل البايتات
    );

    if (result != null) {
      setState(() {
        contractImage = result.files.first; // تحديث حالة الصورة
      });
    }
  }

  Future<List<dynamic>> fetchDrivers() async {
    final response = await http.get(
      Uri.parse(
          'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_drivers_info.php'),
    );
    if (response.statusCode == 200) {
      print("Driver Data: ${response.body}");
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load drivers');
    }
  }

  Future<List<dynamic>> fetchEngineers() async {
    final response = await http.get(
      Uri.parse(
          'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_engineers.php'),
    );
    if (response.statusCode == 200) {
      print("Engineers Data: ${response.body}");
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load drivers');
    }
  }

  Future<List<dynamic>> fetchWorkres() async {
    final response = await http.get(
      Uri.parse(
          'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_workers.php'),
    );
    if (response.statusCode == 200) {
      print("Engineers Data: ${response.body}");
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load workers');
    }
  }

  Future<List<Invoice>> fetchInvoices() async {
    final response = await http.get(
      Uri.parse(
          'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_invoices_data.php'),
    );
    if (response.statusCode == 200) {
      print("Invoices Data: ${response.body}");
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData
          .map((data) => Invoice(
                inv_num: data['inv_num'].toString(),
                inv_title: data['inv_title'],
                inv_date: DateTime.parse(data['inv_date']),
                created_at: DateTime.parse(data['created_at']),
                status: data['status'],
              ))
          .toList();
    } else {
      throw Exception('Failed to load invoices');
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
        //bottomNavigationBar: isSmallScreen ? _buildBottomNav() : null,
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
                            'General Manager Dashboard',
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
          icon: Icon(Icons.receipt),
          label: Text('Invoices'),
          selectedIcon:
              Icon(Icons.receipt, color: Theme.of(context).primaryColor),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.people),
          label: Text('Employees'),
          selectedIcon:
              Icon(Icons.people, color: Theme.of(context).primaryColor),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.precision_manufacturing),
          label: Text('Machinery'),
          selectedIcon: Icon(Icons.precision_manufacturing,
              color: Theme.of(context).primaryColor),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.inventory),
          label: Text('Inventory'),
          selectedIcon:
              Icon(Icons.inventory, color: Theme.of(context).primaryColor),
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => LoginPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildProjectsSection();
      case 1:
        // return _buildInvoicesSection();
        return InvoicesHomePage(
            user_id: widget.user_id); //InvoicesSection(user_id:widget.user_id);
      case 2:
        return _buildEmployeesSection();
      case 3:
        return _buildMachinerySection();
      case 4:
        return MainMenuScreen(governorate_id: governorate_id.toString());
      default:
        return Center(child: Text('Section not found'));
    }
  }

  Widget _buildProjectsSection() {
    return RefreshIndicator(
      onRefresh: () => fetchProjects(widget.user_id),
      color: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Projects', () => _showAddDialog('Project')),
            SizedBox(height: 16),
            if (_isLoading)
              _buildLoadingState()
            else if (_mockProjects.isEmpty)
              _buildEmptyState()
            else
              _buildProjectsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading projects...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsGrid() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width < 600
              ? 1
              : MediaQuery.of(context).size.width < 900
                  ? 2
                  : 3,
          childAspectRatio: 1.4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _mockProjects.length,
        itemBuilder: (context, index) {
          final project = _mockProjects[index];
          return _buildProjectCard(project, index);
        },
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      child: GestureDetector(
        onTap: () async {
          // Add haptic feedback
          HapticFeedback.lightImpact();

          final refreshNeeded = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ProjectDetailsPageAreaManager(project: project),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOutCubic;

                var tween = Tween(begin: begin, end: end).chain(
                  CurveTween(curve: curve),
                );

                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
              transitionDuration: Duration(milliseconds: 300),
            ),
          );

          if (refreshNeeded == true) {
            fetchProjects(widget.user_id);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                HapticFeedback.lightImpact();

                final refreshNeeded = await Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        ProjectDetailsPageAreaManager(project: project),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                            CurvedAnimation(
                                parent: animation, curve: Curves.easeOut),
                          ),
                          child: child,
                        ),
                      );
                    },
                    transitionDuration: Duration(milliseconds: 250),
                  ),
                );

                if (refreshNeeded == true) {
                  fetchProjects(widget.user_id);
                }
              },
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with status badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            project['name'],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusProjectsColor(project['status'])
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusProjectsColor(project['status'])
                                  .withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            project['status'],
                            style: TextStyle(
                              color: _getStatusProjectsColor(project['status']),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Project details with icons
                    _buildDetailRow(
                        Icons.location_city_outlined, 'City', project['city']),
                    SizedBox(height: 8),
                    _buildDetailRow(Icons.person_outline, 'Supervisor',
                        project['supervisor']),

                    Spacer(),

                    // Action button
                    Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.1),
                            Theme.of(context).primaryColor.withOpacity(0.05),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_forward_outlined,
                              color: Theme.of(context).primaryColor,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'View Details',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  DataColumn _buildColumn(String label, String field, {bool numeric = false}) {
    return DataColumn(
      label: Text(label),
      numeric: numeric,
      onSort: (index, _) {
        setState(() {
          if (sortField == field) {
            sortAsc = !sortAsc;
          } else {
            sortField = field;
            sortAsc = true;
          }
        });
      },
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'Paid':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'Pending':
        color = Colors.orange;
        icon = Icons.cancel;
        break;
      case 'late':
        color = Colors.red;
        icon = Icons.access_time;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(status[0].toUpperCase() + status.substring(1),
            style: TextStyle(color: color)),
      ],
    );
  }

  Widget _buildEmployeesSection() {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /* Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _buildSectionHeader('Employees', () => _showAddDialog('Employee')),
        ),*/
          TabBar(
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Drivers'),
              Tab(text: 'Engineers'),
              Tab(text: 'Workers'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildDriversTab(),
                _buildEngineersTab(),
                _buildEmployeeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeTab() {
    return FutureBuilder<List<dynamic>>(
      future: fetchWorkres(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('An error occurred while loading data.'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('There are no Workers.'));
        }

        final workres = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            itemCount: workres.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width < 900 ? 1 : 3,
              childAspectRatio: 0.75, // أقرب للمربع
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final workre = workres[index];
              return Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    height: 380, // ارتفاع قليلاً أكبر لاستيعاب التفاصيل
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // اسم المهندس + الصورة
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue[200],
                              child: Icon(Icons.person,
                                  size: 40, color: Colors.blue),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    workre['full_name'] ?? 'undefined',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    workre['worker_type'] ?? 'undefined',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        Divider(height: 24, thickness: 1),

                        // التخصص والقسم
                        _buildDetailRow(Icons.flag_outlined, 'nationality',
                            workre['nationality']),
                        _buildDetailRow(Icons.location_city_outlined, 'address',
                            workre['address']),
                        _buildDetailRow(Icons.cake_outlined, 'birth date',
                            workre['birth_date']),
                        _buildDetailRow(Icons.phone_outlined, 'phone',
                            workre['phone'] ?? 'undefined'),
                        _buildDetailRow(Icons.lock_clock, 'job status',
                            workre['job_status']),
                        _buildDetailRow(
                            Icons.money, 'salary', workre['salary']),
                        _buildDetailRow(Icons.note, 'notes', workre['notes']),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDriversTab() {
    return StatefulBuilder(
      builder: (context, setState) {
        return FutureBuilder<List<dynamic>>(
          future: fetchDrivers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: SpinKitPulse(
                  color: Theme.of(context).primaryColor,
                  size: 50.0,
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                    SizedBox(height: 16),
                    Text(
                      'An error occurred while loading data.',
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Try again'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_off, size: 60, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'No drivers',
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    ),
                  ],
                ),
              );
            }

            final allDrivers = snapshot.data!;

            return Scaffold(
              /* appBar: AppBar(
                elevation: 0,
                backgroundColor: Colors.white,
                title: Text(
                  'Drivers',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  // زر البحث في AppBar
                  IconButton(
                    icon: Icon(Icons.search, color: Theme.of(context).primaryColor),
                    onPressed: () => _showDriverSearchDialog(context, allDrivers),
                  ),
                  // زر إضافة سائق جديد
                  IconButton(
                    icon: Icon(Icons.person_add, color: Theme.of(context).primaryColor),
                    onPressed: () {
                      // يمكن إضافة وظيفة إضافة سائق جديد هنا
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Add new driver functionality will be added soon')),
                      );
                    },
                  ),
                ],
              ),*/
              body: Container(
                color: Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    itemCount: allDrivers.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(context).size.width < 900 ? 1 : 3,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) {
                      final driver = allDrivers[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side:
                              BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white, Colors.blue.shade50],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => Dialog(
                                            backgroundColor: Colors.transparent,
                                            insetPadding: EdgeInsets.all(16),
                                            child: InteractiveViewer(
                                              minScale: 0.5,
                                              maxScale: 4.0,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Image.network(
                                                  'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/image_proxy.php?url=https://antiquewhite-cobra-422929.hostingersite.com/georgecode/${driver['license_image']}',
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Container(
                                                      height: 300,
                                                      color: Colors.grey[300],
                                                      child: Icon(
                                                          Icons.broken_image,
                                                          size: 100,
                                                          color: Colors.grey),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Container(
                                            color: Colors.grey[200],
                                            height: 160,
                                            width: double.infinity,
                                            child: Image.network(
                                              'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/image_proxy.php?url=https://antiquewhite-cobra-422929.hostingersite.com/georgecode/${driver['license_image']}',
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        size: 50,
                                                        color: Colors.grey),
                                                    SizedBox(height: 8),
                                                    Text('Image not available',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.grey)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.directions_car,
                                              color: Colors.white, size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            driver['vehicle_number'] ??
                                                'undefined',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  driver['driver_name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.phone,
                                          color: Theme.of(context).primaryColor,
                                          size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        driver['driver_phone'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Registration date: ${driver['driver_created_at'] ?? ''}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildActionButton(
                                      icon: Icons.info_outline,
                                      color: Colors.blue,
                                      onTap: () {
                                        // عرض تفاصيل السائق
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Driver details'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Image.network(
                                                  'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/image_proxy.php?url=https://antiquewhite-cobra-422929.hostingersite.com/georgecode/${driver['license_image']}',
                                                  height: 200,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      Icon(
                                                          Icons
                                                              .image_not_supported,
                                                          size: 80),
                                                ),
                                                SizedBox(height: 16),
                                                Text(
                                                    'name: ${driver['driver_name'] ?? ''}'),
                                                Text(
                                                    'phone number: ${driver['driver_phone'] ?? ''}'),
                                                Text(
                                                    'Vehicle number: ${driver['vehicle_number'] ?? ''}'),
                                                Text(
                                                    'Registration date: ${driver['driver_created_at'] ?? ''}'),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text('close'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(width: 8),
                                    _buildActionButton(
                                      icon: Icons.phone,
                                      color: Colors.green,
                                      onTap: () {
                                        // اتصال بالسائق
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Contacting ${driver['driver_name']}')),
                                        );
                                      },
                                    ),
                                    SizedBox(width: 8),
                                    _buildActionButton(
                                      icon: Icons.edit,
                                      color: Colors.orange,
                                      onTap: () {
                                        // تعديل بيانات السائق
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditDriverScreen(
                                              driverData: driver,
                                              onDriverUpdated: () async {
                                                // استدعاء fetchDrivers وتحديث واجهة المستخدم
                                                final drivers =
                                                    await fetchDrivers();
                                                // استدعاء fetchvehicleAvaliable لتحديث قائمة المركبات المتاحة
                                                await fetchvehicle();
                                                setState(() {
                                                  // تحديث قائمة السائقين هنا
                                                  // على سبيل المثال: _drivers = drivers;
                                                });
                                              },
                                            ),
                                          ),
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Edit data${driver['driver_name']}')),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // دالة مساعدة لإنشاء أزرار الإجراءات
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
    );
  }

  // دالة عرض نافذة البحث للسائقين
  void _showDriverSearchDialog(BuildContext context, List<dynamic> allDrivers) {
    final ValueNotifier<String> searchTextNotifier = ValueNotifier<String>('');
    final TextEditingController dialogController = TextEditingController();

    dialogController.addListener(() {
      searchTextNotifier.value = dialogController.text;
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Search for a driver',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dialogController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText:
                      'Enter driver name or phone number or vehicle number...',
                  prefixIcon:
                      Icon(Icons.search, color: Theme.of(context).primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Theme.of(context).primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              SizedBox(height: 16),
              ValueListenableBuilder<String>(
                valueListenable: searchTextNotifier,
                builder: (context, searchText, child) {
                  List<dynamic> dialogFilteredDrivers = searchText.isEmpty
                      ? []
                      : allDrivers
                          .where((driver) =>
                              (driver['driver_name']?.toLowerCase() ?? '')
                                  .contains(searchText.toLowerCase()) ||
                              (driver['driver_phone']?.toLowerCase() ?? '')
                                  .contains(searchText.toLowerCase()) ||
                              (driver['vehicle_number']?.toLowerCase() ?? '')
                                  .contains(searchText.toLowerCase()))
                          .take(5)
                          .toList();

                  if (searchText.isEmpty) {
                    return SizedBox.shrink();
                  }

                  return Flexible(
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: dialogFilteredDrivers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off,
                                      size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'No results found',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: dialogFilteredDrivers.length,
                              separatorBuilder: (context, index) =>
                                  Divider(height: 1),
                              itemBuilder: (context, index) {
                                final driver = dialogFilteredDrivers[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/image_proxy.php?url=https://antiquewhite-cobra-422929.hostingersite.com/georgecode/${driver['license_image']}',
                                        fit: BoxFit.cover,
                                        width: 40,
                                        height: 40,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(Icons.person,
                                                    color: Theme.of(context)
                                                        .primaryColor),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    driver['driver_name'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'phone number: ${driver['driver_phone'] ?? ''}'),
                                      Text(
                                          'Vehicle number: ${driver['vehicle_number'] ?? ''}'),
                                    ],
                                  ),
                                  trailing: Icon(Icons.arrow_forward_ios,
                                      size: 16, color: Colors.grey),
                                  onTap: () {
                                    Navigator.of(dialogContext).pop();
                                    _showDriverDetails(context, driver);
                                  },
                                );
                              },
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'cancel',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('close'),
          ),
        ],
      ),
    );
  }

// دالة منفصلة لعرض تفاصيل السائق
  void _showDriverDetails(BuildContext context, Map<String, dynamic> driver) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Driver details',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/image_proxy.php?url=https://antiquewhite-cobra-422929.hostingersite.com/georgecode/${driver['license_image']}',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(Icons.image_not_supported,
                                size: 80, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildDetailItem(
                    icon: Icons.person,
                    label: 'name',
                    value: driver['driver_name'] ?? '',
                  ),
                  _buildDetailItem(
                    icon: Icons.phone,
                    label: 'phone number',
                    value: driver['driver_phone'] ?? '',
                  ),
                  _buildDetailItem(
                    icon: Icons.directions_car,
                    label: 'Vehicle number',
                    value: driver['vehicle_number'] ?? '',
                  ),
                  _buildDetailItem(
                    icon: Icons.calendar_today,
                    label: 'Registration date',
                    value: driver['driver_created_at'] ?? '',
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'close',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Contacting ${driver['driver_name']}')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone, size: 16),
                            SizedBox(width: 4),
                            Text('contact'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// دالة مساعدة لعرض عناصر التفاصيل
  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Function to show driver search dialog
  /* void _showDriverSearchDialog(BuildContext context, List<dynamic> allDrivers) {
    // Create a temporary controller for text inside the dialog
    final TextEditingController dialogController = TextEditingController();
    
    // List to store filtered search results
    List<dynamic> dialogFilteredDrivers = [];
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          // Update search results inside the dialog
          dialogFilteredDrivers = allDrivers
              .where((driver) => 
                  (driver['name']?.toLowerCase() ?? '').contains(dialogController.text.toLowerCase()) ||
                  (driver['phone']?.toLowerCase() ?? '').contains(dialogController.text.toLowerCase()))
              .take(5)
              .toList();
          
          return AlertDialog(
            title: Text('Search for Driver'),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: dialogController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Enter driver name or phone number...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      // Update dialog state only
                      setDialogState(() {
                        // dialogFilteredDrivers will be updated at the beginning of dialog build
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Display live search results inside the dialog
                  if (dialogController.text.isNotEmpty)
                    Flexible(
                      child: Container(
                        height: 200,
                        child: dialogFilteredDrivers.isEmpty
                            ? Center(child: Text('No results found'))
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: dialogFilteredDrivers.length,
                                itemBuilder: (context, index) {
                                  final driver = dialogFilteredDrivers[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/image_proxy.php?url=https://antiquewhite-cobra-422929.hostingersite.com/georgecode/${driver['license_image']}'
                                      ),
                                      onBackgroundImageError: (_, __) {},
                                      child: Icon(Icons.person),
                                    ),
                                    title: Text(driver['name'] ?? ''),
                                    subtitle: Text('Phone: ${driver['phone'] ?? ''}'),
                                    onTap: () {
                                      // Close dialog first
                                      Navigator.of(dialogContext).pop();
                                      
                                      // Small delay before navigation
                                      Future.delayed(Duration(milliseconds: 100), () {
                                        try {
                                          print("Show driver details: ${driver['name']}");
                                          
                                          // Here you can add code to navigate to driver details page
                                          // or show driver info in a popup
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('Driver Details'),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Image.network(
                                                    'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/image_proxy.php?url=https://antiquewhite-cobra-422929.hostingersite.com/georgecode/${driver['license_image']}',
                                                    height: 200,
                                                    errorBuilder: (context, error, stackTrace) =>
                                                      Icon(Icons.image_not_supported, size: 80),
                                                  ),
                                                  SizedBox(height: 16),
                                                  Text('Name: ${driver['name'] ?? ''}'),
                                                  Text('Phone: ${driver['phone'] ?? ''}'),
                                                  Text('Registration Date: ${driver['created_at'] ?? ''}'),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: Text('Close'),
                                                ),
                                              ],
                                            ),
                                          );
                                        } catch (e) {
                                          print("Error: $e");
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("An error occurred: $e")),
                                          );
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  } */
  //data engineers
/*Widget _buildDetailRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue),
        SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        SizedBox(width: 4),
        Expanded(
          child: Text(
            value ?? 'undefined',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
        ),
      ],
    ),
  );
}*/

  Widget _buildEngineersTab() {
    return FutureBuilder<List<dynamic>>(
      future: fetchEngineers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('An error occurred while loading data.'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('There are no engineers.'));
        }

        final engineers = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            itemCount: engineers.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width < 900 ? 1 : 3,
              childAspectRatio: 0.75, // أقرب للمربع
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final engineer = engineers[index];
              return Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    height: 380, // ارتفاع قليلاً أكبر لاستيعاب التفاصيل
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // اسم المهندس + الصورة
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue[200],
                              child: Icon(Icons.person,
                                  size: 40, color: Colors.blue),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    engineer['name'] ?? 'undefined',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    engineer['Job title'] ?? 'undefined',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        Divider(height: 24, thickness: 1),

                        // التخصص والقسم
                        _buildDetailRow(Icons.engineering_outlined,
                            'Specialization', engineer['Specialization']),
                        _buildDetailRow(Icons.work_outline, 'department',
                            engineer['department']),
                        _buildDetailRow(Icons.location_city_outlined,
                            'Current workplace', engineer['Current_workplace']),
                        _buildDetailRow(
                            Icons.calendar_today_outlined,
                            'Years of experience',
                            '${engineer['Years_of_experience'] ?? 0} Year'),
                        _buildDetailRow(
                            Icons.phone_outlined, 'phone', engineer['phone']),
                        _buildDetailRow(Icons.flag_outlined, 'Nationality',
                            engineer['Nationality']),
                        _buildDetailRow(Icons.cake_outlined, 'date of birth',
                            engineer['date_of_birth']),
                        _buildDetailRow(Icons.access_time_outlined,
                            'created_at', engineer['created_at']),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
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
              _buildSectionHeader(
                  'Machinery', () => _showAddDialog('Machinery')),
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
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => _showAddDialog('Machinery'),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Your First Machine'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
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

  Widget _buildMachineryList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Machinery', () => _showAddDialog('Machinery')),
        const SizedBox(height: 16),

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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MachineDetailPage(machine: machine),
              ),
            );
          },
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
                        color:
                            _getStatusColor(machine['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.precision_manufacturing,
                        color: _getStatusColor(machine['status']),
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
                    /* IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade400,
                    ),
                    onPressed: () => _showDeleteMachineDialog(machine),
                    tooltip: 'Delete Machine',
                  ),*/
                  ],
                ),

                const SizedBox(height: 16),

                // Machine Details
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: machine['location'] ?? 'Unknown',
                        color: Colors.blue,
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

  Widget _buildInfoChip({
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

  String _getStatusText(String? status) {
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

  IconData _getStatusIcon(String? status) {
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

  Color _getStatusProjectsColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'in progress':
        return Colors.green;
      case 'on hold':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'not started':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String? status) {
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

  Widget _buildStatusChip(String? status) {
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final statusIcon = _getStatusIcon(status);

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
                                ? _getStatusColor(status).withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedStatus == status
                                  ? _getStatusColor(status)
                                  : Colors.grey.shade300,
                              width: selectedStatus == status ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getStatusIcon(status),
                                color: _getStatusColor(status),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _getStatusText(status),
                                style: TextStyle(
                                  fontWeight: selectedStatus == status
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: selectedStatus == status
                                      ? _getStatusColor(status)
                                      : Colors.grey.shade700,
                                ),
                              ),
                              const Spacer(),
                              if (selectedStatus == status)
                                Icon(
                                  Icons.check_circle,
                                  color: _getStatusColor(status),
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
                'Status updated to ${_getStatusText(newStatus)} successfully!',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: _getStatusColor(newStatus),
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

//////edit machine to here

  Widget _buildSectionHeader(String title, VoidCallback onAdd) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: Icon(Icons.add),
            label: Text('Add New'),
          ),
        ],
      ),
    );
  }

  Future<void> sendVehicleDataWithProgress(
    BuildContext context,
    String vehiclename,
    String modelname,
    String vehicle_number,
    String status,
    String currectlocation,
    int govId,
    int createdBy,
  ) async {
    final url = Uri.parse(
        'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/add_vehicles.php');

    try {
      // Reset progress to 0
      uploadProgress.value = 0;

      // Show progress dialog first
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: ValueListenableBuilder<double>(
            valueListenable: uploadProgress,
            builder: (context, value, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: value / 100),
                  SizedBox(height: 16),
                  Text('Uploading... ${value.toInt()}%'),
                ],
              );
            },
          ),
        ),
      );

      // Create and prepare the request
      var request = http.MultipartRequest('POST', url);

      request.fields['vehicle_type'] = vehiclename; // ✅ اسم المركبة
      request.fields['model'] = modelname;
      request.fields['vehicle_number'] = vehicle_number; // ✅ الموديل
      request.fields['status'] = status; // ✅ الحالة (مثلاً: "فعال")
      request.fields['current_location'] = currectlocation; // ✅ الموقع الحالي
      request.fields['governorate_id'] = govId.toString(); // ✅ رقم المحافظة
      request.fields['created_by'] = createdBy.toString(); // ✅ المضاف بواسطة

      // Simulate progress for sending data (actual progress monitoring is limited with http package)
      // This creates a smoother visual feedback
      Timer.periodic(Duration(milliseconds: 100), (timer) {
        if (uploadProgress.value < 90) {
          uploadProgress.value += 2;
        }
        if (!context.mounted) timer.cancel();
      });

      // Send the request
      var streamedResponse = await request.send();

      // Get the response data
      var responseBytes = await streamedResponse.stream.toBytes();
      var responseString = utf8.decode(responseBytes);
      var responseData = jsonDecode(responseString);

      // Set progress to 100% when done
      uploadProgress.value = 100;

      // Wait a moment at 100% before closing dialog
      await Future.delayed(Duration(milliseconds: 500));

      // Close the dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.pop(context);
      }

      // Handle response
      if (streamedResponse.statusCode == 200 &&
          responseData['success'] == true) {
        // Reset form fields
        vehicle_name_Controller.clear();
        vehicle_model_Controller.clear();
        vehicle_num_Controller.clear();
        Selectstatusvehicle = statusvehicle.first;
        Selectprojects_name = projects_name.first;

        // Refresh projects list
        await fetchvehicle();

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Project added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to add project: ${responseData['message'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close dialog if still open
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

/*Future<void> fetchvehicle(int createdby_id) async {
  setState(() {
      _isLoading = true; // Add this loading state variable to the class
    });
    try {
      final response = await http.post(Uri.parse(
          'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/fetch_vehicles_data.php?t=${DateTime.now().millisecondsSinceEpoch}'),
         body: {
          'created_by': createdby_id.toString(),
         }
          );
          

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("Machinery Data: $data"); // Add this to debug
        setState(() {
          _mockMachinery = data.map<Map<String, dynamic>>((vehicle) => {
            'vehicle_id':vehicle['vehicle_id'],
            'name': vehicle['vehicle_type'],
            'status': vehicle['status'],
            'vehicle_number': vehicle['vehicle_number'],
            'location': vehicle['current_location'],
            'vehicle_id ': vehicle['vehicle_id '],
            'created_at': vehicle['created_at'],
            'updated_at': vehicle['updated_at']
          }).toList();
          _isLoading = false;
           // Set loading state to false after data is fetched
          
        });
      }else {
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
  }*/

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

  @override
  void dispose() {
    // تحرير الموارد عند إنهاء الصفحة
    searchController.dispose();
    searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    fetchSupervisors();
    print("user_id: ${widget.user_id}");
    fetchgovernorate();
    fetchProjects(widget.user_id); // إضافة استدعاء لجلب المشاريع
    //fetchvehicle(widget.user_id);
    fetchvehicle();
    fetchDrivers();
  }

  // إضافة دالة لجلب المشاريع من قاعدة البيانات
/*Future<void> fetchProjects() async {
  try {
    final response = await http.get(Uri.parse(
        'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/fetchProjects.php'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print("Projects Data: $data");
      
      setState(() {
        _mockProjects = data.map<Map<String, dynamic>>((project) => {
          'name': project['project_name'],
          'status': project['status'],
          'completion': project['status'] == 'completed' ? 1.0 : 
                      project['status'] == 'in_progress' ? 0.7 : 
                      project['status'] == 'on_hold' ? 0.5 : 0.0,
          'cost': double.parse(project['budget'].toString()),
          'projectImage': project['project_image'],
          'startDate': project['start_date'],
          'endDate': project['end_date'],
          'city': project['cityname'],
          'supervisor': project['supervisor_name'] ?? 'Not Assigned',
        }).toList();
      });
    }
  } catch (e) {
    print('Error fetching projects: $e');
  }
}*/
  Future<void> fetchProjects(int createdby_id) async {
    setState(() {
      _isLoading = true; // Add this loading state variable to the class
    });
    try {
      final response = await http.post(
          Uri.parse(
              'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/fetchProjects.php?t=${DateTime.now().millisecondsSinceEpoch}'),
          body: {
            'created_by': createdby_id.toString(),
          });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        print("Projects Data: $data");

        setState(() {
          projects_name =
              data.map((project) => project['project_name']).toList();
          _mockProjects = data
              .map<Map<String, dynamic>>((project) => {
                    'name': project['project_name'],
                    'status': project['status'],
                    'completion': project['status'] == 'completed'
                        ? 1.0
                        : project['status'] == 'in_progress'
                            ? 0.7
                            : project['status'] == 'on_hold'
                                ? 0.5
                                : 0.0,
                    'cost': double.parse(project['budget']),
                    'projectImage': project['project_image'],
                    'startDate': project['start_date'],
                    'endDate': project['end_date'],
                    'city': project['cityname'],
                    'supervisor': project['supervisor_name'] ?? 'Not Assigned',
                    'project_id': project['project_id'],
                    'created_at': project['created_at'],
                    'updated_at': project['updated_at']
                  })
              .toList();
          _isLoading = false;
          // Set loading state to false after data is fetched
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

/*Future<void> sendUserData(String name_project,String city_name,int gov_id,String cost,
String status,int super_id,DateTime s_date,DateTime e_date,int created_by) async {
  final url = Uri.parse('https://antiquewhite-cobra-422929.hostingersite.com/georgecode/insert_project.php'); // 🔁 غيّر الرابط حسب موقع السكربت

  try {
    final response = await http.post(
      url,
      body: {
        'project_name': name_project,
        'governorate_id': gov_id.toString(),
        'start_date': s_date.toIso8601String(),
        'end_date': e_date.toIso8601String(),
        'supervisor_id': super_id.toString(),
        'budget': cost,
        'cityname': city_name,
        'status': status,
        'created_by': created_by.toString(),
      },
    );

    // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Adding project...'),
              ],
            ),
          ),
        ),
      );
    },
  );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['success']) {
       await fetchProjects(); // Refresh the projects list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add project: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print('❌ Error connection: ${response.statusCode}');
    }
    Navigator.pop(context); // Hide loading dialog
  } catch (e) {
     // Hide loading dialog if error occurs
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error adding project: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
} */

// First, add this to your class variables (right after where you declare other variables)
  final ValueNotifier<double> uploadProgress = ValueNotifier<double>(0);

  Future<void> sendUserDataWithProgress(
    BuildContext context,
    String nameProject,
    String cityName,
    int govId,
    String cost,
    String contract_value,
    String status,
    int superId,
    DateTime sDate,
    DateTime eDate,
    int createdBy,
  ) async {
    final url = Uri.parse(
        'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/insert_project.php');

    try {
      // Reset progress to 0
      uploadProgress.value = 0;

      // Show progress dialog first
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: ValueListenableBuilder<double>(
            valueListenable: uploadProgress,
            builder: (context, value, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: value / 100),
                  SizedBox(height: 16),
                  Text('Uploading... ${value.toInt()}%'),
                ],
              );
            },
          ),
        ),
      );

      // Create and prepare the request
      var request = http.MultipartRequest('POST', url);

      request.fields['project_name'] = nameProject;
      request.fields['governorate_id'] = govId.toString();
      request.fields['start_date'] = sDate.toIso8601String();
      request.fields['end_date'] = eDate.toIso8601String();
      request.fields['supervisor_id'] = superId.toString();
      request.fields['budget'] = cost;
      request.fields['contract_value'] = contract_value;
      request.fields['cityname'] = cityName;
      request.fields['status'] = status;
      request.fields['created_by'] = createdBy.toString();

      if (projectImage != null) {
        if (kIsWeb) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'project_image',
              projectImage!.bytes!,
              filename: 'project_image.jpg',
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(
              'project_image',
              projectImage!.path!,
            ),
          );
        }
      }

      if (contractImage != null) {
        if (kIsWeb) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'contract_image',
              contractImage!.bytes!,
              filename: 'contract_image.jpg',
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(
              'contract_image',
              contractImage!.path!,
            ),
          );
        }
      }

      // Simulate progress for sending data (actual progress monitoring is limited with http package)
      // This creates a smoother visual feedback
      Timer.periodic(Duration(milliseconds: 100), (timer) {
        if (uploadProgress.value < 90) {
          uploadProgress.value += 2;
        }
        if (!context.mounted) timer.cancel();
      });

      // Send the request
      var streamedResponse = await request.send();

      // Get the response data
      var responseBytes = await streamedResponse.stream.toBytes();
      var responseString = utf8.decode(responseBytes);
      var responseData = jsonDecode(responseString);

      // Set progress to 100% when done
      uploadProgress.value = 100;

      // Wait a moment at 100% before closing dialog
      await Future.delayed(Duration(milliseconds: 500));

      // Close the dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.pop(context);
      }

      // Handle response
      if (streamedResponse.statusCode == 200 &&
          responseData['success'] == true) {
        // Reset form fields
        nameController.clear();
        cityController.clear();
        costController.clear();
        contractvalueController.clear();
        selectedStatus = statusList.first;
        selectedSupervisor = null;
        startDate = null;
        endDate = null;
        projectImage = null;
        contractImage = null;

        // Refresh projects list
        await fetchProjects(widget.user_id);

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Project added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to add project: ${responseData['message'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close dialog if still open
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  /* if (response.statusCode == 200 && result['success'] == true) {
      // Reset form fields
      nameController.clear();
      cityController.clear();
      costController.clear();
      selectedStatus = statusList.first;
      selectedSupervisor = null;
      startDate = null;
      endDate = null;
      projectImage = null;
      contractImage = null;
      
      // Refresh projects list
      await fetchProjects(widget.user_id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Project added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add project: ${result['message'] ?? 'Unknown error'}'),
          backgroundColor: Colors.red,
        ),
      );
    } 

  } catch (e) {
    // Close the progress dialog if it's open
    Navigator.of(context, rootNavigator: true).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
  }*/

  Future<void> fetchSupervisors() async {
    try {
      final response = await http.get(Uri.parse(
          'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/connectandgetusersname.php'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          supervisors = data
              .where((user) => user['role'] == 'civil engineer')
              .map<Map<String, dynamic>>((user) => {
                    'full_name': user['full_name'],
                    'user_id': user['user_id'],
                  })
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching supervisors: $e');
    }
  }

  Future<void> fetchgovernorate() async {
    try {
      final response = await http.get(Uri.parse(
          'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/connectandgetgovernorate.php'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          governorate = data
              .where((user) => user['manager_name'] == widget.fullName)
              .map<Map<String, dynamic>>((user) => {
                    'governorate_id': user['governorate_id'],
                    'manager_name': user['manager_name'],
                  })
              .toList();
          governorate_id = governorate[0]['governorate_id'];
          print(governorate_id);
        });
      }
    } catch (e) {
      print('Error fetching governorate: $e');
    }
  }

  void _showAddDialog(String type) {
    if (type == 'Project') {
      PlatformFile? localProjectImage = projectImage;
      PlatformFile? localContractImage = contractImage;
      DateTime? localStartDate = startDate;
      DateTime? localEndtDate = endDate;
      showDialog(
        context: context,
        builder: (context) {
          final screenSize = MediaQuery.of(context).size;
          final isSmallScreen = screenSize.width < 600;
          return StatefulBuilder(builder: (context, setDialogState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : screenSize.width * 0.2,
                vertical: isSmallScreen ? 24 : screenSize.height * 0.1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 800,
                  maxHeight: screenSize.height * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Add New Project',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    // Content - All form fields and images in one ScrollView
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Project Details Section
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.start,
                              children: [
                                Container(
                                  width: isSmallScreen
                                      ? double.infinity
                                      : (screenSize.width * 0.25),
                                  child: TextField(
                                    controller: nameController,
                                    decoration: InputDecoration(
                                      labelText: 'Project Name',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.work),
                                    ),
                                  ),
                                ),
                                // ... other form fields ...
                                Container(
                                  width: isSmallScreen
                                      ? double.infinity
                                      : (screenSize.width * 0.25),
                                  child: TextField(
                                    controller: cityController,
                                    decoration: InputDecoration(
                                      labelText: 'City Name',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.location_city),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: isSmallScreen
                                      ? double.infinity
                                      : (screenSize.width * 0.25),
                                  child: TextField(
                                    controller: costController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Budget',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.attach_money),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: isSmallScreen
                                      ? double.infinity
                                      : (screenSize.width * 0.25),
                                  child: TextField(
                                    controller: contractvalueController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Contract Value',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.attach_money),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: isSmallScreen
                                      ? double.infinity
                                      : (screenSize.width * 0.25),
                                  child: DropdownButtonFormField<String>(
                                    value: selectedStatus,
                                    decoration: InputDecoration(
                                      labelText: 'Project Status',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.info_outline),
                                    ),
                                    items: statusList.map((String status) {
                                      return DropdownMenuItem(
                                        value: status,
                                        child: Text(status
                                            .replaceAll('_', ' ')
                                            .toUpperCase()),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedStatus = newValue;
                                      });
                                    },
                                  ),
                                ),
                                Container(
                                  width: isSmallScreen
                                      ? double.infinity
                                      : (screenSize.width * 0.25),
                                  child: DropdownButtonFormField<int>(
                                    value: selectedSupervisor,
                                    decoration: InputDecoration(
                                      labelText: 'Supervisor',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.person),
                                    ),
                                    items: supervisors.map((supervisor) {
                                      return DropdownMenuItem(
                                        value: supervisor['user_id'] as int,
                                        child: Text(supervisor['full_name']),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        selectedSupervisor = newValue;
                                        final selectedSupervisorData =
                                            supervisors.firstWhere(
                                          (supervisor) =>
                                              supervisor['user_id'] == newValue,
                                          orElse: () =>
                                              {'full_name': 'Not found'},
                                        );
                                        selectedSupervisorName =
                                            selectedSupervisorData['full_name'];
                                      });
                                    },
                                  ),
                                ),
                                Container(
                                  width: isSmallScreen
                                      ? double.infinity
                                      : (screenSize.width * 0.25),
                                  child: InkWell(
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (date != null) {
                                        setState(() {
                                          startDate = date;
                                        });
                                        setDialogState(() {
                                          localStartDate = date;
                                          // If end date exists and is before start date, reset it
                                          if (localEndtDate != null &&
                                              localEndtDate!.isBefore(date)) {
                                            localEndtDate = null;
                                            endDate = null;
                                          }
                                        });
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Start Date',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.calendar_today),
                                      ),
                                      child: Text(
                                        localStartDate
                                                ?.toString()
                                                .split(' ')[0] ??
                                            'Select Date',
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: isSmallScreen
                                      ? double.infinity
                                      : (screenSize.width * 0.25),
                                  child: InkWell(
                                    onTap: () async {
                                      // If start date is not selected, show message
                                      if (localStartDate == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Please select start date first'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }

                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: localStartDate!
                                            .add(Duration(days: 1)),
                                        firstDate: localStartDate!
                                            .add(Duration(days: 1)),
                                        lastDate: DateTime(2030),
                                      );
                                      if (date != null) {
                                        // Validate that end date is after start date
                                        if (date.isAfter(localStartDate!)) {
                                          setState(() {
                                            endDate = date;
                                          });
                                          setDialogState(() {
                                            localEndtDate = date;
                                          });
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'End date must be after start date'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'End Date',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.calendar_today),
                                        // Add visual indication if start date is not selected
                                        filled: localStartDate == null,
                                        fillColor: localStartDate == null
                                            ? Colors.grey.shade200
                                            : null,
                                      ),
                                      child: Text(
                                        localEndtDate
                                                ?.toString()
                                                .split(' ')[0] ??
                                            'Select Date',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Image Selection Buttons - Now inside the same ScrollView
                            SizedBox(height: 24),
                            Text(
                              "Project Images",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.start,
                              children: [
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final result =
                                          await FilePicker.platform.pickFiles(
                                        type: FileType.image,
                                        withData: true,
                                      );

                                      if (result != null &&
                                          result.files.isNotEmpty) {
                                        // Update both the dialog state and parent state
                                        setDialogState(() {
                                          localProjectImage =
                                              result.files.first;
                                          print(
                                              "localProjectImage ${localProjectImage!.name}");
                                        });

                                        setState(() {
                                          projectImage = result.files.first;
                                          print(
                                              "projectImage ${projectImage!.name}");
                                        });
                                      }
                                    },
                                    icon:
                                        Icon(Icons.image, color: Colors.white),
                                    label: Text('Select Project Image'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                      backgroundColor: localProjectImage != null
                                          ? Colors.green
                                          : Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation:
                                          localProjectImage != null ? 2 : 1,
                                    ),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final result =
                                          await FilePicker.platform.pickFiles(
                                        type: FileType.image,
                                        withData: true,
                                      );

                                      if (result != null &&
                                          result.files.isNotEmpty) {
                                        // Update both the dialog state and parent state
                                        setDialogState(() {
                                          localContractImage =
                                              result.files.first;
                                        });

                                        setState(() {
                                          contractImage = result.files.first;
                                        });
                                      }
                                    },
                                    icon: Icon(Icons.file_copy,
                                        color: Colors.white),
                                    label: Text('Select Contract Image'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                      backgroundColor:
                                          localContractImage != null
                                              ? Colors.green
                                              : Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation:
                                          localContractImage != null ? 2 : 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Image Previews - Now inside the same ScrollView
                            SizedBox(height: 24),
                            if (localProjectImage != null ||
                                localContractImage != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Selected Images",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    children: [
                                      if (localProjectImage != null)
                                        Container(
                                          width: 300,
                                          height: 200,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.1),
                                                spreadRadius: 1,
                                                blurRadius: 5,
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: kIsWeb
                                                    ? Image.memory(
                                                        localProjectImage!
                                                            .bytes!,
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                      )
                                                    : Image.file(
                                                        File(localProjectImage!
                                                            .path!),
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                      ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: IconButton(
                                                  icon: Icon(Icons.close,
                                                      color: Colors.white),
                                                  onPressed: () {
                                                    setDialogState(() {
                                                      localProjectImage = null;
                                                    });
                                                    setState(() {
                                                      projectImage = null;
                                                    });
                                                  },
                                                  style: IconButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.black54,
                                                    padding: EdgeInsets.all(8),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (localContractImage != null)
                                        Container(
                                          width: 300,
                                          height: 200,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.1),
                                                spreadRadius: 1,
                                                blurRadius: 5,
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: kIsWeb
                                                    ? Image.memory(
                                                        localContractImage!
                                                            .bytes!,
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                      )
                                                    : Image.file(
                                                        File(localContractImage!
                                                            .path!),
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                      ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: IconButton(
                                                  icon: Icon(Icons.close,
                                                      color: Colors.white),
                                                  onPressed: () {
                                                    setDialogState(() {
                                                      localContractImage = null;
                                                    });
                                                    setState(() {
                                                      contractImage = null;
                                                    });
                                                  },
                                                  style: IconButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.black54,
                                                    padding: EdgeInsets.all(8),
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
                          ],
                        ),
                      ),
                    ),

                    // Footer Actions
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                            top: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (_validateForm()) {
                                sendUserDataWithProgress(
                                  context,
                                  nameController.text,
                                  cityController.text,
                                  governorate_id!,
                                  costController.text,
                                  contractvalueController.text,
                                  selectedStatus!,
                                  selectedSupervisor!,
                                  startDate!,
                                  endDate!,
                                  widget.user_id,
                                );
                              }
                            },
                            child: Text('Add Project'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
      );
    }

    if (type == 'Machinery') {
      showDialog(
        context: context,
        builder: (context) {
          final screenSize = MediaQuery.of(context).size;
          final isSmallScreen = screenSize.width < 600;
          return StatefulBuilder(builder: (context, setDialogState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : screenSize.width * 0.2,
                vertical: isSmallScreen ? 24 : screenSize.height * 0.1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 800,
                  maxHeight: screenSize.height * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Add New Vehicle',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    // Content - All form fields and images in one ScrollView
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Project Details Section
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.start,
                              children: [
                                Container(
                                  width: isSmallScreen
                                      ? double.infinity
                                      : (screenSize.width * 0.25),
                                  child: TextField(
                                    controller: vehicle_name_Controller,
                                    decoration: InputDecoration(
                                      labelText: 'Vehicle Name',
                                      border: OutlineInputBorder(),
                                      prefixIcon:
                                          Icon(Icons.precision_manufacturing),
                                    ),
                                  ),
                                ),
                                // ... other form fields ...
                                Container(
                                  width: isSmallScreen
                                      ? double.infinity
                                      : (screenSize.width * 0.25),
                                  child: TextField(
                                    controller: vehicle_model_Controller,
                                    decoration: InputDecoration(
                                      labelText: 'Model',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.push_pin_outlined),
                                    ),
                                  ),
                                ),
                                // ... other form fields ...
                                Container(
                                  width: isSmallScreen
                                      ? double.infinity
                                      : (screenSize.width * 0.25),
                                  child: TextField(
                                    controller: vehicle_num_Controller,
                                    decoration: InputDecoration(
                                      labelText: 'Vehicle Number',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.push_pin_outlined),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: isSmallScreen
                                      ? double.infinity
                                      : (screenSize.width * 0.25),
                                  child: DropdownButtonFormField<dynamic>(
                                    value: Selectprojects_name,
                                    decoration: InputDecoration(
                                      labelText: 'Currect Location',
                                      border: OutlineInputBorder(),
                                      prefixIcon:
                                          Icon(Icons.location_city_rounded),
                                    ),
                                    items: projects_name
                                        .map((dynamic projectLname) {
                                      return DropdownMenuItem(
                                        value: projectLname,
                                        child: Text(projectLname
                                            .replaceAll('_', ' ')
                                            .toUpperCase()),
                                      );
                                    }).toList(),
                                    onChanged: (dynamic? newValue) {
                                      setState(() {
                                        Selectprojects_name = newValue;
                                      });
                                    },
                                  ),
                                ),
                                Container(
                                  width: isSmallScreen
                                      ? double.infinity
                                      : (screenSize.width * 0.25),
                                  child: DropdownButtonFormField<String>(
                                    value: selectedStatus,
                                    decoration: InputDecoration(
                                      labelText: 'Status',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.info_outline),
                                    ),
                                    items: statusvehicle.map((String status) {
                                      return DropdownMenuItem(
                                        value: status,
                                        child: Text(status
                                            .replaceAll('_', ' ')
                                            .toUpperCase()),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        Selectstatusvehicle = newValue;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Footer Actions
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                            top: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (_validateVehicleForm()) {
                                sendVehicleDataWithProgress(
                                    context,
                                    vehicle_name_Controller.text,
                                    vehicle_model_Controller.text,
                                    vehicle_num_Controller.text,
                                    Selectstatusvehicle!,
                                    Selectprojects_name!.toString(),
                                    governorate_id!,
                                    widget.user_id!);
                              }
                            },
                            child: Text('Add Project'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
      );
    }
  }

  bool _validateVehicleForm() {
    if (vehicle_name_Controller.text.isEmpty) {
      _showError('Please enter vehicle name');
      return false;
    }
    if (vehicle_model_Controller.text.isEmpty) {
      _showError('Please enter model name');
      return false;
    }
    if (vehicle_num_Controller.text.isEmpty) {
      _showError('Please enter vehicle number');
      return false;
    }
    if (Selectstatusvehicle == null) {
      _showError('Please select vechicle status');
      return false;
    }
    if (Selectprojects_name == null) {
      _showError('Please select Location');
      return false;
    }

    return true;
  }

  bool _validateForm() {
    if (nameController.text.isEmpty) {
      _showError('Please enter project name');
      return false;
    }
    if (cityController.text.isEmpty) {
      _showError('Please enter city name');
      return false;
    }
    if (costController.text.isEmpty) {
      _showError('Please enter project cost');
      return false;
    }
    if (selectedStatus == null) {
      _showError('Please select project status');
      return false;
    }
    if (selectedSupervisor == null) {
      _showError('Please select supervisor');
      return false;
    }
    if (startDate == null) {
      _showError('Please select start date');
      return false;
    }
    if (endDate == null) {
      _showError('Please select end date');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

int? _columnIndex(String field) {
  switch (field) {
    case 'inv_num':
      return 0;
    case 'inv_title':
      return 1;
    case 'inv_date':
      return 2;
    case 'created_at':
      return 3;
    case 'cost':
      return 5;
    default:
      return null;
  }
}

class Invoice {
  final String inv_num;
  final String inv_title;
  final DateTime inv_date;
  final DateTime created_at;
  final String status;
  /*final double cost;*/

  Invoice({
    required this.inv_num,
    required this.inv_title,
    required this.inv_date,
    required this.created_at,
    required this.status,
    /*required this.cost,*/
  });
}

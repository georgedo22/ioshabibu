import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:habibuios/InventoryApp/inventory_screen.dart';
import 'package:habibuios/Mechanical%20Engineer/MachineDetailsPageMechanical.dart';
import 'package:habibuios/main.dart';


import 'package:http/http.dart' as http;

class MechanicalEngineerDashboard extends StatefulWidget {
  final String username;
  final String fullName;
  final int user_id;

  MechanicalEngineerDashboard(
      {required this.username, required this.fullName, required this.user_id});

  @override
  _MechanicalEngineerDashboardState createState() =>
      _MechanicalEngineerDashboardState();
}

class _MechanicalEngineerDashboardState
    extends State<MechanicalEngineerDashboard> {
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2); // أزرق
  final Color secondaryColor = Colors.white;
  final Color accentColor = const Color(0xFF64B5F6); // أزرق فاتح

  // معلومات المستخدم
  String userName = "Mechanical Engineer";
  String userEmail = "engineer@example.com";
  String userAvatar = "assets/person.jpg";

  int _selectedIndex = 0;

  // قائمة الصفحات التي سيتم عرضها
  List<Widget> get _pages => [
        _buildMachinerySection(), // استخدام widget الآليات
        InventoryScreen(),
        // const Center(
        // child: Text('صفحة المخزون', style: TextStyle(fontSize: 24))),
      ];

  List<Map<String, dynamic>> _mockMachinery = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchvehicle(); // استدعاء البيانات عند تحميل الصفحة
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mechanical Engineer Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: secondaryColor),
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
      //bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: secondaryColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(),
            _buildDrawerItem(
              icon: Icons.engineering,
              text: 'Machinery',
              index: 0,
            ),
            _buildDrawerItem(
              icon: Icons.inventory,
              text: 'Inventory',
              index: 1,
            ),
            const Divider(thickness: 1),
            _buildDrawerItem(
              icon: Icons.logout,
              text: 'Logout',
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: primaryColor,
        /*image: const DecorationImage(
          image: AssetImage('assets/background.jpg'),
          fit: BoxFit.cover,
          opacity: 0.7,
        ),*/
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userName,
            style: TextStyle(
              color: secondaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.fullName,
            style: TextStyle(
              color: secondaryColor.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    int? index,
    VoidCallback? onTap,
  }) {
    final bool isSelected = index != null && index == _selectedIndex;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? primaryColor : Colors.grey[700],
      ),
      title: Text(
        text,
        style: TextStyle(
          color: isSelected ? primaryColor : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? accentColor.withOpacity(0.2) : null,
      shape: isSelected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      onTap: onTap ??
          () {
            if (index != null) {
              setState(() {
                _selectedIndex = index;
              });
              Navigator.pop(context); // إغلاق القائمة الجانبية بعد الاختيار
            }
          },
    );
  }

/*  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: secondaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.engineering),
            label: 'الآليات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'المخزون',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: secondaryColor,
        elevation: 0,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }*/

  // دالة تسجيل الخروج
  void _logout() async {
    // عرض مربع حوار للتأكيد
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // العودة إلى صفحة تسجيل الدخول
                Navigator.of(context).pop(); // إغلاق مربع الحوار
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MachineDetailPageMechanical(machine: machine),
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

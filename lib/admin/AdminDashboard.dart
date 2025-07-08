import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:habibuios/admin/profit_test.dart';
import 'package:habibuios/dashboard_new.dart';
import 'package:habibuios/main.dart';
import 'package:habibuios/users_page.dart';

import 'package:http/http.dart' as http;

class Governorate {
  final int id;
  final String name;
  final String status;
  final String fullName;
  final String areaManager;
  Governorate({
    required this.id,
    required this.name,
    required this.status,
    required this.fullName,
    required this.areaManager,
  });

  factory Governorate.fromJson(Map<String, dynamic> json) {
    return Governorate(
      id: json['governorate_id'],
      name: json['governorate_name'],
      status: json['status'],
      fullName: json['full_name'],
      areaManager: json['manager_name'],
    );
  }
}

class AdminDashboard extends StatefulWidget {
  final String username;
  final String fullName;
  final int user_id;

  AdminDashboard(
      {required this.username, required this.fullName, required this.user_id});
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Future<List<Governorate>> _governoratesFuture;
  List<dynamic> users = [];
  @override
  void initState() {
    super.initState();
    _governoratesFuture = fetchGovernorates();
    fetchUsers();
  }

  // Fetch User from the API
  Future<void> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse(
          'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/admin/get_users.php'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          setState(() {
            users = jsonResponse['data'];
          });
        } else {
          print('Failed to authenticate');
        }
      } else {
        print(
            'Failed to connect to server with status code: \\${response.statusCode}');
      }
    } catch (e) {
      print('Network error: $e');
    }
  }

  Future<List<Governorate>> fetchGovernorates() async {
    final response = await http.get(Uri.parse(
        'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/admin/fetch_governorates.php'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((item) => Governorate.fromJson(item))
            .toList();
      }
    }
    throw Exception('Failed to load governorates');
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'active';
      case 'inactive':
        return 'inactive';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('List of states'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add_location_alt),
            tooltip: 'Add Governorate',
            onPressed: () async {
              final result = await showDialog(
                context: context,
                builder: (context) => AddGovernorateDialog(
                  user_id: widget.user_id,
                  users: users, // تمرير قائمة المستخدمين
                ),
              );
              if (result == true) {
                setState(() {
                  _governoratesFuture = fetchGovernorates();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Governorate added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blue.shade800],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Text(
                        widget.fullName.isNotEmpty
                            ? widget.fullName[0].toUpperCase()
                            : '',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Welcome!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
                      child: Text(
                        widget.fullName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            /*ListTile(
              leading: Icon(Icons.location_on, color: Colors.blue),
              title: Text('States'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StatesPage()),
                );
              },
            ),*/
            ListTile(
              leading: Icon(Icons.people, color: Colors.blue),
              title: Text('Users'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UsersPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.bar_chart, color: Colors.blue),
              title: Text('Reports'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfitTestPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<List<Governorate>>(
          future: _governoratesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                  child: Text('An error occurred while loading the data.'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No states are available.'));
            }
            final governorates = snapshot.data!;
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 2 : 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isWide ? 2.8 : 2.2,
                    ),
                    itemCount: governorates.length,
                    itemBuilder: (context, index) {
                      final gov = governorates[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Dashboard(governorateId: gov.id),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.blue.shade50],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            padding: EdgeInsets.all(20),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: _statusColor(gov.status)
                                      .withOpacity(0.15),
                                  child: Icon(
                                    Icons.location_city,
                                    color: Colors.blue.shade700,
                                    size: 32,
                                  ),
                                ),
                                SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        gov.name,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Area Manager : ${gov.areaManager}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.blueGrey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _statusColor(gov.status)
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              _statusText(gov.status),
                                              style: TextStyle(
                                                color: _statusColor(gov.status),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Icon(Icons.person,
                                              size: 18,
                                              color: Colors.grey[700]),
                                          SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              gov.fullName,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[800],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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
          },
        ),
      ),
    );
  }
}

// Dialog for adding governorate
class AddGovernorateDialog extends StatefulWidget {
  final int user_id;
  final List<dynamic> users;
  AddGovernorateDialog({Key? key, required this.user_id, required this.users})
      : super(key: key);
  @override
  State<AddGovernorateDialog> createState() => _AddGovernorateDialogState();
}

class _AddGovernorateDialogState extends State<AddGovernorateDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  String? selectedManager;
  String status = 'active';
  bool isLoading = false;
  String? errorMessage;

  Future<void> addGovernorate() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    final url =
        'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/admin/add_governorate.php';
    final body = json.encode({
      'name': nameController.text.trim(),
      'manager_name': selectedManager ?? '',
      'status': status,
      'created_by': widget.user_id,
    });
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      final result = json.decode(response.body);
      if (result['success'] == true) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to add governorate';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Governorate'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Governorate Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedManager,
                decoration: InputDecoration(labelText: 'Manager Name'),
                items: widget.users
                    .map<DropdownMenuItem<String>>(
                        (user) => DropdownMenuItem<String>(
                              value: user['full_name'],
                              child: Text(user['full_name']),
                            ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedManager = val;
                  });
                },
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: status,
                decoration: InputDecoration(labelText: 'Status'),
                items: [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: (val) {
                  setState(() {
                    status = val ?? 'active';
                  });
                },
              ),
              if (errorMessage != null) ...[
                SizedBox(height: 8),
                Text(errorMessage!, style: TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading
              ? null
              : () {
                  if (_formKey.currentState!.validate()) {
                    addGovernorate();
                  }
                },
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Add'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class UsersPage extends StatefulWidget {
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<dynamic> users = [];
  late Future<List<Governorate>> _governoratesFuture;
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

  @override
  void initState() {
    super.initState();
    fetchUsers(); // استدعاء البيانات عند تحميل الصفحة
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users'), // تحديث العنوان إلى "Users"
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // الرجوع إلى الصفحة الرئيسية
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            tooltip: 'Add User',
            onPressed: () async {
              final result = await showDialog(
                context: context,
                builder: (context) => AddUserDialog(),
              );
              if (result == true) {
                fetchUsers();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User added successfully!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue,
                          child: Text(
                            user['full_name'][0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['full_name'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user['email'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.phone, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          user['phone'],
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.work, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          user['role'],
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class Governorate {
  final int id;
  final String name;
  Governorate({required this.id, required this.name});
  factory Governorate.fromJson(Map<String, dynamic> json) {
    return Governorate(
      id: int.tryParse(json['governorate_id'].toString()) ?? 0,
      name: json['governorate_name'] ?? '',
    );
  }
}

class AddUserDialog extends StatefulWidget {
  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
  List<Governorate> governorates = [];
  int? selectedGovId;
  bool isGovLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGovernorates();
  }

  Future<void> fetchGovernorates() async {
    setState(() {
      isGovLoading = true;
    });
    try {
      final response = await http.get(Uri.parse(
          'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/admin/fetch_governorates.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final loadedGovernorates = (data['data'] as List)
              .map((item) => Governorate.fromJson(item))
              .toList();
          setState(() {
            governorates = loadedGovernorates;
            if (governorates.isNotEmpty) {
              selectedGovId = null;
            }
            isGovLoading = false;
          });
        } else {
          setState(() {
            isGovLoading = false;
          });
        }
      } else {
        setState(() {
          isGovLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isGovLoading = false;
      });
    }
  }

  Future<void> addUser() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    final url =
        'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/admin/add_user.php';
    final body = json.encode({
      'username': usernameController.text.trim(),
      'full_name': fullNameController.text.trim(),
      'email': emailController.text.trim(),
      'password': passwordController.text.trim(),
      'phone': '+234' + phoneController.text.trim(),
      'role': roleController.text.trim(),
      'gov_id': selectedGovId,
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
          errorMessage = result['message'] ?? 'Failed to add user';
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;
    final isMedium = screenWidth >= 400 && screenWidth < 700;
    final double dialogWidth = isSmall
        ? screenWidth * 0.98
        : isMedium
            ? 380
            : 420;
    final double fieldFontSize = isSmall ? 13 : 15;
    final double labelFontSize = isSmall ? 14 : 16;
    final double titleFontSize = isSmall ? 18 : 22;
    final double contentPadding = isSmall ? 8 : 14;
    final double rowSpacing = isSmall ? 8 : 14;
    final double buttonPadding = isSmall ? 10 : 28;
    final double buttonHeight = isSmall ? 36 : 44;
    final double iconSize = isSmall ? 18 : 22;
    final double borderRadius = isSmall ? 10 : 18;

    InputDecoration _responsiveInputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: labelFontSize),
        prefixIcon: Icon(icon, size: iconSize),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(vertical: contentPadding, horizontal: contentPadding),
      );
    }

    Widget buildRowOrColumn(List<Widget> children) {
      if (isSmall) {
        return Column(
          children: [
            ...children.expand((w) => [w, SizedBox(height: rowSpacing)]).toList()..removeLast(),
          ],
        );
      } else {
        return Row(
          children: [
            Expanded(child: children[0]),
            SizedBox(width: rowSpacing),
            Expanded(child: children[1]),
          ],
        );
      }
    }

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      title: Center(
        child: Text(
          'Add New User',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: titleFontSize,
              color: Colors.blue[800]),
        ),
      ),
      content: Container(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildRowOrColumn([
                  TextFormField(
                    controller: usernameController,
                    style: TextStyle(fontSize: fieldFontSize),
                    decoration: _responsiveInputDecoration('Username', Icons.person_outline),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: fullNameController,
                    style: TextStyle(fontSize: fieldFontSize),
                    decoration: _responsiveInputDecoration('Full Name', Icons.badge_outlined),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ]),
                SizedBox(height: rowSpacing),
                buildRowOrColumn([
                  TextFormField(
                    controller: emailController,
                    style: TextStyle(fontSize: fieldFontSize),
                    decoration: _responsiveInputDecoration('Email', Icons.email_outlined),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: phoneController,
                    style: TextStyle(fontSize: fieldFontSize),
                    decoration: _responsiveInputDecoration('Phone', Icons.phone_outlined).copyWith(
                      prefixIcon: null,
                      prefix: Padding(
                        padding: EdgeInsets.only(left: 8, right: 4),
                        child: Text(
                          '+234',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: fieldFontSize),
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ]),
                SizedBox(height: rowSpacing),
                buildRowOrColumn([
                  TextFormField(
                    controller: passwordController,
                    style: TextStyle(fontSize: fieldFontSize),
                    decoration: _responsiveInputDecoration('Password', Icons.lock_outline),
                    obscureText: true,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: roleController.text.isNotEmpty ? roleController.text : null,
                    decoration: _responsiveInputDecoration('Role', Icons.work_outline),
                    items: [
                      'admin',
                      'area manager',
                      'civil engineer',
                      'eng michanic',
                      'michanic',
                      'other',
                    ]
                        .map((role) => DropdownMenuItem<String>(
                              value: role,
                              child: Text(role[0].toUpperCase() + role.substring(1), style: TextStyle(fontSize: fieldFontSize)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        roleController.text = val ?? '';
                      });
                    },
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ]),
                SizedBox(height: rowSpacing),
                isGovLoading
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: rowSpacing),
                        child: CircularProgressIndicator(),
                      )
                    : DropdownButtonFormField<int>(
                        value: governorates.any((g) => g.id == selectedGovId) ? selectedGovId : null,
                        decoration: _responsiveInputDecoration('Governorate', Icons.location_city_outlined),
                        items: governorates
                            .map((g) => DropdownMenuItem<int>(
                                  value: g.id,
                                  child: Text(g.name, style: TextStyle(fontSize: fieldFontSize)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedGovId = val;
                          });
                        },
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                if (!isGovLoading && governorates.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('No governorates found.', style: TextStyle(color: Colors.red, fontSize: fieldFontSize)),
                  ),
                if (errorMessage != null) ...[
                  SizedBox(height: 6),
                  Text(errorMessage!, style: TextStyle(color: Colors.red, fontSize: fieldFontSize)),
                ],
              ],
            ),
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue[800],
            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: fieldFontSize),
          ),
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: EdgeInsets.symmetric(horizontal: buttonPadding, vertical: 0),
            minimumSize: Size(0, buttonHeight),
            textStyle: TextStyle(fontSize: fieldFontSize, fontWeight: FontWeight.bold),
          ),
          onPressed: isLoading
              ? null
              : () {
                  if (_formKey.currentState!.validate()) {
                    addUser();
                  }
                },
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('Add'),
        ),
      ],
    );
  }
}

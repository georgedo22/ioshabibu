import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MachineDetailPageMechanical extends StatefulWidget {
  final Map<String, dynamic> machine;

  MachineDetailPageMechanical({required this.machine});

  @override
  _MachineDetailPageMechanicalState createState() =>
      _MachineDetailPageMechanicalState();
}

class _MachineDetailPageMechanicalState
    extends State<MachineDetailPageMechanical>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _maintenanceFuture;

  void _showAddMaintenanceDialog() {
    final _formKey = GlobalKey<FormState>();
    String maintenanceType = '';
    String description = '';
    String parts = '';
    String statusBefore = '';
    String statusAfter = '';
    double oilEngQuantity = 0;
    double azolaQuantity = 0;
    String note = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add New Maintenance',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  // Form
                  Flexible(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Maintenance Type',
                              isRequired: true,
                              onSaved: (value) => maintenanceType = value ?? '',
                              icon: Icons.build,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Description',
                              maxLines: 3,
                              onSaved: (value) => description = value ?? '',
                              icon: Icons.description,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Parts Replacement',
                              onSaved: (value) => parts = value ?? '',
                              icon: Icons.settings_backup_restore,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Status Before',
                                    onSaved: (value) =>
                                        statusBefore = value ?? '',
                                    icon: Icons.hourglass_empty,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Status After',
                                    onSaved: (value) =>
                                        statusAfter = value ?? '',
                                    icon: Icons.hourglass_full,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Engine Oil',
                                    keyboardType: TextInputType.number,
                                    onSaved: (value) => oilEngQuantity =
                                        double.tryParse(value ?? '0') ?? 0,
                                    icon: Icons.oil_barrel,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Azola Oil',
                                    keyboardType: TextInputType.number,
                                    onSaved: (value) => azolaQuantity =
                                        double.tryParse(value ?? '0') ?? 0,
                                    icon: Icons.opacity,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Note',
                              maxLines: 3,
                              onSaved: (value) => note = value ?? '',
                              icon: Icons.note,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            _formKey.currentState?.save();
                            try {
                              final currentContext = context;
                              await _submitMaintenance(
                                maintenanceType,
                                description,
                                parts,
                                statusBefore,
                                statusAfter,
                                oilEngQuantity,
                                azolaQuantity,
                                note,
                              );
                              if (!mounted) return;
                              Navigator.of(currentContext).pop();
                              setState(() {
                                _maintenanceFuture = fetchMaintenanceSchedule(
                                    widget.machine['vehicle_id'].toString());
                              });
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required Function(String?) onSaved,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    IconData? icon,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: isRequired
          ? (value) => value?.isEmpty ?? true ? 'This field is required' : null
          : null,
      onSaved: onSaved,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Future<void> _submitMaintenance(
    String maintenanceType,
    String description,
    String parts,
    String statusBefore,
    String statusAfter,
    double oilEngQuantity,
    double azolaQuantity,
    String note,
  ) async {
    final url = Uri.parse(
        'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/add_maintenance.php');

    // Get current date in yyyy-MM-dd format
    final String currentDate = DateTime.now().toIso8601String().split('T')[0];

    final response = await http.post(
      url,
      body: {
        'vehicle_id': widget.machine['vehicle_id'].toString(),
        'm_date': currentDate, // Added maintenance date
        'maintenance_type': maintenanceType,
        'maintenance_description': description,
        'parts_replacement': parts,
        'status_before_maintenance': statusBefore,
        'status_after_maintenance': statusAfter,
        'oil_eng_quantity': oilEngQuantity.toString(),
        'azola_oil_quantity': azolaQuantity.toString(),
        'note': note,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      print("response.statusCode : ${response.statusCode}");
      throw Exception('Failed to add maintenance');
    }

    final result = json.decode(response.body);
    if (!result['success']) {
      throw Exception(result['message']);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _maintenanceFuture =
        fetchMaintenanceSchedule(widget.machine['vehicle_id'].toString());
  }

  Future<List<Map<String, dynamic>>> fetchMaintenanceSchedule(
      String vehicleId) async {
    final url = Uri.parse(
        'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_maintenance_schedule.php');
    final response = await http.post(url, body: {'vehicle_id': vehicleId});

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['success'] == true) {
        return List<Map<String, dynamic>>.from(jsonData['data']);
      } else {
        throw Exception('Server error: ${jsonData['message']}');
      }
    } else {
      throw Exception('Failed to load maintenance schedule');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildMaintenanceTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _maintenanceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));

        final data = snapshot.data!;
        if (data.isEmpty)
          return Center(child: Text('No maintenance records found.'));

        return ListView.builder(
          padding: EdgeInsets.all(12),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            return Card(
              elevation: 2,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text('${item['maintenance_type']} - ${item['m_date']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Description: ${item['maintenance_description'] ?? '---'}'),
                    Text('Parts: ${item['parts_replacement'] ?? '---'}'),
                    Text(
                        'Before: ${item['status_before_maintenance'] ?? '---'}'),
                    Text('After: ${item['status_after_maintenance'] ?? '---'}'),
                    Text(
                        'Engine Oil: ${item['oil_eng_quantity']} | Azola: ${item['azola_oil_quantity']}'),
                    if (item['note'] != null &&
                        item['note'].toString().trim().isNotEmpty)
                      Text('Note: ${item['note']}',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.machine['vehicle_number'] ?? 'Machine Details'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Maintenance schedule'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMaintenanceTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () {
                _showAddMaintenanceDialog();
              },
              child: Icon(Icons.add),
              tooltip: 'Add New Maintenance',
            )
          : null,
    );
  }
}

Future<List<Map<String, dynamic>>> fetchMaintenanceSchedule(
    String vehicleId) async {
  final url = Uri.parse(
      'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_maintenance_schedule.php');

  final response = await http.post(
    url,
    body: {'vehicle_id': vehicleId},
  );

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    if (jsonData['success'] == true) {
      List<dynamic> rawData = jsonData['data'];
      return rawData.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Server error: ${jsonData['message']}');
    }
  } else {
    throw Exception('Failed to load maintenance schedule');
  }
}

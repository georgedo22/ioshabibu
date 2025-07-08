/*
import 'package:flutter/material.dart';
import 'package:habibuv2/Project.dart';

class ProjectDetailsPage extends StatelessWidget {
  final Project project;

  const ProjectDetailsPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(project.name)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🏗️ معلومات أساسية
            _buildSectionTitle("Basic information"),
            _buildDetailRow("Project Name", project.name),
            _buildDetailRow("CreatedAt", project.createdAt),
            _buildDetailRow("CreatedBy", project.createdBy),

            SizedBox(height: 16),

            // 👷‍♀️ الفريق
            _buildSectionTitle("Work Team"),
            _buildDetailRow("Number of engineers", project.engineers.length.toString()),
            ...project.engineers.map((e) => _buildBulletItem(e)),

            SizedBox(height: 16),

            // 📈 التقدم (تجريبي بنسبة ثابتة)
            _buildSectionTitle("Project progress"),
            Text("Progress rate: 60%"),
            SizedBox(height: 6),
            LinearProgressIndicator(value: 0.6),

            SizedBox(height: 16),

            // ✅ المهام (تجريبية)
            _buildSectionTitle("Tasks"),
            _buildTaskItem("Drilling", "In progress"),
            _buildTaskItem("foundations", "Done"),
            _buildTaskItem("Finishing", "Not started"),

            SizedBox(height: 16),

            // 💰 الميزانية
            _buildSectionTitle("Budget and costs"),
            _buildDetailRow("Approved budget", "\$1,000,000"),
            _buildDetailRow("Expenses", "\$600,000"),
            _buildDetailRow("The percentage used", "60%"),

            SizedBox(height: 16),

            // 🖼️ مرفقات (نماذج صور)
            _buildSectionTitle("Attachments"),
            Row(
              children: [
                Expanded(child:Image.asset("assets/before.jpg")),
                SizedBox(width: 8),
                Expanded(child: Image.asset("assets/after.jpg")),
              ],
            ),

            SizedBox(height: 16),

            // 🚧 المشاكل والمخاطر
            _buildSectionTitle("Current problems"),
            _buildBulletItem("Delay in the supply of building materials"),
            _buildBulletItem("Electrical wiring problem"),

            SizedBox(height: 16),

            // 📝 تقارير
            _buildSectionTitle("Reports"),
            _buildBulletItem("April 2025 Report"),
            _buildBulletItem("Quality and Safety Report"),

            SizedBox(height: 16),

            // 🗺️ الموقع والخرائط
            _buildSectionTitle("the site"),
            _buildBulletItem("PDF diagram link"),
            _buildBulletItem("Project location on the map"),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text("$label:", style: TextStyle(fontWeight: FontWeight.w600))),
          Expanded(flex: 5, child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, top: 4),
      child: Row(
        children: [
          Text("• ", style: TextStyle(fontSize: 18)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String taskName, String status) {
    Color color;
    switch (status) {
      case "Done":
        color = Colors.green;
        break;
      case "In progress":
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: color, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text(taskName)),
          Text(status, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:habibuios/Project.dart';

// First, add these imports at the top of the file
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProjectDetailsPage extends StatelessWidget {
  final Project project;

  const ProjectDetailsPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                project.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black45,
                      offset: Offset(2.0, 2.0),
                    )
                  ],
                ),
              ),
              background: Image.asset(
                'assets/background.jpg', // Replace with actual project image
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.5),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Basic Information Section
                _buildSectionCard(
                  title: "Basic Information",
                  icon: Icons.info_outline,
                  content: Column(
                    children: [
                      _buildDetailRow("Project Name", project.name),
                      _buildDetailRow("Created At", project.createdAt),
                      _buildDetailRow("Created By", project.createdBy),
                    ],
                  ),
                ),
                MaterialQuantitiesSection(project: project),
                MachinesSection(project: project),
                // Team Section
                _buildSectionCard(
                  title: "Work Team",
                  icon: Icons.group,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Number of Engineers: ${project.engineers.length}",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      ...project.engineers.map((e) => _buildBulletItem(e)),
                    ],
                  ),
                ),

                // Progress Section
                _buildSectionCard(
                  title: "Project Progress",
                  icon: Icons.trending_up,
                  content: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Progress Rate",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("60%", style: TextStyle(color: Colors.green)),
                        ],
                      ),
                      SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: 0.6,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ],
                  ),
                ),

                // Tasks Section
                _buildSectionCard(
                  title: "Tasks",
                  icon: Icons.checklist,
                  content: Column(
                    children: [
                      _buildTaskItem("Drilling", "In Progress", Colors.orange),
                      _buildTaskItem("Foundations", "Done", Colors.green),
                      _buildTaskItem("Finishing", "Not Started", Colors.grey),
                    ],
                  ),
                ),

                // Budget Section
                _buildSectionCard(
                  title: "Budget and Costs",
                  icon: Icons.attach_money,
                  content: Column(
                    children: [
                      _buildDetailRow("Approved Budget", "\$1,000,000"),
                      _buildDetailRow("Expenses", "\$600,000"),
                      _buildDetailRow("Percentage Used", "60%"),
                    ],
                  ),
                ),

                // Problems Section
                _buildSectionCard(
                  title: "Current Problems",
                  icon: Icons.warning_amber_rounded,
                  content: Column(
                    children: [
                      _buildBulletItem(
                          "Delay in the supply of building materials"),
                      _buildBulletItem("Electrical wiring problem"),
                    ],
                  ),
                ),

                // Attachments Section
                _buildSectionCard(
                  title: "Attachments",
                  icon: Icons.attachment,
                  content: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset("assets/before.jpg"),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset("assets/after.jpg"),
                        ),
                      ),
                    ],
                  ),
                ),

                // Construct Section
                _buildSectionCard(
                  title: "Construct",
                  icon: Icons.attachment,
                  content: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset("assets/before.jpg"),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset("assets/after.jpg"),
                        ),
                      ),
                    ],
                  ),
                ),

                // Reports Section
                /* _buildSectionCard(
                  title: "Reports",
                  icon: Icons.description,
                  content: Column(
                    children: [
                      _buildBulletItem("April 2025 Report"),
                      _buildBulletItem("Quality and Safety Report"),
                    ],
                  ),
                ), */

                // Location Section
                /*   _buildSectionCard(
                  title: "Project Location",
                  icon: Icons.location_on,
                  content: Column(
                    children: [
                      _buildBulletItem("PDF diagram link"),
                      _buildBulletItem("Project location on the map"),
                    ],
                  ),
                ), */
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialRow(String materialName, String unit, int quantity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            materialName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Text(
            "$quantity $unit",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue, size: 24),
                SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            Divider(height: 20, color: Colors.grey[300]),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$label:",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: TextStyle(
              fontSize: 18,
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String taskName, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: color,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(child: Text(taskName)),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Materials and Quantities Section
}

// Add this class after MaterialItem class
class MachineItem {
  String machineName;
  String driverName;
  String status;

  MachineItem({
    required this.machineName,
    required this.driverName,
    required this.status,
  });

  factory MachineItem.fromJson(Map<String, dynamic> json) {
    return MachineItem(
      machineName: json['machineName'],
      driverName: json['driverName'],
      status: json['status'],
    );
  }
}

// Add new StatefulWidget for Machines Section
class MachinesSection extends StatefulWidget {
  final Project project;

  const MachinesSection({Key? key, required this.project}) : super(key: key);

  @override
  State<MachinesSection> createState() => _MachinesSectionState();
}

class _MachinesSectionState extends State<MachinesSection> {
  List<MachineItem> machines = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchMachines(widget.project.name);
  }

  Future<void> fetchMachines(String pn) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://popshop1994.github.io/host_api/machins_projects.json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Fetched Data: $data');

        if (data['projects'] != null) {
          final projectData = (data['projects'] as List).firstWhere(
            (project) => project['projectName'] == pn,
            orElse: () => {'machines': []},
          );

          print('Selected Project Data: $projectData');

          if (projectData['machines'] != null) {
            final machinesList = (projectData['machines'] as List)
                .map((item) => MachineItem.fromJson(item))
                .toList();

            setState(() {
              machines = machinesList;
              isLoading = false;
            });
          } else {
            setState(() {
              machines = [];
              isLoading = false;
            });
          }
        } else {
          setState(() {
            error = 'No projects data found';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Failed to load machines: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error details: $e');
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildSectionCard(
        title: "Project Machines",
        icon: Icons.engineering,
        content: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return _buildSectionCard(
        title: "Project Machines",
        icon: Icons.engineering,
        content: Center(child: Text(error!)),
      );
    }

    return _buildSectionCard(
      title: "Project Machines",
      icon: Icons.engineering,
      content: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: constraints.maxWidth > 600 ? 24.0 : 16.0,
                horizontalMargin: constraints.maxWidth > 600 ? 24.0 : 12.0,
                columns: [
                  DataColumn(
                    label: Container(
                      width: constraints.maxWidth * 0.3,
                      child: Text(
                        'Machine Name',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: constraints.maxWidth > 600 ? 16.0 : 14.0,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      width: constraints.maxWidth * 0.3,
                      child: Text(
                        'Driver Name',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: constraints.maxWidth > 600 ? 16.0 : 14.0,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      width: constraints.maxWidth * 0.3,
                      child: Text(
                        'Status',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: constraints.maxWidth > 600 ? 16.0 : 14.0,
                        ),
                      ),
                    ),
                  ),
                ],
                rows: machines.map((machine) {
                  Color statusColor;
                  IconData statusIcon;

                  switch (machine.status.toLowerCase()) {
                    case 'working':
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                      break;
                    case 'maintenance':
                      statusColor = Colors.orange;
                      statusIcon = Icons.build;
                      break;
                    case 'not working':
                      statusColor = Colors.red;
                      statusIcon = Icons.cancel;
                      break;
                    default:
                      statusColor = Colors.grey;
                      statusIcon = Icons.help_outline;
                  }

                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          width: constraints.maxWidth * 0.3,
                          alignment: Alignment.center,
                          child: Text(
                            machine.machineName,
                            style: TextStyle(
                              fontSize:
                                  constraints.maxWidth > 600 ? 14.0 : 12.0,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: constraints.maxWidth * 0.3,
                          alignment: Alignment.center,
                          child: Text(
                            machine.driverName,
                            style: TextStyle(
                              fontSize:
                                  constraints.maxWidth > 600 ? 14.0 : 12.0,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: constraints.maxWidth * 0.3,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(statusIcon, color: statusColor, size: 20),
                              SizedBox(width: 8),
                              Text(
                                machine.status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize:
                                      constraints.maxWidth > 600 ? 14.0 : 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue, size: 24),
                SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            Divider(height: 20, color: Colors.grey[300]),
            content,
          ],
        ),
      ),
    );
  }
}

// Update the MaterialItem class to match the JSON structure
class MaterialItem {
  String materialName;
  int requiredQuantity;
  int receivedQuantity;
  String unit;

  MaterialItem({
    required this.materialName,
    required this.requiredQuantity,
    required this.receivedQuantity,
    required this.unit,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      materialName: json['materialName'],
      requiredQuantity: json['requiredQuantity'],
      receivedQuantity: json['receivedQuantity'],
      unit: json['unit'],
    );
  }
}

// Update MaterialQuantitiesSection to be stateful
class MaterialQuantitiesSection extends StatefulWidget {
  final Project project;

  const MaterialQuantitiesSection({Key? key, required this.project})
      : super(key: key);

  @override
  State<MaterialQuantitiesSection> createState() =>
      _MaterialQuantitiesSectionState();
}

class _MaterialQuantitiesSectionState extends State<MaterialQuantitiesSection> {
  List<MaterialItem> materials = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchMaterials();
  }

  Future<void> fetchMaterials() async {
    try {
      final response = await http.get(
        Uri.parse('https://popshop1994.github.io/host_api/materials.json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final materialsList = (data['materials'] as List)
            .map((item) => MaterialItem.fromJson(item))
            .toList();

        setState(() {
          materials = materialsList;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load materials';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildSectionCard(
        title: "Materials and quantities",
        icon: Icons.construction,
        content: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return _buildSectionCard(
        title: "Materials and quantities",
        icon: Icons.construction,
        content: Center(child: Text(error!)),
      );
    }

    return _buildSectionCard(
      title: "Materials and quantities",
      icon: Icons.construction,
      content: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: constraints.maxWidth > 600 ? 24.0 : 16.0,
                horizontalMargin: constraints.maxWidth > 600 ? 24.0 : 12.0,
                columns: [
                  DataColumn(
                    label: Container(
                      width: constraints.maxWidth * 0.25,
                      child: Text(
                        'Material Name',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: constraints.maxWidth > 600 ? 16.0 : 14.0,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      width: constraints.maxWidth * 0.25,
                      child: Text(
                        'Required Quantity',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: constraints.maxWidth > 600 ? 16.0 : 14.0,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      width: constraints.maxWidth * 0.25,
                      child: Text(
                        'Received Quantity',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: constraints.maxWidth > 600 ? 16.0 : 14.0,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      width: constraints.maxWidth * 0.25,
                      child: Text(
                        'Status',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: constraints.maxWidth > 600 ? 16.0 : 14.0,
                        ),
                      ),
                    ),
                  ),
                ],
                rows: materials.map((material) {
                  double completionRate =
                      material.receivedQuantity / material.requiredQuantity;
                  IconData statusIcon;
                  Color statusColor;

                  if (completionRate >= 1.1) {
                    statusColor = Colors.purple;
                    statusIcon = Icons.warning_amber_rounded;
                  } else if (completionRate >= 1.0) {
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle;
                  } else if (completionRate >= 0.8) {
                    statusColor = Colors.orange;
                    statusIcon = Icons.error_outline;
                  } else {
                    statusColor = Colors.red;
                    statusIcon = Icons.cancel;
                  }

                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          width: constraints.maxWidth * 0.25,
                          child: Text(
                            material.materialName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize:
                                  constraints.maxWidth > 600 ? 14.0 : 12.0,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: constraints.maxWidth * 0.25,
                          alignment: Alignment.center,
                          child: Text(
                            '${material.requiredQuantity} ${material.unit}',
                            style: TextStyle(
                              fontSize:
                                  constraints.maxWidth > 600 ? 14.0 : 12.0,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: constraints.maxWidth * 0.25,
                          alignment: Alignment.center,
                          child: Text(
                            '${material.receivedQuantity} ${material.unit}',
                            style: TextStyle(
                              fontSize:
                                  constraints.maxWidth > 600 ? 14.0 : 12.0,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: constraints.maxWidth * 0.25,
                          alignment: Alignment.center,
                          child: Icon(
                            statusIcon,
                            color: statusColor,
                            size: constraints.maxWidth > 600 ? 24.0 : 20.0,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  // دالة بناء القسم (من الكود الأصلي)
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue, size: 24),
                SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            Divider(height: 20, color: Colors.grey[300]),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialRow(MaterialItem material) {
    // حساب نسبة الكمية المستلمة
    double completionRate =
        material.receivedQuantity / material.requiredQuantity;

    // تحديد اللون والأيقونة بناءً على نسبة الاستلام
    Color statusColor;
    IconData statusIcon;

    if (completionRate >= 1.1) {
      // الكمية أكبر من المطلوب بنسبة 10٪
      statusColor = Colors.purple;
      statusIcon = Icons.warning_amber_rounded;
    } else if (completionRate >= 1.0) {
      // الكمية مكتملة بالضبط
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (completionRate >= 0.8) {
      // الكمية قريبة من المطلوب (80٪ أو أكثر)
      statusColor = Colors.orange;
      statusIcon = Icons.error_outline;
    } else {
      // الكمية منخفضة
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // اسم المادة
          Expanded(
            flex: 3,
            child: Text(
              material.materialName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),

          // الكمية المطلوبة
          Expanded(
            flex: 2,
            child: Text(
              "${material.requiredQuantity} ${material.unit}",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // الكمية المستلمة
          Expanded(
            flex: 2,
            child: Text(
              "${material.receivedQuantity} ${material.unit}",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // مؤشر الحالة
          Icon(
            statusIcon,
            color: statusColor,
            size: 28,
          ),
        ],
      ),
    );
  }
}

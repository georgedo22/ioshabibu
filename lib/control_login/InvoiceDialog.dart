import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class InvoiceDialog extends StatefulWidget {
  final Function? onInvoiceAdded;
  final int user_id;

  const InvoiceDialog({Key? key, this.onInvoiceAdded, required this.user_id})
      : super(key: key);

  @override
  _InvoiceDialogState createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<InvoiceDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController invNumController = TextEditingController();
  final TextEditingController invTitleController = TextEditingController();
  final TextEditingController fromSenderController = TextEditingController();
  final TextEditingController billToController = TextEditingController();
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();
  final TextEditingController totalPriceController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  String status = "Pending";
  String? selectedProject;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  List<String> projectsName = [];
  List<Map<String, dynamic>> mockProjects = [];

  final Color primaryColor = Colors.indigo;
  final Color accentColor = Colors.indigoAccent;

  @override
  void initState() {
    super.initState();
    fetchProjects(widget.user_id);
    quantityController.addListener(_calculateTotal);
    unitPriceController.addListener(_calculateTotal);

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    quantityController.removeListener(_calculateTotal);
    unitPriceController.removeListener(_calculateTotal);

    quantityController.dispose();
    unitPriceController.dispose();
    totalPriceController.dispose();
    invNumController.dispose();
    invTitleController.dispose();
    fromSenderController.dispose();
    billToController.dispose();
    itemNameController.dispose();
    notesController.dispose();

    _animationController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    if (quantityController.text.isNotEmpty &&
        unitPriceController.text.isNotEmpty) {
      try {
        final quantity = double.parse(quantityController.text);
        final unitPrice = double.parse(unitPriceController.text);
        totalPriceController.text = (quantity * unitPrice).toStringAsFixed(2);
      } catch (e) {
        totalPriceController.text = '';
      }
    } else {
      totalPriceController.text = '';
    }
  }

  Future<void> fetchProjects(int createdBy) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/fetchProjects.php?t=${DateTime.now().millisecondsSinceEpoch}'),
        body: {'created_by': createdBy.toString()},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          projectsName = List<String>.from(
              data.map((project) => project['project_name']));
          mockProjects = data.map<Map<String, dynamic>>((project) => {
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
              }).toList();
          selectedProject = "Private Invoice";
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching projects: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to load projects"),
        backgroundColor: Colors.red,
      ));
    }
  }

  String? getSelectedProjectId() {
    if (selectedProject == "Private Invoice") return null;
    final project = mockProjects.firstWhere(
      (p) => p['name'] == selectedProject,
      orElse: () => {},
    );
    return project['project_id']?.toString();
  }

  Future<void> submitInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse(
        "https://antiquewhite-cobra-422929.hostingersite.com/georgecode/add_invoice_using_created_by.php");

    final invoiceData = {
      "inv_num": invNumController.text,
      "inv_title": invTitleController.text,
      "inv_date": DateFormat('yyyy-MM-dd').format(selectedDate),
      "status": status,
      "project_id": getSelectedProjectId(),
      "created_by": widget.user_id.toString(),
      "details": [
        {
          "from_sender": fromSenderController.text,
          "bill_to": billToController.text,
          "item_name": itemNameController.text,
          "quantity": int.tryParse(quantityController.text) ?? 0,
          "unit_price": double.tryParse(unitPriceController.text) ?? 0,
          "total_price": double.tryParse(totalPriceController.text) ?? 0,
          "notes": notesController.text,
        }
      ]
    };

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(child: CircularProgressIndicator()),
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(invoiceData),
      );

      Navigator.pop(context); // Hide loading

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          if (widget.onInvoiceAdded != null) widget.onInvoiceAdded!();
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Text("Invoice created successfully")
            ]),
            backgroundColor: Colors.green,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error: ${data['error']}"),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Server error: ${response.statusCode}"),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Unexpected error occurred"),
        backgroundColor: Colors.red,
      ));
    }
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: accentColor, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  String? requiredValidator(String? value) {
    if (value == null || value.isEmpty) return 'This field is required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 80,
          vertical: isSmallScreen ? 24 : 80,
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      "Create New Invoice",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Invoice Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16),

                        // Project Selection
                        DropdownButtonFormField<String>(
                          value: selectedProject ?? "Private Invoice",
                          items: [
                            DropdownMenuItem<String>(
                              value: "Private Invoice",
                              child: Text("Private Invoice"),
                            ),
                            ...projectsName.map<DropdownMenuItem<String>>(
                              (name) => DropdownMenuItem<String>(
                                value: name,
                                child: Text(name),
                              ),
                            ).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedProject = value;
                              print("selectedProject ${selectedProject}");
                            });
                          },
                          decoration: inputDecoration("Select Project", Icons.business_center),
                          validator: (value) {
                            if (value == null) return "Please select a project";
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Invoice Number & Title
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: isSmallScreen ? double.infinity : screenSize.width * 0.3,
                              child: TextFormField(
                                controller: invNumController,
                                decoration: inputDecoration("Invoice Number", Icons.tag),
                                validator: requiredValidator,
                              ),
                            ),
                            SizedBox(
                              width: isSmallScreen ? double.infinity : screenSize.width * 0.3,
                              child: TextFormField(
                                controller: invTitleController,
                                decoration: inputDecoration("Invoice Title", Icons.title),
                                validator: requiredValidator,
                              ),
                            ),
                          ],
                        ),

                          SizedBox(height: 16),
                        // Date & Status
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: isSmallScreen ? double.infinity : screenSize.width * 0.3,
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() => selectedDate = picked);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: inputDecoration("Invoice Date", Icons.calendar_today),
                                  child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: isSmallScreen ? double.infinity : screenSize.width * 0.3,
                              child: DropdownButtonFormField<String>(
                                value: status,
                                onChanged: (val) => setState(() => status = val!),
                                items: ["Pending", "Paid", "Late"]
                                    .map((s) => DropdownMenuItem(child: Text(s), value: s))
                                    .toList(),
                                decoration: inputDecoration("Status", Icons.pending_actions),
                                validator: requiredValidator,
                              ),
                            ),
                          ],
                        ),

                        Divider(),

                        // Details Section
                        Text("Invoice Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16),

                        // From / To
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: isSmallScreen ? double.infinity : screenSize.width * 0.3,
                              child: TextFormField(
                                controller: fromSenderController,
                                decoration: inputDecoration("From (Supplier)", Icons.business),
                                validator: requiredValidator,
                              ),
                            ),
                            SizedBox(
                              width: isSmallScreen ? double.infinity : screenSize.width * 0.3,
                              child: TextFormField(
                                controller: billToController,
                                decoration: inputDecoration("To (Customer)", Icons.person),
                                validator: requiredValidator,
                              ),
                            ),
                          ],
                        ),
                          SizedBox(height: 16),
                        // Item Name
                        TextFormField(
                          controller: itemNameController,
                          decoration: inputDecoration("Item Name", Icons.inventory),
                          validator: requiredValidator,
                        ),
                        SizedBox(height: 16),

                        // Quantity / Unit Price / Total
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: isSmallScreen ? double.infinity : screenSize.width * 0.2,
                              child: TextFormField(
                                controller: quantityController,
                                keyboardType: TextInputType.number,
                                decoration: inputDecoration("Quantity", Icons.shopping_cart),
                                validator: requiredValidator,
                              ),
                            ),
                            SizedBox(
                              width: isSmallScreen ? double.infinity : screenSize.width * 0.2,
                              child: TextFormField(
                                controller: unitPriceController,
                                keyboardType: TextInputType.number,
                                decoration: inputDecoration("Unit Price", Icons.attach_money),
                                validator: requiredValidator,
                              ),
                            ),
                            SizedBox(
                              width: isSmallScreen ? double.infinity : screenSize.width * 0.2,
                              child: TextFormField(
                                controller: totalPriceController,
                                decoration: InputDecoration(
                                  labelText: "Total",
                                  prefixIcon: Icon(Icons.calculate, color: primaryColor),
                                  suffixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: primaryColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: accentColor, width: 2),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                ),
                                readOnly: true,
                                enabled: false,
                                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // Notes
                        TextFormField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: inputDecoration("Notes", Icons.note),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Actions
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: Icon(Icons.cancel),
                      label: Text("Cancel"),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: Icon(Icons.save),
                      label: Text("Save Invoice"),
                      onPressed: submitInvoice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
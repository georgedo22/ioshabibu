import 'dart:async';
import 'dart:convert';


import 'package:habibuios/control_login/InvoiceDialog.dart';
import 'package:habibuios/machines/InvoiceDetailPage.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Invoice model
class Invoice {
  final String id;
  final String inv_num;
  final String inv_title;
  final DateTime inv_date;
  final DateTime created_at;
  final String status;

  Invoice({
    required this.id,
    required this.inv_num,
    required this.inv_title,
    required this.inv_date,
    required this.created_at,
    required this.status,
  });
}

class InvoicesSection extends StatefulWidget {
  final int user_id;
  const InvoicesSection({Key? key,required this.user_id}) : super(key: key);

  @override
  State<InvoicesSection> createState() => _InvoicesSectionState();
}

class _InvoicesSectionState extends State<InvoicesSection> {
  // State variables
  final TextEditingController searchController = TextEditingController();
  String currentSearchText = '';
  String filter = 'all';
  List<Invoice> allInvoices = [];
  List<Invoice> filteredInvoices = [];
  bool isLoading = true;
  String sortField = 'inv_num';
  bool sortAsc = true;
  
  @override
  void initState() {
    super.initState();
    print("user_id ${widget.user_id}");
    _loadInvoicesInitially();
  }
  
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Load data at the beginning of the display
  Future<void> _loadInvoicesInitially() async {
    try {
      final invoices = await fetchInvoices();
      if (mounted) {
        setState(() {
          allInvoices = invoices;
          filteredInvoices = invoices;
          isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load invoices: ${error.toString()}')),
        );
      }
    }
  }

  Future<List<Invoice>> fetchInvoices() async {
    final response = await http.post(
      Uri.parse('https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_workshop_invoices.php'),
      body: {
        'created_by': widget.user_id.toString(),
      }
    );
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((data) => Invoice(
        id: data['id'].toString(),
        inv_num: data['inv_num'].toString(),
        inv_title: data['inv_title'],
        inv_date: DateTime.parse(data['inv_date']),
        created_at: DateTime.parse(data['created_at']),
        status: data['status'],
      )).toList();
    } else {
      throw Exception('Failed to load invoices');
    }
  }

  // Fetch invoices from the server
  /*Future<List<Invoice>> fetchInvoices() async {
    final response = await http.get(
      Uri.parse('https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_invoices_data.php'),
    );
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((data) => Invoice(
        id: data['id'].toString(),
        inv_num: data['inv_num'].toString(),
        inv_title: data['inv_title'],
        inv_date: DateTime.parse(data['inv_date']),
        created_at: DateTime.parse(data['created_at']),
        status: data['status'],
      )).toList();
    } else {
      throw Exception('Failed to load invoices');
    }
  }*/

  // Apply search and filtering
  void _applyFiltersAndSearch() {
    if (!mounted) return;
    
    final searchQuery = searchController.text.toLowerCase();
    
    setState(() {
      currentSearchText = searchQuery;
      filteredInvoices = allInvoices.where((invoice) {
        final matchesStatus = filter == 'all' || invoice.status == filter;
        final matchesSearch = searchQuery.isEmpty || 
            invoice.inv_title.toLowerCase().contains(searchQuery) ||
            invoice.inv_num.toLowerCase().contains(searchQuery);
        return matchesStatus && matchesSearch;
      }).toList();
      
      _sortInvoices();
    });
  }

  // Sort the list
  void _sortInvoices() {
    filteredInvoices.sort((a, b) {
      dynamic aField, bField;
      switch (sortField) {
        case 'inv_num':
          aField = a.inv_num;
          bField = b.inv_num;
          break;
        case 'inv_title':
          aField = a.inv_title;
          bField = b.inv_title;
          break;
        case 'inv_date':
          aField = a.inv_date;
          bField = b.inv_date;
          break;
        case 'created_at':
          aField = a.created_at;
          bField = b.created_at;
          break;
        default:
          return 0;
      }
      if (aField is Comparable && bField is Comparable) {
        return sortAsc ? aField.compareTo(bField) : bField.compareTo(aField);
      }
      return 0;
    });
  }

  // Column index for sorting
  int _columnIndex(String field) {
    switch (field) {
      case 'inv_num': return 0;
      case 'inv_title': return 1;
      case 'inv_date': return 2;
      case 'created_at': return 3;
      default: return -1;
    }
  }

  // Build a sortable column
  DataColumn _buildColumn(String label, String field) {
    return DataColumn(
      label: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      onSort: (_, __) {
        setState(() {
          if (sortField == field) {
            sortAsc = !sortAsc;
          } else {
            sortField = field;
            sortAsc = true;
          }
          _sortInvoices();
        });
      },
    );
  }

  // Status badge
  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'Paid': color = Colors.green; break;
      case 'Pending': color = Colors.orange; break;
      case 'Late': color = Colors.red; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Show search dialog
  void _showSearchDialog() {
    // Create a temporary controller for text in the dialog
    final TextEditingController dialogController = TextEditingController(text: searchController.text);
    
    // List to store filtered search results
    List<Invoice> dialogFilteredInvoices = [];
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          // Update search results in the dialog
          dialogFilteredInvoices = allInvoices
              .where((invoice) => 
                  invoice.inv_title.toLowerCase().contains(dialogController.text.toLowerCase()) ||
                  invoice.inv_num.toLowerCase().contains(dialogController.text.toLowerCase()))
              .take(5)
              .toList();
          
          return AlertDialog(
            title: Text('Search for an invoice'),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: dialogController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Enter invoice or customer number...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      // Update dialog state only
                      setDialogState(() {
                        // dialogFilteredInvoices will be updated at the beginning of dialog building
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Display live search results in the dialog
                  if (dialogController.text.isNotEmpty)
                    Flexible(
                      child: Container(
                        height: 200,
                        child: dialogFilteredInvoices.isEmpty
                            ? Center(child: Text('No results found'))
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: dialogFilteredInvoices.length,
                                itemBuilder: (context, index) {
                                  final invoice = dialogFilteredInvoices[index];
                                  return ListTile(
                                    title: Text(invoice.inv_title),
                                    subtitle: Text('Invoice number: ${invoice.inv_num}'),
                                    trailing: _statusBadge(invoice.status),
                                    onTap: () {
                                      // Close the dialog first
                                      Navigator.of(dialogContext).pop();
                                      
                                      // Slight delay before navigation
                                      Future.delayed(Duration(milliseconds: 100), () {
                                        try {
                                          print("Go to the invoice details page: ${invoice.inv_num}");
                                          
                                          // Navigate to details page
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => InvoiceDetailPage(invoice.inv_num),
                                            ),
                                          );
                                        } catch (e) {
                                          print("Transition error: $e");
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
                  // Copy text from temporary controller to main controller
                  searchController.text = dialogController.text;
                  Navigator.of(dialogContext).pop();
                  
                  // Apply search to the main screen
                  _applyFiltersAndSearch();
                },
                child: Text('Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Show edit invoice dialog
  void _showEditInvoiceDialog(Invoice invoice) {
    final TextEditingController titleController = TextEditingController(text: invoice.inv_title);
    String selectedStatus = invoice.status;
    DateTime selectedDate = invoice.inv_date;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Edit Invoice'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Invoice Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 16),SizedBox(height: 16),
              // إضافة حقل التاريخ
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null && picked != selectedDate) {
                    selectedDate = picked;
                    print("selectedDate: ${DateFormat('yyyy-MM-dd').format(selectedDate)}");
                    // إعادة بناء الحوار لتحديث التاريخ المعروض
                    Navigator.of(dialogContext).pop();
                    _showEditInvoiceDialog(Invoice(
                      id: invoice.id,
                      inv_num: invoice.inv_num,
                      inv_title: titleController.text,
                      inv_date: selectedDate,
                      created_at: invoice.created_at,
                      status: selectedStatus,
                    ));
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Invoice Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'Late', child: Text('Late')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    selectedStatus = value;
                  }
                },
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
              _updateInvoice(
                invoice.inv_num,
                titleController.text,
                selectedStatus,
                dialogContext,
                selectedDate,
              );
            },
            child: Text('Update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Update invoice in the database
   Future<void> _updateInvoice(
    String invNum,
    String title,
    String status,
    BuildContext dialogContext,
    DateTime invDate,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://antiquewhite-cobra-422929.hostingersite.com/georgecode/update_invoice.php'),
        body: {
          'inv_num': invNum,
          'inv_title': title,
          'status': status,
          'inv_date': DateFormat('yyyy-MM-dd').format(invDate)  // تم تغيير 'inv-date' إلى 'inv_date'
        },
      );
        print("inv_date ${ DateFormat('yyyy-MM-dd').format(invDate)}");
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          Navigator.of(dialogContext).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invoice updated successfully')),
          );
          // Reload invoices to reflect changes
          _loadInvoicesInitially();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update invoice: ${result['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmation(Invoice invoice) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Delete Invoice'),
        content: Text('Are you sure you want to delete invoice ${invoice.inv_num}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteInvoice(invoice.id, dialogContext);
            },
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Delete invoice from the database
  Future<void> _deleteInvoice(String id, BuildContext dialogContext) async {
    try {
      final response = await http.post(
        Uri.parse('https://antiquewhite-cobra-422929.hostingersite.com/georgecode/delete_invoice.php'),
        body: {
          'id': id,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          Navigator.of(dialogContext).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invoice deleted successfully')),
          );
          // Reload invoices to reflect changes
          _loadInvoicesInitially();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete invoice: ${result['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

   void _showErrorSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    // Check if screen is small
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoices'),
        actions: [
          // Search button in AppBar
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Search Invoices',
          ),

          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => InvoiceDialog(
                  user_id: widget.user_id,
                  onInvoiceAdded: () {
                    // إعادة تحميل الفواتير بعد الإضافة
                    _loadInvoicesInitially();
                  },
                ),
              );
            },
            tooltip: 'Add New Invoice',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display current search criteria
            if (currentSearchText.isNotEmpty || filter != 'all')
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (currentSearchText.isNotEmpty)
                      Chip(
                        label: Text('Search: $currentSearchText'),
                        deleteIcon: Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            searchController.text = '';
                            currentSearchText = '';
                            _applyFiltersAndSearch();
                          });
                        },
                      ),
                    if (filter != 'all')
                      Chip(
                        label: Text('Status: $filter'),
                        deleteIcon: Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            filter = 'all';
                            _applyFiltersAndSearch();
                          });
                        },
                      ),
                  ],
                ),
              ),
              
            // Filter row
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Filter by status: '),
                  SizedBox(width: 8),
                  DropdownButton<String>(
                    value: filter,
                    underline: Container(height: 1, color: Colors.grey.shade400),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          filter = value;
                          _applyFiltersAndSearch();
                        });
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                      DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'Late', child: Text('Late')),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            
            // Data table
          Expanded(
  child: isLoading
      ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 16),
              Text(
                'Loading invoices...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        )
      : filteredInvoices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Invoices Found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your search or filters',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                // Responsive breakpoints
                bool isMobile = constraints.maxWidth < 768;
                bool isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
                
                if (isMobile) {
                  // Mobile: Card-based layout
                  return _buildMobileLayout();
                } else {
                  // Tablet/Desktop: Enhanced table layout
                  return _buildDesktopLayout(isTablet);
                }
              },
            ),
            ),

          ],
        ),
      ),
    );
  }

  // Desktop/Tablet Table Layout
Widget _buildDesktopLayout(bool isTablet) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          spreadRadius: 0,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        // Table Header
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildHeaderText('Invoice Number')),
                if (!isTablet) ...[
                  Expanded(flex: 2, child: _buildHeaderText('Client')),
                  Expanded(flex: 2, child: _buildHeaderText('Release Date')),
                  Expanded(flex: 2, child: _buildHeaderText('Due Date')),
                ] else ...[
                  Expanded(flex: 3, child: _buildHeaderText('Client & Dates')),
                ],
                Expanded(flex: 1, child: _buildHeaderText('Status')),
                Expanded(flex: 1, child: _buildHeaderText('Actions')),
              ],
            ),
          ),
        ),
        
        // Table Body
        Expanded(
          child: ListView.builder(
            itemCount: filteredInvoices.length,
            itemBuilder: (context, index) {
              final invoice = filteredInvoices[index];
              return InkWell(
                onTap: () {
                  try {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InvoiceDetailPage(invoice.inv_num),
                      ),
                    );
                  } catch (e) {
                    _showErrorSnackBar("An error occurred: $e");
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        // Invoice Number
                        Expanded(
                          flex: 2,
                          child: Text(
                            invoice.inv_num,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        
                        if (!isTablet) ...[
                          // Client
                          Expanded(
                            flex: 2,
                            child: Text(
                              invoice.inv_title,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          
                          // Release Date
                          Expanded(
                            flex: 2,
                            child: Text(
                              DateFormat.yMMMd().format(invoice.inv_date),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          
                          // Due Date
                          Expanded(
                            flex: 2,
                            child: Text(
                              DateFormat.yMMMd().format(invoice.created_at),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ] else ...[
                          // Combined Client & Dates for tablet
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  invoice.inv_title,
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${DateFormat.yMMMd().format(invoice.inv_date)} • Due: ${DateFormat.yMMMd().format(invoice.created_at)}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        // Status
                        Expanded(
                          flex: 1,
                          child: _statusBadge(invoice.status),
                        ),
                        
                        // Actions
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _showEditInvoiceDialog(invoice),
                                tooltip: 'Edit Invoice',
                                style: IconButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  backgroundColor: Colors.blue.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _showDeleteConfirmation(invoice),
                                tooltip: 'Delete Invoice',
                                style: IconButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  backgroundColor: Colors.red.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
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
            },
          ),
        ),
      ],
    ),
  );
}


  // Mobile Card Layout
Widget _buildMobileLayout() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          spreadRadius: 0,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: filteredInvoices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final invoice = filteredInvoices[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InvoiceDetailPage(invoice.inv_num),
                  ),
                );
              } catch (e) {
                _showErrorSnackBar("An error occurred: $e");
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with invoice number and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          invoice.inv_num,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _statusBadge(invoice.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Client name
                  Row(
                    children: [
                      Icon(Icons.person_outline, 
                           size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          invoice.inv_title,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, 
                                     size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Released',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat.yMMMd().format(invoice.inv_date),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.schedule_outlined, 
                                     size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Due',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat.yMMMd().format(invoice.created_at),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showEditInvoiceDialog(invoice),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _showDeleteConfirmation(invoice),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
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
  );
}



}






// Helper Methods
Widget _buildHeaderText(String text) {
  return Text(
    text,
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      color: Colors.grey.shade700,
    ),
  );
}


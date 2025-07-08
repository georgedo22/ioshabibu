/*import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class InvoiceDetailPage extends StatefulWidget {
  final String inv_num;
  InvoiceDetailPage(this.inv_num, {super.key});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {

      List<dynamic> _inv_details = [];
    
    initState() {
    super.initState();
    fetchInvDetails(widget.inv_num);
    // Add your initialization code here
  }

        double _calculateSubtotal() {
    if (_inv_details.isEmpty) return 0.0;
    return _inv_details.fold(0.0, (sum, item) {
      return sum + (double.tryParse(item['total_price']?.toString() ?? '0') ?? 0.0);
    });
  }

  /*double _calculateTax() {
    return _calculateSubtotal() * 0.0825; // 8.25% tax rate
  }*/

  double _calculateTotal() {
    return _calculateSubtotal() /*+ _calculateTax()*/;
  }

  Future<List<dynamic>> fetchInvDetails(String id) async {
    final Url='https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_invoices_details_data.php';
    final response = await http.post(Uri.parse(Url),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'inv_num': id,
      },
    );
    if (response.statusCode == 200) {
      print("Invoice Details Data: ${response.body}");
      setState(() {
        _inv_details = json.decode(response.body);
      });
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

Future<void> updateInvStatus(int id) async {
    final Url='https://antiquewhite-cobra-422929.hostingersite.com/georgecode/update_inv_status.php';
    final response = await http.post(Uri.parse(Url),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'id': id.toString(),
      },
    );
    if (response.statusCode == 200) {
      print("Invoice Update Successfull: ${response.body}");
      
    } else {
      throw Exception('Failed to update data');
    }
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
String formatDate(String? dateStr) {
  if (dateStr == null) return 'N/A';
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd/MM/yyyy').format(date);
  } catch (e) {
    return dateStr; // إرجاع النص الأصلي إذا فشل التحويل
  }
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title:  Text(widget.inv_num, style: TextStyle(color: Colors.black)),
        actions: [
          TextButton.icon(
            onPressed: () async {
        print("Type of invoice_id: ${_inv_details[0]['invoice_id'].runtimeType}");

    if (_inv_details.isNotEmpty) {
      try {
        await updateInvStatus(_inv_details[0]['invoice_id']);
        // تحديث البيانات بعد نجاح العملية
        await fetchInvDetails(widget.inv_num);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statu Update Successfull')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status Update Failed')),
                  );
                }
              }
            },
            icon: const Icon(Icons.check_circle, color: Colors.green),
            label: const Text('Mark Paid', style: TextStyle(color: Colors.green)),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async{
             // افتراض أن _invDetails تحتوي على بيانات الفاتورة
               final invoiceId = _inv_details[0]['invoice_id'];
               final invoiceId_id=_inv_details[0]['id'];
                  print('update invoiceId ${invoiceId} ${invoiceId_id}');

                  
                  
              // فتح النافذة المنبثقة لتعديل البيانات
                 await showDialog(
                  context: context,
                 builder: (context) => EditInvoiceDialog(invoiceId: invoiceId, invoiceId_id: invoiceId_id),
                 );
                 // تحديث البيانات بعد إغلاق النافذة المنبثقة
                await fetchInvDetails(widget.inv_num);
                  setState(() {}); // تحديث الواجهة
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Invoice #${widget.inv_num}',
                                style: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                        
                             Text('Issue Date: ${_inv_details.isNotEmpty ? formatDate(_inv_details[0]['inv_date'])  : 'N/A'}'),
                             Text('Created At: ${_inv_details.isNotEmpty ? formatDate(_inv_details[0]['invoice_created_at']) : 'N/A'}'),
                          ],
                        ),
                     _statusBadge(_inv_details.isNotEmpty ? _inv_details[0]['status'] ?? 'Pending' : 'Pending')
                        
                      ],
                    ),
                    const Divider(height: 32),
                    // Address Section
                    Wrap(
                      spacing: 32,
                      runSpacing: 24,
                      children: [
                        SizedBox(
                          width: isSmallScreen ? double.infinity : constraints.maxWidth * 0.4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:  [
                              Text('From', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                            Text(_inv_details.isNotEmpty ? _inv_details[0]['from_sender'] ?? '' : ''),
                             /* Text('123 Business Street'),
                              Text('San Francisco, CA 94103'),
                              Text('United States'),
                              Text('billing@invoicepro.com'), */
                            ],
                          ),
                        ),
                        SizedBox(
                          width: isSmallScreen ? double.infinity : constraints.maxWidth * 0.4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:[
                              Text('Bill To', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                             Text(_inv_details.isNotEmpty ? _inv_details[0]['bill_to'] ?? '' : ''),
                             /* Text('Acme Corporation'),
                              Text('456 Business Avenue, Suite 200'),
                              Text('New York, 10001'),
                              Text('United States'),
                              Text('alex.morgan@acme.com'),
                              Text('(212) 555-1234'), */
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    // Table Section
                    Container(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: const [
                                Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                          const Divider(),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: _inv_details.length,
                            itemBuilder: (context, index) {
                              final item = _inv_details[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(item['item_name'] ?? ''),
                                    ),
                                    Expanded(
                                      child: Text(item['quantity']?.toString() ?? ''),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('\$${item['unit_price']?.toString() ?? '0.00'}'),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('\$${item['total_price']?.toString() ?? '0.00'}'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                                       // Total Section
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: isSmallScreen ? double.infinity : 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                           /* Text(
                              'Subtotal: \$${_calculateSubtotal().toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 16),
                            ), */
                            /*Text(
                              'Tax (8.25%): \$${_calculateTax().toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 16),
                            ),*/
                            SizedBox(height: 8),
                            Text(
                              'Total: \$${_calculateTotal().toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                            ),
                            
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 32),
                    // Notes Section
                      Container(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _inv_details.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(_inv_details[index]['notes'] ?? ''),
                          );
                        },
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
  }
}



class EditInvoiceDialog extends StatefulWidget {
  final int invoiceId;
  final int invoiceId_id;
  const EditInvoiceDialog({required this.invoiceId, required  this.invoiceId_id});

  @override
  _EditInvoiceDialogState createState() => _EditInvoiceDialogState();
}

class _EditInvoiceDialogState extends State<EditInvoiceDialog> {
  late Future<List<dynamic>> _invoiceDataFuture;
  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    _invoiceDataFuture = fetchInvoiceDetails(widget.invoiceId);
  }

   Future<void> updateInvoiceDetails(int invoiceId, int id, Map<String, dynamic> updates) async {
  final url = 'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/update_invoice.php';

  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {
      'id': id.toString(),
      'invoice_id': invoiceId.toString(),
      'from_sender': updates['from_sender'],
      'bill_to': updates['bill_to'],
      'item_name': updates['item_name'],
      'quantity': updates['quantity'].toString(),
      'unit_price': updates['unit_price'].toString(),
      'total_price': updates['total_price'].toString(),
      'notes': updates['notes'].toString(),
    },
  );

  if (response.statusCode == 200) {
    print("Success: ${response.body}");
  } else {
    throw Exception('Failed to update invoice details');
  }
}

  Future<List<dynamic>> fetchInvoiceDetails(int invoiceId) async {
    // API call to get invoice details
    final response = await http.post(
      Uri.parse('https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_invoices_details_data_for_update.php'),
      body:{
        'invoice_id' : invoiceId.toString(),
      }
    );

    if (response.statusCode == 200) {
      print("fetchInvoiceDetails ${response.body}");
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load invoice details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _invoiceDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final invoiceData = snapshot.data!;
          
          // Get screen size for responsive design
          final screenSize = MediaQuery.of(context).size;
          final isSmallScreen = screenSize.width < 600;
          
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Invoice Details ${_currentIndex + 1}/${invoiceData.length}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (invoiceData.length > 1) Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 18),
                      onPressed: _currentIndex > 0
                          ? () => setState(() => _currentIndex--)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 18),
                      onPressed: _currentIndex < invoiceData.length - 1
                          ? () => setState(() => _currentIndex++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            content: Container(
              width: isSmallScreen ? screenSize.width * 0.9 : screenSize.width * 0.5,
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: screenSize.height * 0.7,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'From',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      controller: TextEditingController(text: invoiceData[_currentIndex]['from_sender']),
                      onChanged: (value) => invoiceData[_currentIndex]['from_sender'] = value,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'To',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      controller: TextEditingController(text: invoiceData[_currentIndex]['bill_to']),
                      onChanged: (value) => invoiceData[_currentIndex]['bill_to'] = value,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      controller: TextEditingController(text: invoiceData[_currentIndex]['item_name']),
                      onChanged: (value) => invoiceData[_currentIndex]['item_name'] = value,
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: invoiceData[_currentIndex]['quantity'].toString()),
                            onChanged: (value) => invoiceData[_currentIndex]['quantity'] = int.tryParse(value) ?? 0,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Unit Price',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: invoiceData[_currentIndex]['unit_price'].toString()),
                            onChanged: (value) => invoiceData[_currentIndex]['unit_price'] = double.tryParse(value) ?? 0.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      maxLines: 3,
                      keyboardType: TextInputType.text,
                      controller: TextEditingController(text: invoiceData[_currentIndex]['notes'].toString()),
                      onChanged: (value) => invoiceData[_currentIndex]['notes'] = value,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                child: Text('Cancel'),
              ),
              ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).primaryColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  onPressed: () async {
    try {
      final currentItem = invoiceData[_currentIndex];
      
      // استخدم القيمة الحقيقية لـ id من السجل
      final int id = currentItem['id']; 
      final int invoiceId = widget.invoiceId;
print("currentItem ${id}");
      // احسب total_price
      final double quantity = double.tryParse(currentItem['quantity'].toString()) ?? 0;
      final double unitPrice = double.tryParse(currentItem['unit_price'].toString()) ?? 0;
      final String totalPrice = (quantity * unitPrice).toString();

      // تحديث البيانات على الخادم
      await updateInvoiceDetails(
        invoiceId, // invoice_id
        id, // id (الخاص بكل سطر)
        {
          'from_sender': currentItem['from_sender'],
          'bill_to': currentItem['bill_to'],
          'item_name': currentItem['item_name'],
          'quantity': quantity.toString(),
          'unit_price': unitPrice.toString(),
          'total_price': totalPrice,
          'notes': currentItem['notes'].toString(),
        },
      );

      // تحديث البيانات المحلية مباشرة
      setState(() {
        invoiceData[_currentIndex] = {
          ...currentItem,
          'quantity': quantity,
          'unit_price': unitPrice,
          'total_price': totalPrice,
          'notes': currentItem['notes'],
        };
      });

      // تحديث الصفحة الأم إن وُجدت
      if (context.findAncestorStateOfType<_InvoiceDetailPageState>() != null) {
        final state = context.findAncestorStateOfType<_InvoiceDetailPageState>();
        await state?.fetchInvDetails(currentItem['inv_num']);
      }

      // إغلاق الدايلوج وإظهار رسالة نجاح
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update data: $e')),
      );
    }
  },
  child: Text('Save Changes'),
),
            ],
          );
        }
      },
    );
  }
} */

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class InvoiceDetailPage extends StatefulWidget {
  final String inv_num;
  InvoiceDetailPage(this.inv_num, {super.key});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {

      List<dynamic> _inv_details = [];
    
    initState() {
    super.initState();
    fetchInvDetails(widget.inv_num);
    // Add your initialization code here
  }

        double _calculateSubtotal() {
    if (_inv_details.isEmpty) return 0.0;
    return _inv_details.fold(0.0, (sum, item) {
      return sum + (double.tryParse(item['total_price']?.toString() ?? '0') ?? 0.0);
    });
  }

  /*double _calculateTax() {
    return _calculateSubtotal() * 0.0825; // 8.25% tax rate
  }*/

  double _calculateTotal() {
    return _calculateSubtotal() /*+ _calculateTax()*/;
  }

  Future<List<dynamic>> fetchInvDetails(String id) async {
    final Url='https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_invoices_details_data.php';
    final response = await http.post(Uri.parse(Url),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'inv_num': id,
      },
    );
    if (response.statusCode == 200) {
      print("Invoice Details Data: ${response.body}");
      setState(() {
        _inv_details = json.decode(response.body);
      });
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

Future<void> updateInvStatus(int id) async {
    final Url='https://antiquewhite-cobra-422929.hostingersite.com/georgecode/update_inv_status.php';
    final response = await http.post(Uri.parse(Url),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'id': id.toString(),
      },
    );
    if (response.statusCode == 200) {
      print("Invoice Update Successfull: ${response.body}");
      
    } else {
      throw Exception('Failed to update data');
    }
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
String formatDate(String? dateStr) {
  if (dateStr == null) return 'N/A';
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd/MM/yyyy').format(date);
  } catch (e) {
    return dateStr; // إرجاع النص الأصلي إذا فشل التحويل
  }
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title:  Text(widget.inv_num, style: TextStyle(color: Colors.black)),
        actions: [
          TextButton.icon(
            onPressed: () async {
        print("Type of invoice_id: ${_inv_details[0]['invoice_id'].runtimeType}");

    if (_inv_details.isNotEmpty) {
      try {
        await updateInvStatus(_inv_details[0]['invoice_id']);
        // تحديث البيانات بعد نجاح العملية
        await fetchInvDetails(widget.inv_num);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statu Update Successfull')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status Update Failed')),
                  );
                }
              }
            },
            icon: const Icon(Icons.check_circle, color: Colors.green),
            label: const Text('Mark Paid', style: TextStyle(color: Colors.green)),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async{
             // افتراض أن _invDetails تحتوي على بيانات الفاتورة
               final invoiceId = _inv_details[0]['invoice_id'];
               final invoiceId_id=_inv_details[0]['id'];
                  print('update invoiceId ${invoiceId} ${invoiceId_id}');

                  
                  
              // فتح النافذة المنبثقة لتعديل البيانات
                 await showDialog(
                  context: context,
                 builder: (context) => EditInvoiceDialog(invoiceId: invoiceId, invoiceId_id: invoiceId_id),
                 );
                 // تحديث البيانات بعد إغلاق النافذة المنبثقة
                await fetchInvDetails(widget.inv_num);
                  setState(() {}); // تحديث الواجهة
            },


           
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Invoice #${widget.inv_num}',
                                style: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                        
                             Text('Issue Date: ${_inv_details.isNotEmpty ? formatDate(_inv_details[0]['inv_date'])  : 'N/A'}'),
                             Text('Created At: ${_inv_details.isNotEmpty ? formatDate(_inv_details[0]['invoice_created_at']) : 'N/A'}'),
                          ],
                        ),
                     _statusBadge(_inv_details.isNotEmpty ? _inv_details[0]['status'] ?? 'Pending' : 'Pending')
                        
                      ],
                    ),
                    const Divider(height: 32),
                    // Address Section
                    Wrap(
                      spacing: 32,
                      runSpacing: 24,
                      children: [
                        SizedBox(
                          width: isSmallScreen ? double.infinity : constraints.maxWidth * 0.4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:  [
                              Text('From', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                            Text(_inv_details.isNotEmpty ? _inv_details[0]['from_sender'] ?? '' : ''),
                             /* Text('123 Business Street'),
                              Text('San Francisco, CA 94103'),
                              Text('United States'),
                              Text('billing@invoicepro.com'), */
                            ],
                          ),
                        ),
                        SizedBox(
                          width: isSmallScreen ? double.infinity : constraints.maxWidth * 0.4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:[
                              Text('Bill To', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                             Text(_inv_details.isNotEmpty ? _inv_details[0]['bill_to'] ?? '' : ''),
                             /* Text('Acme Corporation'),
                              Text('456 Business Avenue, Suite 200'),
                              Text('New York, 10001'),
                              Text('United States'),
                              Text('alex.morgan@acme.com'),
                              Text('(212) 555-1234'), */
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    // Table Section
                    Container(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: const [
                                Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                          const Divider(),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: _inv_details.length,
                            itemBuilder: (context, index) {
                              final item = _inv_details[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(item['item_name'] ?? ''),
                                    ),
                                    Expanded(
                                      child: Text(item['quantity']?.toString() ?? ''),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('\$${item['unit_price']?.toString() ?? '0.00'}'),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('\$${item['total_price']?.toString() ?? '0.00'}'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                                       // Total Section
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: isSmallScreen ? double.infinity : 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                           /* Text(
                              'Subtotal: \$${_calculateSubtotal().toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 16),
                            ), */
                            /*Text(
                              'Tax (8.25%): \$${_calculateTax().toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 16),
                            ),*/
                            SizedBox(height: 8),
                            Text(
                              'Total: \$${_calculateTotal().toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                            ),
                            
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 32),
                    // Notes Section
                      Container(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _inv_details.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(_inv_details[index]['notes'] ?? ''),
                          );
                        },
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
  }
}



class EditInvoiceDialog extends StatefulWidget {
  final int invoiceId;
  final int invoiceId_id;
  const EditInvoiceDialog({required this.invoiceId, required  this.invoiceId_id});

  @override
  _EditInvoiceDialogState createState() => _EditInvoiceDialogState();
}

class _EditInvoiceDialogState extends State<EditInvoiceDialog> {
  late Future<List<dynamic>> _invoiceDataFuture;
  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    _invoiceDataFuture = fetchInvoiceDetails(widget.invoiceId);
  }

   Future<void> updateInvoiceDetails(int invoiceId, int id, Map<String, dynamic> updates) async {
  final url = 'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/update_inv_details.php';

  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {
      'id': id.toString(),
      'invoice_id': invoiceId.toString(),
      'from_sender': updates['from_sender'],
      'bill_to': updates['bill_to'],
      'item_name': updates['item_name'],
      'quantity': updates['quantity'].toString(),
      'unit_price': updates['unit_price'].toString(),
      'total_price': updates['total_price'].toString(),
      'notes': updates['notes'].toString(),
    },
  );

  if (response.statusCode == 200) {
    print("Success: ${response.body}");
  } else {
    throw Exception('Failed to update invoice details');
  }
}

  Future<List<dynamic>> fetchInvoiceDetails(int invoiceId) async {
    // API call to get invoice details
    final response = await http.post(
      Uri.parse('https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_invoices_details_data_for_update.php'),
      body:{
        'invoice_id' : invoiceId.toString(),
      }
    );

    if (response.statusCode == 200) {
      print("fetchInvoiceDetails ${response.body}");
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load invoice details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _invoiceDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final invoiceData = snapshot.data!;
          print("invoiceData ${invoiceData[_currentIndex]['id']}");
          // Get screen size for responsive design
          final screenSize = MediaQuery.of(context).size;
          final isSmallScreen = screenSize.width < 600;
          
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Invoice Details ${_currentIndex + 1}/${invoiceData.length}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (invoiceData.length > 1) Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 18),
                      onPressed: _currentIndex > 0
                          ? () => setState(() => _currentIndex--)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 18),
                      onPressed: _currentIndex < invoiceData.length - 1
                          ? () => setState(() => _currentIndex++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            content: Container(
              width: isSmallScreen ? screenSize.width * 0.9 : screenSize.width * 0.5,
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: screenSize.height * 0.7,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'From',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      controller: TextEditingController(text: invoiceData[_currentIndex]['from_sender']),
                      onChanged: (value) => invoiceData[_currentIndex]['from_sender'] = value,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'To',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      controller: TextEditingController(text: invoiceData[_currentIndex]['bill_to']),
                      onChanged: (value) => invoiceData[_currentIndex]['bill_to'] = value,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      controller: TextEditingController(text: invoiceData[_currentIndex]['item_name']),
                      onChanged: (value) => invoiceData[_currentIndex]['item_name'] = value,
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: invoiceData[_currentIndex]['quantity'].toString()),
                            onChanged: (value) => invoiceData[_currentIndex]['quantity'] = int.tryParse(value) ?? 0,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Unit Price',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: invoiceData[_currentIndex]['unit_price'].toString()),
                            onChanged: (value) => invoiceData[_currentIndex]['unit_price'] = double.tryParse(value) ?? 0.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      maxLines: 3,
                      keyboardType: TextInputType.text,
                      controller: TextEditingController(text: invoiceData[_currentIndex]['notes'].toString()),
                      onChanged: (value) => invoiceData[_currentIndex]['notes'] = value,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                child: Text('Cancel'),
              ),
              ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).primaryColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  onPressed: () async {
    try {
      final currentItem = invoiceData[_currentIndex];
      
      
      
      // استخدم القيمة الحقيقية لـ id من السجل
      //final int id = currentItem['id']; 
      final int id = currentItem['id']; 
      final int invoiceId = widget.invoiceId;
print("currentID.D ${id} currentID.I ${invoiceId}");
      // احسب total_price
      final double quantity = double.tryParse(currentItem['quantity'].toString()) ?? 0;
      final double unitPrice = double.tryParse(currentItem['unit_price'].toString()) ?? 0;
      final String totalPrice = (quantity * unitPrice).toString();

      // تحديث البيانات على الخادم
      await updateInvoiceDetails(
        invoiceId, // invoice_id
        id, // id (الخاص بكل سطر)
        {
          'from_sender': currentItem['from_sender'],
          'bill_to': currentItem['bill_to'],
          'item_name': currentItem['item_name'],
          'quantity': quantity.toString(),
          'unit_price': unitPrice.toString(),
          'total_price': totalPrice,
          'notes': currentItem['notes'].toString(),
        },
      );

      // تحديث البيانات المحلية مباشرة
      setState(() {
        invoiceData[_currentIndex] = {
          ...currentItem,
          'quantity': quantity,
          'unit_price': unitPrice,
          'total_price': totalPrice,
          'notes': currentItem['notes'],
        };
      });

      // تحديث الصفحة الأم إن وُجدت
      if (context.findAncestorStateOfType<_InvoiceDetailPageState>() != null) {
        final state = context.findAncestorStateOfType<_InvoiceDetailPageState>();
        await state?.fetchInvDetails(currentItem['inv_num']);
      }

      // إغلاق الدايلوج وإظهار رسالة نجاح
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update data: $e')),
      );
    }
  },
  child: Text('Save Changes'),
),
            ],
          );
        }
      },
    );
  }
} 


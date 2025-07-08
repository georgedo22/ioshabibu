import 'package:flutter/material.dart';
import 'package:habibuios/InventoryApp/api_service.dart';
import 'package:habibuios/InventoryApp/spare_part.dart';


class AddPartScreen extends StatefulWidget {
  final String? governorate_id;
  AddPartScreen({this.governorate_id});
  @override
  _AddPartScreenState createState() => _AddPartScreenState();
}

class _AddPartScreenState extends State<AddPartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _partNameController = TextEditingController();
  final _partCodeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _storageLocationController = TextEditingController();
  final _minimumThresholdController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print('Governorate ID: ${widget.governorate_id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Spare Part'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.green[50]!],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _partNameController,
                    label: 'Part Name',
                    icon: Icons.build_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter part name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _partCodeController,
                    label: 'Part Code',
                    icon: Icons.qr_code_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter part code';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _quantityController,
                    label: 'Quantity',
                    icon: Icons.numbers_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter quantity';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter valid number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _priceController,
                    label: 'Price',
                    icon: Icons.attach_money_outlined,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter valid price';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _storageLocationController,
                    label: 'Storage Location',
                    icon: Icons.location_on_outlined,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _minimumThresholdController,
                    label: 'Minimum Threshold',
                    icon: Icons.low_priority_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (int.tryParse(value) == null) {
                          return 'Please enter valid number';
                        }
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 8,
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Save Part',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  void _savePart() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final part = SparePart(
        partName: _partNameController.text,
        partCode: _partCodeController.text,
        quantity: int.parse(_quantityController.text),
        price: double.parse(_priceController.text),
        storageLocation: _storageLocationController.text,
        minimumThreshold: int.tryParse(_minimumThresholdController.text) ?? 5,
        governorate_id: widget.governorate_id
            .toString(), // Pass the governorate_id as String
      );

      final success = await ApiService.addPart(part);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Failed to save part. Please try again.');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // منع الإغلاق بالضغط خارج الـ dialog
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Success'),
            ],
          ),
          content: Text('Part has been added successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // إغلاق الـ dialog
                _clearForm(); // مسح النموذج
              },
              child: Text('OK', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  void _clearForm() {
    // مسح النصوص من الـ controllers
    _partNameController.clear();
    _partCodeController.clear();
    _quantityController.clear();
    _priceController.clear();
    _storageLocationController.clear();
    _minimumThresholdController.clear();

    // إعادة بناء الواجهة
    setState(() {});

    // إعادة تعيين حالة النموذج بعد delay قصير
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted && _formKey.currentState != null) {
        _formKey.currentState!.reset();
        setState(() {});
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

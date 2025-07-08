import 'package:flutter/material.dart';
import 'package:habibuios/InventoryApp/spare_part.dart';


class PartDetailsScreen extends StatefulWidget {
  final SparePart part;

  PartDetailsScreen({required this.part});

  @override
  _PartDetailsScreenState createState() => _PartDetailsScreenState();
}

class _PartDetailsScreenState extends State<PartDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _partNameController;
  late TextEditingController _partCodeController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _storageLocationController;
  late TextEditingController _minimumThresholdController;
  bool _isLoading = false;

  late SparePart currentPart;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    currentPart = widget.part;

    _partNameController = TextEditingController(text: widget.part.partName);
    _partCodeController = TextEditingController(text: widget.part.partCode);
    _quantityController =
        TextEditingController(text: widget.part.quantity.toString());
    _priceController =
        TextEditingController(text: widget.part.price.toString());
    _storageLocationController =
        TextEditingController(text: widget.part.storageLocation);
    _minimumThresholdController =
        TextEditingController(text: widget.part.minimumThreshold.toString());
  }

  @override
  dispose() {
    _partNameController.dispose();
    _partCodeController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _storageLocationController.dispose();
    _minimumThresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Part Details'),
        backgroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            // onPressed: isEditing ? _saveChanges : _toggleEdit,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo, Colors.indigo[50]!],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.indigo[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.build_circle,
                      size: 60,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                if (isEditing) _buildEditForm() else _buildDetailView(),
                SizedBox(height: 24),
                if (!isEditing) _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailView() {
    final isLowStock = currentPart.isLowStock;
    return Column(
      children: [
        _buildDetailRow('Part Name', currentPart.partName),
        _buildDetailRow('Part Code', currentPart.partCode),
        _buildDetailRow('Quantity', '${currentPart.quantity}',
            isLowStock ? Colors.red : null),
        _buildDetailRow('Price', '\$${currentPart.price.toStringAsFixed(2)}'),
        _buildDetailRow('Storage Location', currentPart.storageLocation),
        _buildDetailRow('Minimum Threshold', '${currentPart.minimumThreshold}'),
        if (isLowStock) ...[
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This part is running low on stock!',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label + ':',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: valueColor ?? Colors.grey[800],
                fontWeight:
                    valueColor != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.indigo, width: 2),
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _partNameController,
            label: 'Part Name',
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          SizedBox(height: 12),
          _buildTextField(
            controller: _partCodeController,
            label: 'Part Code',
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          SizedBox(height: 12),
          _buildTextField(
            controller: _quantityController,
            label: 'Quantity',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Required';
              if (int.tryParse(value!) == null) return 'Invalid number';
              return null;
            },
          ),
          SizedBox(height: 12),
          _buildTextField(
            controller: _priceController,
            label: 'Price',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Required';
              if (double.tryParse(value!) == null) return 'Invalid price';
              return null;
            },
          ),
          SizedBox(height: 12),
          _buildTextField(
            controller: _storageLocationController,
            label: 'Storage Location',
          ),
          SizedBox(height: 12),
          _buildTextField(
            controller: _minimumThresholdController,
            label: 'Minimum Threshold',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isNotEmpty ?? false) {
                if (int.tryParse(value!) == null) return 'Invalid number';
              }
              return null;
            },
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  //onPressed: _isLoading ? null : _saveChanges,
                  onPressed: () {},
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    /* return EditPartForm(
      part: currentPart,
      onSave: (updatedPart) {
        setState(() {
          currentPart = updatedPart;
          isEditing = false;
        });
      },
      onCancel: () {
        setState(() {
          isEditing = false;
        });
      },
    );*/
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _toggleEdit,
            icon: Icon(Icons.edit, color: Colors.white),
            label: Text('Edit Part', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showStockUpdateDialog,
            icon: Icon(Icons.update, color: Colors.white),
            label: Text('Update Stock', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleEdit() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  /*void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      final updatedPart = SparePart(
        id: widget.part.id,
        partName: _partNameController.text,
        partCode: _partCodeController.text,
        quantity: int.parse(_quantityController.text),
        price: double.parse(_priceController.text),
        storageLocation: _storageLocationController.text,
        minimumThreshold: int.tryParse(_minimumThresholdController.text) ?? 5,
      );
      final success = await ApiService.updatePart(updatedPart);
      setState(() {
        _isLoading = false;
      });
      if (success) {
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Part updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update part'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }*/

  void _showStockUpdateDialog() {
    final quantityController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('Update Stock Quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current quantity: ${currentPart.quantity}'),
              SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'New Quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newQuantity = int.tryParse(quantityController.text);
                if (newQuantity != null) {
                  // _updateStock(newQuantity);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  /* void _updateStock(int newQuantity) async {
    final updatedPart = SparePart(
      id: currentPart.id,
      partName: currentPart.partName,
      partCode: currentPart.partCode,
      quantity: newQuantity,
      price: currentPart.price,
      storageLocation: currentPart.storageLocation,
      minimumThreshold: currentPart.minimumThreshold,
    );
    final success = await ApiService.updatePart(updatedPart);
    if (success) {
      setState(() {
        currentPart = updatedPart;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update stock'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }*/
}





// Compare this snippet from part_details_screen.dart:  
 
import 'package:flutter/material.dart';
import 'package:habibuios/InventoryApp/api_service.dart';
import 'package:habibuios/InventoryApp/part_details_screen.dart';
import 'package:habibuios/InventoryApp/spare_part.dart';


class LowStockAlertsScreen extends StatefulWidget {
  @override
  _LowStockAlertsScreenState createState() => _LowStockAlertsScreenState();
}

class _LowStockAlertsScreenState extends State<LowStockAlertsScreen> {
  List<SparePart> lowStockParts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLowStockParts();
  }

  Future<void> _loadLowStockParts() async {
    setState(() {
      isLoading = true;
    });
    final parts = await ApiService.getLowStockParts();
    setState(() {
      lowStockParts = parts;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Low Stock Alerts'),
        backgroundColor: Colors.orange,
        elevation: 0,
       /* actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MainMenuScreen()),
              (route) => false,
            ),
          ),
        ],*/
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange, Colors.orange[50]!],
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : lowStockParts.isEmpty
                ? _buildEmptyState()
                : _buildLowStockList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(40),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'Great News!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 10),
            Text(
              'All parts are well stocked',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: lowStockParts.length,
      itemBuilder: (context, index) {
        final part = lowStockParts[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning, color: Colors.red, size: 24),
            ),
            title: Text(
              part.partName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text('Code: ${part.partCode}'),
                Text('Current Stock: ${part.quantity}'),
                Text('Minimum Required: ${part.minimumThreshold}'),
                Text('Location: ${part.storageLocation}'),
              ],
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'LOW',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () => _showPartDetails(part),
          ),
        );
      },
    );
  }

  void _showPartDetails(SparePart part) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PartDetailsScreen(part: part),
      ),
    ).then((_) => _loadLowStockParts());
  }
}
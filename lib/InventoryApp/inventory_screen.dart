import 'package:flutter/material.dart';
import 'package:habibuios/InventoryApp/api_service.dart';
import 'package:habibuios/InventoryApp/spare_part.dart';


import 'part_details_screen.dart';

class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<SparePart> allParts = [];
  List<SparePart> filteredParts = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllParts();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = searchController.text;
      _filterParts();
    });
  }

  void _filterParts() {
    if (searchQuery.isEmpty) {
      filteredParts = List.from(allParts);
    } else {
      filteredParts = allParts.where((part) {
        return part.partName.toLowerCase().contains(searchQuery.toLowerCase()) ||
               part.partCode.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }
  }

  Future<void> _loadAllParts() async {
    setState(() {
      isLoading = true;
    });
    final parts = await ApiService.getAllParts();
    setState(() {
      allParts = parts;
      filteredParts = List.from(parts);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Current Inventory'),
        backgroundColor: Colors.blue,
        elevation: 0,
        /*actions: [
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
            colors: [Colors.blue, Colors.blue[50]!],
          ),
        ),
        child: Column(
          children: [
            // Search Bar
            Container(
              margin: EdgeInsets.all(16),
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
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search by product name or code number...',
                  prefixIcon: Icon(Icons.search, color: Colors.blue),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            // Results Count
            if (searchQuery.isNotEmpty)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Search results: ${filteredParts.length} products',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 8),
            // Content
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : filteredParts.isEmpty
                      ? _buildEmptyState()
                      : _buildInventoryList(),
            ),
          ],
        ),
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
            Icon(
              searchQuery.isNotEmpty ? Icons.search_off : Icons.inventory_outlined,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              searchQuery.isNotEmpty ? 'No results.' : 'No products available.',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 10),
            Text(
              searchQuery.isNotEmpty
                  ? 'Try searching with different words.'
                  : 'Start by adding some spare parts.',
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

  Widget _buildInventoryList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredParts.length,
      itemBuilder: (context, index) {
        final part = filteredParts[index];
        final isLowStock = part.isLowStock;
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
                color: isLowStock ? Colors.red[100] : Colors.blue[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isLowStock ? Icons.warning : Icons.inventory,
                color: isLowStock ? Colors.red : Colors.blue,
                size: 24,
              ),
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
                Text('Quantity: ${part.quantity}'),
                Text('Price: \$${part.price.toStringAsFixed(2)}'),
                Text('Location: ${part.storageLocation}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLowStock)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'LOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                SizedBox(height: 4),
                Icon(Icons.arrow_forward_ios, size: 16),
              ],
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
    ).then((_) => _loadAllParts()); // Refresh when returning
  }
}
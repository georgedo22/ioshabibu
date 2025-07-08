import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:habibuios/InventoryApp/addpartscreen.dart';
import 'package:habibuios/InventoryApp/inventory_screen.dart';
import 'package:habibuios/InventoryApp/lowstockalertsscreen.dart';


class MainMenuScreen extends StatefulWidget {
  final String? governorate_id;
  MainMenuScreen({required this.governorate_id});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[400]!, Colors.purple[400]!],
          ),
        ),
        child: Stack(
          children: [
            // المحتوى الرئيسي
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Inventory Management System',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ListView(
                        padding: EdgeInsets.all(16),
                        children: [
                          _buildMenuButton(context, 'Add New Spare Part',
                              Icons.add_circle_outline, Colors.green, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AddPartScreen(
                                      governorate_id: widget.governorate_id)),
                            );
                          }),
                          SizedBox(height: 20),
                          _buildMenuButton(context, 'View Low Stock Alerts',
                              Icons.warning_outlined, Colors.orange, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LowStockAlertsScreen()),
                            );
                          }),
                          SizedBox(height: 20),
                          _buildMenuButton(
                              context,
                              'View/Edit Current Inventory',
                              Icons.inventory_outlined,
                              Colors.blue, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => InventoryScreen()),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // زر المنزل في الزاوية العلوية اليمنى
            /*  Positioned(
              top: 30,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context); // العودة للصفحة السابقة
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.home,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
              ),
            ),*/
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 40),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MachineDetailPage extends StatefulWidget {
  final Map<String, dynamic> machine;

  MachineDetailPage({required this.machine});

  @override
  _MachineDetailPageState createState() => _MachineDetailPageState();
}

class _MachineDetailPageState extends State<MachineDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _maintenanceFuture;
  late Future<List<FuelLog>> _fuelLogsFuture;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    _maintenanceFuture =
        fetchMaintenanceSchedule(widget.machine['vehicle_id'].toString());
    _fuelLogsFuture = fetchFuelLogs(widget.machine['vehicle_id']);
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      _loadData();
      await Future.delayed(
          Duration(milliseconds: 500)); // تأخير بسيط لتجربة مستخدم أفضل
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
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
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _maintenanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingWidget();
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString(), _refreshData);
          }

          final data = snapshot.data!;
          if (data.isEmpty) {
            return _buildEmptyWidget(
              'No maintenance records found.',
              Icons.build_outlined,
              _refreshData,
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isMobile = screenWidth <= 600;
              final isTablet = screenWidth > 600 && screenWidth <= 1024;

              return ListView.builder(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final item = data[index];
                  return _buildMaintenanceCard(item, screenWidth);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMaintenanceCard(Map<String, dynamic> item, double screenWidth) {
    final isMobile = screenWidth <= 600;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;

    return Card(
      elevation: isMobile ? 2 : 4,
      margin: EdgeInsets.symmetric(vertical: isMobile ? 6 : 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
      ),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان الرئيسي
            Row(
              children: [
                Icon(
                  Icons.build_circle,
                  color: Colors.blue,
                  size: isMobile ? 20 : 24,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${item['maintenance_type']} - ${item['m_date']}',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 8 : 12),

            // تفاصيل الصيانة
            if (screenWidth > 800)
              _buildMaintenanceDetailsGrid(item, isMobile)
            else
              _buildMaintenanceDetailsList(item, isMobile),

            // الملاحظات
            if (item['note'] != null &&
                item['note'].toString().trim().isNotEmpty) ...[
              SizedBox(height: isMobile ? 8 : 12),
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      color: Colors.blue.shade600,
                      size: isMobile ? 16 : 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note: ${item['note']}',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceDetailsGrid(
      Map<String, dynamic> item, bool isMobile) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 8,
      children: [
        _buildDetailItem('Description',
            item['maintenance_description'] ?? '---', Icons.description),
        _buildDetailItem(
            'Parts', item['parts_replacement'] ?? '---', Icons.build),
        _buildDetailItem('Before', item['status_before_maintenance'] ?? '---',
            Icons.warning),
        _buildDetailItem('After', item['status_after_maintenance'] ?? '---',
            Icons.check_circle),
        _buildDetailItem(
            'Engine Oil', '${item['oil_eng_quantity']}', Icons.oil_barrel),
        _buildDetailItem('Azola Oil', '${item['azola_oil_quantity']}',
            Icons.local_gas_station),
      ],
    );
  }

  Widget _buildMaintenanceDetailsList(
      Map<String, dynamic> item, bool isMobile) {
    return Column(
      children: [
        _buildDetailRow('Description', item['maintenance_description'] ?? '---',
            Icons.description, isMobile),
        _buildDetailRow(
            'Parts', item['parts_replacement'] ?? '---', Icons.build, isMobile),
        _buildDetailRow('Before', item['status_before_maintenance'] ?? '---',
            Icons.warning, isMobile),
        _buildDetailRow('After', item['status_after_maintenance'] ?? '---',
            Icons.check_circle, isMobile),
        _buildDetailRow('Engine Oil', '${item['oil_eng_quantity']}',
            Icons.oil_barrel, isMobile),
        _buildDetailRow('Azola Oil', '${item['azola_oil_quantity']}',
            Icons.local_gas_station, isMobile),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, IconData icon, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: isMobile ? 16 : 18,
            color: Colors.grey.shade600,
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkFuelTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: FutureBuilder<List<FuelLog>>(
        future: _fuelLogsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingWidget();
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString(), _refreshData);
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyWidget(
              'No fuel logs available.',
              Icons.local_gas_station_outlined,
              _refreshData,
            );
          }

          final logs = snapshot.data!;

          return LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isMobile = screenWidth <= 600;
              final isTablet = screenWidth > 600 && screenWidth <= 1024;

              if (isMobile) {
                return _buildMobileFuelLogsList(logs);
              } else {
                return _buildTabletDesktopFuelTable(logs, screenWidth);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildMobileFuelLogsList(List<FuelLog> logs) {
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.date,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${log.hourwork}h worked',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMobileLogDetail(
                          'Hour', log.hour.toString(), Icons.schedule),
                    ),
                    Expanded(
                      child: _buildMobileLogDetail(
                          'Last Hour', log.lasthour.toString(), Icons.history),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMobileLogDetail('Liters',
                          log.liter.toString(), Icons.local_gas_station),
                    ),
                    Expanded(
                      child: _buildMobileLogDetail(
                          'Consumption',
                          log.consumption.toStringAsFixed(2),
                          Icons.trending_down),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Created: ${log.created_at}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileLogDetail(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletDesktopFuelTable(List<FuelLog> logs, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: screenWidth - 32),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dataTableTheme: DataTableThemeData(
                    headingRowColor: MaterialStateColor.resolveWith(
                      (states) => Colors.blue.shade50,
                    ),
                    dataRowColor: MaterialStateColor.resolveWith(
                      (states) => states.contains(MaterialState.selected)
                          ? Colors.blue.shade100
                          : Colors.transparent,
                    ),
                  ),
                ),
                child: DataTable(
                  columnSpacing: screenWidth > 1024 ? 24 : 16,
                  headingRowHeight: 56,
                  dataRowHeight: 48,
                  showCheckboxColumn: false,
                  columns: [
                    DataColumn(
                      label: Text(
                        'Date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Hour',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Last Hour',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Worked Hours',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Liters',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Consumption',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Created At',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                  rows: logs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final log = entry.value;
                    return DataRow(
                      color: MaterialStateColor.resolveWith(
                        (states) =>
                            index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                      ),
                      cells: [
                        DataCell(Text(
                          log.date,
                          style: TextStyle(fontWeight: FontWeight.w500),
                        )),
                        DataCell(Text(log.hour.toString())),
                        DataCell(Text(log.lasthour.toString())),
                        DataCell(
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              log.hourwork.toString(),
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_gas_station,
                                  size: 16, color: Colors.orange),
                              SizedBox(width: 4),
                              Text(log.liter.toString()),
                            ],
                          ),
                        ),
                        DataCell(Text(log.consumption.toStringAsFixed(2))),
                        DataCell(Text(
                          log.created_at,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading data...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'Error loading data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(
      String message, IconData icon, VoidCallback onRefresh) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: Icon(Icons.refresh),
              label: Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth <= 600;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.machine['vehicle_number'] ?? 'Machine Details',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              if (_isRefreshing)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _refreshData,
                  tooltip: 'Refresh',
                ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(kToolbarHeight),
              child: Container(
                color: Colors.blue.shade700,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(
                      text: isMobile ? 'Maintenance' : 'Maintenance Schedule',
                      icon: Icon(Icons.build, size: isMobile ? 16 : 20),
                    ),
                    Tab(
                      text: isMobile ? 'Fuel/Hours' : 'Working Hours / Diesel',
                      icon: Icon(Icons.local_gas_station,
                          size: isMobile ? 16 : 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMaintenanceTab(),
                _buildWorkFuelTab(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FuelLog {
  final String date;
  final int hour;
  final int lasthour;
  final int hourwork;
  final double liter;
  final double consumption;
  final String created_at;

  FuelLog({
    required this.date,
    required this.hour,
    required this.lasthour,
    required this.hourwork,
    required this.liter,
    required this.consumption,
    required this.created_at,
  });

  factory FuelLog.fromJson(Map<String, dynamic> json) {
    return FuelLog(
      date: json['date'],
      hour: int.parse(json['hour'].toString()),
      lasthour: int.parse(json['lasthour'].toString()),
      hourwork: int.parse(json['hourwork'].toString()),
      liter: double.parse(json['liter'].toString()),
      consumption: double.parse(json['consumption'].toString()),
      created_at: json['created_at'] ?? '',
    );
  }
}

Future<List<FuelLog>> fetchFuelLogs(int vehicleId) async {
  final url = Uri.parse(
      "https://antiquewhite-cobra-422929.hostingersite.com/georgecode/get_fuel_work_logs.php?vehicle_id=$vehicleId");

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final body = json.decode(response.body);
    if (body['status']) {
      return (body['data'] as List)
          .map((item) => FuelLog.fromJson(item))
          .toList();
    } else {
      throw Exception(body['message']);
    }
  } else {
    throw Exception("Failed to load fuel logs");
  }
}

/*import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'dart:math';

class ReportsPage extends StatefulWidget {
  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // Dummy data for project performance
  final List<ProjectPerformance> projectPerformances = [
    ProjectPerformance('ATAP', 85.5, 1200000, 950000),
    ProjectPerformance('ZANGO', 72.3, 850000, 620000),
    ProjectPerformance('BARACKS', 65.7, 1500000, 980000),
    ProjectPerformance('SABON KAORA', 55.2, 600000, 330000),
    ProjectPerformance('Houston Flood Control', 90.1, 2000000, 1800000),
    ProjectPerformance('Austin Green Energy Park', 78.6, 1300000, 1020000),
    ProjectPerformance('Dallas Highway Upgrade', 88.4, 1750000, 1540000),
  ];

  String _selectedYear = '2025';
  final List<String> _years = ['2024', '2025', '2026'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comprehensive Reports'),
        actions: [
          DropdownButton<String>(
            value: _selectedYear,
            items: _years.map((String year) {
              return DropdownMenuItem<String>(
                value: year,
                child: Text(year),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedYear = newValue!;
              });
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildPerformanceLeaderboard(),
          SizedBox(height: 16),
          _buildProjectRevenueChart(),
          SizedBox(height: 16),
          _buildCompanyPerformanceChart(),
        ],
      ),
    );
  }

  Widget _buildPerformanceLeaderboard() {
    // Sort projects by profitability
    var sortedProjects = List.of(projectPerformances)
      ..sort((a, b) => b.profitability.compareTo(a.profitability));

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Project Performance Leaderboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: sortedProjects.length,
            itemBuilder: (context, index) {
              var project = sortedProjects[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                  backgroundColor: _getLeaderboardColor(index),
                ),
                title: Text(project.name),
                subtitle: Text('Profitability: ${project.profitability.toStringAsFixed(2)}%'),
                trailing: Text('\$${project.revenue.toStringAsFixed(0)}'),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getLeaderboardColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  Widget _buildProjectRevenueChart() {
    var series = [
      charts.Series<ProjectPerformance, String>(
        id: 'Project Revenue',
        domainFn: (ProjectPerformance project, _) => project.name,
        measureFn: (ProjectPerformance project, _) => project.revenue,
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        data: projectPerformances,
        labelAccessorFn: (ProjectPerformance project, _) =>
        '\$${project.revenue.toStringAsFixed(0)}',
      )
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Revenue Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: charts.BarChart(
                series,
                animate: true,
                vertical: true,
                barRendererDecorator: charts.BarLabelDecorator<String>(),
                domainAxis: charts.OrdinalAxisSpec(
                  renderSpec: charts.SmallTickRendererSpec(
                    labelRotation: 45,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyPerformanceChart() {
    // إنشاء قائمة البيانات مع إضافة فهرسة
    var monthlyData = [
      _MonthlyPerformance(0, 'Jan', 850000),
      _MonthlyPerformance(1, 'Feb', 920000),
      _MonthlyPerformance(2, 'Mar', 1100000),
      _MonthlyPerformance(3, 'Apr', 1250000),
      _MonthlyPerformance(4, 'May', 1050000),
      _MonthlyPerformance(5, 'Jun', 980000),
    ];

    // تعديل السلسلة للتعامل مع القيم الرقمية
    var series = [
      charts.Series<_MonthlyPerformance, num>(
        id: 'Monthly Revenue',
        domainFn: (_MonthlyPerformance month, _) => month.index,
        measureFn: (_MonthlyPerformance month, _) => month.revenue,
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
        data: monthlyData,
        labelAccessorFn: (_MonthlyPerformance month, _) =>
        '${month.monthName}\n\$${month.revenue.toStringAsFixed(0)}',
      )
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: charts.LineChart(
                series,
                animate: true,
                domainAxis: charts.NumericAxisSpec(
                  tickProviderSpec: charts.StaticNumericTickProviderSpec(
                    // إنشاء علامات محددة مسبقًا
                    [
                      charts.TickSpec(0, label: 'Jan'),
                      charts.TickSpec(1, label: 'Feb'),
                      charts.TickSpec(2, label: 'Mar'),
                      charts.TickSpec(3, label: 'Apr'),
                      charts.TickSpec(4, label: 'May'),
                      charts.TickSpec(5, label: 'Jun'),
                    ],
                  ),
                  renderSpec: charts.SmallTickRendererSpec(
                    labelRotation: 45,
                    minimumPaddingBetweenLabelsPx: 4,
                    labelStyle: charts.TextStyleSpec(
                      fontSize: 10,
                      color: charts.MaterialPalette.black,
                    ),
                  ),
                ),
                primaryMeasureAxis: charts.NumericAxisSpec(
                  tickProviderSpec: charts.BasicNumericTickProviderSpec(
                    desiredTickCount: 5,
                  ),
                  renderSpec: charts.GridlineRendererSpec(
                    labelStyle: charts.TextStyleSpec(
                      fontSize: 10,
                      color: charts.MaterialPalette.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data Models
class ProjectPerformance {
  final String name;
  final double profitability;
  final double revenue;
  final double cost;

  ProjectPerformance(this.name, this.profitability, this.revenue, this.cost);
}

// تحديث نموذج البيانات
class _MonthlyPerformance {
  final int index;
  final String monthName;
  final double revenue;

  _MonthlyPerformance(this.index, this.monthName, this.revenue);
}*/
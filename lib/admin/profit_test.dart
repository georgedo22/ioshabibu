import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class ProfitTestPage extends StatefulWidget {
  @override
  State<ProfitTestPage> createState() => _ProfitTestPageState();
}

class _ProfitTestPageState extends State<ProfitTestPage> {
  late Future<List<GovProfit>> _govProfitsFuture;
  late Future<List<ProjectProfit>> _projectProfitsFuture;

  late Future<List<GovProfit>> _govProfitsFuturewithoutYear;
  // int? _selectedYear;
  //List<int> _years = [];

  @override
  void initState() {
    super.initState();
    _projectProfitsFuture = fetchProjectProfits();
    _govProfitsFuture = fetchGovProfits();
    _govProfitsFuturewithoutYear = fetchGovProfitswithoutYear();
    // _initYears();
  }

  /*void _initYears() async {
    // Fetch years from project profits (or set statically if needed)
    final projects = await fetchProjectProfits();
    final years = projects.map((e) => e.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    setState(() {
      _years = years;
      if (_years.isNotEmpty) {
        _selectedYear = _years.first;
      }
    });
  }*/

  Future<List<GovProfit>> fetchGovProfitswithoutYear() async {
    final response = await http.get(Uri.parse(
        'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/admin/fetch_profit_gov.withoutyear.php'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => GovProfit.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load governorate profits');
    }
  }

  Future<List<GovProfit>> fetchGovProfits() async {
    final response = await http.get(Uri.parse(
        'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/admin/fetch_profit_gov.php'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => GovProfit.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load governorate profits');
    }
  }

  Future<List<ProjectProfit>> fetchProjectProfits() async {
    final response = await http.get(Uri.parse(
        'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/admin/fetch_profit_project.php'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => ProjectProfit.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load project profits');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profit Reports',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade800,
        /*actions: [
          if (_years.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: DropdownButton<int>(
                value: _selectedYear,
                dropdownColor: Colors.white,
                icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                underline: SizedBox(),
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                items: _years.map((year) {
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedYear = val;
                  });
                },
              ),
            ),
        ],*/
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: Governorate Profit Chart
            Text(
              "Governorate Profits",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 12),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder<List<GovProfit>>(
                  future: _govProfitsFuturewithoutYear,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                          height: 220,
                          child: Center(child: CircularProgressIndicator()));
                    } else if (snapshot.hasError) {
                      return SizedBox(
                          height: 120,
                          child: Center(child: Text('Error loading data')));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return SizedBox(
                          height: 120,
                          child: Center(child: Text('No data available')));
                    }
                    return GovProfitBarChart(data: snapshot.data!);
                  },
                ),
              ),
            ),
            SizedBox(height: 32),

            // Section 2: Project Profit Chart
            Text(
              "Project Profits",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 12),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder<List<ProjectProfit>>(
                  future: _projectProfitsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                          height: 220,
                          child: Center(child: CircularProgressIndicator()));
                    } else if (snapshot.hasError) {
                      return SizedBox(
                          height: 120,
                          child: Center(child: Text('Error loading data')));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return SizedBox(
                          height: 120,
                          child: Center(child: Text('No data available')));
                    }
                    return ProjectProfitBarChart(data: snapshot.data!);
                  },
                ),
              ),
            ),

            SizedBox(height: 32),
            // New Section: Company Yearly Performance Chart
            FutureBuilder<List<GovProfit>>(
              future: _govProfitsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()));
                } else if (snapshot.hasError) {
                  return SizedBox(
                      height: 120,
                      child: Center(
                          child: Text('Error loading yearly performance')));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SizedBox(
                      height: 120,
                      child: Center(child: Text('No yearly performance data')));
                }
                return CompanyYearlyPerformanceChart(data: snapshot.data!);
              },
            ),

            SizedBox(height: 32),
            FutureBuilder<List<ProjectProfit>>(
              future: _projectProfitsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()));
                } else if (snapshot.hasError) {
                  return SizedBox(
                      height: 120,
                      child: Center(child: Text('Error loading leaderboard')));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SizedBox(
                      height: 120,
                      child: Center(child: Text('No leaderboard data')));
                }
                return ProjectLeaderboardSection(projects: snapshot.data!);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ================== Governorate Profit Chart Widget ==================
class GovProfit {
  final int governorateId;
  final String cityName;
  final double totalContractValue;
  final double totalInvoicePrice;
  final double difference;
  final int? year;

  GovProfit({
    required this.governorateId,
    required this.cityName,
    required this.totalContractValue,
    required this.totalInvoicePrice,
    required this.difference,
    this.year,
  });

  factory GovProfit.fromJson(Map<String, dynamic> json) {
    return GovProfit(
      governorateId: json['governorate_id'],
      cityName: json['cityname'] ?? '',
      totalContractValue:
          double.tryParse(json['total_contract_value'] ?? '0') ?? 0,
      totalInvoicePrice:
          double.tryParse(json['total_invoice_price'] ?? '0') ?? 0,
      difference: double.tryParse(json['difference'] ?? '0') ?? 0,
      year: json['year'] != null ? int.tryParse(json['year'].toString()) : null,
    );
  }
}

class GovProfitBarChart extends StatelessWidget {
  final List<GovProfit> data;
  GovProfitBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data
            .map((e) => e.totalContractValue)
            .fold<double>(0, (p, c) => c > p ? c : p) *
        1.2;
    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY == 0 ? 100 : maxY,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
                reservedSize: 48,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      data[idx].cityName,
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, horizontalInterval: maxY / 5),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(data.length, (i) {
            final gov = data[i];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: gov.totalContractValue,
                  color: Colors.blue.shade700,
                  width: 22,
                  borderRadius: BorderRadius.circular(8),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.blue.shade100,
                  ),
                ),
                BarChartRodData(
                  toY: gov.difference,
                  color: Colors.green.shade400,
                  width: 12,
                  borderRadius: BorderRadius.circular(6),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: false,
                  ),
                ),
              ],
              showingTooltipIndicators: [0],
            );
          }),
        ),
      ),
    );
  }
}

// ================== Project Profit Chart Widget ==================
class ProjectProfit {
  final int projectId;
  final String projectName;
  final int year;
  final double totalContractValue;
  final double totalInvoicePrice;
  final double profit;

  ProjectProfit({
    required this.projectId,
    required this.projectName,
    required this.year,
    required this.totalContractValue,
    required this.totalInvoicePrice,
    required this.profit,
  });

  factory ProjectProfit.fromJson(Map<String, dynamic> json) {
    return ProjectProfit(
      projectId: json['project_id'],
      projectName: json['project_name'] ?? '',
      year: json['year'] ?? 0,
      totalContractValue:
          double.tryParse(json['total_contract_value'] ?? '0') ?? 0,
      totalInvoicePrice:
          double.tryParse(json['total_invoice_price'] ?? '0') ?? 0,
      profit: double.tryParse(json['profit'] ?? '0') ?? 0,
    );
  }
}

class ProjectProfitBarChart extends StatelessWidget {
  final List<ProjectProfit> data;
  ProjectProfitBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data
            .map((e) => e.totalContractValue)
            .fold<double>(0, (p, c) => c > p ? c : p) *
        1.2;
    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY == 0 ? 100 : maxY,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
                reservedSize: 48,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      data[idx].projectName,
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, horizontalInterval: maxY / 5),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(data.length, (i) {
            final p = data[i];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: p.totalContractValue,
                  color: Colors.deepPurple.shade400,
                  width: 22,
                  borderRadius: BorderRadius.circular(8),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.deepPurple.shade100,
                  ),
                ),
                BarChartRodData(
                  toY: p.profit,
                  color: Colors.orange.shade400,
                  width: 12,
                  borderRadius: BorderRadius.circular(6),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: false,
                  ),
                ),
              ],
              showingTooltipIndicators: [0],
            );
          }),
        ),
      ),
    );
  }
}

// ================== Project Leaderboard Section ==================
class ProjectLeaderboardSection extends StatelessWidget {
  final List<ProjectProfit> projects;
  const ProjectLeaderboardSection({required this.projects, super.key});

  Color _medalColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort projects by profitability (profit/contract_value)
    List<ProjectProfit> sorted = List.from(projects);
    sorted.sort((a, b) {
      double aRatio =
          (a.totalContractValue > 0) ? a.profit / a.totalContractValue : 0;
      double bRatio =
          (b.totalContractValue > 0) ? b.profit / b.totalContractValue : 0;
      return bRatio.compareTo(aRatio);
    });

    return Card(
      color: Colors.blueGrey.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Project Performance Leaderboard",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.blueGrey.shade900),
            ),
            SizedBox(height: 16),
            ...List.generate(sorted.length, (i) {
              final p = sorted[i];
              double profitability = (p.totalContractValue > 0)
                  ? (p.profit / p.totalContractValue) * 100
                  : 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    // Medal/Rank
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: _medalColor(i + 1),
                      child: Text(
                        "${i + 1}",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 14),
                    // Project Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.projectName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Profitability: ${profitability.toStringAsFixed(2)}%",
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    // Profit Value
                    Text(
                      "\$${p.profit.toStringAsFixed(0)}",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey.shade800,
                          fontSize: 15),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ================== Company Yearly Performance Line Chart ==================
class CompanyYearlyPerformanceChart extends StatelessWidget {
  final List<GovProfit> data;
  const CompanyYearlyPerformanceChart({required this.data, super.key});

  // For testing: use fake data if data is empty
  List<GovProfit> _getDisplayData() {
    // Use real data from the API
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final List<GovProfit> displayData = _getDisplayData();
    // Group by year and sum the difference for each year
    final Map<int, double> yearToDifference = {};
    for (final item in displayData) {
      if (item.year != null) {
        yearToDifference[item.year!] =
            (yearToDifference[item.year!] ?? 0) + item.difference;
      }
    }
    final years = yearToDifference.keys.toList()..sort();
    // Custom bottom titles: only show label if value is an integer index and there is a spot at that index
    SideTitles customBottomTitles = SideTitles(
      showTitles: true,
      getTitlesWidget: (value, meta) {
        int idx = value.round();
        // Only show if value is integer and there is a year at that index
        if ((value - idx).abs() > 0.01 || idx < 0 || idx >= years.length)
          return SizedBox();
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            years[idx].toString(),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        );
      },
      reservedSize: 36,
      interval: 1,
    );

    final maxY = yearToDifference.values.isEmpty
        ? 100.0
        : yearToDifference.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Company Yearly Performance",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.blue.shade900),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData:
                      FlGridData(show: true, horizontalInterval: maxY / 5),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: customBottomTitles,
                    ),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(years.length, (i) {
                        final year = years[i];
                        final diff = yearToDifference[year] ?? 0;
                        return FlSpot(i.toDouble(), diff);
                      }),
                      isCurved: true,
                      color: Color.fromARGB(255, 0, 0, 0),
                      barWidth: 4,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.teal.shade100.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

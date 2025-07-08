import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicle.dart';

class VehicleService {
  static const String baseUrl =
      'https://antiquewhite-cobra-422929.hostingersite.com/georgecode';
  static Future<List<Vehicle>> fetchVehicles() async {
    final response = await http.get(Uri.parse('$baseUrl/fetch_machin.php'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Vehicle.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load vehicles');
    }
  }

  static Map<String, int> getVehicleStatusCounts(List<Vehicle> vehicles) {
    int active = 0;
    int stopped = 0;
    int maintenance = 0;

    for (var vehicle in vehicles) {
      switch (vehicle.status.toLowerCase()) {
        case 'active':
          active++;
          break;
        case 'stop':
          stopped++;
          break;
        case 'maintenance':
          maintenance++;
          break;
      }
    }

    return {
      'active': active,
      'stopped': stopped,
      'maintenance': maintenance,
      'total': vehicles.length,
    };
  }
}

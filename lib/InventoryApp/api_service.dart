
import 'package:habibuios/InventoryApp/spare_part.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl =
      'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/inventory_management.php';

  static Future<List<SparePart>> getAllParts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?request=parts'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          List<SparePart> parts = (data['data'] as List)
              .map((item) => SparePart.fromJson(item))
              .toList();
          return parts;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching parts: $e');
      return [];
    }
  }

  static Future<List<SparePart>> getLowStockParts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?request=low_stock'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          List<SparePart> parts = (data['data'] as List)
              .map((item) => SparePart.fromJson(item))
              .toList();
          return parts;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching low stock parts: $e');
      return [];
    }
  }

  static Future<bool> addPart(SparePart part) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?request=add_part'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(part.toJson()),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'];
      }
      return false;
    } catch (e) {
      print('Error adding part: $e');
      return false;
    }
  }

  static Future<bool> updatePart(SparePart part) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl?request=update_part'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(part.toJson()),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'];
      }
      return false;
    } catch (e) {
      print('Error updating part: $e');
      return false;
    }
  }

  //admin

  static Future<List<SparePart>> getAllPartsbygovernorates(int id) async {
    try {
      final response = await http.get(Uri.parse(
          'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/admin/fetch_parts_by_gov_id.php?gov_id=$id'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          List<SparePart> parts = (data['data'] as List)
              .map((item) => SparePart.fromJson(item))
              .toList();
          return parts;
        }
        print('parts: ${data['data']}');
      }
      return [];
    } catch (e) {
      print('Error fetching parts: $e');
      return [];
    }
  }
}

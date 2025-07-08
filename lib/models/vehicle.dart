import 'package:flutter/material.dart';

class Vehicle {
  final int vehicleId;
  final String vehicleType;
  final String model;
  final String vehicleNumber;
  final String status;
  final String currentLocation;
  final int governorateId;
  final int createdBy;
  final String createdAt;
  final String updatedAt;
  final int? driverId;

  Vehicle({
    required this.vehicleId,
    required this.vehicleType,
    required this.model,
    required this.vehicleNumber,
    required this.status,
    required this.currentLocation,
    required this.governorateId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.driverId,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json['vehicle_id'],
      vehicleType: json['vehicle_type'],
      model: json['model'],
      vehicleNumber: json['vehicle_number'],
      status: json['status'],
      currentLocation: json['current_location'],
      governorateId: json['governorate_id'],
      createdBy: json['created_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      driverId: json['driver_id'],
    );
  }

  String getStatusInArabic() {
    switch (status.toLowerCase()) {
      case 'active':
        return 'active';
      case 'stop':
        return 'stop';
      case 'maintenance':
        return 'maintenance';
      default:
        return status;
    }
  }

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'stop':
        return Colors.red;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

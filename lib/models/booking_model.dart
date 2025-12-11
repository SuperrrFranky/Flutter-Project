import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String? id;
  final String userId;
  final String vehicleType;
  final String vehicleName;
  final String phoneNumber;
  final String serviceType;
  final List<String> serviceTypes;
  final DateTime preferredDateTime;
  final DateTime createdAt;
  final String status;
  final double totalAmount;
  final List<Map<String, dynamic>> serviceBreakdown;
  final DateTime? lastStatusUpdate;

  BookingModel({
    this.id,
    required this.userId,
    required this.vehicleType,
    required this.vehicleName,
    required this.phoneNumber,
    required this.serviceType,
    List<String>? serviceTypes,
    required this.preferredDateTime,
    DateTime? createdAt,
    this.status = 'pending',
    this.totalAmount = 0.0,
    List<Map<String, dynamic>>? serviceBreakdown,
    this.lastStatusUpdate,
  })  : serviceTypes = serviceTypes ?? const [],
        serviceBreakdown = serviceBreakdown ?? const [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'vehicleType': vehicleType,
      'vehicleName': vehicleName,
      'phoneNumber': phoneNumber,
      'serviceType': serviceType,
      'serviceTypes': serviceTypes,
      'preferredDateTime': preferredDateTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'totalAmount': totalAmount,
      'serviceBreakdown': serviceBreakdown,
      'lastStatusUpdate': lastStatusUpdate?.toIso8601String(),
    };
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      userId: json['userId'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      vehicleName: json['vehicleName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      serviceType: json['serviceType'] ?? '',
      serviceTypes: (json['serviceTypes'] as List?)?.map((e) => e.toString()).toList() ??
          (json['serviceType'] != null ? <String>[json['serviceType']] : <String>[]),
      preferredDateTime: DateTime.parse(json['preferredDateTime']),
      createdAt: DateTime.parse(json['createdAt']),
      status: json['status'] ?? 'pending',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      serviceBreakdown: (json['serviceBreakdown'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      lastStatusUpdate: json['lastStatusUpdate'] != null 
          ? DateTime.parse(json['lastStatusUpdate']) 
          : null,
    );
  }

  // Firebase-specific methods
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'vehicleType': vehicleType,
      'vehicleName': vehicleName,
      'phoneNumber': phoneNumber,
      'serviceType': serviceType,
      'serviceTypes': serviceTypes,
      'preferredDateTime': Timestamp.fromDate(preferredDateTime),
      'status': status,
      'totalAmount': totalAmount,
      'serviceBreakdown': serviceBreakdown,
      'lastStatusUpdate': lastStatusUpdate != null 
          ? Timestamp.fromDate(lastStatusUpdate!) 
          : null,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BookingModel(
      id: documentId,
      userId: map['userId'] ?? '',
      vehicleType: map['vehicleType'] ?? '',
      vehicleName: map['vehicleName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      serviceType: map['serviceType'] ?? '',
      serviceTypes: (map['serviceTypes'] as List?)?.map((e) => e.toString()).toList() ??
          (map['serviceType'] != null ? <String>[map['serviceType']] : <String>[]),
      preferredDateTime: (map['preferredDateTime'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      serviceBreakdown: (map['serviceBreakdown'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      lastStatusUpdate: map['lastStatusUpdate'] != null 
          ? (map['lastStatusUpdate'] as Timestamp).toDate() 
          : null,
    );
  }

  BookingModel copyWith({
    String? id,
    String? userId,
    String? vehicleType,
    String? vehicleName,
    String? phoneNumber,
    String? serviceType,
    List<String>? serviceTypes,
    DateTime? preferredDateTime,
    DateTime? createdAt,
    String? status,
    double? totalAmount,
    List<Map<String, dynamic>>? serviceBreakdown,
    DateTime? lastStatusUpdate,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleName: vehicleName ?? this.vehicleName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      serviceType: serviceType ?? this.serviceType,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      preferredDateTime: preferredDateTime ?? this.preferredDateTime,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      serviceBreakdown: serviceBreakdown ?? this.serviceBreakdown,
      lastStatusUpdate: lastStatusUpdate ?? this.lastStatusUpdate,
    );
  }
}

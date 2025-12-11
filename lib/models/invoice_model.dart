import 'package:assignment/models/service_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//invoice model
class Invoice {
  final String invoiceId;
  final String userId;
  final String carType;
  final String carModel;
  final String? paymentMethod;
  final DateTime invoiceDate;
  final DateTime? paymentDate;
  final String bookingId;
  final String serviceLocation;
  final DateTime serviceDate;
  double? discount;
  final double totalAmount;
  final String status;
  final List<ServiceItem> services;

  Invoice({
    required this.invoiceId,
    required this.userId,
    required this.carType,
    required this.carModel,
    this.paymentMethod,
    required this.invoiceDate,
    this.paymentDate,
    required this.bookingId,
    required this.serviceLocation,
    required this.serviceDate,
    this.discount,
    required this.totalAmount,
    required this.status,
    required this.services,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceId: json['invoiceId'],
      userId: json['userId'],
      carType: json['carType'],
      carModel: json['carModel'],
      paymentMethod: json['paymentMethod'],
      invoiceDate: (json['invoiceDate'] as Timestamp).toDate(),
      paymentDate: json['paymentDate'] != null
          ? (json['paymentDate'] as Timestamp).toDate()
          : null,
      bookingId: json['bookingId'],
      serviceLocation: json['serviceLocation'],
      serviceDate: (json['serviceDate'] as Timestamp).toDate(),
        discount: (json['discount'] as num?)?.toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'],
      services: (json['services'] as List<dynamic>)
          .map((item) => ServiceItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceId': invoiceId,
      'userId': userId,
      'carType': carType,
      'carModel': carModel,
      'paymentMethod': paymentMethod,
      'invoiceDate': invoiceDate,
      'paymentDate': paymentDate,
      'bookingId': bookingId,
      'serviceLocation': serviceLocation,
      'serviceDate': serviceDate,
      'discount': discount,
      'totalAmount': totalAmount,
      'status': status,
      'services': services.map((s) => s.toJson()).toList(),
    };
  }
}

class VehicleModel {
  final String? vehicleId;
  final String userId;
  final String vehicleType;
  final String vehicleName;
  final String? vehiclePhoto; // file path or URL
  final int mileage;
  final String nickName;
  final String vehiclePlateNum;

  VehicleModel({
    this.vehicleId,
    required this.userId,
    required this.vehicleType,
    required this.vehicleName,
    this.vehiclePhoto,
    required this.mileage,
    required this.nickName,
    required this.vehiclePlateNum,
  });

  String get displayName => '$vehicleName - $nickName';
  String get mileageDisplay {
    final formatted = mileage
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => (m[1] ?? '') + ',');
    return '$formatted km';
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'user_id': userId,
      'vehicle_type': vehicleType,
      'vehicle_name': vehicleName,
      'vehicle_photo': vehiclePhoto,
      'mileage': mileage,
      'nick_name': nickName,
      'vehicle_plate_num': vehiclePlateNum,
    };
  }

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      vehicleId: json['vehicle_id'],
      userId: json['user_id'] ?? '',
      vehicleType: json['vehicle_type'] ?? '',
      vehicleName: json['vehicle_name'] ?? '',
      vehiclePhoto: json['vehicle_photo'],
      mileage: (json['mileage'] is int)
          ? json['mileage'] as int
          : int.tryParse('${json['mileage']}') ?? 0,
      nickName: json['nick_name'] ?? '',
      vehiclePlateNum: (json['vehicle_plate_num'] ?? json['plate'] ?? '').toString(),
    );
  }

  VehicleModel copyWith({
    String? vehicleId,
    String? userId,
    String? vehicleType,
    String? vehicleName,
    String? vehiclePhoto,
    int? mileage,
    String? nickName,
    String? vehiclePlateNum,
  }) {
    return VehicleModel(
      vehicleId: vehicleId ?? this.vehicleId,
      userId: userId ?? this.userId,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleName: vehicleName ?? this.vehicleName,
      vehiclePhoto: vehiclePhoto ?? this.vehiclePhoto,
      mileage: mileage ?? this.mileage,
      nickName: nickName ?? this.nickName,
      vehiclePlateNum: vehiclePlateNum ?? this.vehiclePlateNum,
    );
  }
}

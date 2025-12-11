class VoucherModel {
  final String? voucherId;
  final String userId;
  final DateTime expiredDate;
  final int value;

  VoucherModel({
    this.voucherId,
    required this.userId,
    required this.expiredDate,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'voucher_id': voucherId,
      'user_id': userId,
      'expired_date': expiredDate.toIso8601String(),
      'value': value,
    };
  }

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    DateTime parseExpired(dynamic v) {
      if (v == null) return DateTime.now();
      // Support Firestore Timestamp-like object
      if (v is DateTime) return v;
      final maybe = v.toString();
      return DateTime.tryParse(maybe) ?? DateTime.now();
    }

    return VoucherModel(
      voucherId: json['voucher_id'],
      userId: json['user_id'] ?? '',
      expiredDate: parseExpired(json['expired_date']),
      value: (json['value'] is int)
          ? json['value'] as int
          : int.tryParse('${json['value']}') ?? 0,
    );
  }

  VoucherModel copyWith({
    String? voucherId,
    String? userId,
    DateTime? expiredDate,
    int? value,
  }) {
    return VoucherModel(
      voucherId: voucherId ?? this.voucherId,
      userId: userId ?? this.userId,
      expiredDate: expiredDate ?? this.expiredDate,
      value: value ?? this.value,
    );
  }
}



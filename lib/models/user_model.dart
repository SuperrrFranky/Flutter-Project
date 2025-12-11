class UserModel {
  final String? userId;
  final String userName;
  final String password;
  final String email;
  final String phoneNo;
  final String address;
  final String? userPhoto; // file path or URL
  final int point;

  UserModel({
    this.userId,
    required this.userName,
    this.password = '',
    required this.email,
    required this.phoneNo,
    required this.address,
    this.userPhoto,
    this.point = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'password': '', // Always empty - Firebase Auth handles passwords
      'email': email,
      'phoneNo': phoneNo,
      'address': address,
      'user_photo': userPhoto,
      'point': point,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'],
      userName: json['user_name'] ?? '',
      password: '', // Always empty - Firebase Auth handles passwords
      email: json['email'] ?? '',
      phoneNo: json['phoneNo'] ?? '',
      address: json['address'] ?? '',
      userPhoto: json['user_photo'],
      point: (json['point'] is int)
          ? json['point'] as int
          : int.tryParse('${json['point']}') ?? 0,
    );
  }

  UserModel copyWith({
    String? userId,
    String? userName,
    String? password,
    String? email,
    String? phoneNo,
    String? address,
    String? userPhoto,
    int? point,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      password: password ?? this.password,
      email: email ?? this.email,
      phoneNo: phoneNo ?? this.phoneNo,
      address: address ?? this.address,
      userPhoto: userPhoto ?? this.userPhoto,
      point: point ?? this.point,
    );
  }
}



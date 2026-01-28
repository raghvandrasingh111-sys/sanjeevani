class UserModel {
  final String id;
  final String email;
  final String name;
  final String userType; // 'patient' or 'doctor'
  final String? phone;
  final String? profileImageUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    this.phone,
    this.profileImageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      userType: json['user_type'] as String,
      phone: json['phone'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'user_type': userType,
      'phone': phone,
      'profile_image_url': profileImageUrl,
    };
  }
}

class User{
  final String id;
  final String phone;
  final String name;
  final String? email;
  final String userType;
  final String? profilePhotoUrl;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.phone,
    required this.name,
    this.email,
    required this.userType,
    this.profilePhotoUrl,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'],
      name: json['name'],
      email: json['email'],
      userType: json['user_type'],
      profilePhotoUrl: json['profile_photo_url'],
      isVerified: json['is_verified'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return{
      'id': id,
      'phone': phone,
      'name': name,
      'email': email,
      'user_type': userType,
      'profile_photo_url': profilePhotoUrl,
      'is_verified': isVerified,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
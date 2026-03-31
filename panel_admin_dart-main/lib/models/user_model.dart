class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      role: json['role'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName'.trim();
}

class LoginResponse {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final User? user;
  final String? message;

  LoginResponse({
    required this.success,
    this.accessToken,
    this.refreshToken,
    this.user,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json, {bool successOverride = true}) {
    return LoginResponse(
      success: successOverride,
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      message: json['message'],
    );
  }
}

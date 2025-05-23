// class User {
//   final String id;
//   final String email;
//   final String role;
//   final DateTime createdAt;
//   final DateTime updatedAt;

//   User({
//     required this.id,
//     required this.email,
//     required this.role,
//     required this.createdAt,
//     required this.updatedAt,
//   });

//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       id: json['_id'],
//       email: json['email'],
//       role: json['role'],
//       createdAt: DateTime.parse(json['createdAt']),
//       updatedAt: DateTime.parse(json['updatedAt']),
//     );
//   }

//   Map<String, dynamic> toUpdateJson() {
//     return {
//       'email': email,
//       'role': role,
//     };
//   }
// }

class User {
  final String id;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '', // Xử lý null
      email: json['email'] ?? '', // Xử lý null
      role: json['role'] ?? 'user', // Giá trị mặc định nếu null
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(), // Giá trị mặc định
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(), // Giá trị mặc định
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'email': email,
      'role': role,
    };
  }
}
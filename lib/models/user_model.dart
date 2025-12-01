import 'package:hive/hive.dart';
part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  String email;

  @HiveField(2)
  String password; // Password yang sudah di-hash

  @HiveField(3)
  DateTime createdAt;

   @HiveField(4) // 
  String? avatarPath;

  UserModel({
    required this.username,
    required this.email,
    required this.password,
    required this.createdAt,
    this.avatarPath, 
  });

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
      'avatarPath': avatarPath,
    };
  }

  // Create from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      username: map['username'],
      email: map['email'],
      password: map['password'],
      createdAt: DateTime.parse(map['createdAt']),
      avatarPath: map['avatarPath'],
    );
  }
}
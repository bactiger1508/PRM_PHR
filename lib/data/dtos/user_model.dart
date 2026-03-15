import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    super.id,
    super.email,
    super.phone,
    super.passwordHash,
    super.fullName,
    required super.role,
    super.status,
    super.createdAt,
    super.updatedAt,
    super.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      phone: json['phone'],
      passwordHash: json['password_hash'],
      fullName: json['full_name'],
      role: json['role'],
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'])
          : null,
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'email': email,
      'phone': phone,
      'password_hash': passwordHash,
      'full_name': fullName,
      'role': role,
      'status': status,
      'created_at': createdAt?.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
      'avatar': avatar,
    };
  }
}

class UserEntity {
  final int? id;
  final String? email;
  final String? phone;
  final String? passwordHash;
  final String? fullName;
  final String role;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? avatar;

  UserEntity({
    this.id,
    this.email,
    this.phone,
    this.passwordHash,
    this.fullName,
    required this.role,
    this.status = 'ACTIVE',
    this.createdAt,
    this.updatedAt,
    this.avatar,
  });
}

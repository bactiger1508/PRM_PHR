class PatientEntity {
  final int? id;
  final String medicalCode;
  final String? accessCode;
  final String fullName;
  final String? dob; // Changed from int? age
  final String? phone;
  final String? email;
  final String status;
  final int? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PatientEntity({
    this.id,
    required this.medicalCode,
    this.accessCode,
    required this.fullName,
    this.dob,
    this.phone,
    this.email,
    this.status = 'ACTIVE',
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });
}

import '../../domain/entities/patient_entity.dart';

class PatientModel extends PatientEntity {
  PatientModel({
    super.id,
    required super.medicalCode,
    super.accessCode,
    required super.fullName,
    super.dob,
    super.phone,
    super.email,
    super.status,
    super.createdBy,
    super.createdAt,
    super.updatedAt,
    super.familyId,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'],
      medicalCode: json['medical_code'],
      accessCode: json['access_code'],
      fullName: json['full_name'],
      dob: json['dob'],
      phone: json['phone'],
      email: json['email'],
      status: json['status'] ?? 'ACTIVE',
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'])
          : null,
      familyId: json['family_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'medical_code': medicalCode,
      'access_code': accessCode,
      'full_name': fullName,
      'dob': dob,
      'phone': phone,
      'email': email,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt?.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
      'family_id': familyId,
    };
  }
}

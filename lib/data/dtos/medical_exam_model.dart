import 'dart:convert';
import '../../domain/entities/medical_exam_entity.dart';

class MedicalExamModel extends MedicalExamEntity {
  MedicalExamModel({
    super.id,
    required super.patientProfileId,
    super.patientName,
    super.patientMedicalCode,
    required super.examDate,
    super.diagnosis,
    super.symptoms,
    super.vitalSigns,
    super.prescription,
    super.notes,
    super.followUpDate,
    super.status,
    super.createdBy,
    super.createdByName,
    super.createdAt,
    super.updatedAt,
  });

  /// Parse từ row của bảng medical_documents (notes chứa JSON dữ liệu khám)
  factory MedicalExamModel.fromJson(Map<String, dynamic> json) {
    // Parse notes JSON để lấy dữ liệu khám bệnh
    Map<String, dynamic> examData = {};
    if (json['notes'] != null) {
      try {
        examData = jsonDecode(json['notes']) as Map<String, dynamic>;
      } catch (_) {
        examData = {'notes': json['notes']};
      }
    }

    return MedicalExamModel(
      id: json['id'],
      patientProfileId: json['patient_profile_id'],
      patientName: json['patient_name'],
      patientMedicalCode: json['patient_medical_code'],
      examDate: examData['exam_date'] ?? '',
      diagnosis: examData['diagnosis'],
      symptoms: examData['symptoms'],
      vitalSigns: examData['vital_signs'],
      prescription: examData['prescription'],
      notes: examData['notes'],
      followUpDate: examData['follow_up_date'],
      status: json['status'] ?? 'COMPLETED',
      createdBy: json['created_by'],
      createdByName: json['created_by_name'],
      createdAt: json['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'])
          : null,
    );
  }

  /// Chuyển thành map để insert vào bảng medical_documents
  Map<String, dynamic> toDocumentJson(int categoryId) {
    final examData = jsonEncode({
      'exam_date': examDate,
      'diagnosis': diagnosis,
      'symptoms': symptoms,
      'vital_signs': vitalSigns,
      'prescription': prescription,
      'follow_up_date': followUpDate,
      'notes': notes,
    });

    return {
      if (id != null) 'id': id,
      'patient_profile_id': patientProfileId,
      'category_id': categoryId,
      'record_date': createdAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      'title': 'Đơn khám bệnh - $examDate',
      'notes': examData,
      'status': status,
      'is_deleted': 0,
      'created_by': createdBy,
      'created_at': createdAt?.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }
}

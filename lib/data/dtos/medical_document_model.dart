import '../../domain/entities/medical_document_entity.dart';

class MedicalDocumentModel extends MedicalDocumentEntity {
  MedicalDocumentModel({
    super.id,
    required super.patientProfileId,
    required super.categoryId,
    super.categoryName,
    super.patientName,
    super.medicalCode,
    super.recordDate,
    super.title,
    super.notes,
    super.status,
    super.isDeleted,
    super.createdBy,
    super.createdByName,
    super.createdAt,
    super.updatedAt,
    super.files,
    super.tags,
  });

  factory MedicalDocumentModel.fromJson(Map<String, dynamic> json,
      {List<DocumentFileEntity> files = const [],
      List<String> tags = const []}) {
    return MedicalDocumentModel(
      id: json['id'],
      patientProfileId: json['patient_profile_id'],
      categoryId: json['category_id'] ?? 1,
      categoryName: json['category_name'],
      patientName: json['patient_name'],
      medicalCode: json['medical_code'],
      recordDate: json['record_date'],
      title: json['title'],
      notes: json['notes'],
      status: json['status'] ?? 'SAVED',
      isDeleted: json['is_deleted'] ?? 0,
      createdBy: json['created_by'],
      createdByName: json['created_by_name'],
      createdAt: json['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'])
          : null,
      files: files,
      tags: tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patient_profile_id': patientProfileId,
      'category_id': categoryId,
      'record_date': recordDate,
      'title': title,
      'notes': notes,
      'status': status,
      'is_deleted': isDeleted,
      'created_by': createdBy,
      'created_at': createdAt?.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }
}

class DocumentFileModel extends DocumentFileEntity {
  DocumentFileModel({
    super.id,
    super.documentId,
    required super.filePath,
    super.fileType,
    super.fileSize,
    super.createdAt,
  });

  factory DocumentFileModel.fromJson(Map<String, dynamic> json) {
    return DocumentFileModel(
      id: json['id'],
      documentId: json['document_id'],
      filePath: json['file_path'] ?? '',
      fileType: json['file_type'],
      fileSize: json['file_size'],
      createdAt: json['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'document_id': documentId,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
      'created_at': createdAt?.millisecondsSinceEpoch,
    };
  }
}

/// Entity đại diện cho một Tài liệu Y tế (Medical Document)
class MedicalDocumentEntity {
  final int? id;
  final int patientProfileId;
  final int categoryId; // 1: Xét nghiệm, 2: Đơn thuốc, 3: Chẩn đoán
  final String? categoryName; // Để hiển thị
  final String? patientName; // Để hiển thị/tìm kiếm
  final String? medicalCode; // Để hiển thị/tìm kiếm
  final int? recordDate; // timestamp
  final String? title;
  final String? notes;
  final String status; // SAVED, DELETED
  final int isDeleted;
  final int? createdBy;
  final String? createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Quan hệ
  final List<DocumentFileEntity> files;
  final List<String> tags;

  MedicalDocumentEntity({
    this.id,
    required this.patientProfileId,
    required this.categoryId,
    this.categoryName,
    this.patientName,
    this.medicalCode,
    this.recordDate,
    this.title,
    this.notes,
    this.status = 'SAVED',
    this.isDeleted = 0,
    this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
    this.files = const [],
    this.tags = const [],
  });
}

/// Entity cho file đính kèm
class DocumentFileEntity {
  final int? id;
  final int? documentId;
  final String filePath;
  final String? fileType; // image/jpeg, image/png, application/pdf
  final int? fileSize;
  final DateTime? createdAt;

  DocumentFileEntity({
    this.id,
    this.documentId,
    required this.filePath,
    this.fileType,
    this.fileSize,
    this.createdAt,
  });
}

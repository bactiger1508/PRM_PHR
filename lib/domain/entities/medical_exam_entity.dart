/// Entity đại diện cho một Đơn Khám Bệnh (Medical Examination Form)
class MedicalExamEntity {
  final int? id;
  final int patientProfileId;
  final String? patientName; // Để hiển thị, không lưu DB
  final String? patientMedicalCode; // Để hiển thị
  final String examDate; // Ngày khám dd/MM/yyyy
  final String? diagnosis; // Chẩn đoán
  final String? symptoms; // Triệu chứng
  final String? vitalSigns; // Dấu hiệu sinh tồn (mạch, huyết áp, nhiệt độ, cân nặng...)
  final String? prescription; // Đơn thuốc
  final String? notes; // Ghi chú thêm
  final String? followUpDate; // Ngày tái khám
  final String status; // DRAFT, COMPLETED, CANCELLED
  final int? createdBy; // Staff ID
  final String? createdByName; // Để hiển thị
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MedicalExamEntity({
    this.id,
    required this.patientProfileId,
    this.patientName,
    this.patientMedicalCode,
    required this.examDate,
    this.diagnosis,
    this.symptoms,
    this.vitalSigns,
    this.prescription,
    this.notes,
    this.followUpDate,
    this.status = 'COMPLETED',
    this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
  });
}

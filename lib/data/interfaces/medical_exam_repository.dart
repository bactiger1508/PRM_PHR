import '../../domain/entities/medical_exam_entity.dart';

abstract class MedicalExamRepository {
  /// Tạo đơn khám mới cho bệnh nhân
  Future<int> createMedicalExam(MedicalExamEntity exam);

  /// Lấy danh sách đơn khám theo Patient Profile ID
  Future<List<MedicalExamEntity>> getExamsByPatient(int patientProfileId);

  /// Lấy tất cả đơn khám (cho staff xem)
  Future<List<MedicalExamEntity>> getAllExams();

  /// Lấy chi tiết đơn khám theo ID
  Future<MedicalExamEntity?> getExamById(int examId);

  /// Cập nhật đơn khám
  Future<bool> updateExam(MedicalExamEntity exam);

  /// Xóa đơn khám (soft delete)
  Future<bool> deleteExam(int examId);
}

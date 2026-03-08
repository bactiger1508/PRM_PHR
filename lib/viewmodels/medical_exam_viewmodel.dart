import 'package:flutter/foundation.dart';
import '../data/implementations/medical_exam_repository_impl.dart';
import '../domain/entities/medical_exam_entity.dart';

class MedicalExamViewModel extends ChangeNotifier {
  final MedicalExamRepositoryImpl _examRepo;

  MedicalExamViewModel({MedicalExamRepositoryImpl? examRepo})
    : _examRepo = examRepo ?? MedicalExamRepositoryImpl();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  String? _errorMsg;
  String? get errorMsg => _errorMsg;

  List<MedicalExamEntity> _exams = [];
  List<MedicalExamEntity> get exams => _exams;

  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> get patients => _patients;

  MedicalExamEntity? _currentExam;
  MedicalExamEntity? get currentExam => _currentExam;

  /// Tạo đơn khám mới
  Future<bool> createExam({
    required int patientProfileId,
    required String examDate,
    String? diagnosis,
    String? symptoms,
    String? vitalSigns,
    String? prescription,
    String? notes,
    String? followUpDate,
    required int createdByStaffId,
  }) async {
    if (examDate.isEmpty) {
      _errorMsg = 'Ngày khám là bắt buộc.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMsg = null;
    notifyListeners();

    try {
      await _examRepo.createMedicalExam(
        MedicalExamEntity(
          patientProfileId: patientProfileId,
          examDate: examDate,
          diagnosis: diagnosis,
          symptoms: symptoms,
          vitalSigns: vitalSigns,
          prescription: prescription,
          notes: notes,
          followUpDate: followUpDate,
          status: 'COMPLETED',
          createdBy: createdByStaffId,
        ),
      );

      _isSuccess = true;
      return true;
    } catch (e) {
      _errorMsg = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lấy danh sách bệnh nhân để chọn
  Future<void> loadPatients() async {
    _isLoading = true;
    notifyListeners();

    try {
      _patients = await _examRepo.getPatientList();
    } catch (e) {
      _errorMsg = 'Không thể tải danh sách bệnh nhân.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lấy danh sách đơn khám theo bệnh nhân
  Future<void> loadExamsByPatient(int patientProfileId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _exams = await _examRepo.getExamsByPatient(patientProfileId);
    } catch (e) {
      _errorMsg = 'Không thể tải danh sách đơn khám.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lấy tất cả đơn khám
  Future<void> loadAllExams() async {
    _isLoading = true;
    notifyListeners();

    try {
      _exams = await _examRepo.getAllExams();
    } catch (e) {
      _errorMsg = 'Không thể tải danh sách đơn khám.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xóa đơn khám
  Future<bool> deleteExam(int examId) async {
    try {
      final result = await _examRepo.deleteExam(examId);
      if (result) {
        _exams.removeWhere((e) => e.id == examId);
        notifyListeners();
      }
      return result;
    } catch (e) {
      _errorMsg = 'Không thể xóa đơn khám.';
      notifyListeners();
      return false;
    }
  }

  void clearState() {
    _isSuccess = false;
    _errorMsg = null;
    notifyListeners();
  }
}

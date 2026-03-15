import 'package:flutter/foundation.dart';
import '../data/implementations/patient_repository_impl.dart';
import '../data/interfaces/patient_repository.dart';
import '../domain/entities/patient_entity.dart';

class CreatePatientViewModel extends ChangeNotifier {
  final PatientRepository _patientRepo;

  CreatePatientViewModel({PatientRepository? patientRepo})
    : _patientRepo = patientRepo ?? PatientRepositoryImpl();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  String? _errorMsg;
  String? get errorMsg => _errorMsg;

  String _successMedicalCode = '';
  String get successMedicalCode => _successMedicalCode;

  String? _accessCode;
  String? get accessCode => _accessCode;

  Future<bool> createPatient({
    required String fullName,
    required String dob,
    required String phone,
    required String email,
    required int createdByStaffId,
  }) async {
    if (fullName.isEmpty || dob.isEmpty) {
      _errorMsg = 'Họ tên và Ngày sinh là bắt buộc.';
      notifyListeners();
      return false;
    }

    if (email.isNotEmpty && !email.contains('@')) {
      _errorMsg = 'Email không hợp lệ.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMsg = null;
    notifyListeners();

    try {
      final newCode = await _patientRepo.createPatientAndAccount(
        PatientEntity(
          medicalCode: '', 
          fullName: fullName,
          dob: dob,
          phone: phone,
          email: email.isEmpty ? null : email,
          createdBy: createdByStaffId,
        ),
      );

      _isSuccess = true;
      _successMedicalCode = newCode;
      return true;
    } catch (e) {
      _errorMsg = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearState() {
    _isSuccess = false;
    _errorMsg = null;
    _accessCode = null;
    notifyListeners();
  }

  Future<void> generateAccessCode() async {
    if (_successMedicalCode.isEmpty) return;
    
    _isLoading = true;
    _errorMsg = null;
    notifyListeners();

    try {
      _accessCode = await _patientRepo.generateAccessCode(_successMedicalCode);
    } catch (e) {
      _errorMsg = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

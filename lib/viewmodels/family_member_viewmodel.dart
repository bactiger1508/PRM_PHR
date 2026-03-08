import 'package:flutter/foundation.dart';
import '../data/implementations/patient_repository_impl.dart';
import '../data/interfaces/patient_repository.dart';

class FamilyMemberViewModel extends ChangeNotifier {
  final PatientRepository _patientRepo;

  FamilyMemberViewModel({PatientRepository? patientRepo})
      : _patientRepo = patientRepo ?? PatientRepositoryImpl();

  List<Map<String, dynamic>> _familyMembers = [];
  List<Map<String, dynamic>> get familyMembers => _familyMembers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchFamilyMembers(int customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _familyMembers = await _patientRepo.getFamilyMembers(customerId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> linkMember({
    required int customerId,
    required String medicalCode,
    required String accessCode,
    required String relationship,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _patientRepo.linkFamilyMember(customerId, medicalCode, accessCode, relationship);
      if (success) {
        await fetchFamilyMembers(customerId);
      }
      return success;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

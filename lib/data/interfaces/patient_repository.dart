import '../../domain/entities/patient_entity.dart';

abstract class PatientRepository {
  /// Creates a Patient Profile and automatically creates a Customer User Account
  /// Returns the newly created Medical Code or Patient ID.
  Future<String> createPatientAndAccount(PatientEntity patient);

  /// Fetches a patient profile by email
  Future<PatientEntity?> getPatientByEmail(String email);

  /// Updates patient profile information (DOB, Phone)
  Future<bool> updatePatientProfile(int patientId, {String? dob, String? phone});
}

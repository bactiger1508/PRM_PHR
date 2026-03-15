import 'package:phrprmgroupproject/data/db/database_helper.dart';
import '../../domain/entities/patient_entity.dart';
import '../../domain/entities/user_entity.dart';

abstract class PatientRepository {
  /// Creates a Patient Profile and automatically creates a Customer User Account
  /// Returns the newly created Medical Code or Patient ID.
  Future<String> createPatientAndAccount(PatientEntity patient);

  /// Fetches a patient profile by phone or email
  Future<PatientEntity?> getPatientByPhoneOrEmail({String? phone, String? email});

  /// Updates patient profile information (DOB, Phone)
  Future<bool> updatePatientProfile(int patientId, {String? dob, String? phone});

  /// Generates a 6-digit access code for family linking
  Future<String> generateAccessCode(String medicalCode);

  /// Links a patient to a customer account
  Future<bool> linkFamilyMember(int customerId, String medicalCode, String accessCode, String relationship);

  /// Fetches all linked patient profiles for a customer
  Future<List<Map<String, dynamic>>> getFamilyMembers(int customerId);

  Future<DashboardStats> getStats();

  Future<List<UserEntity>> getAllCustomers();
}

import 'dart:math';
import 'package:intl/intl.dart';
import '../../core/utils/hash_utils.dart';
import '../../core/services/email_service.dart';
import '../../domain/entities/patient_entity.dart';
import '../interfaces/patient_repository.dart';
import '../db/database_helper.dart';
import '../dtos/patient_model.dart';
import 'package:sqflite/sqflite.dart';

class PatientRepositoryImpl implements PatientRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final EmailService _emailService = EmailService();

  @override
  Future<String> createPatientAndAccount(PatientEntity patient) async {
    final db = await _dbHelper.database;

    // 1. Generate Medical Code
    String cleanDob = (patient.dob ?? '').replaceAll('/', '');
    if (cleanDob.isEmpty) cleanDob = '00000000';
    String today = DateFormat('ddMMyyyy').format(DateTime.now());
    String prefix = 'PHR-$cleanDob-$today';
    final existing = await db.query('patient_profiles', columns: ['medical_code'], where: 'medical_code LIKE ?', whereArgs: ['$prefix%']);
    int sequence = existing.length + 1;
    String medicalCode = '$prefix-${sequence.toString().padLeft(2, '0')}';

    final String? email = (patient.email != null && patient.email!.trim().isNotEmpty) ? patient.email!.trim() : null;
    final String? phone = (patient.phone != null && patient.phone!.trim().isNotEmpty) ? patient.phone!.trim() : null;

    int? userId;

    await db.transaction((txn) async {
      if (email != null || phone != null) {
        Map<String, dynamic> userMap = {
          'email': email,
          'phone': phone,
          'full_name': patient.fullName,
          'password_hash': HashUtils.hashPassword('123456'),
          'role': 'CUSTOMER',
          'status': 'ACTIVE',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        };
        try {
          userId = await txn.insert('user_accounts', userMap, conflictAlgorithm: ConflictAlgorithm.fail);
        } catch (e) {
          if (e is DatabaseException && e.isUniqueConstraintError()) {
            // Check specifically what conflicted
            if (email != null) {
              final emailConflict = await txn.query('user_accounts', where: 'email = ?', whereArgs: [email]);
              if (emailConflict.isNotEmpty) {
                final res = await txn.query('patient_profiles', columns: ['medical_code'], where: 'email = ?', whereArgs: [email]);
                throw Exception(res.isNotEmpty 
                  ? 'Email này đã được đăng ký hồ sơ. Mã Y Tế: ${res.first['medical_code']}' 
                  : 'Email này đã được sử dụng cho một tài khoản khác.');
              }
            }
            if (phone != null) {
              final phoneConflict = await txn.query('user_accounts', where: 'phone = ?', whereArgs: [phone]);
              if (phoneConflict.isNotEmpty) {
                final res = await txn.query('patient_profiles', columns: ['medical_code'], where: 'phone = ?', whereArgs: [phone]);
                throw Exception(res.isNotEmpty 
                  ? 'Số điện thoại này đã được đăng ký hồ sơ. Mã Y Tế: ${res.first['medical_code']}' 
                  : 'Số điện thoại này đã được sử dụng cho một tài khoản khác.');
              }
            }
            throw Exception('Thông tin Email hoặc Số điện thoại đã tồn tại trên hệ thống.');
          }
          rethrow;
        }
      }

      PatientModel model = PatientModel(
        medicalCode: medicalCode,
        fullName: patient.fullName,
        dob: patient.dob,
        phone: patient.phone,
        email: patient.email,
        status: 'ACTIVE',
        createdBy: patient.createdBy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final patientId = await txn.insert('patient_profiles', model.toJson());

      // 3. Link "Self" relationship if user account was created
      if (userId != null) {
        await txn.insert('family_access', {
          'customer_account_id': userId,
          'patient_profile_id': patientId,
          'relationship': 'Bản thân',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });

    if (patient.email != null && patient.email!.isNotEmpty) {
      _emailService.sendWelcomeEmail(toEmail: patient.email!, defaultPassword: '123456', patientName: patient.fullName);
    }

    return medicalCode;
  }

  @override
  Future<String> generateAccessCode(String medicalCode) async {
    final db = await _dbHelper.database;
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String code = '';
    bool isUnique = false;

    // Loop until we find a globally unique 6-character code
    while (!isUnique) {
      code = String.fromCharCodes(
          Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
      
      final existing = await db.query(
        'patient_profiles',
        columns: ['id'],
        where: 'access_code = ?',
        whereArgs: [code],
      );
      
      if (existing.isEmpty) {
        isUnique = true;
      }
    }

    await db.update(
      'patient_profiles',
      {'access_code': code, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'medical_code = ?',
      whereArgs: [medicalCode],
    );
    return code;
  }

  @override
  Future<PatientEntity?> getPatientByPhoneOrEmail({String? phone, String? email}) async {
    final db = await _dbHelper.database;
    
    if ((phone == null || phone.isEmpty) && (email == null || email.isEmpty)) {
      return null;
    }

    List<String> conditions = [];
    List<dynamic> args = [];

    if (email != null && email.isNotEmpty) {
      conditions.add('email = ?');
      args.add(email);
    }
    if (phone != null && phone.isNotEmpty) {
      conditions.add('phone = ?');
      args.add(phone);
    }

    final String queryWhere = conditions.join(' OR ');
    
    final List<Map<String, dynamic>> maps = await db.query(
      'patient_profiles', 
      where: queryWhere, 
      whereArgs: args,
    );
    
    return maps.isNotEmpty ? PatientModel.fromJson(maps.first) : null;
  }

  @override
  Future<bool> updatePatientProfile(int patientId, {String? dob, String? phone}) async {
    final db = await _dbHelper.database;
    final Map<String, dynamic> values = {'updated_at': DateTime.now().millisecondsSinceEpoch};
    if (dob != null) values['dob'] = dob;
    if (phone != null) values['phone'] = phone;
    final count = await db.update('patient_profiles', values, where: 'id = ?', whereArgs: [patientId]);
    return count > 0;
  }

  @override
  Future<bool> linkFamilyMember(int customerId, String medicalCode, String accessCode, String relationship) async {
    final db = await _dbHelper.database;
    
    // 1. Verify medical code and access code
    final patients = await db.query(
      'patient_profiles',
      where: 'medical_code = ? AND access_code = ?',
      whereArgs: [medicalCode, accessCode],
    );
    
    if (patients.isEmpty) {
      throw Exception('Mã y tế hoặc mã truy cập không chính xác.');
    }
    
    final linkedPatientId = patients.first['id'] as int;
    final linkedPatientEmail = patients.first['email'] as String?;
    final linkedPatientPhone = patients.first['phone'] as String?;
    
    // 2. Insert into family_access (Linker -> Linked Person)
    await db.insert('family_access', {
      'customer_account_id': customerId,
      'patient_profile_id': linkedPatientId,
      'relationship': relationship,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // 3. RECIPROCAL LINKING (Linked Person -> Linker)
    // Find if the linked person has a customer account
    if (linkedPatientEmail != null || linkedPatientPhone != null) {
      final linkedUserAccounts = await db.query(
        'user_accounts',
        where: 'email = ? OR phone = ?',
        whereArgs: [linkedPatientEmail, linkedPatientPhone],
      );

      if (linkedUserAccounts.isNotEmpty) {
        final linkedCustomerId = linkedUserAccounts.first['id'] as int;

        // Find the LIKER's patient profile
        final linkerAccounts = await db.query('user_accounts', where: 'id = ?', whereArgs: [customerId]);
        if (linkerAccounts.isNotEmpty) {
          final linkerEmail = linkerAccounts.first['email'] as String?;
          final linkerPhone = linkerAccounts.first['phone'] as String?;

          if (linkerEmail != null || linkerPhone != null) {
            final linkerPatients = await db.query(
              'patient_profiles',
              where: 'email = ? OR phone = ?',
              whereArgs: [linkerEmail, linkerPhone],
            );

            if (linkerPatients.isNotEmpty) {
              final linkerPatientId = linkerPatients.first['id'] as int;
              
              // Insert reciprocal link
              await db.insert('family_access', {
                'customer_account_id': linkedCustomerId,
                'patient_profile_id': linkerPatientId,
                'relationship': _getReciprocalRelationship(relationship),
                'created_at': DateTime.now().millisecondsSinceEpoch,
              }, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
      }
    }
    
    return true;
  }

  String _getReciprocalRelationship(String relationship) {
    switch (relationship) {
      case 'Con':
        return 'Bố/Mẹ';
      case 'Bố/Mẹ':
        return 'Con';
      case 'Vợ/Chồng':
        return 'Vợ/Chồng';
      case 'Anh/Chị/Em':
        return 'Anh/Chị/Em';
      default:
        return 'Khác';
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFamilyMembers(int customerId) async {
    final db = await _dbHelper.database;
    
    // 1. First, check if the customer has a matching profile and if it's linked
    final userAccounts = await db.query('user_accounts', where: 'id = ?', whereArgs: [customerId]);
    if (userAccounts.isNotEmpty) {
      final user = userAccounts.first;
      final email = user['email'] as String?;
      final phone = user['phone'] as String?;

      if ((email != null && email.isNotEmpty) || (phone != null && phone.isNotEmpty)) {
        // Find matching patient profile
        final List<String> conditions = [];
        final List<dynamic> args = [];
        
        if (email != null && email.isNotEmpty) {
          conditions.add('email = ?');
          args.add(email);
        }
        if (phone != null && phone.isNotEmpty) {
          conditions.add('phone = ?');
          args.add(phone);
        }

        final patients = await db.query(
          'patient_profiles',
          where: conditions.join(' OR '),
          whereArgs: args,
        );

        if (patients.isNotEmpty) {
          final patientId = patients.first['id'] as int;
          
          // Check if already linked
          final linked = await db.query(
            'family_access',
            where: 'customer_account_id = ? AND patient_profile_id = ?',
            whereArgs: [customerId, patientId],
          );

          if (linked.isEmpty) {
            // Auto-link "Bản thân"
            await db.insert('family_access', {
              'customer_account_id': customerId,
              'patient_profile_id': patientId,
              'relationship': 'Bản thân',
              'created_at': DateTime.now().millisecondsSinceEpoch,
            });
          }
        }
      }
    }

    // 2. Fetch all members
    const query = '''
      SELECT p.*, f.relationship, f.created_at as linked_at
      FROM patient_profiles p
      JOIN family_access f ON p.id = f.patient_profile_id
      WHERE f.customer_account_id = ?
      ORDER BY 
        CASE WHEN f.relationship = 'Bản thân' THEN 0 ELSE 1 END,
        f.created_at DESC
    ''';
    
    return await db.rawQuery(query, [customerId]);
  }
}

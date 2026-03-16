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
            if (email != null) {
              final emailConflict = await txn.query('user_accounts', where: 'email = ?', whereArgs: [email]);
              if (emailConflict.isNotEmpty) {
                final res = await txn.query('patient_profiles', columns: ['medical_code'], where: 'email = ?', whereArgs: [email]);
                throw Exception(res.isNotEmpty 
                  ? 'Email này đã được đăng ký hồ sơ. Mã Y Tế: ${res.first['medical_code']}' 
                  : 'Email này đã được sử dụng cho một tài khoản khác.');
              }
            }
            throw Exception('Thông tin Email hoặc Số điện thoại đã tồn tại.');
          }
          rethrow;
        }
      }

      // Nếu bệnh nhân có tài khoản, family_id = userId (chính họ)
      // Nếu không có tài khoản, family_id = family_id của người tạo (staff/head)
      final patientFamilyId = userId ?? await _getUserFamilyId(txn, patient.createdBy);

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
        familyId: patientFamilyId,
      );
      final patientId = await txn.insert('patient_profiles', model.toJson());

      if (userId != null) {
        await txn.insert('family_access', {
          'customer_account_id': userId,
          'patient_profile_id': patientId,
          'relationship': 'Bản thân',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      }

      // Ghi nhật ký tạo hồ sơ
      await txn.insert('audit_logs', {
        'user_id': patient.createdBy,
        'action': 'Tạo hồ sơ bệnh nhân',
        'entity_type': 'patient_profiles',
        'entity_id': patientId,
        'details': 'Đã tạo hồ sơ cho bệnh nhân ${patient.fullName}. Mã Y Tế: $medicalCode',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
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

    while (!isUnique) {
      code = String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
      final existing = await db.query('patient_profiles', columns: ['id'], where: 'access_code = ?', whereArgs: [code]);
      if (existing.isEmpty) isUnique = true;
    }

    await db.update('patient_profiles', {'access_code': code, 'updated_at': DateTime.now().millisecondsSinceEpoch}, where: 'medical_code = ?', whereArgs: [medicalCode]);
    return code;
  }

  Future<void> _notifyFamilyLink(Transaction txn, int customerId, String title, String message) async {
    await txn.insert('system_notifications', {
      'user_id': customerId,
      'title': title,
      'message': message,
      'type': 'FAMILY',
      'is_read': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<bool> linkFamilyMember(int customerId, String medicalCode, String accessCode, String relationship) async {
    final db = await _dbHelper.database;
    
    final patients = await db.query('patient_profiles', where: 'medical_code = ? AND access_code = ?', whereArgs: [medicalCode, accessCode]);
    if (patients.isEmpty) throw Exception('Mã y tế hoặc mã truy cập không chính xác.');
    
    final targetPatientId = patients.first['id'] as int;
    final targetEmail = patients.first['email'] as String?;
    final targetName = patients.first['full_name'] as String;
    
    await db.transaction((txn) async {
      // 0. TỰ CHỮA LÀNH
      // 0. TỰ CHỮA LÀNH (Ensure the linker has a 'Bản thân' profile)
      final currentSelf = await txn.query('family_access',
          where: 'customer_account_id = ? AND relationship = ?',
          whereArgs: [customerId, 'Bản thân']);
      
      int linkerPatientId; String linkerName = 'bạn';
      if (currentSelf.isEmpty) {
        final user = await txn.query('user_accounts', where: 'id = ?', whereArgs: [customerId]);
        final email = user.isNotEmpty ? user.first['email'] as String? : null;
        final fullName = user.isNotEmpty ? user.first['full_name'] as String? : null;
        linkerName = fullName ?? (email != null ? email.split('@')[0] : 'Người dùng');
        
        final random = Random();
        final medicalCodeNew = 'PHR-${DateFormat('ddMMyyyy').format(DateTime.now())}-${random.nextInt(10000).toString().padLeft(4, '0')}';
        
        linkerPatientId = await txn.insert('patient_profiles', {
          'medical_code': medicalCodeNew,
          'full_name': linkerName,
          'email': email,
          'created_by': customerId,
          'family_id': customerId, // Default family_id for self-created profile
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        await txn.insert('family_access', {
          'customer_account_id': customerId,
          'patient_profile_id': linkerPatientId,
          'relationship': 'Bản thân',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        linkerPatientId = currentSelf.first['patient_profile_id'] as int;
        final profileQuery = await txn.query('patient_profiles', columns: ['full_name'], where: 'id = ?', whereArgs: [linkerPatientId]);
        if (profileQuery.isNotEmpty) {
          linkerName = profileQuery.first['full_name'] as String;
        }
      }

      // 1. Thiết lập liên kết chính
      await txn.insert('family_access', {
        'customer_account_id': customerId,
        'patient_profile_id': targetPatientId,
        'relationship': relationship,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await _notifyFamilyLink(txn, customerId, 'Liên kết mới', 'Tài khoản của bạn vừa được liên kết thành công với hồ sơ của $targetName. Bạn hiện có thể xem hồ sơ nhóm gia đình.');

      // 2. TÍNH ĐỐI XỨNG & GOM NHÓM GIA ĐÌNH (Family ID Sync)
      // Khi A liên kết với B (Vợ/Chồng/Con), nếu B chưa có tài khoản hoặc vai trò là quan hệ thân thiết:
      // Gán chung family_id của A (người mời) cho B.

      final currentCustQuery = await txn.query('user_accounts', columns: ['family_id', 'is_family_head'], where: 'id = ?', whereArgs: [customerId]);
      if (currentCustQuery.isEmpty) {
        return false;
      }
      
      // Khắc phục: Sử dụng fallback nếu family_id là null và thực hiện vá lỗi (self-healing)
      int? dbFamilyId = currentCustQuery.first['family_id'] as int?;
      if (dbFamilyId == null) {
        dbFamilyId = customerId;
        await txn.update('user_accounts', {'family_id': customerId}, where: 'id = ?', whereArgs: [customerId]);
      }
      final currentFamilyId = dbFamilyId;

      // Đồng bộ family_id cho chính hồ sơ "Bản thân" của người liên kết
      await txn.update('patient_profiles', 
        {'family_id': currentFamilyId}, 
        where: 'id = ?', whereArgs: [linkerPatientId]);

      final isCurrentHead = (currentCustQuery.first['is_family_head'] ?? 0) == 1;

      // Cập nhật family_id cho hồ sơ mục tiêu
      await txn.update('patient_profiles', {'family_id': currentFamilyId}, where: 'id = ?', whereArgs: [targetPatientId]);

      if (targetEmail != null) {
        final targetUser = await txn.query('user_accounts', columns: ['id', 'family_id'], where: 'email = ?', whereArgs: [targetEmail]);
        if (targetUser.isNotEmpty) {
          final targetAccountId = targetUser.first['id'] as int;
          final targetFamilyId = targetUser.first['family_id'] as int?;

          // If the linked person is a family member (Spouse/Child/Parent)
          // And they don't belong to another family or are currently their own Head
          if (isCurrentHead && (targetFamilyId == null || targetFamilyId == targetAccountId)) {
            // Transfer all of B's family to A's family
            await txn.update('user_accounts', {
              'family_id': currentFamilyId,
              'is_family_head': 0, // B becomes a member, A remains the Head
            }, where: 'id = ?', whereArgs: [targetAccountId]);

            // Update all profiles managed by B to A's family_id
            await txn.update('patient_profiles', {'family_id': currentFamilyId}, where: 'family_id = ?', whereArgs: [targetAccountId]);

            // Notify
            await _notifyFamilyLink(txn, targetAccountId, 'Gia nhập gia đình', 'Bạn đã gia nhập nhóm gia đình của $linkerName.');
          }

          // Establish symmetrical link in family_access table (to maintain relationship labels)
          String reverseRel = relationship;
          if (relationship == 'Con') {
            reverseRel = 'Bố/Mẹ';
          } else if (relationship == 'Bố/Mẹ') {
            reverseRel = 'Con';
          }

          await txn.insert('family_access', {
            'customer_account_id': targetAccountId,
            'patient_profile_id': linkerPatientId,
            'relationship': reverseRel,
            'created_at': DateTime.now().millisecondsSinceEpoch,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // 3. KHÁM PHÁ MẠNG LƯỚI (Cross-linking existing members)
      final existingLinksToTarget = await txn.query('family_access',
        where: 'patient_profile_id = ?', whereArgs: [targetPatientId]);

      for (var existingLink in existingLinksToTarget) {
        final otherAccountId = existingLink['customer_account_id'] as int;
        final otherRelToTarget = existingLink['relationship'] as String;
        if (otherAccountId == customerId) {
          continue;
        }

        final otherSelf = await txn.query('family_access', 
          where: 'customer_account_id = ? AND relationship = ?', 
          whereArgs: [otherAccountId, 'Bản thân']);
        if (otherSelf.isEmpty) {
          continue;
        }
        final otherPatientId = otherSelf.first['patient_profile_id'] as int;

        final otherProfile = await txn.query('patient_profiles', columns: ['full_name'], where: 'id = ?', whereArgs: [otherPatientId]);
        final otherPatientName = otherProfile.isNotEmpty ? otherProfile.first['full_name'] as String : 'Người thân';

        bool pGotA = false;
        bool aGotP = false;

        if (relationship == 'Con' && otherRelToTarget == 'Con') {
          await _linkSymmetrical(txn, customerId, otherPatientId, otherAccountId, linkerPatientId, 'Vợ/Chồng');
          pGotA = true; 
          aGotP = true;
        } else if (relationship == 'Con' && otherRelToTarget == 'Vợ/Chồng') {
          await txn.insert('family_access', {
            'customer_account_id': otherAccountId, 'patient_profile_id': targetPatientId, 'relationship': 'Con', 'created_at': DateTime.now().millisecondsSinceEpoch
          }, conflictAlgorithm: ConflictAlgorithm.replace);
          // Only P got Target (wait, target is targetPatientId. Actually this rule modifies P link to B, not A to P)
        } else if (relationship == 'Anh/Chị/Em' && otherRelToTarget == 'Con') {
          await txn.insert('family_access', {
            'customer_account_id': otherAccountId, 'patient_profile_id': linkerPatientId, 'relationship': 'Con', 'created_at': DateTime.now().millisecondsSinceEpoch
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          await txn.insert('family_access', {
            'customer_account_id': customerId, 'patient_profile_id': otherPatientId, 'relationship': 'Bố/Mẹ', 'created_at': DateTime.now().millisecondsSinceEpoch
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          pGotA = true; 
          aGotP = true;
        } else if (relationship == 'Bố/Mẹ' && otherRelToTarget == 'Vợ/Chồng') {
          await txn.insert('family_access', {
            'customer_account_id': otherAccountId, 'patient_profile_id': linkerPatientId, 'relationship': 'Con', 'created_at': DateTime.now().millisecondsSinceEpoch
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          await txn.insert('family_access', {
            'customer_account_id': customerId, 'patient_profile_id': otherPatientId, 'relationship': 'Bố/Mẹ', 'created_at': DateTime.now().millisecondsSinceEpoch
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          pGotA = true; 
          aGotP = true;
        }
 
        if (pGotA) {
          await _notifyFamilyLink(txn, otherAccountId, 'Phát sinh mạng lưới', 'Do $linkerName vừa liên kết với $targetName, bạn đã tự động được cấp quyền truy cập vào hồ sơ của $linkerName trong mạng lưới gia đình.');
        }
        if (aGotP) {
          await _notifyFamilyLink(txn, customerId, 'Phát sinh mạng lưới', 'Do bạn vừa liên kết với $targetName, bạn đã tự động được cấp quyền truy cập vào hồ sơ của $otherPatientName trong mạng lưới gia đình.');
        }
      }

      // 4. CHIA SẺ DANH SÁCH CÓ SẴNG (Cross-sharing)
      // Khi A liên kết với B (ví dụ Vợ/Chồng), A chia sẻ các hồ sơ con cho B, và ngược lại.
      if (targetEmail != null) {
        final targetUser = await txn.query('user_accounts', columns: ['id'], where: 'email = ?', whereArgs: [targetEmail]);
        if (targetUser.isNotEmpty) {
          final targetAccountId = targetUser.first['id'] as int;

          // A chia sẻ cho B
          final aExistingLinks = await txn.query('family_access', where: 'customer_account_id = ?', whereArgs: [customerId]);
          for (var link in aExistingLinks) {
            final pid = link['patient_profile_id'] as int;
            final rel = link['relationship'] as String;
            if (pid == targetPatientId || pid == linkerPatientId) continue;
            
            String newRel = rel;
            if (relationship == 'Vợ/Chồng' && rel == 'Con') {
              newRel = 'Con';
            } else if (relationship == 'Vợ/Chồng' && rel == 'Bố/Mẹ') {
              newRel = 'Bố/Mẹ';
            }
            
            await txn.insert('family_access', {
              'customer_account_id': targetAccountId, 'patient_profile_id': pid, 'relationship': newRel, 'created_at': DateTime.now().millisecondsSinceEpoch
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }

          // B chia sẻ cho A
          final bExistingLinks = await txn.query('family_access', where: 'customer_account_id = ?', whereArgs: [targetAccountId]);
          for (var link in bExistingLinks) {
            final pid = link['patient_profile_id'] as int;
            final rel = link['relationship'] as String;
            if (pid == targetPatientId || pid == linkerPatientId) continue;

            String newRel = rel;
            if (relationship == 'Vợ/Chồng' && rel == 'Con') { newRel = 'Con'; }
            else if (relationship == 'Vợ/Chồng' && rel == 'Bố/Mẹ') { newRel = 'Bố/Mẹ'; }

            await txn.insert('family_access', {
              'customer_account_id': customerId, 'patient_profile_id': pid, 'relationship': newRel, 'created_at': DateTime.now().millisecondsSinceEpoch
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
      }
    });

    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> getFamilyMembers(int customerId) async {
    final db = await _dbHelper.database;
    
    // Tìm family_id của người dùng
    final userQuery = await db.query('user_accounts', columns: ['family_id'], where: 'id = ?', whereArgs: [customerId]);
    if (userQuery.isEmpty) return [];
    
    int? familyId = userQuery.first['family_id'] as int?;
    
    // Khắc phục: Tự chữa lành triệt để cho cả Account và Patient Profile "Bản thân"
    if (familyId == null) {
      familyId = customerId;
      await db.update('user_accounts', {'family_id': customerId}, where: 'id = ?', whereArgs: [customerId]);
    }

    // Tìm hồ sơ "Bản thân" qua bảng family_access (Độ tin cậy cao nhất)
    final selfLink = await db.query('family_access', 
        columns: ['patient_profile_id'], 
        where: 'customer_account_id = ? AND relationship = ?', 
        whereArgs: [customerId, 'Bản thân']);
    
    if (selfLink.isNotEmpty) {
      final selfPatientId = selfLink.first['patient_profile_id'] as int;
      // Đảm bảo hồ sơ Bản thân luôn khớp Family ID
      await db.update('patient_profiles', {'family_id': familyId}, where: 'id = ?', whereArgs: [selfPatientId]);
    }

    // Self-healing: Sửa family_id cho TẤT CẢ profiles mà user đã liên kết qua family_access
    // nhưng chưa có đúng family_id (đặc biệt quan trọng cho profile của người liên kết gốc)
    await db.rawUpdate('''
      UPDATE patient_profiles 
      SET family_id = ?
      WHERE id IN (SELECT patient_profile_id FROM family_access WHERE customer_account_id = ?)
        AND (family_id IS NULL OR family_id != ?)
    ''', [familyId, customerId, familyId]);

    // Lấy tất cả hồ sơ trong cùng gia đình
    // Kết hợp cả family_id VÀ family_access để đảm bảo không thiếu thành viên
    const query = '''
      SELECT p.*, 
             COALESCE(f.relationship, 'Thành viên') as relationship, 
             COALESCE(f.created_at, p.created_at) as linked_at
      FROM patient_profiles p
      LEFT JOIN family_access f ON p.id = f.patient_profile_id AND f.customer_account_id = ?
      WHERE p.family_id = ?
         OR p.id IN (SELECT patient_profile_id FROM family_access WHERE customer_account_id = ?)
      GROUP BY p.id
      ORDER BY CASE WHEN COALESCE(f.relationship, 'Thành viên') = 'Bản thân' THEN 0 ELSE 1 END, p.id ASC
    ''';
    return await db.rawQuery(query, [customerId, familyId, customerId]);
  }

  @override
  Future<bool> transferFamilyHead(int fromUserId, int toUserId) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      final fromUser = await txn.query('user_accounts', where: 'id = ?', whereArgs: [fromUserId]);
      if (fromUser.isEmpty || (fromUser.first['is_family_head'] ?? 0) == 0) return false;

      await txn.update('user_accounts', {'is_family_head': 0}, where: 'id = ?', whereArgs: [fromUserId]);
      await txn.update('user_accounts', {'is_family_head': 1}, where: 'id = ?', whereArgs: [toUserId]);
      return true;
    });
  }

  @override
  Future<bool> removeFamilyMember(int customerId, int patientId) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      // Kiểm tra quyền (chỉ Head mới được xóa)
      final user = await txn.query('user_accounts', columns: ['is_family_head', 'family_id'], where: 'id = ?', whereArgs: [customerId]);
      if (user.isEmpty || (user.first['is_family_head'] ?? 0) == 0) return false;
      final familyId = user.first['family_id'] as int;

      // Tìm thông tin hồ sơ
      final patient = await txn.query('patient_profiles', where: 'id = ? AND family_id = ?', whereArgs: [patientId, familyId]);
      if (patient.isEmpty) return false;
      
      final targetEmail = patient.first['email'] as String?;
      if (targetEmail != null) {
        final targetUser = await txn.query('user_accounts', where: 'email = ?', whereArgs: [targetEmail]);
        if (targetUser.isNotEmpty) {
          final targetId = targetUser.first['id'] as int;
          // Tách user ra thành gia đình mới của chính họ
          await txn.update('user_accounts', {'family_id': targetId, 'is_family_head': 1}, where: 'id = ?', whereArgs: [targetId]);
          // Cập nhật tất cả hồ sơ mà user đó sở hữu (created_by) về family_id mới của họ
          await txn.update('patient_profiles', {'family_id': targetId}, where: 'created_by = ?', whereArgs: [targetId]);
        }
      } else {
        // Hồ sơ không có tài khoản (ví dụ con nhỏ), tách hẳn khỏi gia đình hiện tại
        await txn.update('patient_profiles', {'family_id': null}, where: 'id = ?', whereArgs: [patientId]);
      }

      await txn.delete('family_access', where: 'patient_profile_id = ?', whereArgs: [patientId]);
      return true;
    });
  }

  @override
  Future<PatientEntity?> getPatientByPhoneOrEmail({String? phone, String? email}) async {
    final db = await _dbHelper.database;
    if ((phone == null || phone.isEmpty) && (email == null || email.isEmpty)) {
      return null;
    }
    List<String> conds = []; List<dynamic> args = [];
    if (email != null && email.isNotEmpty) {
      conds.add('email = ?'); args.add(email);
    }
    if (phone != null && phone.isNotEmpty) {
      conds.add('phone = ?'); args.add(phone);
    }
    final maps = await db.query('patient_profiles', where: conds.join(' OR '), whereArgs: args);
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
  Future<DashboardStats> getStats() async {
    return await DatabaseHelper.instance.getDashboardStats();
  }

  @override
  Future<List<PatientEntity>> getAllPatients() async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'patient_profiles',
      orderBy: 'id DESC',
    );

    return maps.map((map) => PatientModel.fromJson(map)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getDocumentsByPatientId(int patientId) async {
    final db = await DatabaseHelper.instance.database;
    final String sql = '''
      SELECT 
        md.*, 
        dc.name as category_name 
      FROM medical_documents md
      LEFT JOIN document_categories dc ON md.category_id = dc.id
      WHERE md.patient_profile_id = ? AND md.is_deleted = 0
      ORDER BY md.id DESC
    ''';

    return await db.rawQuery(sql, [patientId]);
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentPatients({int limit = 3}) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> result = await db.query(
      'patient_profiles',
      orderBy: 'id DESC',
      // limit: limit,
    );

    return result;
  }

  Future<void> _linkSymmetrical(Transaction txn, int currentCustId, int targetPid, int otherCustId, int linkerPid, String relationship) async {
    await txn.insert('family_access', {
      'customer_account_id': currentCustId, 'patient_profile_id': targetPid, 'relationship': relationship, 'created_at': DateTime.now().millisecondsSinceEpoch
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    String reverseRel = relationship;
    if (relationship == 'Con') {
      reverseRel = 'Bố/Mẹ';
    } else if (relationship == 'Bố/Mẹ') {
      reverseRel = 'Con';
    }

    await txn.insert('family_access', {
      'customer_account_id': otherCustId, 'patient_profile_id': linkerPid, 'relationship': reverseRel, 'created_at': DateTime.now().millisecondsSinceEpoch
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
 
  Future<int> _getUserFamilyId(DatabaseExecutor txn, int? userId) async {
    if (userId == null) return 0;
    final res = await txn.query('user_accounts', columns: ['family_id'], where: 'id = ?', whereArgs: [userId]);
    return res.isNotEmpty ? (res.first['family_id'] as int? ?? userId) : userId;
  }
}

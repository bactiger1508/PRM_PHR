import 'dart:async';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'schema.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    
    // If the database is not open or null, re-initialize it.
    _database = await _initDB('phr_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(DBSchema.createOtpCodesTable);
    }
    if (oldVersion < 3) {
      // Add full_name column to user_accounts
      await db.execute(
        'ALTER TABLE user_accounts ADD COLUMN full_name TEXT',
      );
    }
    if (oldVersion < 4) {
      // Add "Đơn Khám Bệnh" category for medical examinations
      await db.insert(
        'document_categories',
        {'name': 'Đơn Khám Bệnh', 'description': 'Phiếu khám bệnh, chẩn đoán, đơn thuốc'},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    if (oldVersion < 5) {
      await db.execute(DBSchema.createSystemNotificationsTable);
    }
    if (oldVersion < 6) {
      // Add Family ID and Head columns
      await db.execute('ALTER TABLE user_accounts ADD COLUMN family_id INTEGER');
      await db.execute('ALTER TABLE user_accounts ADD COLUMN is_family_head INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE patient_profiles ADD COLUMN family_id INTEGER');
      
      // Initialize existing data: each user is their own family head
      await db.execute('UPDATE user_accounts SET family_id = id, is_family_head = 1');
      
      // Link existing patient profiles to their creators' family
      await db.execute('''
        UPDATE patient_profiles 
        SET family_id = (SELECT family_id FROM user_accounts WHERE id = patient_profiles.created_by)
        WHERE created_by IS NOT NULL
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    // 1. Hệ thống & Master Data
    await db.execute(DBSchema.createUsersTable);
    await db.execute(DBSchema.createDocumentCategoriesTable);
    await db.execute(DBSchema.createTagsTable);

    // 2. Hồ sơ bệnh nhân (Yêu cầu có users)
    await db.execute(DBSchema.createPatientsTable);

    // 3. Liên kết gia đình (Yêu cầu users & patients)
    await db.execute(DBSchema.createFamilyAccessTable);

    // 4. Tài liệu y tế (Yêu cầu patients & categories & users)
    await db.execute(DBSchema.createDocumentsTable);

    // 5. File đính kèm & Tags (Yêu cầu documents)
    await db.execute(DBSchema.createFilesTable);
    await db.execute(DBSchema.createDocumentTagsTable);

    // 6. Logs & Rules & Notifications
    await db.execute(DBSchema.createAuditLogsTable);
    await db.execute(DBSchema.createConfigRulesTable);
    await db.execute(DBSchema.createSystemNotificationsTable);

    // 7. OTP Codes
    await db.execute(DBSchema.createOtpCodesTable);

    // Insert initial Master Data for Document Categories
    await _seedInitialData(db);
  }

  Future _seedInitialData(Database db) async {
    final categories = [
      {
        'name': 'Xét nghiệm',
        'description': 'Kết quả xét nghiệm máu, nước tiểu...',
      },
      {'name': 'Đơn thuốc', 'description': 'Đơn thuốc được bác sĩ kê'},
      {
        'name': 'Chẩn đoán hình ảnh',
        'description': 'X-Quang, MRI, CT Scan, Siêu âm',
      },
      {'name': 'Khác', 'description': 'Các loại tài liệu khác'},
      {'name': 'Đơn Khám Bệnh', 'description': 'Phiếu khám bệnh, chẩn đoán, đơn thuốc'},
    ];

    for (var cat in categories) {
      await db.insert(
        'document_categories',
        cat,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<bool> hasAdminAccount() async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM user_accounts WHERE role = 'ADMIN'",
      ),
    );
    return (count ?? 0) > 0;
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    _database = null; // Clear the static reference
  }

  // For development purposes, to force re-initialization on hot restart
  static void clearStaticDatabaseInstance() {
    _database = null;
  }

  Future<DashboardStats> getDashboardStats() async {
    final db = await DatabaseHelper.instance.database;

    final now = DateTime.now();
    final startOfMonthMs = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final currentYearMonth = DateFormat('yyyy-MM').format(now);
    final patientTotalResult = await db.rawQuery('SELECT COUNT(*) as count FROM patient_profiles');
    final totalPatients = Sqflite.firstIntValue(patientTotalResult) ?? 0;
    final startOfTodayMs = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final currentYearMonthDay = DateFormat('yyyy-MM-dd').format(now);

    final allPatients = await db.rawQuery('SELECT created_at FROM patient_profiles');
    int patientsThisMonth = 0;

    for (var row in allPatients) {
      final createdAt = row['created_at'];
      if (createdAt == null) continue;

      if (createdAt is int) {
        if (createdAt >= startOfMonthMs) patientsThisMonth++;
      } else if (createdAt is String) {
        final parseInt = int.tryParse(createdAt);
        if (parseInt != null) {
          if (parseInt >= startOfMonthMs) patientsThisMonth++;
        } else if (createdAt.startsWith(currentYearMonth)) {
          patientsThisMonth++;
        } else {
          final parsedDate = DateTime.tryParse(createdAt);
          if (parsedDate != null && parsedDate.millisecondsSinceEpoch >= startOfMonthMs) {
            patientsThisMonth++;
          }
        }
      }
    }

    final docTotalResult = await db.rawQuery('SELECT COUNT(*) as count FROM medical_documents WHERE is_deleted = 0');
    final totalDocuments = Sqflite.firstIntValue(docTotalResult) ?? 0;

    final allDocs = await db.rawQuery('SELECT created_at FROM medical_documents WHERE is_deleted = 0');
    int documentsThisMonth = 0;
    int documentsToday = 0;

    for (var row in allDocs) {
      final createdAt = row['created_at'];
      if (createdAt == null) continue;

      if (createdAt is int) {
        if (createdAt >= startOfMonthMs) documentsThisMonth++;
        if (createdAt >= startOfTodayMs) documentsToday++;
      } else if (createdAt is String) {
        final parseInt = int.tryParse(createdAt);
        if (parseInt != null) {
          if (parseInt >= startOfMonthMs) documentsThisMonth++;
          if (parseInt >= startOfTodayMs) documentsToday++;
        } else if (createdAt.startsWith(currentYearMonth)) {
          documentsThisMonth++;
        } else if (createdAt.startsWith(currentYearMonthDay)) { // So sánh theo ngày hôm nay
          documentsToday++;
        } else {
          final parsedDate = DateTime.tryParse(createdAt);
          if (parsedDate != null && parsedDate.millisecondsSinceEpoch >= startOfMonthMs) {
            documentsThisMonth++;
          }
          if (parsedDate != null && parsedDate.millisecondsSinceEpoch >= startOfTodayMs) {
            documentsToday++;
          }
        }
      }
    }

    return DashboardStats(
      totalPatients: totalPatients,
      patientsThisMonth: patientsThisMonth,
      totalDocuments: totalDocuments,
      documentsThisMonth: documentsThisMonth,
      documentToday: documentsToday
    );
  }
}

class DashboardStats {
  final int totalPatients;
  final int patientsThisMonth;
  final int totalDocuments;
  final int documentsThisMonth;
  final int documentToday;

  DashboardStats({
    required this.totalPatients,
    required this.patientsThisMonth,
    required this.totalDocuments,
    required this.documentsThisMonth,
    required this.documentToday,
  });
}

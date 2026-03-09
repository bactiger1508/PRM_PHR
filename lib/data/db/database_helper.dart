import 'dart:async';
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
      version: 4,
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

    // 6. Logs & Rules
    await db.execute(DBSchema.createAuditLogsTable);
    await db.execute(DBSchema.createConfigRulesTable);

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
}

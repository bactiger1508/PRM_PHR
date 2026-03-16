class DBSchema {
  static const String createUsersTable = '''
    CREATE TABLE IF NOT EXISTS user_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE,
        phone TEXT UNIQUE,
        password_hash TEXT,
        full_name TEXT, 
        role TEXT NOT NULL, 
        status TEXT DEFAULT 'ACTIVE',
        created_at INTEGER,
        updated_at INTEGER,
        avatar TEXT,
        family_id INTEGER,
        is_family_head INTEGER DEFAULT 1
    );
  ''';

  static const String createPatientsTable = '''
    CREATE TABLE IF NOT EXISTS patient_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medical_code TEXT UNIQUE NOT NULL, 
        access_code TEXT,                  
        full_name TEXT NOT NULL,
        dob TEXT,
        phone TEXT,
        email TEXT,
        status TEXT DEFAULT 'ACTIVE',      
        created_by INTEGER,                
        created_at INTEGER,
        updated_at INTEGER,
        family_id INTEGER,
        FOREIGN KEY (created_by) REFERENCES user_accounts (id)
    );
  ''';

  static const String createDocumentCategoriesTable = '''
    CREATE TABLE IF NOT EXISTS document_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,         
        description TEXT
    );
  ''';

  static const String createDocumentsTable = '''
    CREATE TABLE IF NOT EXISTS medical_documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_profile_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,      
        record_date INTEGER,               
        title TEXT,
        notes TEXT,
        status TEXT DEFAULT 'SAVED',       
        is_deleted INTEGER DEFAULT 0,      
        created_by INTEGER,                
        created_at INTEGER,
        updated_at INTEGER,
        FOREIGN KEY (patient_profile_id) REFERENCES patient_profiles (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES document_categories (id),
        FOREIGN KEY (created_by) REFERENCES user_accounts (id)
    );
  ''';

  static const String createFilesTable = '''
    CREATE TABLE IF NOT EXISTS document_files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,           
        file_type TEXT,                    
        file_size INTEGER,                 
        created_at INTEGER,
        FOREIGN KEY (document_id) REFERENCES medical_documents (id) ON DELETE CASCADE
    );
  ''';

  static const String createTagsTable = '''
    CREATE TABLE IF NOT EXISTS tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tag_name TEXT UNIQUE NOT NULL,
        created_at INTEGER
    );
  ''';

  static const String createDocumentTagsTable = '''
    CREATE TABLE IF NOT EXISTS document_tags (
        document_id INTEGER,
        tag_id INTEGER,
        PRIMARY KEY (document_id, tag_id),
        FOREIGN KEY (document_id) REFERENCES medical_documents (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
    );
  ''';

  static const String createFamilyAccessTable = '''
    CREATE TABLE IF NOT EXISTS family_access (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_account_id INTEGER NOT NULL, 
        patient_profile_id INTEGER NOT NULL,  
        relationship TEXT,                    
        status TEXT DEFAULT 'ACTIVE',         
        created_at INTEGER,
        UNIQUE(customer_account_id, patient_profile_id),
        FOREIGN KEY (customer_account_id) REFERENCES user_accounts (id) ON DELETE CASCADE,
        FOREIGN KEY (patient_profile_id) REFERENCES patient_profiles (id) ON DELETE CASCADE
    );
  ''';

  static const String createAuditLogsTable = '''
    CREATE TABLE IF NOT EXISTS audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        action TEXT NOT NULL,                 
        entity_type TEXT,                     
        entity_id INTEGER,
        details TEXT,                         
        timestamp INTEGER,
        FOREIGN KEY (user_id) REFERENCES user_accounts (id)
    );
  ''';

  static const String createConfigRulesTable = '''
    CREATE TABLE IF NOT EXISTS config_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key_name TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL,
        description TEXT,
        updated_at INTEGER
    );
  ''';
  static const String createOtpCodesTable = '''
    CREATE TABLE IF NOT EXISTS otp_codes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        otp_code TEXT NOT NULL,
        purpose TEXT DEFAULT 'FORGOT_PASSWORD',
        expires_at INTEGER NOT NULL,
        is_used INTEGER DEFAULT 0,
        created_at INTEGER
    );
  ''';

  static const String createSystemNotificationsTable = '''
    CREATE TABLE IF NOT EXISTS system_notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_accounts (id) ON DELETE CASCADE
    );
  ''';

}

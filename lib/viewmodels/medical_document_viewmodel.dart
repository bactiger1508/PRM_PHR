import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/permission_utils.dart';
import '../data/implementations/medical_document_repository_impl.dart';
import '../data/implementations/category_repository_impl.dart';
import '../domain/entities/medical_document_entity.dart';

import 'auth_viewmodel.dart';

class MedicalDocumentViewModel extends ChangeNotifier {
  final MedicalDocumentRepositoryImpl _docRepo;

  MedicalDocumentViewModel({
    MedicalDocumentRepositoryImpl? docRepo,
    CategoryRepositoryImpl? categoryRepo,
  })  : _docRepo = docRepo ?? MedicalDocumentRepositoryImpl();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMsg;
  String? get errorMsg => _errorMsg;

  // Form state
  int _selectedCategoryIndex = 0;
  int get selectedCategoryIndex => _selectedCategoryIndex;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> get categories => _categories;

  List<String> get categoryNames => _categories.map((c) => c['name'] as String).toList();

  String? get selectedCategoryName =>
      categoryNames.isNotEmpty &&
              _selectedCategoryIndex >= 0 &&
              _selectedCategoryIndex < categoryNames.length
          ? categoryNames[_selectedCategoryIndex]
          : null;

  void selectCategoryByName(String name) {
    final idx = categoryNames.indexOf(name);
    if (idx >= 0) {
      setCategory(idx);
    }
  }

  List<File> _selectedFiles = [];
  List<File> get selectedFiles => _selectedFiles;

  List<String> _selectedTags = [];
  List<String> get selectedTags => _selectedTags;

  List<String> _availableTags = [];
  List<String> get availableTags => _availableTags;

  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> get patients => _patients;

  // Upload progress simulation
  Map<String, double> _uploadProgress = {};
  Map<String, double> get uploadProgress => _uploadProgress;

  // Documents list
  List<MedicalDocumentEntity> _documents = [];
  List<MedicalDocumentEntity> get documents => _documents;

  /// Set selected category by index
  void setCategory(int index) {
    _selectedCategoryIndex = index;
    notifyListeners();
  }

  int? _pendingCategoryId;

  /// Set selected category by DB ID (used mainly for updates)
  void setCategoryById(int categoryId) {
    if (_categories.isEmpty) {
      _pendingCategoryId = categoryId;
      return;
    }
    final index = _categories.indexWhere((c) => c['id'] == categoryId);
    if (index != -1) {
      _selectedCategoryIndex = index;
      notifyListeners();
    }
  }

  /// Load tất cả categories từ DB
  Future<void> loadCategories() async {
    try {
      _categories = await _docRepo.getDocumentCategories();
      if (_pendingCategoryId != null) {
        setCategoryById(_pendingCategoryId!);
        _pendingCategoryId = null;
      }
      notifyListeners();
    } catch (_) {
      _errorMsg = 'Không thể tải danh mục tài liệu.';
      notifyListeners();
    }
  }

  /// Chụp ảnh từ camera
  Future<void> pickFromCamera(BuildContext context) async {
    final hasPermission = await PermissionUtils.requestCameraPermission(context);
    if (!hasPermission) {
      return;
    }

    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (photo != null) {
      _selectedFiles.add(File(photo.path));
      _uploadProgress[photo.name.split('/').last] = 1.0;
      notifyListeners();
    }
  }

  /// Chọn ảnh từ thư viện
  Future<void> pickFromGallery(BuildContext context) async {
    final hasPermission = await PermissionUtils.requestStoragePermission(context);
    if (!hasPermission) {
      return;
    }

    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (images.isNotEmpty) {
      for (var img in images) {
        _selectedFiles.add(File(img.path));
        _uploadProgress[img.name.split('/').last] = 1.0;
      }
      notifyListeners();
    }
  }

  /// Xóa file đã chọn
  void removeFile(int index) {
    if (index >= 0 && index < _selectedFiles.length) {
      final fileName = _selectedFiles[index].path.split('/').last;
      _uploadProgress.remove(fileName);
      _selectedFiles.removeAt(index);
      notifyListeners();
    }
  }

  /// Thêm tag
  void addTag(String tag) {
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      _selectedTags.add(tag);
      notifyListeners();
    }
  }

  /// Xóa tag
  void removeTag(String tag) {
    _selectedTags.remove(tag);
    notifyListeners();
  }

  /// Nạp danh sách file hiện có (dùng cho Cập nhật)
  void initWithFiles(List<String> filePaths) {
    _selectedFiles = filePaths.map((path) => File(path)).toList();
    // Đánh dấu là đã upload xong (1.0) cho các file cũ
    for (var path in filePaths) {
      final fileName = path.split(Platform.pathSeparator).last;
      _uploadProgress[fileName] = 1.0;
    }
    notifyListeners();
  }

  /// Load danh sách bệnh nhân
  Future<void> loadPatients() async {
    _isLoading = true;
    notifyListeners();

    try {
      _patients = await _docRepo.getPatientList();
    } catch (e) {
      _errorMsg = 'Không thể tải danh sách bệnh nhân.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load tất cả tags
  Future<void> loadTags() async {
    try {
      _availableTags = await _docRepo.getAllTags();
      notifyListeners();
    } catch (e) {
      _errorMsg = 'Không thể tải danh sách nhãn tag.';
      notifyListeners();
    }
  }

  /// Load documents theo patient
  Future<void> loadDocumentsByPatient(int patientProfileId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _documents = await _docRepo.getDocumentsByPatient(patientProfileId);
    } catch (e) {
      _errorMsg = 'Không thể tải danh sách tài liệu.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lưu tài liệu y tế
  Future<bool> saveDocument({
    required int patientProfileId,
    required String title,
    int? recordDate,
    String? notes,
    required int createdByStaffId,
    String status = 'SAVED',
    String? customCategoryName,
  }) async {
    if (title.isEmpty) {
      _errorMsg = 'Vui lòng nhập tiêu đề tài liệu.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMsg = null;
    notifyListeners();

    try {
      // Get categoryId from loaded categories
      int categoryId = 1; // Default
      
      if (customCategoryName != null && customCategoryName.trim().isNotEmpty) {
        categoryId = await _docRepo.createDocumentCategory(customCategoryName.trim());
      } else if (_categories.isNotEmpty && _selectedCategoryIndex < _categories.length) {
        categoryId = _categories[_selectedCategoryIndex]['id'] as int;
      }

      final doc = MedicalDocumentEntity(
        patientProfileId: patientProfileId,
        categoryId: categoryId,
        recordDate: recordDate,
        title: title,
        notes: notes,
        status: status,
        createdBy: createdByStaffId,
      );

      final docId = await _docRepo.createDocument(doc);

      // Lưu files
      for (var file in _selectedFiles) {
        final fileEntity = DocumentFileEntity(
          filePath: file.path,
          fileType: _getFileType(file.path),
          fileSize: await file.length(),
        );
        await _docRepo.addFileToDocument(docId, fileEntity);
      }

      // Lưu tags
      for (var tag in _selectedTags) {
        await _docRepo.addTagToDocument(docId, tag);
      }

      // Reload list if needed or at least notify listeners that data has changed
      // (Though the dashboard usually reloads its own list)
      
      return true;
    } catch (e) {
      _errorMsg = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Helper: detect file type
  String _getFileType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// Cập nhật tài liệu y tế
  Future<bool> updateDocument({
    required int docId,
    required String title,
    String? notes,
    int? recordDate,
    required int performedByUserId,
    String? customCategoryName,
  }) async {
    if (title.isEmpty) {
      _errorMsg = 'Vui lòng nhập tiêu đề tài liệu.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMsg = null;
    notifyListeners();

    try {
      int categoryId = 1;
      
      if (customCategoryName != null && customCategoryName.trim().isNotEmpty) {
        categoryId = await _docRepo.createDocumentCategory(customCategoryName.trim());
      } else if (_categories.isNotEmpty && _selectedCategoryIndex < _categories.length) {
        categoryId = _categories[_selectedCategoryIndex]['id'] as int;
      }

      final doc = MedicalDocumentEntity(
        id: docId,
        patientProfileId: 0, // Not needed for update
        categoryId: categoryId,
        title: title,
        notes: notes,
        recordDate: recordDate,
      );

      final success = await _docRepo.updateDocument(doc, performedByUserId);
      if (success) {
        // Cập nhật lại list tags nếu có thay đổi
        await _docRepo.updateTagsForDocument(docId, _selectedTags);
        // Cập nhật lại list files
        await _docRepo.updateFilesForDocument(docId, _selectedFiles);
      }
      return success;
    } catch (e) {
      _errorMsg = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Cập nhật trạng thái tài liệu (DRAFT -> SAVED)
  Future<bool> updateDocumentStatus(int docId, String newStatus, {int? performedByUserId}) async {
    final userId = performedByUserId ?? AuthViewModel.instance.currentUser?.id ?? 0;
    try {
      final result = await _docRepo.updateDocumentStatus(docId, newStatus, userId);
      if (result) {
        // Cập nhật local list nếu có
        final index = _documents.indexWhere((d) => d.id == docId);
        if (index != -1) {
          notifyListeners();
        }
      }
      return result;
    } catch (e) {
      _errorMsg = 'Không thể cập nhật trạng thái tài liệu.';
      notifyListeners();
      return false;
    }
  }

  /// Reset form
  void resetForm() {
    _selectedCategoryIndex = 0;
    _selectedFiles = [];
    _selectedTags = [];
    _uploadProgress = {};
    _errorMsg = null;
    notifyListeners();
  }

  /// Xóa mềm document (có thể khôi phục)
  Future<bool> softDeleteDocument(int docId) async {
    final performedByUserId = AuthViewModel.instance.currentUser?.id ?? 0;
    try {
      final result = await _docRepo.deleteDocument(docId, performedByUserId);
      if (result) {
        _documents.removeWhere((d) => d.id == docId);
        notifyListeners();
      }
      return result;
    } catch (e) {
      _errorMsg = 'Không thể xóa tài liệu.';
      notifyListeners();
      return false;
    }
  }

  /// Khôi phục document đã xóa mềm
  Future<bool> restoreDocument(int docId) async {
    final performedByUserId = AuthViewModel.instance.currentUser?.id ?? 0;
    try {
      final result = await _docRepo.restoreDocument(docId, performedByUserId);
      if (result) {
        notifyListeners();
      }
      return result;
    } catch (e) {
      _errorMsg = 'Không thể khôi phục tài liệu.';
      notifyListeners();
      return false;
    }
  }

  /// Load tài liệu do nhân viên hiện tại tạo
  Future<void> loadDocumentsByCreator(int staffId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _documents = await _docRepo.getDocumentsByCreator(staffId);
    } catch (e) {
      _errorMsg = 'Không thể tải danh sách tài liệu.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xóa vĩnh viễn tài liệu (Xóa DB + File vật lý)
  Future<bool> hardDeleteDocument(int docId) async {
    final performedByUserId = AuthViewModel.instance.currentUser?.id ?? 0;
    try {
      final result = await _docRepo.hardDeleteDocument(docId, performedByUserId);
      if (result) {
        _documents.removeWhere((d) => d.id == docId);
        notifyListeners();
      }
      return result;
    } catch (e) {
      _errorMsg = 'Không thể xóa vĩnh viễn tài liệu.';
      notifyListeners();
      return false;
    }
  }

  /// Dọn sạch thùng rác cho nhân viên
  Future<bool> clearTrash(int staffId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _docRepo.clearTrash(staffId);
      if (result) {
        _documents.removeWhere((d) => d.status == 'DELETED' || d.isDeleted == 1);
        notifyListeners();
      }
      return result;
    } catch (e) {
      _errorMsg = 'Không thể dọn sạch thùng rác.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

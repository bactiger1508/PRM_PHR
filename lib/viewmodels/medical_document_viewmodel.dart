import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../data/implementations/medical_document_repository_impl.dart';
import '../domain/entities/medical_document_entity.dart';

class MedicalDocumentViewModel extends ChangeNotifier {
  final MedicalDocumentRepositoryImpl _docRepo;

  MedicalDocumentViewModel({MedicalDocumentRepositoryImpl? docRepo})
      : _docRepo = docRepo ?? MedicalDocumentRepositoryImpl();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMsg;
  String? get errorMsg => _errorMsg;

  // Form state
  int _selectedCategoryIndex = 0;
  int get selectedCategoryIndex => _selectedCategoryIndex;

  final List<String> categoryNames = ['Xét nghiệm', 'Đơn thuốc', 'Chẩn đoán'];

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

  /// Set selected category
  void setCategory(int index) {
    _selectedCategoryIndex = index;
    notifyListeners();
  }

  /// Chụp ảnh từ camera
  Future<void> pickFromCamera() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (photo != null) {
      _selectedFiles.add(File(photo.path));
      _simulateUpload(photo.name);
      notifyListeners();
    }
  }

  /// Chọn ảnh từ thư viện
  Future<void> pickFromGallery() async {
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (images.isNotEmpty) {
      for (var img in images) {
        _selectedFiles.add(File(img.path));
        _simulateUpload(img.name);
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

  /// Simulate upload progress
  void _simulateUpload(String fileName) async {
    _uploadProgress[fileName] = 0.0;
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      _uploadProgress[fileName] = i / 10;
      notifyListeners();
    }
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
    } catch (_) {}
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
      // categoryId từ DB: 1-indexed (1: Xét nghiệm, 2: Đơn thuốc, 3: Chẩn đoán)
      final categoryId = _selectedCategoryIndex + 1;

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
    try {
      final result = await _docRepo.deleteDocument(docId);
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
    try {
      final result = await _docRepo.restoreDocument(docId);
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

  /// Xóa document
  Future<bool> deleteDocument(int docId) async {
    try {
      final result = await _docRepo.deleteDocument(docId);
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
}

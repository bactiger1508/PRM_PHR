import 'package:flutter/foundation.dart';
import '../data/implementations/tag_repository_impl.dart';
import '../domain/entities/tag_entity.dart';

class TagViewModel extends ChangeNotifier {
  final TagRepositoryImpl _tagRepo;

  TagViewModel({TagRepositoryImpl? tagRepo})
      : _tagRepo = tagRepo ?? TagRepositoryImpl();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMsg;
  String? get errorMsg => _errorMsg;

  List<TagEntity> _tags = [];
  List<TagEntity> get tags => _tags;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<TagEntity> get filteredTags {
    if (_searchQuery.isEmpty) return _tags;
    final q = _searchQuery.toLowerCase();
    return _tags.where((t) => t.tagName.toLowerCase().contains(q)).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadTags() async {
    _isLoading = true;
    _errorMsg = null;
    notifyListeners();

    try {
      _tags = await _tagRepo.getAllTags();
    } catch (e) {
      _errorMsg = 'Không thể tải danh sách nhãn: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTag(String tagName) async {
    _errorMsg = null;
    try {
      await _tagRepo.createTag(tagName);
      await loadTags();
      return true;
    } catch (e) {
      if (e.toString().contains('UNIQUE')) {
        _errorMsg = 'Nhãn "$tagName" đã tồn tại';
      } else {
        _errorMsg = 'Không thể tạo nhãn: $e';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTag(int id, String newName) async {
    _errorMsg = null;
    try {
      final ok = await _tagRepo.updateTag(id, newName);
      if (ok) await loadTags();
      return ok;
    } catch (e) {
      if (e.toString().contains('UNIQUE')) {
        _errorMsg = 'Nhãn "$newName" đã tồn tại';
      } else {
        _errorMsg = 'Không thể cập nhật nhãn: $e';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTag(int id) async {
    _errorMsg = null;
    try {
      final ok = await _tagRepo.deleteTag(id);
      if (ok) await loadTags();
      return ok;
    } catch (e) {
      _errorMsg = 'Không thể xoá nhãn: $e';
      notifyListeners();
      return false;
    }
  }
}

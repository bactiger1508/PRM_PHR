import 'package:flutter/foundation.dart';
import '../data/implementations/category_repository_impl.dart';
import '../domain/entities/category_entity.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryRepositoryImpl _categoryRepo;

  CategoryViewModel({CategoryRepositoryImpl? categoryRepo})
      : _categoryRepo = categoryRepo ?? CategoryRepositoryImpl();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMsg;
  String? get errorMsg => _errorMsg;

  List<CategoryEntity> _categories = [];
  List<CategoryEntity> get categories => _categories;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<CategoryEntity> get filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    final q = _searchQuery.toLowerCase();
    return _categories.where((c) => c.name.toLowerCase().contains(q) || (c.description?.toLowerCase().contains(q) ?? false)).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _isLoading = true;
    _errorMsg = null;
    notifyListeners();

    try {
      _categories = await _categoryRepo.getAllCategories();
    } catch (e) {
      _errorMsg = 'Không thể tải danh mục: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCategory(String name, String? description) async {
    _errorMsg = null;
    try {
      await _categoryRepo.createCategory(name, description);
      await loadCategories();
      return true;
    } catch (e) {
      if (e.toString().contains('UNIQUE')) {
        _errorMsg = 'Danh mục "$name" đã tồn tại';
      } else {
        _errorMsg = 'Không thể tạo danh mục: $e';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(int id, {String? name, String? description}) async {
    _errorMsg = null;
    try {
      final ok = await _categoryRepo.updateCategory(id, name: name, description: description);
      if (ok) await loadCategories();
      return ok;
    } catch (e) {
      if (e.toString().contains('UNIQUE')) {
        _errorMsg = 'Danh mục "$name" đã tồn tại';
      } else {
        _errorMsg = 'Không thể cập nhật danh mục: $e';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    _errorMsg = null;
    try {
      final ok = await _categoryRepo.deleteCategory(id);
      if (ok) await loadCategories();
      return ok;
    } catch (e) {
      _errorMsg = 'Không thể xoá danh mục: $e';
      notifyListeners();
      return false;
    }
  }
}

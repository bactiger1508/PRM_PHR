import '../../domain/entities/category_entity.dart';

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getAllCategories();
  Future<CategoryEntity> createCategory(String name, String? description);
  Future<bool> updateCategory(int id, {String? name, String? description});
  Future<bool> deleteCategory(int id);
}

import '../../domain/entities/tag_entity.dart';

abstract class TagRepository {
  Future<List<TagEntity>> getAllTags();
  Future<TagEntity> createTag(String tagName);
  Future<bool> updateTag(int id, String newName);
  Future<bool> deleteTag(int id);
}

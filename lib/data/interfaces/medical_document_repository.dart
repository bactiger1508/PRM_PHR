import '../../domain/entities/medical_document_entity.dart';

abstract class MedicalDocumentRepository {
  Future<int> createDocument(MedicalDocumentEntity doc);
  Future<void> addFileToDocument(int documentId, DocumentFileEntity file);
  Future<void> addTagToDocument(int documentId, String tagName);
  Future<List<MedicalDocumentEntity>> getDocumentsByPatient(int patientProfileId);
  Future<List<MedicalDocumentEntity>> getDocumentsByCreator(int staffId);
  Future<MedicalDocumentEntity?> getDocumentById(int docId);
  Future<bool> deleteDocument(int docId);
  Future<bool> restoreDocument(int docId);
  Future<bool> updateDocument(MedicalDocumentEntity doc);
  Future<void> updateTagsForDocument(int docId, List<String> newTags);
  Future<List<Map<String, dynamic>>> getDocumentCategories();
}

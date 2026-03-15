import '../../domain/entities/medical_document_entity.dart';

abstract class MedicalDocumentRepository {
  Future<int> createDocument(MedicalDocumentEntity doc);
  Future<void> addFileToDocument(int documentId, DocumentFileEntity file);
  Future<void> addTagToDocument(int documentId, String tagName);
  Future<List<MedicalDocumentEntity>> getDocumentsByPatient(int patientProfileId);
  Future<MedicalDocumentEntity?> getDocumentById(int docId);
  Future<bool> deleteDocument(int docId);
  Future<List<Map<String, dynamic>>> getDocumentCategories();
}

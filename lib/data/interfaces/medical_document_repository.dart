import 'dart:io';
import '../../domain/entities/medical_document_entity.dart';

abstract class MedicalDocumentRepository {
  Future<int> createDocument(MedicalDocumentEntity doc);
  Future<void> addFileToDocument(int documentId, DocumentFileEntity file);
  Future<void> addTagToDocument(int documentId, String tagName);
  Future<List<MedicalDocumentEntity>> getDocumentsByPatient(int patientProfileId);
  Future<List<MedicalDocumentEntity>> getDocumentsByCreator(int staffId);
  Future<MedicalDocumentEntity?> getDocumentById(int docId);
  Future<bool> deleteDocument(int docId, int performedByUserId);
  Future<bool> restoreDocument(int docId, int performedByUserId);
  Future<bool> hardDeleteDocument(int docId, int performedByUserId);
  Future<bool> clearTrash(int staffId);
  Future<bool> updateDocument(MedicalDocumentEntity doc, int performedByUserId);
  Future<void> updateTagsForDocument(int docId, List<String> newTags);
  Future<void> updateFilesForDocument(int docId, List<File> newFiles);
  Future<List<Map<String, dynamic>>> getDocumentCategories();
  Future<bool> updateDocumentStatus(int docId, String newStatus, int performedByUserId);
}

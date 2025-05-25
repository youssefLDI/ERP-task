import 'dart:io';
import 'dart:typed_data';
import 'package:erptask/features/documents/domain/entities/document.dart';

abstract class DocumentRepo {
  // Upload document
  Future<Document> uploadDocument({
    File? file,
    Uint8List? webFileBytes,
    String? webFileName,
    required String title,
    required String description,
    required List<String> tags,
    required String userId,
    String? folderId,
    List<Map<String, dynamic>> accessControlList = const [],
  });

  // Get all documents for a user
  Future<List<Document>> getUserDocuments(String userId);

  // Get document by ID
  Future<Document?> getDocumentById(String documentId);

  // Update document metadata
  Future<Document> updateDocument(Document document);

  // Delete document
  Future<void> deleteDocument(String documentId);

  // Search documents
  Future<List<Document>> searchDocuments({
    required String userId,
    String? query,
    List<String>? tags,
  });
}

import 'dart:io';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erptask/features/documents/domain/entities/document.dart';
import 'package:erptask/features/documents/domain/repos/document_repo.dart';
import 'package:erptask/features/folders/domain/repos/folder_repo.dart';
import 'package:erptask/features/documents/presentation/cubits/document_states.dart';

class DocumentCubit extends Cubit<DocumentState> {
  final DocumentRepo documentRepo;
  final FolderRepo folderRepo;

  List<Document> _documents = [];
  Document? _currentDocument;

  DocumentCubit({required this.documentRepo, required this.folderRepo})
    : super(DocumentInitial());

  // Getters
  List<Document> get documents => _documents;
  Document? get currentDocument => _currentDocument;

  // Upload document
  Future<void> uploadDocument({
    File? file,
    Uint8List? webFileBytes,
    String? webFileName,
    required String title,
    required String description,
    required List<String> tags,
    required String userId,
    String? folderId,
    List<Map<String, dynamic>> accessControlList = const [],
  }) async {
    try {
      emit(DocumentUploading(0.0));

      final document = await documentRepo.uploadDocument(
        file: file,
        webFileBytes: webFileBytes,
        webFileName: webFileName,
        title: title,
        description: description,
        tags: tags,
        userId: userId,
        folderId: folderId,
        accessControlList: accessControlList,
      );

      _documents.insert(0, document);
      emit(DocumentUploaded(document));

      // Refresh the documents list
      emit(DocumentsLoaded(_documents));
    } catch (e) {
      emit(DocumentError('Failed to upload document: $e'));
    }
  }

  // Load user documents
  Future<void> loadUserDocuments(String userId) async {
    try {
      emit(DocumentLoading());

      _documents = await documentRepo.getUserDocuments(userId);
      emit(DocumentsLoaded(_documents));
    } catch (e) {
      emit(DocumentError('Failed to load documents: $e'));
    }
  }

  // Load single document
  Future<void> loadDocument(String documentId) async {
    try {
      emit(DocumentLoading());

      final document = await documentRepo.getDocumentById(documentId);
      if (document != null) {
        _currentDocument = document;
        emit(DocumentLoaded(document));
      } else {
        emit(DocumentError('Document not found'));
      }
    } catch (e) {
      emit(DocumentError('Failed to load document: $e'));
    }
  }

  // Update document
  Future<void> updateDocument(Document document) async {
    try {
      emit(DocumentLoading());
      final updatedDocument = await documentRepo.updateDocument(document);
      _currentDocument = updatedDocument;
      // Always reload from Firestore to get the latest data
      await loadUserDocuments(document.userId);
      emit(DocumentUpdated(updatedDocument));
    } catch (e) {
      emit(DocumentError('Failed to update document: $e'));
    }
  }

  // Delete document
  Future<void> deleteDocument(String documentId) async {
    try {
      emit(DocumentLoading());

      await documentRepo.deleteDocument(documentId);

      // Remove from local list
      _documents.removeWhere((doc) => doc.id == documentId);

      emit(DocumentDeleted('Document deleted successfully'));
      emit(DocumentsLoaded(_documents));
    } catch (e) {
      emit(DocumentError('Failed to delete document: $e'));
    }
  }

  // Search documents
  Future<void> searchDocuments({
    required String userId,
    String? query,
    List<String>? tags,
  }) async {
    try {
      emit(DocumentLoading());

      final searchResults = await documentRepo.searchDocuments(
        userId: userId,
        query: query,
        tags: tags,
      );

      emit(DocumentsLoaded(searchResults));
    } catch (e) {
      emit(DocumentError('Failed to search documents: $e'));
    }
  }

  // Clear search and reload all documents
  Future<void> clearSearch(String userId) async {
    await loadUserDocuments(userId);
  }

  // Reset state
  void resetState() {
    _documents = [];
    _currentDocument = null;
    emit(DocumentInitial());
  }

  Future<void> moveDocumentToFolder({
    required Document document,
    String? newFolderId,
  }) async {
    try {
      emit(DocumentLoading());
      final oldFolderId = document.folderId;
      final updatedDoc = document.copyWith(folderId: newFolderId);
      await documentRepo.updateDocument(updatedDoc);
      if (oldFolderId != null) {
        await folderRepo.removeDocumentFromFolder(
          folderId: oldFolderId,
          documentId: document.id,
        );
      }
      if (newFolderId != null) {
        await folderRepo.addDocumentToFolder(
          folderId: newFolderId,
          documentId: document.id,
        );
      }
      await loadUserDocuments(document.userId);
      emit(DocumentUpdated(updatedDoc));
    } catch (e) {
      emit(DocumentError('Failed to move document: $e'));
    }
  }
}

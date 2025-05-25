import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:erptask/features/documents/domain/entities/document.dart';
import 'package:erptask/features/documents/domain/repos/document_repo.dart';
import 'package:path/path.dart' as path;

class FirebaseDocumentRepo implements DocumentRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
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
  }) async {
    try {
      final docId = _firestore.collection('documents').doc().id;
      String fileExtension = '';
      String fileName = '';
      String storagePath = '';
      int fileSize = 0;
      String downloadUrl = '';
      if (kIsWeb && webFileBytes != null && webFileName != null) {
        fileExtension = path.extension(webFileName);
        fileName = webFileName;
        storagePath = 'documents/$userId/$docId$fileExtension';
        final uploadTask = _storage.ref(storagePath).putData(webFileBytes);
        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
        fileSize = webFileBytes.length;
      } else if (file != null) {
        fileExtension = path.extension(file.path);
        fileName = path.basename(file.path);
        storagePath = 'documents/$userId/$docId$fileExtension';
        final uploadTask = _storage.ref(storagePath).putFile(file);
        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
        fileSize = await file.length();
      } else {
        throw Exception('No file provided for upload');
      }
      final document = Document(
        id: docId,
        title: title,
        description: description,
        fileName: fileName,
        fileUrl: downloadUrl,
        fileType: fileExtension.replaceFirst('.', ''),
        fileSize: fileSize,
        tags: tags,
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        folderId: folderId,
        accessControlList: accessControlList,
      );
      await _firestore
          .collection('documents')
          .doc(docId)
          .set(document.toJson());
      return document;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  @override
  Future<List<Document>> getUserDocuments(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('documents')
              .orderBy('createdAt', descending: true)
              .get();

      final userEmail = await _getUserEmailById(userId);
      return querySnapshot.docs
          .map((doc) => Document.fromJson(doc.data()))
          .where((doc) {
            // Show if user is owner
            if (doc.userId == userId) return true;
            // Show if user email is in ACL
            if (userEmail != null &&
                doc.accessControlList.any((e) => e['userEmail'] == userEmail))
              return true;
            return false;
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get user documents: $e');
    }
  }

  // Helper to get user email by userId (assumes a users collection with email field)
  Future<String?> _getUserEmailById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data()?['email'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Document?> getDocumentById(String documentId) async {
    try {
      final docSnapshot =
          await _firestore.collection('documents').doc(documentId).get();

      if (docSnapshot.exists) {
        return Document.fromJson(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get document: $e');
    }
  }

  @override
  Future<Document> updateDocument(Document document) async {
    try {
      final updatedDocument = document.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection('documents')
          .doc(document.id)
          .update(updatedDocument.toJson());

      return updatedDocument;
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    try {
      // Get document to find file URL
      final document = await getDocumentById(documentId);

      if (document != null) {
        // Delete file from storage
        final ref = _storage.refFromURL(document.fileUrl);
        await ref.delete();

        // Delete document metadata from Firestore
        await _firestore.collection('documents').doc(documentId).delete();
      }
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  @override
  Future<List<Document>> searchDocuments({
    required String userId,
    String? query,
    List<String>? tags,
  }) async {
    try {
      Query<Map<String, dynamic>> queryRef = _firestore
          .collection('documents')
          .where('userId', isEqualTo: userId);

      // Add tag filter if provided
      if (tags != null && tags.isNotEmpty) {
        queryRef = queryRef.where('tags', arrayContainsAny: tags);
      }

      final querySnapshot = await queryRef.get();

      List<Document> documents =
          querySnapshot.docs
              .map((doc) => Document.fromJson(doc.data()))
              .toList();

      // Filter by title/description if query provided
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        documents =
            documents.where((doc) {
              return doc.title.toLowerCase().contains(lowerQuery) ||
                  doc.description.toLowerCase().contains(lowerQuery) ||
                  doc.fileName.toLowerCase().contains(lowerQuery);
            }).toList();
      }

      return documents;
    } catch (e) {
      throw Exception('Failed to search documents: $e');
    }
  }
}

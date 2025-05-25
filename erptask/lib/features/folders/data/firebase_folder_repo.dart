import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:erptask/features/folders/domain/entities/folder.dart';
import 'package:erptask/features/folders/domain/repos/folder_repo.dart';

class FirebaseFolderRepo implements FolderRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Folder> createFolder({
    required String name,
    String? parentId,
    required String userId,
  }) async {
    try {
      final folderId = _firestore.collection('folders').doc().id;

      final folder = Folder(
        id: folderId,
        name: name,
        parentId: parentId,
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('folders').doc(folderId).set(folder.toJson());

      // If this folder has a parent, add it to parent's subfolders list
      if (parentId != null) {
        await _firestore.collection('folders').doc(parentId).update({
          'subfolderIds': FieldValue.arrayUnion([folderId]),
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      return folder;
    } catch (e) {
      throw Exception('Failed to create folder: $e');
    }
  }

  @override
  Future<List<Folder>> getUserFolders(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('folders')
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: false)
              .get();

      return querySnapshot.docs
          .map((doc) => Folder.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user folders: $e');
    }
  }

  @override
  Future<Folder?> getFolderById(String folderId) async {
    try {
      final docSnapshot =
          await _firestore.collection('folders').doc(folderId).get();

      if (docSnapshot.exists) {
        return Folder.fromJson(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get folder: $e');
    }
  }

  @override
  Future<List<Folder>> getSubfolders(String parentId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('folders')
              .where('parentId', isEqualTo: parentId)
              .orderBy('name')
              .get();

      return querySnapshot.docs
          .map((doc) => Folder.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get subfolders: $e');
    }
  }

  @override
  Future<List<Folder>> getRootFolders(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('folders')
              .where('userId', isEqualTo: userId)
              .where('parentId', isNull: true)
              .orderBy('name')
              .get();

      return querySnapshot.docs
          .map((doc) => Folder.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get root folders: $e');
    }
  }

  @override
  Future<Folder> updateFolder(Folder folder) async {
    try {
      final updatedFolder = folder.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection('folders')
          .doc(folder.id)
          .update(updatedFolder.toJson());

      return updatedFolder;
    } catch (e) {
      throw Exception('Failed to update folder: $e');
    }
  }

  @override
  Future<void> deleteFolder(String folderId) async {
    try {
      final folder = await getFolderById(folderId);
      if (folder == null) return;

      // Start a batch write
      final batch = _firestore.batch();

      // Remove this folder from parent's subfolders list
      if (folder.parentId != null) {
        final parentRef = _firestore.collection('folders').doc(folder.parentId);
        batch.update(parentRef, {
          'subfolderIds': FieldValue.arrayRemove([folderId]),
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      // Delete all subfolders recursively
      for (String subfolderId in folder.subfolderIds) {
        await deleteFolder(subfolderId);
      }

      // Move documents out of this folder (set folderId to null in documents)
      for (String documentId in folder.documentIds) {
        final documentRef = _firestore.collection('documents').doc(documentId);
        batch.update(documentRef, {
          'folderId': null,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      // Delete the folder itself
      final folderRef = _firestore.collection('folders').doc(folderId);
      batch.delete(folderRef);

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete folder: $e');
    }
  }

  @override
  Future<void> addDocumentToFolder({
    required String folderId,
    required String documentId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Add document ID to folder's documentIds array
      final folderRef = _firestore.collection('folders').doc(folderId);
      batch.update(folderRef, {
        'documentIds': FieldValue.arrayUnion([documentId]),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Update document's folderId field
      final documentRef = _firestore.collection('documents').doc(documentId);
      batch.update(documentRef, {
        'folderId': folderId,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to add document to folder: $e');
    }
  }

  @override
  Future<void> removeDocumentFromFolder({
    required String folderId,
    required String documentId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Remove document ID from folder's documentIds array
      final folderRef = _firestore.collection('folders').doc(folderId);
      batch.update(folderRef, {
        'documentIds': FieldValue.arrayRemove([documentId]),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Remove folderId from document
      final documentRef = _firestore.collection('documents').doc(documentId);
      batch.update(documentRef, {
        'folderId': null,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to remove document from folder: $e');
    }
  }

  @override
  Future<Folder> moveFolder({
    required String folderId,
    String? newParentId,
  }) async {
    try {
      final folder = await getFolderById(folderId);
      if (folder == null) {
        throw Exception('Folder not found');
      }

      final batch = _firestore.batch();

      // Remove from old parent's subfolders list
      if (folder.parentId != null) {
        final oldParentRef = _firestore
            .collection('folders')
            .doc(folder.parentId);
        batch.update(oldParentRef, {
          'subfolderIds': FieldValue.arrayRemove([folderId]),
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      // Add to new parent's subfolders list
      if (newParentId != null) {
        final newParentRef = _firestore.collection('folders').doc(newParentId);
        batch.update(newParentRef, {
          'subfolderIds': FieldValue.arrayUnion([folderId]),
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      // Update folder's parentId
      final updatedFolder = folder.copyWith(
        parentId: newParentId,
        updatedAt: DateTime.now(),
      );

      final folderRef = _firestore.collection('folders').doc(folderId);
      batch.update(folderRef, updatedFolder.toJson());

      await batch.commit();
      return updatedFolder;
    } catch (e) {
      throw Exception('Failed to move folder: $e');
    }
  }

  @override
  Future<List<Folder>> getFolderPath(String folderId) async {
    try {
      List<Folder> path = [];
      String? currentId = folderId;

      while (currentId != null) {
        final folder = await getFolderById(currentId);
        if (folder != null) {
          path.insert(0, folder);
          currentId = folder.parentId;
        } else {
          break;
        }
      }

      return path;
    } catch (e) {
      throw Exception('Failed to get folder path: $e');
    }
  }
}

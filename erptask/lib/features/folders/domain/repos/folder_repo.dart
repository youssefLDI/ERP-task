import 'package:erptask/features/folders/domain/entities/folder.dart';

abstract class FolderRepo {
  // Create folder
  Future<Folder> createFolder({
    required String name,
    String? parentId,
    required String userId,
  });

  // Get all folders for a user
  Future<List<Folder>> getUserFolders(String userId);

  // Get folder by ID
  Future<Folder?> getFolderById(String folderId);

  // Get subfolders of a parent folder
  Future<List<Folder>> getSubfolders(String parentId);

  // Get root folders (folders with no parent)
  Future<List<Folder>> getRootFolders(String userId);

  // Update folder
  Future<Folder> updateFolder(Folder folder);

  // Delete folder
  Future<void> deleteFolder(String folderId);

  // Add document to folder
  Future<void> addDocumentToFolder({
    required String folderId,
    required String documentId,
  });

  // Remove document from folder
  Future<void> removeDocumentFromFolder({
    required String folderId,
    required String documentId,
  });

  // Move folder to another parent
  Future<Folder> moveFolder({required String folderId, String? newParentId});

  // Get folder path (breadcrumb)
  Future<List<Folder>> getFolderPath(String folderId);
}

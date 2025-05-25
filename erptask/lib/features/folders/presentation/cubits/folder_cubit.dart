import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erptask/features/folders/domain/entities/folder.dart';
import 'package:erptask/features/folders/domain/repos/folder_repo.dart';
import 'package:erptask/features/folders/presentation/cubits/folder_states.dart';

class FolderCubit extends Cubit<FolderState> {
  final FolderRepo folderRepo;

  List<Folder> _folders = [];
  List<Folder> _currentFolderPath = [];
  Folder? _currentFolder;
  String? _currentParentId;

  FolderCubit({required this.folderRepo}) : super(FolderInitial());

  // Getters
  List<Folder> get folders => _folders;
  List<Folder> get currentFolderPath => _currentFolderPath;
  Folder? get currentFolder => _currentFolder;
  String? get currentParentId => _currentParentId;

  // Create folder
  Future<void> createFolder({
    required String name,
    String? parentId,
    required String userId,
  }) async {
    try {
      emit(FolderLoading());

      final folder = await folderRepo.createFolder(
        name: name,
        parentId: parentId,
        userId: userId,
      );

      _folders.add(folder);
      emit(FolderCreated(folder));

      // Refresh current view
      if (parentId == _currentParentId) {
        await loadFolders(userId: userId, parentId: parentId);
      }
    } catch (e) {
      emit(FolderError('Failed to create folder: $e'));
    }
  }

  // Load folders (root or subfolder)
  Future<void> loadFolders({required String userId, String? parentId}) async {
    try {
      emit(FolderLoading());

      List<Folder> folders;
      if (parentId == null) {
        folders = await folderRepo.getRootFolders(userId);
      } else {
        folders = await folderRepo.getSubfolders(parentId);
        // Also load the folder path for breadcrumb
        _currentFolderPath = await folderRepo.getFolderPath(parentId);
        emit(FolderPathLoaded(_currentFolderPath));
      }

      _folders = folders;
      _currentParentId = parentId;
      emit(FoldersLoaded(_folders));
    } catch (e) {
      emit(FolderError('Failed to load folders: $e'));
    }
  }

  // Load all user folders
  Future<void> loadAllUserFolders(String userId) async {
    try {
      emit(FolderLoading());

      _folders = await folderRepo.getUserFolders(userId);
      emit(FoldersLoaded(_folders));
    } catch (e) {
      emit(FolderError('Failed to load user folders: $e'));
    }
  }

  // Load single folder
  Future<void> loadFolder(String folderId) async {
    try {
      emit(FolderLoading());

      final folder = await folderRepo.getFolderById(folderId);
      if (folder != null) {
        _currentFolder = folder;
        emit(FolderLoaded(folder));
      } else {
        emit(FolderError('Folder not found'));
      }
    } catch (e) {
      emit(FolderError('Failed to load folder: $e'));
    }
  }

  // Update folder
  Future<void> updateFolder(Folder folder) async {
    try {
      emit(FolderLoading());

      final updatedFolder = await folderRepo.updateFolder(folder);

      // Update in local list
      final index = _folders.indexWhere((f) => f.id == updatedFolder.id);
      if (index != -1) {
        _folders[index] = updatedFolder;
      }

      _currentFolder = updatedFolder;
      emit(FolderUpdated(updatedFolder));
      emit(FoldersLoaded(_folders));
    } catch (e) {
      emit(FolderError('Failed to update folder: $e'));
    }
  }

  // Delete folder
  Future<void> deleteFolder(String folderId) async {
    try {
      emit(FolderLoading());

      await folderRepo.deleteFolder(folderId);

      // Remove from local list
      _folders.removeWhere((folder) => folder.id == folderId);

      emit(FolderDeleted('Folder deleted successfully'));
      emit(FoldersLoaded(_folders));
    } catch (e) {
      emit(FolderError('Failed to delete folder: $e'));
    }
  }

  // Move folder
  Future<void> moveFolder({
    required String folderId,
    String? newParentId,
  }) async {
    try {
      emit(FolderLoading());

      final movedFolder = await folderRepo.moveFolder(
        folderId: folderId,
        newParentId: newParentId,
      );

      // Update in local list
      final index = _folders.indexWhere((f) => f.id == movedFolder.id);
      if (index != -1) {
        _folders[index] = movedFolder;
      }

      emit(FolderMoved(movedFolder));
      emit(FoldersLoaded(_folders));
    } catch (e) {
      emit(FolderError('Failed to move folder: $e'));
    }
  }

  // Add document to folder
  Future<void> addDocumentToFolder({
    required String folderId,
    required String documentId,
  }) async {
    try {
      emit(FolderLoading());

      await folderRepo.addDocumentToFolder(
        folderId: folderId,
        documentId: documentId,
      );

      emit(DocumentAddedToFolder('Document added to folder successfully'));
    } catch (e) {
      emit(FolderError('Failed to add document to folder: $e'));
    }
  }

  // Remove document from folder
  Future<void> removeDocumentFromFolder({
    required String folderId,
    required String documentId,
  }) async {
    try {
      emit(FolderLoading());

      await folderRepo.removeDocumentFromFolder(
        folderId: folderId,
        documentId: documentId,
      );

      emit(
        DocumentRemovedFromFolder('Document removed from folder successfully'),
      );
    } catch (e) {
      emit(FolderError('Failed to remove document from folder: $e'));
    }
  }

  // Navigate to folder (load subfolders)
  Future<void> navigateToFolder({
    required String folderId,
    required String userId,
  }) async {
    await loadFolders(userId: userId, parentId: folderId);
  }

  // Navigate back (go to parent folder)
  Future<void> navigateBack({required String userId}) async {
    if (_currentFolderPath.isNotEmpty) {
      // Remove current folder from path and get parent
      _currentFolderPath.removeLast();
      final parentId =
          _currentFolderPath.isNotEmpty ? _currentFolderPath.last.id : null;
      await loadFolders(userId: userId, parentId: parentId);
    } else {
      // Go to root
      await loadFolders(userId: userId, parentId: null);
    }
  }

  // Reset state
  void resetState() {
    _folders = [];
    _currentFolderPath = [];
    _currentFolder = null;
    _currentParentId = null;
    emit(FolderInitial());
  }

  // Get folders for selection (used in dialogs)
  List<Folder> getFoldersForSelection({String? excludeFolderId}) {
    return _folders.where((folder) => folder.id != excludeFolderId).toList();
  }
}

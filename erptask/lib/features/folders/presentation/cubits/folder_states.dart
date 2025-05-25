import 'package:erptask/features/folders/domain/entities/folder.dart';

abstract class FolderState {}

// Initial state
class FolderInitial extends FolderState {}

// Loading state
class FolderLoading extends FolderState {}

// Folders loaded successfully
class FoldersLoaded extends FolderState {
  final List<Folder> folders;
  FoldersLoaded(this.folders);
}

// Single folder loaded
class FolderLoaded extends FolderState {
  final Folder folder;
  FolderLoaded(this.folder);
}

// Folder created successfully
class FolderCreated extends FolderState {
  final Folder folder;
  FolderCreated(this.folder);
}

// Folder updated successfully
class FolderUpdated extends FolderState {
  final Folder folder;
  FolderUpdated(this.folder);
}

// Folder deleted successfully
class FolderDeleted extends FolderState {
  final String message;
  FolderDeleted(this.message);
}

// Folder moved successfully
class FolderMoved extends FolderState {
  final Folder folder;
  FolderMoved(this.folder);
}

// Document added to folder
class DocumentAddedToFolder extends FolderState {
  final String message;
  DocumentAddedToFolder(this.message);
}

// Document removed from folder
class DocumentRemovedFromFolder extends FolderState {
  final String message;
  DocumentRemovedFromFolder(this.message);
}

// Folder path loaded (breadcrumb)
class FolderPathLoaded extends FolderState {
  final List<Folder> path;
  FolderPathLoaded(this.path);
}

// Error state
class FolderError extends FolderState {
  final String message;
  FolderError(this.message);
}

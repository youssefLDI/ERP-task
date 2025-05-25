import 'package:erptask/features/documents/domain/entities/document.dart';

abstract class DocumentState {}

// Initial state
class DocumentInitial extends DocumentState {}

// Loading state
class DocumentLoading extends DocumentState {}

// Upload progress state
class DocumentUploading extends DocumentState {
  final double progress;
  DocumentUploading(this.progress);
}

// Documents loaded successfully
class DocumentsLoaded extends DocumentState {
  final List<Document> documents;
  DocumentsLoaded(this.documents);
}

// Single document loaded
class DocumentLoaded extends DocumentState {
  final Document document;
  DocumentLoaded(this.document);
}

// Document uploaded successfully
class DocumentUploaded extends DocumentState {
  final Document document;
  DocumentUploaded(this.document);
}

// Document updated successfully
class DocumentUpdated extends DocumentState {
  final Document document;
  DocumentUpdated(this.document);
}

// Document deleted successfully
class DocumentDeleted extends DocumentState {
  final String message;
  DocumentDeleted(this.message);
}

// Error state
class DocumentError extends DocumentState {
  final String message;
  DocumentError(this.message);
}

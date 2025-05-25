import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erptask/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:erptask/features/documents/presentation/cubits/document_cubit.dart';
import 'package:erptask/features/documents/presentation/cubits/document_states.dart';
import 'package:erptask/features/documents/presentation/pages/upload_document_page.dart';
import 'package:erptask/features/documents/presentation/pages/update_document_page.dart';
import 'package:erptask/features/documents/presentation/pages/document_details_page.dart';
import 'package:erptask/features/documents/presentation/components/document_card.dart';
import 'package:erptask/features/documents/presentation/components/search_bar.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  void _loadDocuments() {
    final userId = context.read<AuthCubit>().currentUser?.uid;
    if (userId != null) {
      context.read<DocumentCubit>().loadUserDocuments(userId);
    }
  }

  void _searchDocuments() {
    final userId = context.read<AuthCubit>().currentUser?.uid;
    final query = _searchController.text.trim();

    if (userId != null) {
      if (query.isEmpty && _selectedTags.isEmpty) {
        context.read<DocumentCubit>().clearSearch(userId);
      } else {
        context.read<DocumentCubit>().searchDocuments(
          userId: userId,
          query: query.isEmpty ? null : query,
          tags: _selectedTags.isEmpty ? null : _selectedTags,
        );
      }
    }
  }

  void _navigateToUpload() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UploadDocumentPage()),
    ).then((_) => _loadDocuments());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _navigateToUpload, icon: const Icon(Icons.add)),
          IconButton(
            onPressed: () {
              context.read<AuthCubit>().logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DocumentSearchBar(
              controller: _searchController,
              onSearch: _searchDocuments,
              onClear: () {
                _searchController.clear();
                _selectedTags.clear();
                _loadDocuments();
              },
            ),
          ),

          // Documents List
          Expanded(
            child: BlocConsumer<DocumentCubit, DocumentState>(
              listener: (context, state) {
                if (state is DocumentError) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                } else if (state is DocumentDeleted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                if (state is DocumentLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is DocumentsLoaded) {
                  if (state.documents.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No documents found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap + to upload your first document',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _loadDocuments(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.documents.length,
                      itemBuilder: (context, index) {
                        final document = state.documents[index];
                        return DocumentCard(
                          document: document,
                          onDelete: () {
                            _showDeleteConfirmation(document.id);
                          },
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        DocumentDetailsPage(document: document),
                              ),
                            );
                          },
                          onUpdate: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        UpdateDocumentPage(document: document),
                              ),
                            );
                            _loadDocuments();
                          },
                        );
                      },
                    ),
                  );
                } else {
                  return const Center(
                    child: Text('Welcome! Upload your first document.'),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToUpload,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmation(String documentId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Document'),
            content: const Text(
              'Are you sure you want to delete this document? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<DocumentCubit>().deleteDocument(documentId);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}

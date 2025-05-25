import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erptask/features/folders/domain/entities/folder.dart';
import 'package:erptask/features/documents/presentation/cubits/document_cubit.dart';
import 'package:erptask/features/documents/domain/entities/document.dart';
import 'package:erptask/features/documents/presentation/pages/document_details_page.dart';

class FolderDocumentsPage extends StatefulWidget {
  final Folder folder;
  const FolderDocumentsPage({super.key, required this.folder});

  @override
  State<FolderDocumentsPage> createState() => _FolderDocumentsPageState();
}

class _FolderDocumentsPageState extends State<FolderDocumentsPage> {
  List<Document> _documents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  void _loadDocuments() async {
    setState(() => _loading = true);
    final cubit = context.read<DocumentCubit>();
    final userId = widget.folder.userId;
    await cubit.loadUserDocuments(userId);
    setState(() {
      _documents =
          cubit.documents
              .where((doc) => doc.folderId == widget.folder.id)
              .toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Documents in "${widget.folder.name}"'),
        centerTitle: true,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _documents.isEmpty
              ? const Center(child: Text('No documents in this folder.'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _documents.length,
                itemBuilder: (context, index) {
                  final document = _documents[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(document.title),
                      subtitle: Text(document.fileName),
                      trailing: const Icon(Icons.chevron_right),
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
                    ),
                  );
                },
              ),
    );
  }
}

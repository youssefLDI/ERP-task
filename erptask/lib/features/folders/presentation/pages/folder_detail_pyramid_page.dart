import 'package:flutter/material.dart';
import 'package:erptask/features/folders/domain/entities/folder.dart';
import 'package:erptask/features/documents/domain/entities/document.dart';
import 'package:erptask/features/documents/presentation/pages/document_details_page.dart';

class FolderDetailPyramidPage extends StatelessWidget {
  final Folder folder;
  final List<Folder> allFolders;
  final List<Document>? allDocuments;
  const FolderDetailPyramidPage({
    super.key,
    required this.folder,
    required this.allFolders,
    this.allDocuments,
  });

  List<Folder> _getSubfolders(String parentId) {
    return allFolders.where((f) => f.parentId == parentId).toList();
  }

  List<Document> _getDocuments(String folderId) {
    return allDocuments?.where((d) => d.folderId == folderId).toList() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Folder Details'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildPyramid(context, folder, 0),
      ),
    );
  }

  Widget _buildPyramid(BuildContext context, Folder folder, int level) {
    final subfolders = _getSubfolders(folder.id);
    final documents = _getDocuments(folder.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 24.0 * level),
          child: Row(
            children: [
              Icon(Icons.folder, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Text(
                folder.name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        ...documents.map(
          (doc) => Padding(
            padding: EdgeInsets.only(left: 24.0 * (level + 1)),
            child: ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: Text(doc.title),
              subtitle: Text(doc.fileName),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DocumentDetailsPage(document: doc),
                  ),
                );
              },
            ),
          ),
        ),
        ...subfolders.map(
          (sub) => GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FolderDetailPyramidPage(
                        folder: sub,
                        allFolders: allFolders,
                        allDocuments: allDocuments,
                      ),
                ),
              );
            },
            child: _buildPyramid(context, sub, level + 1),
          ),
        ),
      ],
    );
  }
}

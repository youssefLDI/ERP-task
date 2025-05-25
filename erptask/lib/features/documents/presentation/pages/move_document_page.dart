import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erptask/features/documents/domain/entities/document.dart';
import 'package:erptask/features/documents/presentation/cubits/document_cubit.dart';
import 'package:erptask/features/folders/presentation/pages/folder_selector.dart';
import 'package:erptask/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:erptask/features/folders/domain/repos/folder_repo.dart';

class MoveDocumentPage extends StatefulWidget {
  final Document document;
  const MoveDocumentPage({super.key, required this.document});

  @override
  State<MoveDocumentPage> createState() => _MoveDocumentPageState();
}

class _MoveDocumentPageState extends State<MoveDocumentPage> {
  String? _selectedFolderId;
  String? _selectedFolderName;
  String? _currentFolderName;
  bool _isMoving = false;

  @override
  void initState() {
    super.initState();
    _selectedFolderId = widget.document.folderId;
    _fetchCurrentFolderName();
  }

  void _fetchCurrentFolderName() async {
    if (widget.document.folderId != null) {
      final folderRepo = context.read<FolderRepo>();
      final folder = await folderRepo.getFolderById(widget.document.folderId!);
      setState(() {
        _currentFolderName = folder?.name;
      });
    } else {
      setState(() {
        _currentFolderName = 'No folder';
      });
    }
  }

  void _moveDocument() async {
    if (_selectedFolderId == widget.document.folderId) {
      Navigator.pop(context); // No change
      return;
    }
    setState(() => _isMoving = true);
    await context.read<DocumentCubit>().moveDocumentToFolder(
      document: widget.document,
      newFolderId: _selectedFolderId,
    );
    setState(() => _isMoving = false);
    if (mounted) {
      Navigator.pop(context, true); // Return true to indicate successful move
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Move Document'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Current Folder:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(_currentFolderName ?? 'No folder'),
            const SizedBox(height: 24),
            Text(
              'Select New Folder:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(_selectedFolderName ?? 'No folder selected'),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Choose Folder'),
                  onPressed: () async {
                    final userId = context.read<AuthCubit>().currentUser?.uid;
                    if (userId == null) return;
                    final folder = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => FolderSelectorPage(userId: userId),
                      ),
                    );
                    if (folder != null) {
                      setState(() {
                        _selectedFolderId = folder.id;
                        _selectedFolderName = folder.name;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isMoving ? null : _moveDocument,
              child:
                  _isMoving
                      ? const CircularProgressIndicator()
                      : const Text('Move Document'),
            ),
          ],
        ),
      ),
    );
  }
}

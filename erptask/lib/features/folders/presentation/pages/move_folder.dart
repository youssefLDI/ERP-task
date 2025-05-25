import 'package:erptask/features/folders/presentation/cubits/folder_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erptask/features/folders/domain/entities/folder.dart';
import 'package:erptask/features/folders/presentation/cubits/folder_cubit.dart';

class MoveFolderDialog extends StatefulWidget {
  final Folder folder;
  final List<Folder> availableFolders;

  const MoveFolderDialog({
    super.key,
    required this.folder,
    required this.availableFolders,
  });

  @override
  State<MoveFolderDialog> createState() => _MoveFolderDialogState();
}

class _MoveFolderDialogState extends State<MoveFolderDialog> {
  String? _selectedParentId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedParentId = widget.folder.parentId;
  }

  @override
  Widget build(BuildContext context) {
    // Filter out the folder itself and its descendants to prevent circular references
    final validFolders =
        widget.availableFolders
            .where(
              (f) =>
                  f.id != widget.folder.id && !_isDescendant(f, widget.folder),
            )
            .toList();

    return BlocListener<FolderCubit, FolderState>(
      listener: (context, state) {
        if (state is FolderMoved) {
          setState(() => _isLoading = false);
          Navigator.of(context).pop(state.folder);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Folder moved successfully')),
          );
        } else if (state is FolderError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is FolderLoading) {
          setState(() => _isLoading = true);
        }
      },
      child: AlertDialog(
        title: Text('Move "${widget.folder.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select the new parent folder:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Current location info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Location:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.folder.parentId == null
                        ? 'Root folder'
                        : _getParentFolderName(widget.folder.parentId!),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Parent folder selection
            DropdownButtonFormField<String?>(
              value: _selectedParentId,
              decoration: const InputDecoration(
                labelText: 'New Parent Folder',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder_open),
              ),
              hint: const Text('Select new parent folder'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.home, size: 20),
                      SizedBox(width: 8),
                      Text('Root folder'),
                    ],
                  ),
                ),
                ...validFolders.map((folder) {
                  return DropdownMenuItem<String?>(
                    value: folder.id,
                    child: Row(
                      children: [
                        const Icon(Icons.folder, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            folder.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedParentId = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Warning if moving to same location
            if (_selectedParentId == widget.folder.parentId)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The folder is already in this location.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed:
                _isLoading || _selectedParentId == widget.folder.parentId
                    ? null
                    : _moveFolder,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Move'),
          ),
        ],
      ),
    );
  }

  void _moveFolder() {
    final folderCubit = context.read<FolderCubit>();
    folderCubit.moveFolder(
      folderId: widget.folder.id,
      newParentId: _selectedParentId,
    );
  }

  String _getParentFolderName(String parentId) {
    final parentFolder = widget.availableFolders.firstWhere(
      (f) => f.id == parentId,
      orElse:
          () => Folder(
            id: '',
            name: 'Unknown',
            userId: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
    );
    return parentFolder.name;
  }

  bool _isDescendant(Folder folder, Folder ancestorFolder) {
    return folder.parentId == ancestorFolder.id ||
        ancestorFolder.subfolderIds.contains(folder.id);
  }
}

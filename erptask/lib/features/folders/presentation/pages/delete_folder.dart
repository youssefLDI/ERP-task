import 'package:erptask/features/folders/presentation/cubits/folder_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erptask/features/folders/domain/entities/folder.dart';
import 'package:erptask/features/folders/presentation/cubits/folder_cubit.dart';

class DeleteFolderDialog extends StatefulWidget {
  final Folder folder;

  const DeleteFolderDialog({super.key, required this.folder});

  @override
  State<DeleteFolderDialog> createState() => _DeleteFolderDialogState();
}

class _DeleteFolderDialogState extends State<DeleteFolderDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final hasContent =
        widget.folder.documentIds.isNotEmpty ||
        widget.folder.subfolderIds.isNotEmpty;

    return BlocListener<FolderCubit, FolderState>(
      listener: (context, state) {
        if (state is FolderDeleted) {
          setState(() => _isLoading = false);
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
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
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Delete Folder'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  const TextSpan(text: 'Are you sure you want to delete "'),
                  TextSpan(
                    text: widget.folder.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '"?'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Folder content info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    hasContent
                        ? Colors.red.withOpacity(0.1)
                        : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border:
                    hasContent
                        ? Border.all(color: Colors.red.withOpacity(0.3))
                        : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This folder contains:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        size: 16,
                        color: hasContent ? Colors.red[600] : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.folder.documentIds.length} documents',
                        style: TextStyle(
                          color: hasContent ? Colors.red[600] : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.folder,
                        size: 16,
                        color: hasContent ? Colors.red[600] : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.folder.subfolderIds.length} subfolders',
                        style: TextStyle(
                          color: hasContent ? Colors.red[600] : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Warning message
            if (hasContent) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Warning:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• All subfolders will be deleted recursively\n• Documents will be moved out of this folder\n• This action cannot be undone',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This folder is empty and can be safely deleted.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed:
                _isLoading ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _deleteFolder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteFolder() {
    final folderCubit = context.read<FolderCubit>();
    folderCubit.deleteFolder(widget.folder.id);
  }
}

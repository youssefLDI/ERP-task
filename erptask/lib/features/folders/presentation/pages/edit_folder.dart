import 'package:erptask/features/folders/presentation/cubits/folder_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erptask/features/folders/domain/entities/folder.dart';
import 'package:erptask/features/folders/presentation/cubits/folder_cubit.dart';

class EditFolderDialog extends StatefulWidget {
  final Folder folder;

  const EditFolderDialog({super.key, required this.folder});

  @override
  State<EditFolderDialog> createState() => _EditFolderDialogState();
}

class _EditFolderDialogState extends State<EditFolderDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.folder.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FolderCubit, FolderState>(
      listener: (context, state) {
        if (state is FolderUpdated) {
          setState(() => _isLoading = false);
          Navigator.of(context).pop(state.folder);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Folder updated successfully')),
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
        title: const Text('Edit Folder'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Folder name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Folder Name',
                  hintText: 'Enter folder name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Folder name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Folder name must be at least 2 characters';
                  }
                  if (value.trim().length > 50) {
                    return 'Folder name must be less than 50 characters';
                  }
                  return null;
                },
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 16),

              // Folder info
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
                      'Folder Information',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.insert_drive_file, size: 16),
                        const SizedBox(width: 8),
                        Text('${widget.folder.documentIds.length} documents'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.folder, size: 16),
                        const SizedBox(width: 8),
                        Text('${widget.folder.subfolderIds.length} subfolders'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Created: ${_formatDate(widget.folder.createdAt)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _updateFolder,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _updateFolder() {
    if (_formKey.currentState!.validate()) {
      final updatedFolder = widget.folder.copyWith(
        name: _nameController.text.trim(),
      );

      final folderCubit = context.read<FolderCubit>();
      folderCubit.updateFolder(updatedFolder);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

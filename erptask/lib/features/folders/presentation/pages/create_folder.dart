import 'package:erptask/features/folders/presentation/cubits/folder_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erptask/features/folders/domain/entities/folder.dart';
import 'package:erptask/features/folders/presentation/cubits/folder_cubit.dart';

class CreateFolderDialog extends StatefulWidget {
  final String userId;
  final String? parentId;
  final List<Folder> availableFolders;

  const CreateFolderDialog({
    super.key,
    required this.userId,
    this.parentId,
    this.availableFolders = const [],
  });

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedParentId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedParentId = widget.parentId;
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
        if (state is FolderCreated) {
          setState(() => _isLoading = false);
          Navigator.of(context).pop(state.folder);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Folder created successfully')),
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
        title: const Text('Create New Folder'),
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

              // Parent folder selection
              if (widget.availableFolders.isNotEmpty) ...[
                Text(
                  'Parent Folder (Optional)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedParentId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.folder_open),
                  ),
                  hint: const Text('Select parent folder'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('None (Root folder)'),
                    ),
                    ...widget.availableFolders.map((folder) {
                      return DropdownMenuItem<String>(
                        value: folder.id,
                        child: Text(folder.name),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedParentId = (value == '' ? null : value);
                    });
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _createFolder,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createFolder() {
    if (_formKey.currentState!.validate()) {
      final folderCubit = context.read<FolderCubit>();
      folderCubit.createFolder(
        name: _nameController.text.trim(),
        parentId: (_selectedParentId == '' ? null : _selectedParentId),
        userId: widget.userId,
      );
    }
  }
}

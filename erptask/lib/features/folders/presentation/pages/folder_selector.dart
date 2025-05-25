import 'package:erptask/features/folders/presentation/cubits/folder_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erptask/features/folders/domain/entities/folder.dart';
import 'package:erptask/features/folders/presentation/cubits/folder_cubit.dart';
import 'package:erptask/features/auth/presentation/cubits/auth_cubit.dart';

class FolderSelectorPage extends StatefulWidget {
  final String userId;
  final String title;
  final String? excludeFolderId;
  final bool allowRoot;

  const FolderSelectorPage({
    super.key,
    required this.userId,
    this.title = 'Select Folder',
    this.excludeFolderId,
    this.allowRoot = true,
  });

  @override
  State<FolderSelectorPage> createState() => _FolderSelectorPageState();
}

class _FolderSelectorPageState extends State<FolderSelectorPage> {
  Folder? _selectedFolder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthCubit>().currentUser?.uid;
      if (userId != null) {
        context.read<FolderCubit>().loadFolders(userId: userId, parentId: null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        leading:
            Navigator.of(context).canPop()
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    final cubit = context.read<FolderCubit>();
                    if (cubit.currentFolderPath.isNotEmpty) {
                      final parentPath =
                          cubit.currentFolderPath.map((f) => f.id).toList();
                      parentPath.removeLast();
                      final parentId =
                          parentPath.isNotEmpty ? parentPath.last : null;
                      final userId = context.read<AuthCubit>().currentUser?.uid;
                      if (userId != null) {
                        cubit.loadFolders(userId: userId, parentId: parentId);
                      }
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                )
                : null,
        actions: [
          if (widget.allowRoot && _selectedFolder == null)
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Select Root'),
            ),
          if (_selectedFolder != null)
            TextButton(
              onPressed: () => Navigator.pop(context, _selectedFolder),
              child: const Text('Select'),
            ),
        ],
      ),
      body: BlocConsumer<FolderCubit, FolderState>(
        listener: (context, state) {
          if (state is FolderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Location:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCurrentLocationText(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_selectedFolder != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        child: Text(
                          'Selected: ${_selectedFolder!.name}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(child: _buildFoldersList(state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFoldersList(FolderState state) {
    if (state is FolderLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final cubit = context.read<FolderCubit>();
    final currentFolders =
        cubit.folders
            .where((folder) => folder.id != widget.excludeFolderId)
            .toList();

    if (currentFolders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No subfolders available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'You can select the current location or go back.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: currentFolders.length,
      itemBuilder: (context, index) {
        final folder = currentFolders[index];
        final isSelected = _selectedFolder?.id == folder.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: isSelected ? 4 : 1,
            color:
                isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
            child: ListTile(
              leading: Icon(
                Icons.folder,
                color:
                    isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.amber[700],
                size: 32,
              ),
              title: Text(
                folder.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '${folder.documentIds.length} documents • ${folder.subfolderIds.length} subfolders',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                    ),
                  if (folder.subfolderIds.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () {
                        final userId =
                            context.read<AuthCubit>().currentUser?.uid;
                        if (userId != null) {
                          cubit.loadFolders(
                            userId: userId,
                            parentId: folder.id,
                          );
                        }
                      },
                      tooltip: 'Open folder',
                    ),
                  ],
                ],
              ),
              onTap: () {
                setState(() {
                  _selectedFolder = isSelected ? null : folder;
                });
              },
              onLongPress:
                  folder.subfolderIds.isNotEmpty
                      ? () {
                        final userId =
                            context.read<AuthCubit>().currentUser?.uid;
                        if (userId != null) {
                          cubit.loadFolders(
                            userId: userId,
                            parentId: folder.id,
                          );
                        }
                      }
                      : null,
            ),
          ),
        );
      },
    );
  }

  String _getCurrentLocationText() {
    final cubit = context.read<FolderCubit>();
    if (cubit.currentFolderPath.isEmpty) {
      return 'Root folder';
    }
    return cubit.currentFolderPath.map((f) => f.name).join(' > ');
  }
}

import 'package:flutter/material.dart';
import 'package:erptask/features/folders/domain/entities/folder.dart';

class FolderGridView extends StatelessWidget {
  final List<Folder> folders;
  final Function(Folder) onFolderTap;
  final Function(Folder)? onFolderEdit;
  final Function(Folder)? onFolderDelete;
  final Function(Folder)? onFolderMove;
  final bool showActions;

  const FolderGridView({
    super.key,
    required this.folders,
    required this.onFolderTap,
    this.onFolderEdit,
    this.onFolderDelete,
    this.onFolderMove,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No folders found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first folder to get started',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        return _FolderGridItem(
          folder: folder,
          onTap: () => onFolderTap(folder),
          onEdit: onFolderEdit != null ? () => onFolderEdit!(folder) : null,
          onDelete:
              onFolderDelete != null ? () => onFolderDelete!(folder) : null,
          onMove: onFolderMove != null ? () => onFolderMove!(folder) : null,
          showActions: showActions,
        );
      },
    );
  }
}

class _FolderGridItem extends StatelessWidget {
  final Folder folder;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMove;
  final bool showActions;

  const _FolderGridItem({
    required this.folder,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onMove,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with folder icon and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.folder,
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                  if (showActions)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit?.call();
                            break;
                          case 'move':
                            onMove?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'move',
                              child: Row(
                                children: [
                                  Icon(Icons.drive_file_move, size: 20),
                                  SizedBox(width: 8),
                                  Text('Move'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Folder name
              Text(
                folder.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // Folder stats
              Row(
                children: [
                  Icon(
                    Icons.insert_drive_file,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${folder.documentIds.length}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.folder, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${folder.subfolderIds.length}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Last updated
              Text(
                'Updated ${_formatDate(folder.updatedAt)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}

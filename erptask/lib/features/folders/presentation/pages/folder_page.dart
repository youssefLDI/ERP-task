import 'package:erptask/features/folders/presentation/components/folder_gridview.dart';
import 'package:erptask/features/folders/presentation/cubits/folder_states.dart';
import 'package:erptask/features/folders/presentation/pages/create_folder.dart';
import 'package:erptask/features/folders/presentation/pages/delete_folder.dart';
import 'package:erptask/features/folders/presentation/pages/edit_folder.dart';
import 'package:erptask/features/folders/presentation/pages/move_folder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erptask/features/folders/domain/entities/folder.dart';
import 'package:erptask/features/folders/presentation/cubits/folder_cubit.dart';
import 'package:erptask/features/folders/presentation/components/folder_list_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:erptask/features/folders/presentation/pages/folder_detail_pyramid_page.dart';
import 'package:erptask/features/documents/presentation/cubits/document_cubit.dart';
import 'package:erptask/features/documents/domain/entities/document.dart';
import 'package:erptask/features/auth/presentation/cubits/auth_cubit.dart';

class FoldersPage extends StatefulWidget {
  final String userId;

  const FoldersPage({super.key, required this.userId});

  @override
  State<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends State<FoldersPage> {
  bool _isGridView = true;

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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folders'),
        elevation: 0,
        actions: [
          // View toggle
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
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
          return _buildContent(state);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateFolderDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(FolderState state) {
    if (state is FolderLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final docCubit = context.read<DocumentCubit>();
    final documents = docCubit.documents;
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('folders')
              .where(
                'userId',
                isEqualTo: context.read<AuthCubit>().currentUser?.uid,
              )
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allFolders =
            snapshot.data?.docs
                .map(
                  (doc) => Folder.fromJson(doc.data() as Map<String, dynamic>),
                )
                .toList() ??
            [];
        final rootFolders =
            allFolders.where((f) => f.parentId == null).toList();
        if (_isGridView) {
          return FolderGridView(
            folders: rootFolders,
            onFolderTap:
                (folder) =>
                    _showFolderDetails(context, folder, allFolders, documents),
            onFolderEdit: _showEditFolderDialog,
            onFolderDelete: _showDeleteFolderDialog,
            onFolderMove: _showMoveFolderDialog,
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rootFolders.length,
            itemBuilder: (context, index) {
              final folder = rootFolders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FolderListTile(
                  folder: folder,
                  onTap:
                      () => _showFolderDetails(
                        context,
                        folder,
                        allFolders,
                        documents,
                      ),
                  onEdit: () => _showEditFolderDialog(folder),
                  onDelete: () => _showDeleteFolderDialog(folder),
                  onMove: () => _showMoveFolderDialog(folder),
                ),
              );
            },
          );
        }
      },
    );
  }

  void _showFolderDetails(
    BuildContext context,
    Folder folder,
    List<Folder> allFolders,
    List<Document> allDocuments,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FolderDetailPyramidPage(
              folder: folder,
              allFolders: allFolders,
              allDocuments: allDocuments,
            ),
      ),
    );
  }

  void _showCreateFolderDialog() {
    final cubit = context.read<FolderCubit>();
    final userId = context.read<AuthCubit>().currentUser?.uid;
    showDialog(
      context: context,
      builder:
          (context) => BlocProvider.value(
            value: cubit,
            child: CreateFolderDialog(
              userId: userId!,
              parentId: cubit.currentParentId,
              availableFolders: cubit.folders,
            ),
          ),
    );
  }

  void _showEditFolderDialog(Folder folder) {
    final cubit = context.read<FolderCubit>();
    showDialog(
      context: context,
      builder:
          (context) => BlocProvider.value(
            value: cubit,
            child: EditFolderDialog(folder: folder),
          ),
    );
  }

  void _showMoveFolderDialog(Folder folder) {
    final cubit = context.read<FolderCubit>();
    showDialog(
      context: context,
      builder:
          (context) => BlocProvider.value(
            value: cubit,
            child: MoveFolderDialog(
              folder: folder,
              availableFolders: cubit.folders,
            ),
          ),
    );
  }

  void _showDeleteFolderDialog(Folder folder) {
    final cubit = context.read<FolderCubit>();
    showDialog(
      context: context,
      builder:
          (context) => BlocProvider.value(
            value: cubit,
            child: DeleteFolderDialog(folder: folder),
          ),
    );
  }
}

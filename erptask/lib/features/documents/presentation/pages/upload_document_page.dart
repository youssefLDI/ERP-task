import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:erptask/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:erptask/features/documents/presentation/cubits/document_cubit.dart';
import 'package:erptask/features/documents/presentation/cubits/document_states.dart';
import 'package:erptask/features/auth/presentation/componenets/my_button.dart';
import 'package:erptask/features/auth/presentation/componenets/my_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:erptask/features/documents/presentation/components/file_type_validator.dart';
import 'package:erptask/features/folders/presentation/pages/folder_selector.dart';

class UploadDocumentPage extends StatefulWidget {
  const UploadDocumentPage({super.key});

  @override
  State<UploadDocumentPage> createState() => _UploadDocumentPageState();
}

class _UploadDocumentPageState extends State<UploadDocumentPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _aclEmailController = TextEditingController();
  String _selectedPermission = 'view only';
  List<Map<String, dynamic>> _accessControlList = [];

  File? _selectedFile;
  Uint8List? _webFileBytes;
  String? _webFileName;
  bool _isUploading = false;
  String? _selectedFolderId;
  String? _selectedFolderName;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'xlsx',
          'xls',
          'ppt',
          'pptx',
          'jpg',
          'jpeg',
          'png',
        ],
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result != null) {
        if (kIsWeb) {
          if (result.files.single.bytes != null) {
            setState(() {
              _webFileBytes = result.files.single.bytes;
              _webFileName = result.files.single.name;
              _selectedFile = null;
            });
          }
        } else if (result.files.single.path != null) {
          setState(() {
            _selectedFile = File(result.files.single.path!);
            _webFileBytes = null;
            _webFileName = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  void _uploadDocument() async {
    if (!kIsWeb && _selectedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a file')));
      return;
    }
    if (kIsWeb && (_webFileBytes == null || _webFileName == null)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a file')));
      return;
    }
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final tagsText = _tagsController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }
    final userId = context.read<AuthCubit>().currentUser?.uid;
    final userEmail = context.read<AuthCubit>().currentUser?.email;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
      return;
    }
    List<String> tags =
        tagsText.isNotEmpty
            ? tagsText
                .split(',')
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList()
            : [];
    // File type and size validation
    String? validationError;
    if (kIsWeb) {
      validationError = FileTypeValidator.validate(
        fileName: _webFileName!,
        fileSize: _webFileBytes!.length,
      );
    } else {
      final fileName = _selectedFile!.path.split('/').last;
      final fileSize = await _selectedFile!.length();
      validationError = FileTypeValidator.validate(
        fileName: fileName,
        fileSize: fileSize,
      );
    }
    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }
    // Ensure uploader is owner
    final acl = List<Map<String, dynamic>>.from(_accessControlList);
    if (userEmail != null && !acl.any((e) => e['userEmail'] == userEmail)) {
      acl.add({'userEmail': userEmail, 'permission': 'owner'});
    }
    if (kIsWeb) {
      context.read<DocumentCubit>().uploadDocument(
        webFileBytes: _webFileBytes,
        webFileName: _webFileName,
        title: title,
        description: description,
        tags: tags,
        userId: userId,
        folderId: _selectedFolderId,
        accessControlList: acl,
      );
    } else {
      context.read<DocumentCubit>().uploadDocument(
        file: _selectedFile!,
        title: title,
        description: description,
        tags: tags,
        userId: userId,
        folderId: _selectedFolderId,
        accessControlList: acl,
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _aclEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document'), centerTitle: true),
      body: BlocConsumer<DocumentCubit, DocumentState>(
        listener: (context, state) {
          if (state is DocumentUploading) {
            setState(() {
              _isUploading = true;
            });
          } else if (state is DocumentUploaded) {
            setState(() {
              _isUploading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Document uploaded successfully!')),
            );
            Navigator.pop(context);
          } else if (state is DocumentError) {
            setState(() {
              _isUploading = false;
            });
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Folder selection
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Folder (optional)',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedFolderName ?? 'No folder selected',
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.folder_open),
                              label: const Text('Choose Folder'),
                              onPressed: () async {
                                final userId =
                                    context.read<AuthCubit>().currentUser?.uid;
                                if (userId == null) return;
                                final folder = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            FolderSelectorPage(userId: userId),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // File Selection
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select File',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (!kIsWeb && _selectedFile != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedFile!.path.split('/').last,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      FutureBuilder<int>(
                                        future: _selectedFile!.length(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return Text(
                                              _formatFileSize(snapshot.data!),
                                              style: TextStyle(
                                                color:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            );
                                          }
                                          return const SizedBox();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedFile = null;
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (kIsWeb &&
                            _webFileBytes != null &&
                            _webFileName != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _webFileName!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatFileSize(_webFileBytes!.length),
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _webFileBytes = null;
                                      _webFileName = null;
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isUploading ? null : _pickFile,
                            icon: const Icon(Icons.attach_file),
                            label: Text(
                              _selectedFile == null && _webFileBytes == null
                                  ? 'Choose File'
                                  : 'Change File',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Supported formats: PDF, DOC, DOCX, TXT, XLS, XLSX, PPT, PPTX, JPG, PNG',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Document Information
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Document Information',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        MyTextField(
                          controller: _titleController,
                          hintText: "Document Title*",
                          obscureText: false,
                        ),

                        const SizedBox(height: 12),

                        // Description
                        TextField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            hintText: 'Description (optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceVariant.withOpacity(0.3),
                          ),
                          maxLines: 3,
                          textInputAction: TextInputAction.newline,
                        ),

                        const SizedBox(height: 12),

                        // Tags
                        TextField(
                          controller: _tagsController,
                          decoration: InputDecoration(
                            hintText: 'Tags (comma separated, optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceVariant.withOpacity(0.3),
                            helperText: 'Example: work, important, project',
                          ),
                        ),

                        // ACL Section
                        const SizedBox(height: 16),
                        Text(
                          'Access Control List',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _aclEmailController,
                                decoration: const InputDecoration(
                                  hintText: 'User email',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _selectedPermission,
                              items: const [
                                DropdownMenuItem(
                                  value: 'view only',
                                  child: Text('View Only'),
                                ),
                                DropdownMenuItem(
                                  value: 'view and edit',
                                  child: Text('View and Edit'),
                                ),
                                DropdownMenuItem(
                                  value: 'owner',
                                  child: Text('Owner'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null)
                                  setState(() => _selectedPermission = value);
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                final email = _aclEmailController.text.trim();
                                if (email.isNotEmpty &&
                                    !_accessControlList.any(
                                      (e) => e['userEmail'] == email,
                                    )) {
                                  setState(() {
                                    _accessControlList.add({
                                      'userEmail': email,
                                      'permission': _selectedPermission,
                                    });
                                    _aclEmailController.clear();
                                  });
                                }
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_accessControlList.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ..._accessControlList.map(
                                (entry) => ListTile(
                                  title: Text(entry['userEmail'] ?? ''),
                                  subtitle: Text(entry['permission'] ?? ''),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _accessControlList.remove(entry);
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Upload Progress
                if (state is DocumentUploading) ...[
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('Uploading...'),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: state.progress),
                          const SizedBox(height: 8),
                          Text('${(state.progress * 100).toInt()}%'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Upload Button
                MyButton(
                  onTap: _isUploading ? null : _uploadDocument,
                  text: _isUploading ? "Uploading..." : "Upload Document",
                ),

                const SizedBox(height: 20),

                // Help Text
                Card(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tips',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Use descriptive titles for easy searching\n'
                          '• Add relevant tags to organize your documents\n'
                          '• Maximum file size: 10 MB\n'
                          '• Files are stored securely in the cloud',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

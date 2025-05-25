import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erptask/features/documents/domain/entities/document.dart';
import 'package:erptask/features/documents/presentation/cubits/document_cubit.dart';
import 'package:erptask/features/auth/presentation/componenets/my_button.dart';
import 'package:erptask/features/auth/presentation/componenets/my_text_field.dart';
import 'package:erptask/features/auth/presentation/cubits/auth_cubit.dart';

class UpdateDocumentPage extends StatefulWidget {
  final Document document;
  const UpdateDocumentPage({super.key, required this.document});

  @override
  State<UpdateDocumentPage> createState() => _UpdateDocumentPageState();
}

class _UpdateDocumentPageState extends State<UpdateDocumentPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  final TextEditingController _aclEmailController = TextEditingController();
  String _selectedPermission = 'view only';
  List<Map<String, dynamic>> _accessControlList = [];
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.document.title);
    _descriptionController = TextEditingController(
      text: widget.document.description,
    );
    _tagsController = TextEditingController(
      text: widget.document.tags.join(', '),
    );
    _accessControlList = List<Map<String, dynamic>>.from(
      widget.document.accessControlList,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _aclEmailController.dispose();
    super.dispose();
  }

  void _updateDocument() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final tagsText = _tagsController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
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
    setState(() {
      _isUpdating = true;
    });
    final updatedDoc = widget.document.copyWith(
      title: title,
      description: description,
      tags: tags,
      accessControlList: _accessControlList,
    );
    await context.read<DocumentCubit>().updateDocument(updatedDoc);
    setState(() {
      _isUpdating = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document updated successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = context.read<AuthCubit>().currentUser?.email;
    final isOwner =
        userEmail != null &&
        widget.document.accessControlList.any(
          (e) => e['userEmail'] == userEmail && e['permission'] == 'owner',
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Update Document'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    MyTextField(
                      controller: _titleController,
                      hintText: "Document Title*",
                      obscureText: false,
                    ),
                    const SizedBox(height: 12),
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
                    if (isOwner) ...[
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            MyButton(
              onTap: _isUpdating ? null : _updateDocument,
              text: _isUpdating ? "Updating..." : "Update Document",
            ),
          ],
        ),
      ),
    );
  }
}

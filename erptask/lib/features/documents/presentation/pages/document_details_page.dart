import 'package:flutter/material.dart';
import 'package:erptask/features/documents/domain/entities/document.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:erptask/features/documents/presentation/pages/move_document_page.dart';
import 'package:erptask/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:erptask/features/documents/presentation/cubits/document_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DocumentDetailsPage extends StatelessWidget {
  final Document document;
  const DocumentDetailsPage({super.key, required this.document});

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openDocument(BuildContext context) async {
    try {
      final uri = Uri.parse(document.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open file.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document Details'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (document.description.isNotEmpty) ...[
                  Text(
                    document.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      document.fileName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.type_specimen, size: 20),
                    const SizedBox(width: 8),
                    Text(document.fileType.toUpperCase()),
                    const SizedBox(width: 16),
                    const Icon(Icons.data_object, size: 20),
                    const SizedBox(width: 8),
                    Text(_formatFileSize(document.fileSize)),
                  ],
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    Text('Created: ${_formatDate(document.createdAt)}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.update, size: 20),
                    const SizedBox(width: 8),
                    Text('Updated: ${_formatDate(document.updatedAt)}'),
                  ],
                ),
                const SizedBox(height: 16),
                if (document.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    children:
                        document.tags
                            .map((tag) => Chip(label: Text(tag)))
                            .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openDocument(context),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open/Download File'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final moved = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => MoveDocumentPage(document: document),
                        ),
                      );
                      if (moved == true) {
                        // Refresh the document list
                        final userId =
                            context.read<AuthCubit>().currentUser?.uid;
                        if (userId != null) {
                          context.read<DocumentCubit>().loadUserDocuments(
                            userId,
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.drive_file_move),
                    label: const Text('Move Document'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FileTypeValidator {
  static const List<String> allowedExtensions = [
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
  ];
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  static String? validate({required String fileName, required int fileSize}) {
    final ext = fileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      return 'Unsupported file type: .$ext';
    }
    if (fileSize > maxFileSizeBytes) {
      return 'File size exceeds 10 MB limit.';
    }
    return null;
  }
}

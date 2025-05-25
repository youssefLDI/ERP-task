class Document {
  final String id;
  final String title;
  final String description;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final List<String> tags;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? folderId;
  final List<Map<String, dynamic>> accessControlList;

  Document({
    required this.id,
    required this.title,
    required this.description,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.tags,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.folderId,
    this.accessControlList = const [],
  });

  // Document --> JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'tags': tags,
      'userId': userId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'folderId': folderId,
      'accessControlList': accessControlList,
    };
  }

  // JSON --> Document
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      fileName: json['fileName'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileType: json['fileType'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      userId: json['userId'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
      folderId: json['folderId'],
      accessControlList:
          (json['accessControlList'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
    );
  }

  // Copy with method for updates
  Document copyWith({
    String? id,
    String? title,
    String? description,
    String? fileName,
    String? fileUrl,
    String? fileType,
    int? fileSize,
    List<String>? tags,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? folderId,
    List<Map<String, dynamic>>? accessControlList,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      tags: tags ?? this.tags,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      folderId: folderId ?? this.folderId,
      accessControlList: accessControlList ?? this.accessControlList,
    );
  }
}

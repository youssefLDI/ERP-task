class Folder {
  final String id;
  final String name;
  final String? parentId;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> documentIds;
  final List<String> subfolderIds;

  Folder({
    required this.id,
    required this.name,
    this.parentId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.documentIds = const [],
    this.subfolderIds = const [],
  });

  // Folder --> JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'userId': userId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'documentIds': documentIds,
      'subfolderIds': subfolderIds,
    };
  }

  // JSON --> Folder
  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      parentId: json['parentId'],
      userId: json['userId'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
      documentIds: List<String>.from(json['documentIds'] ?? []),
      subfolderIds: List<String>.from(json['subfolderIds'] ?? []),
    );
  }

  // Copy with method for updates
  Folder copyWith({
    String? id,
    String? name,
    String? parentId,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? documentIds,
    List<String>? subfolderIds,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      documentIds: documentIds ?? this.documentIds,
      subfolderIds: subfolderIds ?? this.subfolderIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Folder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

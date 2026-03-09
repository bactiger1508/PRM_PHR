class TagEntity {
  final int? id;
  final String tagName;
  final int documentCount;
  final DateTime? createdAt;

  TagEntity({
    this.id,
    required this.tagName,
    this.documentCount = 0,
    this.createdAt,
  });
}

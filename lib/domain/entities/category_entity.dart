class CategoryEntity {
  final int? id;
  final String name;
  final String? description;
  final int documentCount;

  CategoryEntity({
    this.id,
    required this.name,
    this.description,
    this.documentCount = 0,
  });
}

class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final bool isSystem;
  final String? userId;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    required this.isSystem,
    this.userId,
    required this.isActive,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      isSystem: json['isSystem'] as bool? ?? false,
      userId: json['userId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'isSystem': isSystem,
      'userId': userId,
      'isActive': isActive,
    };
  }
}

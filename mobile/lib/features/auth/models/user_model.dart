class UserModel {
  final String id;
  final String telegramId;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.telegramId,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      telegramId: json['telegramId'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'telegramId': telegramId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

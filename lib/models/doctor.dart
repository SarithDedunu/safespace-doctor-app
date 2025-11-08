class Doctor {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String category;
  final String? profilepicture;
  final bool isAvailable;
  final DateTime createdAt;

  Doctor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.category,
    this.profilepicture,
    required this.isAvailable,
    required this.createdAt,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      phone: json['phone'] ?? 'N/A',
      category: json['category'] ?? 'N/A',
      profilepicture: json['profilepicture'],
      isAvailable: json['avb_status'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

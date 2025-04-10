class Member {
  final String id;
  final String name;
  final String rollNumber;
  final String? email;
  final String? phone;
  final DateTime? joinDate;
  final bool isActive;

  Member({
    required this.id,
    required this.name,
    required this.rollNumber,
    this.email,
    this.phone,
    this.joinDate,
    this.isActive = true,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      name: json['name'],
      rollNumber: json['roll_number'],
      email: json['email'],
      phone: json['phone'],
      joinDate: json['join_date'] != null ? DateTime.parse(json['join_date']) : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'roll_number': rollNumber,
      'email': email,
      'phone': phone,
      'join_date': joinDate?.toIso8601String(),
      'is_active': isActive,
    };
  }
}

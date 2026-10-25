// lib/models/admin_model.dart
class AdminModel {
  final String uid;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final List<String> permissions; // YENİ

  AdminModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.role = 'Head Coach',
    this.isActive = true,
    this.permissions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'role': role,
      'isActive': isActive,
      'permissions': permissions,
    };
  }

  factory AdminModel.fromMap(String uid, Map<String, dynamic> map) {
    List<String> parsedPermissions = [];
    if (map['permissions'] != null) {
      if (map['permissions'] is List) {
        parsedPermissions = (map['permissions'] as List)
            .where((e) => e != null)
            .map((e) => e.toString())
            .toList();
      } else if (map['permissions'] is Map) {
        parsedPermissions = (map['permissions'] as Map)
            .values
            .map((e) => e.toString())
            .toList();
      }
    }

    return AdminModel(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'Head Coach',
      isActive: map['isActive'] ?? true,
      permissions: parsedPermissions,
    );
  }

  String get initials {
    if (fullName.isEmpty) return '??';
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, 2).toUpperCase();
  }
}
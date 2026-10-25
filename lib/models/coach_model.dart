class CoachModel {
  final String uid;
  final String fullName;
  final String email;
  final String role; // 'Head Coach', 'Coach', 'Reception', 'Manager'
  final String phone;
  final String sportFocus;
  final String branch;
  final bool isActive;
  final List<String> permissions;
  final DateTime createdAt;
  final String createdBy;

  CoachModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone = '',
    this.sportFocus = 'All',
    this.branch = '',
    this.isActive = true,
    this.permissions = const [],
    required this.createdAt,
    this.createdBy = '',
  });

  bool hasPermission(String permission) {
    return permissions.contains(permission) || role == 'Head Coach' || role == 'Owner';
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'role': role,
      'phone': phone,
      'sportFocus': sportFocus,
      'branch': branch,
      'isActive': isActive,
      'permissions': permissions,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory CoachModel.fromMap(String uid, Map<String, dynamic> map) {
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

    return CoachModel(
      uid: uid,
      fullName: map['fullName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'Coach',
      phone: map['phone']?.toString() ?? '',
      sportFocus: map['sportFocus']?.toString() ?? 'All',
      branch: map['branch']?.toString() ?? '',
      isActive: map['isActive'] != false,
      permissions: parsedPermissions,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      createdBy: map['createdBy']?.toString() ?? '',
    );
  }

  CoachModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? role,
    String? phone,
    String? sportFocus,
    String? branch,
    bool? isActive,
    List<String>? permissions,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return CoachModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      sportFocus: sportFocus ?? this.sportFocus,
      branch: branch ?? this.branch,
      isActive: isActive ?? this.isActive,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
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

// Permission sabitleri
class CoachPermissions {
  static const String managePlayers = 'manage_players';
  static const String manageClasses = 'manage_classes';
  static const String scanQr = 'scan_qr';
  static const String manageAttendance = 'manage_attendance';
  static const String manageMemberships = 'manage_memberships';
  static const String managePayments = 'manage_payments';
  static const String viewReports = 'view_reports';
  static const String sendAnnouncements = 'send_announcements';
  static const String manageFights = 'manage_fights';
  static const String manageTournaments = 'manage_tournaments';
  static const String managePackages = 'manage_packages';
  static const String manageCoaches = 'manage_coaches';
  static const String manageBranches = 'manage_branches';
  static const String markCoachAttendance = 'mark_coach_attendance'; // YENİ
  static const String viewCoachAttendance = 'view_coach_attendance'; // YENİ
  static const String dailyAttend = 'daily_attend'; // YENİ
  static const String viewRewards = 'view_rewards';       // YENİ
  static const String manageRewards = 'manage_rewards';   // YENİ

  static const Map<String, String> labels = {
    managePlayers: 'Manage Players',
    manageClasses: 'Manage Classes',
    scanQr: 'Scan QR / Check-in',
    manageAttendance: 'Manage Attendance',
    manageMemberships: 'Manage Memberships',
    managePayments: 'Record Payments',
    viewReports: 'View Reports',
    sendAnnouncements: 'Send Announcements',
    manageFights: 'Manage Fights',
    manageTournaments: 'Manage Tournaments',
    managePackages: 'Manage Packages',
    manageCoaches: 'Manage Coaches',
    manageBranches: 'Manage Branches',
    dailyAttend: 'Daily Attend & Combos', // YENİ
    markCoachAttendance: 'Coach Check-In',       // YENİ
    viewCoachAttendance: 'View Coach Attendance', // YENİ
    viewRewards: 'View Rewards',       // YENİ
    manageRewards: 'Manage Rewards',   // YENİ
  };

  static const Map<String, String> descriptions = {
    managePlayers: 'Add, edit, and delete player accounts',
    manageClasses: 'Create and manage class schedules',
    scanQr: 'Scan player QR codes for check-in',
    manageAttendance: 'View and manage attendance records',
    manageMemberships: 'Add/update player memberships',
    managePayments: 'Record and view payments',
    viewReports: 'Access analytics and reports',
    sendAnnouncements: 'Broadcast announcements to members',
    manageFights: 'Log fight results',
    manageTournaments: 'Create and manage tournaments',
    managePackages: 'Create and manage subscription packages',
    manageCoaches: 'Add and manage coach accounts',
    manageBranches: 'Create and manage branches',
    dailyAttend: 'Daily combos and attendance with photos', // YENİ
    markCoachAttendance: 'Check in for daily training',       // YENİ
    viewCoachAttendance: 'See all coaches attendance',        // YENİ
    viewRewards: 'See coach rewards and bonuses',      // YENİ
    manageRewards: 'Give rewards, bonuses & discounts', // YENİ
  };
}
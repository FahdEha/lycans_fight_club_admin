class BranchModel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String managerName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? closedAt;
  final int capacity;
  final String notes;
  final List<String> sports;      // YENİ - Branch'te sunulan sporlar
  final String locationLink;       // YENİ - Google Maps link
  final double latitude;           // YENİ
  final double longitude;          // YENİ

  BranchModel({
    required this.id,
    required this.name,
    required this.address,
    this.phone = '',
    this.managerName = '',
    this.isActive = true,
    required this.createdAt,
    this.closedAt,
    this.capacity = 0,
    this.notes = '',
    this.sports = const [],
    this.locationLink = '',
    this.latitude = 0,
    this.longitude = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'managerName': managerName,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
      'capacity': capacity,
      'notes': notes,
      'sports': sports,
      'locationLink': locationLink,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory BranchModel.fromMap(String id, Map<String, dynamic> map) {
    // Sports parsing
    List<String> parsedSports = [];
    if (map['sports'] != null) {
      if (map['sports'] is List) {
        parsedSports = (map['sports'] as List)
            .where((e) => e != null)
            .map((e) => e.toString())
            .toList();
      } else if (map['sports'] is Map) {
        parsedSports = (map['sports'] as Map)
            .values
            .map((e) => e.toString())
            .toList();
      }
    }

    return BranchModel(
      id: id,
      name: map['name']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      managerName: map['managerName']?.toString() ?? '',
      isActive: map['isActive'] != false,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      closedAt: map['closedAt'] != null
          ? DateTime.tryParse(map['closedAt'].toString())
          : null,
      capacity: (map['capacity'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString() ?? '',
      sports: parsedSports,
      locationLink: map['locationLink']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

  BranchModel copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? managerName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? closedAt,
    int? capacity,
    String? notes,
    List<String>? sports,
    String? locationLink,
    double? latitude,
    double? longitude,
  }) {
    return BranchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      managerName: managerName ?? this.managerName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      closedAt: closedAt ?? this.closedAt,
      capacity: capacity ?? this.capacity,
      notes: notes ?? this.notes,
      sports: sports ?? this.sports,
      locationLink: locationLink ?? this.locationLink,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

// Spor seçenekleri - sabit
class BranchSports {
  static const List<String> all = [
    'MMA',
    'Boxing',
    'Kickboxing',
    'Muay Thai',
    'Jiu-Jitsu',
    'Brazilian Jiu-Jitsu',
    'Wrestling',
    'Judo',
    'Karate',
    'Taekwondo',
    'Strength & Conditioning',
    'CrossFit',
    'Yoga',
    'Pilates',
  ];

  // İkon ve renk için (opsiyonel)
  static String getIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'mma':
        return 'mma';
      case 'boxing':
        return 'boxing';
      case 'kickboxing':
        return 'kickboxing';
      case 'muay thai':
        return 'muay_thai';
      case 'jiu-jitsu':
      case 'brazilian jiu-jitsu':
        return 'jiu_jitsu';
      default:
        return 'default';
    }
  }
}
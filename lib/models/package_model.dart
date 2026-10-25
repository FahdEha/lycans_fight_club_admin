class PackageModel {
  final String id;
  final String name;
  final double price;
  final int durationDays;
  final List<String> features;
  final bool isFeatured;
  final bool isActive;
  final bool isUnlimited;
  final int maxSessions;
  final int weeklySessions;
  final List<String> trainingDays;
  final String branch;
  final Map<String, String> trainingTimes; // YENİ - Gün -> Saat eşleşmesi

  PackageModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    this.features = const [],
    this.isFeatured = false,
    this.isActive = true,
    this.isUnlimited = true,
    this.maxSessions = 0,
    this.weeklySessions = 0,
    this.trainingDays = const [],
    this.branch = '',
    this.trainingTimes = const {}, // Varsayılan boş map
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'durationDays': durationDays,
      'features': features,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'isUnlimited': isUnlimited,
      'maxSessions': maxSessions,
      'weeklySessions': weeklySessions,
      'trainingDays': trainingDays,
      'branch': branch,
      'trainingTimes': trainingTimes,
    };
  }

  factory PackageModel.fromMap(String key, Map<String, dynamic> map) {
    final String packageId = map['id']?.toString() ?? key;

    List<String> parsedFeatures = [];
    if (map['features'] != null) {
      if (map['features'] is List) {
        parsedFeatures = (map['features'] as List)
            .where((e) => e != null)
            .map((e) => e.toString())
            .toList();
      } else if (map['features'] is Map) {
        parsedFeatures = (map['features'] as Map)
            .values
            .map((e) => e.toString())
            .toList();
      }
    }

    List<String> parsedTrainingDays = [];
    if (map['trainingDays'] != null) {
      if (map['trainingDays'] is List) {
        parsedTrainingDays = (map['trainingDays'] as List)
            .where((e) => e != null)
            .map((e) => e.toString())
            .toList();
      } else if (map['trainingDays'] is Map) {
        parsedTrainingDays = (map['trainingDays'] as Map)
            .values
            .map((e) => e.toString())
            .toList();
      }
    }

    Map<String, String> parsedTrainingTimes = {};
    if (map['trainingTimes'] != null && map['trainingTimes'] is Map) {
      (map['trainingTimes'] as Map).forEach((k, v) {
        parsedTrainingTimes[k.toString()] = v.toString();
      });
    }

    final int maxSessions = (map['maxSessions'] as num?)?.toInt() ?? 0;
    final int weeklySessions = (map['weeklySessions'] as num?)?.toInt() ?? (maxSessions / 4).ceil();

    return PackageModel(
      id: packageId,
      name: map['name']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      durationDays: (map['durationDays'] as num?)?.toInt() ?? 30,
      features: parsedFeatures,
      isFeatured: map['isFeatured'] == true,
      isActive: map['isActive'] != false,
      isUnlimited: map['isUnlimited'] != false,
      maxSessions: maxSessions,
      weeklySessions: weeklySessions,
      trainingDays: parsedTrainingDays,
      branch: map['branch']?.toString() ?? '',
      trainingTimes: parsedTrainingTimes,
    );
  }
}
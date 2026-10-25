class PlanRequestModel {
  final String id;
  final String userId;
  final String playerName;
  final String currentPackageId;
  final String currentPackageName;
  final double currentPackagePrice;
  final String requestedPackageId;
  final String requestedPackageName;
  final double requestedPackagePrice;
  final int requestedPackageDurationDays;
  final bool requestedIsUnlimited;
  final int requestedMaxSessions;
  final int requestedWeeklySessions;
  final String type; // 'upgrade' or 'downgrade'
  final String status; // 'pending', 'approved', 'declined'
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String respondedBy;

  PlanRequestModel({
    required this.id,
    required this.userId,
    required this.playerName,
    this.currentPackageId = '',
    this.currentPackageName = '',
    this.currentPackagePrice = 0,
    required this.requestedPackageId,
    required this.requestedPackageName,
    required this.requestedPackagePrice,
    required this.requestedPackageDurationDays,
    this.requestedIsUnlimited = true,
    this.requestedMaxSessions = 0,
    this.requestedWeeklySessions = 0,
    this.type = 'upgrade',
    this.status = 'pending',
    required this.createdAt,
    this.respondedAt,
    this.respondedBy = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'playerName': playerName,
      'currentPackageId': currentPackageId,
      'currentPackageName': currentPackageName,
      'currentPackagePrice': currentPackagePrice,
      'requestedPackageId': requestedPackageId,
      'requestedPackageName': requestedPackageName,
      'requestedPackagePrice': requestedPackagePrice,
      'requestedPackageDurationDays': requestedPackageDurationDays,
      'requestedIsUnlimited': requestedIsUnlimited,
      'requestedMaxSessions': requestedMaxSessions,
      'requestedWeeklySessions': requestedWeeklySessions,
      'type': type,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'respondedBy': respondedBy,
    };
  }

  factory PlanRequestModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return PlanRequestModel(
      id: id,
      userId: map['userId']?.toString() ?? '',
      playerName: map['playerName']?.toString() ?? '',
      currentPackageId: map['currentPackageId']?.toString() ?? '',
      currentPackageName: map['currentPackageName']?.toString() ?? '',
      currentPackagePrice: (map['currentPackagePrice'] as num?)?.toDouble() ?? 0,
      requestedPackageId: map['requestedPackageId']?.toString() ?? '',
      requestedPackageName: map['requestedPackageName']?.toString() ?? '',
      requestedPackagePrice: (map['requestedPackagePrice'] as num?)?.toDouble() ?? 0,
      requestedPackageDurationDays: (map['requestedPackageDurationDays'] as num?)?.toInt() ?? 30,
      requestedIsUnlimited: map['requestedIsUnlimited'] != false,
      requestedMaxSessions: (map['requestedMaxSessions'] as num?)?.toInt() ?? 0,
      requestedWeeklySessions: (map['requestedWeeklySessions'] as num?)?.toInt() ?? 0,
      type: map['type']?.toString() ?? 'upgrade',
      status: map['status']?.toString() ?? 'pending',
      createdAt: DateTime.parse(map['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      respondedAt: map['respondedAt'] != null
          ? DateTime.tryParse(map['respondedAt'].toString())
          : null,
      respondedBy: map['respondedBy']?.toString() ?? '',
    );
  }

  PlanRequestModel copyWith({
    String? id,
    String? status,
    DateTime? respondedAt,
    String? respondedBy,
  }) {
    return PlanRequestModel(
      id: id ?? this.id,
      userId: userId,
      playerName: playerName,
      currentPackageId: currentPackageId,
      currentPackageName: currentPackageName,
      currentPackagePrice: currentPackagePrice,
      requestedPackageId: requestedPackageId,
      requestedPackageName: requestedPackageName,
      requestedPackagePrice: requestedPackagePrice,
      requestedPackageDurationDays: requestedPackageDurationDays,
      requestedIsUnlimited: requestedIsUnlimited,
      requestedMaxSessions: requestedMaxSessions,
      requestedWeeklySessions: requestedWeeklySessions,
      type: type,
      status: status ?? this.status,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      respondedBy: respondedBy ?? this.respondedBy,
    );
  }
}
class AttendanceModel {
  final String id;
  final String userId;
  final String playerName;
  final String classId; // YENİ - Coach lookup için
  final String className;
  final DateTime timestamp;
  final String status;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.playerName,
    this.classId = '', // YENİ
    required this.className,
    required this.timestamp,
    this.status = 'recorded',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'playerName': playerName,
      'classId': classId, // YENİ
      'className': className,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }

  factory AttendanceModel.fromMap(String id, Map<String, dynamic> map) {
    return AttendanceModel(
      id: id,
      userId: map['userId']?.toString() ?? '',
      playerName: map['playerName']?.toString() ?? '',
      classId: map['classId']?.toString() ?? '', // YENİ
      className: map['className']?.toString() ?? '',
      timestamp: DateTime.parse(
        map['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      status: map['status']?.toString() ?? 'recorded',
    );
  }
}
class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final String audience;
  final DateTime sentAt;
  final String sentBy;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    this.audience = 'All Members',
    required this.sentAt,
    this.sentBy = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'audience': audience,
      'sentAt': sentAt.toIso8601String(),
      'sentBy': sentBy,
    };
  }

  factory AnnouncementModel.fromMap(String id, Map<String, dynamic> map) {
    return AnnouncementModel(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      audience: map['audience'] ?? 'All Members',
      sentAt: DateTime.parse(map['sentAt'] ?? DateTime.now().toIso8601String()),
      sentBy: map['sentBy'] ?? '',
    );
  }
}
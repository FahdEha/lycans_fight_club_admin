class TournamentModel {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String venue;
  final String status; // registration_open, brackets_set, completed
  final int registeredCount;
  final int maxParticipants;
  final int weightClasses;
  final int ourFighters;

  TournamentModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.venue,
    this.status = 'registration_open',
    this.registeredCount = 0,
    this.maxParticipants = 96,
    this.weightClasses = 8,
    this.ourFighters = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'venue': venue,
      'status': status,
      'registeredCount': registeredCount,
      'maxParticipants': maxParticipants,
      'weightClasses': weightClasses,
      'ourFighters': ourFighters,
    };
  }

  factory TournamentModel.fromMap(String id, Map<String, dynamic> map) {
    return TournamentModel(
      id: id,
      name: map['name'] ?? '',
      startDate: DateTime.parse(map['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(map['endDate'] ?? DateTime.now().toIso8601String()),
      venue: map['venue'] ?? '',
      status: map['status'] ?? 'registration_open',
      registeredCount: map['registeredCount'] ?? 0,
      maxParticipants: map['maxParticipants'] ?? 96,
      weightClasses: map['weightClasses'] ?? 8,
      ourFighters: map['ourFighters'] ?? 0,
    );
  }
}
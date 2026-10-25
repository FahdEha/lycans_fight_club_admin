class PlayerModel {
  final String uid;
  final String fullName;
  final String phone;
  final String email;
  final String sport;
  final String level;
  final String weightClass;
  final String emergencyContact;
  final String emergencyPhone;
  final String guardian;
  final String membershipId;
  final String currentPackageId;
  final int playerNumber;
  final String branchId;    // YENİ
  final String branchName;  // YENİ
  final String rank;
  final int wins;
  final int losses;
  final int draws;
  final int winsByKO;
  final int winsByDecision;
  final DateTime joinDate;
  final double weight;
  final double height;
  final bool isActive;

  PlayerModel({
    required this.uid,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.sport,
    required this.level,
    required this.weightClass,
    required this.emergencyContact,
    required this.emergencyPhone,
    this.guardian = 'Not applicable',
    this.membershipId = '',
    this.currentPackageId = '',
    this.playerNumber = 0,
    this.branchId = '',       // YENİ
    this.branchName = '',     // YENİ
    this.rank = '01',
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.winsByKO = 0,
    this.winsByDecision = 0,
    required this.joinDate,
    this.weight = 0,
    this.height = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'sport': sport,
      'level': level,
      'weightClass': weightClass,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'guardian': guardian,
      'membershipId': membershipId,
      'currentPackageId': currentPackageId,
      'playerNumber': playerNumber,
      'branchId': branchId,       // YENİ
      'branchName': branchName,   // YENİ
      'rank': rank,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'winsByKO': winsByKO,
      'winsByDecision': winsByDecision,
      'joinDate': joinDate.toIso8601String(),
      'weight': weight,
      'height': height,
      'isActive': isActive,
    };
  }

  factory PlayerModel.fromMap(String key, Map<String, dynamic> map) {
    return PlayerModel(
      uid: key,
      fullName: map['fullName']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      sport: map['sport']?.toString() ?? '',
      level: map['level']?.toString() ?? '',
      weightClass: map['weightClass']?.toString() ?? '',
      emergencyContact: map['emergencyContact']?.toString() ?? '',
      emergencyPhone: map['emergencyPhone']?.toString() ?? '',
      guardian: map['guardian']?.toString() ?? 'Not applicable',
      membershipId: map['membershipId']?.toString() ?? '',
      currentPackageId: map['currentPackageId']?.toString() ?? '',
      playerNumber: (map['playerNumber'] as num?)?.toInt() ?? 0,
      branchId: map['branchId']?.toString() ?? '',       // YENİ
      branchName: map['branchName']?.toString() ?? '',   // YENİ
      rank: map['rank']?.toString() ?? '01',
      wins: (map['wins'] as num?)?.toInt() ?? 0,
      losses: (map['losses'] as num?)?.toInt() ?? 0,
      draws: (map['draws'] as num?)?.toInt() ?? 0,
      winsByKO: (map['winsByKO'] as num?)?.toInt() ?? 0,
      winsByDecision: (map['winsByDecision'] as num?)?.toInt() ?? 0,
      joinDate: DateTime.parse(
        map['joinDate']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      height: (map['height'] as num?)?.toDouble() ?? 0.0,
      isActive: map['isActive'] != false,
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

  String get displayBadge =>
      playerNumber > 0 ? playerNumber.toString() : initials;

  String get record => '$wins-$losses-$draws';
}
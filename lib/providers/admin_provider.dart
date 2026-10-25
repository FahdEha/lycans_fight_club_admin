import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/PlanRequestModel.dart';
import '../models/admin_model.dart';
import '../models/player_model.dart';
import '../models/coach_model.dart';
import '../models/class_model.dart';
import '../models/package_model.dart';
import '../models/invoice_model.dart';
import '../models/announcement_model.dart';
import '../models/attendance_model.dart';
import '../models/tournament_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/branch_model.dart';

class AdminProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  AdminModel? _admin;
  List<PlayerModel> _players = [];
  List<CoachModel> _coaches = [];
  List<ClassModel> _classes = [];
  List<PackageModel> _packages = [];
  List<InvoiceModel> _invoices = [];
  List<AnnouncementModel> _announcements = [];
  List<AttendanceModel> _attendance = [];
  List<TournamentModel> _tournaments = [];
  Map<String, dynamic> _dashboardStats = {};
  List<Map<String, dynamic>> _pendingUsers = [];
  List<BranchModel> _branches = [];
  List<BranchModel> get branches => _branches;
  List<Map<String, dynamic>> _coachAttendance = []; // YENİ

  // YENİ: temizlik için yukarı alındı
  List<Map<String, dynamic>> _memberships = [];
  List<Map<String, dynamic>> get memberships => _memberships;

  List<Map<String, dynamic>> _dailyCombos = [];
  List<Map<String, dynamic>> _dailyAttendances = [];
  List<Map<String, dynamic>> _coachRewards = [];

  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  // Getters
  AdminModel? get admin => _admin;
  List<PlayerModel> get players => _players;
  List<CoachModel> get coaches => _coaches;
  List<ClassModel> get classes => _classes;
  List<PackageModel> get packages => _packages;
  List<InvoiceModel> get invoices => _invoices;
  List<AnnouncementModel> get announcements => _announcements;
  List<AttendanceModel> get attendance => _attendance;
  List<TournamentModel> get tournaments => _tournaments;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  List<Map<String, dynamic>> get pendingUsers => _pendingUsers;
  List<Map<String, dynamic>> get coachAttendance => _coachAttendance; // YENİ
  List<Map<String, dynamic>> get dailyCombos => _dailyCombos;
  List<Map<String, dynamic>> get dailyAttendances => _dailyAttendances;
  List<Map<String, dynamic>> get coachRewards => _coachRewards;


  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        _authService.getAdminStream(user.uid).listen((admin) {
          _admin = admin;
          if (admin != null) {
            _isAuthenticated = true;
            _loadAllData();
          } else {
            _isAuthenticated = false;
            _authService.logout();
          }
          _isLoading = false;
          notifyListeners();
        });
      } else {
        _isAuthenticated = false;
        _admin = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _loadAllData() {
    _databaseService.getPlayersStream().listen((players) {
      _players = players;
      notifyListeners();
    });

    _databaseService.getCoachesStream().listen((coaches) {
      _coaches = coaches;
      notifyListeners();
    });

    _databaseService.getClassesStream().listen((classes) {
      _classes = classes;
      notifyListeners();
    });

    _databaseService.getPackagesStream().listen((packages) {
      _packages = packages;
      notifyListeners();
    });

    _databaseService.getInvoicesStream().listen((invoices) {
      _invoices = invoices;
      notifyListeners();
    });

    _databaseService.getAnnouncementsStream().listen((announcements) {
      _announcements = announcements;
      notifyListeners();
    });

    _databaseService.getAttendanceStream().listen((attendance) {
      _attendance = attendance;
      notifyListeners();
    });

    _databaseService.getTournamentsStream().listen((tournaments) {
      _tournaments = tournaments;
      notifyListeners();
    });

    _databaseService.getDashboardStatsStream().listen((stats) {
      _dashboardStats = stats;
      notifyListeners();
    });

    _databaseService.getMembershipsStream().listen((memberships) {
      _memberships = memberships;
      notifyListeners();
    });

    _databaseService.getBranchesStream().listen((branches) {
      _branches = branches;
      notifyListeners();
    });

    _databaseService.getPendingUsersStream().listen((pending) {
      _pendingUsers = pending;
      notifyListeners();
    });

    _databaseService.getCoachAttendanceStream().listen((records) {
      _coachAttendance = records;
      notifyListeners();
    });

    _databaseService.getDailyCombosStream().listen((list) {
      _dailyCombos = list;
      notifyListeners();
    });

    _databaseService.getDailyAttendancesStream().listen((list) {
      _dailyAttendances = list;
      notifyListeners();
    });

    _databaseService.getCoachRewardsStream().listen((rewards) {
      _coachRewards = rewards;
      notifyListeners();
    });
  }

  // Auth
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.login(email, password);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  // Players
  Future<void> updatePlayer(String uid, Map<String, dynamic> data) async {
    await _databaseService.updatePlayer(uid, data);
  }

  Future<void> deletePlayer(String uid) async {
    await _databaseService.deletePlayer(uid);
  }

  Future<void> updatePlayerLevel(String uid, String level) async {
    await _databaseService.updatePlayerLevel(uid, level);
  }

  Future<void> updatePlayerSport(String uid, String sport) async {
    await _databaseService.updatePlayerSport(uid, sport);
  }

  Future<void> addPlayerWithAuth({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String sport,
    required String level,
    required String weightClass,
  }) async {
    await _databaseService.addPlayerWithAuth(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      sport: sport,
      level: level,
      weightClass: weightClass,
    );
  }

  // Classes
  Future<void> addClass(ClassModel classModel) async {
    await _databaseService.addClass(classModel);
  }

  Future<void> updateClass(String id, Map<String, dynamic> data) async {
    await _databaseService.updateClass(id, data);
  }

  Future<void> deleteClass(String id) async {
    await _databaseService.deleteClass(id);
  }

  // Packages
  Future<void> addPackage(PackageModel package) async {
    await _databaseService.addPackage(package);
  }

  Future<void> updatePackage(String id, Map<String, dynamic> data) async {
    await _databaseService.updatePackage(id, data);
  }

  Future<void> deletePackage(String id) async {
    await _databaseService.deletePackage(id);
  }

  // Invoices & Payments
  Future<void> addInvoice(InvoiceModel invoice) async {
    await _databaseService.addInvoice(invoice);
  }

  // Branches
  Future<String> addBranch(BranchModel branch) async {
    final id = await _databaseService.addBranch(branch);
    return id;
  }

  Future<void> updateBranch(String id, Map<String, dynamic> data) async {
    await _databaseService.updateBranch(id, data);
  }

  Future<void> toggleBranchStatus(String id, bool isActive) async {
    await _databaseService.toggleBranchStatus(id, isActive);
  }

  Future<void> deleteBranch(String id) async {
    await _databaseService.deleteBranch(id);
  }

  // ============ RECORD PAYMENT (FIX) ============
  Future<void> recordPayment({
    required String userId,
    required String playerName,
    required String packageName,
    required double amount,
    required String paymentMethod,
    String? groupId,      // YENİ
    String? groupName,    // YENİ
  }) async {
    await _databaseService.recordPayment(
      userId: userId,
      playerName: playerName,
      packageName: packageName,
      amount: amount,
      paymentMethod: paymentMethod,
      staffName: _admin?.fullName ?? 'Admin',
      groupId: groupId,       // FIX: artık iletiliyor
      groupName: groupName,   // FIX: artık iletiliyor
    );
  }

  // Membership
  Future<void> freezeMembership(String userId) async {
    await _databaseService.freezeMembership(userId);
  }

  Future<void> unfreezeMembership(String userId) async {
    await _databaseService.unfreezeMembership(userId);
  }

  Future<void> extendMembership(String userId, int days) async {
    await _databaseService.extendMembership(userId, days);
  }

  // Announcements
  Future<void> sendAnnouncement(
      AnnouncementModel announcement, {
        List<String>? selectedPlayerIds,
      }) async {
    await _databaseService.sendAnnouncement(
      announcement,
      selectedPlayerIds: selectedPlayerIds,
    );
  }

  // Attendance
  Future<void> recordCheckIn({
    required String userId,
    required String playerName,
    required String className,
  }) async {
    await _databaseService.recordCheckIn(
      userId: userId,
      playerName: playerName,
      className: className,
    );
  }

  // Tournaments
  Future<void> addTournament(TournamentModel tournament) async {
    await _databaseService.addTournament(tournament);
  }

  Future<void> updateTournament(String id, Map<String, dynamic> data) async {
    await _databaseService.updateTournament(id, data);
  }

  Future<void> deleteTournament(String id) async {
    await _databaseService.deleteTournament(id);
  }

  Future<void> activatePendingUser({
    required Map<String, dynamic> pendingUser,
    required String packageId,
    required String packageName,
    required double packagePrice,
    required int packageDurationDays,
    required bool isUnlimited,
    required int maxSessions,
    required int weeklySessions,
    required String paymentMethod,
    String? groupId,      // YENİ
    String? groupName,    // YENİ
  }) async {
    await _databaseService.activatePendingUser(
      pendingUser: pendingUser,
      packageId: packageId,
      packageName: packageName,
      packagePrice: packagePrice,
      packageDurationDays: packageDurationDays,
      isUnlimited: isUnlimited,
      maxSessions: maxSessions,
      weeklySessions: weeklySessions,
      paymentMethod: paymentMethod,
      adminName: _admin?.fullName ?? 'Admin',
      groupId: groupId,       // YENİ
      groupName: groupName,   // YENİ
    );
  }

  Future<void> removePendingUser(String uid) async {
    await _databaseService.removePendingUser(uid);
  }

  Future<void> disablePendingUser(String uid, bool disable) async {
    await _databaseService.disablePendingUser(uid, disable);
  }

  // Fight Results
  Future<void> logFightResult({
    required String fighterUid,
    required String fighterName,
    required String opponentName,
    required String eventName,
    required String result,
    required String winType,
  }) async {
    await _databaseService.logFightResult(
      fighterUid: fighterUid,
      fighterName: fighterName,
      opponentName: opponentName,
      eventName: eventName,
      result: result,
      winType: winType,
    );
  }

  // Coach Notes
  Future<void> addCoachNote({
    required String userId,
    required String coachName,
    required String message,
  }) async {
    await _databaseService.addCoachNote(
      userId: userId,
      coachName: coachName,
      message: message,
    );
  }

  // Exercises
  Future<void> addExercise({
    required String userId,
    required String name,
    required String weekNumber,
    required int sets,
    required int reps,
    required int rounds,
    required int durationMinutes,
    required int restSeconds,
    required String category,
  }) async {
    await _databaseService.addExercise(
      userId: userId,
      name: name,
      weekNumber: weekNumber,
      sets: sets,
      reps: reps,
      rounds: rounds,
      durationMinutes: durationMinutes,
      restSeconds: restSeconds,
      category: category,
    );
  }

  Future<CoachModel?> createCoach({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String role,
    required String sportFocus,
    required String branch,
    required List<String> permissions,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final coach = await _authService.createCoach(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        role: role,
        sportFocus: sportFocus,
        branch: branch,
        permissions: permissions,
        createdBy: _admin?.fullName ?? 'Admin',
      );
      return coach;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<PlanRequestModel>> getPlayerPlanRequests(String userId) {
    return _databaseService.getPlayerPlanRequestsStream(userId);
  }

  Future<void> approvePlanRequest(PlanRequestModel request) async {
    await _databaseService.approvePlanRequest(
      request: request,
      adminName: _admin?.fullName ?? 'Admin',
    );
  }

  Future<void> declinePlanRequest(PlanRequestModel request) async {
    await _databaseService.declinePlanRequest(
      request: request,
      adminName: _admin?.fullName ?? 'Admin',
    );
  }

  Future<void> updateCoach(String uid, Map<String, dynamic> data) async {
    await _databaseService.updateCoach(uid, data);
  }

  Future<void> deleteCoach(String uid) async {
    await _databaseService.deleteCoach(uid);
  }

  Future<void> toggleCoachStatus(String uid, bool isActive) async {
    await _databaseService.toggleCoachStatus(uid, isActive);
  }

  Future<void> updateCoachPermissions(String uid, List<String> permissions) async {
    await _databaseService.updateCoachPermissions(uid, permissions);
  }

  // Current admin'in bir permission'ı var mı?
  bool hasPermission(String permission) {
    if (_admin == null) return false;
    if (_admin!.role == 'Head Coach' || _admin!.role == 'Owner') return true;
    return _admin!.permissions.contains(permission);
  }

  Stream<List<Map<String, dynamic>>> getPlayerExercises(String userId) {
    return _databaseService.getExercisesStream(userId);
  }

  Stream<List<Map<String, dynamic>>> getCoachNotes(String userId) {
    return _databaseService.getCoachNotesStream(userId);
  }

  Future<void> deleteExercise(String exerciseId) async {
    await _databaseService.deleteExercise(exerciseId);
  }

  Stream<List<Map<String, dynamic>>> getFightsStream() {
    return _databaseService.getFightsStream();
  }

  Future<void> updateFightResult(String fightId, String result, String winType) async {
    await _databaseService.updateFightResult(fightId, result, winType);
  }

  Future<void> deleteFight(String fightId) async {
    await _databaseService.deleteFight(fightId);
  }

  Stream<List<Map<String, dynamic>>> getBookedPlayersForClass(String classId) {
    return _databaseService.getBookedPlayersForClass(classId);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _databaseService.deleteAnnouncement(id);
  }

  Stream<Map<String, dynamic>?> getMembershipStatus(String userId) {
    return _databaseService.getMembershipStatusStream(userId);
  }

  Future<void> recordCheckInWithSessionUpdate({
    required String userId,
    required String playerName,
    required String className,
  }) async {
    await _databaseService.recordCheckInWithSessionUpdate(
      userId: userId,
      playerName: playerName,
      className: className,
    );
  }

  Future<void> markPlayerAbsent({
    required String userId,
    required String playerName,
    required String className,
  }) async {
    await _databaseService.markAbsent(
      userId: userId,
      playerName: playerName,
      className: className,
    );
  }

  // ============ COACH REWARDS ============
  Future<void> giveCoachReward({
    required String coachUid,
    required String coachName,
    required String coachRole,
    required String type,
    required String title,
    required String description,
    required double amount,
    required double discountPercent,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _admin == null) return;
    await _databaseService.giveCoachReward(
      coachUid: coachUid,
      coachName: coachName,
      coachRole: coachRole,
      type: type,
      title: title,
      description: description,
      amount: amount,
      discountPercent: discountPercent,
      givenBy: _admin!.fullName,
      givenByUid: uid,
    );
  }

  Future<void> deleteCoachReward(String id) async {
    await _databaseService.deleteCoachReward(id);
  }

  /// Belirli bir coach'un reward'larını getirir
  List<Map<String, dynamic>> getRewardsForCoach(String coachUid) {
    return _coachRewards
        .where((r) => r['coachUid'] == coachUid)
        .toList();
  }

  // ============ COACH ATTENDANCE ============
  Future<void> recordCoachAttendance({
    required String branchId,
    required String branchName,
    String note = '',
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _admin == null) return;
    await _databaseService.recordCoachAttendance(
      coachUid: uid,
      coachName: _admin!.fullName,
      coachRole: _admin!.role,
      branchId: branchId,
      branchName: branchName,
      note: note,
    );
  }

  Map<String, dynamic>? getTodayCheckIn(String coachUid) {
    final now = DateTime.now();
    final key =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      return _coachAttendance.firstWhere(
            (r) => r['coachUid'] == coachUid && r['date'] == key,
      );
    } catch (_) {
      return null;
    }
  }

  bool hasCheckedInToday(String coachUid) {
    return getTodayCheckIn(coachUid) != null;
  }

  // ============ DAILY COMBO ============
  Future<void> recordDailyCombo({
    required String combo,
    required String branchId,
    required String branchName,
    required String dateKey,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _admin == null) return;
    await _databaseService.recordDailyCombo(
      coachUid: uid,
      coachName: _admin!.fullName,
      coachRole: _admin!.role,
      combo: combo,
      branchId: branchId,
      branchName: branchName,
      dateKey: dateKey,
    );
  }

  Future<void> deleteDailyCombo(String id) async {
    await _databaseService.deleteDailyCombo(id);
  }

// ============ DAILY ATTENDANCE ============
  Future<void> recordDailyAttendance({
    required String groupId,
    required String groupName,
    required String branchId,
    required String branchName,
    required List<String> playerUids,
    required List<String> playerNames,
    required List<int> playerNumbers,
    required List<String> photoUrls,
    required String notes,
    required String dateKey,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _admin == null) return;
    await _databaseService.recordDailyAttendance(
      coachUid: uid,
      coachName: _admin!.fullName,
      groupId: groupId,
      groupName: groupName,
      branchId: branchId,
      branchName: branchName,
      playerUids: playerUids,
      playerNames: playerNames,
      playerNumbers: playerNumbers,
      photoUrls: photoUrls,
      notes: notes,
      dateKey: dateKey,
    );
  }

  Future<void> deleteDailyAttendance(String id) async {
    await _databaseService.deleteDailyAttendance(id);
  }

  /// Belirli bir gruba ait oyuncuları döndürür (membership.groupName/id üzerinden)
  List<PlayerModel> getPlayersForGroup(String groupId, String groupName) {
    final ids = <String>{};
    for (final m in _memberships) {
      final mUid = (m['userId'] ?? '').toString();
      final mGroupId = (m['groupId'] ?? '').toString();
      final mGroupName = (m['groupName'] ?? '').toString();
      final isActive = m['isActive'] == true || m['isActive'] == null;
      if (!isActive) continue;
      if (mGroupId == groupId || mGroupName == groupName) {
        ids.add(mUid);
      }
    }
    return _players.where((p) => ids.contains(p.uid)).toList()
      ..sort((a, b) => a.playerNumber.compareTo(b.playerNumber));
  }
}
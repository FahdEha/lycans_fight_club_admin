import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import '../models/PlanRequestModel.dart';
import '../models/branch_model.dart';
import '../models/player_model.dart';
import '../models/coach_model.dart';
import '../models/class_model.dart';
import '../models/package_model.dart';
import '../models/invoice_model.dart';
import '../models/announcement_model.dart';
import '../models/attendance_model.dart';
import '../models/tournament_model.dart';
import '../utils/constants.dart';

class DatabaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Map<String, dynamic> _convertMap(Map<Object?, Object?> map) {
    return Map<String, dynamic>.from(map);
  }

  // ============ YARDIMCI METODLAR ============

  // ============ PLAYERS ============
  Stream<List<PlayerModel>> getPlayersStream() {
    return _database.ref(AppConstants.usersPath).onValue.map((event) {
      final snapshot = event.snapshot;
      final List<PlayerModel> players = [];
      if (snapshot.exists && snapshot.value != null) {
        final map = _convertMap(snapshot.value as Map);
        map.forEach((key, value) {
          players.add(PlayerModel.fromMap(key, _convertMap(value as Map)));
        });
      }
      players.sort((a, b) => a.fullName.compareTo(b.fullName));
      return players;
    });
  }

  Future<void> updatePlayer(String uid, Map<String, dynamic> data) async {
    await _database.ref('${AppConstants.usersPath}/$uid').update(data);
  }

  Future<void> deletePlayer(String uid) async {
    await _database.ref('${AppConstants.usersPath}/$uid').remove();
  }

  Future<void> updatePlayerLevel(String uid, String level) async {
    await _database.ref('${AppConstants.usersPath}/$uid').update({'level': level});
  }

  Future<void> updatePlayerSport(String uid, String sport) async {
    await _database.ref('${AppConstants.usersPath}/$uid').update({'sport': sport});
  }

  // Firebase Auth ile oyuncu ekleme
  Future<void> addPlayerWithAuth({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String sport,
    required String level,
    required String weightClass,
  }) async {
    try {
      final auth = FirebaseAuth.instance;
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      final now = DateTime.now();

      await _database.ref('${AppConstants.usersPath}/$uid').set({
        'uid': uid,
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'sport': sport,
        'level': level,
        'weightClass': weightClass,
        'emergencyContact': fullName,
        'emergencyPhone': phone,
        'guardian': 'Not applicable',
        'membershipId': '',
        'rank': '01',
        'wins': 0,
        'losses': 0,
        'draws': 0,
        'winsByKO': 0,
        'winsByDecision': 0,
        'joinDate': now.toIso8601String(),
        'weight': 0,
        'height': 0,
        'isActive': true,
      });

      // Hoş geldin bildirimi
      final notifRef = _database.ref(AppConstants.notificationsPath).push();
      await notifRef.set({
        'id': notifRef.key,
        'userId': uid,
        'title': 'Welcome to T2 Academy!',
        'message': 'Your account has been created. Start your training journey today.',
        'timestamp': now.toIso8601String(),
        'isRead': false,
        'type': 'welcome',
        'iconType': 'welcome',
      });

      // Başlangıç membership kaydı
      final membershipRef = _database.ref(AppConstants.membershipsPath).push();
      await membershipRef.set({
        'id': membershipRef.key,
        'userId': uid,
        'planName': 'Fighter Plan',
        'planType': 'Fighter',
        'price': 2500,
        'startDate': now.toIso8601String(),
        'endDate': now.add(const Duration(days: 30)).toIso8601String(),
        'renewDate': now.add(const Duration(days: 30)).toIso8601String(),
        'isActive': true,

        'isUnlimited': true,
        'maxSessions': 0,
        'usedSessions': 0,
      });
    } catch (e) {
      throw Exception('Error adding player: $e');
    }
  }

  Stream<List<PlanRequestModel>> getPlayerPlanRequestsStream(String userId) {
    return _database
        .ref(AppConstants.planRequestsPath)
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final snapshot = event.snapshot;
      final List<PlanRequestModel> requests = [];
      if (snapshot.exists && snapshot.value != null) {
        final map = _convertMap(snapshot.value as Map);
        map.forEach((key, value) {
          requests.add(PlanRequestModel.fromMap(key, _convertMap(value as Map)));
        });
      }
      // Pending önce, sonra tarih
      requests.sort((a, b) {
        if (a.status == 'pending' && b.status != 'pending') return -1;
        if (a.status != 'pending' && b.status == 'pending') return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return requests;
    });
  }

  Future<void> approvePlanRequest({
    required PlanRequestModel request,
    required String adminName,
  }) async {
    final now = DateTime.now();
    final duration = request.requestedPackageDurationDays;

    // 1. Yeni membership oluştur
    final membershipRef = _database.ref(AppConstants.membershipsPath).push();
    final newMembershipId = membershipRef.key;

    await membershipRef.set({
      'id': newMembershipId,
      'userId': request.userId,
      'planName': request.requestedPackageName,
      'planType': request.requestedPackageName,
      'price': request.requestedPackagePrice,
      'startDate': now.toIso8601String(),
      'endDate': now.add(Duration(days: duration)).toIso8601String(),
      'renewDate': now.add(Duration(days: duration)).toIso8601String(),
      'isActive': true,
      'isUnlimited': request.requestedIsUnlimited,
      'maxSessions': request.requestedMaxSessions,
      'usedSessions': 0,
      'durationDays': duration,
      'packageId': request.requestedPackageId,
      'weeklySessions': request.requestedWeeklySessions,
    });

    // 2. User'ın currentPackageId'sini güncelle
    await _database.ref('${AppConstants.usersPath}/${request.userId}').update({
      'membershipId': newMembershipId,
      'currentPackageId': request.requestedPackageId,
    });

    // 3. Fatura oluştur
    final invoiceRef = _database.ref(AppConstants.invoicesPath).push();
    await invoiceRef.set({
      'id': invoiceRef.key,
      'userId': request.userId,
      'invoiceNumber': 'INV-${now.millisecondsSinceEpoch.toString().substring(5)}',
      'description': '${request.requestedPackageName} — $duration Days',
      'packageName': request.requestedPackageName,
      'playerName': request.playerName,
      'amount': request.requestedPackagePrice,
      'date': now.toIso8601String(),
      'isPaid': true,
      'paymentMethod': 'Cash',
      'staffName': adminName,
    });

    // 4. Request'i approved olarak işaretle
    await _database.ref('${AppConstants.planRequestsPath}/${request.id}').update({
      'status': 'approved',
      'respondedAt': now.toIso8601String(),
      'respondedBy': adminName,
    });

    // 5. Notification gönder
    final notifRef = _database.ref(AppConstants.notificationsPath).push();
    await notifRef.set({
      'id': notifRef.key,
      'userId': request.userId,
      'title': 'Plan Approved!',
      'message': 'Your ${request.type} request has been approved. You are now on ${request.requestedPackageName}.',
      'timestamp': now.toIso8601String(),
      'isRead': false,
      'type': 'membership',
      'iconType': 'membership',
    });
  }

  Future<void> declinePlanRequest({
    required PlanRequestModel request,
    required String adminName,
  }) async {
    final now = DateTime.now();

    await _database.ref('${AppConstants.planRequestsPath}/${request.id}').update({
      'status': 'declined',
      'respondedAt': now.toIso8601String(),
      'respondedBy': adminName,
    });

    // Notification
    final notifRef = _database.ref(AppConstants.notificationsPath).push();
    await notifRef.set({
      'id': notifRef.key,
      'userId': request.userId,
      'title': 'Plan Request Declined',
      'message': 'Your ${request.type} request for ${request.requestedPackageName} was declined. Contact admin for more info.',
      'timestamp': now.toIso8601String(),
      'isRead': false,
      'type': 'membership',
      'iconType': 'membership',
    });
  }

  // ============ COACHES ============
  Stream<List<CoachModel>> getCoachesStream() {
    return _database.ref(AppConstants.adminsPath).onValue.map((event) {
      final snapshot = event.snapshot;
      final List<CoachModel> coaches = [];
      if (snapshot.exists && snapshot.value != null) {
        final map = _convertMap(snapshot.value as Map);
        map.forEach((key, value) {
          coaches.add(CoachModel.fromMap(key, _convertMap(value as Map)));
        });
      }
      coaches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return coaches;
    });
  }

  Future<void> updateCoach(String uid, Map<String, dynamic> data) async {
    await _database.ref('${AppConstants.adminsPath}/$uid').update(data);
  }

  Future<void> deleteCoach(String uid) async {
    await _database.ref('${AppConstants.adminsPath}/$uid').remove();
  }

  Future<void> toggleCoachStatus(String uid, bool isActive) async {
    await _database.ref('${AppConstants.adminsPath}/$uid').update({
      'isActive': isActive,
    });
  }

  Future<void> updateCoachPermissions(String uid, List<String> permissions) async {
    await _database.ref('${AppConstants.adminsPath}/$uid').update({
      'permissions': permissions,
    });
  }

  // ============ COACH ATTENDANCE ============
  Stream<List<Map<String, dynamic>>> getCoachAttendanceStream() {
    return _database.ref(AppConstants.coachAttendancePath).onValue.map((event) {
      final snapshot = event.snapshot;
      final List<Map<String, dynamic>> records = [];
      if (snapshot.exists && snapshot.value != null) {
        final map = _convertMap(snapshot.value as Map);
        map.forEach((key, value) {
          final data = _convertMap(value as Map);
          data['id'] = key;
          records.add(data);
        });
      }
      records.sort((a, b) {
        final aDate = DateTime.tryParse(a['checkedInAt']?.toString() ?? '') ??
            DateTime.now();
        final bDate = DateTime.tryParse(b['checkedInAt']?.toString() ?? '') ??
            DateTime.now();
        return bDate.compareTo(aDate);
      });
      return records;
    });
  }

  Future<void> recordCoachAttendance({
    required String coachUid,
    required String coachName,
    required String coachRole,
    required String branchId,
    required String branchName,
    String note = '',
  }) async {
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final ref = _database.ref(AppConstants.coachAttendancePath).push();
    await ref.set({
      'id': ref.key,
      'coachUid': coachUid,
      'coachName': coachName,
      'coachRole': coachRole,
      'branchId': branchId,
      'branchName': branchName,
      'checkedInAt': now.toIso8601String(),
      'date': dateKey,
      'note': note,
    });
  }

  Future<Map<String, dynamic>?> getTodayCoachCheckIn(String coachUid) async {
    try {
      final now = DateTime.now();
      final dateKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final snapshot = await _database
          .ref(AppConstants.coachAttendancePath)
          .orderByChild('date')
          .equalTo(dateKey)
          .get();
      if (snapshot.exists && snapshot.value != null) {
        final map = _convertMap(snapshot.value as Map);
        for (final entry in map.entries) {
          final data = _convertMap(entry.value as Map);
          if (data['coachUid'] == coachUid) return data;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ============ CLASSES ============
  Stream<List<ClassModel>> getClassesStream() {
    return _database.ref(AppConstants.classesPath).onValue.map((event) {
      final snapshot = event.snapshot;
      final List<ClassModel> classes = [];
      if (snapshot.exists && snapshot.value != null) {
        final map = _convertMap(snapshot.value as Map);
        map.forEach((key, value) {
          classes.add(ClassModel.fromMap(key, _convertMap(value as Map)));
        });
      }
      classes.sort((a, b) => a.startTime.compareTo(b.startTime));
      return classes;
    });
  }

  Future<void> addClass(ClassModel classModel) async {
    final ref = _database.ref(AppConstants.classesPath).push();
    await ref.set(classModel.toMap());
  }

  Future<void> updateClass(String id, Map<String, dynamic> data) async {
    await _database.ref('${AppConstants.classesPath}/$id').update(data);
  }

  Future<void> deleteClass(String id) async {
    await _database.ref('${AppConstants.classesPath}/$id').remove();
  }

  // ============ PENDING USERS ============
  Stream<List<Map<String, dynamic>>> getPendingUsersStream() {
    return _database.ref('pending_users').onValue.map((event) {
      final snapshot = event.snapshot;
      final List<Map<String, dynamic>> pending = [];
      if (snapshot.exists && snapshot.value != null) {
        final map = _convertMap(snapshot.value as Map);
        map.forEach((key, value) {
          final data = _convertMap(value as Map);
          data['uid'] = key;
          pending.add(data);
        });
      }
      // pending önce, sonra disabled; her grup içinde tarih azalan
      pending.sort((a, b) {
        final aStatus = (a['status'] ?? 'pending').toString();
        final bStatus = (b['status'] ?? 'pending').toString();
        if (aStatus == 'pending' && bStatus != 'pending') return -1;
        if (aStatus != 'pending' && bStatus == 'pending') return 1;
        final aDate = DateTime.tryParse(a['requestedAt']?.toString() ?? '') ?? DateTime.now();
        final bDate = DateTime.tryParse(b['requestedAt']?.toString() ?? '') ?? DateTime.now();
        return bDate.compareTo(aDate);
      });
      return pending;
    });
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
    required String adminName,
    String? groupId,      // YENİ
    String? groupName,    // YENİ
  }) async {
    final uid = (pendingUser['uid'] ?? '').toString();
    if (uid.isEmpty) throw Exception('Invalid pending user');

    final now = DateTime.now();
    final endDate = now.add(Duration(days: packageDurationDays));

    // 1) users/{uid} — aktif oyuncu kaydı
    await _database.ref('${AppConstants.usersPath}/$uid').set({
      'uid': uid,
      'fullName': pendingUser['fullName'] ?? '',
      'phone': pendingUser['phone'] ?? '',
      'email': pendingUser['email'] ?? '',
      'sport': pendingUser['sport'] ?? '',
      'level': pendingUser['level'] ?? '',
      'weightClass': pendingUser['weightClass'] ?? '',
      'emergencyContact': pendingUser['emergencyContact'] ?? '',
      'emergencyPhone': pendingUser['emergencyPhone'] ?? '',
      'guardian': pendingUser['guardian'] ?? 'Not applicable',
      'membershipId': '',
      'currentPackageId': packageId,
      'playerNumber': pendingUser['playerNumber'] ?? 0,
      'rank': '01',
      'wins': 0,
      'losses': 0,
      'draws': 0,
      'winsByKO': 0,
      'winsByDecision': 0,
      'joinDate': now.toIso8601String(),
      'weight': 0,
      'height': 0,
      'isActive': true,
    });

    // 2) Membership
    final membershipRef =
    _database.ref(AppConstants.membershipsPath).push();
    await membershipRef.set({
      'id': membershipRef.key,
      'userId': uid,
      'planName': packageName,
      'planType': packageName,
      'price': packagePrice,
      'startDate': now.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'renewDate': endDate.toIso8601String(),
      'isActive': true,
      'isUnlimited': isUnlimited,
      'maxSessions': maxSessions,
      'usedSessions': 0,
      'durationDays': packageDurationDays,
      'packageId': packageId,
      'weeklySessions': weeklySessions,
      'groupId': groupId ?? '',      // YENİ
      'groupName': groupName ?? '',  // YENİ
    });

    // currentPackageId güncelle
    await _database.ref('${AppConstants.usersPath}/$uid').update({
      'membershipId': membershipRef.key,
    });

    // 3) Fatura
    final invoiceRef = _database.ref(AppConstants.invoicesPath).push();
    await invoiceRef.set({
      'id': invoiceRef.key,
      'invoiceNumber':
      'INV-${now.millisecondsSinceEpoch.toString().substring(5)}',
      'userId': uid,
      'playerName': pendingUser['fullName'] ?? '',
      'packageName': packageName,
      'description': '$packageName — $packageDurationDays Days',
      'amount': packagePrice,
      'paymentMethod': paymentMethod,
      'staffName': adminName,
      'date': now.toIso8601String(),
      'isPaid': true,
    });

    // 4) Welcome notification
    final notifRef =
    _database.ref(AppConstants.notificationsPath).push();
    await notifRef.set({
      'id': notifRef.key,
      'userId': uid,
      'title': 'Welcome to Lycans Fight Club!',
      'message':
      'Your account is activated. You are now on $packageName. Let\'s train!',
      'timestamp': now.toIso8601String(),
      'isRead': false,
      'type': 'welcome',
      'iconType': 'welcome',
    });

    // 5) pending_users/{uid} sil
    await _database.ref('pending_users/$uid').remove();
  }

  Future<void> removePendingUser(String uid) async {
    await _database.ref('pending_users/$uid').remove();
  }

  Future<void> disablePendingUser(String uid, bool disable) async {
    await _database.ref('pending_users/$uid').update({
      'status': disable ? 'disabled' : 'pending',
      if (disable) 'disabledAt': DateTime.now().toIso8601String(),
      if (!disable) 'disabledAt': null,
    });
  }

  // ============ PACKAGES ============
  Stream<List<PackageModel>> getPackagesStream() {
    return _database.ref(AppConstants.packagesPath).onValue.map((event) {
      final snapshot = event.snapshot;
      final List<PackageModel> packages = [];
      if (snapshot.exists && snapshot.value != null) {
        final map = _convertMap(snapshot.value as Map);
        map.forEach((key, value) {
          packages.add(PackageModel.fromMap(key, _convertMap(value as Map)));
        });
      }
      return packages;
    });
  }

  // Admin database_service.dart addPackage metodu
  Future<String?> addPackage(PackageModel package) async {
    final ref = _database.ref(AppConstants.packagesPath).push();
    final newId = ref.key; // Firebase'in oluşturduğu push key

    await ref.set({
      ...package.toMap(),
      'id': newId, // id'yi Firebase push key ile aynı yap
    });

    return newId;
  }

  Future<void> updatePackage(String id, Map<String, dynamic> data) async {
    await _database.ref('${AppConstants.packagesPath}/$id').update(data);
  }

  Future<void> deletePackage(String id) async {
    await _database.ref('${AppConstants.packagesPath}/$id').remove();
  }

  // ============ INVOICES ============
  Stream<List<InvoiceModel>> getInvoicesStream() {
    return _database.ref(AppConstants.invoicesPath).onValue.map((event) {
      final snapshot = event.snapshot;
      final List<InvoiceModel> invoices = [];
      if (snapshot.exists && snapshot.value != null) {
        final map = _convertMap(snapshot.value as Map);
        map.forEach((key, value) {
          invoices.add(InvoiceModel.fromMap(key, _convertMap(value as Map)));
        });
      }
      invoices.sort((a, b) => b.date.compareTo(a.date));
      return invoices;
    });
  }

  Future<void> addInvoice(InvoiceModel invoice) async {
    final ref = _database.ref(AppConstants.invoicesPath).push();
    await ref.set(invoice.toMap());
  }

  // ============ Ödeme kaydetme (FIX) ============
  Future<void> recordPayment({
    required String userId,
    required String playerName,
    required String packageName,
    required double amount,
    required String paymentMethod,
    String? groupId,      // YENİ
    String? groupName,    // YENİ
    String staffName = 'Admin',
  }) async {
    final now = DateTime.now();

    // 1. Fatura kaydı
    final ref = _database.ref(AppConstants.invoicesPath).push();
    await ref.set({
      'id': ref.key,
      'invoiceNumber': 'INV-${now.millisecondsSinceEpoch.toString().substring(5)}',
      'userId': userId,
      'playerName': playerName,
      'packageName': packageName,
      'description': '$packageName — Membership', // <-- YENİ EKLENEN SATIR
      'amount': amount,
      'paymentMethod': paymentMethod,
      'staffName': staffName,
      'date': now.toIso8601String(),
      'isPaid': true,
      'groupId': groupId ?? '',       // YENİ
      'groupName': groupName ?? '',   // YENİ
    });

    // 2. Membership güncelle
    final membershipSnapshot = await _database
        .ref(AppConstants.membershipsPath)
        .orderByChild('userId')
        .equalTo(userId)
        .get();

    if (membershipSnapshot.exists && membershipSnapshot.value != null) {
      // === MEVCUT MEMBERSHIP VAR → güncelle ===
      final map = _convertMap(membershipSnapshot.value as Map);

      // En güncel membership'i bul (endDate en ileri olan)
      final entries = map.entries.toList();
      entries.sort((a, b) {
        final aData = _convertMap(a.value as Map);
        final bData = _convertMap(b.value as Map);
        final aDate = DateTime.parse(
            aData['endDate'] ?? DateTime.now().toIso8601String());
        final bDate = DateTime.parse(
            bData['endDate'] ?? DateTime.now().toIso8601String());
        return bDate.compareTo(aDate);
      });

      final latestKey = entries.first.key;
      final latestData = _convertMap(entries.first.value as Map);

      final currentEnd = DateTime.parse(
          latestData['endDate'] ?? now.toIso8601String());
      final newEnd = currentEnd.isBefore(now)
          ? now.add(const Duration(days: 30))
          : currentEnd.add(const Duration(days: 30));

      final updates = <String, dynamic>{
        'endDate': newEnd.toIso8601String(),
        'renewDate': newEnd.toIso8601String(),
        'isActive': true,
        'isFrozen': false,
      };

      // FIX: Group bilgisi verildiyse mevcut membership'e de yaz
      if (groupId != null && groupId.isNotEmpty) {
        updates['groupId'] = groupId;
      }
      if (groupName != null && groupName.isNotEmpty) {
        updates['groupName'] = groupName;
      }

      await _database
          .ref('${AppConstants.membershipsPath}/$latestKey')
          .update(updates);
    } else {
      // === MEMBERSHIP YOK → yeni oluştur ===
      final membershipRef = _database.ref(AppConstants.membershipsPath).push();
      final newMembership = <String, dynamic>{
        'id': membershipRef.key,
        'userId': userId,
        'planName': packageName,
        'planType': packageName,
        'price': amount,
        'startDate': now.toIso8601String(),
        'endDate': now.add(const Duration(days: 30)).toIso8601String(),
        'renewDate': now.add(const Duration(days: 30)).toIso8601String(),
        'isActive': true,
        'isUnlimited': true,
        'maxSessions': 0,
        'usedSessions': 0,
      };

      // FIX: Group bilgisi verildiyse ekle
      if (groupId != null && groupId.isNotEmpty) {
        newMembership['groupId'] = groupId;
      }
      if (groupName != null && groupName.isNotEmpty) {
        newMembership['groupName'] = groupName;
      }

      await membershipRef.set(newMembership);
    }
  }

  // ============ MEMBERSHIP İŞLEMLERİ ============
  // database_service.dart - freezeMembership düzeltilmiş
  Future<void> freezeMembership(String userId) async {
    final snapshot = await _database
        .ref(AppConstants.membershipsPath)
        .orderByChild('userId')
        .equalTo(userId)
        .get();

    if (snapshot.exists && snapshot.value != null) {
      final map = _convertMap(snapshot.value as Map);
      for (final entry in map.entries) {
        await _database.ref('${AppConstants.membershipsPath}/${entry.key}').update({
          'isActive': false,
          'isFrozen': true,
          'frozenAt': DateTime.now().toIso8601String(),
        });
      }
    } else {
      // Membership yoksa oluştur ve dondur
      final now = DateTime.now();
      final membershipRef = _database.ref(AppConstants.membershipsPath).push();
      await membershipRef.set({
        'id': membershipRef.key,
        'userId': userId,
        'planName': 'Fighter Plan',
        'planType': 'Fighter',
        'price': 2500,
        'startDate': now.toIso8601String(),
        'endDate': now.add(const Duration(days: 30)).toIso8601String(),
        'renewDate': now.add(const Duration(days: 30)).toIso8601String(),
        'isActive': false,
        'isFrozen': true,
        'frozenAt': now.toIso8601String(),
        'isUnlimited': true,
        'maxSessions': 0,
        'usedSessions': 0,
      });
    }
  }

  Future<void> unfreezeMembership(String userId) async {
    final snapshot = await _database
        .ref(AppConstants.membershipsPath)
        .orderByChild('userId')
        .equalTo(userId)
        .get();

    if (snapshot.exists && snapshot.value != null) {
      final map = _convertMap(snapshot.value as Map);
      for (final entry in map.entries) {
        await _database.ref('${AppConstants.membershipsPath}/${entry.key}').update({
          'isActive': true,
          'isFrozen': false,
          'unfrozenAt': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  Future<void> extendMembership(String userId, int days) async {
    final snapshot = await _database
        .ref(AppConstants.membershipsPath)
        .orderByChild('userId')
        .equalTo(userId)
        .get();

    if (snapshot.exists && snapshot.value != null) {
      final map = _convertMap(snapshot.value as Map);
      for (final entry in map.entries) {
        final data = _convertMap(entry.value as Map);
        final currentEnd = DateTime.parse(data['endDate'] ?? DateTime.now().toIso8601String());
        final newEnd = currentEnd.isBefore(DateTime.now())
            ? DateTime.now().add(Duration(days: days))
            : currentEnd.add(Duration(days: days));
        await _database.ref('${AppConstants.membershipsPath}/${entry.key}').update({
          'endDate': newEnd.toIso8601String(),
          'renewDate': newEnd.toIso8601String(),
          'isActive': true,
          'isFrozen': false,
        });
      }
    }
  }

  // ============ ANNOUNCEMENTS ============
  Stream<List<AnnouncementModel>> getAnnouncementsStream() {
    return _database.ref(AppConstants.announcementsPath).onValue.map((event) {
      final snapshot = event.snapshot;
      final List<AnnouncementModel> announcements = [];
      if (snapshot.exists && snapshot.value != null) {
        final map = _convertMap(snapshot.value as Map);
        map.forEach((key, value) {
          announcements.add(AnnouncementModel.fromMap(key, _convertMap(value as Map)));
        });
      }
      announcements.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      return announcements;
    });
  }

  // database_service.dart içindeki sendAnnouncement metodu
  Future<void> sendAnnouncement(
      AnnouncementModel announcement, {
        List<String>? selectedPlayerIds,
      }) async {
    final ref = _database.ref(AppConstants.announcementsPath).push();
    await ref.set({
      ...announcement.toMap(),
      'selectedPlayerIds': selectedPlayerIds ?? [],
      'isForAll': selectedPlayerIds == null || selectedPlayerIds.isEmpty,
    });

    if (selectedPlayerIds == null || selectedPlayerIds.isEmpty) {
      // Tüm oyunculara bildirim
      final notifRef = _database.ref(AppConstants.notificationsPath).push();
      await notifRef.set({
        'id': notifRef.key,
        'userId': 'all',
        'title': announcement.title,
        'message': announcement.message,
        'timestamp': announcement.sentAt.toIso8601String(),
        'isRead': false,
        'type': 'announcement',
        'iconType': 'announcement',
      });
    } else {
      // Seçili oyunculara bildirim
      for (final playerId in selectedPlayerIds) {
        final notifRef = _database.ref(AppConstants.notificationsPath).push();
        await notifRef.set({
          'id': notifRef.key,
          'userId': playerId,
          'title': announcement.title,
          'message': announcement.message,
          'timestamp': announcement.sentAt.toIso8601String(),
          'isRead': false,
          'type': 'announcement',
          'iconType': 'announcement',
        });
      }
    }
  }

  // ============ ATTENDANCE ============
  Stream<List<AttendanceModel>> getAttendanceStream() {
    return _database.ref(AppConstants.checkinsPath).onValue.map((event) {
      final snapshot = event.snapshot;
      final List<AttendanceModel> attendance = [];
      if (snapshot.exists && snapshot.value != null) {
        final map = _convertMap(snapshot.value as Map);
        map.forEach((key, value) {
          attendance.add(AttendanceModel.fromMap(key, _convertMap(value as Map)));
        });
      }
      attendance.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return attendance;
    });
  }

  Future<void> recordCheckIn({
    required String userId,
    required String playerName,
    required String className,
    String status = 'recorded',
  }) async {
    final now = DateTime.now();
    final ref = _database.ref(AppConstants.checkinsPath).push();
    await ref.set({
      'id': ref.key,
      'userId': userId,
      'playerName': playerName,
      'className': className,
      'timestamp': now.toIso8601String(),
      'status': status,
    });

    // Attendance kaydı da ekle
    final attendanceRef = _database.ref('${AppConstants.attendancePath}/$userId').push();
    await attendanceRef.set({
      'id': attendanceRef.key,
      'userId': userId,
      'playerName': playerName,
      'className': className,
      'date': now.toIso8601String(),
      'status': status,
    });
  }

  // ============ TOURNAMENTS ============
  Stream<List<TournamentModel>> getTournamentsStream() {
    return _database.ref(AppConstants.tournamentsPath).onValue.map((event) {
      final snapshot = event.snapshot;
      final List<TournamentModel> tournaments = [];
      if (snapshot.exists && snapshot.value != null) {
        final map = _convertMap(snapshot.value as Map);
        map.forEach((key, value) {
          tournaments.add(TournamentModel.fromMap(key, _convertMap(value as Map)));
        });
      }
      return tournaments;
    });
  }

  Future<void> addTournament(TournamentModel tournament) async {
    final ref = _database.ref(AppConstants.tournamentsPath).push();
    await ref.set(tournament.toMap());
  }

  Future<void> updateTournament(String id, Map<String, dynamic> data) async {
    await _database.ref('${AppConstants.tournamentsPath}/$id').update(data);
  }

  Future<void> deleteTournament(String id) async {
    await _database.ref('${AppConstants.tournamentsPath}/$id').remove();
  }

  // ============ FIGHTS ============
  Stream<List<Map<String, dynamic>>> getFightsStream() {
    return _database.ref(AppConstants.fightsPath).onValue.map((event) {
      final snapshot = event.snapshot;
      final List<Map<String, dynamic>> fights = [];
      if (snapshot.exists && snapshot.value != null) {
        final map = _convertMap(snapshot.value as Map);
        map.forEach((key, value) {
          fights.add(_convertMap(value as Map));
        });
      }
      return fights;
    });
  }

  Future<void> logFightResult({
    required String fighterUid,
    required String fighterName,
    required String opponentName,
    required String eventName,
    required String result,
    required String winType,
  }) async {
    final now = DateTime.now();
    final ref = _database.ref(AppConstants.fightsPath).push();
    await ref.set({
      'id': ref.key,
      'userId': fighterUid,
      'opponentName': opponentName,
      'eventName': eventName,
      'eventType': 'Competition',
      'fightDate': now.toIso8601String(),
      'result': result.toLowerCase(),
      'winType': winType,
      'round': 0,
      'userWeight': 0,
      'opponentWeight': 0,
      'weightClass': '',
      'isUpcoming': false,
      'venue': '',
    });
  }

  Future<void> updateFightResult(String fightId, String result, String winType) async {
    await _database.ref('${AppConstants.fightsPath}/$fightId').update({
      'result': result,
      'winType': winType,
      'isUpcoming': false,
    });
  }

  // ============ COACH NOTES ============
  Future<void> addCoachNote({
    required String userId,
    required String coachName,
    required String message,
  }) async {
    final ref = _database.ref(AppConstants.coachNotesPath).push();
    await ref.set({
      'id': ref.key,
      'userId': userId,
      'coachName': coachName,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Map<String, dynamic>>> getCoachNotesStream(String userId) {
    return _database
        .ref(AppConstants.coachNotesPath)
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final snapshot = event.snapshot;
      final List<Map<String, dynamic>> notes = [];
      if (snapshot.exists && snapshot.value != null) {
        final map = _convertMap(snapshot.value as Map);
        map.forEach((key, value) {
          notes.add(_convertMap(value as Map));
        });
      }
      notes.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
      return notes;
    });
  }

  // ============ BRANCHES ============
  Stream<List<BranchModel>> getBranchesStream() {
    return _database.ref(AppConstants.branchesPath).onValue.map((event) {
      final snapshot = event.snapshot;
      final List<BranchModel> branches = [];
      if (snapshot.exists && snapshot.value != null) {
        final map = _convertMap(snapshot.value as Map);
        map.forEach((key, value) {
          branches.add(BranchModel.fromMap(key, _convertMap(value as Map)));
        });
      }
      branches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return branches;
    });
  }

  Future<String> addBranch(BranchModel branch) async {
    final ref = _database.ref(AppConstants.branchesPath).push();
    final newId = ref.key ?? DateTime.now().millisecondsSinceEpoch.toString();
    await ref.set(branch.copyWith(id: newId).toMap());
    return newId;
  }

  Future<void> updateBranch(String id, Map<String, dynamic> data) async {
    await _database.ref('${AppConstants.branchesPath}/$id').update(data);
  }

  Future<void> toggleBranchStatus(String id, bool isActive) async {
    await _database.ref('${AppConstants.branchesPath}/$id').update({
      'isActive': isActive,
      'closedAt': isActive ? null : DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteBranch(String id) async {
    await _database.ref('${AppConstants.branchesPath}/$id').remove();
  }


    // ============ EXERCISES ============
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
    final ref = _database.ref(AppConstants.exercisesPath).push();
    await ref.set({
      'id': ref.key,
      'userId': userId,
      'name': name,
      'weekNumber': weekNumber,
      'sets': sets,
      'reps': reps,
      'rounds': rounds,
      'durationMinutes': durationMinutes,
      'restSeconds': restSeconds,
      'isCompleted': false,
      'category': category,
      'coachNote': '',
    });
  }

  Stream<List<Map<String, dynamic>>> getExercisesStream(String userId) {
    return _database
        .ref(AppConstants.exercisesPath)
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final snapshot = event.snapshot;
      final List<Map<String, dynamic>> exercises = [];
      if (snapshot.exists && snapshot.value != null) {
        final map = _convertMap(snapshot.value as Map);
        map.forEach((key, value) {
          exercises.add(_convertMap(value as Map));
        });
      }
      return exercises;
    });
  }

  Future<void> deleteExercise(String exerciseId) async {
    await _database.ref('${AppConstants.exercisesPath}/$exerciseId').remove();
  }

  // ============ DASHBOARD STATS ============
  Stream<Map<String, dynamic>> getDashboardStatsStream() {
    return Stream.multi((controller) async {
      final playersSnapshot = await _database.ref(AppConstants.usersPath).get();
      final membershipsSnapshot = await _database.ref(AppConstants.membershipsPath).get();
      final classesSnapshot = await _database.ref(AppConstants.classesPath).get();
      final invoicesSnapshot = await _database.ref(AppConstants.invoicesPath).get();
      final checkinsSnapshot = await _database.ref(AppConstants.checkinsPath).get();

      final players = playersSnapshot.exists ? _convertMap(playersSnapshot.value as Map) : {};
      final memberships = membershipsSnapshot.exists ? _convertMap(membershipsSnapshot.value as Map) : {};
      final classes = classesSnapshot.exists ? _convertMap(classesSnapshot.value as Map) : {};
      final invoices = invoicesSnapshot.exists ? _convertMap(invoicesSnapshot.value as Map) : {};
      final checkins = checkinsSnapshot.exists ? _convertMap(checkinsSnapshot.value as Map) : {};

      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      int activeMembers = 0;
      int expiredMembers = 0;
      int frozenMembers = 0;

      memberships.forEach((key, value) {
        final data = _convertMap(value as Map);
        final endDate = DateTime.parse(data['endDate'] ?? now.toIso8601String());
        if (data['isActive'] == false) {
          frozenMembers++;
        } else if (endDate.isAfter(now)) {
          activeMembers++;
        } else {
          expiredMembers++;
        }
      });

      int todayAttendance = 0;
      checkins.forEach((key, value) {
        final data = _convertMap(value as Map);
        final timestamp = DateTime.parse(data['timestamp'] ?? now.toIso8601String());
        if (timestamp.year == now.year && timestamp.month == now.month && timestamp.day == now.day) {
          todayAttendance++;
        }
      });

      double monthlyRevenue = 0;
      double unpaid = 0;
      double todayRevenue = 0;
      invoices.forEach((key, value) {
        final data = _convertMap(value as Map);
        final amount = (data['amount'] ?? 0).toDouble();
        final date = DateTime.parse(data['date'] ?? now.toIso8601String());

        if (data['isPaid'] != true) {
          unpaid += amount;
        }

        if (date.month == now.month && date.year == now.year) {
          if (data['isPaid'] == true) {
            monthlyRevenue += amount;
          }
        }

        if (date.day == now.day && date.month == now.month && date.year == now.year) {
          if (data['isPaid'] == true) {
            todayRevenue += amount;
          }
        }
      });

      int classesToday = 0;
      classes.forEach((key, value) {
        final data = _convertMap(value as Map);
        final startTime = DateTime.parse(data['startTime'] ?? now.toIso8601String());
        if (startTime.year == now.year && startTime.month == now.month && startTime.day == now.day) {
          classesToday++;
        }
      });

      controller.add({
        'totalPlayers': players.length,
        'activeMembers': activeMembers,
        'expiredMembers': expiredMembers,
        'frozenMembers': frozenMembers,
        'todayAttendance': todayAttendance,
        'classesToday': classesToday,
        'monthlyRevenue': monthlyRevenue,
        'todayRevenue': todayRevenue,
        'unpaid': unpaid,
      });
      controller.close();
    });
  }

  Future<void> deleteFight(String fightId) async {
    await _database.ref('${AppConstants.fightsPath}/$fightId').remove();
  }

  // database_service.dart'a ekle
  Stream<List<Map<String, dynamic>>> getBookedPlayersForClass(String classId) {
    return _database
        .ref(AppConstants.schedulesPath)
        .onValue
        .map((event) {
      final snapshot = event.snapshot;
      final List<Map<String, dynamic>> bookings = [];

      if (snapshot.exists && snapshot.value != null) {
        final map = _convertMap(snapshot.value as Map);
        map.forEach((userId, userBookings) {
          final userMap = _convertMap(userBookings as Map);
          userMap.forEach((bookingId, bookingData) {
            final data = _convertMap(bookingData as Map);
            if (data['classId'] == classId || data['id'] == classId) {
              bookings.add({
                ...data,
                'userId': userId,
                'bookingId': bookingId,
              });
            }
          });
        });
      }

      return bookings;
    });
  }

  // database_service.dart'a ekle
  Future<void> deleteAnnouncement(String id) async {
    await _database.ref('${AppConstants.announcementsPath}/$id').remove();
  }

  // database_service.dart'a ekle
  // database_service.dart - getMembershipStatusStream düzeltilmiş
  Stream<Map<String, dynamic>?> getMembershipStatusStream(String userId) {
    return _database
        .ref(AppConstants.membershipsPath)
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists && snapshot.value != null) {
        final map = _convertMap(snapshot.value as Map);
        final entries = map.entries.toList();
        if (entries.isNotEmpty) {
          entries.sort((a, b) {
            final aDate = DateTime.parse(a.value['endDate'] ?? DateTime.now().toIso8601String());
            final bDate = DateTime.parse(b.value['endDate'] ?? DateTime.now().toIso8601String());
            return bDate.compareTo(aDate);
          });
          final data = _convertMap(entries.first.value as Map);
          data['id'] = entries.first.key;
          data['isFrozen'] = data['isFrozen'] ?? false;
          return data;
        }
      }
      return null;
    });
  }

  // database_service.dart'a ekle
  Stream<List<Map<String, dynamic>>> getMembershipsStream() {
    return _database.ref(AppConstants.membershipsPath).onValue.map((event) {
      final snapshot = event.snapshot;
      final List<Map<String, dynamic>> memberships = [];
      if (snapshot.exists && snapshot.value != null) {
        final map = _convertMap(snapshot.value as Map);
        map.forEach((key, value) {
          final data = _convertMap(value as Map);
          data['id'] = key;
          memberships.add(data);
        });
      }
      return memberships;
    });
  }

  // admin database_service.dart'a ekle
  Future<void> recordCheckInWithSessionUpdate({
    required String userId,
    required String playerName,
    required String className,
  }) async {
    final now = DateTime.now();

    // 1. Check-in kaydı oluştur
    final ref = _database.ref(AppConstants.checkinsPath).push();
    await ref.set({
      'id': ref.key,
      'userId': userId,
      'playerName': playerName,
      'className': className,
      'timestamp': now.toIso8601String(),
      'status': 'recorded',
    });

    // 2. Attendance kaydı
    final attendanceRef = _database.ref('${AppConstants.attendancePath}/$userId').push();
    await attendanceRef.set({
      'id': attendanceRef.key,
      'userId': userId,
      'playerName': playerName,
      'className': className,
      'date': now.toIso8601String(),
      'status': 'recorded',
    });

    // 3. USED SESSIONS +1 İŞLEMİ
    final membershipSnapshot = await _database
        .ref(AppConstants.membershipsPath)
        .orderByChild('userId')
        .equalTo(userId)
        .get();

    debugPrint('=== SESSION UPDATE ===');
    debugPrint('User ID: $userId');
    debugPrint('Membership exists: ${membershipSnapshot.exists}');

    if (membershipSnapshot.exists && membershipSnapshot.value != null) {
      final membershipsMap = _convertMap(membershipSnapshot.value as Map);
      final entries = membershipsMap.entries.toList();

      // En güncel membership'i bul
      entries.sort((a, b) {
        final aDate = DateTime.parse(a.value['endDate'] ?? DateTime.now().toIso8601String());
        final bDate = DateTime.parse(b.value['endDate'] ?? DateTime.now().toIso8601String());
        return bDate.compareTo(aDate);
      });

      final membershipId = entries.first.key;
      final membershipData = _convertMap(entries.first.value as Map);

      debugPrint('Membership ID: $membershipId');
      debugPrint('Plan: ${membershipData['planName']}');
      debugPrint('isUnlimited: ${membershipData['isUnlimited']}');

      final bool isUnlimited = membershipData['isUnlimited'] ?? true;
      final int currentUsedSessions = (membershipData['usedSessions'] as num?)?.toInt() ?? 0;
      final int maxSessions = (membershipData['maxSessions'] as num?)?.toInt() ?? 0;

      debugPrint('Current usedSessions: $currentUsedSessions');
      debugPrint('Max sessions: $maxSessions');

      // Eğer unlimited DEĞİLSE usedSessions'ı +1 artır
      if (!isUnlimited) {
        final int newUsedSessions = currentUsedSessions + 1;

        await _database.ref('${AppConstants.membershipsPath}/$membershipId').update({
          'usedSessions': newUsedSessions,
        });

        debugPrint('✅ usedSessions updated: $newUsedSessions / $maxSessions');
      } else {
        debugPrint('ℹ️ Unlimited membership - no session tracking');
      }
    } else {
      debugPrint('❌ No membership found for user');
    }
    debugPrint('=== END SESSION UPDATE ===');
  }

  // ============ MARK ABSENT (session counts) ============
  Future<void> markAbsent({
    required String userId,
    required String playerName,
    required String className,
  }) async {
    final now = DateTime.now();

    // Attendance kaydı (status = absent)
    final attendanceRef =
    _database.ref('${AppConstants.attendancePath}/$userId').push();
    await attendanceRef.set({
      'id': attendanceRef.key,
      'userId': userId,
      'playerName': playerName,
      'className': className,
      'date': now.toIso8601String(),
      'status': 'absent',
    });

    // USED SESSIONS +1
    final membershipSnapshot = await _database
        .ref(AppConstants.membershipsPath)
        .orderByChild('userId')
        .equalTo(userId)
        .get();

    if (membershipSnapshot.exists && membershipSnapshot.value != null) {
      final membershipsMap = _convertMap(membershipSnapshot.value as Map);
      final entries = membershipsMap.entries.toList();
      entries.sort((a, b) {
        final aDate = DateTime.parse(
            a.value['endDate'] ?? DateTime.now().toIso8601String());
        final bDate = DateTime.parse(
            b.value['endDate'] ?? DateTime.now().toIso8601String());
        return bDate.compareTo(aDate);
      });

      final membershipId = entries.first.key;
      final membershipData = _convertMap(entries.first.value as Map);
      final bool isUnlimited = membershipData['isUnlimited'] ?? true;
      final int currentUsedSessions =
          (membershipData['usedSessions'] as num?)?.toInt() ?? 0;

      if (!isUnlimited) {
        await _database
            .ref('${AppConstants.membershipsPath}/$membershipId')
            .update({'usedSessions': currentUsedSessions + 1});
      }
    }
  }

  // ============ COACH REWARDS ============
  Stream<List<Map<String, dynamic>>> getCoachRewardsStream() {
    return _database.ref(AppConstants.coachRewardsPath).onValue.map((event) {
      final snap = event.snapshot;
      final list = <Map<String, dynamic>>[];
      if (snap.exists && snap.value != null) {
        final map = _convertMap(snap.value as Map);
        map.forEach((k, v) {
          final d = _convertMap(v as Map);
          d['id'] = k;
          list.add(d);
        });
      }
      list.sort((a, b) {
        final aD = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
            DateTime.now();
        final bD = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
            DateTime.now();
        return bD.compareTo(aD);
      });
      return list;
    });
  }

  Future<void> giveCoachReward({
    required String coachUid,
    required String coachName,
    required String coachRole,
    required String type,
    required String title,
    required String description,
    required double amount,
    required double discountPercent,
    required String givenBy,
    required String givenByUid,
  }) async {
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final ref = _database.ref(AppConstants.coachRewardsPath).push();
    await ref.set({
      'id': ref.key,
      'coachUid': coachUid,
      'coachName': coachName,
      'coachRole': coachRole,
      'type': type,
      'title': title,
      'description': description,
      'amount': amount,
      'discountPercent': discountPercent,
      'givenBy': givenBy,
      'givenByUid': givenByUid,
      'date': dateKey,
      'createdAt': now.toIso8601String(),
    });
  }

  Future<void> deleteCoachReward(String id) async {
    await _database.ref('${AppConstants.coachRewardsPath}/$id').remove();
  }

  // ============ DAILY COMBOS ============
  Stream<List<Map<String, dynamic>>> getDailyCombosStream() {
    return _database.ref(AppConstants.dailyCombosPath).onValue.map((event) {
      final snap = event.snapshot;
      final list = <Map<String, dynamic>>[];
      if (snap.exists && snap.value != null) {
        final map = _convertMap(snap.value as Map);
        map.forEach((k, v) {
          final d = _convertMap(v as Map);
          d['id'] = k;
          list.add(d);
        });
      }
      list.sort((a, b) {
        final aD =
            DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
        final bD =
            DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
        return bD.compareTo(aD);
      });
      return list;
    });
  }

  Future<void> recordDailyCombo({
    required String coachUid,
    required String coachName,
    required String coachRole,
    required String combo,
    required String branchId,
    required String branchName,
    required String dateKey,
  }) async {
    final ref = _database.ref(AppConstants.dailyCombosPath).push();
    await ref.set({
      'id': ref.key,
      'coachUid': coachUid,
      'coachName': coachName,
      'coachRole': coachRole,
      'combo': combo,
      'branchId': branchId,
      'branchName': branchName,
      'date': dateKey,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteDailyCombo(String id) async {
    await _database.ref('${AppConstants.dailyCombosPath}/$id').remove();
  }

// ============ DAILY ATTENDANCES ============
  Stream<List<Map<String, dynamic>>> getDailyAttendancesStream() {
    return _database
        .ref(AppConstants.dailyAttendancesPath)
        .onValue
        .map((event) {
      final snap = event.snapshot;
      final list = <Map<String, dynamic>>[];
      if (snap.exists && snap.value != null) {
        final map = _convertMap(snap.value as Map);
        map.forEach((k, v) {
          final d = _convertMap(v as Map);
          d['id'] = k;
          list.add(d);
        });
      }
      list.sort((a, b) {
        final aD = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
            DateTime.now();
        final bD = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
            DateTime.now();
        return bD.compareTo(aD);
      });
      return list;
    });
  }

  Future<void> recordDailyAttendance({
    required String coachUid,
    required String coachName,
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
    final ref = _database.ref(AppConstants.dailyAttendancesPath).push();
    await ref.set({
      'id': ref.key,
      'coachUid': coachUid,
      'coachName': coachName,
      'groupId': groupId,
      'groupName': groupName,
      'branchId': branchId,
      'branchName': branchName,
      'playerUids': playerUids,
      'playerNames': playerNames,
      'playerNumbers': playerNumbers,
      'playerCount': playerUids.length,
      'photoUrls': photoUrls,
      'notes': notes,
      'date': dateKey,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteDailyAttendance(String id) async {
    await _database.ref('${AppConstants.dailyAttendancesPath}/$id').remove();
  }
}


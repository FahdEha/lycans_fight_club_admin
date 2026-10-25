import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

import '../models/coach_model.dart';
import '../models/invoice_model.dart';
import '../models/player_model.dart';
import '../models/branch_model.dart';
import '../models/package_model.dart';
import '../models/class_model.dart';
import '../providers/admin_provider.dart';
import 'players_screen.dart';
import 'attendance_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  final Color generalGlassDark = const Color(0xFF0F1115);
  final Color glassBorder = Colors.white;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final stats = provider.dashboardStats;
    final players = provider.players;
    final attendance = provider.attendance;
    final classes = provider.classes;
    final invoices = provider.invoices;

    final now = DateTime.now();

    final Color bgGlass = generalGlassDark.withOpacity(0.5);
    final Color borderGlass = glassBorder.withOpacity(0.04);

    final todayAttendance = attendance.where((a) {
      return a.timestamp.year == now.year &&
          a.timestamp.month == now.month &&
          a.timestamp.day == now.day;
    }).length;

    final todayClasses = classes.where((c) {
      return c.startTime.year == now.year &&
          c.startTime.month == now.month &&
          c.startTime.day == now.day;
    }).length;

    final totalPlayers = (stats['totalPlayers'] as int?) ?? players.length;
    final activeMembers = (stats['activeMembers'] as int?) ?? 0;
    final todayAttendanceCount =
        (stats['todayAttendance'] as int?) ?? todayAttendance;
    final classesTodayCount = (stats['classesToday'] as int?) ?? todayClasses;

    final revenueData = _calculateMonthlyRevenue(invoices);
    final membershipMix = _calculateMembershipMix(provider);

    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/dashboard_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),
                  Text(
                    'Good Morning',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white60,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    'Fighter',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(width: 2, height: 28, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Discipline today,\nstrength tomorrow.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildKpiSection(totalPlayers, activeMembers,
                      todayAttendanceCount, classesTodayCount, bgGlass, borderGlass),
                  const SizedBox(height: 8),

                  _buildStrongerEveryDayCard(),
                  const SizedBox(height: 12),

                  _buildShortcutsSection(context, provider),
                  const SizedBox(height: 12),

                  const _CoachCheckInCard(),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          context,
                          title: 'New Members',
                          subtitle: 'View member stats',
                          icon: Icons.people_alt_outlined,
                          bgImage: 'assets/images/members_card_bg.png',
                          onTap: () => _showChartBottomSheet(
                            context,
                            title: 'New Members (Last 4 Weeks)',
                            chartWidget: _buildNewMembersChart(players),
                            glassDark: bgGlass,
                            glassBorder: borderGlass,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionCard(
                          context,
                          title: 'Revenue',
                          subtitle: 'Check revenue stats',
                          icon: Icons.calendar_today_outlined,
                          bgImage: 'assets/images/revenue_card_bg.png',
                          onTap: () => _showChartBottomSheet(
                            context,
                            title: 'Revenue (Last 6 Months)',
                            chartWidget: _buildRevenueChart(revenueData),
                            glassDark: bgGlass,
                            glassBorder: borderGlass,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  _buildMembershipMixCard(
                      membershipMix, activeMembers, bgGlass, borderGlass),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ SHORTCUTS SECTION ============
  Widget _buildShortcutsSection(BuildContext context, AdminProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildShortcutCard(
            icon: Icons.people_alt_rounded,
            label: 'PLAYERS',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlayersScreen()),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildShortcutCard(
            icon: Icons.qr_code_scanner_rounded,
            label: 'ATTENDANCE',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AttendanceScreen()),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildShortcutCard(
            icon: Icons.person_add_alt_1_rounded,
            label: 'ADD PLAYER',
            isPrimary: true,
            onTap: () => _showAddPlayerFlow(context, provider),
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isPrimary
              ? LinearGradient(
            colors: [
              Colors.red.withOpacity(0.85),
              Colors.red.withOpacity(0.55),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isPrimary ? null : generalGlassDark.withOpacity(0.5),
          border: Border.all(
            color: isPrimary
                ? Colors.red.withOpacity(0.6)
                : glassBorder.withOpacity(0.05),
            width: 0.5,
          ),
          boxShadow: isPrimary
              ? [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 14,
              spreadRadius: 0,
            ),
          ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPrimary
                    ? Colors.white.withOpacity(0.15)
                    : Colors.red.withOpacity(0.12),
                border: Border.all(
                  color: isPrimary
                      ? Colors.white.withOpacity(0.25)
                      : Colors.red.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Icon(
                icon,
                size: 15,
                color: isPrimary ? Colors.white : Colors.red,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ ADD PLAYER FLOW ============
  Future<void> _showAddPlayerFlow(
      BuildContext context, AdminProvider provider) async {
    final playerData = await _showPlayerInfoDialog(context, provider);
    if (playerData == null) return;
    if (!context.mounted) return;

    final membershipResult =
    await _showMembershipSetupDialog(context, provider, playerData);
    if (membershipResult == null) return;
    if (!context.mounted) return;

    await _finalizeAddPlayer(context, provider, playerData, membershipResult);
  }

  // ---------- STEP 1: Player Info Dialog ----------
  Future<Map<String, dynamic>?> _showPlayerInfoDialog(
      BuildContext context, AdminProvider provider) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emergencyNameCtrl = TextEditingController();
    final emergencyPhoneCtrl = TextEditingController();

    String level = 'N - Beginner';
    String weightClass = '63.5 kg';
    String? branchId;
    BranchModel? selectedBranch;

    final branches = provider.branches;
    if (branches.isNotEmpty) {
      branchId = branches.first.id;
      selectedBranch = branches.first;
    }

    // ===== YENİ: Sport, seçili branch'in sporlarına göre başlar =====
    String sport = (selectedBranch != null &&
        selectedBranch!.sports.isNotEmpty)
        ? selectedBranch!.sports.first
        : 'Kickboxing';

    final levels = ['N - Beginner', 'C - Intermediate', 'B - Advanced', 'A - Professional'];
    final weights = [
      '55.0 kg', '57.5 kg', '60.0 kg', '63.5 kg', '67.0 kg',
      '70.0 kg', '73.5 kg', '77.0 kg', '81.0 kg', '85.0 kg', '90.0 kg+'
    ];

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            // ===== YENİ: Sporlar seçili branch'e göre dinamik =====
            final sports =
            (selectedBranch != null && selectedBranch!.sports.isNotEmpty)
                ? selectedBranch!.sports
                : <String>[
              'Kickboxing',
              'Boxing',
              'MMA',
              'Muay Thai',
              'Jiu-Jitsu'
            ];

            // Güvenlik: seçili sport bu listede yoksa ilkine düş
            if (!sports.contains(sport)) {
              sport = sports.first;
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: generalGlassDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.red.withOpacity(0.4), width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.red.withOpacity(0.35),
                                    width: 0.5),
                              ),
                              child: const Icon(Icons.person_add_alt_1_rounded,
                                  size: 16, color: Colors.red),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ADD NEW PLAYER',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.8,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Step 1 of 2 · Player Info',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        _label('Full Name'),
                        _textField(nameCtrl, 'Enter full name'),
                        const SizedBox(height: 12),

                        _label('Phone Number'),
                        _textField(phoneCtrl, 'e.g. 01012345678',
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: 12),

                        // ===== BRANCH ÖNCE (sporlar buna bağlı) =====
                        _label('Branch'),
                        if (branches.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 14, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No branches. Add a branch first.',
                                    style: GoogleFonts.inter(
                                        fontSize: 10, color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.25)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: branchId,
                                isExpanded: true,
                                dropdownColor: generalGlassDark,
                                icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white54,
                                    size: 18),
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: Colors.white),
                                items: branches.map((b) {
                                  return DropdownMenuItem<String>(
                                    value: b.id,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined,
                                            size: 12, color: Colors.white54),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            b.name,
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.white),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setStateSB(() {
                                    branchId = val;
                                    selectedBranch = branches
                                        .where((b) => b.id == val)
                                        .firstOrNull;
                                    // Branch değişince sport'u yeni branch'in
                                    // ilk sporuna resetle
                                    if (selectedBranch != null &&
                                        selectedBranch!.sports.isNotEmpty) {
                                      if (!selectedBranch!.sports
                                          .contains(sport)) {
                                        sport =
                                            selectedBranch!.sports.first;
                                      }
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),

                        // ===== SPORT (dinamik — branch'e göre) =====
                        _label('Sport'),
                        _dropdown(sport, sports,
                                (v) => setStateSB(() => sport = v!)),
                        const SizedBox(height: 12),

                        _label('Level'),
                        _dropdown(level, levels,
                                (v) => setStateSB(() => level = v!)),
                        const SizedBox(height: 12),

                        _label('Weight Class'),
                        _dropdown(weightClass, weights,
                                (v) => setStateSB(() => weightClass = v!)),
                        const SizedBox(height: 12),

                        _label('Emergency Contact Name'),
                        _textField(emergencyNameCtrl, 'e.g. Father / Mother'),
                        const SizedBox(height: 12),

                        _label('Emergency Contact Phone'),
                        _textField(emergencyPhoneCtrl, 'e.g. 01098765432',
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: 22),

                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(dialogContext),
                                child: Container(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.1)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'CANCEL',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (nameCtrl.text.trim().isEmpty ||
                                      phoneCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(dialogContext)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          'Name and phone are required',
                                          style: GoogleFonts.inter(
                                              fontSize: 11)),
                                      backgroundColor: Colors.red,
                                    ));
                                    return;
                                  }
                                  if (selectedBranch == null) {
                                    ScaffoldMessenger.of(dialogContext)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          'Please select a branch',
                                          style: GoogleFonts.inter(
                                              fontSize: 11)),
                                      backgroundColor: Colors.red,
                                    ));
                                    return;
                                  }
                                  Navigator.pop(dialogContext, {
                                    'fullName': nameCtrl.text.trim(),
                                    'phone': phoneCtrl.text.trim(),
                                    'sport': sport,
                                    'level': level,
                                    'weightClass': weightClass,
                                    'emergencyContact':
                                    emergencyNameCtrl.text.trim().isEmpty
                                        ? nameCtrl.text.trim()
                                        : emergencyNameCtrl.text.trim(),
                                    'emergencyPhone':
                                    emergencyPhoneCtrl.text.trim().isEmpty
                                        ? phoneCtrl.text.trim()
                                        : emergencyPhoneCtrl.text.trim(),
                                    'branch': selectedBranch,
                                  });
                                },
                                child: Container(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red.withOpacity(0.95),
                                        Colors.red.withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.3),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'NEXT',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.arrow_forward_rounded,
                                          size: 14, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------- STEP 2: Membership Setup Dialog (DISCOUNT EKLENDI) ----------
  Future<Map<String, dynamic>?> _showMembershipSetupDialog(
      BuildContext context,
      AdminProvider provider,
      Map<String, dynamic> playerData,
      ) async {
    final branch = playerData['branch'] as BranchModel;
    final fullName = playerData['fullName'] as String;

    final packages = provider.packages.where((p) {
      return p.branch == branch.name;
    }).toList();

    final classes = provider.classes.where((c) {
      return c.branchId == branch.id || c.branch == branch.name;
    }).toList();

    String? selectedPackageId = packages.isNotEmpty ? packages.first.id : null;
    final amountCtrl = TextEditingController(
      text: packages.isNotEmpty ? packages.first.price.toStringAsFixed(0) : '',
    );
    // ===== YENİ: DISCOUNT CONTROLLER =====
    final discountCtrl = TextEditingController(text: '0');
    String paymentMethod = 'Cash';
    final paymentMethods = ['Cash', 'InstaPay', 'Visa'];

    String? selectedGroupId = classes.isNotEmpty ? classes.first.id : null;
    String? selectedGroupName =
    classes.isNotEmpty ? classes.first.className : null;

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            // Canlı hesap: amount - discount
            final double originalAmount =
                double.tryParse(amountCtrl.text.trim()) ?? 0;
            final double discount =
                double.tryParse(discountCtrl.text.trim()) ?? 0;
            final double finalAmount =
            (originalAmount - discount).clamp(0, double.infinity).toDouble();

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: generalGlassDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.red.withOpacity(0.4), width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.red.withOpacity(0.35),
                                    width: 0.5),
                              ),
                              child: const Icon(Icons.card_membership_rounded,
                                  size: 16, color: Colors.red),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CREATE MEMBERSHIP',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.8,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Step 2 of 2 · $fullName',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 12, color: Colors.white54),
                              const SizedBox(width: 8),
                              Text(
                                'Branch: ',
                                style: GoogleFonts.inter(
                                    fontSize: 10, color: Colors.white54),
                              ),
                              Expanded(
                                child: Text(
                                  branch.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        _label('Package'),
                        if (packages.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 14, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No packages in this branch.',
                                    style: GoogleFonts.inter(
                                        fontSize: 10, color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.25)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedPackageId,
                                isExpanded: true,
                                dropdownColor: generalGlassDark,
                                icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white54,
                                    size: 18),
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: Colors.white),
                                items: packages.map((p) {
                                  return DropdownMenuItem<String>(
                                    value: p.id,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p.name,
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.white),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${p.price.toStringAsFixed(0)} EGP',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setStateSB(() {
                                    selectedPackageId = val;
                                    final p = packages
                                        .where((x) => x.id == val)
                                        .firstOrNull;
                                    if (p != null) {
                                      amountCtrl.text =
                                          p.price.toStringAsFixed(0);
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            const Icon(Icons.groups_outlined,
                                size: 12, color: Colors.red),
                            const SizedBox(width: 6),
                            Text(
                              'Group',
                              style: GoogleFonts.inter(
                                  fontSize: 10, color: Colors.white54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (classes.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 14, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No classes in this branch.',
                                    style: GoogleFonts.inter(
                                        fontSize: 10, color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.25)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedGroupId,
                                isExpanded: true,
                                dropdownColor: generalGlassDark,
                                icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white54,
                                    size: 18),
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: Colors.white),
                                items: classes.map((c) {
                                  return DropdownMenuItem<String>(
                                    value: c.id,
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.sports_martial_arts,
                                            size: 12,
                                            color: Colors.white54),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            c.className,
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.white),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (c.sport.isNotEmpty)
                                          Text(
                                            c.sport,
                                            style: GoogleFonts.inter(
                                              fontSize: 9,
                                              color: Colors.red,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setStateSB(() {
                                    selectedGroupId = val;
                                    final c = classes
                                        .where((x) => x.id == val)
                                        .firstOrNull;
                                    selectedGroupName = c?.className;
                                  });
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),

                        // ===== AMOUNT =====
                        _label('Amount (EGP)'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: TextField(
                            controller: amountCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setStateSB(() {}),
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                              EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ===== YENİ: DISCOUNT =====
                        Row(
                          children: [
                            _label('Discount (EGP)'),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: Colors.orange.withOpacity(0.35),
                                    width: 0.5),
                              ),
                              child: Text(
                                'OPTIONAL',
                                style: GoogleFonts.inter(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: discount > 0
                                    ? Colors.orange.withOpacity(0.5)
                                    : Colors.white.withOpacity(0.1),
                                width: discount > 0 ? 1 : 0.5),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.local_offer_rounded,
                                  size: 14,
                                  color: discount > 0
                                      ? Colors.orange
                                      : Colors.white38),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: discountCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setStateSB(() {}),
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: discount > 0
                                          ? Colors.orange
                                          : Colors.white,
                                      fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.white30),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                    EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              Text(
                                'EGP',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ===== YENİ: CANLI ÖZET =====
                        if (originalAmount > 0) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: discount > 0
                                    ? [
                                  Colors.green.withOpacity(0.1),
                                  Colors.green.withOpacity(0.03),
                                ]
                                    : [
                                  Colors.white.withOpacity(0.03),
                                  Colors.white.withOpacity(0.01),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: discount > 0
                                    ? Colors.green.withOpacity(0.35)
                                    : Colors.white.withOpacity(0.06),
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                _summaryRow(
                                  'Package Price',
                                  '${originalAmount.toStringAsFixed(0)} EGP',
                                  Colors.white70,
                                ),
                                if (discount > 0) ...[
                                  const SizedBox(height: 6),
                                  _summaryRow(
                                    'Discount',
                                    '-${discount.toStringAsFixed(0)} EGP',
                                    Colors.orange,
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Container(
                                  height: 0.5,
                                  color: Colors.white.withOpacity(0.08),
                                ),
                                const SizedBox(height: 6),
                                _summaryRow(
                                  'Total',
                                  '${finalAmount.toStringAsFixed(0)} EGP',
                                  Colors.green,
                                  bold: true,
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        _label('Payment Method'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: paymentMethods.map((m) {
                            final isSelected = paymentMethod == m;
                            return GestureDetector(
                              onTap: () =>
                                  setStateSB(() => paymentMethod = m),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.red.withOpacity(0.12)
                                      : Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.red.withOpacity(0.6)
                                        : Colors.white.withOpacity(0.1),
                                    width: isSelected ? 1 : 0.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.2),
                                      blurRadius: 10,
                                    ),
                                  ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getPaymentIcon(m),
                                      size: 12,
                                      color: isSelected
                                          ? Colors.red
                                          : Colors.white54,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      m,
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 22),

                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(dialogContext),
                                child: Container(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.1)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'CANCEL',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  final pkg = packages
                                      .where((p) => p.id == selectedPackageId)
                                      .firstOrNull;
                                  if (pkg == null) {
                                    ScaffoldMessenger.of(dialogContext)
                                        .showSnackBar(SnackBar(
                                      content: Text('Please select a package',
                                          style: GoogleFonts.inter(
                                              fontSize: 11)),
                                      backgroundColor: Colors.red,
                                    ));
                                    return;
                                  }
                                  final amount = double.tryParse(
                                      amountCtrl.text.trim()) ??
                                      0;
                                  if (amount <= 0) {
                                    ScaffoldMessenger.of(dialogContext)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          'Please enter a valid amount',
                                          style: GoogleFonts.inter(
                                              fontSize: 11)),
                                      backgroundColor: Colors.red,
                                    ));
                                    return;
                                  }
                                  final double discountVal = double.tryParse(
                                      discountCtrl.text.trim()) ??
                                      0;
                                  if (discountVal < 0) {
                                    ScaffoldMessenger.of(dialogContext)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          'Discount cannot be negative',
                                          style: GoogleFonts.inter(
                                              fontSize: 11)),
                                      backgroundColor: Colors.red,
                                    ));
                                    return;
                                  }
                                  if (discountVal >= amount) {
                                    ScaffoldMessenger.of(dialogContext)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          'Discount must be less than amount',
                                          style: GoogleFonts.inter(
                                              fontSize: 11)),
                                      backgroundColor: Colors.red,
                                    ));
                                    return;
                                  }
                                  Navigator.pop(dialogContext, {
                                    'package': pkg,
                                    'groupId': selectedGroupId,
                                    'groupName': selectedGroupName,
                                    'amount': amount,
                                    'discount': discountVal,
                                    'paymentMethod': paymentMethod,
                                  });
                                },
                                child: Container(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red.withOpacity(0.95),
                                        Colors.red.withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.3),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_rounded,
                                          size: 14, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        'ADD PLAYER',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===== SUMMARY ROW HELPER =====
  Widget _summaryRow(String label, String value, Color color,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold ? Colors.white : Colors.white60,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: bold ? 12 : 11,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ---------- FINAL: Save Player (DISCOUNT DESTEĞİ EKLENDİ) ----------
  Future<void> _finalizeAddPlayer(
      BuildContext context,
      AdminProvider provider,
      Map<String, dynamic> playerData,
      Map<String, dynamic> membershipData,
      ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) => const Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.red),
        ),
      ),
    );

    final fullName = playerData['fullName'] as String;
    final phone = playerData['phone'] as String;
    final sport = playerData['sport'] as String;
    final level = playerData['level'] as String;
    final weightClass = playerData['weightClass'] as String;
    final emergencyContact = playerData['emergencyContact'] as String;
    final emergencyPhone = playerData['emergencyPhone'] as String;
    final branch = playerData['branch'] as BranchModel;

    final pkg = membershipData['package'] as PackageModel;
    final groupId = membershipData['groupId'] as String?;
    final groupName = membershipData['groupName'] as String?;
    final originalAmount = membershipData['amount'] as double;
    final discount = (membershipData['discount'] as double?) ?? 0;
    final double finalAmount = (originalAmount - discount).clamp(0, double.infinity).toDouble();
    final paymentMethod = membershipData['paymentMethod'] as String;

    final authEmail = '$phone@lycans.app';

    try {
      // 1) AUTH USER CREATE — REST API
      final apiKey = Firebase.app().options.apiKey;
      final signUpUrl = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
      );

      final authResponse = await http.post(
        signUpUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': authEmail,
          'password': phone,
          'returnSecureToken': true,
        }),
      );

      if (authResponse.statusCode != 200) {
        final errBody = jsonDecode(authResponse.body);
        final errCode = errBody['error']?['message'] ?? 'AUTH_ERROR';
        String friendlyMsg = 'Failed to create account';
        if (errCode == 'EMAIL_EXISTS') {
          friendlyMsg = 'This phone number is already registered.';
        } else if (errCode ==
            'WEAK_PASSWORD : Password should be at least 6 characters') {
          friendlyMsg = 'Password must be at least 6 characters.';
        } else if (errCode.toString().contains('WEAK_PASSWORD')) {
          friendlyMsg = 'Password is too weak.';
        } else if (errCode == 'INVALID_EMAIL') {
          friendlyMsg = 'Invalid phone format.';
        }
        throw Exception(friendlyMsg);
      }

      final authResult = jsonDecode(authResponse.body);
      final uid = authResult['localId'] as String;

      // 2) RESERVE PLAYER NUMBER
      final counterRef =
      FirebaseDatabase.instance.ref('counters/player_number');
      final txResult = await counterRef.runTransaction((current) {
        final val = (current as num?)?.toInt() ?? 9;
        return Transaction.success(val + 1);
      });
      final playerNumber = (txResult.snapshot.value as num?)?.toInt() ?? 10;

      await FirebaseDatabase.instance
          .ref('counters/player_map/$playerNumber')
          .set(uid);

      final now = DateTime.now();
      final durationDays = pkg.durationDays > 0 ? pkg.durationDays : 30;
      final endDate = now.add(Duration(days: durationDays));

      // 3) WRITE USER
      await FirebaseDatabase.instance.ref('users/$uid').set({
        'uid': uid,
        'fullName': fullName,
        'phone': phone,
        'email': authEmail,
        'sport': sport,
        'level': level,
        'weightClass': weightClass,
        'emergencyContact': emergencyContact,
        'emergencyPhone': emergencyPhone,
        'guardian': 'Not applicable',
        'membershipId': '',
        'currentPackageId': pkg.id,
        'playerNumber': playerNumber,
        'branchId': branch.id,
        'branchName': branch.name,
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

      // 4) WRITE MEMBERSHIP (price = finalAmount, discount ayrıca saklanır)
      final membershipRef =
      FirebaseDatabase.instance.ref('memberships').push();
      final membershipMap = <String, dynamic>{
        'id': membershipRef.key,
        'userId': uid,
        'planName': pkg.name,
        'planType': pkg.name,
        'price': finalAmount,
        'originalPrice': originalAmount,
        'discount': discount,
        'startDate': now.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'renewDate': endDate.toIso8601String(),
        'isActive': true,
        'isUnlimited': pkg.isUnlimited,
        'maxSessions': pkg.maxSessions,
        'usedSessions': 0,
        'durationDays': durationDays,
        'packageId': pkg.id,
        'weeklySessions': pkg.weeklySessions,
        'branchId': branch.id,
        'branchName': branch.name,
      };
      if (groupId != null && groupId.isNotEmpty) {
        membershipMap['groupId'] = groupId;
      }
      if (groupName != null && groupName.isNotEmpty) {
        membershipMap['groupName'] = groupName;
      }
      await membershipRef.set(membershipMap);

      await FirebaseDatabase.instance.ref('users/$uid').update({
        'membershipId': membershipRef.key,
      });

      // 5) WRITE INVOICE (amount = finalAmount, discount + original saklanır)
      final invoiceRef = FirebaseDatabase.instance.ref('invoices').push();
      await invoiceRef.set({
        'id': invoiceRef.key,
        'invoiceNumber':
        'INV-${now.millisecondsSinceEpoch.toString().substring(5)}',
        'userId': uid,
        'playerName': fullName,
        'packageName': pkg.name,
        'description': '${pkg.name} — $durationDays Days',
        'amount': finalAmount,
        'originalAmount': originalAmount,
        'discount': discount,
        'paymentMethod': paymentMethod,
        'staffName': provider.admin?.fullName ?? 'Admin',
        'date': now.toIso8601String(),
        'isPaid': true,
      });

      // 6) WELCOME NOTIFICATION
      final notifRef = FirebaseDatabase.instance.ref('notifications').push();
      await notifRef.set({
        'id': notifRef.key,
        'userId': uid,
        'title': 'Welcome to Lycans Fight Club!',
        'message':
        'Your account is ready. You are on ${pkg.name}. Let\'s train!',
        'timestamp': now.toIso8601String(),
        'isRead': false,
        'type': 'welcome',
        'iconType': 'welcome',
      });

      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        _showPlayerAddedDialog(
          context,
          playerNumber: playerNumber,
          phone: phone,
          fullName: fullName,
          packageName: pkg.name,
          originalAmount: originalAmount,
          discount: discount,
          finalAmount: finalAmount,
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: GoogleFonts.inter(fontSize: 11)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ---------- SUCCESS DIALOG (DISCOUNT GÖSTERİMİ EKLENDİ) ----------
  void _showPlayerAddedDialog(
      BuildContext context, {
        required int playerNumber,
        required String phone,
        required String fullName,
        required String packageName,
        required double originalAmount,
        required double discount,
        required double finalAmount,
      }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: generalGlassDark,
              borderRadius: BorderRadius.circular(20),
              border:
              Border.all(color: Colors.green.withOpacity(0.4), width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.12),
                    border:
                    Border.all(color: Colors.green.withOpacity(0.4), width: 1),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF00C853), size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  'PLAYER ADDED',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fullName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 14),

                // Player number
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border:
                    Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PLAYER NO.  ',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: Colors.white54,
                        ),
                      ),
                      Text(
                        '#$playerNumber',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Login credentials
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: Colors.red.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.key_rounded,
                              size: 12, color: Colors.red),
                          const SizedBox(width: 6),
                          Text(
                            'LOGIN CREDENTIALS',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _credentialRow(Icons.phone_outlined, 'Phone', phone),
                      const SizedBox(height: 6),
                      _credentialRow(
                          Icons.lock_outline_rounded, 'Password', phone),
                      const SizedBox(height: 8),
                      Text(
                        'Player can log in using their phone number and password.',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Colors.white54,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ===== PRICING SUMMARY =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: discount > 0
                        ? Colors.green.withOpacity(0.06)
                        : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: discount > 0
                          ? Colors.green.withOpacity(0.25)
                          : Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded,
                              size: 12, color: Colors.white54),
                          const SizedBox(width: 6),
                          Text(
                            'PACKAGE PAYMENT',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _summaryRow(
                        packageName,
                        '${originalAmount.toStringAsFixed(0)} EGP',
                        Colors.white70,
                      ),
                      if (discount > 0) ...[
                        const SizedBox(height: 6),
                        _summaryRow(
                          'Discount',
                          '-${discount.toStringAsFixed(0)} EGP',
                          Colors.orange,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 0.5,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        const SizedBox(height: 6),
                      ] else
                        const SizedBox(height: 6),
                      _summaryRow(
                        discount > 0 ? 'Total Paid' : 'Amount Paid',
                        '${finalAmount.toStringAsFixed(0)} EGP',
                        Colors.green,
                        bold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'DONE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _credentialRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.white54),
        const SizedBox(width: 8),
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ============ SMALL HELPERS ============
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 10, color: Colors.white54),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint,
      {TextInputType? keyboardType}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 11, color: Colors.white30),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _dropdown(
      String value, List<String> items, void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: generalGlassDark,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white54, size: 18),
          style: GoogleFonts.inter(fontSize: 11, color: Colors.white),
          items: items.map((s) {
            return DropdownMenuItem<String>(
              value: s,
              child: Text(s),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'Cash':
        return Icons.payments_outlined;
      case 'InstaPay':
        return Icons.bolt_rounded;
      case 'Visa':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  // ===== KPI BÖLÜMÜ =====
  Widget _buildKpiSection(int total, int active, int attendance, int classes,
      Color bgGlass, Color borderGlass) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: bgGlass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderGlass),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKpiItem(
                  Icons.person_outline, '$total', 'Total Members', true),
              _buildVerticalDivider(),
              _buildKpiItem(Icons.person_add_alt_1_outlined, '$active',
                  'Active Members', true),
              _buildVerticalDivider(),
              _buildKpiItem(Icons.calendar_today_outlined, '$attendance',
                  "Today's Attendance", false),
              _buildVerticalDivider(),
              _buildKpiItem(Icons.event_note_outlined, '$classes',
                  'Classes Today', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiItem(
      IconData icon, String value, String label, bool isHighlighted) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isHighlighted ? Colors.red : Colors.white54,
          size: 18,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w400,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withOpacity(0.1),
    );
  }

  // ===== STRONGER EVERY DAY CARD =====
  Widget _buildStrongerEveryDayCard() {
    return Container(
      width: double.infinity,
      height: 175,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 0.5),
        image: const DecorationImage(
          image: AssetImage('assets/images/dashboard_card_bg.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 20,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TRAINING',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.red,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stronger\nEvery Day',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.1,
              ),
            ),
            const Spacer(),
            Text(
              'Same goal.\nBigger dreams.',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.white54,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child:
              const Icon(Icons.chevron_right, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required String bgImage,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          image: DecorationImage(
            image: AssetImage(bgImage),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: Colors.red, size: 18),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.chevron_right,
                        color: Colors.white, size: 12),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== MEMBERSHIP MIX =====
  Widget _buildMembershipMixCard(List<Map<String, dynamic>> membershipMix,
      int totalActive, Color bgGlass, Color borderGlass) {
    final double ringValue = membershipMix.isNotEmpty
        ? ((membershipMix.first['percentage'] as double) / 100).clamp(0.0, 1.0)
        : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgGlass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderGlass),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Membership Mix',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Total active memberships',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 7,
                          color: Colors.red.withOpacity(0.2),
                        ),
                        CircularProgressIndicator(
                          value: ringValue,
                          strokeWidth: 7,
                          color: Colors.red,
                          strokeCap: StrokeCap.round,
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$totalActive',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Total',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: membershipMix.isEmpty
                        ? Text(
                      'No active memberships yet',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: Colors.white54),
                    )
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: membershipMix.take(3).map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius:
                                  BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item['name'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${item['count']}  ·  ${(item['percentage'] as double).toStringAsFixed(0)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.chevron_right,
                        color: Colors.white, size: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== BOTTOM SHEET =====
  void _showChartBottomSheet(
      BuildContext context, {
        required String title,
        required Widget chartWidget,
        required Color glassDark,
        required Color glassBorder,
      }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: glassDark,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(child: chartWidget),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== DİNAMİK HESAPLAMALAR =====
  List<Map<String, dynamic>> _calculateMonthlyRevenue(
      List<InvoiceModel> invoices) {
    final now = DateTime.now();
    final months = <Map<String, dynamic>>[];
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthInvoices = invoices.where((inv) =>
      inv.date.year == monthDate.year &&
          inv.date.month == monthDate.month &&
          inv.isPaid);
      final total =
      monthInvoices.fold<double>(0, (sum, inv) => sum + inv.amount);
      months.add({
        'month': DateFormat('MMM').format(monthDate),
        'revenue': total,
      });
    }
    return months;
  }

  List<Map<String, dynamic>> _calculateMembershipMix(
      AdminProvider provider) {
    final now = DateTime.now();

    final activeMemberships = provider.memberships.where((m) {
      final isActive = m['isActive'] ?? false;
      final isFrozen = m['isFrozen'] ?? false;
      if (!isActive || isFrozen) return false;
      final endDate = DateTime.tryParse(m['endDate']?.toString() ?? '');
      if (endDate == null) return false;
      return endDate.isAfter(now);
    }).toList();

    if (activeMemberships.isEmpty) return [];

    final packageCounts = <String, int>{};
    for (final membership in activeMemberships) {
      final planName =
      (membership['planName'] ?? membership['planType'] ?? '')
          .toString()
          .trim();
      if (planName.isNotEmpty) {
        packageCounts[planName] = (packageCounts[planName] ?? 0) + 1;
      }
    }

    final totalActive = activeMemberships.length;
    final result = <Map<String, dynamic>>[];
    packageCounts.forEach((name, count) {
      final percentage = (count / totalActive) * 100;
      result.add({
        'name': name,
        'count': count,
        'percentage': percentage,
      });
    });
    result.sort((a, b) =>
        (b['percentage'] as double).compareTo(a['percentage'] as double));
    return result;
  }

  // ===== CHARTS =====
  Widget _buildRevenueChart(List<Map<String, dynamic>> revenueData) {
    final maxRevenue = revenueData
        .map((d) => d['revenue'] as double)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = maxRevenue > 0 ? maxRevenue * 1.2 : 1000.0;

    return maxRevenue > 0
        ? BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < revenueData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      revenueData[index]['month'] as String,
                      style: GoogleFonts.inter(
                          fontSize: 9, color: Colors.white54),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: revenueData.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value['revenue'] as double,
                width: 16,
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [Colors.red, Colors.red.withOpacity(0.3)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    )
        : Center(
      child: Text(
        'No revenue data yet',
        style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
      ),
    );
  }

  Widget _buildNewMembersChart(List<PlayerModel> players) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    final weeks = <Map<String, dynamic>>[];

    for (int i = 3; i >= 0; i--) {
      final weekStart = thisMonday.subtract(Duration(days: i * 7));
      final weekStartDate =
      DateTime(weekStart.year, weekStart.month, weekStart.day);
      final weekEnd = weekStartDate.add(const Duration(days: 7));

      final count = players.where((p) {
        final joinDate =
        DateTime(p.joinDate.year, p.joinDate.month, p.joinDate.day);
        return (joinDate.isAfter(weekStartDate) ||
            joinDate.isAtSameMomentAs(weekStartDate)) &&
            joinDate.isBefore(weekEnd);
      }).length;

      weeks.add({'week': 'W${4 - i}', 'count': count});
    }

    final maxCount =
    weeks.map((w) => w['count'] as int).fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = maxCount > 0 ? (maxCount * 1.3).toDouble() : 5.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < weeks.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      weeks[index]['week'] as String,
                      style: GoogleFonts.inter(
                          fontSize: 9, color: Colors.white54),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: weeks.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: (entry.value['count'] as int).toDouble(),
                width: 16,
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [Colors.red, Colors.red.withOpacity(0.3)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ============ COACH CHECK-IN CARD ============
class _CoachCheckInCard extends StatefulWidget {
  const _CoachCheckInCard();

  @override
  State<_CoachCheckInCard> createState() => _CoachCheckInCardState();
}

class _CoachCheckInCardState extends State<_CoachCheckInCard> {
  String? _selectedBranchId;
  bool _isSubmitting = false;
  Timer? _ticker;
  DateTime _now = DateTime.now();

  static const Color _red = Color(0xFFE50914);
  static const Color _dark = Color(0xFF0F1115);
  static const Color _green = Color(0xFF00C853);
  static const Duration _cooldown = Duration(hours: 1);

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final admin = provider.admin;
    if (admin == null) return const SizedBox.shrink();

    final canCheckIn =
    provider.hasPermission(CoachPermissions.markCoachAttendance);
    if (!canCheckIn) return const SizedBox.shrink();

    final branches = provider.branches.where((b) => b.isActive).toList();
    if (branches.isEmpty) return const SizedBox.shrink();

    _selectedBranchId ??= branches.first.id;
    final selectedBranch = branches.firstWhere(
          (b) => b.id == _selectedBranchId,
      orElse: () => branches.first,
    );

    final latestCheckIn = provider.getTodayCheckIn(admin.uid);
    DateTime? lastTime;
    if (latestCheckIn != null) {
      lastTime =
          DateTime.tryParse(latestCheckIn['checkedInAt']?.toString() ?? '');
    }

    Duration remaining = Duration.zero;
    if (lastTime != null) {
      final elapsed = _now.difference(lastTime);
      if (elapsed < _cooldown) {
        remaining = _cooldown - elapsed;
      }
    }
    final inCooldown = remaining.inSeconds > 0;

    String lastLabel = 'No check-in yet';
    if (lastTime != null) {
      final hh = lastTime.hour.toString().padLeft(2, '0');
      final mm = lastTime.minute.toString().padLeft(2, '0');
      final bName = latestCheckIn?['branchName']?.toString() ?? '';
      lastLabel = '$hh:$mm · $bName';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _dark.withOpacity(0.5),
        border: Border.all(color: _red.withOpacity(0.25), width: 0.8),
        boxShadow: [
          BoxShadow(color: _red.withOpacity(0.08), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(5),
                  border:
                  Border.all(color: _red.withOpacity(0.35), width: 0.5),
                ),
                child:
                Icon(Icons.access_time_rounded, size: 9, color: _red),
              ),
              const SizedBox(width: 6),
              Text(
                'COACH CHECK-IN',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                  color: _red,
                ),
              ),
              const Spacer(),
              if (lastTime != null)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded,
                          size: 9, color: Colors.white38),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          lastLabel,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Colors.white54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: branches.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final b = branches[index];
                      final isSelected = b.id == _selectedBranchId;
                      return GestureDetector(
                        onTap: inCooldown || _isSubmitting
                            ? null
                            : () => setState(() => _selectedBranchId = b.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            gradient: isSelected
                                ? LinearGradient(
                              colors: [
                                _red.withOpacity(0.18),
                                _red.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                                : null,
                            color: isSelected
                                ? null
                                : Colors.white.withOpacity(0.03),
                            border: Border.all(
                              color: isSelected
                                  ? _red.withOpacity(0.7)
                                  : Colors.white.withOpacity(0.08),
                              width: isSelected ? 1 : 0.5,
                            ),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: _red.withOpacity(0.2),
                                blurRadius: 8,
                              ),
                            ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 9,
                                color: isSelected ? _red : Colors.white54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                b.name,
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildCompactAttendButton(
                provider,
                selectedBranch,
                inCooldown,
                remaining,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAttendButton(
      AdminProvider provider,
      BranchModel branch,
      bool inCooldown,
      Duration remaining,
      ) {
    String label;
    if (_isSubmitting) {
      label = 'WAIT';
    } else if (inCooldown) {
      final m = remaining.inMinutes;
      final s = remaining.inSeconds % 60;
      label = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    } else {
      label = 'CHECK IN';
    }

    final isDisabled = _isSubmitting || inCooldown;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () async {
        setState(() => _isSubmitting = true);
        try {
          await provider.recordCoachAttendance(
            branchId: branch.id,
            branchName: branch.name,
          );
          if (mounted) {
            final now = DateTime.now();
            final hh = now.hour.toString().padLeft(2, '0');
            final mm = now.minute.toString().padLeft(2, '0');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Checked in at ${branch.name} · $hh:$mm',
                  style: GoogleFonts.inter(fontSize: 11),
                ),
                backgroundColor: _green,
                duration: const Duration(seconds: 2),
              ),
            );
            setState(() {
              _now = DateTime.now();
              _isSubmitting = false;
            });
            return;
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e',
                    style: GoogleFonts.inter(fontSize: 11)),
                backgroundColor: _red,
              ),
            );
          }
        } finally {
          if (mounted && _isSubmitting) {
            setState(() => _isSubmitting = false);
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          gradient: isDisabled
              ? LinearGradient(
            colors: [
              Colors.white.withOpacity(0.05),
              Colors.white.withOpacity(0.03),
            ],
          )
              : LinearGradient(
            colors: [
              _red.withOpacity(0.95),
              _red.withOpacity(0.7),
            ],
          ),
          border: Border.all(
            color: isDisabled
                ? Colors.white.withOpacity(0.1)
                : _red.withOpacity(0.5),
            width: 0.5,
          ),
          boxShadow: isDisabled
              ? null
              : [
            BoxShadow(
              color: _red.withOpacity(0.35),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isSubmitting)
              const SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                inCooldown
                    ? Icons.lock_clock_rounded
                    : Icons.flash_on_rounded,
                size: 11,
                color: isDisabled ? Colors.white38 : Colors.white,
              ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isDisabled ? Colors.white38 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
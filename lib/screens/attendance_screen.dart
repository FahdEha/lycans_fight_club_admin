import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/class_model.dart';
import '../models/player_model.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // ===== SCANNER STATE =====
  MobileScannerController? _scannerController;
  bool _isScanning = false;
  String? _scanResult;
  DateTime? _lastScanTime;
  DateTime _selectedDate = DateTime.now();

  // ===== TOP TAB =====
  int _topTab = 0;

  // ===== CHECKLIST STATE =====
  String? _checklistGroupId;
  String? _checklistGroupName;
  final Map<String, bool> _checklistMarks = {};
  bool _savingChecklist = false;

  // ===== COLORS =====
  static const Color _red = Color(0xFFE50914);
  static const Color _dark = Color(0xFF0F1115);
  static const Color _green = Color(0xFF00C853);
  static const Color _orange = Color(0xFFFF9800);

  // Glass constants
  static final Color _glassBg = const Color(0xFF0F1115).withOpacity(0.4);
  static final Color _glassBorder = Colors.white.withOpacity(0.08);

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  // ============ SCANNER METHODS ============
  void _startScanner() {
    _scannerController?.dispose();
    _scannerController = MobileScannerController(
      formats: [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    setState(() {
      _isScanning = true;
      _scanResult = null;
      _lastScanTime = null;
    });
  }

  void _stopScanner() {
    _scannerController?.dispose();
    _scannerController = null;
    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.redAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF151515),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF151515),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _getDateText() {
    final now = DateTime.now();
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      return 'Today';
    }
    return DateFormat('MMM dd').format(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ===== BACKGROUND IMAGE =====
          Positioned.fill(
            child: Image.asset(
              'assets/images/attendance_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // ===== DARK OVERLAY =====
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.55)),
          ),

          // ===== CONTENT =====
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: _buildTopTabs(),
                ),
                Expanded(
                  child: _topTab == 0
                      ? _buildScannerTab()
                      : _buildChecklistTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ============== TOP SEGMENTED TABS (Glass) ==================
  // ============================================================
  Widget _buildTopTabs() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _glassBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _glassBorder, width: 0.8),
          ),
          child: Row(
            children: [
              Expanded(
                child: _tabButton(
                  index: 0,
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'SCANNER',
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _tabButton(
                  index: 1,
                  icon: Icons.checklist_rounded,
                  label: 'CHECKLIST',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = _topTab == index;
    return GestureDetector(
      onTap: () => setState(() => _topTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
            colors: [
              _red.withOpacity(0.9),
              _red.withOpacity(0.6),
            ],
          )
              : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
            BoxShadow(
              color: _red.withOpacity(0.4),
              blurRadius: 16,
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
                color: selected ? Colors.white : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ============== TAB 1: SCANNER ==============================
  // ============================================================
  Widget _buildScannerTab() {
    final provider = Provider.of<AdminProvider>(context);
    final attendance = provider.attendance;

    final filteredAttendance = attendance.where((a) {
      return a.timestamp.year == _selectedDate.year &&
          a.timestamp.month == _selectedDate.month &&
          a.timestamp.day == _selectedDate.day;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: isWide
              ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  flex: 3,
                  child: _buildCheckInLog(filteredAttendance)),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: _buildScanner(provider)),
            ],
          )
              : Column(
            children: [
              _buildCheckInLog(filteredAttendance),
              const SizedBox(height: 20),
              _buildScanner(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckInLog(List filteredAttendance) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.monitor_heart_outlined,
                      color: _red, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Live Check-in Log',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: _glassBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: Colors.white.withOpacity(0.7), size: 11),
                      const SizedBox(width: 6),
                      Text(
                        _getDateText(),
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down,
                          color: Colors.white.withOpacity(0.7), size: 13),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (filteredAttendance.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'No check-ins found for this date',
                  style:
                  GoogleFonts.inter(fontSize: 12, color: Colors.white38),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredAttendance.length > 10
                  ? 10
                  : filteredAttendance.length,
              itemBuilder: (context, index) {
                final a = filteredAttendance[index];
                return _buildAttendanceRow(a);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRow(dynamic a) {
    final status = (a.status ?? 'recorded').toString();
    final isAbsent = status == 'absent';
    final accent = isAbsent ? _orange : _green;
    final statusLabel = isAbsent ? 'ABSENT' : 'PRESENT';
    final statusIcon =
    isAbsent ? Icons.cancel_rounded : Icons.check_circle_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(color: accent.withOpacity(0.6), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border:
              Border.all(color: _red.withOpacity(0.3), width: 1),
            ),
            child: Center(
              child: Text(
                _getInitials(a.playerName),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _red,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  a.playerName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.95),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  a.className,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border:
                    Border.all(color: accent.withOpacity(0.4), width: 0.5),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.inter(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('HH:mm').format(a.timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(statusIcon, color: accent, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner(AdminProvider provider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _red.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _red.withOpacity(0.15),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/images/scan_card_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _glassBorder),
                  ),
                  child: Icon(Icons.qr_code_2,
                      color: _red.withOpacity(0.8), size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan at Reception',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Place QR inside frame',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isScanning && _scannerController != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: MobileScanner(
                          controller: _scannerController,
                          onDetect: (capture) {
                            final now = DateTime.now();
                            if (_lastScanTime != null &&
                                now.difference(_lastScanTime!) <
                                    const Duration(seconds: 3)) {
                              return;
                            }
                            final barcodes = capture.barcodes;
                            if (barcodes.isEmpty) return;
                            final rawValue = barcodes.first.rawValue;
                            if (rawValue == null || rawValue.isEmpty) return;
                            _lastScanTime = now;
                            _processQrCode(rawValue, provider);
                          },
                          errorBuilder: (context, error) {
                            return Container(
                              color: Colors.black,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: Colors.red, size: 24),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Camera error',
                                      style: GoogleFonts.inter(
                                          fontSize: 9,
                                          color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Icon(
                        Icons.qr_code_scanner,
                        size: 48,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    _buildCorner(top: true, left: true),
                    _buildCorner(top: true, left: false),
                    _buildCorner(top: false, left: true),
                    _buildCorner(top: false, left: false),
                  ],
                ),
              ),
            ),
            if (_scanResult != null && !_isScanning) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _scanResult!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color:
                    _scanResult!.contains('+') ? _green : _red,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                if (_isScanning) {
                  _stopScanner();
                } else {
                  _startScanner();
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: _isScanning
                        ? [Colors.black87, Colors.black87]
                        : [const Color(0xFF900000), const Color(0xFFFF0000)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  border: Border.all(
                    color: _isScanning
                        ? Colors.white.withOpacity(0.2)
                        : _red.withOpacity(0.5),
                  ),
                  boxShadow: _isScanning
                      ? []
                      : [
                    BoxShadow(
                      color: _red.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isScanning
                          ? Icons.stop_circle_outlined
                          : Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isScanning ? 'STOP SCANNING' : 'START SCANNING',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    if (!_isScanning) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward,
                          color: Colors.white, size: 14),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner({required bool top, required bool left}) {
    return Positioned(
      top: top ? 0 : null,
      bottom: !top ? 0 : null,
      left: left ? 0 : null,
      right: !left ? 0 : null,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? const BorderSide(color: Colors.redAccent, width: 2.0)
                : BorderSide.none,
            bottom: !top
                ? const BorderSide(color: Colors.redAccent, width: 2.0)
                : BorderSide.none,
            left: left
                ? const BorderSide(color: Colors.redAccent, width: 2.0)
                : BorderSide.none,
            right: !left
                ? const BorderSide(color: Colors.redAccent, width: 2.0)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(12) : Radius.zero,
            topRight: top && !left ? const Radius.circular(12) : Radius.zero,
            bottomLeft: !top && left ? const Radius.circular(12) : Radius.zero,
            bottomRight:
            !top && !left ? const Radius.circular(12) : Radius.zero,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  // ============================================================
  // ============== TAB 2: CHECKLIST (Glass) ====================
  // ============================================================
  Widget _buildChecklistTab() {
    final provider = Provider.of<AdminProvider>(context);
    final classes = provider.classes;

    final groupPlayers = _checklistGroupId == null
        ? <PlayerModel>[]
        : provider.getPlayersForGroup(
        _checklistGroupId ?? '', _checklistGroupName ?? '');

    final now = DateTime.now();
    final todayAttendedUids = provider.attendance
        .where((a) =>
    a.timestamp.year == now.year &&
        a.timestamp.month == now.month &&
        a.timestamp.day == now.day)
        .map((a) => a.userId)
        .toSet();

    final markedCount = _checklistMarks.length;
    final presentCount =
        _checklistMarks.values.where((v) => v).length;
    final absentCount =
        _checklistMarks.values.where((v) => !v).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== GROUP SPINNER =====
          _buildGroupSpinner(classes),
          const SizedBox(height: 14),

          if (_checklistGroupId == null)
            _buildSelectGroupHint()
          else ...[
            _buildGroupHeader(
                groupPlayers.length, markedCount, presentCount, absentCount),
            const SizedBox(height: 14),

            if (groupPlayers.isEmpty)
              _buildEmptyPlayers()
            else
              ...groupPlayers.map(
                      (p) => _buildChecklistPlayerTile(p, todayAttendedUids)),

            const SizedBox(height: 18),
            _buildSaveButton(provider, groupPlayers, todayAttendedUids),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ===== ELEGANT GROUP SPINNER (Glass) =====
  Widget _buildGroupSpinner(List<ClassModel> classes) {
    if (classes.isEmpty) {
      return _GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: _orange),
            const SizedBox(width: 10),
            Text(
              'No groups available',
              style: GoogleFonts.inter(fontSize: 12, color: _orange),
            ),
          ],
        ),
      );
    }

    final groupNames = <String>[];
    for (final c in classes) {
      final n = c.className.trim();
      if (n.isNotEmpty && !groupNames.contains(n)) groupNames.add(n);
    }

    final selected =
    _checklistGroupName != null && groupNames.contains(_checklistGroupName)
        ? _checklistGroupName!
        : 'Select a group';

    return PopupMenuButton<String>(
      onSelected: (val) {
        final cls = classes.firstWhere(
              (c) => c.className.trim() == val,
          orElse: () => classes.first,
        );
        setState(() {
          _checklistGroupId = cls.id;
          _checklistGroupName = cls.className;
          _checklistMarks.clear();
        });
      },
      offset: const Offset(0, 62),
      color: const Color(0xFF151515),
      elevation: 20,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _red.withOpacity(0.3), width: 0.8),
      ),
      itemBuilder: (context) {
        return groupNames.map((g) {
          final isCurrent = g == _checklistGroupName;
          return PopupMenuItem<String>(
            value: g,
            height: 40,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent ? _red : Colors.white.withOpacity(0.2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    g.toUpperCase(),
                    style: GoogleFonts.oswald(
                      fontSize: 12,
                      fontWeight:
                      isCurrent ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.8,
                      color: isCurrent
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
                if (isCurrent)
                  Icon(Icons.check_rounded, size: 14, color: _red),
              ],
            ),
          );
        }).toList();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _checklistGroupId != null
                  ? _red.withOpacity(0.1)
                  : _glassBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _checklistGroupId != null
                    ? _red.withOpacity(0.5)
                    : _glassBorder,
                width: 0.8,
              ),
              boxShadow: _checklistGroupId != null
                  ? [
                BoxShadow(
                  color: _red.withOpacity(0.15),
                  blurRadius: 20,
                ),
              ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _red.withOpacity(0.15),
                    border:
                    Border.all(color: _red.withOpacity(0.35), width: 0.5),
                  ),
                  child: Icon(Icons.groups_rounded, size: 14, color: _red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GROUP',
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selected.toUpperCase(),
                        style: GoogleFonts.oswald(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: _checklistGroupId != null
                              ? Colors.white
                              : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: _glassBorder),
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectGroupHint() {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _red.withOpacity(0.1),
              border: Border.all(color: _red.withOpacity(0.3), width: 0.8),
            ),
            child: Icon(
              Icons.touch_app_rounded,
              size: 26,
              color: _red.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a group to start',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mark each player as present or absent',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(
      int total, int marked, int present, int absent) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _red.withOpacity(0.3), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: _red.withOpacity(0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 32,
                decoration: BoxDecoration(
                  color: _red,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(color: _red.withOpacity(0.6), blurRadius: 8),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _checklistGroupName?.toUpperCase() ?? '',
                      style: GoogleFonts.oswald(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$marked of $total marked',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              _statChip(
                icon: Icons.check_circle_rounded,
                label: '$present',
                color: _green,
              ),
              const SizedBox(width: 6),
              _statChip(
                icon: Icons.cancel_rounded,
                label: '$absent',
                color: _orange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.oswald(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlayers() {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: _orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No players assigned to this group',
              style: GoogleFonts.inter(fontSize: 11, color: _orange),
            ),
          ),
        ],
      ),
    );
  }

  // ===== PLAYER TILE (Glass) =====
  Widget _buildChecklistPlayerTile(
      PlayerModel player, Set<String> todayAttendedUids) {
    final alreadyIn = todayAttendedUids.contains(player.uid);
    final mark = _checklistMarks[player.uid];
    final isPresent = mark == true;
    final isAbsent = mark == false;

    // Determine accent color for the tile
    final Color tileAccent;
    if (alreadyIn || isPresent) {
      tileAccent = _green;
    } else if (isAbsent) {
      tileAccent = _orange;
    } else {
      tileAccent = Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: alreadyIn
                  ? _green.withOpacity(0.08)
                  : (isPresent
                  ? _green.withOpacity(0.06)
                  : (isAbsent
                  ? _orange.withOpacity(0.06)
                  : _glassBg)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: alreadyIn
                    ? _green.withOpacity(0.4)
                    : (isPresent
                    ? _green.withOpacity(0.4)
                    : (isAbsent
                    ? _orange.withOpacity(0.4)
                    : _glassBorder)),
                width: alreadyIn || isPresent || isAbsent ? 1 : 0.8,
              ),
              boxShadow: (alreadyIn || isPresent)
                  ? [
                BoxShadow(
                  color: _green.withOpacity(0.12),
                  blurRadius: 12,
                ),
              ]
                  : (isAbsent
                  ? [
                BoxShadow(
                  color: _orange.withOpacity(0.12),
                  blurRadius: 12,
                ),
              ]
                  : null),
            ),
            child: Row(
              children: [
                // Number badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tileAccent == Colors.white
                        ? Colors.white.withOpacity(0.05)
                        : tileAccent.withOpacity(0.15),
                    border: Border.all(
                      color: tileAccent == Colors.white
                          ? Colors.white.withOpacity(0.12)
                          : tileAccent.withOpacity(0.6),
                      width: 1.2,
                    ),
                    boxShadow: tileAccent == Colors.white
                        ? null
                        : [
                      BoxShadow(
                        color: tileAccent.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: player.playerNumber > 0
                        ? Text(
                      '#${player.playerNumber}',
                      style: GoogleFonts.oswald(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tileAccent == Colors.white
                            ? Colors.white70
                            : tileAccent,
                        letterSpacing: 0.3,
                      ),
                    )
                        : Text(
                      player.initials,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.fullName,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${player.sport} · ${player.level}',
                        style: GoogleFonts.inter(
                            fontSize: 9.5, color: Colors.white38),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (alreadyIn)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _green.withOpacity(0.5), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 11, color: _green),
                        const SizedBox(width: 5),
                        Text(
                          'RECORDED',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: _green,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      _markBtn(
                        label: 'PRESENT',
                        icon: Icons.check_rounded,
                        color: _green,
                        selected: isPresent,
                        onTap: () => setState(() {
                          if (isPresent) {
                            _checklistMarks.remove(player.uid);
                          } else {
                            _checklistMarks[player.uid] = true;
                          }
                        }),
                      ),
                      const SizedBox(width: 6),
                      _markBtn(
                        label: 'ABSENT',
                        icon: Icons.close_rounded,
                        color: _orange,
                        selected: isAbsent,
                        onTap: () => setState(() {
                          if (isAbsent) {
                            _checklistMarks.remove(player.uid);
                          } else {
                            _checklistMarks[player.uid] = false;
                          }
                        }),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _markBtn({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? color.withOpacity(0.8)
                : Colors.white.withOpacity(0.1),
            width: selected ? 1 : 0.5,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 10,
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11,
              color: selected ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: selected ? Colors.white : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== SAVE BUTTON =====
  Widget _buildSaveButton(
      AdminProvider provider,
      List<PlayerModel> groupPlayers,
      Set<String> todayAttendedUids,
      ) {
    final saveable = _checklistMarks.entries
        .where((e) => !todayAttendedUids.contains(e.key))
        .toList();

    final disabled = _savingChecklist ||
        saveable.isEmpty ||
        _checklistGroupId == null;

    return GestureDetector(
      onTap: disabled
          ? null
          : () => _saveChecklist(provider, groupPlayers, saveable),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: disabled
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
            color: disabled
                ? Colors.white.withOpacity(0.1)
                : _red.withOpacity(0.5),
            width: 0.5,
          ),
          boxShadow: disabled
              ? null
              : [
            BoxShadow(
              color: _red.withOpacity(0.4),
              blurRadius: 18,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_savingChecklist)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                Icons.save_rounded,
                size: 15,
                color: disabled ? Colors.white38 : Colors.white,
              ),
            const SizedBox(width: 8),
            Text(
              _savingChecklist
                  ? 'SAVING...'
                  : 'SAVE (${saveable.length})',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
                color: disabled ? Colors.white38 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChecklist(
      AdminProvider provider,
      List<PlayerModel> groupPlayers,
      List<MapEntry<String, bool>> saveable,
      ) async {
    setState(() => _savingChecklist = true);
    int presentCount = 0;
    int absentCount = 0;

    try {
      for (final entry in saveable) {
        final uid = entry.key;
        final isPresent = entry.value;
        final player = groupPlayers.firstWhere((p) => p.uid == uid);

        if (isPresent) {
          await provider.recordCheckInWithSessionUpdate(
            userId: uid,
            playerName: player.fullName,
            className: _checklistGroupName ?? 'General',
          );
          presentCount++;
        } else {
          await provider.markPlayerAbsent(
            userId: uid,
            playerName: player.fullName,
            className: _checklistGroupName ?? 'General',
          );
          absentCount++;
        }
      }

      if (!mounted) return;

      setState(() {
        _checklistMarks.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved · $presentCount present · $absentCount absent',
            style: GoogleFonts.inter(fontSize: 11),
          ),
          backgroundColor: _green,
          duration: const Duration(seconds: 3),
        ),
      );
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
      if (mounted) setState(() => _savingChecklist = false);
    }
  }

  // ============================================================
  // ============== QR PROCESS (unchanged) ======================
  // ============================================================
  Future<void> _processQrCode(String qrData, AdminProvider provider) async {
    final parts = qrData.split('|');
    if (parts.length < 2) {
      setState(() {
        _scanResult = 'Invalid QR';
        _isScanning = false;
      });
      _stopScanner();
      return;
    }

    final userId = parts[1].trim();
    dynamic player =
        provider.players.where((p) => p.uid == userId).firstOrNull;
    player ??= provider.players
        .where((p) => p.uid.contains(userId) || userId.contains(p.uid))
        .firstOrNull;
    player ??= provider.players.where((p) => p.email == userId).firstOrNull;

    if (player == null) {
      setState(() {
        _scanResult = 'Player not found!';
        _isScanning = false;
      });
      _stopScanner();
      return;
    }

    final now = DateTime.now();

    final todayCheckIns = provider.attendance.where((a) {
      return a.userId == player.uid &&
          a.timestamp.year == now.year &&
          a.timestamp.month == now.month &&
          a.timestamp.day == now.day;
    }).toList();

    if (todayCheckIns.isNotEmpty) {
      setState(() {
        _scanResult = 'Already checked in today!';
        _isScanning = false;
      });
      _stopScanner();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player.fullName} already checked in today!'),
          backgroundColor: _red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final playerGroup = _findPlayerGroupClass(player, provider);

    if (playerGroup == null) {
      await _performCheckIn(provider, player, null);
      return;
    }

    final timeOk = _isTrainingTime(playerGroup, now);

    if (timeOk) {
      await _performCheckIn(provider, player, playerGroup);
      return;
    }

    _stopScanner();
    setState(() {
      _scanResult = 'Not training time for ${player.fullName}';
      _isScanning = false;
    });

    final proceed = await _showTimeMismatchDialog(
      playerName: player.fullName,
      groupName: playerGroup.className,
      scheduleInfo: _buildScheduleLabel(playerGroup),
      nowInfo: DateFormat('EEE · HH:mm').format(now),
    );

    if (proceed == true && mounted) {
      await _performCheckIn(provider, player, playerGroup);
    }
  }

  Future<void> _performCheckIn(
      AdminProvider provider,
      dynamic player,
      dynamic group,
      ) async {
    final now = DateTime.now();
    final className = group?.className ??
        (provider.classes
            .where((c) =>
        c.startTime.year == now.year &&
            c.startTime.month == now.month &&
            c.startTime.day == now.day)
            .firstOrNull
            ?.className ??
            'General Session');

    await provider.recordCheckInWithSessionUpdate(
      userId: player.uid,
      playerName: player.fullName,
      className: className,
    );

    if (mounted) {
      setState(() {
        _scanResult = '+ ${player.fullName} checked in';
        _isScanning = false;
      });
      _stopScanner();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+ ${player.fullName} checked in successfully'),
          backgroundColor: _green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  dynamic _findPlayerGroupClass(dynamic player, AdminProvider provider) {
    final membership = provider.memberships.firstWhere(
          (m) =>
      m['userId'] == player.uid &&
          (m['isActive'] == true || m['isActive'] == null),
      orElse: () => <String, dynamic>{},
    );

    final groupId = membership['groupId']?.toString() ?? '';
    final groupName = membership['groupName']?.toString() ?? '';

    if (groupId.isEmpty && groupName.isEmpty) return null;

    for (final c in provider.classes) {
      if (groupId.isNotEmpty && c.id == groupId) return c;
      if (groupName.isNotEmpty && c.className == groupName) return c;
    }
    return null;
  }

  bool _isTrainingTime(dynamic classModel, DateTime now) {
    final dayShort = DateFormat('EEE').format(now);
    final dayLong = DateFormat('EEEE').format(now);

    final List<String> scheduleDays =
    (classModel.scheduleDays as List).cast<String>();
    if (scheduleDays.isEmpty) return true;

    final dayMatches = scheduleDays.any((d) {
      final u = d.toUpperCase();
      return u == dayShort.toUpperCase() ||
          u == dayLong.toUpperCase() ||
          u.startsWith(dayShort.toUpperCase());
    });
    if (!dayMatches) return false;

    int hh = classModel.startTime.hour;
    int mm = classModel.startTime.minute;

    final timeStr = (classModel.timeStr as String?) ?? '';
    if (timeStr.isNotEmpty && timeStr.contains(':')) {
      final tp = timeStr.split(':');
      hh = int.tryParse(tp[0]) ?? hh;
      mm = int.tryParse(tp[1]) ?? mm;
    }

    final classTime = DateTime(now.year, now.month, now.day, hh, mm);
    final diff = now.difference(classTime).inMinutes.abs();
    return diff <= 30;
  }

  String _buildScheduleLabel(dynamic classModel) {
    final days = (classModel.scheduleDays as List).cast<String>();
    final time = (classModel.timeStr as String?) ?? '';
    final dayPart = days.isEmpty ? 'Daily' : days.join(', ');
    return time.isEmpty ? dayPart : '$dayPart · $time';
  }

  Future<bool?> _showTimeMismatchDialog({
    required String playerName,
    required String groupName,
    required String scheduleInfo,
    required String nowInfo,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _dark.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _orange.withOpacity(0.45), width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: _orange.withOpacity(0.2),
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
                        color: _orange.withOpacity(0.12),
                        border: Border.all(
                            color: _orange.withOpacity(0.4), width: 1),
                      ),
                      child: const Icon(Icons.warning_amber_rounded,
                          color: _orange, size: 26),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'NOT TRAINING TIME',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: _orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      playerName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Column(
                        children: [
                          if (groupName.isNotEmpty)
                            _infoRow('Group', groupName),
                          if (scheduleInfo.isNotEmpty)
                            _infoRow('Schedule', scheduleInfo),
                          _infoRow('Current', nowInfo),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This player is outside their scheduled training time. Do you want to record attendance anyway?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: Colors.white54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                Navigator.pop(dialogContext, false),
                            child: Container(
                              padding:
                              const EdgeInsets.symmetric(vertical: 12),
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
                            onTap: () => Navigator.pop(dialogContext, true),
                            child: Container(
                              padding:
                              const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _red.withOpacity(0.95),
                                    _red.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: _red.withOpacity(0.3),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'CHECK-IN ANYWAY',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                  color: Colors.white,
                                ),
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
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: Colors.white38,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
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
    );
  }
}

// ============================================================
// ============ GLASS CARD WIDGET =============================
// ============================================================
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double? height;
  final Color? glowColor;

  const _GlassCard({
    required this.child,
    required this.padding,
    this.height,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF0F1115).withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 0.8,
            ),
            boxShadow: glowColor != null
                ? [
              BoxShadow(
                color: glowColor!.withOpacity(0.15),
                blurRadius: 24,
              ),
            ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
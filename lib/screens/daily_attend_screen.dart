import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/branch_model.dart';
import '../models/class_model.dart';
import '../models/coach_model.dart';
import '../models/player_model.dart';
import '../providers/admin_provider.dart';
import '../services/cloudinary_service.dart';

class DailyAttendScreen extends StatefulWidget {
  const DailyAttendScreen({super.key});

  @override
  State<DailyAttendScreen> createState() => _DailyAttendScreenState();
}

class _DailyAttendScreenState extends State<DailyAttendScreen> {
  int _activeTab = 0; // 0=Combo, 1=Attendance, 2=History

  static const Color _red = Color(0xFFE50914);
  static const Color _dark = Color(0xFF0F1115);
  static const Color _dark2 = Color(0xFF151515);
  static const Color _green = Color(0xFF00C853);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/players_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.55),
        child: SafeArea(
          child: Column(
            children: [
              // ===== HEADER =====
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _red.withOpacity(0.12),
                        border: Border.all(
                            color: _red.withOpacity(0.4), width: 0.8),
                      ),
                      child: Icon(Icons.bolt_rounded, size: 16, color: _red),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAILY TRAINING',
                          style: GoogleFonts.oswald(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.3,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE · dd MMM yyyy')
                              .format(DateTime.now()),
                          style: GoogleFonts.inter(
                              fontSize: 9.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ===== SEGMENTED TABS =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSegmentedTabs(),
              ),
              const SizedBox(height: 12),

              // ===== CONTENT =====
              Expanded(
                child: IndexedStack(
                  index: _activeTab,
                  children: const [
                    _ComboTab(),
                    _AttendanceTab(),
                    _HistoryTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    final tabs = [
      {'label': 'COMBO', 'icon': Icons.sports_martial_arts_rounded},
      {'label': 'ATTENDANCE', 'icon': Icons.groups_rounded},
      {'label': 'HISTORY', 'icon': Icons.history_rounded},
    ];

    return Row(
      children: List.generate(tabs.length, (i) {
        final selected = _activeTab == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _activeTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                  colors: [
                    _red.withOpacity(0.9),
                    _red.withOpacity(0.6),
                  ],
                )
                    : null,
                color: selected ? null : _dark.withOpacity(0.5),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: selected
                      ? _red.withOpacity(0.6)
                      : Colors.white.withOpacity(0.06),
                  width: 0.5,
                ),
                boxShadow: selected
                    ? [
                  BoxShadow(
                    color: _red.withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(tabs[i]['icon'] as IconData,
                      size: 13,
                      color: selected ? Colors.white : Colors.white54),
                  const SizedBox(width: 6),
                  Text(
                    tabs[i]['label'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight:
                      selected ? FontWeight.w800 : FontWeight.w500,
                      letterSpacing: 0.8,
                      color: selected ? Colors.white : Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ============================================================
// ================== TAB 1: COMBO ============================
// ============================================================
class _ComboTab extends StatefulWidget {
  const _ComboTab();

  @override
  State<_ComboTab> createState() => _ComboTabState();
}

class _ComboTabState extends State<_ComboTab> {
  final TextEditingController _ctrl = TextEditingController();
  final List<String> _selectedChips = [];
  String? _branchId;
  String? _branchName;
  bool _saving = false;

  static const Color _red = Color(0xFFE50914);
  static const Color _dark = Color(0xFF0F1115);
  static const Color _green = Color(0xFF00C853);

  static const List<String> _quickMoves = [
    'Jab', 'Cross', 'Hook', 'Uppercut',
    'Low Kick', 'High Kick', 'Body Kick', 'Front Kick',
    'Elbow', 'Knee', 'Clinch', 'Takedown',
    'Sweep', 'Guard Pass', 'Mount', 'Rear Naked',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _todayKey =>
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  String get _comboPreview {
    final text = _ctrl.text.trim();
    if (text.isNotEmpty) return text;
    return _selectedChips.join(' → ');
  }

  void _toggleChip(String move) {
    setState(() {
      if (_selectedChips.contains(move)) {
        _selectedChips.remove(move);
      } else {
        _selectedChips.add(move);
      }
      _syncToController();
    });
  }

  void _syncToController() {
    if (_selectedChips.isEmpty) return;
    _ctrl.text = _selectedChips.join(' → ');
    _ctrl.selection =
        TextSelection.collapsed(offset: _ctrl.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final branches = provider.branches.where((b) => b.isActive).toList();

    _branchId ??= branches.isNotEmpty ? branches.first.id : null;
    _branchName ??= branches.isNotEmpty ? branches.first.name : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Today's Combo Input Card =====
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: _dark.withOpacity(0.7),
              border: Border.all(color: _red.withOpacity(0.25), width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: _red.withOpacity(0.08),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _red.withOpacity(0.35), width: 0.5),
                      ),
                      child: Icon(Icons.sports_martial_arts_rounded,
                          size: 12, color: _red),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "TODAY'S COMBO",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: _red,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _todayKey,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Text field
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    maxLines: 3,
                    minLines: 2,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText:
                      'Type today\'s combo... e.g. cross hook low kick cross',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white30,
                        height: 1.5,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 10),

                // Preview
                if (_comboPreview.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [
                          _red.withOpacity(0.1),
                          _red.withOpacity(0.03),
                        ],
                      ),
                      border:
                      Border.all(color: _red.withOpacity(0.25), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 12, color: _red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _comboPreview.toUpperCase(),
                            style: GoogleFonts.oswald(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ===== Quick Moves =====
          Row(
            children: [
              Container(width: 12, height: 1.5, color: _red),
              const SizedBox(width: 8),
              Text(
                'QUICK MOVES',
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickMoves.map((m) {
              final selected = _selectedChips.contains(m);
              return GestureDetector(
                onTap: () => _toggleChip(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? _red.withOpacity(0.15)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? _red.withOpacity(0.6)
                          : Colors.white.withOpacity(0.08),
                      width: selected ? 1 : 0.5,
                    ),
                    boxShadow: selected
                        ? [
                      BoxShadow(
                        color: _red.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ]
                        : null,
                  ),
                  child: Text(
                    m,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : Colors.white60,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ===== Branch Selector =====
          Row(
            children: [
              Container(width: 12, height: 1.5, color: _red),
              const SizedBox(width: 8),
              Text(
                'BRANCH',
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (branches.isEmpty)
            _emptyBranchBox()
          else
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: branches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final b = branches[i];
                  final selected = b.id == _branchId;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _branchId = b.id;
                      _branchName = b.name;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? LinearGradient(
                          colors: [
                            _red.withOpacity(0.18),
                            _red.withOpacity(0.05),
                          ],
                        )
                            : null,
                        color: selected
                            ? null
                            : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? _red.withOpacity(0.7)
                              : Colors.white.withOpacity(0.08),
                          width: selected ? 1 : 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 11,
                            color: selected ? _red : Colors.white54,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            b.name,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
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
          const SizedBox(height: 18),

          // ===== Save Button =====
          _buildSaveButton(provider),
          const SizedBox(height: 20),

          // ===== Today's Combos (list) =====
          _buildTodayCombos(provider),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _emptyBranchBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            'No branches. Add a branch first.',
            style: GoogleFonts.inter(fontSize: 10.5, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AdminProvider provider) {
    final disabled = _saving ||
        _comboPreview.isEmpty ||
        _branchId == null ||
        _branchName == null;

    return GestureDetector(
      onTap: disabled ? null : () => _save(provider),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
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
              color: _red.withOpacity(0.35),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_saving)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: Colors.white,
                ),
              )
            else
              Icon(Icons.save_rounded,
                  size: 15,
                  color: disabled ? Colors.white38 : Colors.white),
            const SizedBox(width: 8),
            Text(
              _saving ? 'SAVING...' : 'SAVE COMBO',
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

  Future<void> _save(AdminProvider provider) async {
    setState(() => _saving = true);
    try {
      await provider.recordDailyCombo(
        combo: _comboPreview,
        branchId: _branchId!,
        branchName: _branchName!,
        dateKey: _todayKey,
      );
      if (mounted) {
        setState(() {
          _ctrl.clear();
          _selectedChips.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Combo saved',
                style: GoogleFonts.inter(fontSize: 11)),
            backgroundColor: _green,
            duration: const Duration(seconds: 2),
          ),
        );
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
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildTodayCombos(AdminProvider provider) {
    final todayCombos = provider.dailyCombos
        .where((c) => c['date'] == _todayKey)
        .toList();

    if (todayCombos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 12, height: 1.5, color: _red),
            const SizedBox(width: 8),
            Text(
              "TODAY'S COMBOS (${todayCombos.length})",
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...todayCombos.map((c) => _buildComboCard(c)),
      ],
    );
  }

  Widget _buildComboCard(Map<String, dynamic> combo) {
    final coachName = combo['coachName']?.toString() ?? '';
    final comboText = combo['combo']?.toString() ?? '';
    final branchName = combo['branchName']?.toString() ?? '';
    final dt = DateTime.tryParse(combo['createdAt']?.toString() ?? '');
    final timeLabel =
    dt != null ? DateFormat('HH:mm').format(dt) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _dark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _red.withOpacity(0.12),
                  border:
                  Border.all(color: _red.withOpacity(0.3), width: 0.5),
                ),
                child: Center(
                  child: Text(
                    _initials(coachName),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _red,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  coachName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                timeLabel,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _red.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _red.withOpacity(0.2), width: 0.5),
            ),
            child: Text(
              comboText,
              style: GoogleFonts.oswald(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
          if (branchName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_rounded,
                    size: 9, color: Colors.white38),
                const SizedBox(width: 4),
                Text(
                  branchName,
                  style: GoogleFonts.inter(
                      fontSize: 9.5, color: Colors.white38),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '??';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

// ============================================================
// ================== TAB 2: ATTENDANCE =======================
// ============================================================
class _AttendanceTab extends StatefulWidget {
  const _AttendanceTab();

  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  String? _groupId;
  String? _groupName;
  String? _branchId;
  String? _branchName;
  final Set<String> _selectedPlayerUids = {};
  final List<String> _photoUrls = [];
  final List<File> _localPhotos = [];
  final TextEditingController _notesCtrl = TextEditingController();
  bool _uploading = false;
  bool _saving = false;

  static const Color _red = Color(0xFFE50914);
  static const Color _dark = Color(0xFF0F1115);
  static const Color _green = Color(0xFF00C853);

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final classes = provider.classes;

    // Group list = classes
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Group Selector (iOS style) =====
          _buildGroupSelector(classes),
          const SizedBox(height: 16),

          // If group selected → show content
          if (_groupId == null)
            _buildSelectGroupHint()
          else ...[
            // Selected group header
            _buildSelectedGroupHeader(provider),
            const SizedBox(height: 16),

            // Photos
            _buildPhotoSection(),
            const SizedBox(height: 16),

            // Players list
            _buildPlayersList(provider),
            const SizedBox(height: 14),

            // Notes
            _buildNotesField(),
            const SizedBox(height: 16),

            // Save button
            _buildSaveButton(provider),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ===== iOS-style Group Selector (bottom sheet with CupertinoPicker) =====
  Widget _buildGroupSelector(List<ClassModel> classes) {
    final selected =
    _groupId != null ? _groupName ?? '—' : 'Select a group';

    return GestureDetector(
      onTap: classes.isEmpty ? null : () => _openGroupPicker(classes),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: _groupId != null
              ? LinearGradient(
            colors: [
              _red.withOpacity(0.15),
              _red.withOpacity(0.04),
            ],
          )
              : null,
          color: _groupId == null ? _dark.withOpacity(0.6) : null,
          border: Border.all(
            color: _groupId != null
                ? _red.withOpacity(0.6)
                : Colors.white.withOpacity(0.08),
            width: 0.8,
          ),
          boxShadow: _groupId != null
              ? [
            BoxShadow(
              color: _red.withOpacity(0.15),
              blurRadius: 16,
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
                color: _red.withOpacity(0.12),
                border:
                Border.all(color: _red.withOpacity(0.3), width: 0.5),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: _groupId != null ? Colors.white : Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            if (_groupId != null)
              GestureDetector(
                onTap: () => setState(() {
                  _groupId = null;
                  _groupName = null;
                  _selectedPlayerUids.clear();
                }),
                child: Icon(Icons.close_rounded,
                    size: 16, color: Colors.white38),
              )
            else
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  void _openGroupPicker(List<ClassModel> classes) {
    int tempIndex = classes.indexWhere((c) => c.id == _groupId);
    if (tempIndex < 0) tempIndex = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          height: 340,
          decoration: BoxDecoration(
            color: _dark,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: _red.withOpacity(0.3), width: 0.8),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'SELECT GROUP',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: _red,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'DONE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // iOS-style picker
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 44,
                  scrollController:
                  FixedExtentScrollController(initialItem: tempIndex),
                  selectionOverlay: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                            color: _red.withOpacity(0.4), width: 0.8),
                        bottom: BorderSide(
                            color: _red.withOpacity(0.4), width: 0.8),
                      ),
                    ),
                  ),
                  onSelectedItemChanged: (i) {
                    tempIndex = i;
                  },
                  children: classes.map((c) {
                    final isSelected = c.id == _groupId;
                    return Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_martial_arts_rounded,
                            size: 12,
                            color:
                            isSelected ? _red : Colors.white38,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            c.className.toUpperCase(),
                            style: GoogleFonts.oswald(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Confirm
              Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 14,
                  top: 6,
                ),
                child: GestureDetector(
                  onTap: () {
                    final sel = classes[tempIndex];
                    setState(() {
                      _groupId = sel.id;
                      _groupName = sel.className;
                      _branchId = sel.branchId;
                      _branchName = sel.branch;
                      _selectedPlayerUids.clear();
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _red.withOpacity(0.95),
                          _red.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _red.withOpacity(0.3),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'CONFIRM',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectGroupHint() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: _dark.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.touch_app_rounded,
              size: 32, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 12),
          Text(
            'Select a group to start',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose the training group you taught today',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedGroupHeader(AdminProvider provider) {
    final players =
    provider.getPlayersForGroup(_groupId ?? '', _groupName ?? '');
    final branchName = _branchName ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _red.withOpacity(0.25), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _groupName?.toUpperCase() ?? '',
                  style: GoogleFonts.oswald(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
                if (branchName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 9, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(
                        branchName,
                        style: GoogleFonts.inter(
                            fontSize: 9.5, color: Colors.white38),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_selectedPlayerUids.length}/${players.length}',
                style: GoogleFonts.oswald(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: _red,
                  height: 1,
                ),
              ),
              Text(
                'selected',
                style: GoogleFonts.inter(
                    fontSize: 8.5, color: Colors.white38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== Photos =====
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 12, height: 1.5, color: _red),
            const SizedBox(width: 8),
            Text(
              'PHOTOS (${_photoUrls.length})',
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
                color: Colors.white70,
              ),
            ),
            const Spacer(),
            Text(
              'optional',
              style: GoogleFonts.inter(
                fontSize: 9,
                color: Colors.white30,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 84,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add button
              GestureDetector(
                onTap: _uploading ? null : _pickAndUpload,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.03),
                    border: Border.all(
                        color: _red.withOpacity(0.35), width: 0.8),
                  ),
                  child: _uploading
                      ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFE50914),
                      ),
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_rounded,
                          size: 18, color: _red),
                      const SizedBox(height: 4),
                      Text(
                        'ADD',
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: _red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Photo thumbs
              ...List.generate(_photoUrls.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 0.5),
                          image: DecorationImage(
                            image: NetworkImage(_photoUrls[i]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _photoUrls.removeAt(i);
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.7),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 0.5),
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 10, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 12),
        decoration: const BoxDecoration(
          color: _dark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _sheetBtn(Icons.camera_alt_rounded, 'Take Photo',
                    () => Navigator.pop(context, ImageSource.camera)),
            _sheetBtn(Icons.photo_library_rounded, 'Choose from Gallery',
                    () => Navigator.pop(context, ImageSource.gallery)),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return;

    setState(() {
      _uploading = true;
      _localPhotos.add(File(picked.path));
    });

    final url = await CloudinaryService.uploadImage(File(picked.path));

    if (!mounted) return;
    setState(() {
      _uploading = false;
      if (url != null) {
        _photoUrls.add(url);
      } else {
        _localPhotos.removeLast();
      }
    });

    if (url == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed. Check your connection.',
              style: GoogleFonts.inter(fontSize: 11)),
          backgroundColor: _red,
        ),
      );
    }
  }

  Widget _sheetBtn(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: _red, size: 18),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  // ===== Players list =====
  Widget _buildPlayersList(AdminProvider provider) {
    final players =
    provider.getPlayersForGroup(_groupId ?? '', _groupName ?? '');

    if (players.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 14, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No players assigned to this group yet.',
                style:
                GoogleFonts.inter(fontSize: 10.5, color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 12, height: 1.5, color: _red),
            const SizedBox(width: 8),
            Text(
              'PLAYERS (${players.length})',
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
                color: Colors.white70,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() {
                if (_selectedPlayerUids.length == players.length) {
                  _selectedPlayerUids.clear();
                } else {
                  _selectedPlayerUids.clear();
                  _selectedPlayerUids.addAll(players.map((p) => p.uid));
                }
              }),
              child: Text(
                _selectedPlayerUids.length == players.length
                    ? 'CLEAR ALL'
                    : 'SELECT ALL',
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: _red,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...players.map((p) => _buildPlayerTile(p)),
      ],
    );
  }

  Widget _buildPlayerTile(PlayerModel player) {
    final selected = _selectedPlayerUids.contains(player.uid);
    final number = player.playerNumber;

    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _selectedPlayerUids.remove(player.uid);
        } else {
          _selectedPlayerUids.add(player.uid);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? _red.withOpacity(0.1)
              : _dark.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? _red.withOpacity(0.6)
                : Colors.white.withOpacity(0.05),
            width: selected ? 1 : 0.5,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: _red.withOpacity(0.15),
              blurRadius: 10,
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            // Number badge (büyük, kırmızı glow'lu)
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? _red.withOpacity(0.15)
                    : Colors.white.withOpacity(0.03),
                border: Border.all(
                  color: selected
                      ? _red.withOpacity(0.7)
                      : Colors.white.withOpacity(0.1),
                  width: selected ? 1.2 : 0.5,
                ),
                boxShadow: selected
                    ? [
                  BoxShadow(
                    color: _red.withOpacity(0.25),
                    blurRadius: 10,
                  ),
                ]
                    : null,
              ),
              child: Center(
                child: number > 0
                    ? Text(
                  '#$number',
                  style: GoogleFonts.oswald(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: selected ? Colors.white : Colors.white70,
                  ),
                )
                    : Text(
                  player.initials,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : Colors.white70,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${player.sport} · ${player.level}',
                    style: GoogleFonts.inter(
                        fontSize: 9.5, color: Colors.white38),
                  ),
                ],
              ),
            ),
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _red : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? _red
                      : Colors.white.withOpacity(0.2),
                  width: selected ? 0 : 1,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                  size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 12, height: 1.5, color: _red),
            const SizedBox(width: 8),
            Text(
              'NOTES',
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
                color: Colors.white70,
              ),
            ),
            const Spacer(),
            Text(
              'optional',
              style: GoogleFonts.inter(
                fontSize: 9,
                color: Colors.white30,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: _dark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: _notesCtrl,
            maxLines: 2,
            minLines: 1,
            style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Anything to note about today\'s session...',
              hintStyle:
              GoogleFonts.inter(fontSize: 11, color: Colors.white30),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(AdminProvider provider) {
    final disabled = _saving ||
        _selectedPlayerUids.isEmpty ||
        _groupId == null ||
        _uploading;

    return GestureDetector(
      onTap: disabled ? null : () => _save(provider),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
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
              color: _red.withOpacity(0.35),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_saving)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: Colors.white,
                ),
              )
            else
              Icon(Icons.check_circle_rounded,
                  size: 15,
                  color: disabled ? Colors.white38 : Colors.white),
            const SizedBox(width: 8),
            Text(
              _saving
                  ? 'SAVING...'
                  : 'FINISH ATTENDANCE (${_selectedPlayerUids.length})',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: disabled ? Colors.white38 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(AdminProvider provider) async {
    setState(() => _saving = true);
    try {
      final players =
      provider.getPlayersForGroup(_groupId ?? '', _groupName ?? '');
      final selected = players
          .where((p) => _selectedPlayerUids.contains(p.uid))
          .toList();

      await provider.recordDailyAttendance(
        groupId: _groupId ?? '',
        groupName: _groupName ?? '',
        branchId: _branchId ?? '',
        branchName: _branchName ?? '',
        playerUids: selected.map((p) => p.uid).toList(),
        playerNames: selected.map((p) => p.fullName).toList(),
        playerNumbers: selected.map((p) => p.playerNumber).toList(),
        photoUrls: _photoUrls,
        notes: _notesCtrl.text.trim(),
        dateKey: _todayKey,
      );

      if (!mounted) return;
      setState(() {
        _selectedPlayerUids.clear();
        _photoUrls.clear();
        _localPhotos.clear();
        _notesCtrl.clear();
        _groupId = null;
        _groupName = null;
        _branchId = null;
        _branchName = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance saved',
              style: GoogleFonts.inter(fontSize: 11)),
          backgroundColor: _green,
          duration: const Duration(seconds: 2),
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
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ============================================================
// ================== TAB 3: HISTORY ==========================
// ============================================================
class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  static const Color _red = Color(0xFFE50914);
  static const Color _dark = Color(0xFF0F1115);
  static const Color _green = Color(0xFF00C853);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final coaches = provider.coaches;

    if (coaches.isEmpty) {
      return Center(
        child: Text(
          'No coaches yet',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: coaches.length,
      itemBuilder: (context, i) {
        final coach = coaches[i];
        final comboCount = provider.dailyCombos
            .where((c) => c['coachUid'] == coach.uid)
            .length;
        final attendCount = provider.dailyAttendances
            .where((a) => a['coachUid'] == coach.uid)
            .length;

        return GestureDetector(
          onTap: () => _openCoachHistory(coach),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _dark.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _red.withOpacity(0.12),
                    border:
                    Border.all(color: _red.withOpacity(0.4), width: 0.8),
                  ),
                  child: Center(
                    child: Text(
                      coach.initials,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _red,
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
                        coach.fullName,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        coach.role.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _miniStat(Icons.sports_martial_arts_rounded,
                              '$comboCount combos'),
                          const SizedBox(width: 10),
                          _miniStat(
                              Icons.groups_rounded, '$attendCount sessions'),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: Colors.white38),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _miniStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: _red),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  void _openCoachHistory(CoachModel coach) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CoachHistoryScreen(coach: coach),
      ),
    );
  }
}

// ============================================================
// =========== COACH HISTORY SCREEN (with date range) =========
// ============================================================
class _CoachHistoryScreen extends StatefulWidget {
  final CoachModel coach;
  const _CoachHistoryScreen({required this.coach});

  @override
  State<_CoachHistoryScreen> createState() => _CoachHistoryScreenState();
}

class _CoachHistoryScreenState extends State<_CoachHistoryScreen> {
  static const Color _red = Color(0xFFE50914);
  static const Color _dark = Color(0xFF0F1115);
  static const Color _green = Color(0xFF00C853);

  DateTimeRange? _range;
  String _preset = 'Last7'; // Today / Last7 / Last30 / Custom / All

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final coach = widget.coach;

    final combos = provider.dailyCombos
        .where((c) => c['coachUid'] == coach.uid)
        .toList();
    final attends = provider.dailyAttendances
        .where((a) => a['coachUid'] == coach.uid)
        .toList();

    final filteredCombos = _filterByDate(combos);
    final filteredAttends = _filterByDate(attends);

    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/players_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.65),
          child: SafeArea(
            child: Column(
              children: [
                // ===== HEADER =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: Colors.white),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _red.withOpacity(0.12),
                          border: Border.all(
                              color: _red.withOpacity(0.4), width: 0.8),
                        ),
                        child: Center(
                          child: Text(
                            coach.initials,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _red,
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
                              coach.fullName,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              coach.role.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: _red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== DATE FILTER CHIPS =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _dateChip('Today', 'Today'),
                        const SizedBox(width: 8),
                        _dateChip('Last 7 days', 'Last7'),
                        const SizedBox(width: 8),
                        _dateChip('Last 30 days', 'Last30'),
                        const SizedBox(width: 8),
                        _customRangeChip(),
                        const SizedBox(width: 8),
                        _dateChip('All time', 'All'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ===== CONTENT =====
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats row
                        Row(
                          children: [
                            Expanded(
                              child: _statBox(
                                icon: Icons.sports_martial_arts_rounded,
                                value: '${filteredCombos.length}',
                                label: 'Combos',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _statBox(
                                icon: Icons.groups_rounded,
                                value: '${filteredAttends.length}',
                                label: 'Sessions',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _statBox(
                                icon: Icons.people_alt_rounded,
                                value:
                                '${filteredAttends.fold<int>(0, (sum, a) => sum + ((a['playerCount'] as num?)?.toInt() ?? 0))}',
                                label: 'Players',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Combos
                        _sectionTitle('RECENT COMBOS (${filteredCombos.length})'),
                        const SizedBox(height: 8),
                        if (filteredCombos.isEmpty)
                          _emptyBox('No combos in this range')
                        else
                          ...filteredCombos.map((c) => _comboCard(c)),
                        const SizedBox(height: 20),

                        // Attendances
                        _sectionTitle(
                            'ATTENDANCE SESSIONS (${filteredAttends.length})'),
                        const SizedBox(height: 8),
                        if (filteredAttends.isEmpty)
                          _emptyBox('No attendance in this range')
                        else
                          ...filteredAttends.map((a) => _attendanceCard(a)),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== Filter =====
  List<Map<String, dynamic>> _filterByDate(
      List<Map<String, dynamic>> list) {
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);

    switch (_preset) {
      case 'Today':
        return list.where((e) => e['date'] == todayKey).toList();
      case 'Last7':
        final from = now.subtract(const Duration(days: 7));
        return list.where((e) {
          final d = DateTime.tryParse(e['date']?.toString() ?? '');
          return d != null && !d.isBefore(from);
        }).toList();
      case 'Last30':
        final from = now.subtract(const Duration(days: 30));
        return list.where((e) {
          final d = DateTime.tryParse(e['date']?.toString() ?? '');
          return d != null && !d.isBefore(from);
        }).toList();
      case 'Custom':
        if (_range == null) return list;
        return list.where((e) {
          final d = DateTime.tryParse(e['date']?.toString() ?? '');
          if (d == null) return false;
          return !d.isBefore(_range!.start) &&
              !d.isAfter(_range!.end.add(const Duration(days: 1)));
        }).toList();
      default:
        return list;
    }
  }

  Widget _dateChip(String label, String value) {
    final selected = _preset == value;
    return GestureDetector(
      onTap: () => setState(() {
        _preset = value;
        _range = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
            colors: [
              _red.withOpacity(0.85),
              _red.withOpacity(0.55),
            ],
          )
              : null,
          color: selected ? null : _dark.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? _red.withOpacity(0.6)
                : Colors.white.withOpacity(0.08),
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _customRangeChip() {
    final selected = _preset == 'Custom';
    final label = selected && _range != null
        ? '${DateFormat('dd MMM').format(_range!.start)} – ${DateFormat('dd MMM').format(_range!.end)}'
        : 'Custom';

    return GestureDetector(
      onTap: _pickRange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
            colors: [
              _red.withOpacity(0.85),
              _red.withOpacity(0.55),
            ],
          )
              : null,
          color: selected ? null : _dark.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? _red.withOpacity(0.6)
                : Colors.white.withOpacity(0.08),
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded,
                size: 11,
                color: selected ? Colors.white : Colors.white60),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _range ??
          DateTimeRange(
              start: now.subtract(const Duration(days: 7)), end: now),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _red,
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
    if (picked != null && mounted) {
      setState(() {
        _range = picked;
        _preset = 'Custom';
      });
    }
  }

  Widget _statBox({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: _dark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: _red),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.oswald(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                    fontSize: 8.5, color: Colors.white38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(width: 12, height: 1.5, color: _red),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: _dark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white38),
        ),
      ),
    );
  }

  // ===== Combo card =====
  Widget _comboCard(Map<String, dynamic> combo) {
    final comboText = combo['combo']?.toString() ?? '';
    final branchName = combo['branchName']?.toString() ?? '';
    final dt = DateTime.tryParse(combo['createdAt']?.toString() ?? '');
    final dateStr = dt != null ? DateFormat('dd MMM').format(dt) : '';
    final timeStr = dt != null ? DateFormat('HH:mm').format(dt) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _dark.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 11, color: _red),
              const SizedBox(width: 6),
              Text(
                '$dateStr · $timeStr',
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white38,
                ),
              ),
              const Spacer(),
              if (branchName.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 9, color: Colors.white38),
                    const SizedBox(width: 3),
                    Text(
                      branchName,
                      style: GoogleFonts.inter(
                          fontSize: 9, color: Colors.white38),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _red.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border:
              Border.all(color: _red.withOpacity(0.2), width: 0.5),
            ),
            child: Text(
              comboText,
              style: GoogleFonts.oswald(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Attendance card (with photos) =====
  Widget _attendanceCard(Map<String, dynamic> attend) {
    final groupName = attend['groupName']?.toString() ?? '';
    final branchName = attend['branchName']?.toString() ?? '';
    final notes = attend['notes']?.toString() ?? '';
    final dt = DateTime.tryParse(attend['createdAt']?.toString() ?? '');
    final dateStr = dt != null ? DateFormat('dd MMM').format(dt) : '';
    final timeStr = dt != null ? DateFormat('HH:mm').format(dt) : '';

    final playerNames = (attend['playerNames'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        [];
    final playerNumbers = (attend['playerNumbers'] as List?)
        ?.map((e) => (e as num?)?.toInt() ?? 0)
        .toList() ??
        [];
    final photoUrls = (attend['photoUrls'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        [];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _dark.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: _green.withOpacity(0.3), width: 0.5),
                ),
                child: Icon(Icons.groups_rounded,
                    size: 11, color: _green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName.toUpperCase(),
                      style: GoogleFonts.oswald(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$dateStr · $timeStr',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              if (branchName.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 9, color: Colors.white38),
                    const SizedBox(width: 3),
                    Text(
                      branchName,
                      style: GoogleFonts.inter(
                          fontSize: 9, color: Colors.white38),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Players + numbers
          Text(
            'PLAYERS (${playerNames.length})',
            style: GoogleFonts.inter(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(playerNames.length, (i) {
              final name = playerNames[i];
              final num = i < playerNumbers.length ? playerNumbers[i] : 0;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _red.withOpacity(0.25), width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (num > 0) ...[
                      Text(
                        '#$num',
                        style: GoogleFonts.oswald(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: _red,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 1,
                        height: 10,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          // Notes
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(8),
                border:
                Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Text(
                notes,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: Colors.white70,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          // Photos
          if (photoUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'PHOTOS (${photoUrls.length})',
              style: GoogleFonts.inter(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  return GestureDetector(
                    onTap: () => _showPhotoFullscreen(photoUrls[i]),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 0.5),
                        image: DecorationImage(
                          image: NetworkImage(photoUrls[i]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPhotoFullscreen(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 0.5),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
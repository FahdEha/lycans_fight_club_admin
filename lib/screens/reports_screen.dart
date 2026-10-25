import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:google_fonts/google_fonts.dart';

import '../models/branch_model.dart';
import '../models/class_model.dart';
import '../models/invoice_model.dart';
import '../models/package_model.dart';
import '../models/player_model.dart';
import '../providers/admin_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _dateFilterMode = 'All';
  late DateTime _scrollerBaseDate;
  late PageController _pageController;

  // ===== Branch + Group filtreleri =====
  String? _selectedBranchId;
  String? _selectedBranchName;
  String? _selectedGroupName;

  static const String _empty = '—';

  static const Color primaryRed = Color(0xFFE52020);
  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFFA0A0A0);
  static const Color textDarkGrey = Color(0xFF505050);

  @override
  void initState() {
    super.initState();
    _alignScrollerToWeek(DateTime.now());
    _pageController = PageController(initialPage: 1000);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _alignScrollerToWeek(DateTime date) {
    int weekday = date.weekday;
    _scrollerBaseDate = date.subtract(Duration(days: weekday - 1));
  }

  void _changeScrollerWeek(int weeksToAdd) {
    if (weeksToAdd > 0) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: darkBg,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/reports_bg.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateFilterSection(),
                      const SizedBox(height: 12),
                      _buildBranchGroupFilters(provider),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 9,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildReportCard(context, provider, index),
                          );
                        },
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ============ BRANCH + GROUP FİLTRELERİ ====================
  // ============================================================
  Widget _buildBranchGroupFilters(AdminProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildElegantPill(
            icon: Icons.location_on_outlined,
            label: _selectedBranchName ?? 'All Branches',
            hasValue: _selectedBranchId != null,
            onTap: () => _showBranchPicker(provider),
            onClear: _selectedBranchId != null
                ? () => setState(() {
              _selectedBranchId = null;
              _selectedBranchName = null;
            })
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildElegantPill(
            icon: Icons.groups_outlined,
            label: _selectedGroupName ?? 'All Groups',
            hasValue: _selectedGroupName != null,
            onTap: () => _showGroupPicker(provider),
            onClear: _selectedGroupName != null
                ? () => setState(() => _selectedGroupName = null)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildElegantPill({
    required IconData icon,
    required String label,
    required bool hasValue,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: hasValue
              ? primaryRed.withOpacity(0.1)
              : const Color(0xFF131313).withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue
                ? primaryRed.withOpacity(0.4)
                : Colors.white.withOpacity(0.06),
            width: hasValue ? 1 : 0.6,
          ),
          boxShadow: hasValue
              ? [
            BoxShadow(
              color: primaryRed.withOpacity(0.15),
              blurRadius: 10,
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: hasValue ? primaryRed : textGrey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: hasValue ? textWhite : textGrey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasValue)
              GestureDetector(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.close, size: 12, color: primaryRed),
                ),
              )
            else
              const Icon(Icons.keyboard_arrow_down,
                  size: 13, color: textGrey),
          ],
        ),
      ),
    );
  }

  void _showBranchPicker(AdminProvider provider) {
    final branches = provider.branches.where((b) => b.isActive).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildPickerSheet(
        title: 'Select Branch',
        icon: Icons.location_on_outlined,
        items: [
          {'id': null, 'label': 'All Branches', 'subtitle': ''},
          ...branches.map((b) => {
            'id': b.id,
            'label': b.name,
            'subtitle': b.address.isNotEmpty ? b.address : '',
          }),
        ],
        currentId: _selectedBranchId,
        onSelect: (id, label) {
          setState(() {
            _selectedBranchId = id;
            _selectedBranchName = label == 'All Branches' ? null : label;
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showGroupPicker(AdminProvider provider) {
    final groups = <String>[];
    for (final c in provider.classes) {
      final n = c.className.trim();
      if (n.isNotEmpty && !groups.contains(n)) groups.add(n);
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildPickerSheet(
        title: 'Select Group',
        icon: Icons.groups_outlined,
        items: [
          {'id': null, 'label': 'All Groups', 'subtitle': ''},
          ...groups.map((g) => {
            'id': g,
            'label': g,
            'subtitle':
            '${provider.classes.where((c) => c.className == g).length} class(es)',
          }),
        ],
        currentId: _selectedGroupName,
        onSelect: (id, label) {
          setState(() {
            _selectedGroupName = label == 'All Groups' ? null : label;
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Widget _buildPickerSheet({
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String? currentId,
    required void Function(String?, String) onSelect,
  }) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: primaryRed.withOpacity(0.1),
                    border: Border.all(
                        color: primaryRed.withOpacity(0.3), width: 0.8),
                  ),
                  child: Icon(icon, size: 15, color: primaryRed),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textWhite,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF222228), height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                final id = item['id'] as String?;
                final label = item['label'] as String;
                final subtitle = item['subtitle'] as String? ?? '';
                final isSelected = id == currentId;

                return GestureDetector(
                  onTap: () => onSelect(id, label),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryRed.withOpacity(0.1)
                          : Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? primaryRed.withOpacity(0.4)
                            : Colors.white.withOpacity(0.05),
                        width: isSelected ? 1 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? primaryRed : Colors.white24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected ? textWhite : textGrey,
                                ),
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: textDarkGrey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_rounded,
                              size: 16, color: primaryRed),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }

  // ============================================================
  // ============ YENİ: COACH PICKER ============================
  // ============================================================
  Future<Map<String, dynamic>?> _showCoachPicker(
      AdminProvider provider) async {
    final coaches = provider.coaches;
    if (coaches.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No coaches found',
              style: GoogleFonts.inter(fontSize: 11),
            ),
            backgroundColor: primaryRed,
          ),
        );
      }
      return null;
    }

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildPickerSheet(
        title: 'Select Coach',
        icon: Icons.person_search_rounded,
        items: coaches.map((c) {
          final parts = <String>[];
          if (c.role.isNotEmpty) parts.add(c.role);
          if (c.branch.isNotEmpty) parts.add(c.branch);
          return {
            'id': c.uid,
            'label': c.fullName,
            'subtitle': parts.isEmpty ? '—' : parts.join(' · '),
          };
        }).toList(),
        currentId: null,
        onSelect: (id, label) {
          Navigator.pop(ctx, {'uid': id, 'name': label});
        },
      ),
    );
  }

  // ============================================================
  // ============ TARİH FİLTRE BÖLÜMÜ ==========================
  // ============================================================
  Widget _buildDateFilterSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131313).withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Date Range',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textWhite,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Analyze performance',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                          color: primaryRed,
                        ),
                      ),
                    ],
                  ),
                  _buildCustomFilterTrigger(),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavButton(
                      Icons.chevron_left, () => _changeScrollerWeek(-1)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          int offset = index - 1000;
                          setState(() {
                            _alignScrollerToWeek(DateTime.now()
                                .add(Duration(days: offset * 7)));
                          });
                        },
                        itemBuilder: (context, pageIndex) {
                          int offset = pageIndex - 1000;
                          DateTime pageBaseDate = DateTime.now()
                              .add(Duration(days: offset * 7));
                          int weekday = pageBaseDate.weekday;
                          DateTime weekStart = pageBaseDate
                              .subtract(Duration(days: weekday - 1));

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(7, (dayIndex) {
                              final currentDate = weekStart
                                  .add(Duration(days: dayIndex));
                              return Expanded(
                                  child: _buildDateItem(currentDate));
                            }),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildNavButton(
                      Icons.chevron_right, () => _changeScrollerWeek(1)),
                  const SizedBox(width: 8),
                  _buildCalendarButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomFilterTrigger() {
    final Map<String, String> modes = {
      'All': 'All Time',
      'Today': 'Today',
      'ThisWeek': 'This Week',
      'ThisMonth': 'This Month',
      'Custom': 'Custom Range',
    };

    return GestureDetector(
      onTap: _showFilterBottomSheet,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF161618),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              modes[_dateFilterMode] ?? 'All Time',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w400,
                color: textWhite,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, color: textWhite, size: 12),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF111111).withOpacity(0.9),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textGrey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Select Filter Mode',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textWhite,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFilterOption('All Time', 'All', Icons.all_inclusive),
                _buildFilterOption('Today', 'Today', Icons.today),
                _buildFilterOption(
                    'This Week', 'ThisWeek', Icons.date_range),
                _buildFilterOption(
                    'This Month', 'ThisMonth', Icons.calendar_month),
                _buildFilterOption(
                    'Custom Range', 'Custom', Icons.edit_calendar),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String label, String value, IconData icon) {
    final bool isSelected = _dateFilterMode == value;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (value == 'Custom') {
          _openCustomDateRangePicker();
        } else {
          _handleFilterTap(value);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryRed.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
            isSelected ? primaryRed.withOpacity(0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? primaryRed : textGrey),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: isSelected ? primaryRed : textWhite,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check, size: 16, color: primaryRed),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFF161618),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Icon(icon, color: textWhite, size: 12),
      ),
    );
  }

  Widget _buildCalendarButton() {
    return GestureDetector(
      onTap: _openCustomDateRangePicker,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF161618),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primaryRed.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: primaryRed.withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ],
        ),
        child: const Icon(Icons.calendar_today_outlined,
            color: primaryRed, size: 14),
      ),
    );
  }

  Widget _buildDateItem(DateTime date) {
    final bool isSelected = _startDate != null &&
        _endDate != null &&
        date.year == _startDate!.year &&
        date.month == _startDate!.month &&
        date.day == _startDate!.day &&
        _dateFilterMode == 'Custom';

    final String dayName = DateFormat('E').format(date).toUpperCase();
    final String dayNum = DateFormat('d').format(date);
    final String monthName = DateFormat('MMM').format(date).toUpperCase();

    return GestureDetector(
      onTap: () {
        setState(() {
          _startDate = DateTime(date.year, date.month, date.day);
          _endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
          _dateFilterMode = 'Custom';
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: primaryRed.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: GoogleFonts.inter(
                fontSize: 7,
                fontWeight: FontWeight.w500,
                color: isSelected ? textWhite : textDarkGrey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              dayNum,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textWhite,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              monthName,
              style: GoogleFonts.inter(
                fontSize: 6,
                fontWeight: FontWeight.w500,
                color: isSelected ? textWhite : textDarkGrey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ============ REPORT KARTLARI (9 RAPOR) ====================
  // ============================================================
  Widget _buildReportCard(
      BuildContext context, AdminProvider provider, int index) {
    final reports = [
      {
        'icon': Icons.people_outline,
        'title': 'Attendance Report',
        'desc': 'Daily & monthly check-ins\nby class and coach.',
      },
      {
        'icon': Icons.attach_money,
        'title': 'Revenue Report',
        'desc': 'Full breakdown of income\nby package and method.',
      },
      {
        'icon': Icons.workspace_premium_outlined,
        'title': 'Membership Report',
        'desc': 'New & renewed memberships\nwith status.',
      },
      {
        'icon': Icons.person_add_alt_1_outlined,
        'title': 'New Members Report',
        'desc': 'New signups with plan,\ngroup & branch details.',
      },
      {
        'icon': Icons.sports_mma_outlined,
        'title': 'Coach Performance',
        'desc': 'Class occupancy and\nretention by coach.',
      },
      {
        'icon': Icons.calendar_today_outlined,
        'title': 'Class Occupancy',
        'desc': 'Fill rate for every\nscheduled class.',
      },
      {
        'icon': Icons.bolt_outlined,
        'title': 'Inactive Players',
        'desc': 'No attendance in the\nlast 14 days.',
      },
      {
        'icon': Icons.access_time_outlined,
        'title': 'Coach Check-ins',
        'desc': 'Daily coach check-ins\nby branch and coach.',
      },
      {
        'icon': Icons.groups_outlined,
        'title': 'Coach Daily Attendance',
        'desc': 'Coach-marked attendance\nwith photos & notes.',
      },
    ];

    final report = reports[index];

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF131313).withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryRed.withOpacity(0.08),
                  border: Border.all(color: primaryRed.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryRed.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Icon(report['icon'] as IconData,
                    color: primaryRed, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            report['title'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textWhite,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.monitor_heart_outlined,
                            color: primaryRed, size: 10),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report['desc'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w400,
                        color: textGrey,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ===== VIEW REPORT — direkt PDF açar =====
                    GestureDetector(
                      onTap: () => _exportReport(
                          context, provider, index, 'pdf',
                          isPreview: true),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View Report',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                                color: textWhite,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward,
                                color: textWhite, size: 8),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildMiniExportButton(
                            icon: Icons.table_chart_outlined,
                            label: 'Excel',
                            onTap: () => _exportReport(
                                context, provider, index, 'csv'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildMiniExportButton(
                            icon: Icons.picture_as_pdf_outlined,
                            label: 'PDF',
                            onTap: () => _exportReport(
                                context, provider, index, 'pdf'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniExportButton(
      {required IconData icon,
        required String label,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textWhite, size: 8),
            const SizedBox(width: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 7,
                fontWeight: FontWeight.w500,
                color: textWhite,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ============ FİLTRE HELPERS ===============================
  // ============================================================
  void _handleFilterTap(String key) {
    setState(() {
      _dateFilterMode = key;
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _openCustomDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: primaryRed,
              onPrimary: Colors.white,
              surface: Color(0xFF121212),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF121212),
            textTheme: TextTheme(
              titleLarge:
              GoogleFonts.outfit(fontSize: 16, color: Colors.white),
              bodyMedium:
              GoogleFonts.inter(fontSize: 12, color: Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateFilterMode = 'Custom';
        _startDate = picked.start;
        _endDate = picked.end;
        _alignScrollerToWeek(_startDate!);
      });
    }
  }

  String _getFilterLabel() {
    switch (_dateFilterMode) {
      case 'Today':
        return 'Today';
      case 'ThisWeek':
        return 'This Week';
      case 'ThisMonth':
        return 'This Month';
      case 'Custom':
        if (_startDate != null && _endDate != null) {
          if (_startDate!.isAtSameMomentAs(_endDate!)) {
            return DateFormat('dd MMM yyyy').format(_startDate!);
          }
          return '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}';
        }
        return 'Custom';
      default:
        return 'All Time';
    }
  }

  (DateTime, DateTime)? _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_dateFilterMode) {
      case 'Today':
        return (today, today.add(const Duration(days: 1)));
      case 'ThisWeek':
        final monday = today.subtract(Duration(days: now.weekday - 1));
        return (monday, monday.add(const Duration(days: 7)));
      case 'ThisMonth':
        final firstDay = DateTime(now.year, now.month, 1);
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        return (firstDay, nextMonth);
      case 'Custom':
        if (_startDate != null && _endDate != null) {
          return (_startDate!, _endDate!.add(const Duration(days: 1)));
        }
        return null;
      default:
        return null;
    }
  }

  bool _isInDateRange(DateTime date) {
    final range = _getDateRange();
    if (range == null) return true;
    final (start, end) = range;
    return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
        date.isBefore(end);
  }

  bool _passesBranch(AdminProvider provider,
      {String? branchId, String? userId}) {
    if (_selectedBranchId == null) return true;
    if (branchId != null && branchId.isNotEmpty) {
      return branchId == _selectedBranchId;
    }
    if (userId != null && userId.isNotEmpty) {
      try {
        final player = provider.players.firstWhere((p) => p.uid == userId);
        return player.branchId == _selectedBranchId;
      } catch (_) {}
    }
    return true;
  }

  bool _passesGroup({String? className, String? groupName}) {
    if (_selectedGroupName == null) return true;
    if (className != null && className.isNotEmpty) {
      return className == _selectedGroupName;
    }
    if (groupName != null && groupName.isNotEmpty) {
      return groupName == _selectedGroupName;
    }
    return true;
  }

  Map<String, PlayerModel> _buildPlayerMap(AdminProvider provider) {
    final map = <String, PlayerModel>{};
    for (final p in provider.players) {
      map[p.uid] = p;
    }
    return map;
  }

  Map<String, PackageModel> _buildPackageMap(AdminProvider provider) {
    final map = <String, PackageModel>{};
    for (final p in provider.packages) {
      map[p.id] = p;
    }
    return map;
  }

  Map<String, BranchModel> _buildBranchMap(AdminProvider provider) {
    final map = <String, BranchModel>{};
    for (final b in provider.branches) {
      map[b.id] = b;
    }
    return map;
  }

  PlayerModel? _getPlayer(Map<String, PlayerModel> playerMap, String? userId) {
    if (userId == null || userId.isEmpty) return null;
    return playerMap[userId];
  }

  String _safe(String? value) {
    if (value == null || value.trim().isEmpty) return _empty;
    return value.trim();
  }

  String _getPlayerPackageName(
      PlayerModel player, Map<String, PackageModel> packageMap) {
    final pkgId = player.currentPackageId;
    if (pkgId.isNotEmpty) {
      final pkg = packageMap[pkgId];
      if (pkg != null) return pkg.name;
    }
    return _empty;
  }

  Future<pw.MemoryImage?> _loadLogo() async {
    try {
      final ByteData data =
      await rootBundle.load('assets/images/lycans_logo.jpeg');
      final Uint8List bytes = data.buffer.asUint8List();
      return pw.MemoryImage(bytes);
    } catch (e) {
      debugPrint('Logo yüklenemedi: $e');
      return null;
    }
  }

  // ============================================================
  // ============ EXPORT — 9 RAPOR + COACH PICKER ==============
  // ============================================================
  Future<void> _exportReport(
      BuildContext context,
      AdminProvider provider,
      int reportIndex,
      String format, {
        bool isPreview = false,
      }) async {
    // ===== COACH RAPORLARI İÇİN COACH PICKER =====
    String? selectedCoachUid;
    String? selectedCoachName;

    if (reportIndex == 7 || reportIndex == 8) {
      final picked = await _showCoachPicker(provider);
      if (picked == null) return;
      selectedCoachUid = picked['uid'] as String?;
      selectedCoachName = picked['name'] as String?;
    }

    final playerMap = _buildPlayerMap(provider);
    final packageMap = _buildPackageMap(provider);
    final branchMap = _buildBranchMap(provider);

    List<List<String>> rows = [];
    String reportName = '';
    final dateRangeLabel =
    _dateFilterMode == 'All' ? 'All Time' : _getFilterLabel();

    final filterSummary = <String>[];
    if (_selectedBranchName != null)
      filterSummary.add('Branch: $_selectedBranchName');
    if (_selectedGroupName != null)
      filterSummary.add('Group: $_selectedGroupName');
    if (selectedCoachName != null)
      filterSummary.add('Coach: $selectedCoachName');

    try {
      switch (reportIndex) {
      // ===== 0: ATTENDANCE =====
        case 0:
          reportName = 'Attendance Report';
          final filteredAttendance = provider.attendance
              .where((a) => _isInDateRange(a.timestamp))
              .where((a) => _passesBranch(provider, userId: a.userId))
              .where((a) => _passesGroup(className: a.className))
              .toList();

          if (filteredAttendance.isEmpty) {
            _showCustomEmptyDialog(context, reportName);
            return;
          }

          rows = [
            [
              'Date',
              'Time',
              'Player',
              'Phone',
              'Class/Group',
              'Coach',
              'Status'
            ],
            ...filteredAttendance.map((a) {
              final player = _getPlayer(playerMap, a.userId);
              final playerName = player?.fullName ??
                  (a.playerName.isNotEmpty ? a.playerName : null);
              final phone = player?.phone;

              final classModel = provider.classes
                  .where((c) => c.id == a.classId)
                  .firstOrNull;
              final coachName = classModel?.coachName;

              final statusText = a.status == 'recorded'
                  ? 'Present'
                  : a.status == 'absent'
                  ? 'Absent'
                  : a.status == 'denied_expired'
                  ? 'Denied - Expired'
                  : a.status == 'denied_frozen'
                  ? 'Denied - Frozen'
                  : _safe(a.status);

              return [
                DateFormat('yyyy-MM-dd').format(a.timestamp),
                DateFormat('HH:mm').format(a.timestamp),
                _safe(playerName),
                _safe(phone),
                _safe(a.className),
                _safe(coachName),
                statusText,
              ];
            }),
          ];
          break;

      // ===== 1: REVENUE =====
        case 1:
          reportName = 'Revenue Report';
          final filteredInvoices = provider.invoices
              .where((i) => _isInDateRange(i.date))
              .where((i) => _passesBranch(provider, userId: i.userId))
              .toList();

          if (filteredInvoices.isEmpty) {
            _showCustomEmptyDialog(context, reportName);
            return;
          }

          final totalPaid = filteredInvoices
              .where((i) => i.isPaid)
              .fold<double>(0, (s, i) => s + i.amount);
          final totalUnpaid = filteredInvoices
              .where((i) => !i.isPaid)
              .fold<double>(0, (s, i) => s + i.amount);

          rows = [
            [
              'Invoice #',
              'Player',
              'Phone',
              'Package',
              'Amount (EGP)',
              'Method',
              'Staff',
              'Date',
              'Status'
            ],
            ...filteredInvoices.map((i) {
              final player = _getPlayer(playerMap, i.userId);
              final playerName = player?.fullName ??
                  (i.playerName.isNotEmpty ? i.playerName : null);
              final phone = player?.phone;

              String packageName = i.packageName;
              if (packageName.isEmpty || packageName == _empty) {
                if (player != null) {
                  packageName = _getPlayerPackageName(player, packageMap);
                }
              }

              return [
                _safe(i.invoiceNumber),
                _safe(playerName),
                _safe(phone),
                _safe(packageName),
                i.amount.toStringAsFixed(0),
                _safe(i.paymentMethod),
                _safe(i.staffName),
                DateFormat('yyyy-MM-dd').format(i.date),
                i.isPaid ? 'Paid' : 'Unpaid',
              ];
            }),
            [
              'TOTAL',
              '',
              '',
              'Paid: ${totalPaid.toStringAsFixed(0)} EGP',
              'Unpaid: ${totalUnpaid.toStringAsFixed(0)} EGP',
              '',
              '',
              '',
              ''
            ],
          ];
          break;

      // ===== 2: MEMBERSHIP =====
        case 2:
          reportName = 'Membership Report';
          final playersMap = playerMap;

          final filteredMemberships = provider.memberships.where((m) {
            final startStr = m['startDate']?.toString() ?? '';
            final start = DateTime.tryParse(startStr);
            if (start == null) return false;
            if (!_isInDateRange(start)) return false;
            final uid = m['userId']?.toString() ?? '';
            return _passesBranch(provider, userId: uid);
          }).toList();

          if (filteredMemberships.isEmpty) {
            _showCustomEmptyDialog(context, reportName);
            return;
          }

          final range = _getDateRange();
          final rangeStart = range?.$1;

          rows = [
            [
              'Type',
              'Player',
              'Phone',
              'Branch',
              'Group',
              'Package',
              'Amount (EGP)',
              'Start',
              'End',
              'Status'
            ],
            ...filteredMemberships.map((m) {
              final uid = m['userId']?.toString() ?? '';
              final player = playersMap[uid];
              final playerName = player?.fullName ?? _empty;
              final phone = player?.phone ?? _empty;

              final branchId =
                  m['branchId']?.toString() ?? player?.branchId ?? '';
              final branchName = m['branchName']?.toString() ??
                  branchMap[branchId]?.name ??
                  _empty;
              final groupName = m['groupName']?.toString() ?? _empty;
              final packageName = m['planName']?.toString() ?? _empty;
              final amount = (m['price'] as num?)?.toDouble() ?? 0;
              final startDate =
              DateTime.tryParse(m['startDate']?.toString() ?? '');
              final endDate =
              DateTime.tryParse(m['endDate']?.toString() ?? '');
              final isActive = m['isActive'] == true;
              final isFrozen = m['isFrozen'] == true;

              final joinDate = player?.joinDate;
              final isNew = joinDate != null &&
                  (rangeStart == null || !joinDate.isBefore(rangeStart));

              final status = isFrozen
                  ? 'Frozen'
                  : !isActive
                  ? 'Inactive'
                  : (endDate != null && endDate.isBefore(DateTime.now()))
                  ? 'Expired'
                  : 'Active';

              return [
                isNew ? 'NEW' : 'RENEWAL',
                _safe(playerName),
                _safe(phone),
                _safe(branchName),
                _safe(groupName),
                _safe(packageName),
                amount.toStringAsFixed(0),
                startDate != null
                    ? DateFormat('yyyy-MM-dd').format(startDate)
                    : _empty,
                endDate != null
                    ? DateFormat('yyyy-MM-dd').format(endDate)
                    : _empty,
                status,
              ];
            }),
          ];
          break;

      // ===== 3: NEW MEMBERS =====
        case 3:
          reportName = 'New Members Report';
          final range = _getDateRange();
          final rangeStart = range?.$1;
          final rangeEnd = range?.$2;

          final newPlayers = provider.players.where((p) {
            if (rangeStart != null && p.joinDate.isBefore(rangeStart)) {
              return false;
            }
            if (rangeEnd != null && !p.joinDate.isBefore(rangeEnd)) {
              return false;
            }
            if (_selectedBranchId != null &&
                p.branchId != _selectedBranchId) {
              return false;
            }
            return true;
          }).toList();

          if (newPlayers.isEmpty) {
            _showCustomEmptyDialog(context, reportName);
            return;
          }

          rows = [
            [
              'Player #',
              'Name',
              'Phone',
              'Sport',
              'Level',
              'Weight Class',
              'Branch',
              'Group',
              'Package',
              'Joined',
              'Sub. Start',
              'Sub. End'
            ],
            ...newPlayers.map((p) {
              final memberships = provider.memberships
                  .where((m) => m['userId'] == p.uid)
                  .toList();
              Map<String, dynamic>? latest;
              if (memberships.isNotEmpty) {
                memberships.sort((a, b) {
                  final aD =
                      DateTime.tryParse(a['startDate']?.toString() ?? '') ??
                          DateTime.now();
                  final bD =
                      DateTime.tryParse(b['startDate']?.toString() ?? '') ??
                          DateTime.now();
                  return bD.compareTo(aD);
                });
                latest = memberships.first;
              }

              final branchName = p.branchName.isNotEmpty
                  ? p.branchName
                  : (branchMap[p.branchId]?.name ?? _empty);
              final groupName = latest?['groupName']?.toString() ?? _empty;
              final packageName = latest?['planName']?.toString() ??
                  _getPlayerPackageName(p, packageMap);
              final subStart = latest?['startDate']?.toString();
              final subEnd = latest?['endDate']?.toString();

              return [
                p.playerNumber > 0 ? '#${p.playerNumber}' : _empty,
                _safe(p.fullName),
                _safe(p.phone),
                _safe(p.sport),
                _safe(p.level),
                _safe(p.weightClass),
                _safe(branchName),
                _safe(groupName),
                _safe(packageName),
                DateFormat('yyyy-MM-dd').format(p.joinDate),
                subStart != null
                    ? DateFormat('yyyy-MM-dd').format(
                    DateTime.tryParse(subStart) ?? p.joinDate)
                    : _empty,
                subEnd != null
                    ? DateFormat('yyyy-MM-dd').format(
                    DateTime.tryParse(subEnd) ?? p.joinDate)
                    : _empty,
              ];
            }),
          ];
          break;

      // ===== 4: COACH PERFORMANCE =====
        case 4:
          reportName = 'Coach Performance Report';
          final filteredClasses = provider.classes
              .where((c) => _isInDateRange(c.startTime))
              .where((c) => _passesBranch(provider, branchId: c.branchId))
              .where((c) => _passesGroup(className: c.className))
              .toList();

          if (filteredClasses.isEmpty) {
            _showCustomEmptyDialog(context, reportName);
            return;
          }

          final Map<String, List<ClassModel>> coachGroups = {};
          for (final c in filteredClasses) {
            coachGroups.putIfAbsent(c.coachName, () => []);
            coachGroups[c.coachName]!.add(c);
          }

          rows = [
            [
              'Coach',
              'Branch',
              'Class',
              'Sport',
              'Schedule',
              'Booked',
              'Capacity',
              'Fill Rate'
            ],
            ...filteredClasses.map((c) {
              String branchName = c.branch;
              if (branchName.isEmpty && c.branchId.isNotEmpty) {
                final branch = branchMap[c.branchId];
                branchName = branch?.name ?? _empty;
              }
              return [
                _safe(c.coachName),
                _safe(branchName),
                _safe(c.className),
                _safe(c.sport),
                _safe(c.schedule),
                c.bookedCount.toString(),
                c.capacity.toString(),
                '${(c.fillPercent * 100).toStringAsFixed(0)}%',
              ];
            }),
            ['--- COACH SUMMARY ---', '', '', '', '', '', '', ''],
            ...coachGroups.entries.map((e) {
              final totalBooked =
              e.value.fold<int>(0, (s, c) => s + c.bookedCount);
              final totalCapacity =
              e.value.fold<int>(0, (s, c) => s + c.capacity);
              final fillRate = totalCapacity > 0
                  ? (totalBooked / totalCapacity * 100).toStringAsFixed(0)
                  : '0';
              return [
                _safe(e.key),
                '${e.value.length} classes',
                '',
                '',
                '',
                '$totalBooked',
                '$totalCapacity',
                '$fillRate%',
              ];
            }),
          ];
          break;

      // ===== 5: CLASS OCCUPANCY =====
        case 5:
          reportName = 'Class Occupancy Report';
          final filteredClasses = provider.classes
              .where((c) => _isInDateRange(c.startTime))
              .where((c) => _passesBranch(provider, branchId: c.branchId))
              .where((c) => _passesGroup(className: c.className))
              .toList();

          if (filteredClasses.isEmpty) {
            _showCustomEmptyDialog(context, reportName);
            return;
          }

          rows = [
            [
              'Class/Group',
              'Sport',
              'Coach',
              'Branch',
              'Location',
              'Schedule',
              'Time',
              'Booked',
              'Capacity',
              'Fill Rate',
              'Status'
            ],
            ...filteredClasses.map((c) {
              String branchName = c.branch;
              if (branchName.isEmpty && c.branchId.isNotEmpty) {
                final branch = branchMap[c.branchId];
                branchName = branch?.name ?? _empty;
              }
              final fillRate = c.fillPercent;
              final status = fillRate >= 1.0
                  ? 'FULL'
                  : fillRate >= 0.8
                  ? 'ALMOST FULL'
                  : fillRate >= 0.4
                  ? 'FILLING'
                  : 'OPEN';
              return [
                _safe(c.className),
                _safe(c.sport),
                _safe(c.coachName),
                _safe(branchName),
                _safe(c.location),
                _safe(c.schedule),
                _safe(c.timeStr),
                c.bookedCount.toString(),
                c.capacity.toString(),
                '${(fillRate * 100).toStringAsFixed(0)}%',
                status,
              ];
            }),
          ];
          break;

      // ===== 6: INACTIVE PLAYERS =====
        case 6:
          reportName = 'Inactive Players Report';
          final now = DateTime.now();
          final inactive = provider.players.where((p) {
            if (!_passesBranch(provider, branchId: p.branchId)) return false;
            final playerAttendance =
            provider.attendance.where((a) => a.userId == p.uid).toList();
            if (playerAttendance.isEmpty) return true;
            playerAttendance
                .sort((a, b) => b.timestamp.compareTo(a.timestamp));
            return now.difference(playerAttendance.first.timestamp).inDays >
                14;
          }).toList();

          if (inactive.isEmpty) {
            _showCustomEmptyDialog(context, reportName);
            return;
          }

          rows = [
            [
              'Player #',
              'Player',
              'Phone',
              'Branch',
              'Sport',
              'Level',
              'Weight Class',
              'Package',
              'Last Attendance',
              'Days Inactive'
            ],
            ...inactive.map((p) {
              final packageName = _getPlayerPackageName(p, packageMap);
              final playerAttendance =
              provider.attendance.where((a) => a.userId == p.uid).toList();

              String lastAttendance = _empty;
              String daysInactive = _empty;

              if (playerAttendance.isNotEmpty) {
                playerAttendance
                    .sort((a, b) => b.timestamp.compareTo(a.timestamp));
                final last = playerAttendance.first.timestamp;
                lastAttendance = DateFormat('yyyy-MM-dd').format(last);
                daysInactive = '${now.difference(last).inDays} days';
              } else {
                lastAttendance = 'Never';
                daysInactive = 'No records';
              }

              final branchName = p.branchName.isNotEmpty
                  ? p.branchName
                  : (branchMap[p.branchId]?.name ?? _empty);

              return [
                p.playerNumber > 0 ? '#${p.playerNumber}' : _empty,
                _safe(p.fullName),
                _safe(p.phone),
                _safe(branchName),
                _safe(p.sport),
                _safe(p.level),
                _safe(p.weightClass),
                _safe(packageName),
                lastAttendance,
                daysInactive,
              ];
            }),
          ];
          break;

      // ===== 7: COACH CHECK-INS =====
        case 7:
          reportName = 'Coach Check-ins Report'
              '${selectedCoachName != null ? ' — $selectedCoachName' : ''}';
          final filtered = provider.coachAttendance.where((c) {
            final t = DateTime.tryParse(c['checkedInAt']?.toString() ?? '');
            if (t == null) return false;
            if (!_isInDateRange(t)) return false;
            if (!_passesBranch(
                provider, branchId: c['branchId']?.toString())) {
              return false;
            }
            if (selectedCoachUid != null &&
                c['coachUid']?.toString() != selectedCoachUid) {
              return false;
            }
            return true;
          }).toList();

          if (filtered.isEmpty) {
            _showCustomEmptyDialog(context, reportName);
            return;
          }

          rows = [
            ['Date', 'Time', 'Coach', 'Role', 'Branch', 'Note'],
            ...filtered.map((c) {
              final dt =
              DateTime.tryParse(c['checkedInAt']?.toString() ?? '');
              return [
                dt != null ? DateFormat('yyyy-MM-dd').format(dt) : _empty,
                dt != null ? DateFormat('HH:mm').format(dt) : _empty,
                _safe(c['coachName']?.toString()),
                _safe(c['coachRole']?.toString()),
                _safe(c['branchName']?.toString()),
                _safe(c['note']?.toString()),
              ];
            }),
          ];
          break;

      // ===== 8: COACH DAILY ATTENDANCE =====
        case 8:
          reportName = 'Coach Daily Attendance Report'
              '${selectedCoachName != null ? ' — $selectedCoachName' : ''}';
          final filtered = provider.dailyAttendances.where((a) {
            final d = DateTime.tryParse(a['date']?.toString() ??
                a['createdAt']?.toString() ??
                '');
            if (d == null) return false;
            if (!_isInDateRange(d)) return false;
            if (!_passesBranch(
                provider, branchId: a['branchId']?.toString())) {
              return false;
            }
            if (!_passesGroup(groupName: a['groupName']?.toString())) {
              return false;
            }
            if (selectedCoachUid != null &&
                a['coachUid']?.toString() != selectedCoachUid) {
              return false;
            }
            return true;
          }).toList();

          if (filtered.isEmpty) {
            _showCustomEmptyDialog(context, reportName);
            return;
          }

          rows = [
            [
              'Date',
              'Time',
              'Coach',
              'Group',
              'Branch',
              'Players',
              'Player Names',
              'Notes',
              'Photos'
            ],
            ...filtered.map((a) {
              final dt = DateTime.tryParse(a['createdAt']?.toString() ?? '');
              final players =
                  (a['playerNumbers'] as List?)?.cast<num>() ?? [];
              final names =
                  (a['playerNames'] as List?)?.cast<String>() ?? [];
              final photos = (a['photoUrls'] as List?) ?? [];

              final playerList = List.generate(
                players.length > names.length ? players.length : names.length,
                    (i) {
                  final num = i < players.length ? players[i].toInt() : 0;
                  final name = i < names.length ? names[i] : '';
                  return num > 0 ? '#$num $name' : name;
                },
              ).where((s) => s.trim().isNotEmpty).join(', ');

              return [
                dt != null ? DateFormat('yyyy-MM-dd').format(dt) : _empty,
                dt != null ? DateFormat('HH:mm').format(dt) : _empty,
                _safe(a['coachName']?.toString()),
                _safe(a['groupName']?.toString()),
                _safe(a['branchName']?.toString()),
                '${(a['playerCount'] as num?)?.toInt() ?? players.length}',
                _safe(playerList),
                _safe(a['notes']?.toString()),
                '${photos.length}',
              ];
            }),
          ];
          break;

        default:
          rows = [
            ['No data']
          ];
      }

      final logoImage = await _loadLogo();

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.black,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 50,
                      height: 50,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(25),
                      ),
                      child: pw.ClipOval(
                        child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                      ),
                    ),
                  if (logoImage != null) pw.SizedBox(width: 14),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          'LYCANS FIGHT CLUB',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.amber,
                            letterSpacing: 1.2,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          reportName,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Date Filter: $dateRangeLabel',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            if (filterSummary.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                filterSummary.join('  ·  '),
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ],
            pw.SizedBox(height: 6),
            pw.Text(
              'Total Records: ${rows.length - 1}',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: rows.first,
              data: rows.skip(1).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey800,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding:
              const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 0.5,
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '© ${DateTime.now().year} Lycans Fight Club',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Confidential Report',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => doc.save());

      if (!isPreview && context.mounted) {
        _showSuccessDialog(
            context,
            '$reportName exported successfully in ${format.toUpperCase()} format.');
      }
    } catch (e) {
      debugPrint('Export error: $e');
      if (context.mounted) {
        _showErrorDialog(context, 'Failed to export report: $e');
      }
    }
  }

  // ============================================================
  // ============ DIALOGLAR ====================================
  // ============================================================
  void _showCustomEmptyDialog(BuildContext context, String reportName) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                    color: primaryRed.withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 5)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: primaryRed, size: 40),
                const SizedBox(height: 12),
                Text(
                  'No Data Found',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'There is no data available for $reportName in the selected date range.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: textGrey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed.withOpacity(0.15),
                      foregroundColor: primaryRed,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: primaryRed.withOpacity(0.5)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text('Close',
                        style: GoogleFonts.inter(
                            fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: primaryRed, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 10, color: textWhite),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: primaryRed.withOpacity(0.3)),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 10, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: primaryRed.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
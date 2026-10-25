import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/coach_model.dart';
import '../models/branch_model.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';

class CoachesScreen extends StatefulWidget {
  const CoachesScreen({super.key});

  @override
  State<CoachesScreen> createState() => _CoachesScreenState();
}

class _CoachesScreenState extends State<CoachesScreen> {
  // ===== COACHES TAB STATE =====
  String _searchQuery = '';
  String _filter = 'All';
  final List<String> _filters = ['All', 'Coaches', 'Staff', 'Inactive'];

  // ===== ATTENDANCE TAB STATE =====
  int _activeTab = 0; // 0 = Coaches, 1 = Attendance
  DateTime _selectedDate = DateTime.now();
  String _dateChip = 'Today'; // Today / Yesterday / Last7 / Custom

  final Color _darkBg = const Color(0xFF0A0A0A);
  final Color _cardBg = const Color(0xFF141414).withOpacity(0.7);
  final Color _redAccent = const Color(0xFFE50914);
  final Color _textGrey = const Color(0xFF9E9E9E);
  final Color _borderColor = Colors.white.withOpacity(0.1);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final allCoaches = provider.coaches;
    final currentAdmin = provider.admin;

    final canManageCoaches = currentAdmin?.role == 'Head Coach' ||
        currentAdmin?.role == 'Owner' ||
        (currentAdmin?.permissions.contains(CoachPermissions.manageCoaches) ??
            false);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/coaches_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              Image.asset(
                'assets/images/lycans_png.png',
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),

              // Dynamic title based on active tab
              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  children: _activeTab == 0
                      ? [
                    const TextSpan(text: 'Coaches '),
                    TextSpan(
                        text: '&', style: TextStyle(color: _redAccent)),
                    const TextSpan(text: ' Staff'),
                  ]
                      : [
                    const TextSpan(text: 'Coach '),
                    TextSpan(
                        text: 'Attendance',
                        style: TextStyle(color: _redAccent)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _activeTab == 0
                    ? 'Manage your team, roles and\nclub permissions'
                    : 'Track daily coach check-ins',
                style: GoogleFonts.poppins(
                    fontSize: 10, color: _textGrey, height: 1.3),
              ),
              const SizedBox(height: 16),

              // ===== SEGMENTED TABS =====
              _buildSegmentedTabs(provider),
              const SizedBox(height: 16),

              // ===== TAB CONTENT =====
              if (_activeTab == 0)
                _buildCoachesTabContent(
                    provider, currentAdmin, canManageCoaches, allCoaches)
              else
                _buildAttendanceTabContent(provider),
            ],
          ),
        ),
      ),
    );
  }

  // ============ SEGMENTED TABS ============
  Widget _buildSegmentedTabs(AdminProvider provider) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _activeTab = 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: _activeTab == 0 ? null : _cardBg,
                gradient: _activeTab == 0
                    ? LinearGradient(
                  colors: [
                    _redAccent.withOpacity(0.85),
                    _redAccent.withOpacity(0.55),
                  ],
                )
                    : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _activeTab == 0
                      ? _redAccent.withOpacity(0.6)
                      : _borderColor,
                  width: 0.5,
                ),
                boxShadow: _activeTab == 0
                    ? [
                  BoxShadow(
                    color: _redAccent.withOpacity(0.25),
                    blurRadius: 12,
                  ),
                ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_alt_rounded,
                    size: 14,
                    color: _activeTab == 0 ? Colors.white : _textGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'COACHES',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: _activeTab == 0 ? Colors.white : _textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _activeTab = 1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: _activeTab == 1 ? null : _cardBg,
                gradient: _activeTab == 1
                    ? LinearGradient(
                  colors: [
                    _redAccent.withOpacity(0.85),
                    _redAccent.withOpacity(0.55),
                  ],
                )
                    : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _activeTab == 1
                      ? _redAccent.withOpacity(0.6)
                      : _borderColor,
                  width: 0.5,
                ),
                boxShadow: _activeTab == 1
                    ? [
                  BoxShadow(
                    color: _redAccent.withOpacity(0.25),
                    blurRadius: 12,
                  ),
                ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: _activeTab == 1 ? Colors.white : _textGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ATTENDANCE',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: _activeTab == 1 ? Colors.white : _textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // ==================== TAB 1: COACHES ============================
  // ================================================================
  Widget _buildCoachesTabContent(
      AdminProvider provider,
      dynamic currentAdmin,
      bool canManageCoaches,
      List<CoachModel> allCoaches,
      ) {
    final coaches = allCoaches.where((c) {
      final matchesSearch = c.fullName
          .toLowerCase()
          .contains(_searchQuery.toLowerCase()) ||
          c.email.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesFilter = true;
      if (_filter == 'Inactive') matchesFilter = !c.isActive;
      if (_filter == 'Coaches') {
        matchesFilter = c.role.toLowerCase().contains('coach') && c.isActive;
      }
      if (_filter == 'Staff') {
        matchesFilter = !c.role.toLowerCase().contains('coach') && c.isActive;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    final activeCount = allCoaches.where((c) => c.isActive).length;
    final inactiveCount = allCoaches.length - activeCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filters.map((filter) {
              final isSelected = _filter == filter;
              IconData iconData;
              if (filter == 'Coaches') {
                iconData = Icons.person_outline;
              } else if (filter == 'Staff') {
                iconData = Icons.shield_outlined;
              } else if (filter == 'Inactive') {
                iconData = Icons.person_off_outlined;
              } else {
                iconData = Icons.grid_view_rounded;
              }

              return GestureDetector(
                onTap: () => setState(() => _filter = filter),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.transparent,
                    border: Border.all(
                      color: isSelected ? _redAccent : _borderColor,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(iconData,
                          size: 12,
                          color: isSelected ? _redAccent : _textGrey),
                      const SizedBox(width: 6),
                      Text(
                        filter,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : _textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Search bar
        Row(
          children: [
            Expanded(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _cardBg,
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 14, color: _textGrey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search coaches...',
                          hintStyle: GoogleFonts.poppins(
                              fontSize: 11, color: _textGrey),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cardBg,
                border: Border.all(color: _borderColor),
              ),
              child: Icon(Icons.tune, size: 14, color: _textGrey),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.people_outline,
                value: '${allCoaches.length}',
                label: 'Total Coaches',
                iconColor: _redAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                icon: Icons.verified_user_outlined,
                value: '$activeCount',
                label: 'Active',
                iconColor: _textGrey,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                icon: Icons.person_off_outlined,
                value: '$inactiveCount',
                label: 'Inactive',
                iconColor: _textGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Add button
        if (canManageCoaches)
          InkWell(
            onTap: () => _showCoachDialog(provider, currentAdmin!),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    _redAccent.withOpacity(0.15),
                    Colors.transparent
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                border: Border.all(
                    color: _redAccent.withOpacity(0.5), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 16, color: _redAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add New Coach',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: _redAccent),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),

        Text(
          'COACHES (${coaches.length})',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _redAccent,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),

        if (coaches.isEmpty)
          _buildEmptyState(canManageCoaches, provider, currentAdmin)
        else
          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: coaches.length,
            itemBuilder: (context, index) {
              return _buildCoachCard(
                coaches[index],
                provider,
                currentAdmin,
                canManageCoaches,
              );
            },
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ================================================================
  // ==================== TAB 2: ATTENDANCE =========================
  // ================================================================
  Widget _buildAttendanceTabContent(AdminProvider provider) {
    final admin = provider.admin;
    if (admin == null) return const SizedBox.shrink();

    // View all permission?
    final canViewAll = admin.role == 'Owner' ||
        admin.role == 'Head Coach' ||
        admin.role == 'Manager' ||
        provider.hasPermission(CoachPermissions.viewCoachAttendance);

    // Filter by role
    final allRecords = provider.coachAttendance;
    final visibleRecords = canViewAll
        ? allRecords
        : allRecords.where((r) => r['coachUid'] == admin.uid).toList();

    // Filter by selected date
    final selectedKey =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    final filtered = visibleRecords.where((r) {
      if (_dateChip == 'Last7') {
        // Last 7 days
        final rDate = DateTime.tryParse(r['date']?.toString() ?? '');
        if (rDate == null) return false;
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        return rDate.isAfter(sevenDaysAgo);
      }
      // Today / Yesterday / Custom → exact match
      return r['date'] == selectedKey;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== DATE CHIPS =====
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDateChip('Today', 'Today'),
              const SizedBox(width: 8),
              _buildDateChip('Yesterday', 'Yesterday'),
              const SizedBox(width: 8),
              _buildDateChip('Last 7 Days', 'Last7'),
              const SizedBox(width: 8),
              _buildCustomDateChip(),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Selected date display
        Row(
          children: [
            Container(width: 8, height: 1.5, color: _redAccent),
            const SizedBox(width: 8),
            Text(
              _dateChip == 'Last7'
                  ? 'Showing last 7 days'
                  : DateFormat('EEEE, dd MMM yyyy')
                  .format(_selectedDate),
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ===== SELF CHECK-IN STATUS =====
        if (provider.hasCheckedInToday(admin.uid))
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                vertical: 10, horizontal: 14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF00C853).withOpacity(0.08),
              border: Border.all(
                  color: const Color(0xFF00C853).withOpacity(0.3),
                  width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 13, color: Color(0xFF00C853)),
                const SizedBox(width: 8),
                Text(
                  'You checked in today',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00C853),
                  ),
                ),
              ],
            ),
          ),

        // ===== STATS =====
        Row(
          children: [
            Expanded(
              child: _buildAttendanceStat(
                icon: Icons.event_available_rounded,
                value: '${filtered.length}',
                label: _dateChip == 'Last7' ? 'Last 7 Days' : 'Check-ins',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAttendanceStat(
                icon: Icons.people_alt_rounded,
                value: '${filtered.map((r) => r['coachUid']).toSet().length}',
                label: 'Unique Coaches',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAttendanceStat(
                icon: Icons.location_on_rounded,
                value:
                '${filtered.map((r) => r['branchId']).toSet().length}',
                label: 'Branches',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ===== RECORDS LIST =====
        Text(
          'RECORDS (${filtered.length})',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _redAccent,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),

        if (filtered.isEmpty)
          _buildAttendanceEmptyState()
        else
          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return _buildAttendanceCard(filtered[index], canViewAll);
            },
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDateChip(String label, String value) {
    final isSelected = _dateChip == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _dateChip = value;
          final now = DateTime.now();
          if (value == 'Today') _selectedDate = now;
          if (value == 'Yesterday') {
            _selectedDate = now.subtract(const Duration(days: 1));
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? LinearGradient(
            colors: [
              _redAccent.withOpacity(0.85),
              _redAccent.withOpacity(0.55),
            ],
          )
              : null,
          color: isSelected ? null : _cardBg,
          border: Border.all(
            color: isSelected
                ? _redAccent.withOpacity(0.7)
                : _borderColor,
            width: isSelected ? 1.2 : 0.8,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: _redAccent.withOpacity(0.25),
              blurRadius: 10,
            ),
          ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : _textGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateChip() {
    final isSelected = _dateChip == 'Custom';
    final label = isSelected
        ? DateFormat('dd MMM').format(_selectedDate)
        : 'Custom';
    return GestureDetector(
      onTap: () async {
        final picked = await _showCustomDatePicker(_selectedDate);
        if (picked != null) {
          setState(() {
            _selectedDate = picked;
            _dateChip = 'Custom';
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? LinearGradient(
            colors: [
              _redAccent.withOpacity(0.85),
              _redAccent.withOpacity(0.55),
            ],
          )
              : null,
          color: isSelected ? null : _cardBg,
          border: Border.all(
            color: isSelected
                ? _redAccent.withOpacity(0.7)
                : _borderColor,
            width: isSelected ? 1.2 : 0.8,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: _redAccent.withOpacity(0.25),
              blurRadius: 10,
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 12,
              color: isSelected ? Colors.white : _textGrey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : _textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _cardBg,
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _redAccent, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 8, color: _textGrey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _cardBg,
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded,
              size: 32, color: _textGrey.withOpacity(0.5)),
          const SizedBox(height: 10),
          Text(
            'No check-ins',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _dateChip == 'Last7'
                ? 'No check-ins in last 7 days'
                : 'No coach checked in on this date',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 10, color: _textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(
      Map<String, dynamic> record, bool canViewAll) {
    final name = (record['coachName'] ?? '').toString();
    final role = (record['coachRole'] ?? '').toString();
    final branchName = (record['branchName'] ?? '').toString();
    final note = (record['note'] ?? '').toString();
    final dt = DateTime.tryParse(
        record['checkedInAt']?.toString() ?? '');
    final timeLabel = dt != null
        ? DateFormat('HH:mm').format(dt)
        : '—';
    final dateLabel = dt != null
        ? DateFormat('dd MMM yyyy').format(dt)
        : '';

    final initials = name.isNotEmpty
        ? name
        .trim()
        .split(' ')
        .take(2)
        .map((p) => p.isNotEmpty ? p[0] : '')
        .join()
        .toUpperCase()
        : '??';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _cardBg,
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _redAccent, width: 1.2),
                  color: Colors.black.withOpacity(0.5),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (role.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _redAccent.withOpacity(0.1),
                              border: Border.all(
                                  color: _redAccent.withOpacity(0.3)),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w600,
                                color: _redAccent,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 10, color: _textGrey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            branchName,
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: _textGrey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        note,
                        style: GoogleFonts.poppins(
                            fontSize: 9, color: _textGrey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _redAccent,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style:
                    GoogleFonts.poppins(fontSize: 8, color: _textGrey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ CUSTOM DATE PICKER ============
  Future<DateTime?> _showCustomDatePicker(DateTime initial) async {
    return showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) => _CustomCalendarDialog(initialDate: initial),
    );
  }

  // ================================================================
  // ============== MEVCUT COACHES TAB METODLARI ====================
  // ================================================================
  // (Aşağıdaki metodların tamamı önceki koddan aynen korunmuştur)

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _cardBg,
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 8, color: _textGrey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      bool canManageCoaches,
      AdminProvider provider,
      dynamic currentAdmin,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _cardBg,
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.person_off_outlined,
              size: 32, color: _textGrey.withOpacity(0.5)),
          const SizedBox(height: 10),
          Text(
            'No coaches yet',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your first coach to get started',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 10, color: _textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachCard(
      CoachModel coach,
      AdminProvider provider,
      dynamic currentAdmin,
      bool canManageCoaches,
      ) {
    final isCurrentUser = currentAdmin?.uid == coach.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _cardBg,
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _redAccent, width: 1.5),
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: Center(
                    child: Text(
                      coach.initials,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    coach.fullName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isCurrentUser) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: _redAccent.withOpacity(0.15),
                                    ),
                                    child: Text(
                                      'YOU',
                                      style: GoogleFonts.poppins(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: _redAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: coach.isActive
                                  ? Colors.green.withOpacity(0.1)
                                  : _textGrey.withOpacity(0.1),
                              border: Border.all(
                                color: coach.isActive
                                    ? Colors.green.withOpacity(0.3)
                                    : _textGrey.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: coach.isActive
                                        ? Colors.green
                                        : _textGrey,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  coach.isActive ? 'ACTIVE' : 'INACTIVE',
                                  style: GoogleFonts.poppins(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color: coach.isActive
                                        ? Colors.green
                                        : _textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email_outlined,
                              size: 10, color: _textGrey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              coach.email,
                              style: GoogleFonts.poppins(
                                  fontSize: 9, color: _textGrey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          if (coach.sportFocus.isNotEmpty &&
                              coach.sportFocus != 'All')
                            _buildMiniInfo(Icons.sports_mma_outlined,
                                coach.sportFocus),
                          if (coach.branch.isNotEmpty)
                            _buildMiniInfo(Icons.location_on_outlined,
                                coach.branch),
                          if (coach.phone.isNotEmpty)
                            _buildMiniInfo(
                                Icons.phone_outlined, coach.phone),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildRoleBadge(coach.role),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: _textGrey),
              ],
            ),
          ),

          if (canManageCoaches && !isCurrentUser)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: _borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.security_outlined,
                      label: 'Permissions',
                      color: _textGrey,
                      onTap: () => _showPermissionsDialog(provider, coach),
                    ),
                  ),
                  Container(width: 1, height: 20, color: _borderColor),
                  Expanded(
                    child: _buildActionButton(
                      icon: coach.isActive
                          ? Icons.block_outlined
                          : Icons.check_circle_outline,
                      label: coach.isActive ? 'Disable' : 'Enable',
                      color: _redAccent,
                      onTap: () => _toggleStatus(provider, coach),
                    ),
                  ),
                  Container(width: 1, height: 20, color: _borderColor),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      color: _redAccent,
                      onTap: () => _deleteCoach(provider, coach),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9, color: _textGrey),
        const SizedBox(width: 2),
        Text(
          text,
          style: GoogleFonts.poppins(fontSize: 9, color: _textGrey),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    final isHead = role.toUpperCase().contains('HEAD');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: _redAccent.withOpacity(0.1),
        border: Border.all(color: _redAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isHead ? Icons.star : Icons.person_outline,
              size: 9, color: _redAccent),
          const SizedBox(width: 4),
          Text(
            role.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: _redAccent,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // ===== ADD COACH DIALOG (Birebir korundu) =====
  void _showCoachDialog(AdminProvider provider, dynamic currentAdmin) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final sportController = TextEditingController();

    String selectedRole = 'Coach';
    String? selectedBranchId;
    bool obscurePassword = true;
    final Set<String> selectedPermissions = {};

    final roles = ['Head Coach', 'Coach', 'Manager', 'Reception'];
    final activeBranches =
    provider.branches.where((b) => b.isActive).toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            if (selectedBranchId == null && activeBranches.isNotEmpty) {
              selectedBranchId = activeBranches.first.id;
            }

            return AlertDialog(
              backgroundColor: _darkBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _borderColor),
              ),
              title: Row(
                children: [
                  Icon(Icons.person_add_alt_1_outlined,
                      color: _redAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Add New Coach',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('FULL NAME *'),
                      _buildTextField(
                          controller: nameController,
                          hint: 'e.g., Ahmed Mohamed',
                          icon: Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildFieldLabel('EMAIL *'),
                      _buildTextField(
                          controller: emailController,
                          hint: 'coach@t2academy.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      _buildFieldLabel('PASSWORD *'),
                      _buildPasswordField(
                        controller: passwordController,
                        obscure: obscurePassword,
                        onToggle: () => setDialogState(
                                () => obscurePassword = !obscurePassword),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('PHONE'),
                                _buildTextField(
                                    controller: phoneController,
                                    hint: '+20 100...',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('SPORT FOCUS'),
                                _buildTextField(
                                    controller: sportController,
                                    hint: 'e.g., Kickboxing',
                                    icon: Icons.sports_mma_outlined),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('ROLE *'),
                                _buildDropdown<String>(
                                  value: selectedRole,
                                  items: roles,
                                  labelBuilder: (r) => r,
                                  onChanged: (value) => setDialogState(
                                          () => selectedRole = value),
                                  icon: Icons.workspace_premium_outlined,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('BRANCH'),
                                activeBranches.isEmpty
                                    ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                    BorderRadius.circular(10),
                                    color: _cardBg,
                                    border: Border.all(
                                        color: _redAccent
                                            .withOpacity(0.3)),
                                  ),
                                  child: Text('No active branches',
                                      style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: _redAccent)),
                                )
                                    : _buildBranchDropdown(
                                  branches: activeBranches,
                                  selectedId: selectedBranchId,
                                  onChanged: (id) => setDialogState(
                                          () => selectedBranchId = id),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                          'PERMISSIONS (${selectedPermissions.length})',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: _textGrey,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: _cardBg,
                          border: Border.all(color: _borderColor),
                        ),
                        child: Column(
                          children:
                          CoachPermissions.labels.entries.map((entry) {
                            final key = entry.key;
                            final label = entry.value;
                            final isSelected =
                            selectedPermissions.contains(key);

                            return _buildPermissionTile(
                              key: key,
                              label: label,
                              description:
                              CoachPermissions.descriptions[key] ?? '',
                              isSelected: isSelected,
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val) {
                                    selectedPermissions.add(key);
                                  } else {
                                    selectedPermissions.remove(key);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: _textGrey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty ||
                        emailController.text.trim().isEmpty ||
                        passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Name, email, and password are required'),
                          backgroundColor: AppConstants.ember,
                        ),
                      );
                      return;
                    }
                    if (passwordController.text.length < 6) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content:
                          Text('Password must be at least 6 characters'),
                          backgroundColor: AppConstants.ember,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    final branchName = selectedBranchId != null
                        ? activeBranches
                        .where((b) => b.id == selectedBranchId)
                        .map((b) => b.name)
                        .firstOrNull ??
                        ''
                        : '';

                    try {
                      await provider.createCoach(
                        fullName: nameController.text.trim(),
                        email: emailController.text.trim(),
                        password: passwordController.text,
                        phone: phoneController.text.trim(),
                        role: selectedRole,
                        sportFocus: sportController.text.trim(),
                        branch: branchName,
                        permissions: selectedPermissions.toList(),
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Coach added successfully'),
                            backgroundColor: AppConstants.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e
                                .toString()
                                .replaceAll('Exception: ', '')),
                            backgroundColor: AppConstants.ember,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('CREATE',
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: GoogleFonts.poppins(
            fontSize: 9,
            color: _textGrey,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _cardBg,
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _textGrey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style:
              GoogleFonts.poppins(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                GoogleFonts.poppins(fontSize: 11, color: _textGrey),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _cardBg,
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 14, color: _textGrey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style:
              GoogleFonts.poppins(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Min 6 characters',
                hintStyle:
                GoogleFonts.poppins(fontSize: 11, color: _textGrey),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 14,
                color: _textGrey),
            onPressed: onToggle,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchDropdown({
    required List<BranchModel> branches,
    required String? selectedId,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: _cardBg,
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, size: 14, color: _textGrey),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedId,
                isExpanded: true,
                dropdownColor: _darkBg,
                icon: Icon(Icons.arrow_drop_down,
                    color: _textGrey, size: 16),
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.white),
                items: branches.map((branch) {
                  return DropdownMenuItem<String>(
                    value: branch.id,
                    child: Text(
                      branch.name,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required Function(T) onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: _cardBg,
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _textGrey),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                dropdownColor: _darkBg,
                icon: Icon(Icons.arrow_drop_down,
                    color: _textGrey, size: 16),
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.white),
                items: items.map((item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(labelBuilder(item)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) onChanged(val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required String key,
    required String label,
    required String description,
    required bool isSelected,
    required Function(bool) onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!isSelected),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isSelected ? _redAccent : Colors.transparent,
                border: Border.all(
                    color: isSelected ? _redAccent : _textGrey, width: 1),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          color:
                          isSelected ? Colors.white : _textGrey)),
                  if (description.isNotEmpty)
                    Text(description,
                        style: GoogleFonts.poppins(
                            fontSize: 8,
                            color: _textGrey.withOpacity(0.6))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionsDialog(AdminProvider provider, CoachModel coach) {
    final Set<String> selectedPermissions = Set.from(coach.permissions);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: _darkBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _borderColor),
              ),
              title: Text('Edit Permissions',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              content: Container(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${selectedPermissions.length} selected',
                              style: GoogleFonts.poppins(
                                  fontSize: 10, color: _textGrey)),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                if (selectedPermissions.length ==
                                    CoachPermissions.labels.length) {
                                  selectedPermissions.clear();
                                } else {
                                  selectedPermissions.clear();
                                  selectedPermissions.addAll(
                                      CoachPermissions.labels.keys);
                                }
                              });
                            },
                            child: Text(
                              selectedPermissions.length ==
                                  CoachPermissions.labels.length
                                  ? 'Clear All'
                                  : 'Select All',
                              style: GoogleFonts.poppins(
                                  fontSize: 10, color: _redAccent),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: _cardBg,
                          border: Border.all(color: _borderColor),
                        ),
                        child: Column(
                          children:
                          CoachPermissions.labels.entries.map((entry) {
                            final key = entry.key;
                            final isSelected =
                            selectedPermissions.contains(key);
                            return _buildPermissionTile(
                              key: key,
                              label: entry.value,
                              description:
                              CoachPermissions.descriptions[key] ?? '',
                              isSelected: isSelected,
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val) {
                                    selectedPermissions.add(key);
                                  } else {
                                    selectedPermissions.remove(key);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: _textGrey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await provider.updateCoachPermissions(
                        coach.uid, selectedPermissions.toList());
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Permissions updated',
                              style: GoogleFonts.poppins(fontSize: 11)),
                          backgroundColor: Colors.green));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                  ),
                  child: Text('SAVE',
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleStatus(AdminProvider provider, CoachModel coach) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _darkBg,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: _borderColor)),
          title: Text(coach.isActive ? 'Disable Coach' : 'Enable Coach',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.white)),
          content: Text(
            coach.isActive
                ? 'Disable "${coach.fullName}"?'
                : 'Enable "${coach.fullName}"?',
            style:
            GoogleFonts.poppins(fontSize: 11, color: _textGrey),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: _textGrey))),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: coach.isActive
                      ? AppConstants.ember
                      : AppConstants.green),
              child: Text(coach.isActive ? 'Disable' : 'Enable',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      await provider.toggleCoachStatus(coach.uid, !coach.isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Status updated',
                style: GoogleFonts.poppins(fontSize: 11)),
            backgroundColor:
            coach.isActive ? AppConstants.ember : AppConstants.green));
      }
    }
  }

  Future<void> _deleteCoach(AdminProvider provider, CoachModel coach) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _darkBg,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                  color: AppConstants.ember.withOpacity(0.5))),
          title: Text('Delete Coach',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.white)),
          content: Text(
              'Are you sure you want to delete "${coach.fullName}"?',
              style:
              GoogleFonts.poppins(fontSize: 11, color: _textGrey)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: _textGrey))),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.ember),
              child: Text('Delete',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      await provider.deleteCoach(coach.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Coach deleted',
                style: GoogleFonts.poppins(fontSize: 11)),
            backgroundColor: AppConstants.ember));
      }
    }
  }
}

// ================================================================
// ============ CUSTOM CALENDAR DIALOG (Dark + Red Accent) ========
// ================================================================
class _CustomCalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  const _CustomCalendarDialog({required this.initialDate});

  @override
  State<_CustomCalendarDialog> createState() =>
      _CustomCalendarDialogState();
}

class _CustomCalendarDialogState extends State<_CustomCalendarDialog> {
  late DateTime _month;
  late DateTime _selected;

  static const Color _red = Color(0xFFE50914);
  static const Color _dark = Color(0xFF0F1115);

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.initialDate.year, widget.initialDate.month, 1);
    _selected = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    final firstDay = DateTime(_month.year, _month.month, 1);
    final firstWeekday = firstDay.weekday; // 1=Mon ... 7=Sun
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final selectedKey =
    DateTime(_selected.year, _selected.month, _selected.day);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _dark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _red.withOpacity(0.35), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: _red.withOpacity(0.15),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _red.withOpacity(0.3), width: 0.5),
                  ),
                  child: Icon(Icons.calendar_month_rounded,
                      size: 16, color: _red),
                ),
                const SizedBox(width: 12),
                Text(
                  'SELECT DATE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: _red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // MONTH NAV
            Row(
              children: [
                _navBtn(Icons.chevron_left_rounded, () {
                  setState(() {
                    _month = DateTime(_month.year, _month.month - 1, 1);
                  });
                }),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy').format(_month),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                _navBtn(Icons.chevron_right_rounded, () {
                  setState(() {
                    _month = DateTime(_month.year, _month.month + 1, 1);
                  });
                }),
              ],
            ),
            const SizedBox(height: 14),

            // WEEKDAY LABELS
            Row(
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
                return Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // DAYS GRID
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                final dayNum = index - firstWeekday + 2;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const SizedBox();
                }
                final date =
                DateTime(_month.year, _month.month, dayNum);
                final isSelected = DateUtils.isSameDay(date, selectedKey);
                final isToday = DateUtils.isSameDay(date, todayKey);

                return GestureDetector(
                  onTap: () => setState(() => _selected = date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected
                          ? LinearGradient(
                        colors: [
                          _red.withOpacity(0.95),
                          _red.withOpacity(0.55),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      border: isToday && !isSelected
                          ? Border.all(
                          color: _red.withOpacity(0.5), width: 1)
                          : null,
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: _red.withOpacity(0.4),
                          blurRadius: 10,
                        ),
                      ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNum',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : isToday
                            ? _red
                            : Colors.white70,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),

            // ACTIONS
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                    onTap: () => Navigator.pop(context, _selected),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                        'SELECT',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
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
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, size: 14, color: Colors.white70),
      ),
    );
  }
}
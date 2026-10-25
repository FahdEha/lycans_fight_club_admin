import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/coach_model.dart';
import '../providers/admin_provider.dart';

// ============================================================
// ==================== REWARD TYPE META ======================
// ============================================================
class _RT {
  final String key;
  final String label;
  final String short;
  final IconData icon;
  final Color color;

  const _RT(this.key, this.label, this.short, this.icon, this.color);
}

const List<_RT> _types = [
  _RT('bonus', 'Performance Bonus', 'BONUS', Icons.trending_up_rounded,
      Color(0xFF00D26A)),
  _RT('award', 'Achievement Award', 'AWARD',
      Icons.workspace_premium_rounded, Color(0xFFD4AF37)),
  _RT('gift', 'Gift', 'GIFT', Icons.redeem_rounded, Color(0xFFA855F7)),
  _RT('certificate', 'Certificate', 'CERT', Icons.verified_rounded,
      Color(0xFF3B82F6)),
  _RT('recognition', 'Recognition', 'RECOG', Icons.favorite_rounded,
      Color(0xFFEC4899)),
  _RT('discount', 'Discount', 'DISC', Icons.local_offer_rounded,
      Color(0xFFF59E0B)),
  _RT('penalty', 'Penalty', 'PENALTY', Icons.trending_down_rounded,
      Color(0xFFEF4444)),
];

_RT _metaOf(String? key) =>
    _types.firstWhere((t) => t.key == key, orElse: () => _types.first);

// ============================================================
// ===================== MAIN SCREEN ==========================
// ============================================================
class CoachesRewardsScreen extends StatefulWidget {
  const CoachesRewardsScreen({super.key});

  @override
  State<CoachesRewardsScreen> createState() => _CoachesRewardsScreenState();
}

class _CoachesRewardsScreenState extends State<CoachesRewardsScreen> {
  String? _selectedCoachUid; // null = all coaches (full view)
  String _filter = 'all';
  String _searchQuery = '';

  static const Color _bg1 = Color(0xFF0A0A0A);
  static const Color _bg2 = Color(0xFF0F0F12);
  static const Color _card = Color(0xFF141418);
  static const Color _card2 = Color(0xFF1A1A1F);
  static const Color _red = Color(0xFFE50914);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _green = Color(0xFF00D26A);
  static const Color _textDim = Color(0xFF8A8A95);
  static const Color _border = Color(0xFF222228);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final admin = provider.admin;
    if (admin == null) return const SizedBox.shrink();

    // ===== PERMISSION LOGIC =====
// Owner / Head Coach veya manageRewards → tüm coach'ları ve reward'ları görür
// viewRewards (sadece view) veya hiç permission → sadece kendini görür
    final isOwnerOrHead =
        admin.role == 'Owner' || admin.role == 'Head Coach';
    final canManageRewards =
    admin.permissions.contains(CoachPermissions.manageRewards);
    final canSeeAll = isOwnerOrHead || canManageRewards;
    final canGiveReward = canSeeAll; // FAB ve give butonu için aynı

// ===== DATA =====
    final allCoaches = provider.coaches;
    final allRewards = provider.coachRewards;

    final visibleCoaches = canSeeAll
        ? allCoaches
        : allCoaches.where((c) => c.uid == admin.uid).toList();

    final visibleRewards = canSeeAll
        ? allRewards
        : allRewards
        .where((r) => r['coachUid'] == admin.uid)
        .toList();

    // Filtered rewards
    final filteredRewards = visibleRewards.where((r) {
      // Coach filter
      if (_selectedCoachUid != null &&
          r['coachUid'] != _selectedCoachUid) {
        return false;
      }
      // Type filter
      if (_filter != 'all' && r['type'] != _filter) return false;
      // Search
      if (_searchQuery.isNotEmpty) {
        final t = r['title']?.toString().toLowerCase() ?? '';
        final n = r['coachName']?.toString().toLowerCase() ?? '';
        final q = _searchQuery.toLowerCase();
        if (!t.contains(q) && !n.contains(q)) return false;
      }
      return true;
    }).toList();

    // Stats
    final totalRewards = visibleRewards.length;
    final totalBonus = visibleRewards
        .where((r) => r['type'] == 'bonus')
        .fold<double>(
        0, (s, r) => s + ((r['amount'] as num?)?.toDouble() ?? 0));
    final now = DateTime.now();
    final thisMonth = visibleRewards.where((r) {
      final d = DateTime.tryParse(r['date']?.toString() ?? '');
      return d != null && d.year == now.year && d.month == now.month;
    }).length;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bg1, _bg2],
        ),
      ),
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // ===== HEADER =====
                _buildHeader(admin, canSeeAll),

                // ===== STATS STRIP =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStatsStrip(
                      totalRewards, totalBonus, thisMonth),
                ),

                // ===== COACH CAROUSEL (sadece full view) =====
                if (canSeeAll && visibleCoaches.length > 1) ...[
                  const SizedBox(height: 16),
                  _buildCoachCarousel(visibleCoaches, visibleRewards),
                ],

                // ===== FILTER BAR =====
                const SizedBox(height: 14),
                _buildFilterBar(),

                // ===== FEED =====
                const SizedBox(height: 10),
                Expanded(
                  child: filteredRewards.isEmpty
                      ? _buildEmptyState(canSeeAll)
                      : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: filteredRewards.length,
                    itemBuilder: (_, i) =>
                        _buildFeedItem(filteredRewards[i], canSeeAll),
                  ),
                ),
              ],
            ),
          ),

          // ===== FAB (sadece manage permission) =====
          if (canGiveReward)
            Positioned(
              right: 20,
              bottom: 20,
              child: _buildFab(),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // ====================== HEADER ==============================
  // ============================================================
  Widget _buildHeader(dynamic admin, bool canSeeAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Coaches ',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Rewards',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: _gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  canSeeAll
                      ? 'Recognition · Bonuses · Discounts'
                      : 'Your personal rewards',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _textDim,
                  ),
                ),
              ],
            ),
          ),
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _card2,
              border: Border.all(color: _border, width: 1),
            ),
            child: Center(
              child: Text(
                admin.initials ?? 'AD',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ================== STATS STRIP =============================
  // ============================================================
  Widget _buildStatsStrip(
      int total, double bonusTotal, int thisMonth) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statItem(
              'TOTAL',
              '$total',
              Icons.emoji_events_rounded,
              _gold,
            ),
          ),
          _vDivider(),
          Expanded(
            child: _statItem(
              'BONUS',
              '${NumberFormat('#,##0').format(bonusTotal)}',
              Icons.payments_rounded,
              _green,
            ),
          ),
          _vDivider(),
          Expanded(
            child: _statItem(
              'THIS MONTH',
              '$thisMonth',
              Icons.calendar_today_rounded,
              _red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: _textDim,
          ),
        ),
      ],
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      height: 32,
      color: _border,
    );
  }

  // ============================================================
  // ================== COACH CAROUSEL ==========================
  // ============================================================
  Widget _buildCoachCarousel(List coaches, List rewards) {
    return SizedBox(
      height: 92,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: coaches.length + 1, // +1 for "All"
        itemBuilder: (context, index) {
          if (index == 0) {
            // ALL chip
            final selected = _selectedCoachUid == null;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _selectedCoachUid = null),
                child: _coachChip(
                  initials: 'ALL',
                  name: 'Everyone',
                  count: rewards.length,
                  selected: selected,
                  isAll: true,
                ),
              ),
            );
          }

          final coach = coaches[index - 1];
          final coachRewardCount =
              rewards.where((r) => r['coachUid'] == coach.uid).length;
          final selected = _selectedCoachUid == coach.uid;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedCoachUid = selected ? null : coach.uid;
              }),
              child: _coachChip(
                initials: coach.initials,
                name: coach.fullName,
                count: coachRewardCount,
                selected: selected,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _coachChip({
    required String initials,
    required String name,
    required int count,
    required bool selected,
    bool isAll = false,
  }) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: selected
                      ? LinearGradient(
                    colors: [
                      _red.withOpacity(0.9),
                      _red.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                  color: selected ? null : _card2,
                  border: Border.all(
                    color: selected
                        ? _red.withOpacity(0.9)
                        : _border,
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected
                      ? [
                    BoxShadow(
                      color: _red.withOpacity(0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                      : null,
                ),
                child: Center(
                  child: isAll
                      ? Icon(
                    Icons.groups_rounded,
                    size: 20,
                    color: selected ? Colors.white : _textDim,
                  )
                      : Text(
                    initials,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : _textDim,
                    ),
                  ),
                ),
              ),
              // Count badge
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: _gold,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _bg2, width: 2),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            name.split(' ').first,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : _textDim,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ================== FILTER BAR ==============================
  // ============================================================
  Widget _buildFilterBar() {
    final chips = [
      {'key': 'all', 'label': 'All'},
      {'key': 'bonus', 'label': 'Bonuses'},
      {'key': 'award', 'label': 'Awards'},
      {'key': 'gift', 'label': 'Gifts'},
      {'key': 'discount', 'label': 'Discounts'},
      {'key': 'penalty', 'label': 'Penalties'},
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = chips[i];
          final selected = _filter == c['key'];
          return GestureDetector(
            onTap: () => setState(() => _filter = c['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? Colors.white : _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? Colors.white : _border,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  c['label']!,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight:
                    selected ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: 0.3,
                    color: selected ? Colors.black : _textDim,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // ================== FEED ITEM ===============================
  // ============================================================
  Widget _buildFeedItem(Map<String, dynamic> reward, bool canSeeAll) {
    final meta = _metaOf(reward['type']?.toString());
    final title = reward['title']?.toString() ?? '';
    final description = reward['description']?.toString() ?? '';
    final coachName = reward['coachName']?.toString() ?? '';
    final coachRole = reward['coachRole']?.toString() ?? '';
    final givenBy = reward['givenBy']?.toString() ?? '';
    final amount = (reward['amount'] as num?)?.toDouble() ?? 0;
    final discountPercent =
        (reward['discountPercent'] as num?)?.toDouble() ?? 0;
    final date = reward['date']?.toString() ?? '';

    String amountDisplay = '';
    if (amount > 0) {
      final prefix = reward['type'] == 'penalty' ? '-' : '+';
      amountDisplay = '$prefix${NumberFormat('#,##0').format(amount)}';
    } else if (discountPercent > 0) {
      amountDisplay = '${discountPercent.toStringAsFixed(0)}%';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Color strip
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: meta.color,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14)),
                boxShadow: [
                  BoxShadow(
                    color: meta.color.withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: type + date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: meta.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(meta.icon,
                                  size: 9, color: meta.color),
                              const SizedBox(width: 4),
                              Text(
                                meta.short,
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: meta.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _fmtDate(date),
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: _textDim,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Coach (sadece full view)
                    if (canSeeAll) ...[
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _card2,
                              border: Border.all(color: _border),
                            ),
                            child: Center(
                              child: Text(
                                _initialsOf(coachName),
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    coachName,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (coachRole.isNotEmpty) ...[
                                  const SizedBox(width: 5),
                                  Text(
                                    '· ${coachRole.toUpperCase()}',
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: _red.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Title row with amount on right
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    color: _textDim,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (amountDisplay.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: meta.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: meta.color.withOpacity(0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              amountDisplay,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: meta.color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Footer
                    if (givenBy.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 10, color: _textDim),
                          const SizedBox(width: 5),
                          Text(
                            'Given by ',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              color: _textDim,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              givenBy,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ===================== FAB ==================================
  // ============================================================
  Widget _buildFab() {
    return GestureDetector(
      onTap: () => _openGiveSheet(),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 18, color: Colors.black),
            const SizedBox(width: 6),
            Text(
              'REWARD',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // =================== EMPTY STATE ============================
  // ============================================================
  Widget _buildEmptyState(bool canSeeAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _card,
                border: Border.all(color: _border, width: 1),
              ),
              child: Icon(Icons.emoji_events_outlined,
                  size: 32, color: _textDim),
            ),
            const SizedBox(height: 16),
            Text(
              canSeeAll ? 'No rewards yet' : 'No rewards for you yet',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              canSeeAll
                  ? 'Give your first reward to a coach'
                  : 'Your rewards will appear here',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ================== HELPERS =================================
  // ============================================================
  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return DateFormat('dd MMM yyyy').format(d);
  }

  String _initialsOf(String name) {
    if (name.isEmpty) return '??';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  // ============================================================
  // ================== GIVE REWARD SHEET =======================
  // ============================================================
  void _openGiveSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _GiveRewardSheet(),
    );
  }
}

// ============================================================
// ================== GIVE REWARD SHEET =======================
// ============================================================
class _GiveRewardSheet extends StatefulWidget {
  const _GiveRewardSheet();

  @override
  State<_GiveRewardSheet> createState() => _GiveRewardSheetState();
}

class _GiveRewardSheetState extends State<_GiveRewardSheet> {
  String? _coachUid;
  String? _coachName;
  String? _coachRole;
  String _type = 'bonus';
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _saving = false;

  static const Color _bg = Color(0xFF0F0F12);
  static const Color _card = Color(0xFF141418);
  static const Color _border = Color(0xFF222228);
  static const Color _red = Color(0xFFE50914);
  static const Color _textDim = Color(0xFF8A8A95);

  bool get _needsAmount =>
      _type == 'bonus' || _type == 'penalty' || _type == 'gift';
  bool get _needsPercent => _type == 'discount';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final coaches = provider.coaches;
    final meta = _metaOf(_type);

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: meta.color.withOpacity(0.12),
                      border: Border.all(
                          color: meta.color.withOpacity(0.35), width: 1),
                    ),
                    child:
                    Icon(meta.icon, size: 16, color: meta.color),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Give Reward',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'To a team member',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: _textDim,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Coach selector
                    _label('RECIPIENT'),
                    const SizedBox(height: 8),
                    if (coaches.isEmpty)
                      _emptyBox('No coaches available')
                    else
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: coaches.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final c = coaches[i];
                            final selected = c.uid == _coachUid;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _coachUid = c.uid;
                                _coachName = c.fullName;
                                _coachRole = c.role;
                              }),
                              child: AnimatedContainer(
                                duration:
                                const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.white
                                      : _card,
                                  borderRadius:
                                  BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? Colors.white
                                        : _border,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: selected
                                            ? Colors.black
                                            .withOpacity(0.1)
                                            : _border,
                                      ),
                                      child: Center(
                                        child: Text(
                                          c.initials,
                                          style: GoogleFonts.inter(
                                            fontSize: 7,
                                            fontWeight:
                                            FontWeight.w800,
                                            color: selected
                                                ? Colors.black
                                                : Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      c.fullName.split(' ').first,
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: selected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: selected
                                            ? Colors.black
                                            : Colors.white70,
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

                    // Type grid
                    _label('TYPE'),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: _types.length,
                      itemBuilder: (context, i) {
                        final t = _types[i];
                        final selected = _type == t.key;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _type = t.key;
                            _amountCtrl.clear();
                          }),
                          child: AnimatedContainer(
                            duration:
                            const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: selected
                                  ? t.color.withOpacity(0.12)
                                  : _card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? t.color
                                    : _border,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Icon(
                                  t.icon,
                                  size: 16,
                                  color: selected
                                      ? t.color
                                      : _textDim,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  t.short,
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: selected
                                        ? Colors.white
                                        : _textDim,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),

                    // Title
                    _label('TITLE'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _titleCtrl,
                      hint: _suggestTitle(),
                    ),
                    const SizedBox(height: 14),

                    // Description
                    _label('DESCRIPTION (optional)'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _descCtrl,
                      hint: 'Add context...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),

                    // Amount
                    if (_needsAmount) ...[
                      _label(_type == 'penalty'
                          ? 'PENALTY AMOUNT (EGP)'
                          : 'AMOUNT (EGP)'),
                      const SizedBox(height: 8),
                      _field(
                        controller: _amountCtrl,
                        hint: '0',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (_needsPercent) ...[
                      _label('DISCOUNT (%)'),
                      const SizedBox(height: 8),
                      _field(
                        controller: _amountCtrl,
                        hint: '20',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                    ],
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 10, 20, MediaQuery.of(context).padding.bottom + 14),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border, width: 1),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: _textDim,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _saving ? null : _save,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: meta.color,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: meta.color.withOpacity(0.35),
                              blurRadius: 14,
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
                              const Icon(Icons.check_rounded,
                                  size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              _saving ? 'SAVING...' : 'GIVE REWARD',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) {
    return Text(
      t,
      style: GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
        color: _textDim,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _border, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          GoogleFonts.inter(fontSize: 11, color: _textDim),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(11),
        border:
        Border.all(color: Colors.orange.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            text,
            style:
            GoogleFonts.inter(fontSize: 10.5, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  String _suggestTitle() {
    switch (_type) {
      case 'bonus':
        return 'Monthly performance bonus';
      case 'award':
        return 'Coach of the month';
      case 'gift':
        return 'New training gear';
      case 'certificate':
        return 'Certification awarded';
      case 'recognition':
        return 'Outstanding dedication';
      case 'discount':
        return 'Personal training discount';
      case 'penalty':
        return 'Late attendance penalty';
      default:
        return 'Reward title';
    }
  }

  Future<void> _save() async {
    if (_coachUid == null || _coachName == null) {
      _snack('Please select a recipient');
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Please enter a title');
      return;
    }

    double amount = 0;
    double discountPercent = 0;

    if (_needsAmount) {
      amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
      if (amount <= 0) {
        _snack('Please enter a valid amount');
        return;
      }
    } else if (_needsPercent) {
      discountPercent = double.tryParse(_amountCtrl.text.trim()) ?? 0;
      if (discountPercent <= 0 || discountPercent > 100) {
        _snack('Discount must be 1-100');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      await provider.giveCoachReward(
        coachUid: _coachUid!,
        coachName: _coachName!,
        coachRole: _coachRole ?? '',
        type: _type,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        amount: amount,
        discountPercent: discountPercent,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reward given to $_coachName',
            style: GoogleFonts.inter(fontSize: 11),
          ),
          backgroundColor: const Color(0xFF00D26A),
        ),
      );
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 11)),
        backgroundColor: _red,
      ),
    );
  }
}
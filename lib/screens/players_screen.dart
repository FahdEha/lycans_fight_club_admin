import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';
import '../models/player_model.dart';
import 'player_detail_screen.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  String _searchQuery = '';
  String _filter = 'All';
  final List<String> _filters = ['All', 'Active', 'Expired', 'Frozen'];
  bool _showPending = false;

  final Color generalGlassDark = const Color(0xFF0F1115).withOpacity(0.5);
  final Color glassBorder = Colors.white.withOpacity(0.04);
  final Color primaryRed = const Color(0xFFE50914);
  final Color textDim = Colors.white.withOpacity(0.5);

  Future<int> _reserveNextPlayerNumber() async {
    final ref = FirebaseDatabase.instance.ref('counters/player_number');
    final result = await ref.runTransaction((current) {
      final val = (current as num?)?.toInt() ?? 9;
      return Transaction.success(val + 1);
    });
    final value = result.snapshot.value;
    return (value is num) ? value.toInt() : 10;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final pendingUsers = provider.pendingUsers;
    final pendingCount = pendingUsers
        .where((p) => (p['status'] ?? 'pending') == 'pending')
        .length;

    final players = provider.players.where((p) {
      final matchesSearch = p.fullName
          .toLowerCase()
          .contains(_searchQuery.toLowerCase()) ||
          p.phone.contains(_searchQuery);
      final matchesFilter =
          _filter == 'All' || _getPlayerStatus(provider, p) == _filter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/players_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: _buildSegmentedTabs(pendingCount),
            ),
            if (!_showPending) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: _buildSearchBar(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._filters.map((filter) => _buildFilterChip(filter)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildAddPlayerButton(provider),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: players.isEmpty
                    ? Center(
                  child: Text(
                    'No players found',
                    style: GoogleFonts.inter(fontSize: 12, color: textDim),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    return _buildPlayerCard(provider, player);
                  },
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Expanded(
                child: pendingUsers.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 36, color: textDim),
                      const SizedBox(height: 10),
                      Text(
                        'No pending requests',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: textDim),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  itemCount: pendingUsers.length,
                  itemBuilder: (context, index) {
                    final pu = pendingUsers[index];
                    return _buildPendingUserCard(provider, pu);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============ SEGMENTED TABS ============
  Widget _buildSegmentedTabs(int pendingCount) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _showPending = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: !_showPending ? null : generalGlassDark,
                gradient: !_showPending
                    ? RadialGradient(
                  center: Alignment.center,
                  radius: 2.5,
                  colors: [
                    Colors.transparent,
                    primaryRed.withOpacity(0.35),
                  ],
                  stops: const [0.2, 1.0],
                )
                    : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !_showPending
                      ? primaryRed.withOpacity(0.6)
                      : glassBorder,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_alt_outlined,
                      size: 14,
                      color: !_showPending ? Colors.white : textDim),
                  const SizedBox(width: 8),
                  Text(
                    'PLAYERS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: !_showPending ? Colors.white : textDim,
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
            onTap: () => setState(() => _showPending = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: _showPending ? null : generalGlassDark,
                gradient: _showPending
                    ? RadialGradient(
                  center: Alignment.center,
                  radius: 2.5,
                  colors: [
                    Colors.transparent,
                    primaryRed.withOpacity(0.35),
                  ],
                  stops: const [0.2, 1.0],
                )
                    : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _showPending
                      ? primaryRed.withOpacity(0.6)
                      : glassBorder,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pending_actions_rounded,
                      size: 14,
                      color: _showPending ? Colors.white : textDim),
                  const SizedBox(width: 8),
                  Text(
                    'PENDING',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: _showPending ? Colors.white : textDim,
                    ),
                  ),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryRed,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryRed.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        '$pendingCount',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============ PENDING USER CARD ============
  Widget _buildPendingUserCard(
      AdminProvider provider, Map<String, dynamic> pu) {
    final status = (pu['status'] ?? 'pending').toString();
    final isDisabled = status == 'disabled';
    final fullName = (pu['fullName'] ?? '').toString();
    final phone = (pu['phone'] ?? '').toString();
    final sport = (pu['sport'] ?? '').toString();
    final level = (pu['level'] ?? '').toString();
    final weightClass = (pu['weightClass'] ?? '').toString();
    final playerNumber = (pu['playerNumber'] as num?)?.toInt() ?? 0;
    final uid = (pu['uid'] ?? '').toString();
    final initials = fullName.isNotEmpty
        ? fullName
        .trim()
        .split(' ')
        .take(2)
        .map((p) => p.isNotEmpty ? p[0] : '')
        .join()
        .toUpperCase()
        : '??';

    final statusColor = isDisabled ? Colors.orange : const Color(0xFF00C853);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: generalGlassDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: glassBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0F1115),
                        border: Border.all(
                            color: primaryRed.withOpacity(0.4), width: 0.5),
                      ),
                      child: Center(
                        child: playerNumber > 0
                            ? Text(
                          '#$playerNumber',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          initials,
                          style: GoogleFonts.inter(
                            fontSize: 12,
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
                          Text(
                            fullName.isEmpty ? 'Unknown' : fullName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined,
                                  size: 10, color: textDim),
                              const SizedBox(width: 4),
                              Text(
                                phone.isEmpty ? '—' : phone,
                                style: GoogleFonts.inter(
                                    fontSize: 10.5, color: textDim),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${sport.isEmpty ? "—" : sport} · ${level.isEmpty ? "—" : level} · ${weightClass.isEmpty ? "—" : weightClass}',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: textDim),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withOpacity(0.35),
                            width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isDisabled ? 'DISABLED' : 'PENDING',
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showActivateDialog(provider, pu),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryRed.withOpacity(0.9),
                                primaryRed.withOpacity(0.65),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: primaryRed.withOpacity(0.25),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  size: 12, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                'ACTIVATE',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            _handleToggleDisable(provider, uid, isDisabled),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.35),
                                width: 0.5),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isDisabled
                                    ? Icons.play_arrow_rounded
                                    : Icons.pause_rounded,
                                size: 12,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isDisabled ? 'ENABLE' : 'DISABLE',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _confirmRemovePending(provider, pu),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 9, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.redAccent.withOpacity(0.35),
                              width: 0.5),
                        ),
                        child: const Icon(Icons.delete_outline,
                            size: 14, color: Colors.redAccent),
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
  }

  Future<void> _handleToggleDisable(
      AdminProvider provider, String uid, bool isDisabled) async {
    await provider.disablePendingUser(uid, !isDisabled);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDisabled ? 'User re-enabled' : 'User disabled',
            style: GoogleFonts.inter(fontSize: 11),
          ),
          backgroundColor:
          isDisabled ? const Color(0xFF00C853) : Colors.orange,
        ),
      );
    }
  }

  void _confirmRemovePending(
      AdminProvider provider, Map<String, dynamic> pu) {
    final fullName = (pu['fullName'] ?? 'this user').toString();
    final uid = (pu['uid'] ?? '').toString();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 34),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1115),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.redAccent.withOpacity(0.4), width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent.withOpacity(0.12),
                    border: Border.all(
                        color: Colors.redAccent.withOpacity(0.4), width: 1),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 24),
                ),
                const SizedBox(height: 16),
                Text(
                  'REMOVE REQUEST',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Remove $fullName\'s pending registration? This cannot be undone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: textDim, height: 1.5),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(dialogContext),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: glassBorder),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'CANCEL',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: textDim,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(dialogContext);
                          await provider.removePendingUser(uid);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Request removed',
                                    style:
                                    GoogleFonts.inter(fontSize: 11)),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.redAccent.withOpacity(0.5)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'REMOVE',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: Colors.redAccent,
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
      },
    );
  }

  // ============ ACTIVATE DIALOG (Group eklendi) ============
  void _showActivateDialog(AdminProvider provider, Map<String, dynamic> pu) {
    final packages = provider.packages;
    final classes = provider.classes; // YENİ: Group için
    final fullName = (pu['fullName'] ?? '').toString();
    final phone = (pu['phone'] ?? '').toString();
    final sport = (pu['sport'] ?? '').toString();
    final level = (pu['level'] ?? '').toString();
    final weightClass = (pu['weightClass'] ?? '').toString();
    final playerNumber = (pu['playerNumber'] as num?)?.toInt() ?? 0;

    String? selectedPackageId =
    packages.isNotEmpty ? packages.first.id : null;
    final amountCtrl = TextEditingController(
      text: packages.isNotEmpty
          ? packages.first.price.toStringAsFixed(0)
          : '',
    );
    String paymentMethod = 'Cash';
    final paymentMethods = ['Cash', 'InstaPay', 'Visa'];

    // YENİ: Group state
    String? selectedGroupId = classes.isNotEmpty ? classes.first.id : null;
    String? selectedGroupName =
    classes.isNotEmpty ? classes.first.className : null;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setStateSB) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1115),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: primaryRed.withOpacity(0.4), width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: primaryRed.withOpacity(0.15),
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
                      // HEADER
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryRed.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: primaryRed.withOpacity(0.35),
                                  width: 0.5),
                            ),
                            child: Icon(Icons.person_add_alt_1,
                                size: 16, color: primaryRed),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ACTIVATE PLAYER',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.8,
                                    color: primaryRed,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  fullName.isEmpty ? 'Unknown' : fullName,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // PLAYER INFO
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: glassBorder),
                        ),
                        child: Column(
                          children: [
                            if (playerNumber > 0)
                              _buildInfoRow(
                                  Icons.tag, 'NUMBER', '#$playerNumber'),
                            _buildInfoRow(Icons.phone_outlined, 'PHONE',
                                phone.isEmpty ? '—' : phone),
                            _buildInfoRow(Icons.sports_martial_arts, 'SPORT',
                                sport.isEmpty ? '—' : sport),
                            _buildInfoRow(Icons.trending_up, 'LEVEL',
                                level.isEmpty ? '—' : level),
                            _buildInfoRow(Icons.fitness_center, 'WEIGHT',
                                weightClass.isEmpty ? '—' : weightClass),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // MEMBERSHIP SECTION LABEL
                      Row(
                        children: [
                          Container(
                              width: 16,
                              height: 1.5,
                              color: primaryRed),
                          const SizedBox(width: 8),
                          Text(
                            'CREATE MEMBERSHIP',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // PACKAGE
                      Text(
                        'Package',
                        style:
                        GoogleFonts.inter(fontSize: 10, color: textDim),
                      ),
                      const SizedBox(height: 6),
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
                                  'No packages found. Add a package first.',
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: primaryRed.withOpacity(0.25)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedPackageId,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0F1115),
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
                                          color: primaryRed,
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
                      const SizedBox(height: 14),

                      // ===== GROUP (YENİ) =====
                      Row(
                        children: [
                          Icon(Icons.groups_outlined,
                              size: 12, color: primaryRed),
                          const SizedBox(width: 6),
                          Text(
                            'Group',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: textDim),
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
                                  'No classes available. Add a class first.',
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: primaryRed.withOpacity(0.25)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedGroupId,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0F1115),
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
                                            color: primaryRed,
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
                      const SizedBox(height: 14),

                      // AMOUNT
                      Text(
                        'Amount (EGP)',
                        style:
                        GoogleFonts.inter(fontSize: 10, color: textDim),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: glassBorder),
                        ),
                        child: TextField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
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
                      const SizedBox(height: 14),

                      // PAYMENT METHOD
                      Text(
                        'Payment Method',
                        style:
                        GoogleFonts.inter(fontSize: 10, color: textDim),
                      ),
                      const SizedBox(height: 8),
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
                                    ? primaryRed.withOpacity(0.12)
                                    : Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryRed.withOpacity(0.6)
                                      : glassBorder,
                                  width: isSelected ? 1 : 0.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                  BoxShadow(
                                    color: primaryRed
                                        .withOpacity(0.2),
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
                                        ? primaryRed
                                        : textDim,
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
                                          : textDim,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),

                      // BUTTONS
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(dialogContext),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 13),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                  Border.all(color: glassBorder),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'CANCEL',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                    color: textDim,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final selectedPkg = packages
                                    .where((p) =>
                                p.id == selectedPackageId)
                                    .firstOrNull;
                                if (selectedPkg == null) {
                                  ScaffoldMessenger.of(dialogContext)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Please select a package',
                                          style: GoogleFonts.inter(
                                              fontSize: 11)),
                                      backgroundColor: primaryRed,
                                    ),
                                  );
                                  return;
                                }
                                final amount = double.tryParse(
                                    amountCtrl.text.trim()) ??
                                    0;
                                if (amount <= 0) {
                                  ScaffoldMessenger.of(dialogContext)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Please enter a valid amount',
                                          style: GoogleFonts.inter(
                                              fontSize: 11)),
                                      backgroundColor: primaryRed,
                                    ),
                                  );
                                  return;
                                }

                                Navigator.pop(dialogContext);

                                await provider.activatePendingUser(
                                  pendingUser: pu,
                                  packageId: selectedPkg.id,
                                  packageName: selectedPkg.name,
                                  packagePrice: amount,
                                  packageDurationDays:
                                  selectedPkg.durationDays > 0
                                      ? selectedPkg.durationDays
                                      : 30,
                                  isUnlimited: selectedPkg.isUnlimited,
                                  maxSessions: selectedPkg.maxSessions,
                                  weeklySessions:
                                  selectedPkg.weeklySessions,
                                  paymentMethod: paymentMethod,
                                  groupId: selectedGroupId,       // YENİ
                                  groupName: selectedGroupName,   // YENİ
                                );

                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        selectedGroupName != null
                                            ? '$fullName activated · ${selectedPkg.name} · Group: $selectedGroupName'
                                            : '$fullName activated · ${selectedPkg.name}',
                                        style: GoogleFonts.inter(
                                            fontSize: 11),
                                      ),
                                      backgroundColor:
                                      const Color(0xFF00C853),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 13),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryRed.withOpacity(0.95),
                                      primaryRed.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius:
                                  BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryRed.withOpacity(0.3),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'ACTIVATE',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
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
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 12, color: textDim),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: textDim,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'Cash': return Icons.payments_outlined;
      case 'InstaPay': return Icons.bolt_rounded;
      case 'Visa': return Icons.credit_card;
      default: return Icons.payment;
    }
  }

  // ==================== MEVCUT METODLAR ====================
  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: generalGlassDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: glassBorder, width: 0.5),
          ),
          child: Row(
            children: [
              Icon(Icons.search,
                  size: 16, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  onChanged: (value) =>
                      setState(() => _searchQuery = value),
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search players...',
                    hintStyle:
                    GoogleFonts.inter(fontSize: 12, color: textDim),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _filter == filter;
    Widget icon;
    if (filter == 'All') {
      icon = Icon(Icons.people_alt_outlined,
          size: 13, color: isSelected ? Colors.white : textDim);
    } else if (filter == 'Frozen') {
      icon = Icon(Icons.ac_unit,
          size: 11, color: isSelected ? Colors.white : textDim);
    } else {
      Color dotColor =
      filter == 'Active' ? const Color(0xFF00C853) : Colors.grey;
      icon = Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          color: dotColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: dotColor.withOpacity(0.5), blurRadius: 4),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? null : generalGlassDark,
          gradient: isSelected
              ? RadialGradient(
            center: Alignment.center,
            radius: 1.8,
            colors: [
              Colors.transparent,
              primaryRed.withOpacity(0.35),
            ],
            stops: const [0.3, 1.0],
          )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
            isSelected ? primaryRed.withOpacity(0.6) : glassBorder,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              filter,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight:
                isSelected ? FontWeight.w500 : FontWeight.w400,
                color: isSelected ? Colors.white : textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPlayerButton(AdminProvider provider) {
    return GestureDetector(
      onTap: () => _showAddPlayerDialog(provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 2.5,
            colors: [
              Colors.transparent,
              primaryRed.withOpacity(0.4),
            ],
            stops: const [0.2, 1.0],
          ),
          borderRadius: BorderRadius.circular(12),
          border:
          Border.all(color: primaryRed.withOpacity(0.5), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'ADD PLAYER',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(AdminProvider provider, PlayerModel player) {
    final status = _getPlayerStatus(provider, player);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: Container(
            decoration: BoxDecoration(
              color: generalGlassDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: glassBorder, width: 0.5),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 14,
                  bottom: 14,
                  child: Container(
                    width: 2.5,
                    decoration: BoxDecoration(
                      color: primaryRed,
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(4)),
                      boxShadow: [
                        BoxShadow(
                          color: primaryRed.withOpacity(0.8),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            _showEditNumberDialog(provider, player),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0F1115),
                            border: Border.all(
                                color:
                                primaryRed.withOpacity(0.4),
                                width: 0.5),
                          ),
                          child: Center(
                            child: Text(
                              player.displayBadge,
                              style: GoogleFonts.inter(
                                fontSize:
                                player.playerNumber > 0 ? 13 : 12,
                                fontWeight: player.playerNumber > 0
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                letterSpacing: player.playerNumber > 0
                                    ? -0.3
                                    : 0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.fullName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${player.sport} · ${player.level} · ${player.phone}',
                              style: GoogleFonts.inter(
                                  fontSize: 10.5, color: textDim),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildStatusTag(status),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    PlayerDetailScreen(player: player)),
                          );
                        },
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 16, color: textDim),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    Color color;
    Color borderColor;
    switch (status) {
      case 'Active':
        color = const Color(0xFF00C853);
        borderColor = color.withOpacity(0.3);
        break;
      case 'Expired':
        color = Colors.grey;
        borderColor = color.withOpacity(0.3);
        break;
      case 'Frozen':
        color = Colors.blue;
        borderColor = color.withOpacity(0.3);
        break;
      default:
        color = Colors.grey;
        borderColor = color.withOpacity(0.2);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: generalGlassDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.6), blurRadius: 3),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getPlayerStatus(AdminProvider provider, PlayerModel player) {
    final playerMemberships = provider.memberships
        .where((m) => m['userId'] == player.uid)
        .toList();
    if (playerMemberships.isEmpty) return 'Frozen';
    playerMemberships.sort((a, b) {
      final aDate = DateTime.parse(
          a['endDate'] ?? DateTime.now().toIso8601String());
      final bDate = DateTime.parse(
          b['endDate'] ?? DateTime.now().toIso8601String());
      return bDate.compareTo(aDate);
    });
    final latest = playerMemberships.first;
    final isFrozen = latest['isFrozen'] ?? false;
    final isActive = latest['isActive'] ?? false;
    final endDate = DateTime.parse(
        latest['endDate'] ?? DateTime.now().toIso8601String());
    final now = DateTime.now();
    if (isFrozen || !isActive) return 'Frozen';
    if (endDate.isBefore(now)) return 'Expired';
    return 'Active';
  }

  void _showEditNumberDialog(AdminProvider provider, PlayerModel player) {
    final controller = TextEditingController(
      text: player.playerNumber > 0 ? player.playerNumber.toString() : '',
    );
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1115),
              borderRadius: BorderRadius.circular(20),
              border:
              Border.all(color: primaryRed.withOpacity(0.3), width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: primaryRed.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: primaryRed.withOpacity(0.3),
                            width: 0.5),
                      ),
                      child:
                      Icon(Icons.numbers, size: 16, color: primaryRed),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PLAYER NUMBER',
                              style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                  color: primaryRed)),
                          const SizedBox(height: 2),
                          Text(player.fullName,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (player.playerNumber > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Current: ',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: textDim)),
                        Text('#${player.playerNumber}',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: primaryRed.withOpacity(0.4), width: 0.5),
                  ),
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 2),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '00',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.15),
                          letterSpacing: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(dialogContext),
                        child: Container(
                          padding:
                          const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: glassBorder),
                          ),
                          alignment: Alignment.center,
                          child: Text('CANCEL',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                  color: textDim)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final text = controller.text.trim();
                          if (text.isEmpty) return;
                          final newNumber = int.tryParse(text);
                          if (newNumber == null || newNumber < 1) {
                            ScaffoldMessenger.of(dialogContext)
                                .showSnackBar(SnackBar(
                                content: Text(
                                    'Please enter a valid number',
                                    style: GoogleFonts.inter(
                                        fontSize: 11)),
                                backgroundColor: primaryRed));
                            return;
                          }
                          if (newNumber == player.playerNumber) {
                            Navigator.pop(dialogContext);
                            return;
                          }
                          final matches = provider.players
                              .where((p) =>
                          p.uid != player.uid &&
                              p.playerNumber == newNumber)
                              .toList();
                          final conflicting =
                          matches.isEmpty ? null : matches.first;
                          Navigator.pop(dialogContext);
                          if (conflicting != null) {
                            _showNumberConflictDialog(
                                provider, player, conflicting, newNumber);
                          } else {
                            await provider.updatePlayer(
                                player.uid, {'playerNumber': newNumber});
                            if (mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                    '#${player.playerNumber} → #$newNumber for ${player.fullName}',
                                    style: GoogleFonts.inter(
                                        fontSize: 11)),
                                backgroundColor:
                                const Color(0xFF00C853),
                              ));
                            }
                          }
                        },
                        child: Container(
                          padding:
                          const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              primaryRed.withOpacity(0.9),
                              primaryRed.withOpacity(0.7),
                            ]),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                  color: primaryRed.withOpacity(0.3),
                                  blurRadius: 12),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text('SAVE',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNumberConflictDialog(AdminProvider provider,
      PlayerModel editingPlayer,
      PlayerModel conflictingPlayer,
      int newNumber) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1115),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.orange.withOpacity(0.4), width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.orange.withOpacity(0.4),
                            width: 0.5),
                      ),
                      child: const Icon(Icons.warning_amber_rounded,
                          size: 16, color: Colors.orange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NUMBER IN USE',
                              style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                  color: Colors.orange)),
                          const SizedBox(height: 2),
                          Text('Conflict detected',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: glassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                              fontSize: 11, color: textDim, height: 1.5),
                          children: [
                            TextSpan(
                                text:
                                '#$newNumber is already assigned to '),
                            TextSpan(
                                text: conflictingPlayer.fullName,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildConflictPlayerChip(
                                'YOU',
                                editingPlayer.playerNumber,
                                editingPlayer.fullName,
                                primaryRed),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.swap_horiz_rounded,
                                size: 18, color: Colors.white38),
                          ),
                          Expanded(
                            child: _buildConflictPlayerChip(
                                'OTHER',
                                conflictingPlayer.playerNumber,
                                conflictingPlayer.fullName,
                                Colors.orange),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    final oldNumber = editingPlayer.playerNumber;
                    await provider.updatePlayer(editingPlayer.uid,
                        {'playerNumber': newNumber});
                    await provider.updatePlayer(conflictingPlayer.uid,
                        {'playerNumber': oldNumber});
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Swapped: #$oldNumber ↔ #$newNumber',
                            style: GoogleFonts.inter(fontSize: 11)),
                        backgroundColor: const Color(0xFF00C853),
                      ));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        primaryRed.withOpacity(0.9),
                        primaryRed.withOpacity(0.6),
                      ]),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: primaryRed.withOpacity(0.3),
                            blurRadius: 12),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.swap_horiz_rounded,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text('REPLACE',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Swap numbers with ${conflictingPlayer.fullName}',
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                color: Colors.white.withOpacity(0.7)),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await provider.updatePlayer(
                        editingPlayer.uid, {'playerNumber': newNumber});
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Assigned #$newNumber to ${editingPlayer.fullName} (duplicate allowed)',
                            style: GoogleFonts.inter(fontSize: 11)),
                        backgroundColor: const Color(0xFF00C853),
                      ));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.flash_on_rounded,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text('OVERRIDE',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Both players can share #$newNumber',
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                color: Colors.white.withOpacity(0.6)),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(dialogContext),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    alignment: Alignment.center,
                    child: Text('CANCEL',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                            color: textDim)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConflictPlayerChip(
      String label, int number, String name, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: color)),
          const SizedBox(height: 4),
          Text(number > 0 ? '#$number' : '—',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text(name,
              style: GoogleFonts.inter(fontSize: 9, color: textDim),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  void _showAddPlayerDialog(AdminProvider provider) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    String selectedSport = 'Kickboxing';
    String selectedLevel = 'Beginner';
    String selectedWeightClass = '63.5 kg';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F1115),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: glassBorder, width: 0.5),
          ),
          title: Text('Add Player',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(nameController, 'Full Name'),
                  const SizedBox(height: 12),
                  _buildDialogTextField(phoneController, 'Phone'),
                  const SizedBox(height: 12),
                  _buildDialogTextField(emailController, 'Email'),
                  const SizedBox(height: 12),
                  _buildDialogDropdown(
                    value: selectedSport,
                    label: 'Sport',
                    items: ['Kickboxing', 'Boxing', 'MMA', 'Muay Thai', 'Jiu-Jitsu'],
                    onChanged: (value) => selectedSport = value!,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogDropdown(
                    value: selectedLevel,
                    label: 'Level',
                    items: ['Beginner', 'Intermediate', 'Advanced', 'Professional'],
                    onChanged: (value) => selectedLevel = value!,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogDropdown(
                    value: selectedWeightClass,
                    label: 'Weight Class',
                    items: [
                      '55.0 kg', '57.5 kg', '60.0 kg', '63.5 kg',
                      '67.0 kg', '70.0 kg', '73.5 kg', '77.0 kg',
                      '81.0 kg', '85.0 kg', '90.0 kg+'
                    ],
                    onChanged: (value) => selectedWeightClass = value!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel',
                  style: GoogleFonts.inter(fontSize: 11, color: textDim)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    emailController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
                    content: Text('Name and email are required',
                        style: GoogleFonts.inter(fontSize: 11)),
                    backgroundColor: primaryRed,
                  ));
                  return;
                }
                Navigator.pop(dialogContext);
                try {
                  final credential = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: 'player123',
                  );
                  final uid = credential.user!.uid;
                  final now = DateTime.now();
                  int playerNumber = 0;
                  try {
                    playerNumber = await _reserveNextPlayerNumber();
                  } catch (_) {}
                  final player = PlayerModel(
                    uid: uid,
                    fullName: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    email: emailController.text.trim(),
                    sport: selectedSport,
                    level: selectedLevel,
                    weightClass: selectedWeightClass,
                    emergencyContact: nameController.text.trim(),
                    emergencyPhone: phoneController.text.trim(),
                    joinDate: now,
                    playerNumber: playerNumber,
                  );
                  await provider.updatePlayer(uid, player.toMap());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Player #$playerNumber added successfully',
                          style: GoogleFonts.inter(fontSize: 11)),
                      backgroundColor: const Color(0xFF00C853),
                    ));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e',
                          style: GoogleFonts.inter(fontSize: 11)),
                      backgroundColor: primaryRed,
                    ));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed.withOpacity(0.8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text('Add Player',
                  style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w500)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogTextField(
      TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 11, color: textDim),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: glassBorder, width: 0.5)),
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: primaryRed, width: 0.5)),
      ),
    );
  }

  Widget _buildDialogDropdown({
    required String value,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF0F1115),
      style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 11, color: textDim),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: glassBorder, width: 0.5)),
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: primaryRed, width: 0.5)),
      ),
      items:
      items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: onChanged,
    );
  }
}
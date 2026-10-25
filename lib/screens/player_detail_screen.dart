import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/PlanRequestModel.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';
import '../models/player_model.dart';

// --- TASARIM SABİTLERİ (Karanlık Tema ve Kırmızı Vurgular) ---
const Color _darkBg = Color(0xFF09090B);
final Color generalGlassDark = const Color(0xFF0F1115).withValues(alpha: 0.5);
final Color glassBorder = Colors.white.withValues(alpha: 0.04);
const Color _redAccent = Color(0xFFE50914);
const Color _redGlow = Color(0x4DE50914);
const Color _textMain = Color(0xFFFFFFFF);
const Color _textDim = Color(0xFFA1A1AA);
const Color _textFaint = Color(0xFF71717A);

class PlayerDetailScreen extends StatefulWidget {
  final PlayerModel player;
  const PlayerDetailScreen({super.key, required this.player});

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  int _currentTab = 0;
  DateTime _calendarMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _tabs = [
    {'name': 'Info', 'icon': Icons.person_outline},
    {'name': 'Membership', 'icon': Icons.workspace_premium_outlined},
    {'name': 'Attendance', 'icon': Icons.calendar_today_outlined},
    {'name': 'Payments', 'icon': Icons.payment_outlined},
    {'name': 'Progress', 'icon': Icons.bar_chart_outlined},
    {'name': 'Competition', 'icon': Icons.sports_mma_outlined},
    {'name': 'Notes', 'icon': Icons.notes_outlined},
  ];

  String _getBackgroundImage() {
    switch (_currentTab) {
      case 0:
      case 1:
        return 'assets/images/player_membership_info_bg.png';
      case 2:
      case 3:
        return 'assets/images/player_attendance_payments_bg.png';
      case 4:
        return 'assets/images/player_progress_bg.png';
      default:
        return 'assets/images/player_membership_info_bg.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final player = provider.players.where((p) => p.uid == widget.player.uid).firstOrNull ?? widget.player;

    return Scaffold(
      backgroundColor: _darkBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Image.asset(
                _getBackgroundImage(),
                key: ValueKey<String>(_getBackgroundImage()),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) => Container(color: _darkBg),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(player),
                _buildTabBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    child: _buildCurrentTab(provider, player),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== BAŞLIK VE TAB BAR =====================
  Widget _buildHeader(PlayerModel player) {
    final provider = Provider.of<AdminProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: _textMain, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: AssetImage('assets/images/lycans_png.png'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(color: _redAccent.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  player.fullName,
                  style: GoogleFonts.oswald(fontSize: 18, color: _textMain, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${player.sport} - ${player.level}',
                  style: GoogleFonts.poppins(fontSize: 10, color: _textDim, fontWeight: FontWeight.w300),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: _textMain, size: 20),
            onPressed: () => _showDeletePlayerDialog(provider, player),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            decoration: BoxDecoration(
              color: _darkBg.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: glassBorder),
            ),
            child: SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final isActive = _currentTab == index;
                  return GestureDetector(
                    onTap: () => setState(() => _currentTab = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isActive ? _redAccent.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive ? _redAccent.withValues(alpha: 0.8) : Colors.transparent,
                          width: 1,
                        ),
                        boxShadow: isActive ? [BoxShadow(color: _redGlow, blurRadius: 8)] : [],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          Icon(_tabs[index]['icon'], size: 12, color: isActive ? _textMain : _textDim),
                          const SizedBox(width: 4),
                          Text(
                            _tabs[index]['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: isActive ? _textMain : _textDim,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
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
        ),
      ),
    );
  }

  Widget _buildCurrentTab(AdminProvider provider, PlayerModel player) {
    switch (_currentTab) {
      case 0: return _buildInfoTab(provider, player);
      case 1: return _buildMembershipTab(provider, player);
      case 2: return _buildAttendanceTab(provider, player);
      case 3: return _buildPaymentsTab(provider, player);
      case 4: return _buildProgressTab(provider, player);
      case 5: return _buildCompetitionTab(provider, player);
      case 6: return _buildNotesTab(provider, player);
      default: return const SizedBox();
    }
  }

  // ===================== SİLME İŞLEMİ =====================
  void _showDeletePlayerDialog(AdminProvider provider, PlayerModel player) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _darkBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _redAccent.withValues(alpha: 0.5)),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_rounded, color: _redAccent, size: 22),
              const SizedBox(width: 8),
              Text(
                'Delete Player',
                style: GoogleFonts.oswald(fontSize: 18, color: _textMain, letterSpacing: 1),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to permanently delete ${player.fullName}?',
                style: GoogleFonts.poppins(fontSize: 12, color: _textMain, height: 1.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _redAccent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'This action cannot be undone. All data, memberships, attendance records, and the account will be deleted from the system.',
                  style: GoogleFonts.poppins(fontSize: 10, color: _redAccent, height: 1.4),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 11, color: _textDim)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Deleting player...', style: TextStyle(fontSize: 11)),
                    backgroundColor: Colors.orange
                ));

                await provider.deletePlayer(player.uid);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Player deleted successfully', style: TextStyle(fontSize: 11)),
                      backgroundColor: Colors.green
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('DELETE', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ===================== ORTAK KULLANILAN PLAN VE AKSİYON BUTONLARI =====================
  Widget _buildPlanAndActionButtons(AdminProvider provider, PlayerModel player, {required bool isInfoScreen}) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: provider.getMembershipStatus(player.uid),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final isActive = data?['isActive'] ?? false;
        final planName = data?['planName'] ?? 'CHAMPION PLAN';
        final groupName = data?['groupName'] as String?;
        final expiry = data != null ? DateTime.parse(data['endDate']) : DateTime.now();
        final start = data != null && data['startDate'] != null ? DateTime.parse(data['startDate']) : DateTime.now().subtract(const Duration(days: 30));

        String bgImage = isInfoScreen ? 'assets/images/info_plan_bg.png' : 'assets/images/membership_plan_bg.png';

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(image: AssetImage(bgImage), fit: BoxFit.cover),
                border: Border.all(color: glassBorder),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(planName.toUpperCase(), style: GoogleFonts.oswald(fontSize: 10, color: _redAccent, letterSpacing: 1)),
                      if (!isInfoScreen)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                          child: Text(isActive ? 'Active' : 'Frozen', style: GoogleFonts.poppins(fontSize: 8, color: isActive ? Colors.green : Colors.redAccent)),
                        )
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('30 Days Program', style: GoogleFonts.poppins(fontSize: 14, color: _textMain, fontWeight: FontWeight.bold)),
                  Text('INV - 17...', style: GoogleFonts.poppins(fontSize: 9, color: _textDim)),

                  if (groupName != null && groupName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.groups_outlined, size: 10, color: _redAccent),
                        const SizedBox(width: 4),
                        Text(
                          'Group: $groupName',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: _redAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 10, color: _textDim),
                          const SizedBox(width: 4),
                          Text('Start ${DateFormat('dd MMM yyyy').format(start)}  |  End ${DateFormat('dd MMM yyyy').format(expiry)}',
                              style: GoogleFonts.poppins(fontSize: 9, color: _textDim)),
                        ],
                      ),
                      InkWell(
                        onTap: () => _showRecordPaymentBottomSheet(provider, player),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: generalGlassDark,
                            border: Border.all(color: _redAccent.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.payment, size: 10, color: _textMain),
                              const SizedBox(width: 6),
                              Text('RECORD', style: GoogleFonts.poppins(fontSize: 8, color: _textMain, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (isInfoScreen)
              Row(
                children: [
                  Expanded(
                    child: isActive
                        ? _buildImageButton('FREEZE\nMEMBERSHIP', Icons.ac_unit, 'assets/images/freeze_bg.png', () => _showFreezeDialog(provider, player))
                        : _buildActionGlassButton('ACTIVATE\nMEMBERSHIP', Icons.play_arrow, Colors.greenAccent, () => provider.unfreezeMembership(player.uid)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildImageButton('EXTEND\nMEMBERSHIP', Icons.calendar_month, 'assets/images/extend_bg.png', () => _showExtendDialog(provider, player)),
                  ),
                ],
              )
            else
              Column(
                children: [
                  isActive
                      ? _buildMenuButton('Freeze Membership', Icons.ac_unit, () => _showFreezeDialog(provider, player))
                      : _buildMenuButtonActivate('Activate Membership', Icons.play_arrow, () => provider.unfreezeMembership(player.uid)),
                  const SizedBox(height: 8),
                  _buildMenuButton('Extend Membership', Icons.calendar_month, () => _showExtendDialog(provider, player)),
                ],
              ),
          ],
        );
      },
    );
  }

  // ===================== 1. INFO TAB =====================
  Widget _buildInfoTab(AdminProvider provider, PlayerModel player) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _redAccent.withValues(alpha: 0.4), blurRadius: 20)],
                  image: const DecorationImage(
                    image: AssetImage('assets/images/lycans_png.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEditableInfoRow(Icons.phone, 'Phone', player.phone, () => _editFieldDialog(provider, player, 'Phone', player.phone)),
                    _buildEditableInfoRow(Icons.fitness_center, 'Weight Class', player.weightClass, () => _editWeightClassDialog(provider, player)),
                    _buildEditableInfoRow(Icons.security, 'Emergency Contact', '${player.emergencyContact} - ${player.emergencyPhone}', () => _editEmergencyDialog(provider, player)),
                    _buildEditableInfoRow(Icons.person, 'Guardian', player.guardian.isEmpty ? 'Not applicable' : player.guardian, () => _editFieldDialog(provider, player, 'Guardian', player.guardian)),
                    _buildEditableInfoRow(Icons.star, 'Rank', player.rank, () => _editRankDialog(provider, player)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: _buildStatCard(Icons.fitness_center, 'Weight Class', player.weightClass)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard(Icons.star, 'Rank', player.rank)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard(Icons.sports_mma, 'Record', '${player.wins}W - ${player.losses}L - ${player.draws}D')),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard(Icons.emoji_events, 'Fitness Level', player.level, onTap: () => _editLevelDialog(provider, player))),
          ],
        ),
        const SizedBox(height: 16),

        _buildPlanAndActionButtons(provider, player, isInfoScreen: true),
        const SizedBox(height: 16),

        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: _buildLatestActivity(provider, player),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildProgressCard(player),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEditableInfoRow(IconData icon, String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: _textDim),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.poppins(fontSize: 8, color: _textFaint)),
                  Text(value, style: GoogleFonts.poppins(fontSize: 11, color: _textMain, fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: _GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          children: [
            Icon(icon, color: _redAccent, size: 18),
            const SizedBox(height: 6),
            Text(title, style: GoogleFonts.poppins(fontSize: 8, color: _textDim), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.poppins(fontSize: 10, color: _textMain, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildImageButton(String text, IconData icon, String assetPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(image: AssetImage(assetPath), fit: BoxFit.cover),
          border: Border.all(color: glassBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blueAccent, size: 18),
                const SizedBox(width: 10),
                Text(text, style: GoogleFonts.poppins(fontSize: 9, color: _textMain, fontWeight: FontWeight.w500)),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, size: 10, color: _textDim),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGlassButton(String text, IconData icon, Color glowColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: glowColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: glowColor.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: glowColor.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: glowColor, size: 18),
                const SizedBox(width: 10),
                Text(text, style: GoogleFonts.poppins(fontSize: 9, color: _textMain, fontWeight: FontWeight.w500)),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, size: 10, color: _textDim),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestActivity(AdminProvider provider, PlayerModel player) {
    final atts = provider.attendance.where((a) => a.userId == player.uid).toList()..sort((a,b) => b.timestamp.compareTo(a.timestamp));

    return _GlassCard(
      height: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.show_chart, size: 14, color: _redAccent),
                  const SizedBox(width: 6),
                  Text('Latest Activity', style: GoogleFonts.poppins(fontSize: 11, color: _textMain, fontWeight: FontWeight.w500)),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _currentTab = 2),
                child: Text('See All', style: GoogleFonts.poppins(fontSize: 9, color: _textDim)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (atts.isEmpty)
            Expanded(child: Center(child: Text('No recent activity', style: GoogleFonts.poppins(fontSize: 10, color: _textFaint))))
          else
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: atts.take(3).map((a) => _buildActivityRow(Icons.emoji_events, a.className, a.timestamp)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityRow(IconData icon, String title, DateTime time) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
          child: Icon(icon, size: 12, color: _textDim),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 10, color: _textMain)),
              Text(DateFormat('dd MMM yyyy · HH:mm').format(time), style: GoogleFonts.poppins(fontSize: 8, color: _textFaint)),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios, size: 8, color: _textFaint),
      ],
    );
  }

  Widget _buildProgressCard(PlayerModel player) {
    return _GlassCard(
      height: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, size: 14, color: _redAccent),
              const SizedBox(width: 6),
              Text('Progress', style: GoogleFonts.poppins(fontSize: 11, color: _textMain, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressItem('Weight', '${player.weight.toStringAsFixed(1)} kg'),
                _buildProgressItem('Height', '${player.height.toStringAsFixed(0)} cm'),
                _buildProgressItem('Class', player.weightClass),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 9, color: _textDim)),
        Text(value, style: GoogleFonts.poppins(fontSize: 11, color: _textMain, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ===================== 2. MEMBERSHIP TAB =====================
  Widget _buildMembershipTab(AdminProvider provider, PlayerModel player) {
    return Column(
      children: [
        _buildPlanAndActionButtons(provider, player, isInfoScreen: false),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMenuButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: _GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _textMain),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 12, color: _textMain))),
            const Icon(Icons.arrow_forward_ios, size: 12, color: _textDim),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButtonActivate(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.greenAccent),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 12, color: _textMain))),
                const Icon(Icons.arrow_forward_ios, size: 12, color: _textDim),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================== 3. ATTENDANCE TAB (Özel Takvim) =====================
  Widget _buildAttendanceTab(AdminProvider provider, PlayerModel player) {
    final atts = provider.attendance.where((a) => a.userId == player.uid).toList();

    int daysInMonth = DateUtils.getDaysInMonth(_calendarMonth.year, _calendarMonth.month);
    DateTime firstDayOfMonth = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    int firstWeekday = firstDayOfMonth.weekday;

    return Column(
      children: [
        _GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: _textMain, size: 14),
                    onPressed: () => setState(() => _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1)),
                  ),
                  Text(DateFormat('MMMM yyyy').format(_calendarMonth), style: GoogleFonts.poppins(fontSize: 12, color: _textMain, fontWeight: FontWeight.w500)),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: _textMain, size: 14),
                    onPressed: () => setState(() => _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) =>
                    SizedBox(width: 30, child: Text(d, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 9, color: _textDim)))
                ).toList(),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 10, crossAxisSpacing: 5),
                itemCount: 42,
                itemBuilder: (context, index) {
                  int dayNumber = index - firstWeekday + 2;
                  if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox();

                  DateTime date = DateTime(_calendarMonth.year, _calendarMonth.month, dayNumber);
                  bool isSelected = DateUtils.isSameDay(date, _selectedDate);
                  bool hasAttendance = atts.any((a) => DateUtils.isSameDay(a.timestamp, date));

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = date),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white.withValues(alpha: 0.3)) : null,
                      ),
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Text(dayNumber.toString(), style: GoogleFonts.poppins(fontSize: 11, color: isSelected ? _textMain : _textDim)),
                          if (hasAttendance)
                            Positioned(
                              bottom: -4,
                              child: Container(
                                width: 4, height: 4,
                                decoration: BoxDecoration(color: _redAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _redGlow, blurRadius: 4)]),
                              ),
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...atts.where((a) => DateUtils.isSameDay(a.timestamp, _selectedDate)).map((a) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.person, size: 16, color: _redAccent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.className, style: GoogleFonts.poppins(fontSize: 11, color: _textMain)),
                          Text(DateFormat('dd MMM yyyy · HH:mm').format(a.timestamp), style: GoogleFonts.poppins(fontSize: 9, color: _textDim)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 10, color: _textDim),
                  ],
                ),
              ),
            )
        ).toList(),
        if (atts.where((a) => DateUtils.isSameDay(a.timestamp, _selectedDate)).isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('No attendance for this day', style: GoogleFonts.poppins(fontSize: 10, color: _textFaint)),
          ),
      ],
    );
  }

  // ===================== 4. PAYMENTS TAB =====================
  Widget _buildPaymentsTab(AdminProvider provider, PlayerModel player) {
    final invoices = provider.invoices
        .where((i) => i.userId == player.uid)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== PENDING REQUESTS SECTION =====
        StreamBuilder<List<PlanRequestModel>>(
          stream: provider.getPlayerPlanRequests(player.uid),
          builder: (context, snapshot) {
            final allRequests = snapshot.data ?? [];
            final pendingRequests =
            allRequests.where((r) => r.status == 'pending').toList();

            if (pendingRequests.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.pending_actions_rounded,
                        size: 12,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PENDING REQUESTS',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${pendingRequests.length}',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...pendingRequests.map((request) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildPendingRequestCard(provider, request),
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          },
        ),

        // ===== CURRENT PLAN / RECORD PAYMENT =====
        _GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Record New Payment',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _textMain,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Manually record a payment for this player',
                style: GoogleFonts.poppins(fontSize: 10, color: _textDim),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _showRecordPaymentBottomSheet(provider, player),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: _redAccent.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.payment, size: 14, color: _textMain),
                      const SizedBox(width: 8),
                      Text(
                        'RECORD PAYMENT',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _textMain,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ===== PAYMENT HISTORY =====
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment History',
              style: GoogleFonts.poppins(fontSize: 12, color: _textMain),
            ),
            Text(
              '${invoices.length} total',
              style: GoogleFonts.poppins(fontSize: 9, color: _redAccent),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (invoices.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No payment history yet',
                style: GoogleFonts.poppins(fontSize: 10, color: _textFaint),
              ),
            ),
          )
        else
          ...invoices.map(
                (inv) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _GlassCard(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 16, color: _textMain),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.packageName,
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: _textMain),
                          ),
                          Text(
                            '${DateFormat('dd MMM yyyy').format(inv.date)} · ${inv.amount.toStringAsFixed(0)} EGP',
                            style: GoogleFonts.poppins(
                                fontSize: 9, color: _textDim),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Paid',
                        style: GoogleFonts.poppins(
                            fontSize: 9, color: Colors.green),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios,
                        size: 10, color: _textDim),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

// ===== PENDING REQUEST CARD =====
  Widget _buildPendingRequestCard(
      AdminProvider provider, PlanRequestModel request) {
    final isUpgrade = request.type == 'upgrade';
    final accentColor = isUpgrade ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.08),
            generalGlassDark,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUpgrade
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 9,
                      color: accentColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      request.type.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  DateFormat('dd MMM · HH:mm').format(request.createdAt),
                  style: GoogleFonts.poppins(
                      fontSize: 8, color: _textFaint),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: glassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FROM',
                        style: GoogleFonts.poppins(
                          fontSize: 7,
                          color: _textFaint,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.currentPackageName.isEmpty
                            ? '—'
                            : request.currentPackageName,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _textMain,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${request.currentPackagePrice.toStringAsFixed(0)} EGP',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          color: _textDim,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: _textFaint,
                ),
              ),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TO',
                        style: GoogleFonts.poppins(
                          fontSize: 7,
                          color: accentColor,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.requestedPackageName,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _textMain,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${request.requestedPackagePrice.toStringAsFixed(0)} EGP',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showDeclineConfirmDialog(provider, request),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.close_rounded,
                            size: 12, color: Colors.redAccent),
                        const SizedBox(width: 5),
                        Text(
                          'DECLINE',
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.redAccent,
                            letterSpacing: 0.8,
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
                  onTap: () => _showApproveConfirmDialog(provider, request),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.greenAccent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_rounded,
                            size: 12, color: Colors.greenAccent),
                        const SizedBox(width: 5),
                        Text(
                          'APPROVE',
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.greenAccent,
                            letterSpacing: 0.8,
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
    );
  }

// ===== APPROVE CONFIRM DIALOG =====
  void _showApproveConfirmDialog(
      AdminProvider provider, PlanRequestModel request) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _darkBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.4)),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.greenAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Approve Request',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textMain,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Approve this ${request.type} request?',
                style: GoogleFonts.poppins(fontSize: 11, color: _textDim),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: generalGlassDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requestedPackageName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${request.requestedPackagePrice.toStringAsFixed(0)} EGP · ${request.requestedPackageDurationDays} days',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: _textDim,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 12, color: Colors.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'You will need to assign a group in the next step.',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.orange,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(fontSize: 11, color: _textDim),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showChooseGroupForApproveSheet(provider, request);
              },
              icon: const Icon(Icons.check, size: 14),
              label: Text(
                'CONTINUE',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ===== GRUP SEÇME BOTTOM SHEET =====
  void _showChooseGroupForApproveSheet(AdminProvider provider, PlanRequestModel request) {
    final classes = provider.classes;
    String? selectedGroupId = classes.isNotEmpty ? classes.first.id : null;
    String? selectedGroupName = classes.isNotEmpty ? classes.first.className : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: _darkBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('APPROVE REQUEST', style: GoogleFonts.oswald(fontSize: 16, color: _textMain, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text('Choose the group for ${request.playerName} before approving.', style: GoogleFonts.poppins(fontSize: 11, color: _textDim)),
                  const SizedBox(height: 20),

                  Text('Group / Class', style: GoogleFonts.poppins(fontSize: 10, color: _textDim)),
                  const SizedBox(height: 4),
                  if (classes.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Text('No groups available. You can still approve.', style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange)),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _redAccent.withValues(alpha: 0.3)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedGroupId,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1A1A1E),
                          style: GoogleFonts.poppins(fontSize: 11, color: _textMain),
                          icon: const Icon(Icons.keyboard_arrow_down, color: _textDim, size: 18),
                          items: classes.map((c) {
                            return DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(c.className),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setSheetState(() {
                              selectedGroupId = val;
                              final c = classes.where((x) => x.id == val).firstOrNull;
                              selectedGroupName = c?.className;
                            });
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(sheetContext);

                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Approving and assigning group...', style: TextStyle(fontSize: 11)), backgroundColor: Colors.green));

                        await provider.approvePlanRequest(request);

                        await FirebaseDatabase.instance.ref('plan_requests/${request.id}').remove();

                        if (selectedGroupId != null && selectedGroupName != null) {
                          try {
                            final snap = await FirebaseDatabase.instance
                                .ref('memberships')
                                .orderByChild('userId')
                                .equalTo(request.userId)
                                .get();
                            if (snap.exists && snap.value != null) {
                              final map = snap.value as Map;
                              String? latestMembershipId;
                              int latestTimestamp = 0;
                              map.forEach((key, value) {
                                final data = value as Map;
                                final startStr = data['startDate']?.toString() ?? '';
                                final timestamp = DateTime.tryParse(startStr)?.millisecondsSinceEpoch ?? 0;
                                if (timestamp > latestTimestamp) {
                                  latestTimestamp = timestamp;
                                  latestMembershipId = key;
                                }
                              });
                              if (latestMembershipId != null) {
                                await FirebaseDatabase.instance.ref('memberships/$latestMembershipId').update({
                                  'groupId': selectedGroupId,
                                  'groupName': selectedGroupName,
                                });
                              }
                            }
                          } catch (e) {
                            debugPrint('Error updating membership group: $e');
                          }
                        }

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${request.playerName} approved successfully', style: GoogleFonts.poppins(fontSize: 11)),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('APPROVE & ASSIGN', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

// ===== DECLINE CONFIRM DIALOG =====
  void _showDeclineConfirmDialog(
      AdminProvider provider, PlanRequestModel request) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _darkBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.redAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Decline Request',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textMain,
                ),
              ),
            ],
          ),
          content: Text(
            'Decline ${request.playerName}\'s ${request.type} request for ${request.requestedPackageName}?',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: _textDim,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(fontSize: 11, color: _textDim),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await provider.declinePlanRequest(request);
                await FirebaseDatabase.instance.ref('plan_requests/${request.id}').remove();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Request declined and removed',
                        style: GoogleFonts.poppins(fontSize: 11),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.close, size: 14),
              label: Text(
                'DECLINE',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ===================== KALAN TABLAR =====================
  Widget _buildProgressTab(AdminProvider provider, PlayerModel player) {
    return Column(
      children: [
        _GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildEditableInfoRow(Icons.monitor_weight, 'Weight', '${player.weight.toStringAsFixed(1)} kg', () => _editProgressFieldDialog(provider, player, 'Weight', player.weight.toString())),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              _buildEditableInfoRow(Icons.height, 'Height', '${player.height.toStringAsFixed(0)} cm', () => _editProgressFieldDialog(provider, player, 'Height', player.height.toString())),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              _buildEditableInfoRow(Icons.fitness_center, 'Weight Class', player.weightClass, () => _editWeightClassDialog(provider, player)),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              _buildEditableInfoRow(Icons.emoji_events, 'Level', player.level, () => _editLevelDialog(provider, player)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompetitionTab(AdminProvider provider, PlayerModel player) {
    return const Center(child: Text('Competition module matching new design', style: TextStyle(color: Colors.white, fontSize: 10)));
  }

  Widget _buildNotesTab(AdminProvider provider, PlayerModel player) {
    return const Center(child: Text('Notes module matching new design', style: TextStyle(color: Colors.white, fontSize: 10)));
  }

  // ===================== MODERN DİYALOGLAR (BOTTOM SHEETS) =====================
  void _editFieldDialog(AdminProvider provider, PlayerModel player, String field, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    _showModernBottomSheet(
      title: 'Edit $field',
      child: _buildModernTextField(controller, field),
      onSave: () async {
        if(field == 'Phone') await provider.updatePlayer(player.uid, {'phone': controller.text});
        if(field == 'Email') await provider.updatePlayer(player.uid, {'email': controller.text});
        if(field == 'Guardian') await provider.updatePlayer(player.uid, {'guardian': controller.text});
        if (!mounted) return;
        Navigator.pop(context);
      },
    );
  }

  void _editProgressFieldDialog(AdminProvider provider, PlayerModel player, String field, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    _showModernBottomSheet(
      title: 'Edit $field',
      child: _buildModernTextField(controller, field, isNumber: true),
      onSave: () async {
        if(field == 'Weight') await provider.updatePlayer(player.uid, {'weight': double.tryParse(controller.text) ?? player.weight});
        if(field == 'Height') await provider.updatePlayer(player.uid, {'height': double.tryParse(controller.text) ?? player.height});
        if (!mounted) return;
        Navigator.pop(context);
      },
    );
  }

  void _editEmergencyDialog(AdminProvider provider, PlayerModel player) {
    final nameCtrl = TextEditingController(text: player.emergencyContact);
    final phoneCtrl = TextEditingController(text: player.emergencyPhone);
    _showModernBottomSheet(
      title: 'Emergency Contact',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModernTextField(nameCtrl, 'Name'),
          const SizedBox(height: 12),
          _buildModernTextField(phoneCtrl, 'Phone', isNumber: true),
        ],
      ),
      onSave: () async {
        await provider.updatePlayer(player.uid, {'emergencyContact': nameCtrl.text, 'emergencyPhone': phoneCtrl.text});
        if (!mounted) return;
        Navigator.pop(context);
      },
    );
  }

  void _editWeightClassDialog(AdminProvider provider, PlayerModel player) {
    String selected = player.weightClass;
    final options = ['55.0 kg', '57.5 kg', '60.0 kg', '63.5 kg', '67.0 kg', '70.0 kg', '73.5 kg', '77.0 kg', '81.0 kg', '85.0 kg', '90.0 kg+'];
    _showModernBottomSheet(
      title: 'Weight Class',
      child: StatefulBuilder(builder: (context, setStateSB) {
        return _buildModernDropdown(selected, options, (val) => setStateSB(() => selected = val!));
      }),
      onSave: () async {
        await provider.updatePlayer(player.uid, {'weightClass': selected});
        if (!mounted) return;
        Navigator.pop(context);
      },
    );
  }

  void _editLevelDialog(AdminProvider provider, PlayerModel player) {
    String selected = player.level;
    final options = ['Beginner', 'Intermediate', 'Advanced', 'Professional'];
    _showModernBottomSheet(
      title: 'Fitness Level',
      child: StatefulBuilder(builder: (context, setStateSB) {
        return _buildModernDropdown(selected, options, (val) => setStateSB(() => selected = val!));
      }),
      onSave: () async {
        await provider.updatePlayerLevel(player.uid, selected);
        if (!mounted) return;
        Navigator.pop(context);
      },
    );
  }

  void _editRankDialog(AdminProvider provider, PlayerModel player) {
    String selected = player.rank;
    // 100'e kadar spinner
    final options = List.generate(100, (i) => (i + 1).toString().padLeft(2, '0'));
    _showModernBottomSheet(
      title: 'Rank',
      child: StatefulBuilder(builder: (context, setStateSB) {
        return _buildModernDropdown(selected, options, (val) => setStateSB(() => selected = val!));
      }),
      onSave: () async {
        await provider.updatePlayer(player.uid, {'rank': selected});
        if (!mounted) return;
        Navigator.pop(context);
      },
    );
  }

  void _showFreezeDialog(AdminProvider provider, PlayerModel player) {
    String selected = '7';
    final options = ['7', '14', '21', '30'];
    _showModernBottomSheet(
      title: 'Freeze Membership',
      child: StatefulBuilder(builder: (context, setStateSB) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration (Days)', style: GoogleFonts.poppins(fontSize: 10, color: _textDim)),
            const SizedBox(height: 6),
            _buildModernDropdown(selected, options, (val) => setStateSB(() => selected = val!)),
          ],
        );
      }),
      onSave: () async {
        await provider.freezeMembership(player.uid);
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Frozen successfully', style: TextStyle(fontSize: 10)), backgroundColor: Colors.blue));
      },
    );
  }

  void _showExtendDialog(AdminProvider provider, PlayerModel player) {
    String selected = '30';
    final options = ['7', '14', '30', '60', '90'];
    _showModernBottomSheet(
      title: 'Extend Membership',
      child: StatefulBuilder(builder: (context, setStateSB) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Days to add', style: GoogleFonts.poppins(fontSize: 10, color: _textDim)),
            const SizedBox(height: 6),
            _buildModernDropdown(selected, options, (val) => setStateSB(() => selected = val!)),
          ],
        );
      }),
      onSave: () async {
        await provider.extendMembership(player.uid, int.parse(selected));
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Extended successfully', style: TextStyle(fontSize: 10)), backgroundColor: Colors.green));
      },
    );
  }

  // ===================== RECORD PAYMENT =====================
  void _showRecordPaymentBottomSheet(AdminProvider provider, PlayerModel player) {
    final packages = provider.packages;
    if (packages.isEmpty) return;

    final classes = provider.classes;

    String? selectedPackageId = packages.first.id;
    final amountCtrl = TextEditingController(text: packages.first.price.toStringAsFixed(0));
    String method = 'Cash';

    String? selectedGroupId = classes.isNotEmpty ? classes.first.id : null;
    String? selectedGroupName = classes.isNotEmpty ? classes.first.className : null;

    _showModernBottomSheet(
      title: 'Record Payment',
      child: StatefulBuilder(builder: (context, setStateSB) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Package', style: GoogleFonts.poppins(fontSize: 10, color: _textDim)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedPackageId,
                  isExpanded: true,
                  dropdownColor: _darkBg,
                  style: GoogleFonts.poppins(fontSize: 11, color: _textMain),
                  items: packages.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} - ${p.price.toStringAsFixed(0)} EGP'))).toList(),
                  onChanged: (val) {
                    setStateSB(() {
                      selectedPackageId = val;
                      final p = packages.where((x) => x.id == val).firstOrNull;
                      if(p != null) amountCtrl.text = p.price.toStringAsFixed(0);
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Icon(Icons.groups_outlined, size: 12, color: _redAccent),
                const SizedBox(width: 6),
                Text('Group', style: GoogleFonts.poppins(fontSize: 10, color: _textDim)),
              ],
            ),
            const SizedBox(height: 4),
            if (classes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No classes available. Add a class first.',
                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _redAccent.withValues(alpha: 0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedGroupId,
                    isExpanded: true,
                    dropdownColor: _darkBg,
                    icon: const Icon(Icons.keyboard_arrow_down, color: _textDim, size: 18),
                    style: GoogleFonts.poppins(fontSize: 11, color: _textMain),
                    items: classes.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.id,
                        child: Row(
                          children: [
                            const Icon(Icons.sports_martial_arts, size: 12, color: _textDim),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.className,
                                style: GoogleFonts.poppins(fontSize: 11, color: _textMain),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setStateSB(() {
                        selectedGroupId = val;
                        final c = classes.where((x) => x.id == val).firstOrNull;
                        selectedGroupName = c?.className;
                      });
                    },
                  ),
                ),
              ),
            const SizedBox(height: 12),

            _buildModernTextField(amountCtrl, 'Amount (EGP)', isNumber: true),
            const SizedBox(height: 12),

            Text('Method', style: GoogleFonts.poppins(fontSize: 10, color: _textDim)),
            const SizedBox(height: 4),
            _buildModernDropdown(method, ['Cash', 'Card', 'Bank Transfer'], (val) => setStateSB(() => method = val!)),
          ],
        );
      }),
      onSave: () async {
        final p = packages.where((x) => x.id == selectedPackageId).firstOrNull;
        if (p != null) {
          await provider.recordPayment(
            userId: player.uid,
            playerName: player.fullName,
            packageName: p.name,
            amount: double.tryParse(amountCtrl.text) ?? 0,
            paymentMethod: method,
            groupId: selectedGroupId,
            groupName: selectedGroupName,
          );

          // YENİ: currentPackageId ve membershipId user'a kaydediliyor VE plan bilgileri güncelleniyor
          try {
            final snap = await FirebaseDatabase.instance
                .ref('memberships')
                .orderByChild('userId')
                .equalTo(player.uid)
                .get();
            if (snap.exists && snap.value != null) {
              final map = snap.value as Map;
              String? latestMembershipId;
              int latestTimestamp = 0;
              map.forEach((key, value) {
                final data = value as Map;
                final startStr = data['startDate']?.toString() ?? '';
                final timestamp = DateTime.tryParse(startStr)?.millisecondsSinceEpoch ?? 0;
                if (timestamp > latestTimestamp) {
                  latestTimestamp = timestamp;
                  latestMembershipId = key;
                }
              });
              if (latestMembershipId != null) {
                await provider.updatePlayer(player.uid, {
                  'currentPackageId': p.id,
                  'membershipId': latestMembershipId,
                });

                // Membership detaylarını pakete göre güncelle
                await FirebaseDatabase.instance.ref('memberships/$latestMembershipId').update({
                  'planName': p.name,
                  'planType': p.name,
                  'packageId': p.id,
                  'isUnlimited': p.isUnlimited,
                  'maxSessions': p.maxSessions,
                  'weeklySessions': p.weeklySessions,
                  'durationDays': p.durationDays,
                });
              }
            }
          } catch (e) {
            debugPrint('Error updating user package/membership ID: $e');
          }
        }
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              selectedGroupName != null
                  ? 'Payment recorded · Group: $selectedGroupName'
                  : 'Payment recorded',
              style: const TextStyle(fontSize: 10),
            ),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  // YARDIMCI WIDGETLAR
  void _showModernBottomSheet({required String title, required Widget child, required VoidCallback onSave}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: _darkBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: generalGlassDark)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(), style: GoogleFonts.oswald(fontSize: 16, color: _textMain, letterSpacing: 1)),
              const SizedBox(height: 20),
              child,
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('SAVE', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.poppins(fontSize: 11, color: _textMain),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: GoogleFonts.poppins(fontSize: 10, color: _textDim),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: glassBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _redAccent)),
      ),
    );
  }

  Widget _buildModernDropdown(String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: glassBorder)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: _darkBg,
          style: GoogleFonts.poppins(fontSize: 11, color: _textMain),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// Ortak Kullanılan Özel Blur (Glassmorphism) Kart Widget'ı
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double? height;
  const _GlassCard({required this.child, required this.padding, this.height});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: generalGlassDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}
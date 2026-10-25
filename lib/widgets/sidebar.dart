import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/coach_model.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';

class Sidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavigate;
  final String adminName;
  final String adminRole;
  final String adminInitials;

  const Sidebar({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
    required this.adminName,
    required this.adminRole,
    required this.adminInitials,
  });

  // Her item için gerekli permission (Backend ve dinamik yapı korundu)
  static const List<List<String>> _itemPermissions = [
    [], // 0: Dashboard (Home)
    [CoachPermissions.managePlayers], // 1: Players
    [CoachPermissions.manageCoaches], // 2: Coaches
    [CoachPermissions.manageClasses], // 3: Classes
    [CoachPermissions.scanQr, CoachPermissions.manageAttendance], // 4: Attendance
    [CoachPermissions.managePackages], // 5: Subscriptions
    [CoachPermissions.manageFights], // 6: Fighters
    [CoachPermissions.manageTournaments], // 7: Tournaments (Gizlendi)
    [CoachPermissions.managePayments], // 8: Finance (Gizlendi)
    [CoachPermissions.sendAnnouncements], // 9: Announcements
    [CoachPermissions.viewReports], // 10: Reports
    [CoachPermissions.manageBranches], // 11: Branches
    [CoachPermissions.dailyAttend], // 12: Daily Attend
    [CoachPermissions.viewRewards, CoachPermissions.manageRewards], // 13: Coaches Rewards (YENİ)
  ];

  bool _canAccess(AdminProvider provider, int index) {
    if (index < 0 || index >= _itemPermissions.length) return false;
    final required = _itemPermissions[index];
    if (required.isEmpty) return true;

    final admin = provider.admin;
    if (admin == null) return false;
    if (admin.role == 'Head Coach' || admin.role == 'Owner') return true;

    return required.any((p) => admin.permissions.contains(p));
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);

    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Colors.black,
        image: DecorationImage(
          image: AssetImage('assets/images/sidebar_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Üst Logo ve Marka Kısmı
            Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 20),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/lycans_png.png',
                    width: 140,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'LYCANS',
                    style: GoogleFonts.permanentMarker(
                      fontSize: 26,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'F I G H T   C L U B',
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE50000),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'F E A R L E S S   F I G H T E R S',
                    style: GoogleFonts.montserrat(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Navigasyon Menüsü
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                physics: const BouncingScrollPhysics(),
                children: [
                  if (_canAccess(provider, 0))
                    _buildNavItem(0, Icons.home_outlined, 'Home'),

                  if (_canAccess(provider, 3))
                    _buildNavItem(3, Icons.calendar_today_outlined, 'Classes'),

                  if (_canAccess(provider, 4))
                    _buildNavItem(4, Icons.qr_code_scanner_outlined, 'Attendance'),

                  // YENİ: Daily Attend (Attendance'ın altında)
                  if (_canAccess(provider, 12))
                    _buildNavItem(12, Icons.bolt_rounded, 'Daily Attend'),

                  if (_canAccess(provider, 1))
                    _buildNavItem(1, Icons.people_outline, 'Players'),

                  if (_canAccess(provider, 2))
                    _buildNavItem(2, Icons.group_outlined, 'Coaches & Staff'),

                  if (_canAccess(provider, 5))
                    _buildNavItem(5, Icons.web_asset_outlined, 'Subscriptions'),

                  if (_canAccess(provider, 6))
                    _buildNavItem(6, Icons.emoji_events_outlined, 'Fights'),

                  if (_canAccess(provider, 9))
                    _buildNavItem(9, Icons.campaign_outlined, 'Announcements'),

                  if (_canAccess(provider, 10))
                    _buildNavItem(10, Icons.description_outlined, 'Reports'),

                  if (_canAccess(provider, 11))
                    _buildNavItem(11, Icons.location_on_outlined, 'Branches'),

                  if (_canAccess(provider, 13))
                    _buildNavItem(13, Icons.card_giftcard_rounded, 'Coaches Rewards'),
                ],
              ),
            ),

            // Alt Kısım - Admin Bilgileri
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE50000),
                        width: 1.5,
                      ),
                      color: Colors.black54,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/lycans_png.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adminName,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          adminRole,
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.logout_outlined,
                      size: 22,
                      color: Colors.white,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      // Logout işlemi
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = currentIndex == index;
    final Color activeColor = Colors.white;
    final Color inactiveColor = Colors.white.withOpacity(0.8);

    return InkWell(
      onTap: () => onNavigate(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: isActive
            ? BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFE50000).withOpacity(0.7),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE50000).withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        )
            : BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  color: isActive ? activeColor : inactiveColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isActive ? Colors.white : Colors.white38,
            ),
          ],
        ),
      ),
    );
  }
}
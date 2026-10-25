import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/coach_model.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';
import '../widgets/sidebar.dart';
import 'coaches_rewards_screen.dart';
import 'dashboard_screen.dart';
import 'players_screen.dart';
import 'coaches_screen.dart';
import 'classes_screen.dart';
import 'attendance_screen.dart';
import 'packages_screen.dart';
import 'fighters_screen.dart';
import 'tournaments_screen.dart';
import 'finance_screen.dart';
import 'announcements_screen.dart';
import 'reports_screen.dart';
import 'branches_screen.dart';
import 'daily_attend_screen.dart'; // YENİ

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Her ekran için gerekli permission'ları tanımla
  // Boş liste = herkes erişebilir (Dashboard)
  static const List<List<String>> _requiredPermissions = [
    [], // 0: Dashboard - herkese açık
    [CoachPermissions.managePlayers], // 1: Players
    [CoachPermissions.manageCoaches], // 2: Coaches
    [CoachPermissions.manageClasses], // 3: Classes
    [CoachPermissions.scanQr, CoachPermissions.manageAttendance], // 4: Attendance
    [CoachPermissions.managePackages], // 5: Subscriptions
    [CoachPermissions.manageFights], // 6: Fighters
    [CoachPermissions.manageTournaments], // 7: Tournaments
    [CoachPermissions.managePayments], // 8: Finance
    [CoachPermissions.sendAnnouncements], // 9: Announcements
    [CoachPermissions.viewReports], // 10: Reports
    [CoachPermissions.manageBranches], // 11: Branches
    [CoachPermissions.dailyAttend], // 12: Daily Attend (YENİ)
    [CoachPermissions.viewRewards, CoachPermissions.manageRewards], // 13: Coaches Rewards (YENİ)
  ];

  static const List<String> _titles = [
    'Dashboard',
    'Players',
    'Coaches & Staff',
    'Classes',
    'Attendance',
    'Subscriptions',
    'Fighters',
    'Tournaments',
    'Finance',
    'Announcements',
    'Reports',
    'Branches',
    'Daily Attend',
    'Coaches Rewards', // YENİ
  ];

  static const List<String> _subtitles = [
    "Everything happening at your academy, right now.",
    'Manage every member, their membership and progress.',
    'Team accounts, roles and permissions.',
    'Schedule sessions and track capacity.',
    'Live QR check-ins at the door.',
    'Packages, pricing and durations.',
    'Fight records and competition history.',
    'Brackets, weigh-ins and results.',
    'Revenue, invoices and outstanding balances.',
    'Broadcast updates to your members.',
    'Export data across the academy.',
    'Manage your academy locations.',
    'Daily combos and attendance with photos.',
    'Recognition, bonuses & discounts for your team.', // YENİ
  ];

  static const List<Widget> _screens = [
    DashboardScreen(),
    PlayersScreen(),
    CoachesScreen(),
    ClassesScreen(),
    AttendanceScreen(),
    PackagesScreen(),
    FightersScreen(),
    TournamentsScreen(),
    FinanceScreen(),
    AnnouncementsScreen(),
    ReportsScreen(),
    BranchesScreen(),
    DailyAttendScreen(),
    CoachesRewardsScreen(), // YENİ
  ];

  // Permission kontrolü - merkezi
  bool _canAccess(AdminProvider provider, int index) {
    if (index < 0 || index >= _requiredPermissions.length) return false;

    final required = _requiredPermissions[index];

    // Boş liste = herkes erişebilir
    if (required.isEmpty) return true;

    // Head Coach ve Owner her şeye erişebilir
    final admin = provider.admin;
    if (admin == null) return false;
    if (admin.role == 'Head Coach' || admin.role == 'Owner') return true;

    // Herhangi bir permission yeterli
    return required.any((p) => admin.permissions.contains(p));
  }

  // İlk erişilebilir sayfayı bul
  int _findFirstAccessibleIndex(AdminProvider provider) {
    for (int i = 0; i < _screens.length; i++) {
      if (_canAccess(provider, i)) return i;
    }
    return 0;
  }

  void _navigateTo(int index) {
    final provider = Provider.of<AdminProvider>(context, listen: false);

    if (!_canAccess(provider, index)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You don\'t have permission to access this section'),
          backgroundColor: AppConstants.ember,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _currentIndex = index;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final admin = provider.admin;

    // Eğer current index erişilemezse, ilk erişilebilir sayfaya yönlendir
    if (!_canAccess(provider, _currentIndex)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final newIndex = _findFirstAccessibleIndex(provider);
        if (mounted && newIndex != _currentIndex) {
          setState(() => _currentIndex = newIndex);
        }
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppConstants.bg,
      drawer: Sidebar(
        currentIndex: _currentIndex,
        onNavigate: _navigateTo,
        adminName: admin?.fullName ?? 'Admin',
        adminRole: admin?.role ?? 'Head Coach',
        adminInitials: admin?.initials ?? 'HC',
      ),
      body: SafeArea(
        child: Row(
          children: [
            // Desktop sidebar
            if (MediaQuery.of(context).size.width >= 880)
              Sidebar(
                currentIndex: _currentIndex,
                onNavigate: _navigateTo,
                adminName: admin?.fullName ?? 'Admin',
                adminRole: admin?.role ?? 'Head Coach',
                adminInitials: admin?.initials ?? 'HC',
              ),

            // Main content
            Expanded(
              child: Column(
                children: [
                  // Top bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: AppConstants.ink.withValues(alpha: 0.07)),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (MediaQuery.of(context).size.width < 880)
                          IconButton(
                            icon: const Icon(Icons.menu,
                                color: AppConstants.ink),
                            onPressed: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _titles[_currentIndex],
                                style: const TextStyle(
                                  fontFamily: 'Oswald',
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _subtitles[_currentIndex],
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppConstants.inkFaint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Notification icon
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppConstants.bgCard,
                            border: Border.all(
                                color: AppConstants.ink
                                    .withValues(alpha: 0.07)),
                          ),
                          child: const Icon(Icons.notifications_outlined,
                              color: AppConstants.ink, size: 16),
                        ),
                        const SizedBox(width: 10),
                        // Admin avatar
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppConstants.bgCard,
                            border: Border.all(
                                color: AppConstants.gold, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              admin?.initials ?? 'HC',
                              style: const TextStyle(
                                fontFamily: 'Oswald',
                                fontSize: 13,
                                color: AppConstants.goldSoft,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Screen content - sadece yetkili ekranı göster
                  Expanded(
                    child: _canAccess(provider, _currentIndex)
                        ? IndexedStack(
                      index: _currentIndex,
                      children: _screens,
                    )
                        : _buildAccessDenied(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.ember.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 48,
                color: AppConstants.emberGlow,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Access Denied',
              style: TextStyle(
                fontFamily: 'Oswald',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppConstants.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You don\'t have permission to access this feature.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppConstants.inkDim, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
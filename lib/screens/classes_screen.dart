import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/branch_model.dart';
import '../models/class_model.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'MMA', 'icon': Icons.sports_martial_arts},
    {'name': 'Kickboxing', 'icon': Icons.sports_kabaddi},
    {'name': 'Boxing', 'icon': Icons.sports_mma},
    {'name': 'BJJ', 'icon': Icons.change_history},
  ];

  static const List<String> _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);

    final Color generalGlassDark = const Color(0xFF0F1115).withOpacity(0.5);
    final Color glassBorder = Colors.white.withOpacity(0.04);

    final classes = provider.classes.where((c) {
      final matchesSearch = c.className.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.coachName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.branch.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategoryIndex == 0 ||
          c.sport.toLowerCase().contains(_categories[_selectedCategoryIndex]['name'].toString().toLowerCase());

      return matchesSearch && matchesCategory;
    }).toList();

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/classes_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // --- SEARCH BAR (İnce ve Blurlu) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: generalGlassDark,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: glassBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 16, color: Colors.white.withOpacity(0.5)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (value) => setState(() => _searchQuery = value),
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search classes...',
                            hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.4)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- CATEGORIES ---
          SizedBox(
            height: 32,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE50000).withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFE50000) : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        Icon(
                          _categories[index]['icon'] as IconData,
                          size: 13,
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _categories[index]['name'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // --- CREATE CLASS BUTTON (İnce ve Blurlu) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => _showCreateClassDialog(provider),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: generalGlassDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: glassBorder),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE50000).withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, size: 12, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Create Class',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, size: 16, color: Colors.white54),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- CLASSES LIST ---
          Expanded(
            child: classes.isEmpty
                ? Center(
              child: Text(
                'No classes yet.',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: classes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildClassCard(classes[index], provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(ClassModel classModel, AdminProvider provider) {
    final Color generalGlassDark = const Color(0xFF0F1115).withOpacity(0.5);
    final Color glassBorder = Colors.white.withOpacity(0.04);

    Color getSportColor(String sport) {
      final s = sport.toLowerCase();
      if (s.contains('mma')) return const Color(0xFFE50000);
      if (s.contains('box')) return const Color(0xFF2E8CFF);
      if (s.contains('bjj')) return const Color(0xFF8C52FF);
      return const Color(0xFFF5A623);
    }

    final sportColor = getSportColor(classModel.sport);
    final scheduleDisplay = classModel.schedule.replaceAll('·', ' • ');

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: generalGlassDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: glassBorder),
          ),
          child: Column(
            children: [
              // ÜST KISIM: İnce Yatay Fotoğraf ve Bilgiler
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Sol Taraftaki Sabit ve Yatay Fotoğraf
                  Container(
                    width: 120,
                    height: 75,
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/dashboard_card_bg.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 4,
                        height: 35,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE50000),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Sağ Taraftaki Bilgiler
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: sportColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: sportColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  classModel.sport.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: sportColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00FF66).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF00FF66).withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF00FF66),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Active',
                                      style: GoogleFonts.inter(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF00FF66),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            classModel.className,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 10, color: Colors.white.withOpacity(0.5)),
                              const SizedBox(width: 4),
                              Text(
                                scheduleDisplay.isEmpty ? 'Daily' : scheduleDisplay,
                                style: GoogleFonts.inter(fontSize: 9, color: Colors.white.withOpacity(0.7)),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.access_time, size: 10, color: Colors.white.withOpacity(0.5)),
                              const SizedBox(width: 4),
                              Text(
                                classModel.timeStr.isEmpty
                                    ? DateFormat('HH:mm').format(classModel.startTime)
                                    : classModel.timeStr,
                                style: GoogleFonts.inter(fontSize: 9, color: Colors.white.withOpacity(0.7)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 11, color: Colors.white.withOpacity(0.5)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${classModel.coachName} • ${classModel.sport}',
                                  style: GoogleFonts.inter(fontSize: 9, color: Colors.white.withOpacity(0.5)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ALT KISIM: Booked Badge (Tıklanabilir) ve Edit/Delete
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Row(
                  children: [
                    // Booked badge sol tarafta ve tıklanabilir
                    GestureDetector(
                      onTap: () => _showBookedPlayers(classModel, provider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_alt_outlined, size: 10, color: Colors.white.withOpacity(0.6)),
                            const SizedBox(width: 6),
                            Text(
                              '${classModel.bookedCount} / ${classModel.capacity} booked',
                              style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: Colors.white.withOpacity(0.9),
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white.withOpacity(0.5)
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: Colors.white,
                      width: 80,
                      onTap: () => _showEditClassDialog(provider, classModel),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      color: const Color(0xFFE50000),
                      backgroundColor: const Color(0xFFE50000).withOpacity(0.1),
                      borderColor: const Color(0xFFE50000).withOpacity(0.3),
                      width: 80,
                      onTap: () => _deleteClass(provider, classModel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    Color? backgroundColor,
    Color? borderColor,
    double? width,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor ?? Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 10, color: color.withOpacity(0.9)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BOOKED PLAYERS BOTTOM SHEET (Blurlu & Profesyonel Tasarım)
  // ===========================================================================

  void _showBookedPlayers(ClassModel classModel, AdminProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1115).withOpacity(0.8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${classModel.className} — Players',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(sheetContext),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.white.withOpacity(0.7), size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${classModel.coachName} • ${classModel.branch} • ${classModel.bookedCount} / ${classModel.capacity} booked',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: provider.getBookedPlayersForClass(classModel.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFE50000)));
                      }
                      final bookings = snapshot.data ?? [];
                      if (bookings.isEmpty) {
                        return Center(
                          child: Text(
                            'No players booked yet',
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: bookings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          final playerId = booking['userId'] ?? '';
                          final player = provider.players.where((p) => p.uid == playerId).firstOrNull;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: const Color(0xFFE50000).withOpacity(0.15),
                                  border: Border.all(color: const Color(0xFFE50000).withOpacity(0.3)),
                                ),
                                child: Center(
                                  child: Text(
                                    player?.initials ?? '??',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFE50000),
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                player?.fullName ?? booking['playerName'] ?? 'Unknown',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                '${player?.sport ?? ''} • ${player?.level ?? ''} • ${player?.phone ?? ''}',
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: const Color(0xFF00FF66).withOpacity(0.1),
                                  border: Border.all(color: const Color(0xFF00FF66).withOpacity(0.2)),
                                ),
                                child: Text(
                                  'Booked',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF00FF66),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // ÇOK ADIMLI (MULTI-STEP) CREATE & EDIT BOTTOM SHEET MANTIKLARI
  // ===========================================================================

  void _showCreateClassDialog(AdminProvider provider) {
    _showMultiStepForm(provider: provider, isEdit: false);
  }

  void _showEditClassDialog(AdminProvider provider, ClassModel classModel) {
    _showMultiStepForm(provider: provider, isEdit: true, existingClass: classModel);
  }

  void _showMultiStepForm({
    required AdminProvider provider,
    required bool isEdit,
    ClassModel? existingClass,
  }) {
    final nameController = TextEditingController(text: isEdit ? existingClass!.className : '');
    final coachController = TextEditingController(text: isEdit ? existingClass!.coachName : '');
    final locationController = TextEditingController(text: isEdit ? existingClass!.location : '');
    final TextEditingController whatsappController = TextEditingController(text: isEdit ? existingClass!.whatsappGroupUrl : '');

    String? selectedBranchId = isEdit && existingClass!.branchId.isNotEmpty ? existingClass.branchId : null;
    String selectedSport = isEdit ? existingClass!.sport : '';
    String selectedLevel = isEdit ? existingClass!.level : 'All';
    String selectedTime = isEdit
        ? (existingClass!.timeStr.isNotEmpty ? existingClass.timeStr : DateFormat('HH:mm').format(existingClass.startTime))
        : '08:00';
    int capacity = isEdit ? existingClass!.capacity : 20;
    int duration = isEdit ? existingClass!.duration : 60;
    Set<String> selectedDays = isEdit ? existingClass!.scheduleDays.toSet() : {};
    bool isDaily = isEdit ? existingClass!.schedule == 'Daily' : false;

    final activeBranches = provider.branches.where((b) => b.isActive).toList();
    int currentStep = 0; // 0, 1, 2

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final selectedBranch = selectedBranchId != null
                  ? activeBranches.where((b) => b.id == selectedBranchId).firstOrNull
                  : null;
              final availableSports = selectedBranch?.sports ?? [];

              if (availableSports.isNotEmpty && (selectedSport.isEmpty || !availableSports.contains(selectedSport))) {
                selectedSport = availableSports.first;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), // Klavye itmesi için
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1115).withOpacity(0.85),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(top: 12, bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Title & Step Indicator
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isEdit ? 'Edit Class' : 'Create Class',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              children: List.generate(3, (index) {
                                return Container(
                                  width: 24,
                                  height: 4,
                                  margin: const EdgeInsets.only(left: 4),
                                  decoration: BoxDecoration(
                                    color: index <= currentStep
                                        ? const Color(0xFFE50000)
                                        : Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Form İçeriği
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _buildFormStep(
                              step: currentStep,
                              nameController: nameController,
                              coachController: coachController,
                              locationController: locationController,
                              selectedBranchId: selectedBranchId,
                              selectedSport: selectedSport,
                              selectedLevel: selectedLevel,
                              selectedTime: selectedTime,
                              capacity: capacity,
                              duration: duration,
                              whatsappController: whatsappController,
                              selectedDays: selectedDays,
                              isDaily: isDaily,
                              activeBranches: activeBranches,
                              availableSports: availableSports,
                              onBranchChanged: (val) => setSheetState(() { selectedBranchId = val; selectedSport = ''; }),
                              onSportChanged: (val) => setSheetState(() => selectedSport = val),
                              onLevelChanged: (val) => setSheetState(() => selectedLevel = val),
                              onTimeChanged: (val) => setSheetState(() => selectedTime = val),
                              onCapacityChanged: (val) => capacity = int.tryParse(val) ?? capacity,
                              onDurationChanged: (val) => duration = int.tryParse(val) ?? duration,
                              onDailyToggled: () {
                                setSheetState(() {
                                  isDaily = !isDaily;
                                  if (isDaily) {
                                    selectedDays = _allDays.toSet();
                                  } else {
                                    selectedDays.clear();
                                  }
                                });
                              },
                              onDayToggled: (day) {
                                setSheetState(() {
                                  if (selectedDays.contains(day)) selectedDays.remove(day);
                                  else selectedDays.add(day);
                                  isDaily = selectedDays.length == 7;
                                });
                              },
                            ),
                          ),
                        ),
                      ),

                      // Alt Butonlar (Back / Next / Save)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                        ),
                        child: Row(
                          children: [
                            if (currentStep > 0)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setSheetState(() => currentStep--),
                                  child: Container(
                                    height: 48,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Back',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              flex: 2,
                              child: GestureDetector(
                                onTap: () async {
                                  // Validation before next
                                  if (currentStep == 0) {
                                    if (nameController.text.isEmpty || coachController.text.isEmpty || selectedBranchId == null) {
                                      _showError(sheetContext, 'Please fill Name, Coach and Branch.');
                                      return;
                                    }
                                    setSheetState(() => currentStep++);
                                  } else if (currentStep == 1) {
                                    if (selectedSport.isEmpty) {
                                      _showError(sheetContext, 'Please select a sport.');
                                      return;
                                    }
                                    setSheetState(() => currentStep++);
                                  } else if (currentStep == 2) {
                                    if (selectedDays.isEmpty) {
                                      _showError(sheetContext, 'Please select at least one training day.');
                                      return;
                                    }

                                    // Save Logic
                                    Navigator.pop(sheetContext);

                                    final now = DateTime.now();
                                    final timeParts = selectedTime.split(':');
                                    final startTime = DateTime(now.year, now.month, now.day, int.parse(timeParts[0]), int.parse(timeParts[1]));
                                    final endTime = startTime.add(Duration(minutes: duration));
                                    final sortedDays = selectedDays.toList()..sort((a, b) => _allDays.indexOf(a).compareTo(_allDays.indexOf(b)));
                                    final scheduleStr = sortedDays.length == 7 ? 'Daily' : sortedDays.join('·');
                                    final branch = activeBranches.where((b) => b.id == selectedBranchId).firstOrNull;

                                    if (isEdit) {
                                      await provider.updateClass(existingClass!.id, {
                                        'className': nameController.text.trim(),
                                        'coachName': coachController.text.trim(),
                                        'branch': branch?.name ?? '',
                                        'branchId': selectedBranchId ?? '',
                                        'location': locationController.text.trim(),
                                        'sport': selectedSport,
                                        'level': selectedLevel,
                                        'capacity': capacity,
                                        'duration': duration,
                                        'schedule': scheduleStr,
                                        'timeStr': selectedTime,
                                        'whatsappGroupUrl': whatsappController.text.trim(), // BURAYI EKLE
                                      });
                                    } else {
                                      final newClass = ClassModel(
                                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                                        className: nameController.text.trim(),
                                        coachName: coachController.text.trim(),
                                        branch: branch?.name ?? '',
                                        branchId: selectedBranchId ?? '',
                                        location: locationController.text.trim(),
                                        startTime: startTime,
                                        endTime: endTime,
                                        capacity: capacity,
                                        level: selectedLevel,
                                        sport: selectedSport,
                                        duration: duration,
                                        schedule: scheduleStr,
                                        timeStr: selectedTime,
                                        whatsappGroupUrl: whatsappController.text.trim(), // BURAYI EKLE
                                      );
                                      await provider.addClass(newClass);
                                    }

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(isEdit ? 'Class updated' : 'Class created'),
                                          backgroundColor: const Color(0xFF00FF66),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE50000),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE50000).withOpacity(0.3),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    currentStep == 2 ? (isEdit ? 'Save Changes' : 'Create Class') : 'Next',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
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
            },
          ),
        );
      },
    );
  }

  Widget _buildFormStep({
    required int step,
    required TextEditingController nameController,
    required TextEditingController coachController,
    required TextEditingController locationController,
    required TextEditingController whatsappController, // YENİ EKLENDİ
    required String? selectedBranchId,
    required String selectedSport,
    required String selectedLevel,
    required String selectedTime,
    required int capacity,
    required int duration,
    required Set<String> selectedDays,
    required bool isDaily,
    required List<BranchModel> activeBranches,
    required List<String> availableSports,
    required Function(String) onBranchChanged,
    required Function(String) onSportChanged,
    required Function(String) onLevelChanged,
    required Function(String) onTimeChanged,
    required Function(String) onCapacityChanged,
    required Function(String) onDurationChanged,
    required VoidCallback onDailyToggled,
    required Function(String) onDayToggled,
  }) {
    if (step == 0) {
      return Column(
        key: const ValueKey('step0'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('CLASS NAME'),
          const SizedBox(height: 8),
          _buildTextField(
              controller: nameController,
              hint: 'e.g., Kickboxing — Advanced',
              icon: Icons.fitness_center),
          const SizedBox(height: 16),
          _buildFieldLabel('COACH NAME'),
          const SizedBox(height: 8),
          _buildTextField(
              controller: coachController,
              hint: 'e.g., Coach Ahmed',
              icon: Icons.person_outline),
          const SizedBox(height: 16),
          _buildFieldLabel('BRANCH'),
          const SizedBox(height: 8),
          activeBranches.isEmpty
              ? _buildWarningBox('No active branches. Create a branch first.')
              : _buildDropdown<String>(
            value: selectedBranchId,
            items: activeBranches.map((b) => b.id).toList(),
            labelBuilder: (id) =>
            activeBranches.firstWhere((b) => b.id == id).name,
            onChanged: onBranchChanged,
            icon: Icons.location_on_outlined,
            hint: 'Select branch',
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('LOCATION (Optional)'),
          const SizedBox(height: 8),
          _buildTextField(
              controller: locationController,
              hint: 'e.g., Ring Hall B, Mat Room',
              icon: Icons.meeting_room_outlined),
          const SizedBox(height: 16),

          // === YENİ: WHATSAPP GROUP URL ===
          _buildFieldLabel('WHATSAPP GROUP URL (Optional)'),
          const SizedBox(height: 8),
          _buildTextField(
              controller: whatsappController,
              hint: 'e.g., https://chat.whatsapp.com/...',
              icon: Icons.link),
        ],
      );
    } else if (step == 1) {
      return Column(
        key: const ValueKey('step1'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('SPORT'),
          const SizedBox(height: 8),
          selectedBranchId == null
              ? _buildWarningBox('Select a branch first in Step 1')
              : availableSports.isEmpty
              ? _buildWarningBox('This branch has no sports.')
              : _buildDropdown<String>(
            value: selectedSport.isEmpty
                ? availableSports.first
                : selectedSport,
            items: availableSports,
            labelBuilder: (s) => s,
            onChanged: onSportChanged,
            icon: Icons.sports_mma_outlined,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('LEVEL'),
                    const SizedBox(height: 8),
                    _buildDropdown<String>(
                      value: selectedLevel,
                      items: [
                        'All',
                        'Beginner',
                        'Intermediate',
                        'Advanced',
                        'Professional'
                      ],
                      labelBuilder: (l) => l,
                      onChanged: onLevelChanged,
                      icon: Icons.trending_up,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('TIME'),
                    const SizedBox(height: 8),
                    _buildDropdown<String>(
                      value: selectedTime,
                      items: List.generate(14,
                              (i) => '${(i + 8).toString().padLeft(2, '0')}:00'),
                      labelBuilder: (t) => t,
                      onChanged: onTimeChanged,
                      icon: Icons.access_time,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        key: const ValueKey('step2'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldLabel('TRAINING DAYS'),
              Text(
                '${selectedDays.length} selected',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFFE50000),
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: onDailyToggled,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isDaily
                          ? const Color(0xFFE50000).withOpacity(0.15)
                          : Colors.transparent,
                      border: Border.all(
                        color: isDaily
                            ? const Color(0xFFE50000)
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: isDaily
                                ? const Color(0xFFE50000)
                                : Colors.transparent,
                            border: Border.all(
                              color: isDaily
                                  ? const Color(0xFFE50000)
                                  : Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: isDaily
                              ? const Icon(Icons.check,
                              size: 12, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Daily (all week)',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: isDaily
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isDaily ? Colors.white : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allDays.map((day) {
                    final isSelected = selectedDays.contains(day);
                    return GestureDetector(
                      onTap: () => onDayToggled(day),
                      child: Container(
                        width: 45,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected
                              ? const Color(0xFFE50000).withOpacity(0.15)
                              : Colors.white.withOpacity(0.03),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFE50000)
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              day.substring(0, 1),
                              style: GoogleFonts.inter(
                                  fontSize: 10, color: Colors.white54),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              day.substring(1),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color:
                                isSelected ? Colors.white : Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('CAPACITY'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      keyboardType: TextInputType.number,
                      hint: '$capacity',
                      icon: Icons.people_outline,
                      onChanged: onCapacityChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('DURATION (MIN)'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      keyboardType: TextInputType.number,
                      hint: '$duration',
                      icon: Icons.timer_outlined,
                      onChanged: onDurationChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  // ===========================================================================
  // FORM HELPER WIDGETS (Tümü yeni modern tasarıma güncellendi)
  // ===========================================================================

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 10,
        letterSpacing: 1.2,
        color: Colors.white54,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        prefixIcon: Icon(icon, size: 18, color: Colors.white54),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE50000)),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required Function(T) onChanged,
    required IconData icon,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white54),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                dropdownColor: const Color(0xFF1A1A1E),
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                hint: hint != null ? Text(hint, style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)) : null,
                items: items.map((item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(labelBuilder(item), overflow: TextOverflow.ellipsis),
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

  Widget _buildWarningBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFE50000).withOpacity(0.1),
        border: Border.all(color: const Color(0xFFE50000).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFE50000)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFFE50000))),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: const Color(0xFFE50000),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteClass(AdminProvider provider, ClassModel classModel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Class',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete "${classModel.className}"?',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50000),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      await provider.deleteClass(classModel.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Class deleted'),
            backgroundColor: Color(0xFFE50000),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

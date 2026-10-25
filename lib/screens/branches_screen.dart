import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/branch_model.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';

// Tasarıma özel renk paleti
class _DarkTheme {
  static const Color redAccent = Color(0xFFFF0022);
  static const Color redDim = Color(0x33FF0022);
  static const Color backgroundDark = Color(0xFF090909);
  static const Color cardBg = Color(0x7A000000); // Blur için saydam
  static const Color borderFaint = Color(0xFF2A2A2A);
  static const Color textMain = Color(0xFFF0F0F0);
  static const Color textDim = Color(0xFF888888);
  static const Color greenAccent = Color(0xFF00FF66);
}

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  String _searchQuery = '';
  String _filter = 'All';
  final List<String> _filters = ['All', 'Active', 'Closed'];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final allBranches = provider.branches;

    final branches = allBranches.where((b) {
      final matchesSearch = b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.address.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _filter == 'All' ||
          (_filter == 'Active' && b.isActive) ||
          (_filter == 'Closed' && !b.isActive);
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      // Arkaplan tam ekranı kaplasın
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/classes_bg.png'),
            fit: BoxFit.cover, // Boşluksuz tam kaplama
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Arama Çubuğu (Çok İnce)
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _DarkTheme.borderFaint),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 16, color: _DarkTheme.textDim),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: (value) => setState(() => _searchQuery = value),
                          style: GoogleFonts.inter(fontSize: 11, color: _DarkTheme.textMain),
                          decoration: InputDecoration(
                            hintText: 'Search branches...',
                            hintStyle: GoogleFonts.inter(fontSize: 11, color: _DarkTheme.textDim),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Filtreler
                Row(
                  children: _filters.map((filter) {
                    final isSelected = _filter == filter;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = filter),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: isSelected ? Colors.transparent : _DarkTheme.backgroundDark.withOpacity(0.6),
                          border: Border.all(
                            color: isSelected ? _DarkTheme.redAccent : _DarkTheme.borderFaint,
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: _DarkTheme.redAccent.withOpacity(0.2), blurRadius: 8)]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (filter == 'All')
                              Icon(Icons.grid_view_rounded,
                                  size: 11, color: isSelected ? _DarkTheme.textMain : _DarkTheme.textDim)
                            else
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: filter == 'Active' ? _DarkTheme.greenAccent : _DarkTheme.redAccent,
                                ),
                              ),
                            const SizedBox(width: 6),
                            Text(
                              filter,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? _DarkTheme.textMain : _DarkTheme.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Yeni Şube Ekle Butonu
                GestureDetector(
                  onTap: () => _showBranchDialog(provider),
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _DarkTheme.backgroundDark.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _DarkTheme.redAccent.withOpacity(0.8)),
                      boxShadow: [
                        BoxShadow(color: _DarkTheme.redAccent.withOpacity(0.1), blurRadius: 10),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.add, color: _DarkTheme.textMain, size: 16),
                        const SizedBox(width: 12),
                        Text(
                          'New Branch',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _DarkTheme.textMain,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward, color: _DarkTheme.redAccent, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Şube Listesi
                if (branches.isEmpty)
                  _buildEmptyState(provider)
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: branches.length,
                    itemBuilder: (context, index) {
                      return _buildBranchCard(branches[index], provider);
                    },
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AdminProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _DarkTheme.cardBg,
        border: Border.all(color: _DarkTheme.borderFaint),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off_outlined, size: 40, color: _DarkTheme.textDim.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            'No branches found',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _DarkTheme.textMain),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(BranchModel branch, AdminProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DarkTheme.borderFaint),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: _DarkTheme.cardBg,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Sol Fotoğraf - DAHA GENİŞ
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/dashboard_card_bg.png',
                          width: 110, // Genişletildi
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Orta Bilgiler
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, color: _DarkTheme.redAccent, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    branch.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _DarkTheme.textMain,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 18),
                              child: Text(
                                branch.address,
                                style: GoogleFonts.inter(fontSize: 10, color: _DarkTheme.textDim),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Overflow hatasını önlemek için Wrap kullanıldı
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _buildMiniInfo(Icons.people_outline, '${branch.capacity} capacity'),
                                _buildMiniInfo(
                                  Icons.calendar_today_outlined,
                                  DateFormat('dd MMM yyyy').format(branch.createdAt),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Sağ Taraf: Durum ve Ok
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.transparent,
                              border: Border.all(
                                color: branch.isActive ? _DarkTheme.greenAccent.withOpacity(0.3) : _DarkTheme.redAccent.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: branch.isActive ? _DarkTheme.greenAccent : _DarkTheme.redAccent,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  branch.isActive ? 'Active' : 'Closed',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: branch.isActive ? _DarkTheme.greenAccent : _DarkTheme.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _showSportsBottomSheet(branch),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _DarkTheme.borderFaint),
                                color: _DarkTheme.backgroundDark.withOpacity(0.5),
                              ),
                              child: const Icon(Icons.chevron_right, size: 16, color: _DarkTheme.textMain),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Alt Butonlar
                Container(
                  height: 40,
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: _DarkTheme.borderFaint)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: branch.isActive ? Icons.lock_outline : Icons.lock_open_outlined,
                          label: branch.isActive ? 'Close' : 'Reopen',
                          color: _DarkTheme.textDim,
                          onTap: () => _toggleStatus(provider, branch),
                        ),
                      ),
                      Container(width: 1, color: _DarkTheme.borderFaint),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          color: _DarkTheme.textDim,
                          onTap: () => _showBranchDialog(provider, branch: branch),
                        ),
                      ),
                      Container(width: 1, color: _DarkTheme.borderFaint),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          color: _DarkTheme.redAccent,
                          onTap: () => _deleteBranch(provider, branch),
                        ),
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

  Widget _buildMiniInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: _DarkTheme.textDim),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(fontSize: 9, color: _DarkTheme.textDim),
        ),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== SPORLAR BOTTOM SHEET (Şık Açılır Menü) =====
  void _showSportsBottomSheet(BranchModel branch) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF121212),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              border: Border(top: BorderSide(color: _DarkTheme.redAccent, width: 1)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: _DarkTheme.borderFaint, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.sports_mma, color: _DarkTheme.redAccent, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Sports Offered',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: _DarkTheme.textMain),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Available disciplines at ${branch.name}',
                  style: GoogleFonts.inter(fontSize: 11, color: _DarkTheme.textDim),
                ),
                const SizedBox(height: 24),
                if (branch.sports.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('No sports listed.', style: GoogleFonts.inter(fontSize: 12, color: _DarkTheme.textDim)),
                    ),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: branch.sports.map((sport) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _DarkTheme.redDim,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _DarkTheme.redAccent.withOpacity(0.5)),
                        ),
                        child: Text(
                          sport,
                          style: GoogleFonts.inter(fontSize: 11, color: _DarkTheme.textMain, fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== YENİ/DÜZENLE DİYALOG (DARK NEON KONSEPT) =====
  void _showBranchDialog(AdminProvider provider, {BranchModel? branch}) {
    final nameController = TextEditingController(text: branch?.name ?? '');
    final addressController = TextEditingController(text: branch?.address ?? '');
    final phoneController = TextEditingController(text: branch?.phone ?? '');
    final managerController = TextEditingController(text: branch?.managerName ?? '');
    final capacityController = TextEditingController(
      text: branch != null && branch.capacity > 0 ? branch.capacity.toString() : '',
    );
    final notesController = TextEditingController(text: branch?.notes ?? '');

    bool isActive = branch?.isActive ?? true;
    Set<String> selectedSports = Set.from(branch?.sports ?? []);
    String locationLink = branch?.locationLink ?? '';
    double latitude = branch?.latitude ?? 0;
    double longitude = branch?.longitude ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.9,
                decoration: const BoxDecoration(
                  color: Color(0xFF121212),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  border: Border(top: BorderSide(color: _DarkTheme.borderFaint, width: 1)),
                ),
                padding: EdgeInsets.only(
                  left: 20, right: 20, top: 20,
                  bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 20,
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: _DarkTheme.borderFaint, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          branch == null ? 'New Branch' : 'Edit Branch',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: _DarkTheme.textMain),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: _DarkTheme.textDim, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(dialogContext),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDarkTextField(controller: nameController, hint: 'Branch Name', icon: Icons.business),
                            const SizedBox(height: 12),
                            _buildDarkTextField(controller: addressController, hint: 'Address', icon: Icons.location_on_outlined, maxLines: 2),
                            const SizedBox(height: 16),

                            // MAP LOCATION (GERİ GETİRİLDİ)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('MAP LOCATION', style: GoogleFonts.inter(fontSize: 10, color: _DarkTheme.textDim, letterSpacing: 1)),
                                if (locationLink.isNotEmpty)
                                  Text('PIN SET', style: GoogleFonts.inter(fontSize: 9, color: _DarkTheme.greenAccent, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final result = await _showLocationPicker(
                                  dialogContext,
                                  currentLat: latitude,
                                  currentLng: longitude,
                                );
                                if (result != null) {
                                  setDialogState(() {
                                    locationLink = result['link']!;
                                    latitude = result['lat']!;
                                    longitude = result['lng']!;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: _DarkTheme.backgroundDark,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: locationLink.isNotEmpty ? _DarkTheme.greenAccent.withOpacity(0.4) : _DarkTheme.borderFaint,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      locationLink.isNotEmpty ? Icons.map : Icons.add_location_alt_outlined,
                                      size: 16,
                                      color: locationLink.isNotEmpty ? _DarkTheme.greenAccent : _DarkTheme.textDim,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        locationLink.isNotEmpty ? 'Location pinned on map' : 'Tap to pin location on map',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: locationLink.isNotEmpty ? _DarkTheme.greenAccent : _DarkTheme.textDim,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, size: 16, color: _DarkTheme.textDim),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(child: _buildDarkTextField(controller: phoneController, hint: 'Phone', icon: Icons.phone_outlined, keyboardType: TextInputType.phone)),
                                const SizedBox(width: 10),
                                Expanded(child: _buildDarkTextField(controller: capacityController, hint: 'Capacity', icon: Icons.people_outline, keyboardType: TextInputType.number)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDarkTextField(controller: managerController, hint: 'Manager Name', icon: Icons.person_outline),
                            const SizedBox(height: 20),

                            Text('SPORTS OFFERED', style: GoogleFonts.inter(fontSize: 10, color: _DarkTheme.textDim, letterSpacing: 1)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: BranchSports.all.map((sport) {
                                final isSelected = selectedSports.contains(sport);
                                return GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      isSelected ? selectedSports.remove(sport) : selectedSports.add(sport);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? _DarkTheme.redAccent.withOpacity(0.2) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: isSelected ? _DarkTheme.redAccent : _DarkTheme.borderFaint),
                                    ),
                                    child: Text(
                                      sport,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: isSelected ? _DarkTheme.textMain : _DarkTheme.textDim,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _DarkTheme.backgroundDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _DarkTheme.borderFaint),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Branch is Active', style: GoogleFonts.inter(fontSize: 11, color: _DarkTheme.textMain)),
                                  Switch(
                                    value: isActive,
                                    activeColor: _DarkTheme.greenAccent,
                                    onChanged: (val) => setDialogState(() => isActive = val),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        if (nameController.text.trim().isEmpty) return;
                        Navigator.pop(dialogContext);
                        if (branch == null) {
                          final newBranch = BranchModel(
                            id: '',
                            name: nameController.text.trim(),
                            address: addressController.text.trim(),
                            phone: phoneController.text.trim(),
                            managerName: managerController.text.trim(),
                            isActive: isActive,
                            createdAt: DateTime.now(),
                            capacity: int.tryParse(capacityController.text) ?? 0,
                            notes: notesController.text.trim(),
                            sports: selectedSports.toList(),
                            locationLink: locationLink,
                            latitude: latitude,
                            longitude: longitude,
                          );
                          await provider.addBranch(newBranch);
                        } else {
                          await provider.updateBranch(branch.id, {
                            'name': nameController.text.trim(),
                            'address': addressController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'managerName': managerController.text.trim(),
                            'isActive': isActive,
                            'capacity': int.tryParse(capacityController.text) ?? branch.capacity,
                            'notes': notesController.text.trim(),
                            'sports': selectedSports.toList(),
                            'locationLink': locationLink,
                            'latitude': latitude,
                            'longitude': longitude,
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _DarkTheme.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'SAVE BRANCH',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===== HARİTA KONUM SEÇİCİ (DARK TEMA UYARLAMASI) =====
  Future<Map<String, dynamic>?> _showLocationPicker(
      BuildContext parentContext, {
        required double currentLat,
        required double currentLng,
      }) async {
    // Mısır/Kahire default başlangıç
    double defaultLat = currentLat != 0 ? currentLat : 30.0444;
    double defaultLng = currentLng != 0 ? currentLng : 31.2357;

    LatLng selectedLocation = LatLng(defaultLat, defaultLng);
    bool hasSelection = currentLat != 0 && currentLng != 0;

    return showDialog<Map<String, dynamic>>(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Dialog(
                backgroundColor: _DarkTheme.backgroundDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: _DarkTheme.redAccent.withOpacity(0.5)),
                ),
                insetPadding: const EdgeInsets.all(16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: _DarkTheme.borderFaint)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.map_outlined, color: _DarkTheme.redAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Pin Location',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _DarkTheme.textMain),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close, color: _DarkTheme.textDim, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),

                      // MAP
                      Expanded(
                        child: ClipRRect(
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: selectedLocation,
                              initialZoom: currentLat != 0 ? 15 : 11,
                              minZoom: 3,
                              maxZoom: 19,
                              onTap: (tapPosition, point) {
                                setDialogState(() {
                                  selectedLocation = point;
                                  hasSelection = true;
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.lycans.admin.lycans_fight_club_admin',
                                maxNativeZoom: 19,
                              ),
                              if (hasSelection)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: selectedLocation,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_pin,
                                        color: _DarkTheme.redAccent,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Info & Actions
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: _DarkTheme.borderFaint)),
                          color: _DarkTheme.backgroundDark,
                        ),
                        child: Column(
                          children: [
                            if (!hasSelection)
                              Text(
                                'Tap anywhere on the map to drop a pin',
                                style: GoogleFonts.inter(fontSize: 11, color: _DarkTheme.textDim),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(dialogContext),
                                    child: Container(
                                      height: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: _DarkTheme.borderFaint),
                                      ),
                                      child: Text('Cancel', style: GoogleFonts.inter(fontSize: 11, color: _DarkTheme.textDim)),
                                    ),
                                  ),
                                ),
                                if (currentLat != 0) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(dialogContext, {'link': '', 'lat': 0.0, 'lng': 0.0}),
                                    child: Container(
                                      height: 40,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: _DarkTheme.borderFaint),
                                      ),
                                      child: Text('Remove', style: GoogleFonts.inter(fontSize: 11, color: _DarkTheme.redAccent)),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: GestureDetector(
                                    onTap: hasSelection
                                        ? () {
                                      final lat = selectedLocation.latitude;
                                      final lng = selectedLocation.longitude;
                                      final link = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                                      Navigator.pop(dialogContext, {'link': link, 'lat': lat, 'lng': lng});
                                    }
                                        : null,
                                    child: Container(
                                      height: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: hasSelection ? _DarkTheme.redAccent : _DarkTheme.borderFaint,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'SAVE',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: hasSelection ? Colors.white : _DarkTheme.textDim,
                                          letterSpacing: 1,
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
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDarkTextField({required TextEditingController controller, required String hint, required IconData icon, int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 12, color: _DarkTheme.textMain),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 11, color: _DarkTheme.textDim),
        prefixIcon: Icon(icon, size: 16, color: _DarkTheme.textDim),
        filled: true,
        fillColor: _DarkTheme.backgroundDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _DarkTheme.borderFaint)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _DarkTheme.redAccent)),
      ),
    );
  }

  // ===== DURUM DEĞİŞTİR (CLOSE/REOPEN) DİYALOĞU =====
  Future<void> _toggleStatus(AdminProvider provider, BranchModel branch) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: _DarkTheme.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _DarkTheme.borderFaint)),
            title: Text(
              branch.isActive ? 'Close Branch?' : 'Reopen Branch?',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _DarkTheme.textMain),
            ),
            content: Text(
              'Are you sure you want to change the status of ${branch.name}?',
              style: GoogleFonts.inter(fontSize: 11, color: _DarkTheme.textDim),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('Cancel', style: GoogleFonts.inter(fontSize: 11, color: _DarkTheme.textDim)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text('Confirm', style: GoogleFonts.inter(fontSize: 11, color: _DarkTheme.redAccent, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );

    if (confirm == true && mounted) {
      await provider.toggleBranchStatus(branch.id, !branch.isActive);
    }
  }

  // ===== SİLME DİYALOĞU =====
  Future<void> _deleteBranch(AdminProvider provider, BranchModel branch) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: _DarkTheme.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _DarkTheme.redAccent.withOpacity(0.5))),
            title: Text(
              'Delete Branch',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _DarkTheme.redAccent),
            ),
            content: Text(
              'This action cannot be undone. Delete "${branch.name}"?',
              style: GoogleFonts.inter(fontSize: 11, color: _DarkTheme.textDim),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('Cancel', style: GoogleFonts.inter(fontSize: 11, color: _DarkTheme.textDim)),
              ),
              Container(
                decoration: BoxDecoration(color: _DarkTheme.redAccent, borderRadius: BorderRadius.circular(8)),
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text('Delete', style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirm == true && mounted) {
      await provider.deleteBranch(branch.id);
    }
  }
}
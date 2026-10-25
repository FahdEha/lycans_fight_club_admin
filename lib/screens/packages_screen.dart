import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/branch_model.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';
import '../models/package_model.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final packages = provider.packages;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF050505),
        image: DecorationImage(
          image: AssetImage('assets/images/subscriptions_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddPackageButton(context, provider),
            const SizedBox(height: 20),

            if (packages.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black.withOpacity(0.5),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Center(
                  child: Text(
                    'No packages yet. Create your first package!',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: packages.length,
                itemBuilder: (context, index) {
                  return _buildPackageCard(context, packages[index], provider);
                },
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPackageButton(BuildContext context, AdminProvider provider) {
    return GestureDetector(
      onTap: () => _showPackageDialog(context, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D).withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE50914).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE50914).withOpacity(0.3)),
              ),
              child: const Icon(Icons.add, color: Color(0xFFE50914), size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Package',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Create and manage new subscription plans.',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(BuildContext context, PackageModel package, AdminProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: package.isFeatured
              ? const Color(0xFFE50914).withOpacity(0.4)
              : Colors.white.withOpacity(0.05),
          width: 1,
        ),
        image: DecorationImage(
          image: AssetImage(
            package.isFeatured
                ? 'assets/images/plan_popular_card_bg.png'
                : 'assets/images/subscriptions_plan_card_bg.png',
          ),
          fit: BoxFit.cover,
        ),
        boxShadow: package.isFeatured
            ? [
          BoxShadow(
            color: const Color(0xFFE50914).withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: package.isFeatured
                        ? const Color(0xFFE50914).withOpacity(0.3)
                        : Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Icon(
                  package.isFeatured ? Icons.workspace_premium : Icons.star_border,
                  color: package.isFeatured ? const Color(0xFFE50914) : Colors.white54,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            package.name,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (package.isFeatured)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE50914).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE50914).withOpacity(0.5)),
                            ),
                            child: Text(
                              'Popular',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                color: const Color(0xFFE50914),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${package.price.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            'EGP / ${package.durationDays} days',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Active',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Branch + Sessions row
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white54, size: 12),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  package.isUnlimited
                      ? 'Unlimited Sessions'
                      : '${package.maxSessions} sessions/month (${package.weeklySessions}/week)',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Branch badge
          if (package.branch.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: Colors.white54, size: 12),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    package.branch,
                    style: GoogleFonts.inter(
                        fontSize: 10, color: Colors.white54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 4),
          ...package.features.map((feature) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 12, color: Colors.white70),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      feature,
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPackageDialog(context, provider, package: package),
                  icon: const Icon(Icons.settings_outlined, size: 12, color: Colors.white70),
                  label: Text('Manage',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white70)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    backgroundColor: Colors.black.withOpacity(0.3),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deletePackage(context, provider, package),
                  icon: const Icon(Icons.delete_outline, size: 12, color: Color(0xFFE50914)),
                  label: Text('Cancel',
                      style: GoogleFonts.inter(fontSize: 10, color: Color(0xFFE50914))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: const Color(0xFFE50914).withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    backgroundColor: const Color(0xFFE50914).withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPackageDialog(BuildContext context, AdminProvider provider, {PackageModel? package}) {
    final nameController = TextEditingController(text: package?.name ?? '');
    final priceController = TextEditingController(
      text: package != null ? package.price.toStringAsFixed(0) : '',
    );
    final durationController = TextEditingController(
      text: package != null ? package.durationDays.toString() : '30',
    );
    final featuresController = TextEditingController(
      text: package?.features.join('\n') ?? '',
    );
    final maxSessionsController = TextEditingController(
      text: package != null && package.maxSessions > 0 ? package.maxSessions.toString() : '',
    );

    bool isFeatured = package?.isFeatured ?? false;
    bool isUnlimited = package?.isUnlimited ?? true;

    // Branch listesi
    final activeBranches =
    provider.branches.where((b) => b.isActive).toList();
    String? selectedBranchId;

    // Mevcut paketin branch'ini bul (isimle eşleştir)
    if (package != null && package.branch.isNotEmpty) {
      final match = activeBranches
          .where((b) => b.name == package.branch)
          .firstOrNull;
      if (match != null) {
        selectedBranchId = match.id;
      }
    }
    // Default: ilk branch
    if (selectedBranchId == null && activeBranches.isNotEmpty) {
      selectedBranchId = activeBranches.first.id;
    }

    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      barrierDismissible: true,
      barrierLabel: 'PackageDialog',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: FadeTransition(
              opacity: animation,
              child: StatefulBuilder(
                builder: (dialogContext, setDialogState) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF0A0A0A).withOpacity(0.9),
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: const Color(0xFFE50914).withOpacity(0.3)),
                    ),
                    title: Text(
                      package == null ? 'NEW PACKAGE' : 'EDIT PACKAGE',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    content: SizedBox(
                      width: 400,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildDialogTextField(nameController, 'Package Name',
                                hint: 'e.g. Champion Plan'),
                            Row(
                              children: [
                                Expanded(
                                    child: _buildDialogTextField(
                                        priceController, 'Price (EGP)',
                                        isNumber: true, hint: '1200')),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _buildDialogTextField(
                                        durationController, 'Duration (days)',
                                        isNumber: true, hint: '30')),
                              ],
                            ),

                            // ===== BRANCH DROPDOWN =====
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildBranchDropdown(
                                branches: activeBranches,
                                selectedId: selectedBranchId,
                                onChanged: (id) {
                                  setDialogState(() => selectedBranchId = id);
                                },
                              ),
                            ),

                            _buildDialogTextField(
                                featuresController, 'Features (one per line)',
                                maxLines: 4,
                                hint:
                                'Unlimited sessions\nProgress tracking'),

                            const SizedBox(height: 8),
                            _buildCustomCheckbox('Popular / Featured Plan',
                                isFeatured, (val) {
                                  setDialogState(() => isFeatured = val ?? false);
                                }),
                            _buildCustomCheckbox(
                                'Unlimited Sessions', isUnlimited, (val) {
                              setDialogState(() {
                                isUnlimited = val ?? true;
                                if (isUnlimited) maxSessionsController.clear();
                              });
                            }),

                            if (!isUnlimited) ...[
                              const SizedBox(height: 12),
                              _buildDialogTextField(
                                  maxSessionsController,
                                  'Max Sessions per Month',
                                  isNumber: true,
                                  hint: '12'),
                            ],
                          ],
                        ),
                      ),
                    ),
                    actionsPadding:
                    const EdgeInsets.only(right: 16, bottom: 16),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text('Cancel',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.white54)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty ||
                              priceController.text.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                  content: Text('Name and price are required'),
                                  backgroundColor: Colors.red),
                            );
                            return;
                          }

                          if (!isUnlimited &&
                              maxSessionsController.text.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                  content:
                                  Text('Enter max sessions per month'),
                                  backgroundColor: Colors.red),
                            );
                            return;
                          }

                          // Branch adı çek
                          String branchName = '';
                          if (selectedBranchId != null) {
                            final b = activeBranches
                                .where((x) => x.id == selectedBranchId)
                                .firstOrNull;
                            branchName = b?.name ?? '';
                          }

                          Navigator.pop(dialogContext);

                          final features = featuresController.text
                              .split('\n')
                              .map((f) => f.trim())
                              .where((f) => f.isNotEmpty)
                              .toList();

                          final int maxSessions = isUnlimited
                              ? 0
                              : (int.tryParse(maxSessionsController.text) ?? 0);
                          final int weeklySessions = isUnlimited
                              ? 0
                              : (maxSessions / 4).ceil();

                          if (package == null) {
                            final newPackage = PackageModel(
                              id: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              name: nameController.text.trim(),
                              price: double.tryParse(priceController.text) ?? 0,
                              durationDays:
                              int.tryParse(durationController.text) ?? 30,
                              features: features,
                              isFeatured: isFeatured,
                              isUnlimited: isUnlimited,
                              maxSessions: maxSessions,
                              weeklySessions: weeklySessions,
                              branch: branchName,
                            );
                            await provider.addPackage(newPackage);
                          } else {
                            await provider.updatePackage(package.id, {
                              'name': nameController.text.trim(),
                              'price': double.tryParse(priceController.text) ??
                                  package.price,
                              'durationDays':
                              int.tryParse(durationController.text) ??
                                  package.durationDays,
                              'features': features,
                              'isFeatured': isFeatured,
                              'isUnlimited': isUnlimited,
                              'maxSessions': maxSessions,
                              'weeklySessions': weeklySessions,
                              'branch': branchName,
                            });
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(package == null
                                    ? 'Package created'
                                    : 'Package updated'),
                                backgroundColor: Colors.green.shade800,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE50914),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          textStyle: GoogleFonts.inter(
                              fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        child: Text(package == null ? 'CREATE' : 'SAVE'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ===== BRANCH DROPDOWN WIDGET =====
  Widget _buildBranchDropdown({
    required List<BranchModel> branches,
    required String? selectedId,
    required Function(String) onChanged,
  }) {
    if (branches.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFE50914).withOpacity(0.05),
          border: Border.all(color: const Color(0xFFE50914).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 14, color: Color(0xFFE50914)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No active branches. Create one first.',
                style: GoogleFonts.inter(
                    fontSize: 10, color: const Color(0xFFE50914)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black.withOpacity(0.6),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined,
              size: 16, color: Colors.white54),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedId,
                isExpanded: true,
                dropdownColor: const Color(0xFF0A0A0A),
                icon: const Icon(Icons.arrow_drop_down,
                    color: Colors.white54, size: 18),
                hint: Text(
                  'Select Branch',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: Colors.white38),
                ),
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.white),
                items: branches.map((branch) {
                  return DropdownMenuItem<String>(
                    value: branch.id,
                    child: Text(
                      branch.name,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white),
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

  Widget _buildDialogTextField(TextEditingController controller, String label,
      {bool isNumber = false, int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle:
          GoogleFonts.inter(color: Colors.white24, fontSize: 11),
          labelStyle:
          GoogleFonts.inter(color: Colors.white54, fontSize: 11),
          filled: true,
          fillColor: Colors.black.withOpacity(0.6),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
            BorderSide(color: const Color(0xFFE50914).withOpacity(0.5)),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomCheckbox(
      String title, bool value, Function(bool?) onChanged) {
    return Theme(
      data: ThemeData(
        unselectedWidgetColor: Colors.white30,
      ),
      child: CheckboxListTile(
        title: Text(title,
            style:
            GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFE50914),
        checkColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      ),
    );
  }

  Future<void> _deletePackage(
      BuildContext context, AdminProvider provider, PackageModel package) async {
    final confirm = await showGeneralDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      barrierDismissible: true,
      barrierLabel: 'DeleteDialog',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) =>
      const SizedBox(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: FadeTransition(
              opacity: animation,
              child: AlertDialog(
                backgroundColor:
                const Color(0xFF0A0A0A).withOpacity(0.9),
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color: const Color(0xFFE50914).withOpacity(0.4)),
                ),
                title: Text(
                  'Delete Package',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                content: Text(
                  'Are you sure you want to delete "${package.name}"? This action cannot be undone.',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: Colors.white54)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      textStyle: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('DELETE'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirm == true && mounted) {
      await provider.deletePackage(package.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Package deleted'),
              backgroundColor: Color(0xFFE50914)),
        );
      }
    }
  }
}
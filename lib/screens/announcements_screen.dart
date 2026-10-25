import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';
import '../models/announcement_model.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _audience = 'All Members';
  final Set<String> _selectedPlayerIds = {};

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final announcements = provider.announcements;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compose
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppConstants.bgCard,
              border: Border.all(color: AppConstants.ink.withValues(alpha: 0.07)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'New Announcement',
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.ink,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 13, color: AppConstants.ink),
                  decoration: InputDecoration(
                    hintText: 'Announcement title...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppConstants.inkFaint),
                    filled: true,
                    fillColor: AppConstants.bgCard2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppConstants.ink.withValues(alpha: 0.07)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppConstants.ink.withValues(alpha: 0.07)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppConstants.gold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13, color: AppConstants.ink),
                  decoration: InputDecoration(
                    hintText: 'Write your announcement message...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppConstants.inkFaint),
                    filled: true,
                    fillColor: AppConstants.bgCard2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppConstants.ink.withValues(alpha: 0.07)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppConstants.ink.withValues(alpha: 0.07)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppConstants.gold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Audience selection
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildAudienceChip('All Members'),
                    _buildAudienceChip('Specific Players'),
                  ],
                ),
                if (_audience == 'Specific Players') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppConstants.bgCard2,
                      border: Border.all(color: AppConstants.ink.withValues(alpha: 0.07)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Selected: ${_selectedPlayerIds.length} players',
                              style: const TextStyle(fontSize: 12, color: AppConstants.inkDim),
                            ),
                            TextButton(
                              onPressed: () => _showPlayerSelector(provider),
                              child: const Text(
                                'SELECT PLAYERS',
                                style: TextStyle(fontSize: 11, color: AppConstants.goldSoft),
                              ),
                            ),
                          ],
                        ),
                        if (_selectedPlayerIds.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _selectedPlayerIds.map((uid) {
                              final player = provider.players.where((p) => p.uid == uid).firstOrNull;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: AppConstants.gold.withValues(alpha: 0.12),
                                  border: Border.all(color: AppConstants.gold.withValues(alpha: 0.16)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      player?.fullName ?? uid,
                                      style: const TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontSize: 9.5,
                                        color: AppConstants.goldSoft,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => _selectedPlayerIds.remove(uid));
                                      },
                                      child: const Icon(Icons.close, size: 12, color: AppConstants.emberGlow),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Title and message are required'),
                          backgroundColor: AppConstants.ember,
                        ),
                      );
                      return;
                    }

                    if (_audience == 'Specific Players' && _selectedPlayerIds.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Select at least one player'),
                          backgroundColor: AppConstants.ember,
                        ),
                      );
                      return;
                    }

                    final announcement = AnnouncementModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: _titleController.text.trim(),
                      message: _messageController.text.trim(),
                      audience: _audience == 'All Members' ? 'All Members' : 'Specific Players',
                      sentAt: DateTime.now(),
                      sentBy: provider.admin?.fullName ?? 'Admin',
                    );

                    await provider.sendAnnouncement(
                      announcement,
                      selectedPlayerIds: _audience == 'All Members' ? null : _selectedPlayerIds.toList(),
                    );

                    _titleController.clear();
                    _messageController.clear();
                    _selectedPlayerIds.clear();
                    setState(() => _audience = 'All Members');

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Announcement sent'),
                          backgroundColor: AppConstants.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.send, size: 14),
                  label: const Text(
                    'SEND ANNOUNCEMENT',
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.gold,
                    foregroundColor: const Color(0xFF1A1305),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Sent Announcements',
            style: TextStyle(
              fontFamily: 'Oswald',
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppConstants.ink,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppConstants.bgCard,
              border: Border.all(color: AppConstants.ink.withValues(alpha: 0.07)),
            ),
            child: announcements.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No announcements yet',
                  style: TextStyle(fontSize: 12, color: AppConstants.inkFaint),
                ),
              ),
            )
                : Column(
              children: announcements.asMap().entries.map((entry) {
                final index = entry.key;
                final announcement = entry.value;
                final isLast = index == announcements.length - 1;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                      bottom: BorderSide(
                        color: AppConstants.ink.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          color: AppConstants.bgCard2,
                        ),
                        child: const Icon(Icons.campaign, color: AppConstants.goldSoft, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              announcement.title,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              announcement.message,
                              style: const TextStyle(fontSize: 11, color: AppConstants.inkDim),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${announcement.audience} · Sent ${DateFormat('dd MMM, HH:mm').format(announcement.sentAt)}',
                              style: const TextStyle(fontSize: 10, color: AppConstants.inkFaint),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteAnnouncement(provider, announcement),
                        icon: const Icon(Icons.delete_outline, color: AppConstants.emberGlow, size: 16),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceChip(String label) {
    final isSelected = _audience == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _audience = label;
          if (label == 'All Members') {
            _selectedPlayerIds.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected
              ? AppConstants.gold.withValues(alpha: 0.12)
              : AppConstants.bgCard2,
          border: Border.all(
            color: isSelected
                ? AppConstants.gold.withValues(alpha: 0.16)
                : AppConstants.ink.withValues(alpha: 0.07),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: isSelected ? AppConstants.goldSoft : AppConstants.inkDim,
          ),
        ),
      ),
    );
  }

  void _showPlayerSelector(AdminProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Players',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.ink,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close, color: AppConstants.ink),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose one or more players to send this announcement to',
                    style: TextStyle(fontSize: 12, color: AppConstants.inkDim),
                  ),
                  const SizedBox(height: 16),
                  // Select all button
                  Row(
                    children: [
                      Checkbox(
                        value: _selectedPlayerIds.length == provider.players.length && provider.players.isNotEmpty,
                        onChanged: (value) {
                          setSheetState(() {
                            if (value == true) {
                              _selectedPlayerIds.addAll(provider.players.map((p) => p.uid));
                            } else {
                              _selectedPlayerIds.clear();
                            }
                          });
                          setState(() {});
                        },
                        activeColor: AppConstants.gold,
                      ),
                      const Text(
                        'Select All',
                        style: TextStyle(fontSize: 13, color: AppConstants.ink),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: provider.players.length,
                      itemBuilder: (context, index) {
                        final player = provider.players[index];
                        final isSelected = _selectedPlayerIds.contains(player.uid);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setSheetState(() {
                              if (value == true) {
                                _selectedPlayerIds.add(player.uid);
                              } else {
                                _selectedPlayerIds.remove(player.uid);
                              }
                            });
                            setState(() {});
                          },
                          activeColor: AppConstants.gold,
                          title: Text(
                            player.fullName,
                            style: const TextStyle(fontSize: 13, color: AppConstants.ink),
                          ),
                          subtitle: Text(
                            '${player.sport} · ${player.level}',
                            style: const TextStyle(fontSize: 10.5, color: AppConstants.inkFaint),
                          ),
                          secondary: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              color: AppConstants.bgCard2,
                            ),
                            child: Center(
                              child: Text(
                                player.initials,
                                style: const TextStyle(
                                  fontFamily: 'Oswald',
                                  fontSize: 12,
                                  color: AppConstants.goldSoft,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.gold,
                      foregroundColor: const Color(0xFF1A1305),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'CONFIRM (${_selectedPlayerIds.length} selected)',
                      style: const TextStyle(
                        fontFamily: 'Oswald',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // announcements_screen.dart içindeki _deleteAnnouncement metodu
  Future<void> _deleteAnnouncement(AdminProvider provider, AnnouncementModel announcement) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppConstants.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppConstants.ember.withValues(alpha: 0.3)),
          ),
          title: const Text(
            'Delete Announcement',
            style: TextStyle(fontFamily: 'Oswald', fontSize: 18, color: AppConstants.ink),
          ),
          content: Text(
            'Are you sure you want to delete "${announcement.title}"?',
            style: const TextStyle(fontSize: 13, color: AppConstants.inkDim),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel', style: TextStyle(color: AppConstants.inkDim)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.ember,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      await provider.deleteAnnouncement(announcement.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement deleted'),
            backgroundColor: AppConstants.ember,
          ),
        );
      }
    }
  }
}
// tournaments_screen.dart - GÜNCELLENMİŞ
// Edit ve Delete butonları ekle
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';
import '../models/tournament_model.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final tournaments = provider.tournaments;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 250,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppConstants.bgCard2,
                    border: Border.all(color: AppConstants.ink.withValues(alpha: 0.07)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, size: 15, color: AppConstants.inkFaint),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          style: TextStyle(fontSize: 12.5, color: AppConstants.ink),
                          decoration: InputDecoration(
                            hintText: 'Search tournaments...',
                            hintStyle: TextStyle(fontSize: 12.5, color: AppConstants.inkFaint),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateTournamentDialog(provider),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('CREATE TOURNAMENT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.gold,
                  foregroundColor: const Color(0xFF1A1305),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (tournaments.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppConstants.bgCard,
                border: Border.all(color: AppConstants.ink.withValues(alpha: 0.07)),
              ),
              child: const Center(
                child: Text('No tournaments yet', style: TextStyle(fontSize: 13, color: AppConstants.inkFaint)),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 900
                    ? 3
                    : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.1 : 1.3,
              ),
              itemCount: tournaments.length,
              itemBuilder: (context, index) {
                return _buildTournamentCard(tournaments[index], provider);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTournamentCard(TournamentModel tournament, AdminProvider provider) {
    final statusColor = tournament.status == 'registration_open'
        ? AppConstants.green
        : tournament.status == 'brackets_set'
        ? AppConstants.goldSoft
        : AppConstants.blue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppConstants.bgCard,
        border: Border.all(color: AppConstants.ink.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: statusColor.withValues(alpha: 0.12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  tournament.status == 'registration_open' ? 'Registration Open' : tournament.status == 'brackets_set' ? 'Brackets Set' : 'Completed',
                  style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 9.5, color: statusColor),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppConstants.inkDim),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditTournamentDialog(provider, tournament);
                  } else if (value == 'delete') {
                    _deleteTournament(provider, tournament);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tournament.name,
            style: const TextStyle(fontFamily: 'Oswald', fontSize: 16, fontWeight: FontWeight.w600, color: AppConstants.ink),
          ),
          const SizedBox(height: 6),
          Text(
            '${DateFormat('dd MMM').format(tournament.startDate)} – ${DateFormat('dd MMM').format(tournament.endDate)} · ${tournament.venue}',
            style: const TextStyle(fontSize: 11.5, color: AppConstants.inkDim),
          ),
          const SizedBox(height: 12),
          _buildTournamentInfo('Registered:', '${tournament.registeredCount} / ${tournament.maxParticipants}'),
          _buildTournamentInfo('Weight Classes:', '${tournament.weightClasses}'),
          _buildTournamentInfo('Our Fighters:', '${tournament.ourFighters}'),
          const Spacer(),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${tournament.name} - Viewing bracket'), backgroundColor: AppConstants.green),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.ink,
              side: BorderSide(color: AppConstants.gold.withValues(alpha: 0.16)),
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              tournament.status == 'completed' ? 'VIEW RESULTS' : 'VIEW BRACKET',
              style: const TextStyle(fontFamily: 'Oswald', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppConstants.inkDim)),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppConstants.goldSoft)),
        ],
      ),
    );
  }

  void _showCreateTournamentDialog(AdminProvider provider) {
    final nameController = TextEditingController();
    final venueController = TextEditingController();
    String status = 'registration_open';
    int maxParticipants = 96;
    int weightClasses = 8;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppConstants.bgCard,
          title: const Text('Create Tournament', style: TextStyle(fontFamily: 'Oswald', fontSize: 18, color: AppConstants.ink)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tournament Name')),
                const SizedBox(height: 10),
                TextField(controller: venueController, decoration: const InputDecoration(labelText: 'Venue')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  dropdownColor: AppConstants.bgCard,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    DropdownMenuItem(value: 'registration_open', child: Text('Registration Open')),
                    DropdownMenuItem(value: 'brackets_set', child: Text('Brackets Set')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  ],
                  onChanged: (value) => status = value!,
                ),
                const SizedBox(height: 10),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Max Participants', hintText: '$maxParticipants'),
                  onChanged: (value) => maxParticipants = int.tryParse(value) ?? 96,
                ),
                const SizedBox(height: 10),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Weight Classes', hintText: '$weightClasses'),
                  onChanged: (value) => weightClasses = int.tryParse(value) ?? 8,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final now = DateTime.now();
                final tournament = TournamentModel(
                  id: now.millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  startDate: now.add(const Duration(days: 14)),
                  endDate: now.add(const Duration(days: 16)),
                  venue: venueController.text,
                  status: status,
                  maxParticipants: maxParticipants,
                  weightClasses: weightClasses,
                );
                await provider.addTournament(tournament);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tournament created'), backgroundColor: AppConstants.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.gold),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showEditTournamentDialog(AdminProvider provider, TournamentModel tournament) {
    final nameController = TextEditingController(text: tournament.name);
    final venueController = TextEditingController(text: tournament.venue);
    String status = tournament.status;
    int maxParticipants = tournament.maxParticipants;
    int weightClasses = tournament.weightClasses;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppConstants.bgCard,
          title: const Text('Edit Tournament', style: TextStyle(fontFamily: 'Oswald', fontSize: 18, color: AppConstants.ink)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tournament Name')),
                const SizedBox(height: 10),
                TextField(controller: venueController, decoration: const InputDecoration(labelText: 'Venue')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  dropdownColor: AppConstants.bgCard,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    DropdownMenuItem(value: 'registration_open', child: Text('Registration Open')),
                    DropdownMenuItem(value: 'brackets_set', child: Text('Brackets Set')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  ],
                  onChanged: (value) => status = value!,
                ),
                const SizedBox(height: 10),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Max Participants', hintText: '$maxParticipants'),
                  onChanged: (value) => maxParticipants = int.tryParse(value) ?? tournament.maxParticipants,
                ),
                const SizedBox(height: 10),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Weight Classes', hintText: '$weightClasses'),
                  onChanged: (value) => weightClasses = int.tryParse(value) ?? tournament.weightClasses,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await provider.updateTournament(tournament.id, {
                  'name': nameController.text,
                  'venue': venueController.text,
                  'status': status,
                  'maxParticipants': maxParticipants,
                  'weightClasses': weightClasses,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tournament updated'), backgroundColor: AppConstants.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.gold),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTournament(AdminProvider provider, TournamentModel tournament) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppConstants.bgCard,
          title: const Text('Delete Tournament', style: TextStyle(fontFamily: 'Oswald', fontSize: 18, color: AppConstants.ink)),
          content: Text('Are you sure you want to delete "${tournament.name}"?', style: const TextStyle(fontSize: 13, color: AppConstants.inkDim)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.ember),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      await provider.deleteTournament(tournament.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournament deleted'), backgroundColor: AppConstants.ember),
        );
      }
    }
  }
}
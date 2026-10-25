import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';

class FightersScreen extends StatefulWidget {
  const FightersScreen({super.key});

  @override
  State<FightersScreen> createState() => _FightersScreenState();
}

class _FightersScreenState extends State<FightersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final fighters = provider.players
        .where((p) => p.wins > 0 || p.losses > 0 || p.winsByKO > 0 || p.winsByDecision > 0)
        .where((p) => p.fullName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
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
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 15, color: AppConstants.inkFaint),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (value) => setState(() => _searchQuery = value),
                          style: const TextStyle(fontSize: 12.5, color: AppConstants.ink),
                          decoration: const InputDecoration(
                            hintText: 'Search fighters...',
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
                onPressed: () => _showLogFightDialog(provider),
                icon: const Icon(Icons.add, size: 14),
                label: const Text(
                  'LOG FIGHT RESULT',
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

        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppConstants.bgCard,
              border: Border.all(color: AppConstants.ink.withValues(alpha: 0.07)),
            ),
            child: fighters.isEmpty
                ? const Center(
              child: Text(
                'No fighters with records yet',
                style: TextStyle(fontSize: 13, color: AppConstants.inkFaint),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: fighters.length,
              itemBuilder: (context, index) {
                final fighter = fighters[index];
                return _buildFighterTile(fighter);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFighterTile(fighter) {
    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: AppConstants.bgCard2,
        ),
        child: Center(
          child: Text(
            fighter.initials,
            style: const TextStyle(
              fontFamily: 'Oswald',
              fontSize: 12,
              color: AppConstants.goldSoft,
            ),
          ),
        ),
      ),
      title: Text(
        fighter.fullName,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppConstants.ink),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        fighter.weightClass,
        style: const TextStyle(fontSize: 11, color: AppConstants.inkFaint),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${fighter.wins}',
                  style: const TextStyle(color: AppConstants.green, fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: '-${fighter.losses}',
                  style: const TextStyle(color: AppConstants.emberGlow, fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: '-${fighter.draws}',
                  style: const TextStyle(color: AppConstants.inkDim),
                ),
              ],
            ),
            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12),
          ),
          const SizedBox(width: 16),
          Text(
            '${fighter.winsByKO} KO',
            style: const TextStyle(fontSize: 11, color: AppConstants.inkDim),
          ),
          const SizedBox(width: 12),
          Text(
            '${fighter.winsByDecision} Dec',
            style: const TextStyle(fontSize: 11, color: AppConstants.inkDim),
          ),
        ],
      ),
    );
  }

  void _showLogFightDialog(AdminProvider provider) {
    String selectedFighterUid = '';
    final opponentController = TextEditingController();
    String selectedResult = 'Win';
    String selectedWinType = 'KO';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppConstants.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppConstants.gold.withValues(alpha: 0.16)),
              ),
              title: const Text(
                'Log Fight Result',
                style: TextStyle(fontFamily: 'Oswald', fontSize: 18, color: AppConstants.ink),
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedFighterUid.isEmpty ? null : selectedFighterUid,
                        dropdownColor: AppConstants.bgCard,
                        style: const TextStyle(fontSize: 13, color: AppConstants.ink),
                        decoration: InputDecoration(
                          labelText: 'Fighter',
                          labelStyle: const TextStyle(color: AppConstants.inkFaint),
                          filled: true,
                          fillColor: AppConstants.bgCard2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppConstants.ink.withValues(alpha: 0.07)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppConstants.ink.withValues(alpha: 0.07)),
                          ),
                        ),
                        items: provider.players.map((p) {
                          return DropdownMenuItem(
                            value: p.uid,
                            child: Text('${p.fullName} (${p.weightClass})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedFighterUid = value!);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: opponentController,
                        style: const TextStyle(fontSize: 13, color: AppConstants.ink),
                        decoration: InputDecoration(
                          labelText: 'Opponent Name',
                          labelStyle: const TextStyle(color: AppConstants.inkFaint),
                          filled: true,
                          fillColor: AppConstants.bgCard2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppConstants.ink.withValues(alpha: 0.07)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppConstants.ink.withValues(alpha: 0.07)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppConstants.gold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedResult,
                        dropdownColor: AppConstants.bgCard,
                        style: const TextStyle(fontSize: 13, color: AppConstants.ink),
                        decoration: InputDecoration(
                          labelText: 'Result',
                          labelStyle: const TextStyle(color: AppConstants.inkFaint),
                          filled: true,
                          fillColor: AppConstants.bgCard2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppConstants.ink.withValues(alpha: 0.07)),
                          ),
                        ),
                        items: ['Win', 'Loss', 'Draw']
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedResult = value!);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedWinType,
                        dropdownColor: AppConstants.bgCard,
                        style: const TextStyle(fontSize: 13, color: AppConstants.ink),
                        decoration: InputDecoration(
                          labelText: 'Win Type',
                          labelStyle: const TextStyle(color: AppConstants.inkFaint),
                          filled: true,
                          fillColor: AppConstants.bgCard2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppConstants.ink.withValues(alpha: 0.07)),
                          ),
                        ),
                        items: ['KO', 'TKO', 'Decision', 'Submission']
                            .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedWinType = value!);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: AppConstants.inkDim)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedFighterUid.isEmpty || opponentController.text.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Select fighter and enter opponent name'),
                          backgroundColor: AppConstants.ember,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(dialogContext);

                    final fighter = provider.players
                        .where((p) => p.uid == selectedFighterUid)
                        .firstOrNull;

                    if (fighter != null) {
                      int wins = fighter.wins;
                      int losses = fighter.losses;
                      int draws = fighter.draws;
                      int winsByKO = fighter.winsByKO;
                      int winsByDecision = fighter.winsByDecision;

                      if (selectedResult == 'Win') {
                        wins++;
                        if (selectedWinType == 'KO' || selectedWinType == 'TKO') {
                          winsByKO++;
                        } else {
                          winsByDecision++;
                        }
                      } else if (selectedResult == 'Loss') {
                        losses++;
                      } else {
                        draws++;
                      }

                      await provider.updatePlayer(selectedFighterUid, {
                        'wins': wins,
                        'losses': losses,
                        'draws': draws,
                        'winsByKO': winsByKO,
                        'winsByDecision': winsByDecision,
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${fighter.fullName} $selectedResult vs ${opponentController.text} logged',
                            ),
                            backgroundColor: AppConstants.green,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.gold,
                    foregroundColor: const Color(0xFF1A1305),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
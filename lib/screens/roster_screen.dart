import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/roster_player.dart';
import '../providers/roster_provider.dart';

class RosterScreen extends ConsumerStatefulWidget {
  const RosterScreen({super.key});

  @override
  ConsumerState<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends ConsumerState<RosterScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _showAddOrEditPlayerDialog(BuildContext context, WidgetRef ref, [RosterPlayer? existingPlayer]) {
    final nameController = TextEditingController(text: existingPlayer?.name ?? '');
    final jerseyController = TextEditingController(text: existingPlayer?.jerseyNumber ?? '');
    String selectedPosition = existingPlayer?.position ?? 'Offense';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(existingPlayer == null ? 'Add Team Member' : 'Edit Player'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Player Name',
                    hintText: 'e.g. John Doe',
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: jerseyController,
                  decoration: const InputDecoration(
                    labelText: 'Jersey Number',
                    hintText: 'e.g. 23',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: selectedPosition,
                  isExpanded: true,
                  hint: const Text('Position / Role'),
                  items: const [
                    DropdownMenuItem(value: 'Offense', child: Text('Offense')),
                    DropdownMenuItem(value: 'Defense', child: Text('Defense')),
                    DropdownMenuItem(value: 'Goalie', child: Text('Goalie')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedPosition = val);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    final newPlayer = RosterPlayer(
                      id: existingPlayer?.id ?? const Uuid().v4(),
                      name: name,
                      jerseyNumber: jerseyController.text.trim(),
                      position: selectedPosition,
                    );

                    if (existingPlayer == null) {
                      ref.read(rosterProvider.notifier).addPlayer(newPlayer);
                    } else {
                      ref.read(rosterProvider.notifier).updatePlayer(newPlayer);
                    }
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roster = ref.watch(rosterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Roster'),
      ),
      body: roster.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Your roster is empty.',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add players to easily drop them onto the whiteboard.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: roster.length,
              itemBuilder: (context, index) {
                final player = roster[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: player.position == 'Offense' 
                          ? const Color(0xFF023398) 
                          : player.position == 'Defense'
                            ? Colors.red 
                            : Colors.orange,
                      foregroundColor: Colors.white,
                      child: Text(
                        player.jerseyNumber.isNotEmpty ? player.jerseyNumber : player.name[0],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(player.position),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showAddOrEditPlayerDialog(context, ref, player),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            ref.read(rosterProvider.notifier).removePlayer(player.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF38e77d),
        foregroundColor: const Color(0xFF023398),
        onPressed: () => _showAddOrEditPlayerDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/player_entity.dart';
import '../providers/drawing_provider.dart';
import '../providers/roster_provider.dart';

void showPlayerCustomizationDialog(BuildContext context, WidgetRef ref, {PlayerEntity? existingPlayer}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PlayerCustomizationSheet(existingPlayer: existingPlayer),
  );
}

class _PlayerCustomizationSheet extends ConsumerStatefulWidget {
  final PlayerEntity? existingPlayer;

  const _PlayerCustomizationSheet({this.existingPlayer});

  @override
  ConsumerState<_PlayerCustomizationSheet> createState() => _PlayerCustomizationSheetState();
}

class _PlayerCustomizationSheetState extends ConsumerState<_PlayerCustomizationSheet> {
  late TextEditingController _labelController;
  late Color _selectedColor;

  final List<Color> _availableColors = [
    const Color(0xFF023398), // Primary Blue
    const Color(0xFF38e77d), // Primary Green
    Colors.red,
    Colors.black,
    Colors.orange,
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    final defaultLabel = widget.existingPlayer?.label ?? "O";
    _labelController = TextEditingController(text: defaultLabel);
    
    // Default to the globally selected color if creating a new player
    _selectedColor = widget.existingPlayer?.color ?? 
        ref.read(drawingProvider).selectedColor;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine default Offense vs Defense based on label text for quick selection
    bool isOffense = _labelController.text.toUpperCase() == "O";
    bool isDefense = _labelController.text.toUpperCase() == "X";
    
    final roster = ref.watch(rosterProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existingPlayer == null ? 'Add Player' : 'Edit Player',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOffense ? const Color(0xFF023398) : Colors.grey[200],
                      foregroundColor: isOffense ? Colors.white : Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setState(() {
                        _labelController.text = "O";
                        // Auto switch color to blue if it makes sense, maybe not restrict it
                      });
                    },
                    child: const Text('Offense (O)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDefense ? Colors.red : Colors.grey[200],
                      foregroundColor: isDefense ? Colors.white : Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setState(() {
                        _labelController.text = "X";
                        _selectedColor = Colors.red; // Set explicit defense color intuitively
                      });
                    },
                    child: const Text('Defense (X)'),
                  ),
                ),
              ],
            ),
            
            // Roster Selector Integration
            if (roster.isNotEmpty && widget.existingPlayer == null) ...[
              const SizedBox(height: 24),
              const Text('Add from Roster', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: roster.length,
                  itemBuilder: (context, index) {
                    final rp = roster[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text('${rp.name} (${rp.jerseyNumber})'),
                        backgroundColor: rp.position == 'Offense' 
                          ? const Color(0xFF023398).withAlpha(30) 
                          : Colors.red.withAlpha(30),
                        onPressed: () {
                          setState(() {
                            _labelController.text = rp.jerseyNumber.isNotEmpty ? rp.jerseyNumber : rp.name[0];
                            if (rp.position == 'Offense') {
                              _selectedColor = const Color(0xFF023398);
                            } else if (rp.position == 'Defense') {
                              _selectedColor = Colors.red;
                            } else {
                              _selectedColor = Colors.orange;
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            TextField(
              controller: _labelController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              maxLength: 3,
              decoration: InputDecoration(
                labelText: 'Jersey / Label',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            const Text('Player Color', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _availableColors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 40 : 32,
                    height: isSelected ? 40 : 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF38e77d) : Colors.grey[400]!,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38e77d), // Secondary green
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                final notifier = ref.read(drawingProvider.notifier);
                
                if (widget.existingPlayer == null) {
                  final newEntity = PlayerEntity(
                    id: const Uuid().v4(),
                    position: const Offset(150, 150),
                    color: _selectedColor,
                    label: _labelController.text.isNotEmpty ? _labelController.text : "O",
                  );
                  notifier.addPlayer(newEntity);
                } else {
                  // Edit Existing
                  final updatedEntity = PlayerEntity(
                    id: widget.existingPlayer!.id,
                    position: widget.existingPlayer!.position,
                    color: _selectedColor,
                    label: _labelController.text.isNotEmpty ? _labelController.text : "O",
                  );
                  
                  // Instead of purely update position, create a full update method or reuse position logic with replacing
                  notifier.updatePlayerComplete(updatedEntity);
                }
                
                Navigator.pop(context);
              },
              child: Text(
                widget.existingPlayer == null ? 'Drop Player' : 'Save Changes',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

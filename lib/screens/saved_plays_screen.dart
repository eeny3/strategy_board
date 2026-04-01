import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/play_storage_provider.dart';
import '../providers/drawing_provider.dart';

class SavedPlaysScreen extends ConsumerStatefulWidget {
  const SavedPlaysScreen({super.key});

  @override
  ConsumerState<SavedPlaysScreen> createState() => _SavedPlaysScreenState();
}

class _SavedPlaysScreenState extends ConsumerState<SavedPlaysScreen> {
  String _searchQuery = '';
  String _selectedFolder = 'All';

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

  @override
  Widget build(BuildContext context) {
    final allSavedPlays = ref.watch(playStorageProvider);
    final storageNotifier = ref.read(playStorageProvider.notifier);
    final drawingNotifier = ref.read(drawingProvider.notifier);

    // Extract unique folders
    final Set<String> folders = {'All'};
    for (var p in allSavedPlays) {
      folders.add(p.folder);
    }

    // Filter plays
    final filteredPlays = allSavedPlays.where((play) {
      final matchesFolder = _selectedFolder == 'All' || play.folder == _selectedFolder;
      final matchesSearch = play.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFolder && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Plays'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Home',
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search plays...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
          
          // Folder Filter Chips
          if (folders.length > 1) // Only show if there's actually categories
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: folders.map((folder) {
                  final isSelected = _selectedFolder == folder;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(folder),
                      selected: isSelected,
                      selectedColor: const Color(0xFF023398).withAlpha(50),
                      onSelected: (selected) {
                        setState(() {
                          _selectedFolder = selected ? folder : 'All';
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          
          // Plays List
          Expanded(
            child: filteredPlays.isEmpty
                ? const Center(
                    child: Text(
                      'No matching plays found.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredPlays.length,
                    padding: const EdgeInsets.all(16.0),
                    itemBuilder: (context, index) {
                      final play = filteredPlays[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF023398),
                            child: Icon(
                              _getIconForBackground(play.backgroundType),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            play.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Folder: ${play.folder} • ${play.strokes.length} strokes',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _confirmDelete(context, () {
                                    storageNotifier.deletePlay(play.id);
                                  });
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            drawingNotifier.loadPlay(play);
                            Navigator.pop(context); // Go back to whiteboard
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Loaded ${play.name}')),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForBackground(dynamic type) {
    // We can just rely on the name from the enum
    final typeStr = type.toString();
    if (typeStr.contains('basketball')) return Icons.sports_basketball;
    if (typeStr.contains('soccer')) return Icons.sports_soccer;
    return Icons.sports_football;
  }

  void _confirmDelete(BuildContext context, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Play?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onDelete();
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

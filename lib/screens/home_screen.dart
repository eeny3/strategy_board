import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/play_storage_provider.dart';
import 'whiteboard_screen.dart';
import 'roster_screen.dart';
import 'drills_library_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
    
    // Extract unique folders
    final Set<String> folders = {'General'};
    for (var p in allSavedPlays) {
      folders.add(p.folder);
    }
    final folderList = folders.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playbooks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.timer),
            tooltip: 'Practice Plans',
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const DrillsLibraryScreen())
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.people_alt),
            tooltip: 'Team Roster',
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const RosterScreen())
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Whitespace',
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const WhiteboardScreen())
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Active Folders',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF023398),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: folderList.length,
                  itemBuilder: (context, index) {
                    final folderName = folderList[index];
                    final playCount = allSavedPlays.where((p) => p.folder == folderName).length;
                    
                    return _buildFolderCard(context, folderName, playCount);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF38e77d),
        foregroundColor: const Color(0xFF023398),
        icon: const Icon(Icons.draw),
        label: const Text('Draw Play', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => const WhiteboardScreen())
          );
        },
      ),
    );
  }

  Widget _buildFolderCard(BuildContext context, String folderName, int playCount) {
    return GestureDetector(
      onTap: () {
        // Later we can implement opening a specific folder or showing a filtered list.
        // For now, jump straight to the whiteboard to start drawing in this conceptual folder
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => const WhiteboardScreen())
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF023398),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Center(
                  child: Icon(Icons.folder_special, size: 64, color: Colors.white),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      folderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$playCount plays',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

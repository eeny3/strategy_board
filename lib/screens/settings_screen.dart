import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/play_storage_provider.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'App Data',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF023398)),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Clear All Saved Plays'),
            subtitle: const Text('This action permanently deletes all local data.'),
            onTap: () {
              _showClearDataConfirm(context, ref);
            },
          ),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Preferences',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF023398)),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Reset Onboarding'),
            subtitle: const Text('Show the first-launch tutorial again.'),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hasSeenOnboarding', false);

              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                );
              }
            },
          ),
          const Divider(),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                const Icon(Icons.sports_baseball_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'Digital Playbook & Whiteboard',
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                ),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showClearDataConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Plays?'),
        content: const Text('Are you sure you want to permanently delete ALL saved plays? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(playStorageProvider.notifier).clearAll();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All plays have been deleted.')),
              );
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

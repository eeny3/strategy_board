import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/play.dart';

final playStorageProvider = NotifierProvider<PlayStorageNotifier, List<Play>>(() {
  return PlayStorageNotifier();
});

class PlayStorageNotifier extends Notifier<List<Play>> {
  Future<void>? _loadFuture;

  @override
  List<Play> build() {
    _loadFuture = loadPlays(); // Auto load on init and keep track
    return [];
  }

  Future<Directory> get _localPath async {
    return await getApplicationDocumentsDirectory();
  }

  Future<void> savePlay(Play play) async {
    // Wait for the initial load to finish to prevent race conditions
    if (_loadFuture != null) {
      await _loadFuture;
    }

    try {
      final directory = await _localPath;
      // create a specific directory for our plays
      final playsDir = Directory('${directory.path}/digital_plays');
      if (!await playsDir.exists()) {
        await playsDir.create(recursive: true);
      }

      final file = File('${playsDir.path}/${play.id}.json');
      final jsonString = jsonEncode(play.toJson());
      await file.writeAsString(jsonString);

      // Add to our state list and sort by date
      final updatedList = [...state, play];
      updatedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = updatedList;
    } catch (e) {
      debugPrint('Error saving play: $e');
    }
  }

  Future<void> loadPlays() async {
    try {
      final directory = await _localPath;
      final playsDir = Directory('${directory.path}/digital_plays');
      if (!await playsDir.exists()) {
        state = [];
        return;
      }

      List<Play> loadedPlays = [];
      final files = playsDir.listSync();
      for (var entity in files) {
        if (entity is File && entity.path.endsWith('.json')) {
          final jsonString = await entity.readAsString();
          final playData = jsonDecode(jsonString);
          loadedPlays.add(Play.fromJson(playData));
        }
      }

      loadedPlays.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = loadedPlays;
    } catch (e) {
      debugPrint('Error loading plays: $e');
    }
  }

  Future<void> deletePlay(String id) async {
    if (_loadFuture != null) {
      await _loadFuture;
    }
    
    try {
      final directory = await _localPath;
      final file = File('${directory.path}/digital_plays/$id.json');
      if (await file.exists()) {
        await file.delete();
      }
      state = state.where((play) => play.id != id).toList();
    } catch (e) {
      debugPrint('Error deleting play: $e');
    }
  }

  Future<void> clearAll() async {
    if (_loadFuture != null) {
      await _loadFuture;
    }
    
    try {
      final directory = await _localPath;
      final playsDir = Directory('${directory.path}/digital_plays');
      if (await playsDir.exists()) {
        await playsDir.delete(recursive: true);
      }
      state = [];
    } catch (e) {
      debugPrint('Error clearing plays: $e');
    }
  }
}

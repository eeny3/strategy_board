import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/practice_drill.dart';

final drillStorageProvider = NotifierProvider<DrillStorageNotifier, List<PracticeDrill>>(() {
  return DrillStorageNotifier();
});

class DrillStorageNotifier extends Notifier<List<PracticeDrill>> {
  Future<void>? _loadFuture;

  @override
  List<PracticeDrill> build() {
    _loadFuture = loadDrills();
    return [];
  }

  Future<Directory> get _localPath async {
    return await getApplicationDocumentsDirectory();
  }

  Future<void> saveDrill(PracticeDrill drill) async {
    if (_loadFuture != null) {
      await _loadFuture;
    }

    try {
      final directory = await _localPath;
      final drillsDir = Directory('${directory.path}/digital_drills');
      if (!await drillsDir.exists()) {
        await drillsDir.create(recursive: true);
      }

      final file = File('${drillsDir.path}/${drill.id}.json');
      final jsonString = jsonEncode(drill.toJson());
      await file.writeAsString(jsonString);

      final updatedList = [...state, drill];
      updatedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = updatedList;
    } catch (e) {
      debugPrint('Error saving drill: $e');
    }
  }

  Future<void> loadDrills() async {
    try {
      final directory = await _localPath;
      final drillsDir = Directory('${directory.path}/digital_drills');
      if (!await drillsDir.exists()) {
        state = [];
        return;
      }

      List<PracticeDrill> loadedDrills = [];
      final files = drillsDir.listSync();
      for (var entity in files) {
        if (entity is File && entity.path.endsWith('.json')) {
          final jsonString = await entity.readAsString();
          final drillData = jsonDecode(jsonString);
          loadedDrills.add(PracticeDrill.fromJson(drillData));
        }
      }

      loadedDrills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = loadedDrills;
    } catch (e) {
      debugPrint('Error loading drills: $e');
    }
  }

  Future<void> deleteDrill(String id) async {
    if (_loadFuture != null) {
      await _loadFuture;
    }
    
    try {
      final directory = await _localPath;
      final file = File('${directory.path}/digital_drills/$id.json');
      if (await file.exists()) {
        await file.delete();
      }
      state = state.where((drill) => drill.id != id).toList();
    } catch (e) {
      debugPrint('Error deleting drill: $e');
    }
  }
}

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/roster_player.dart';

final rosterProvider = NotifierProvider<RosterNotifier, List<RosterPlayer>>(() {
  return RosterNotifier();
});

class RosterNotifier extends Notifier<List<RosterPlayer>> {
  @override
  List<RosterPlayer> build() {
    _loadRoster();
    return [];
  }

  static const _prefsKey = 'team_roster';

  Future<void> _loadRoster() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);
    
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> decodedList = jsonDecode(jsonString);
        state = decodedList.map((item) => RosterPlayer.fromJson(item)).toList();
      } catch (e) {
        state = [];
      }
    }
  }

  Future<void> _saveRoster() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(state.map((p) => p.toJson()).toList());
    await prefs.setString(_prefsKey, jsonString);
  }

  void addPlayer(RosterPlayer player) {
    state = [...state, player];
    _saveRoster();
  }

  void removePlayer(String id) {
    state = state.where((p) => p.id != id).toList();
    _saveRoster();
  }

  void updatePlayer(RosterPlayer updatedPlayer) {
    state = state.map((p) => p.id == updatedPlayer.id ? updatedPlayer : p).toList();
    _saveRoster();
  }
}

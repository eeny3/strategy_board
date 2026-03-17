import 'stroke.dart';
import 'player_entity.dart';

enum BackgroundType {
  basketball,
  soccer,
  football,
}

class Play {
  final String id;
  final String name;
  final BackgroundType backgroundType;
  final List<Stroke> strokes;
  final List<PlayerEntity> players;
  final String folder;
  final DateTime createdAt;

  Play({
    required this.id,
    required this.name,
    required this.backgroundType,
    required this.strokes,
    required this.players,
    this.folder = 'Uncategorized',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'backgroundType': backgroundType.name,
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'players': players.map((p) => p.toJson()).toList(),
      'folder': folder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Play.fromJson(Map<String, dynamic> json) {
    var rawStrokes = json['strokes'] as List?;
    List<Stroke> loadedStrokes = [];
    if (rawStrokes != null) {
      loadedStrokes = rawStrokes.map((s) => Stroke.fromJson(s as Map<String, dynamic>)).toList();
    }

    var rawPlayers = json['players'] as List?;
    List<PlayerEntity> loadedPlayers = [];
    if (rawPlayers != null) {
      loadedPlayers = rawPlayers.map((p) => PlayerEntity.fromJson(p as Map<String, dynamic>)).toList();
    }

    return Play(
      id: json['id'] as String,
      name: json['name'] as String,
      backgroundType: BackgroundType.values.firstWhere(
        (e) => e.name == json['backgroundType'],
        orElse: () => BackgroundType.basketball, // Default fallback
      ),
      strokes: loadedStrokes,
      players: loadedPlayers,
      folder: json['folder'] as String? ?? 'Uncategorized',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

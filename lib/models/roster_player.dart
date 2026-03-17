class RosterPlayer {
  final String id;
  final String name;
  final String jerseyNumber;
  final String position;

  const RosterPlayer({
    required this.id,
    required this.name,
    required this.jerseyNumber,
    required this.position,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'jerseyNumber': jerseyNumber,
      'position': position,
    };
  }

  factory RosterPlayer.fromJson(Map<String, dynamic> json) {
    return RosterPlayer(
      id: json['id'] as String,
      name: json['name'] as String,
      jerseyNumber: json['jerseyNumber'] as String,
      position: json['position'] as String,
    );
  }
}

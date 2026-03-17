import 'play.dart';

class PracticeDrill {
  final String id;
  final String title;
  final String description;
  final int estimatedMinutes;
  final List<Play> sequence;
  final DateTime createdAt;

  const PracticeDrill({
    required this.id,
    required this.title,
    required this.description,
    required this.estimatedMinutes,
    required this.sequence,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'estimatedMinutes': estimatedMinutes,
      'sequence': sequence.map((p) => p.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PracticeDrill.fromJson(Map<String, dynamic> json) {
    return PracticeDrill(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      estimatedMinutes: json['estimatedMinutes'] as int,
      sequence: (json['sequence'] as List<dynamic>)
          .map((item) => Play.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

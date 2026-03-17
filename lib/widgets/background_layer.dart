import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/play.dart';
import '../providers/drawing_provider.dart';

class BackgroundLayer extends ConsumerWidget {
  const BackgroundLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundType = ref.watch(
      drawingProvider.select((state) => state.backgroundType),
    );

    // Placeholders for actual images
    // The user will replace these with Image.asset('assets/images/basketball.png') etc.
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(_getBackgroundAsset(backgroundType)),
        ),
      ),
    );
  }

  String _getBackgroundAsset(BackgroundType type) {
    switch (type) {
      case BackgroundType.basketball:
        return "assets/images/basketball.jpg";
      case BackgroundType.soccer:
        return "assets/images/soccer.jpeg";
      case BackgroundType.football:
        return "assets/images/football.jpeg";
    }
  }
}

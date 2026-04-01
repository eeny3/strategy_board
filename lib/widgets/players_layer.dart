import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/drawing_provider.dart';
import 'player_customization_dialog.dart';

class PlayersLayer extends ConsumerWidget {
  const PlayersLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawingState = ref.watch(drawingProvider);
    final drawingNotifier = ref.read(drawingProvider.notifier);
    final isDrawMode = drawingState.toolMode == ToolMode.draw;

    return Stack(
      children: drawingState.players.map((player) {
        return Positioned(
          left: player.position.dx - 20, // Center the 40x40 circle
          top: player.position.dy - 20,
          child: IgnorePointer(
            ignoring: isDrawMode,
            child: GestureDetector(
              onPanUpdate: (details) {
                final renderBox = context.findRenderObject() as RenderBox;
                final localPosition = renderBox.globalToLocal(details.globalPosition);
                drawingNotifier.updatePlayerPosition(
                  player.id, 
                  localPosition
                );
              },
              onTap: () {
                 showPlayerCustomizationDialog(context, ref, existingPlayer: player);
              },
              onLongPress: () {
                 drawingNotifier.removePlayer(player.id);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: player.color, // Usually white or team color
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))
                  ],
                ),
                child: Center(
                  child: Text(
                    player.label,
                    style: TextStyle(
                      color: _getTextColorForBackground(player.color),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getTextColorForBackground(Color bg) {
    // If background is light, use dark text, else light text
    if (bg.computeLuminance() > 0.5) return Colors.black;
    return Colors.white;
  }
}

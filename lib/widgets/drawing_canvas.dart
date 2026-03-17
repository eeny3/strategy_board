import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/drawing_provider.dart';
import 'playbook_painter.dart';
import 'players_layer.dart';

class DrawingCanvas extends ConsumerWidget {
  const DrawingCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawingState = ref.watch(drawingProvider);
    final drawingNotifier = ref.read(drawingProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Stack(
          children: [
            GestureDetector(
              onPanStart: drawingState.toolMode == ToolMode.draw ? (details) {
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                final localPosition = renderBox.globalToLocal(details.globalPosition);
                drawingNotifier.startStroke(localPosition);
              } : null,
              onPanUpdate: drawingState.toolMode == ToolMode.draw ? (details) {
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                final localPosition = renderBox.globalToLocal(details.globalPosition);
                drawingNotifier.updateStroke(localPosition);
              } : null,
              onPanEnd: drawingState.toolMode == ToolMode.draw ? (details) {
                drawingNotifier.endStroke();
              } : null,
              child: Container(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                color: Colors.transparent,
                child: CustomPaint(
                  painter: PlaybookPainter(
                    strokes: drawingState.strokes,
                    currentStroke: drawingState.currentStroke,
                  ),
                  child: Container(),
                ),
              ),
            ),
            const PlayersLayer(),
          ],
        );

        return content;
      },
    );
  }
}

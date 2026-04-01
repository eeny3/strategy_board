import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import '../providers/drawing_provider.dart';
import '../models/stroke.dart';
import 'player_customization_dialog.dart';

class ToolsPanel extends ConsumerWidget {
  final VoidCallback? onHide;
  
  ToolsPanel({super.key, this.onHide});

  final List<Color> _availableColors = [
    const Color(0xFF023398), // Primary Blue
    const Color(0xFF38e77d), // Primary Green
    Colors.red,
    Colors.white,
  ];

  final List<LineType> _lineTypes = [
    LineType.solid,
    LineType.dashed,
    LineType.arrow,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawingState = ref.watch(drawingProvider);
    final drawingNotifier = ref.read(drawingProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(200),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withAlpha(100)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, 4),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Modes and Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Mode group
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModeToggle(
                            icon: Icons.edit,
                            tooltip: 'Draw',
                            isSelected: drawingState.toolMode == ToolMode.draw,
                            onTap: () => drawingNotifier.setToolMode(ToolMode.draw),
                          ),
                          const SizedBox(width: 8),
                          _buildModeToggle(
                            icon: Icons.pan_tool,
                            tooltip: 'Pan',
                            isSelected: drawingState.toolMode == ToolMode.panZoom,
                            onTap: () => drawingNotifier.setToolMode(ToolMode.panZoom),
                          ),
                        ],
                      ),
                      
                      // Add Player
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF023398),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(10),
                          shape: const CircleBorder(),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () {
                          showPlayerCustomizationDialog(context, ref);
                        },
                        child: const Tooltip(
                          message: 'Add Player',
                          child: Icon(Icons.person_add, size: 20),
                        ),
                      ),
                      
                      // Actions group
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.undo),
                            color: Colors.grey[800],
                            tooltip: 'Undo',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            onPressed: () {
                              drawingNotifier.undo();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red[400],
                            tooltip: 'Clear Board',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: const Text('Clear Board?'),
                                  content: const Text('This will clear all strokes and players.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context), 
                                      child: const Text('Cancel')
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () {
                                        drawingNotifier.clearBoard();
                                        Navigator.pop(context);
                                      }, 
                                      child: const Text('Clear', style: TextStyle(color: Colors.white))
                                    ),
                                  ],
                                )
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Row 2: Stroke Properties (Types & Thickness)
                  Row(
                    children: [
                      // Line Types
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _lineTypes.map((type) {
                          final isSelected = drawingState.selectedLineType == type;
                          IconData iconData;
                          String tooltip;
                          switch (type) {
                            case LineType.solid:
                              iconData = Icons.horizontal_rule;
                              tooltip = "Solid Line";
                              break;
                            case LineType.dashed:
                              iconData = Icons.more_horiz;
                              tooltip = "Dashed Line";
                              break;
                            case LineType.arrow:
                              iconData = Icons.arrow_outward;
                              tooltip = "Arrow";
                              break;
                          }

                          return Tooltip(
                            message: tooltip,
                            child: InkWell(
                              onTap: () => drawingNotifier.changeLineType(type),
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF023398).withAlpha(30) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  iconData,  
                                  color: isSelected ? const Color(0xFF023398) : Colors.grey[400],
                                  size: 24,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(width: 16),

                      // Stroke Thickness
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                          ),
                          child: Slider(
                            value: drawingState.selectedThickness,
                            min: 1.0,
                            max: 20.0,
                            activeColor: const Color(0xFF023398),
                            inactiveColor: Colors.grey[300],
                            onChanged: (val) {
                              drawingNotifier.changeThickness(val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Row 3: Colors
                  SizedBox(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _availableColors.length,
                            itemBuilder: (context, index) {
                              final color = _availableColors[index];
                              final isSelected = drawingState.selectedColor == color;
                              return GestureDetector(
                                onTap: () => drawingNotifier.changeColor(color),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 16),
                                  child: Center(
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: isSelected ? 32 : 24,
                                      height: isSelected ? 32 : 24,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFF38e77d) : Colors.grey[400]!,
                                          width: isSelected ? 3 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [BoxShadow(color: color.withAlpha(100), blurRadius: 8, spreadRadius: 2)]
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (onHide != null)
                          IconButton(
                            icon: const Icon(Icons.visibility_off),
                            color: Colors.grey[800],
                            tooltip: 'Hide Panel',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            onPressed: onHide,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle({
    required IconData icon, 
    required String tooltip, 
    required bool isSelected, 
    required VoidCallback onTap
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF023398) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF023398) : Colors.grey[400]!
            ),
          ),
          child: Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.grey[800]),
        ),
      ),
    );
  }
}

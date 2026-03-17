import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stroke.dart';
import '../models/play.dart';
import '../models/player_entity.dart';

enum ToolMode { draw, panZoom }

final drawingProvider = NotifierProvider<DrawingNotifier, DrawingState>(() {
  return DrawingNotifier();
});

class DrawingState {
  final List<Stroke> strokes;
  final List<PlayerEntity> players;
  final Stroke? currentStroke;
  final Color selectedColor;
  final double selectedThickness;
  final LineType selectedLineType;
  final BackgroundType backgroundType;
  final ToolMode toolMode;

  DrawingState({
    required this.strokes,
    required this.players,
    this.currentStroke,
    required this.selectedColor,
    required this.selectedThickness,
    required this.selectedLineType,
    required this.backgroundType,
    required this.toolMode,
  });

  DrawingState copyWith({
    List<Stroke>? strokes,
    List<PlayerEntity>? players,
    Stroke? currentStroke,
    Color? selectedColor,
    double? selectedThickness,
    LineType? selectedLineType,
    BackgroundType? backgroundType,
    ToolMode? toolMode,
  }) {
    return DrawingState(
      strokes: strokes ?? this.strokes,
      players: players ?? this.players,
      currentStroke: currentStroke, 
      selectedColor: selectedColor ?? this.selectedColor,
      selectedThickness: selectedThickness ?? this.selectedThickness,
      selectedLineType: selectedLineType ?? this.selectedLineType,
      backgroundType: backgroundType ?? this.backgroundType,
      toolMode: toolMode ?? this.toolMode,
    );
  }

  DrawingState clearCurrentStroke() {
     return DrawingState(
      strokes: strokes,
      players: players,
      currentStroke: null,
      selectedColor: selectedColor,
      selectedThickness: selectedThickness,
      selectedLineType: selectedLineType,
      backgroundType: backgroundType,
      toolMode: toolMode,
    );
  }
}

class DrawingNotifier extends Notifier<DrawingState> {
  @override
  DrawingState build() {
    return DrawingState(
      strokes: [],
      players: [],
      selectedColor: const Color(0xFF023398), // Default Blue
      selectedThickness: 4.0,
      selectedLineType: LineType.solid,
      backgroundType: BackgroundType.basketball,
      toolMode: ToolMode.draw,
    );
  }

  void startStroke(Offset point) {
    state = state.copyWith(
      currentStroke: Stroke(
        points: [point],
        color: state.selectedColor,
        thickness: state.selectedThickness,
        type: state.selectedLineType,
      ),
    );
  }

  void updateStroke(Offset point) {
    if (state.currentStroke != null) {
      final updatedPoints = List<Offset>.from(state.currentStroke!.points)..add(point);
      state = state.copyWith(
        currentStroke: Stroke(
          points: updatedPoints,
          color: state.selectedColor,
          thickness: state.selectedThickness,
          type: state.selectedLineType,
        ),
      );
    }
  }

  void endStroke() {
    if (state.currentStroke != null) {
      state = state.clearCurrentStroke().copyWith(
        strokes: [...state.strokes, state.currentStroke!],
      );
    }
  }

  void undo() {
    if (state.strokes.isNotEmpty) {
      final updatedStrokes = List<Stroke>.from(state.strokes)..removeLast();
      state = state.copyWith(strokes: updatedStrokes);
    }
  }

  void clearBoard() {
    state = state.copyWith(strokes: [], players: []);
  }

  void changeColor(Color color) {
    state = state.copyWith(selectedColor: color);
  }

  void changeThickness(double thickness) {
    state = state.copyWith(selectedThickness: thickness);
  }

  void changeLineType(LineType type) {
    state = state.copyWith(selectedLineType: type);
  }

  void changeBackground(BackgroundType type) {
    state = state.copyWith(backgroundType: type);
  }

  void setToolMode(ToolMode mode) {
    state = state.copyWith(toolMode: mode);
  }

  void addPlayer(PlayerEntity player) {
    state = state.copyWith(players: [...state.players, player]);
  }

  void updatePlayerPosition(String id, Offset newPos) {
    final updatedPlayers = state.players.map((p) {
      if (p.id == id) {
        return PlayerEntity(
          id: p.id,
          position: newPos,
          color: p.color,
          label: p.label,
        );
      }
      return p;
    }).toList();
    state = state.copyWith(players: updatedPlayers);
  }

  void updatePlayerComplete(PlayerEntity updatedPlayer) {
    final updatedPlayers = state.players.map((p) {
      if (p.id == updatedPlayer.id) return updatedPlayer;
      return p;
    }).toList();
    state = state.copyWith(players: updatedPlayers);
  }

  void removePlayer(String id) {
    final updatedPlayers = state.players.where((p) => p.id != id).toList();
    state = state.copyWith(players: updatedPlayers);
  }

  void loadPlay(Play play) {
    state = state.copyWith(
      strokes: play.strokes,
      players: play.players,
      backgroundType: play.backgroundType,
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:uuid/uuid.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/tools_panel.dart';
import '../widgets/background_layer.dart';
import '../providers/drawing_provider.dart';
import '../providers/play_storage_provider.dart';
import '../models/play.dart';
import 'saved_plays_screen.dart';
import 'settings_screen.dart';

class WhiteboardScreen extends ConsumerStatefulWidget {
  const WhiteboardScreen({super.key});

  @override
  ConsumerState<WhiteboardScreen> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends ConsumerState<WhiteboardScreen> {
  final ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final drawingState = ref.watch(drawingProvider);

    return Scaffold(
      backgroundColor: Colors.grey,
      body: Stack(
        children: [
          // Background + Canvas layer spanning full screen
          Positioned.fill(
            child: Screenshot(
              controller: screenshotController,
              child: InteractiveViewer(
                panEnabled: drawingState.toolMode == ToolMode.panZoom,
                scaleEnabled: drawingState.toolMode == ToolMode.panZoom,
                minScale: 0.5,
                maxScale: 4.0,
                child: Stack(
                  children: [
                    const BackgroundLayer(),
                    const DrawingCanvas(),
                  ],
                ),
              ),
            ),
          ),
          
          // Floating Top Navigation Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(200),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(50)),
                     boxShadow: const [
                       BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                     ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.list),
                        tooltip: 'Saved Plays',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPlaysScreen()));
                        },
                      ),
                      const Spacer(),
                      const Text(
                        'DIGITAL PLAYBOOK',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.save),
                        tooltip: 'Save Play',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        onPressed: () {
                          _showSaveDialog(context, ref);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        tooltip: 'Export',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        onPressed: () {
                          _showExportOptions(context);
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        tooltip: 'More Options',
                        offset: const Offset(0, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onSelected: (value) {
                          if (value == 'background') {
                            _showBackgroundSelector(context, ref);
                          } else if (value == 'settings') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'background',
                            child: Row(
                              children: [
                                Icon(Icons.map_outlined, size: 20),
                                SizedBox(width: 8),
                                Text('Change Background'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'settings',
                            child: Row(
                              children: [
                                Icon(Icons.settings, size: 20),
                                SizedBox(width: 8),
                                Text('Settings'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tools Panel positioned at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ToolsPanel(),
          ),
        ],
      ),
    );
  }

  void _showSaveDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final folderController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Save Play'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Play Name',
                  hintText: 'e.g. Inbound 1',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: folderController,
                decoration: const InputDecoration(
                  labelText: 'Folder / Category',
                  hintText: 'e.g. Offense',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final folder = folderController.text.trim();
                if (name.isNotEmpty) {
                  _savePlay(name, folder.isEmpty ? 'Uncategorized' : folder, ref);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Play saved locally!')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _savePlay(String name, String folder, WidgetRef ref) {
    final drawingState = ref.read(drawingProvider);
    final storageNotifier = ref.read(playStorageProvider.notifier);

    final newPlay = Play(
      id: const Uuid().v4(),
      name: name,
      backgroundType: drawingState.backgroundType,
      strokes: drawingState.strokes,
      players: drawingState.players,
      folder: folder,
      createdAt: DateTime.now(),
    );

    storageNotifier.savePlay(newPlay);
  }

  void _showBackgroundSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Select Background', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.sports_basketball),
                title: const Text('Basketball'),
                onTap: () {
                  ref.read(drawingProvider.notifier).changeBackground(BackgroundType.basketball);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sports_soccer),
                title: const Text('Soccer'),
                onTap: () {
                  ref.read(drawingProvider.notifier).changeBackground(BackgroundType.soccer);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sports_football),
                title: const Text('Football'),
                onTap: () {
                  ref.read(drawingProvider.notifier).changeBackground(BackgroundType.football);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Save to Gallery as Image'),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportImage(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Share as PDF'),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportPdf(context);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> _exportImage(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      final imageBytes = await screenshotController.capture();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/playbook_export_${DateTime.now().millisecondsSinceEpoch}.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(imageBytes);

        await Gal.putImage(imagePath);
        
        messenger.showSnackBar(
          const SnackBar(content: Text('Play exported to your Photo Gallery!')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to export image: $e')),
      );
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final imageBytes = await screenshotController.capture();
      if (imageBytes != null) {
        final pdf = pw.Document();
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(child: pw.Image(image)); // Center image in PDF
            },
          ),
        );

        final directory = await getTemporaryDirectory();
        final pdfPath = '${directory.path}/playbook_export_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File(pdfPath);
        await file.writeAsBytes(await pdf.save());

        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(pdfPath)], text: 'Check out this play!');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    }
  }
}



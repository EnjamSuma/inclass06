// In-Class Activity 06 — Drawing with Flutter
// Student: [Your Full Name]
// Date: September 29, 2026

import 'dart:math' show pi, Random;

import 'package:flutter/material.dart';

void main() => runApp(const SmileyApp());

class SmileyApp extends StatelessWidget {
  const SmileyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smiley Painter Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const DrawingPlayground(),
    );
  }
}

/// The named face designs (Level 3).
enum FaceType { classic, sleepy, surprised }

/// One saved snapshot of everything the user can change (bonus undo stack).
class FaceConfig {
  const FaceConfig({
    this.mood = 0.8,
    this.type = FaceType.classic,
    this.colorOverride,
    this.hat = false,
    this.glasses = false,
    this.mustache = false,
  });

  final double mood;
  final FaceType type;
  final Color? colorOverride; // set by long-press; cleared when slider moves
  final bool hat;
  final bool glasses;
  final bool mustache;

  /// Face color reacts to mood bands unless a random color was chosen.
  Color get faceColor {
    if (colorOverride != null) return colorOverride!;
    if (mood < 0.35) return Colors.lightBlue.shade300; // cool
    if (mood <= 0.7) return Colors.yellow.shade600; // neutral
    return Colors.orange.shade400; // warm
  }

  FaceConfig copyWith({
    double? mood,
    FaceType? type,
    Color? colorOverride,
    bool clearColor = false,
    bool? hat,
    bool? glasses,
    bool? mustache,
  }) {
    return FaceConfig(
      mood: mood ?? this.mood,
      type: type ?? this.type,
      colorOverride: clearColor ? null : (colorOverride ?? this.colorOverride),
      hat: hat ?? this.hat,
      glasses: glasses ?? this.glasses,
      mustache: mustache ?? this.mustache,
    );
  }
}

class DrawingPlayground extends StatefulWidget {
  const DrawingPlayground({super.key});

  @override
  State<DrawingPlayground> createState() => _DrawingPlaygroundState();
}

class _DrawingPlaygroundState extends State<DrawingPlayground> {
  FaceConfig config = const FaceConfig();
  final List<FaceConfig> undoStack = [];
  final Random rng = Random();

  /// Save the current configuration before a change.
  void _saveForUndo() => undoStack.add(config);

  void _undo() {
    if (undoStack.isEmpty) return;
    setState(() => config = undoStack.removeLast());
    _toast('Undo: restored previous face');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars() // remove old message first
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  String _name(FaceType t) => t.name[0].toUpperCase() + t.name.substring(1);

  void _setType(FaceType t) {
    setState(() {
      _saveForUndo();
      config = config.copyWith(type: t);
    });
  }

  // Level 4: tap cycles faces
  void _cycleFace() {
    final next = FaceType.values[(config.type.index + 1) % FaceType.values.length];
    setState(() {
      _saveForUndo();
      config = config.copyWith(type: next);
    });
    _toast('Face changed to ${_name(next)}');
  }

  // Level 4: long-press randomizes mood + face color
  void _randomize() {
    final newMood = rng.nextDouble();
    final newColor = Color.fromRGBO(
      100 + rng.nextInt(156),
      100 + rng.nextInt(156),
      100 + rng.nextInt(156),
      1,
    );
    setState(() {
      _saveForUndo();
      config = config.copyWith(mood: newMood, colorOverride: newColor);
    });
    _toast('Random mood ${newMood.toStringAsFixed(2)} and new face color');
  }

  Widget _accessoryButton({
    required IconData icon,
    required String tooltip,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return IconButton.filledTonal(
      isSelected: selected,
      tooltip: tooltip,
      icon: Icon(icon),
      selectedIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CustomPainter Smiley Lab'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
            onPressed: undoStack.isEmpty ? null : _undo,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Drawing area: fills available space so it scales with orientation
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: _cycleFace,
                onLongPress: _randomize,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: SmileyPainter(
                    mood: config.mood,
                    faceColor: config.faceColor,
                    type: config.type,
                    showHat: config.hat,
                    showGlasses: config.glasses,
                    showMustache: config.mustache,
                  ),
                ),
              ),
            ),
            // Controls: scrollable so nothing overflows in landscape
            Flexible(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text('Mood: ${config.mood.toStringAsFixed(2)}'),
                    Slider(
                      value: config.mood,
                      onChangeStart: (_) => _saveForUndo(), // one undo step per drag
                      onChanged: (double v) => setState(
                        () => config = config.copyWith(mood: v, clearColor: true),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final t in FaceType.values)
                          ChoiceChip(
                            label: Text(_name(t)),
                            selected: config.type == t,
                            onSelected: (_) => _setType(t),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _accessoryButton(
                          icon: Icons.school,
                          tooltip: 'Hat',
                          selected: config.hat,
                          onPressed: () => setState(() {
                            _saveForUndo();
                            config = config.copyWith(hat: !config.hat);
                          }),
                        ),
                        const SizedBox(width: 8),
                        _accessoryButton(
                          icon: Icons.visibility,
                          tooltip: 'Glasses',
                          selected: config.glasses,
                          onPressed: () => setState(() {
                            _saveForUndo();
                            config = config.copyWith(glasses: !config.glasses);
                          }),
                        ),
                        const SizedBox(width: 8),
                        _accessoryButton(
                          icon: Icons.face,
                          tooltip: 'Mustache',
                          selected: config.mustache,
                          onPressed: () => setState(() {
                            _saveForUndo();
                            config = config.copyWith(mustache: !config.mustache);
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap the face to cycle designs · long-press to randomize',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SmileyPainter extends CustomPainter {
  SmileyPainter({
    required this.mood,
    required this.faceColor,
    required this.type,
    required this.showHat,
    required this.showGlasses,
    required this.showMustache,
  });

  final double mood;
  final Color faceColor;
  final FaceType type;
  final bool showHat;
  final bool showGlasses;
  final bool showMustache;

  @override
  void paint(Canvas canvas, Size size) {
    // Everything is based on center and radius, so it stays responsive.
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.32; // leaves room for the hat

    final ink = Colors.black87;
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = ink;

    // 1) Face fill + border
    canvas.drawCircle(c, r, Paint()..color = faceColor);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // 2) Blush (happy faces only)
    if (mood > 0.7 && type != FaceType.sleepy) {
      final blush = Paint()..color = const Color.fromRGBO(255, 105, 180, 0.4);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(c.dx - r * 0.62, c.dy + r * 0.15),
            width: r * 0.28,
            height: r * 0.16),
        blush,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(c.dx + r * 0.62, c.dy + r * 0.15),
            width: r * 0.28,
            height: r * 0.16),
        blush,
      );
    }

    // 3) Eyes
    final eyeY = c.dy - r * 0.18;
    final eyeDx = r * 0.35;
    final leftEye = Offset(c.dx - eyeDx, eyeY);
    final rightEye = Offset(c.dx + eyeDx, eyeY);

    switch (type) {
      case FaceType.classic:
        canvas.drawCircle(leftEye, r * 0.09, fill);
        canvas.drawCircle(rightEye, r * 0.09, fill);
        break;
      case FaceType.sleepy:
        // Closed eyes: small downward-curving arcs
        for (final e in [leftEye, rightEye]) {
          canvas.drawArc(
            Rect.fromCenter(center: e, width: r * 0.3, height: r * 0.2),
            0.1 * pi,
            0.8 * pi,
            false,
            stroke,
          );
        }
        break;
      case FaceType.surprised:
        // Big white eyes with pupils
        for (final e in [leftEye, rightEye]) {
          canvas.drawCircle(e, r * 0.16, Paint()..color = Colors.white);
          canvas.drawCircle(
            e,
            r * 0.16,
            Paint()
              ..color = ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
          canvas.drawCircle(e, r * 0.07, fill);
        }
        break;
    }

    // 4) Mouth
    switch (type) {
      case FaceType.surprised:
        // Round open mouth
        final mouth = Rect.fromCenter(
          center: Offset(c.dx, c.dy + r * 0.42),
          width: r * 0.32,
          height: r * 0.45,
        );
        canvas.drawOval(mouth, Paint()..color = const Color(0xFF5A1A1A));
        canvas.drawOval(mouth, stroke..strokeWidth = 4);
        break;
      case FaceType.sleepy:
        // Soft, small smile
        canvas.drawArc(
          Rect.fromCenter(
              center: Offset(c.dx, c.dy + r * 0.3),
              width: r * 0.5,
              height: r * 0.25),
          0.15 * pi,
          0.7 * pi,
          false,
          stroke,
        );
        break;
      case FaceType.classic:
        if (mood < 0.35) {
          // Frown: top part of an oval placed lower on the face
          final frownRect = Rect.fromCenter(
            center: Offset(c.dx, c.dy + r * 0.55),
            width: r * 0.9,
            height: r * (0.3 + (0.35 - mood) * 0.8),
          );
          canvas.drawArc(frownRect, 1.15 * pi, 0.7 * pi, false, stroke);
        } else if (mood <= 0.7) {
          // Neutral / soft smile
          final rect = Rect.fromCenter(
            center: Offset(c.dx, c.dy + r * 0.25),
            width: r * 0.8,
            height: r * 0.35,
          );
          canvas.drawArc(rect, 0.2 * pi, 0.6 * pi, false, stroke);
        } else {
          // Big smile, optionally with an open-mouth fill
          final rect = Rect.fromCenter(
            center: Offset(c.dx, c.dy + r * 0.15),
            width: r * 1.0,
            height: r * (0.6 + (mood - 0.7) * 0.8),
          );
          if (mood > 0.85) {
            final open = Path()..addArc(rect, 0.1 * pi, 0.8 * pi);
            open.close();
            canvas.drawPath(open, Paint()..color = const Color(0xFF5A1A1A));
          }
          canvas.drawArc(rect, 0.1 * pi, 0.8 * pi, false, stroke);
        }
        break;
    }

    // 5) Accessories last so they sit on top
    if (showGlasses) {
      final glassRadius = r * 0.24;
      final glassPaint = Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(leftEye, glassRadius, glassPaint);
      canvas.drawCircle(rightEye, glassRadius, glassPaint);
      canvas.drawLine(
        Offset(leftEye.dx + glassRadius, eyeY),
        Offset(rightEye.dx - glassRadius, eyeY),
        glassPaint,
      );
    }

    if (showMustache) {
      final mPaint = Paint()..color = Colors.brown.shade700;
      final y = c.dy + r * 0.22;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(c.dx - r * 0.18, y), width: r * 0.38, height: r * 0.14),
        mPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(c.dx + r * 0.18, y), width: r * 0.38, height: r * 0.14),
        mPaint,
      );
    }

    if (showHat) {
      final hatPaint = Paint()..color = Colors.deepPurple;
      final brimY = c.dy - r * 0.95;
      // Crown
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(c.dx, brimY - r * 0.3),
              width: r * 0.9,
              height: r * 0.6),
          Radius.circular(r * 0.08),
        ),
        hatPaint,
      );
      // Brim
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(c.dx, brimY), width: r * 1.6, height: r * 0.14),
          Radius.circular(r * 0.07),
        ),
        Paint()..color = Colors.deepPurple.shade900,
      );
    }
  }

  // Repaint only if an input that affects the drawing changed.
  @override
  bool shouldRepaint(covariant SmileyPainter old) {
    return old.mood != mood ||
        old.faceColor != faceColor ||
        old.type != type ||
        old.showHat != showHat ||
        old.showGlasses != showGlasses ||
        old.showMustache != showMustache;
  }
}
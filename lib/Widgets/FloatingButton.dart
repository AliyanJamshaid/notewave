import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class FloatingButton extends StatelessWidget {
  final ValueNotifier<bool> isDialOpen;
  final VoidCallback onCreateNoteTap;
  final VoidCallback onVoiceNotesTap;

  const FloatingButton({
    super.key,
    required this.isDialOpen,
    required this.onCreateNoteTap,
    required this.onVoiceNotesTap,
  });

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      openCloseDial: isDialOpen,
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      animatedIconTheme: const IconThemeData(size: 22.0),
      curve: Curves.elasticInOut,
      childPadding: const EdgeInsets.all(8),
      spaceBetweenChildren: 10,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.note_add),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          onTap: onCreateNoteTap,
        ),
        SpeedDialChild(
          child: const Icon(Icons.keyboard_voice),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          onTap: onVoiceNotesTap,
        ),
      ],
    );
  }
}

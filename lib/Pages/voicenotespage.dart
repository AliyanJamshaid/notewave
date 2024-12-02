// voice_notes_page.dart
import 'package:flutter/material.dart';

class VoiceNotesPage extends StatelessWidget {
  const VoiceNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Notes'),
        backgroundColor: const Color(0xFF133E87),
      ),
      body: Center(
        child: const Text('Voice Notes Content'),
      ),
    );
  }
}

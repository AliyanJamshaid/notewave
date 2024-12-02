// voice_notes_page.dart
import 'package:flutter/material.dart';

class PhotoNotesPage extends StatelessWidget {
  const PhotoNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Notes'),
        backgroundColor: const Color(0xFF133E87),
      ),
      body: Center(
        child: const Text('Photo Notes Content'),
      ),
    );
  }
}

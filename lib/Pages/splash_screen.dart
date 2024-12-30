import 'package:flutter/material.dart';
import 'package:notewave/pages/notespage.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const NotesPage()),
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/logo.png',
          width: 150,
          height: 150,
        ),
      ),
    );
  }
}

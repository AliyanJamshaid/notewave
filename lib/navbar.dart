import 'package:flutter/material.dart';

// Page widgets remain the same
class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Notes Page'),
      ),
    );
  }
}

class VoiceNotesPage extends StatelessWidget {
  const VoiceNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Voice Notes Page'),
      ),
    );
  }
}

class PhotoNotesPage extends StatelessWidget {
  const PhotoNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Photo Notes Page'),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final Color customBlue = const Color(0xFF133E87);

  final List<Widget> _pages = const [
    NotesPage(),
    VoiceNotesPage(),
    PhotoNotesPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.note_alt_outlined),
              activeIcon: Icon(Icons.note_alt),
              label: _selectedIndex == 0 ? 'Notes' : '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.keyboard_voice_outlined),
              activeIcon: Icon(Icons.keyboard_voice),
              label: _selectedIndex == 1 ? 'Voice Notes' : '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_camera_outlined),
              activeIcon: Icon(Icons.photo_camera),
              label: _selectedIndex == 2 ? 'Photo Notes' : '',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: customBlue,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          iconSize: 28,
          onTap: _onItemTapped,
          showSelectedLabels: true,
          showUnselectedLabels: false,
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: const Color(0xFF133E87),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF133E87),
        ),
      ),
      home: const MainPage(),
    );
  }
}

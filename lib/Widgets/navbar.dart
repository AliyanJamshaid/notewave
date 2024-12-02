import 'package:flutter/material.dart';

class Navbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const Navbar(
      {super.key, required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    final Color customBlue = const Color(0xFF133E87);

    return Container(
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
            label: selectedIndex == 0 ? 'Notes' : '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.keyboard_voice_outlined),
            activeIcon: Icon(Icons.keyboard_voice),
            label: selectedIndex == 1 ? 'Voice Notes' : '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_camera_outlined),
            activeIcon: Icon(Icons.photo_camera),
            label: selectedIndex == 2 ? 'Photo Notes' : '',
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: customBlue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 28,
        onTap: onItemTapped,
        showSelectedLabels: true,
        showUnselectedLabels: false,
      ),
    );
  }
}

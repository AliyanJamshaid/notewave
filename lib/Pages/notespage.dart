import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Assuming these are the paths to your other pages
import 'package:notewave/Pages/create_note.dart';
import 'package:notewave/Widgets/note_item.dart';
import 'package:notewave/pages/voicenotespage.dart';
import 'package:notewave/pages/settingspage.dart'; // Import SettingsPage

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, dynamic>> _notes = [];
  ValueNotifier<bool> isDialOpen = ValueNotifier(false);
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? notesJson = prefs.getString("notes");

      if (notesJson != null) {
        final Map<String, dynamic> notesMap =
            Map<String, dynamic>.from(jsonDecode(notesJson));
        setState(() {
          _notes = notesMap.values.toList().cast<Map<String, dynamic>>();
          _notes.sort((a, b) => DateTime.parse(b['timestamp'])
              .compareTo(DateTime.parse(a['timestamp'])));
        });
      } else {
        print('No notes found.');
      }
    } catch (e) {
      print('Error loading notes: $e');
    }
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<Map<String, dynamic>> _getFilteredNotes() {
    if (_searchQuery.isEmpty) {
      return _notes;
    } else {
      return _notes
          .where((note) =>
              note['title'].toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotes = _getFilteredNotes();

    return Scaffold(
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.only(top: 20),
          child: const Text(
            'My Notes',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(
              color: Colors.grey,
              thickness: 1,
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                onChanged: _updateSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                
                  fillColor: Colors.grey[200],
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filteredNotes.isEmpty
                  ? Center(
                      child: Text(
                        'No notes yet. Tap + to create a note',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        return NoteItem(
                          id: note['id'],
                          title: note['title'] ?? 'Untitled Note',
                          description: "todo",
                          timestamp: _formatDate(note['timestamp']),
                          backgroundColor: note['color'] != null
                              ? Color(note['color'])
                              : const Color(0xFFF3E5F5),
                          onRefresh: _loadNotes,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        // Dial open/close controller
        openCloseDial: isDialOpen,
        icon: Icons.add,
        activeIcon: Icons.close,
        // Speed Dial properties
        //nimatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        animatedIconTheme: IconThemeData(size: 22.0),
        curve: Curves.elasticInOut,
        childPadding: const EdgeInsets.all(8),
        spaceBetweenChildren: 10,

        // Dial children (buttons)
        children: [
          SpeedDialChild(
            child: Icon(Icons.note_add),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateNotePage()),
              ).then((_) {
                _loadNotes(); // Refresh after adding a note
              });
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.keyboard_voice),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VoiceNotesPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(String timestamp) {
    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:notewave/Pages/create_note.dart';
import 'package:notewave/Widgets/note_item.dart';
import 'package:notewave/pages/voicenotespage.dart';
import 'package:notewave/Pages/viewnote.dart';
import 'package:notewave/pages/settingspage.dart';
import 'package:notewave/Widgets/FloatingButton.dart';
import 'package:notewave/services/notes_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, dynamic>> _notes = [];
  ValueNotifier<bool> isDialOpen = ValueNotifier(false);
  String _searchQuery = '';
  bool _isLoading = true;
  final NotesService _notesService = NotesService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    _searchFocusNode.unfocus();
    _initializeNotes();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeNotes() async {
    setState(() => _isLoading = true);
    await _loadLocalNotes();
    await _syncNotes();
    setState(() => _isLoading = false);
  }

  Future<void> _loadLocalNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localNotesJson = prefs.getString('local_notes');
      print(localNotesJson);
      if (localNotesJson != null) {
        final Map<String, dynamic> decodedJson = json.decode(localNotesJson);
        setState(() {
          _notes = decodedJson.values
              .map((note) => Map<String, dynamic>.from(note as Map))
              .toList();
          _sortNotes();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notes: $e')),
        );
      }
    }
  }

  Future<void> _saveLocalNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> notesMap = {
        for (var note in _notes)
          note['id'].toString(): Map<String, dynamic>.from(note)
      };
      await prefs.setString('local_notes', json.encode(notesMap));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving notes: $e')),
        );
      }
    }
  }

  Future<void> _syncNotes() async {
    try {
      final Map<String, dynamic> localNotesMap = {
        for (var note in _notes)
          note['id'].toString(): Map<String, dynamic>.from(note)
      };

      await _notesService.syncNotes(localNotesMap);

      final updatedNotes = await _notesService.getNotes();
      setState(() {
        _notes = updatedNotes;
        _sortNotes();
      });

      await _saveLocalNotes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error syncing notes: $e')),
        );
      }
    }
  }

  void _sortNotes() {
    _notes.sort((a, b) => DateTime.parse(b['timestamp'])
        .compareTo(DateTime.parse(a['timestamp'])));
  }

  Future<void> _refreshNotes() async {
    await _syncNotes();
  }

  List<Map<String, dynamic>> _getFilteredNotes() {
    if (_searchQuery.isEmpty) {
      return _notes;
    }
    return _notes
        .where((note) =>
            note['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (note['content'] ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  String _formatDate(String timestamp) {
    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredNotes = _getFilteredNotes();

    return Scaffold(
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.only(top: 20),
          child: Text(
            'My Notes',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: theme.iconTheme.color),
            onPressed: () {
              _searchFocusNode.unfocus();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              ).then((_) {
                _refreshNotes();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshNotes,
              color: theme.colorScheme.primary,
              child: Container(
                color: theme.scaffoldBackgroundColor,
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
                      child: Theme(
                        data: theme.copyWith(
                          inputDecorationTheme: InputDecorationTheme(
                            filled: true,
                            fillColor: theme.brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                        child: TextField(
                          autofocus: false,
                          focusNode: _searchFocusNode,
                          onChanged: (query) {
                            setState(() {
                              _searchQuery = query;
                            });
                          },
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search notes...',
                            hintStyle: TextStyle(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: theme.brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            prefixIconColor: theme.iconTheme.color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filteredNotes.isEmpty
                          ? Center(
                              child: Text(
                                'No notes yet. Tap + to create a note',
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: filteredNotes.length,
                              itemBuilder: (context, index) {
                                final note = filteredNotes[index];
                                return NoteItem(
                                  id: note['id'],
                                  content: note['content'] ?? '',
                                  title: note['title'] ?? 'Untitled Note',
                                  timestamp: _formatDate(note['timestamp']),
                                  backgroundColor: note['color'] != null
                                      ? Color(note['color'])
                                      : theme.colorScheme.primaryContainer,
                                  onRefresh: _refreshNotes,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingButton(
        isDialOpen: isDialOpen,
        onCreateNoteTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateNotePage()),
          ).then((_) {
            _refreshNotes();
          });
        },
        onVoiceNotesTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VoiceNotesPage()),
          );
        },
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper method to convert Firebase timestamp to ISO string
  String _convertTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now().toIso8601String();
    if (timestamp is Timestamp) return timestamp.toDate().toIso8601String();
    if (timestamp is String) return timestamp;
    return DateTime.now().toIso8601String();
  }

  // Helper method to ensure all required fields are present and timestamps are properly formatted
  Map<String, dynamic> _ensureNoteFields(Map<String, dynamic> note) {
    final now = DateTime.now().toIso8601String();

    // Convert any potential Timestamp objects to ISO strings
    final timestamp = _convertTimestamp(note['timestamp']);
    final createdAt = _convertTimestamp(note['createdAt']);
    final updatedAt = _convertTimestamp(note['updatedAt']);

    return {
      'id': note['id'] ?? '',
      'title': note['title'] ?? 'Untitled Note',
      'content': note['content'] ?? '',
      'timestamp': timestamp,
      'color': note['color'] ?? 0xFFF3E5F5,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Helper method to prepare note data for Firestore
  Map<String, dynamic> _prepareForFirestore(Map<String, dynamic> note) {
    // Convert ISO string dates to Timestamps for Firestore
    try {
      return {
        ...note,
        'timestamp': Timestamp.fromDate(DateTime.parse(note['timestamp'])),
        'createdAt': Timestamp.fromDate(DateTime.parse(note['createdAt'])),
        'updatedAt': Timestamp.fromDate(DateTime.parse(note['updatedAt'])),
      };
    } catch (e) {
      print('Error converting dates to Timestamps: $e');
      return note;
    }
  }

  // Create a new note
  Future<void> createNote({
    required String id,
    required String title,
    required String content,
    required String timestamp,
    required int color,
  }) async {
    final noteData = _ensureNoteFields({
      'id': id,
      'title': title,
      'content': content,
      'timestamp': timestamp,
      'color': color,
    });

    // Save to local storage first
    await _saveNoteLocally(id, noteData);

    // If user is logged in, also save to cloud
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final firestoreData = _prepareForFirestore(noteData);
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notes')
            .doc(id)
            .set(firestoreData);
      } catch (e) {
        print('Failed to save note to cloud: $e');
      }
    }
  }

  // Get all notes
  Future<List<Map<String, dynamic>>> getNotes() async {
    final localNotes = await _getLocalNotes();

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notes')
            .orderBy('timestamp', descending: true)
            .get();

        final cloudNotes =
            snapshot.docs.map((doc) => _ensureNoteFields(doc.data())).toList();

        return await _mergeNotes(localNotes, cloudNotes);
      } catch (e) {
        print('Failed to get cloud notes: $e');
      }
    }

    return localNotes;
  }

  // Update a note
  Future<void> updateNote({
    required String id,
    String? title,
    String? content,
    String? timestamp,
    int? color,
  }) async {
    final existingNote = await _getNoteLocally(id);
    if (existingNote == null) return;

    final updatedNote = Map<String, dynamic>.from(existingNote);
    if (title != null) updatedNote['title'] = title;
    if (content != null) updatedNote['content'] = content;
    if (timestamp != null) updatedNote['timestamp'] = timestamp;
    if (color != null) updatedNote['color'] = color;
    updatedNote['updatedAt'] = DateTime.now().toIso8601String();

    final completeNote = _ensureNoteFields(updatedNote);
    await _saveNoteLocally(id, completeNote);

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final firestoreData = _prepareForFirestore(completeNote);
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notes')
            .doc(id)
            .update(firestoreData);
      } catch (e) {
        print('Failed to update note in cloud: $e');
      }
    }
  }

  // Sync notes
  Future<void> syncNotes(Map<String, dynamic> localNotes) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .get();

      final cloudNotes = {
        for (var doc in snapshot.docs) doc.id: _ensureNoteFields(doc.data())
      };

      final batch = _firestore.batch();

      final localNotesList = localNotes.values
          .map((note) =>
              _ensureNoteFields(Map<String, dynamic>.from(note as Map)))
          .toList();
      final cloudNotesList = cloudNotes.values.toList();

      final mergedNotes = await _mergeNotes(localNotesList, cloudNotesList);

      // Update cloud with merged notes
      for (var note in mergedNotes) {
        final firestoreData = _prepareForFirestore(note);
        batch.set(
          _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notes')
              .doc(note['id']),
          firestoreData,
        );
      }

      await batch.commit();

      // Save merged notes locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'local_notes',
        json.encode({for (var note in mergedNotes) note['id']: note}),
      );
    } catch (e) {
      print('Error syncing notes: $e');
      throw Exception('Failed to sync notes: $e');
    }
  }

  // Delete a note
  Future<void> deleteNote(String id) async {
    // Delete locally first
    await _deleteNoteLocally(id);

    // If user is logged in, delete from cloud
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notes')
            .doc(id)
            .delete();
      } catch (e) {
        print('Failed to delete note from cloud: $e');
        // Continue anyway since we deleted locally
      }
    }
  }

  // Local storage helpers
  Future<void> _saveNoteLocally(
      String id, Map<String, dynamic> noteData) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString('local_notes') ?? '{}';
    final notes = Map<String, dynamic>.from(json.decode(notesJson));

    // Ensure all fields are present before saving
    notes[id] = _ensureNoteFields(noteData);
    await prefs.setString('local_notes', json.encode(notes));
  }

  Future<Map<String, dynamic>?> _getNoteLocally(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString('local_notes') ?? '{}';
    final notes = Map<String, dynamic>.from(json.decode(notesJson));
    final note = notes[id];
    return note != null ? _ensureNoteFields(note) : null;
  }

  Future<void> _deleteNoteLocally(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString('local_notes') ?? '{}';
    final notes = Map<String, dynamic>.from(json.decode(notesJson));

    if (notes.containsKey(id)) {
      notes.remove(id);
      await prefs.setString('local_notes', json.encode(notes));
      print('Note $id successfully deleted locally.');
    } else {
      print('Note $id not found in local storage.');
    }
  }

  Future<List<Map<String, dynamic>>> _getLocalNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString('local_notes') ?? '{}';
    final notes = Map<String, dynamic>.from(json.decode(notesJson));
    return notes.values
        .map(
            (note) => _ensureNoteFields(Map<String, dynamic>.from(note as Map)))
        .toList();
  }

  // Merge local and cloud notes
  Future<List<Map<String, dynamic>>> _mergeNotes(
    List<Map<String, dynamic>> localNotes,
    List<Map<String, dynamic>> cloudNotes,
  ) async {
    final mergedNotes = <String, Map<String, dynamic>>{};

    // Add all local notes with ensured fields
    for (final note in localNotes) {
      final completeNote = _ensureNoteFields(note);
      mergedNotes[completeNote['id']] = completeNote;
    }

    // Merge cloud notes, preferring the most recent version
    for (final cloudNote in cloudNotes) {
      final completeCloudNote = _ensureNoteFields(cloudNote);
      final id = completeCloudNote['id'];
      final localNote = mergedNotes[id];

      if (localNote == null) {
        // Note exists only in cloud
        mergedNotes[id] = completeCloudNote;
      } else {
        // Note exists in both places - compare timestamps
        try {
          final cloudUpdated = DateTime.parse(completeCloudNote['updatedAt']);
          final localUpdated = DateTime.parse(localNote['updatedAt']);

          if (cloudUpdated.isAfter(localUpdated)) {
            mergedNotes[id] = completeCloudNote;
          }
        } catch (e) {
          print('Error comparing timestamps: $e');
          // Keep local version if there's an error comparing timestamps
        }
      }
    }

    // Save merged notes locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_notes', json.encode(mergedNotes));

    return mergedNotes.values.toList();
  }

}

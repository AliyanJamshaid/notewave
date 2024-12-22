import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:notewave/services/notes_service.dart';
import 'package:notewave/pages/loginpage.dart';
import 'package:notewave/main.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  bool _isSyncEnabled = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotesService _notesService = NotesService();

  @override
  void initState() {
    super.initState();
    _checkSyncStatus();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('dark_mode') ?? false;
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  Future<void> _setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() {
      _isDarkMode = value;
    });
  }

  // Helper function to show error messages
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
    print('Error: $message');
  }

  // Save sync status to SharedPreferences
  Future<void> _setSyncEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sync_enabled', value);
  }

  // Retrieve sync status from SharedPreferences
  Future<void> _checkSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isSyncEnabled = prefs.getBool('sync_enabled') ?? false;

    setState(() {
      _isSyncEnabled = isSyncEnabled && _auth.currentUser != null;
    });
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      setState(() {
        _isSyncEnabled = false;
      });
    } catch (e) {
      _showError('Error signing out: ${e.toString()}');
    }
  }

  Future<void> _syncData() async {
    if (!_isSyncEnabled || _auth.currentUser == null) {
      _showError('Cannot sync: User not logged in');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser!;
      print('Starting sync for user: ${user.uid}');

      // 1. Get local notes
      final prefs = await SharedPreferences.getInstance();
      final localNotesJson = prefs.getString('notes');
      print('Local notes retrieved'); // Debug log

      Map<String, dynamic> localNotes = {};
      if (localNotesJson != null) {
        try {
          localNotes = Map<String, dynamic>.from(jsonDecode(localNotesJson));
          print(
              'Local notes parsed successfully: ${localNotes.length} notes'); // Debug log
        } catch (e) {
          print('Error parsing local notes: $e'); // Debug log
          _showError('Error reading local notes: ${e.toString()}');
          return;
        }
      }

      // 2. Use NotesService to sync notes
      try {
        await _notesService.syncNotes(localNotes);
        print('Notes synced successfully'); // Debug log
      } catch (e) {
        print('Error during sync: $e'); // Debug log
        _showError('Error syncing notes: ${e.toString()}');
        return;
      }

      // 3. Save the merged notes back to local storage
      try {
        final mergedNotes = await _notesService.getNotes();
        final mergedNotesMap = {for (var note in mergedNotes) note['id']: note};

        await prefs.setString('notes', jsonEncode(mergedNotesMap));
        print('Local storage updated with merged notes'); // Debug log
      } catch (e) {
        print('Error updating local storage: $e'); // Debug log
        _showError('Error saving to local storage: ${e.toString()}');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Unexpected error during sync: $e'); // Debug log
      _showError('Unexpected error during sync: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _refreshSettings() {
    _checkSyncStatus();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        actions: [
          if (user != null)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _signOut,
            ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.all(16.0),
            children: [
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text('Dark Mode'),
                      value: _isDarkMode,
                      onChanged: (bool value) async {
                        await _setDarkMode(value);
                        ThemeProvider.of(context)?.toggleTheme(value);
                      },
                    ),
                    SwitchListTile(
                      title: Text('Sync with Account'),
                      subtitle: Text(user == null
                          ? 'Login required for sync'
                          : 'Sync your notes across devices'),
                      value: _isSyncEnabled,
                      onChanged: user == null
                          ? null
                          : (bool value) async {
                              setState(() {
                                _isSyncEnabled = value;
                              });
                              await _setSyncEnabled(value); // Save sync status
                              if (value) {
                                await _syncData();
                              }
                            },
                    ),
                  ],
                ),
              ),
              if (user != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: _syncData,
                    child: Text('Force Sync Now'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              SizedBox(height: 16.0),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Account'),
                      subtitle: Text(user?.email ?? 'Not logged in'),
                    ),
                    ListTile(
                      leading: Icon(Icons.notifications),
                      title: Text('Notifications'),
                      subtitle: Text('Manage your notification settings'),
                    ),
                    ListTile(
                      leading: Icon(Icons.privacy_tip),
                      title: Text('Privacy'),
                      subtitle: Text('Manage your privacy settings'),
                    ),
                    if (user == null)
                      ListTile(
                        leading: Icon(Icons.login),
                        title: Text('Login'),
                        subtitle: Text('Sign in to enable sync'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()),
                          ).then((_) {
                            _refreshSettings();
                          });
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

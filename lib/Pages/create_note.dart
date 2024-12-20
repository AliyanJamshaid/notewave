import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class CreateNotePage extends StatefulWidget {
  final String? existingNoteId;
  const CreateNotePage({super.key, this.existingNoteId});

  @override
  State<CreateNotePage> createState() => _CreateNotePageState();
}

class _CreateNotePageState extends State<CreateNotePage> {
  final QuillController _controller = QuillController.basic();
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _editorFocusNode = FocusNode();

  // List of predefined colors for notes
  final List<Color> _noteColors = [
    Colors.blue[100]!,
    Colors.green[100]!,
    Colors.yellow[100]!,
    Colors.pink[100]!,
    Colors.purple[100]!,
    Colors.orange[100]!,
    Colors.teal[100]!,
  ];

  late Color _selectedColor;

  @override
  void initState() {
    super.initState();

    // Generate or load color
    _selectedColor = _getRandomColor();

    // Disable focus for both title and editor
    _titleFocusNode.unfocus();
    _editorFocusNode.unfocus();

    // If editing an existing note, load its content
    if (widget.existingNoteId != null) {
      _loadExistingNote();
    }
  }

  Color _getRandomColor() {
    final random = Random();
    return _noteColors[random.nextInt(_noteColors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _titleFocusNode.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    try {
      // Get the document as a JSON representation
      final content = jsonEncode(_controller.document.toDelta().toJson());
      final String noteId = widget.existingNoteId ?? _generateNoteId();

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final String? notesJson = prefs.getString("notes");

      Map<String, dynamic> notes = notesJson != null
          ? Map<String, dynamic>.from(jsonDecode(notesJson))
          : {};

      final noteData = {
        'id': noteId,
        'title': _titleController.text.isEmpty
            ? 'Untitled Note'
            : _titleController.text,
        'content': content, // Store as JSON string
        'timestamp': DateTime.now().toIso8601String(),
        'color': _selectedColor.value,
      };

      notes[noteId] = noteData;

      await prefs.setString("notes", jsonEncode(notes));

      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save note: $e')),
      );
    }
  }

  // Generate a unique note ID
  String _generateNoteId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  Future<void> _loadExistingNote() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? notesJson = prefs.getString("notes");

      if (notesJson != null) {
        final Map<String, dynamic> notes =
            Map<String, dynamic>.from(jsonDecode(notesJson));

        final existingNote = notes[widget.existingNoteId];
        if (existingNote != null) {
          // Set title
          _titleController.text = existingNote['title'] ?? '';

          // Set note color if exists
          if (existingNote['color'] != null) {
            setState(() {
              _selectedColor = Color(existingNote['color']);
            });
          }

          // Set note content from JSON
          if (existingNote['content'] != null) {
            final contentJson = jsonDecode(existingNote['content']);
            setState(() {
              _controller.document = Document.fromJson(contentJson);
            });

            // Ensure focus is cleared
            WidgetsBinding.instance.addPostFrameCallback((_) {
              FocusScope.of(context).unfocus();
            });
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading note: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        _titleFocusNode.unfocus();
        _editorFocusNode.unfocus();
      },
      child: Scaffold(
        backgroundColor: _selectedColor,
        appBar: AppBar(
          leading: IconButton(
            icon: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              icon: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              onPressed: _saveNote,
            ),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Note Title',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[600]),
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: QuillEditor.basic(
                controller: _controller,
                focusNode: _editorFocusNode,
                configurations: QuillEditorConfigurations(
                  autoFocus: false,
                ),
              ),
            ),
            QuillSimpleToolbar(
              controller: _controller,
              configurations: const QuillSimpleToolbarConfigurations(
                showBackgroundColorButton: false,
                showClearFormat: false,
                showIndent: false,
                showSubscript: false,
                showSuperscript: false,
                showRedo: false,
                showUndo: false,
                showCodeBlock: false,
                showFontSize: false,
                showFontFamily: false,
                showLink: false,
                showStrikeThrough: false,
                showInlineCode: false,
                showListCheck: false,
                showSearchButton: false,
                showClipboardCut: false,
                showClipboardPaste: false,
                showClipboardCopy: false,
                toolbarIconAlignment: WrapAlignment.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
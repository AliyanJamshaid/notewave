import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:notewave/services/notes_service.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
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
  final NotesService _notesService = NotesService();

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
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    print('CreateNotePage: initState called');

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
      print('CreateNotePage: Saving note');
      // Get the document as a JSON representation
      final content = jsonEncode(_controller.document.toDelta().toJson());
      final String noteId = widget.existingNoteId ?? _generateNoteId();
      final timestamp = DateTime.now().toIso8601String();

      print('CreateNotePage: Creating note with ID: $noteId');

      if (widget.existingNoteId != null) {
        // Update existing note
        await _notesService.updateNote(
          id: noteId,
          title: _titleController.text.isEmpty
              ? 'Untitled Note'
              : _titleController.text,
          content: content,
          timestamp: timestamp,
          color: _selectedColor.value,
        );
        print('CreateNotePage: Note updated successfully');
      } else {
        // Create new note
        await _notesService.createNote(
          id: noteId,
          title: _titleController.text.isEmpty
              ? 'Untitled Note'
              : _titleController.text,
          content: content,
          timestamp: timestamp,
          color: _selectedColor.value,
        );
        print('CreateNotePage: Note created successfully');
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('CreateNotePage: Error saving note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save note: $e')),
        );
      }
    }
  }

  String _generateNoteId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  Future<void> _loadExistingNote() async {
    try {
      print(
          'CreateNotePage: Loading existing note with ID: ${widget.existingNoteId}');
      final notes = await _notesService.getNotes();
      final existingNote = notes.firstWhere(
        (note) => note['id'] == widget.existingNoteId,
        orElse: () => {},
      );

      if (existingNote.isNotEmpty) {
        print('CreateNotePage: Found existing note: ${existingNote['title']}');
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
      } else {
        print(
            'CreateNotePage: No existing note found with ID: ${widget.existingNoteId}');
      }
    } catch (e) {
      print('CreateNotePage: Error loading note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading note: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityProvider(
      child: Scaffold(
        backgroundColor: _selectedColor,
        appBar: AppBar(
          leading: IconButton(
            icon: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
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
                decoration: const BoxDecoration(
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 30.0, vertical: 20.0),
                child: QuillEditor.basic(
                  controller: _controller,
                  focusNode: _editorFocusNode,
                  configurations: QuillEditorConfigurations(
                    placeholder: "Start writing...",
                    autoFocus: false,
                  ),
                ),
              ),
            ),
            KeyboardVisibilityBuilder(
              builder: (context, isKeyboardVisible) {
                return Column(
                  children: [
                    if (isKeyboardVisible)
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
                          showQuote: false,
                          toolbarIconAlignment: WrapAlignment.end,
                          sectionDividerSpace: 0,
                          toolbarSectionSpacing: 0,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

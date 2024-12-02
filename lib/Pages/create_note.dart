import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CreateNotePage extends StatefulWidget {
  const CreateNotePage({super.key});

  @override
  State<CreateNotePage> createState() => _CreateNotePageState();
}

class _CreateNotePageState extends State<CreateNotePage> {
  final QuillController _controller = QuillController.basic();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Save the note
  Future<void> _saveNote() async {
    try {
      final contents = jsonEncode(_controller.document.toDelta().toJson());
      print('Saving note: $contents');

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("note", contents);
      print('Note saved successfully!');
    } catch (e) {
      print('Error saving note: $e');
    }
  }

  // Retrieve the note from SharedPreferences and load it
  Future<void> _retrieveNote() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? savedNote = prefs.getString("note");

      if (savedNote != null) {
        print('Retrieved note: $savedNote');

        final delta = jsonDecode(savedNote);
        final doc = Document.fromJson(delta);
        setState(() {
          _controller.document = doc;
        });
      } else {
        print('No saved note found.');
      }
    } catch (e) {
      print('Error retrieving note: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _retrieveNote(); // Retrieve the saved note when the page initializes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            onPressed: _saveNote, // Trigger save when button is pressed
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: QuillEditor.basic(
              controller: _controller,
              configurations: const QuillEditorConfigurations(),
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
    );
  }
}

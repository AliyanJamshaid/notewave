import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:notewave/Pages/create_note.dart';
import 'dart:convert';

class ViewNote extends StatefulWidget {
  final String id;
  final String title;
  final String content;
  final Color backgroundColor;
  final VoidCallback? onRefresh;

  const ViewNote({
    super.key,
    required this.id,
    required this.title,
    required this.content,
    required this.backgroundColor,
    this.onRefresh,
  });

  @override
  State<ViewNote> createState() => _ViewNotePageState();
}

class _ViewNotePageState extends State<ViewNote> {
  final QuillController _controller = QuillController.basic();

  @override
  void initState() {
    super.initState();
    // Prevent keyboard from showing automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });

    // Set content immediately since we have it
    if (widget.content.isNotEmpty) {
      try {
        final contentJson = jsonDecode(widget.content);
        _controller.document = Document.fromJson(contentJson);
      } catch (e) {
        print('Error parsing note content: $e');
      }
    }
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNotePage(
          existingNoteId: widget.id,
        ),
      ),
    );

    // If note was edited and saved (result is true), call refresh callback
    if (result == true && widget.onRefresh != null) {
      widget.onRefresh!();
      Navigator.pop(context); // Close the view page after successful edit
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Edit button
          IconButton(
            icon: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 24,
              ),
            ),
            onPressed: _navigateToEdit,
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 30.0,
                vertical: 20.0,
              ),
              child: QuillEditor.basic(
                controller: _controller,
                configurations: QuillEditorConfigurations(
                  autoFocus: false,
                  disableClipboard: true,
                  requestKeyboardFocusOnCheckListChanged: false,
                  expands: false,
                  enableInteractiveSelection: false,
                  checkBoxReadOnly: true,
                  scrollable: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

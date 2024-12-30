import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import 'package:notewave/pages/create_note.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';

class NoteActionButtons extends StatelessWidget {
  final QuillController controller;
  final VoidCallback onEdit;

  const NoteActionButtons({
    Key? key,
    required this.controller,
    required this.onEdit,
  }) : super(key: key);

  void _copyNote(BuildContext context) async {
    final plainText = controller.document.toPlainText();
    await Clipboard.setData(ClipboardData(text: plainText));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      final pdf = pw.Document();
      final plainText = controller.document.toPlainText();

      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Text(
              plainText,
              style: const pw.TextStyle(fontSize: 12),
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'note_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF downloaded successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating PDF: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(
            Icons.edit,
            color: Colors.black, // Changed color to black
            size: 24,
          ),
          onPressed: onEdit,
          padding: const EdgeInsets.all(5),
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 3),
        IconButton(
          icon: const Icon(
            Icons.file_download,
            color: Colors.black, // Changed color to black
            size: 24,
          ),
          onPressed: () => _downloadPdf(context),
          padding: const EdgeInsets.all(5),
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 3),
        IconButton(
          icon: const Icon(
            Icons.copy,
            color: Colors.black, // Changed color to black
            size: 24,
          ),
          onPressed: () => _copyNote(context),
          padding: const EdgeInsets.all(5),
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

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
  late QuillController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });

    // Initialize QuillController
    if (widget.content.isNotEmpty) {
      try {
        final contentJson = jsonDecode(widget.content);
        _controller = QuillController(
          document: Document.fromJson(contentJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        print('Error parsing note content: $e');
        _controller = QuillController.basic();
      }
    } else {
      _controller = QuillController.basic();
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

    if (result == true && widget.onRefresh != null) {
      widget.onRefresh!();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: Colors.black,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          NoteActionButtons(
            controller: _controller,
            onEdit: _navigateToEdit,
          ),
        ],
        backgroundColor: widget.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
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
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30.0,
                  vertical: 20.0,
                ),
                child: QuillEditor.basic(
                  controller: _controller,
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
    _scrollController.dispose();
    super.dispose();
  }
}

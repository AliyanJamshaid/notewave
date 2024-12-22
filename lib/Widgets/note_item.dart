import 'package:flutter/material.dart';
import 'package:notewave/services/notes_service.dart';
import 'package:notewave/Pages/viewnote.dart';
import 'dart:convert';

class NoteItem extends StatelessWidget {
  final String id;
  final String title;
  final String content;
  final String timestamp;
  final Color backgroundColor;
  final VoidCallback? onRefresh;
  final NotesService _notesService = NotesService();

  NoteItem({
    super.key,
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    this.backgroundColor = const Color(0xFFFFFBFE),
    this.onRefresh,
  });

  String _parseContent() {
    try {
      final List<dynamic> contentList = json.decode(content);
      if (contentList.isNotEmpty && contentList[0]['insert'] != null) {
        return contentList[0]['insert'].toString().replaceAll('\\n', '');
      }
    } catch (e) {
      print('Error parsing content: $e');
    }
    return '';
  }

  String _formatDateTime(String timestamp) {
    try {
      final DateTime date = DateTime.parse(timestamp);
      final Duration difference = DateTime.now().difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String parsedContent = _parseContent();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: () => _editNote(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (parsedContent.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        parsedContent,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                          height: 1.4,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      _formatDateTime(timestamp),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Colors.grey[400],
                  ),
                  onPressed: () => _deleteNote(context),
                  splashRadius: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteNote(BuildContext context) async {
    try {
      final bool? shouldDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete Note',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            content: const Text(
              'Are you sure you want to delete this note?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (shouldDelete == true) {
        await _notesService.deleteNote(id);
        if (onRefresh != null) onRefresh!();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Note deleted'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.black87,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete note: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _editNote(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewNote(
          id: id,
          title: title,
          content: content,
          backgroundColor: backgroundColor,
          onRefresh: onRefresh,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:notewave/Widgets/note_item.dart';
import 'package:notewave/Pages/create_note.dart'; // Import the new page

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.only(top: 20), // Add padding to the top
          child: const Text(
            'My Notes',
            style: TextStyle(
              fontSize: 30, // Make the text larger
              fontWeight: FontWeight.bold, // Bold text
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true, // Center the title in the AppBar
      ),
      body: Container(
        color: Colors.grey[50], // Light background
        padding: const EdgeInsets.all(16.0),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Horizontal rule (divider) before the notes
            Divider(
              color: Colors.grey, // Color of the line
              thickness: 1, // Line thickness
              height: 20, // Space before and after the line
            ),
            NoteItem(
              title: 'E-commerce Idea',
              description:
                  'Personalize the shopping experience with AI suggestions, user flow, design...',
              timestamp: 'Nov 15, 2023 6:45 PM',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the CreateNotePage
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateNotePage()),
          );
        },
        backgroundColor: Colors.blue, // Set the background color to blue
        child: const Icon(
          Icons.add,
          color: Colors.white, // Set the icon color to white
        ),
      ),
    );
  }
}

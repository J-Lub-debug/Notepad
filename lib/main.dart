import 'package:flutter/material.dart';
import 'package:notepad/screens/Note.dart';

class ListOfNotes extends StatefulWidget {
  const ListOfNotes({super.key});

  @override
  State<ListOfNotes> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<ListOfNotes> {
  var noteTitle = <String>['Note 1', 'Note 2'];
  var noteContent = <String>['Text 1', 'Text 2'];

  late var originalNoteTitle = List<String>.from(noteTitle);
  late var originalNoteContent = List<String>.from(noteContent);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.search),
        title: TextField(
          //No const because it changes
          onChanged: (String string) {
            displayContaining(string);
          },
        ),
        backgroundColor: Colors.yellow,
      ),
      body: ListView.builder(
          itemCount: noteTitle.length,
          prototypeItem: ListTile(
            contentPadding: EdgeInsets.all(10),
            title:
                Text(noteTitle.firstWhere((element) => true, orElse: () => '')),
            subtitle: Text(
                noteContent.firstWhere((element) => true, orElse: () => '')),
          ),
          itemBuilder: (context, index) {
            return ListTile(
                title: Text(noteTitle[index]),
                subtitle: Text(noteContent[index]));
          }),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _navigateAndDisplaySelection(context);
        },
      ),
    );
  }

  Future<void> _navigateAndDisplaySelection(BuildContext context) async {
    // Navigator.push returns a Future that completes after calling
    // Navigator.pop on the Selection Screen.
    final result = await Navigator.push(
      context,
      // Create the Note screen in the next step.
      MaterialPageRoute(builder: (context) => Note()),
    );
    setState(() {
      noteTitle.add(result['title']);
      noteContent.add(result['subtitle']);
      originalNoteTitle.add(result['title']);
      originalNoteContent.add(result['subtitle']);
    });
  }

  void displayContaining(String string) {
    var noteTitleContaining = [];
    var noteContentContaining = [];

    for (var i = 0; i < originalNoteContent.length; i++) {
      if (originalNoteTitle[i].contains(string) ||
          originalNoteContent[i].contains(string)) {
        noteTitleContaining.add(originalNoteTitle[i]);
        noteContentContaining.add(originalNoteContent[i]);
      }
    }
    setState(() {
      noteTitle = List<String>.from(noteTitleContaining);
      noteContent = List<String>.from(noteContentContaining);
    });
  }
}

class TextFieldExampleApp extends StatelessWidget {
  const TextFieldExampleApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: ListOfNotes(),
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: const TextFieldExampleApp()));

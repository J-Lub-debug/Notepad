//Make an single database connection on init

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:notepad/screens/Note.dart';
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseProvider {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    final path = join(await getDatabasesPath(), 'notes.db');
    return await openDatabase(
      path,
      // When the database is first created, create a table to store notes.
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return db.execute(
          'CREATE TABLE Notes(id INTEGER PRIMARY KEY, title TEXT, subtitle TEXT)',
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
  }
}

class ListOfNotes extends StatefulWidget {
  const ListOfNotes({super.key});

  @override
  State<ListOfNotes> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<ListOfNotes> {
  var noteTitle = [];
  var noteContent = [];

  late var originalNoteTitle = [];
  late var originalNoteContent = [];

  late var isSelected =
      List<bool>.filled(noteTitle.length, false, growable: true);
  late var tileColor =
      List<Color>.filled(noteTitle.length, Colors.white, growable: true);

  var appBarActionsEnabled = false;

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
        actions: <Widget>[
          if (appBarActionsEnabled)
            IconButton(
                icon: Icon(Icons.delete),
                padding: EdgeInsets.all(2.0),
                onPressed: () => deleteSelectedNotes()),
        ],
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
                subtitle: Text(noteContent[index]),
                onLongPress: () {
                  toggleSelection(index);
                  toggleActions();
                },
                selected: isSelected[index],
                tileColor: tileColor[index],
                enabled: true);
          }),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _navigateAndDisplaySelection(context);
        },
      ),
    );
  }

  Future<void> deleteSelectedNotes() async {
    final database = await DatabaseProvider.database;
    // Remove the Note from the database.
    for (int i = 0; i < noteTitle.length; i++) {
      if (isSelected[i] == true) {
        await database.delete(
          'Notes',
          // Use a `where` clause to delete a specific note.
          where: 'id = ?',
          // Pass the Note's id as a whereArg to prevent SQL injection.
          whereArgs: [i],
        );
      }
    }
    setState(() {
      for (int i = 0; i < isSelected.length; i++) {
        if (isSelected[i] == true) {
          noteTitle.removeAt(i);
          noteContent.removeAt(i);
          originalNoteTitle.removeAt(i);
          originalNoteContent.removeAt(i);
          isSelected.removeAt(i);
          tileColor.removeAt(i);
        }
      }
    });
  }

  void toggleSelection(index) {
    setState(() {
      if (isSelected[index]) {
        tileColor[index] = Colors.white;
        isSelected[index] = false;
      } else {
        tileColor[index] = Colors.grey.shade300;
        isSelected[index] = true;
      }
    });
  }

  void toggleActions() {
    setState(() {
      if (isSelected.any((isTrue) => isTrue == true)) {
        appBarActionsEnabled = true;
      } else {
        appBarActionsEnabled = false;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    retrieveNotes();
  }

  Future<void> retrieveNotes() async {
    var tempNoteTitleWait = [];
    var tempNoteContentWait = [];

    final database = await DatabaseProvider.database;

    final List<Map<String, dynamic>> result = await selectNotesDB(database);

    for (final row in result) {
      tempNoteTitleWait.add(row['title']);
      tempNoteContentWait.add(row['subtitle']);
    }

    setState(() {
      noteTitle = List<String>.from(tempNoteTitleWait);
      noteContent = List<String>.from(tempNoteContentWait);
      originalNoteTitle = List<String>.from(tempNoteTitleWait);
      originalNoteContent = List<String>.from(tempNoteContentWait);
    });
  }

  // A method that retrieves all the notes from the Notes table.
  Future<List<Map<String, dynamic>>> selectNotesDB(database) async {
    // Get a reference to the database.
    final db = await database;
    // Query the table for all The notes.
    final List<Map<String, dynamic>> maps = await db.query('Notes');
    return maps;
  }

  Future<void> _navigateAndDisplaySelection(BuildContext context) async {
    // Navigator.push returns a Future that completes after calling
    // Navigator.pop on the Selection Screen.
    final result = await Navigator.push(
      context,
      // Create the Note screen in the next step.
      MaterialPageRoute(builder: (context) => Note()),
    );
    // Avoid errors caused by flutter upgrade.
    // Importing 'package:flutter/widgets.dart' is required.
    WidgetsFlutterBinding.ensureInitialized();
    // Open the database and store the reference.
    final database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), 'notes.db'),
    );
    await insertNote(result, database);
    setState(() {
      noteTitle.add(result['title']);
      noteContent.add(result['subtitle']);
      originalNoteTitle.add(result['title']);
      originalNoteContent.add(result['subtitle']);
      isSelected.add(false);
      tileColor.add(Colors.white);
    });
  }

  // Define a function that inserts notes into the database
  Future<void> insertNote(mapNote, database) async {
    // Get a reference to the database.
    final db = await database;

    // Insert the Note into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same note is inserted twice.
    //
    // In this case, replace any previous data.
    await db.insert(
      'Notes',
      mapNote,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

//Make tabs only clickable by Icons or other way around

import 'package:flutter/material.dart';
import 'package:notepad/screens/Note.dart';
import 'package:notepad/widgets/CheckboxLabel.dart';
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

//Singleton
class DatabaseProvider {
  static Database? _database;
  static bool _isDatabaseInitialized = false;

  static Future<Database> get database async {
    if (_isDatabaseInitialized) {
      return _database!;
    }
    _database = await _initDatabase();
    _isDatabaseInitialized = true;
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
      onCreate: (db, version) async {
        // Run the CREATE TABLE statement on the database.
        // CREATE Notes Table
        await db.execute(
          'CREATE TABLE Notes(id INTEGER PRIMARY KEY, title TEXT, subtitle TEXT)',
        );
        // CREATE ToDoLists and Points TABLEs
        await db.execute(
            'CREATE TABLE ToDoLists (id INTEGER PRIMARY KEY, title TEXT)');
        await db.execute(
            'CREATE TABLE Points (id INTEGER PRIMARY KEY, content TEXT, isChecked INTEGER, toDoListId INTEGER, FOREIGN KEY(toDoListId) REFERENCES ToDoLists(id) ON DELETE CASCADE ON UPDATE CASCADE)');
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
  }
}

class ListPoint {
  final String content;
  final bool isChecked;

  const ListPoint({required this.content, required this.isChecked});
}

class ToDoList {
  final String title;
  final List<ListPoint> points;
  const ToDoList({this.title = '', required this.points});
}

class ListOfNotes extends StatefulWidget {
  const ListOfNotes({super.key});

  @override
  State<ListOfNotes> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<ListOfNotes>
    with SingleTickerProviderStateMixin {
  bool _isNotesInitialized = false;
  bool _isToDoListsInitialized = false;

  //ToDo's

  List<ToDoList> toDoLists = [];

  //Tabs
  late TabController _tabController;

  var iconColors = [Colors.red, Colors.black];

  //Notes
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
        title: TabBar(
          controller: _tabController,
          tabs: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: InkWell(
                onTap: () {
                  // Handle tab selection
                  _tabController.animateTo(0);
                  setState(() {
                    updateIconColor(0);
                  });
                },
                child: Icon(Icons.format_list_bulleted, color: iconColors[0]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: InkWell(
                onTap: () {
                  // Handle tab selection
                  _tabController.animateTo(1);
                  setState(() {
                    updateIconColor(1);
                  });
                },
                child: Icon(Icons.check_box_outlined, color: iconColors[1]),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: TextField(
            decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search notes',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0))),
            //No const because it changes
            onChanged: (String string) {
              if (_tabController.index == 0) {
                displayContainingNotes(string);
              } else {}
            },
          ),
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
      body: TabBarView(controller: _tabController, children: [
        ListView.builder(
            itemCount: noteTitle.length,
            prototypeItem: ListTile(
              contentPadding: EdgeInsets.all(10),
              title: Text(
                  noteTitle.firstWhere((element) => true, orElse: () => '')),
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
                  onTap: () {
                    _editNote(context, index);
                  },
                  selected: isSelected[index],
                  tileColor: tileColor[index],
                  enabled: true);
            }),
        ListView.separated(
          itemCount: toDoLists.length,
          separatorBuilder: (context, index) =>
              Divider(), // Add a divider between items
          itemBuilder: (context, index) {
            final currentList = toDoLists[index];
            return ListTile(
              title: Text(toDoLists[index].title),
              subtitle: currentList != null
                  ? ListView.builder(
                      shrinkWrap:
                          true, // Ensure the inner ListView takes only the space it needs
                      itemCount: currentList.points.length,
                      itemBuilder: (context, i) {
                        final currentItem = currentList.points[i].content;
                        return ListTile(
                          title: CheckboxLabel(
                            checked: false,
                            label: currentItem,
                            editable: false,
                          ),
                        );
                      },
                    )
                  : const SizedBox(), // Handle null case for currentList
              onTap: () {},
              enabled: true,
            );
          },
        )
      ]),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          if (_tabController.index == 0) {
            _addNote(context);
          } else {
            _showDialogBox(context);
          }
        },
      ),
    );
  }

  Future<void> _showDialogBox(BuildContext context) async {
    CheckboxLabel checkboxLabel;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const TextField(
            decoration: InputDecoration(hintText: 'Title'),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                checkboxLabel =
                    CheckboxLabel(checked: false, label: '', editable: true)
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Approve'),
              onPressed: () {
                _addToDo(checkboxLabel);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addToDo(CheckboxLabel checkboxLabel) async {
    var title = checkboxLabel.label;
    List<String> pointsContent = [];
    List<bool> isChecked = [];

    for (Point point in checkboxLabel.points) {
      String text = point.textController.text;
      bool checked = point.checked;
      pointsContent.add(text);
      isChecked.add(checked);
    }

    List<ListPoint> points = [];
    for (int i = 0; i < pointsContent.length; i++) {
      points.add(ListPoint(content: pointsContent[i], isChecked: isChecked[i]));
    }

    final Database database = await DatabaseProvider.database;

    int toDoListId = await database.insert('ToDoLists', {'title': title});

    for (ListPoint point in points) {
      await database.insert('Points', {
        'content': point.content,
        'isChecked': point.isChecked ? 1 : 0,
        'toDoListId': toDoListId
      });
    }

    setState(() {
      toDoLists.add(ToDoList(title: title, points: points));
    });
  }

  void updateIconColor(int tabIndex) {
    setState(() {
      // Reset all colors to black
      iconColors = [Colors.black, Colors.black];
      // Update the color of the tapped icon
      iconColors[tabIndex] = Colors.red;
    });
  }

  Future<void> _editNote(BuildContext context, int index) async {
    final result = await Navigator.push(
      context,
      // Create the Note screen in the next step.
      MaterialPageRoute(
          builder: (context) =>
              Note(null, noteTitle[index], noteContent[index])),
    );
    final database = await DatabaseProvider.database;

    if (result != null) {
      await database.update('Notes', result,
          where: 'title = ?', whereArgs: [noteTitle[index]]);

      setState(() {
        noteTitle[index] = result['title'];
        noteContent[index] = result['subtitle'];
      });
    }
  }

  Future<void> deleteSelectedNotes() async {
    final database = await DatabaseProvider.database;

    List<int> indicesToDelete = [];
    // Remove the Note from the database.
    for (int i = 0; i < isSelected.length; i++) {
      if (isSelected[i] == true) {
        await database.delete(
          'Notes',
          // Use a `where` clause to delete a specific note.
          where: 'title = ?',
          // Pass the Note's id as a whereArg to prevent SQL injection
          whereArgs: [noteTitle[i]],
        );

        indicesToDelete.add(i);
      }
    }

    setState(() {
      //Reverse iteration to do not affect the index
      for (int i = indicesToDelete.length - 1; i >= 0; i--) {
        int index = indicesToDelete[i];

        noteTitle.removeAt(index);
        noteContent.removeAt(index);
        originalNoteTitle.removeAt(index);
        originalNoteContent.removeAt(index);
        isSelected.removeAt(index);
        tileColor.removeAt(index);
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
    _tabController = TabController(vsync: this, length: 2);
    _initializeNotes();
    _initializeToDoLists();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotes() async {
    if (!_isNotesInitialized) {
      await _retrieveNotes();
      _isNotesInitialized = true;
    }
  }

  Future<void> _initializeToDoLists() async {
    if (!_isToDoListsInitialized) {
      await _retrieveToDoLists();
      _isToDoListsInitialized = true;
    }
  }

  Future<void> _retrieveToDoLists() async {
    final database = await DatabaseProvider.database;

    final List<Map<String, dynamic>> toDoListMaps =
        await database.query('ToDoLists');

    for (Map<String, dynamic> toDoListMap in toDoListMaps) {
      List<Map<String, dynamic>> pointMaps = await database.query(
        'Points',
        where: 'toDoListId = ?',
        whereArgs: [toDoListMap['id']],
      );

      List<ListPoint> points = pointMaps.map<ListPoint>((pointMap) {
        return ListPoint(
          content: pointMap['content'],
          isChecked: pointMap['isChecked'] == 1,
        );
      }).toList();

      toDoLists.add(ToDoList(title: toDoListMap['title'], points: points));
    }
  }

  Future<void> _retrieveNotes() async {
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

  Future<void> _addNote(BuildContext context) async {
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
    if (result != null) {
      if (result['title'] != '' && result['subtitle'] != '') {
        await insertNote(result);
        setState(() {
          noteTitle.add(result['title']);
          noteContent.add(result['subtitle']);
          originalNoteTitle.add(result['title']);
          originalNoteContent.add(result['subtitle']);
          isSelected.add(false);
          tileColor.add(Colors.white);
        });
      }
    }
  }

  // Define a function that inserts notes into the database
  Future<void> insertNote(mapNote) async {
    // Get a reference to the database.
    final db = await DatabaseProvider.database;

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

  void displayContainingNotes(String string) {
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

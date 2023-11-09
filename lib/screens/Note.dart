import 'package:flutter/material.dart';

class Note extends StatefulWidget {
  String? title;
  String? subtitle;

  Note([Key? key, this.title, this.subtitle]) : super(key: key);

  @override
  State<Note> createState() => _NoteState();
}

class _NoteState extends State<Note> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.title ?? '';
    _subtitleController.text = widget.subtitle ?? '';
    _titleController.addListener(() {});
    _subtitleController.addListener(() {});
  }

  /* @override
 / void dispose() {
 /   _controller.dispose();
    super.dispose();
  }
  */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Note taking screen"), actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.check),
          onPressed: () {
            Navigator.pop(context, {
              "title": _titleController.text,
              "subtitle": _subtitleController.text
            });
          },
        ),
      ]),
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(children: [
            TextField(
              controller: _titleController,
              style: TextStyle(fontSize: 30.0),
              decoration:
                  InputDecoration(border: InputBorder.none, hintText: 'Title'),
            ),
            TextField(
              controller: _subtitleController,
              keyboardType: TextInputType.multiline,
              maxLines: null,
            ),
          ]),
        ),
      ),
    );
  }
}

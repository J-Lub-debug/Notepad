//Change points, checkedPoints, _textController, _focusNodes into the Class
//Add focus to new row upon creation, keyboard doesn't appear, it may have something to do with textInputAction: TextInputAction.next,

import 'package:flutter/material.dart';

class Point {
  int id;
  bool checked;
  FocusNode focusNode;
  TextEditingController textController;

  Point({
    required this.id,
    required this.checked,
    FocusNode? focusNode,
    TextEditingController? textController,
  })  : focusNode = focusNode ?? FocusNode(),
        textController = textController ??
            TextEditingController(
                text:
                    '\u200B'); // invisible char so the user has to delete it before the row gets deleted
}

class CheckboxLabel extends StatefulWidget {
  bool? checked;
  String label;
  bool editable;

  CheckboxLabel({
    Key? key,
    required this.checked,
    required this.label,
    required this.editable,
  }) : super(key: key);

  @override
  State<CheckboxLabel> createState() => _CheckboxLabelState();
}

class _CheckboxLabelState extends State<CheckboxLabel> {
  List<Point> points = [Point(id: 0, checked: false)];

  @override
  Widget build(BuildContext context) {
    return widget.editable
        ? SingleChildScrollView(
            child: Column(
              children: [
                for (int index = 0; index < points.length; index++)
                  ListTile(
                    leading: Checkbox(
                      value: points[index].checked,
                      onChanged: (val) {
                        setState(() => points[index].checked = val!);
                      },
                    ),
                    title: TextField(
                      //enabled: false,
                      controller: points[index].textController,
                      keyboardType: TextInputType.multiline,
                      focusNode: points[index].focusNode,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (value) => _onSubmitted(index),
                      onChanged: (value) => _onEmptyDelete(index, value),
                    ),
                  ),
              ],
            ),
          )
        : Row(children: [
            Checkbox(
              value: widget.checked,
              onChanged: (val) {
                setState(() {
                  widget.checked = val;
                });
              },
            ),
            Text(widget.label)
          ]);
  }

  void _onSubmitted(index) {
    setState(() {
      points.add(Point(id: index, checked: false));
    });
    // Set focus to the new TextField
    FocusScope.of(context).requestFocus(points.last.focusNode);
    //! Keyboard doesn't show up even though the focus shows displaying blue outline on Text field
  }

  void _onEmptyDelete(index, value) {
    if (value.length == 0 && points.length > 1) {
      setState(() {
        points.removeAt(index);
      });
      //Set focus to previous TextField
      FocusScope.of(context).requestFocus(points.last.focusNode);
    }
  }
}

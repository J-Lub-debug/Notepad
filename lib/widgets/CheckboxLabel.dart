//Add crosing out the row and greying it out when checked
//Add checkbox next to title and make it cross out all when checked
//Add focus to new row upon creation, keyboard doesn't appear, it may have something to do with textInputAction: TextInputAction.next,

import 'package:flutter/material.dart';

class Point {
  bool checked;
  FocusNode focusNode;
  TextEditingController textController;

  Point({
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
  bool editable;
  List<Point> points;
  final Function(CheckboxLabel) onPointsUpdated; //callback function

  CheckboxLabel({
    Key? key,
    required this.editable,
    List<Point>? points,
    required this.onPointsUpdated,
  })  : points = points != null && points.isNotEmpty
            ? points
            : [Point(checked: false)],
        super(key: key);

  @override
  State<CheckboxLabel> createState() => _CheckboxLabelState();

  // New method to handle points update
  void updateWidget(CheckboxLabel updatedWidget) {
    // Call the callback from _MyWidgetState directly
    onPointsUpdated(updatedWidget);
  }
}

class _CheckboxLabelState extends State<CheckboxLabel> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          for (int index = 0; index < widget.points.length; index++)
            ListTile(
              leading: Checkbox(
                value: widget.points[index].checked,
                onChanged: (val) {
                  setState(() {
                    widget.points[index].checked = val!;
                  });
                  widget.onPointsUpdated(widget);
                },
              ),
              title: TextField(
                enabled: widget.editable,
                controller: widget.points[index].textController,
                keyboardType: TextInputType.multiline,
                focusNode: widget.points[index].focusNode,
                style: TextStyle(
                    color: widget.points[index].checked
                        ? Colors.grey
                        : Colors.black,
                    decoration: widget.points[index].checked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none),
                decoration: InputDecoration(
                    border: widget.editable
                        ? const UnderlineInputBorder()
                        : InputBorder.none),
                textInputAction: TextInputAction.next,
                onSubmitted: (value) =>
                    _onSubmitted(index + 1), //if the first point has id:0
                onChanged: (value) => _onEmptyDelete(index, value),
              ),
            ),
        ],
      ),
    );
  }

  void _onSubmitted(index) {
    setState(() {
      widget.points.add(Point(checked: false));
    });
    // Set focus to the new TextField
    FocusScope.of(context).requestFocus(widget.points.last.focusNode);
    //! Keyboard doesn't show up even though the focus shows displaying blue outline on Text field
  }

  void _onEmptyDelete(index, value) {
    if (value.length == 0 && widget.points.length > 1) {
      setState(() {
        widget.points.removeAt(index);
      });
      //Set focus to previous TextField
      FocusScope.of(context).requestFocus(widget.points.last.focusNode);
    }
  }
}

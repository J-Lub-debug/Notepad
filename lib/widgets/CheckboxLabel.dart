//Change points, checkedPoints, _textController into the Class
//Add focus to new row upon creation, keyboard doesn't appear

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  List<FocusNode> _focusNodes = [FocusNode()];

  List<TextEditingController> _textController = [
    TextEditingController(text: '\u200B') // invisible char
  ];

  List<int> points = [0];
  List<bool> checkedPoints = [false];

  @override
  Widget build(BuildContext context) {
    return widget.editable
        ? SingleChildScrollView(
            child: Column(
              children: [
                for (int index = 0; index < points.length; index++)
                  ListTile(
                    leading: Checkbox(
                      value: checkedPoints[index],
                      onChanged: (val) {
                        setState(() => checkedPoints[index] = val!);
                      },
                    ),
                    title: TextField(
                      //enabled: false,
                      controller: _textController[index],
                      keyboardType: TextInputType.multiline,
                      focusNode: _focusNodes[index],
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
      points.add(index);
      checkedPoints.add(false);
      _textController.add(TextEditingController(text: '\u200B'));
      _focusNodes.add(FocusNode());
    });
    // Set focus to the new TextField
    FocusScope.of(context).requestFocus(_focusNodes.last);
    SystemChannels.textInput.invokeMethod('TextInput.show');
    FocusScope.of(context).requestFocus(_focusNodes.last);
  }

  void _onEmptyDelete(index, value) {
    if (value.length == 0 && points.length > 1) {
      setState(() {
        points.removeAt(index);
        checkedPoints.removeAt(index);
        _textController.removeAt(index);
        _focusNodes.removeAt(index);
      });
      FocusScope.of(context).requestFocus(_focusNodes.last);
    }
  }
}

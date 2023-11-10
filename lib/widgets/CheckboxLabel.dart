import 'package:flutter/material.dart';

class CheckboxLabel extends StatefulWidget {
  bool? checked;
  String label;

  CheckboxLabel({
    Key? key,
    required this.checked,
    required this.label,
  }) : super(key: key);

  @override
  State<CheckboxLabel> createState() => _CheckboxLabelState();
}

class _CheckboxLabelState extends State<CheckboxLabel> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
            value: widget.checked,
            onChanged: (val) {
              setState(() => widget.checked = val);
            }),
        Text(widget.label)
      ],
    );
  }
}

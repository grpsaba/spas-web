import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class RowPerPageWidget extends StatefulWidget {
  RowPerPageWidget(
      {super.key,
      required this.incremente,
      required this.decremente,
      required this.controller});
  void Function() incremente;
  void Function() decremente;
  TextEditingController controller;
  @override
  _RowPerPageState createState() => _RowPerPageState();
}

class _RowPerPageState extends State<RowPerPageWidget> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color.fromARGB(255, 228, 225, 225),
      ),
      width: 125,
      child: Row(
        children: [
          IconButton(
              onPressed: widget.decremente,
              icon: Icon(
                HugeIcons.strokeRoundedArrowLeft01,
                color: Theme.of(context).primaryColor,
              )),
          Expanded(
              child: TextFormField(
            readOnly: true,
            controller: widget.controller,
            decoration: const InputDecoration(border: InputBorder.none),
          )),
          IconButton(
              onPressed: widget.incremente,
              icon: Icon(HugeIcons.strokeRoundedArrowRight01,
                  color: Theme.of(context).primaryColor))
        ],
      ),
    );
  }
}

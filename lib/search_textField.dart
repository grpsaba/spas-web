import 'package:flutter/material.dart';

class SearchTextField extends StatefulWidget {
  final void Function(String keyword) onSearch;

  final void Function() onPress;
  final TextEditingController? controller;
  final Size size;
  final Color fillColor;
  final Color hintColor;
  final Color textColor;
  const SearchTextField(
      {Key? key,
      required this.onSearch,
      required this.onPress,
      this.controller,
      this.size = const Size(150, 40),
      this.fillColor = const Color(0xFFCBCFD0),
      this.hintColor = Colors.black12,
      this.textColor = Colors.black})
      : super(key: key);

  @override
  State<SearchTextField> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchTextField> {
  void initState() {
    super.initState();
  }

  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        constraints: BoxConstraints.loose(widget.size),
        decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Expanded(
              child: TextFormField(
            style: TextStyle(color: widget.textColor),
            controller: widget.controller,
            onChanged: (value) => widget.onSearch(value),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
                hintStyle: TextStyle(color: widget.hintColor),
                fillColor: widget.fillColor,
                filled: true,
                hintText: "Recherche",
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20)),
                    borderSide: BorderSide.none)),
          )),
          IconButton(
            icon: const Icon(
              Icons.search,
              color: Colors.white,
            ),
            onPressed: widget.onPress,
          ),
        ]));
  }
}

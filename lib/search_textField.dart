import 'package:flutter/material.dart';

class SearchTextField extends StatefulWidget {
  final void Function(String keyword) onSearch;

  final void Function() onPress;
  final TextEditingController? controller;

  const SearchTextField({
    Key? key,
    required this.onSearch,
    required this.onPress,
    this.controller,
  }) : super(key: key);

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
        constraints: BoxConstraints.loose(const Size(200, 40)),
        decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Expanded(
              child: TextFormField(
            controller: widget.controller,
            onChanged: (value) => widget.onSearch(value),
            textAlignVertical: TextAlignVertical.center,
            decoration: const InputDecoration(
                fillColor: Color.fromARGB(255, 228, 225, 225),
                filled: true,
                hintText: "Recherche",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10)),
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

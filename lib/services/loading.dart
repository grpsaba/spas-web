import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Loading extends StatelessWidget {
  Loading(
      {Key? key,
      required this.size,
      required this.inline,
      this.sos = false,
      this.status = false})
      : super(key: key);
  double size;
  bool status;
  bool inline;
  bool sos;
  @override
  Widget build(BuildContext context) {
    if (sos == true) {
      switch (status) {
        case true:
          return Center(
              child:
                  LoadingAnimationWidget.beat(color: Colors.red, size: size));
        case false:
          return Center(
              child:
                  LoadingAnimationWidget.beat(color: Colors.green, size: size));
        default:
          return Center(
              child:
                  LoadingAnimationWidget.beat(color: Colors.green, size: size));
      }
    } else {
      return inline
          ? Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Theme.of(context).primaryColor, size: size))
          : Center(
              child: LoadingAnimationWidget.hexagonDots(
                  color: Theme.of(context).primaryColor, size: size));
    }
  }
}

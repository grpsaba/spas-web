import 'dart:async';

import 'package:flutter/cupertino.dart';

class DelayedAnimation extends StatefulWidget {
  final Widget? child;
  final int? delay;
  bool topToBottom = true;
  bool bottomToTop = false;
  bool leftToRight = false;
  bool rightToLeft = false;
  DelayedAnimation(
      {Key? key,
      this.child,
      this.delay = 1000,
      this.topToBottom = true,
      this.bottomToTop = false,
      this.leftToRight = false,
      this.rightToLeft = false})
      : super(key: key);
  @override
  State<DelayedAnimation> createState() {
    return _DelayedAnimationState();
  }
}

class _DelayedAnimationState extends State<DelayedAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controler;
  late Animation<Offset> _animationOffset;
  double dx = 0.0;
  double dy = 0.0;
  @override
  void initState() {
    super.initState();
    _controler = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    final curve = CurvedAnimation(parent: _controler, curve: Curves.decelerate);
    if (widget.topToBottom) {
      dx = 0.0;
      dy = -0.5;
    }
    if (widget.bottomToTop) {
      dx = 0.0;
      dy = 0.5;
    }
    if (widget.leftToRight) {
      dx = -0.5;
      dy = 0.0;
    }
    if (widget.rightToLeft) {
      dx = 0.5;
      dy = 0.0;
    }
    _animationOffset =
        Tween<Offset>(begin: Offset(dx, dy), end: Offset.zero).animate(curve);
    Timer(Duration(milliseconds: widget.delay!), () {
      _controler.forward();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return FadeTransition(
      opacity: _controler,
      child: SlideTransition(child: widget.child, position: _animationOffset),
    );
  }
}

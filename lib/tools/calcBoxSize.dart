import 'package:flutter/material.dart';

Map<String, double> calcBoxSize(GlobalKey boxKey) {
  final context = boxKey.currentContext;
  if (context == null) {
    return {
      'width': 0,
      'height': 0,
    };
  }
  final RenderBox containerRenderBox = context.findRenderObject();
  return {
    'width': containerRenderBox.size.width,
    'height': containerRenderBox.size.height,
  };
}

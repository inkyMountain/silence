import 'package:flutter/material.dart';

Map<String, double> calcBoxSize(GlobalKey boxKey) {
  final RenderBox containerRenderBox = boxKey.currentContext.findRenderObject();
  return {
    'width': containerRenderBox.size.width,
    'height': containerRenderBox.size.height,
  };
}

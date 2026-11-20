import 'package:flutter/material.dart';

/// Scales a design value against a 430x932 reference frame so the same
/// Figma-style numbers Phase 1-5's screens were sketched against stay
/// proportionally correct on other screen sizes.
const double _baseWidth = 430;
const double _baseHeight = 932;

double responsiveWidth(BuildContext context, double value) {
  final screenWidth = MediaQuery.of(context).size.width;
  return value * (screenWidth / _baseWidth);
}

double responsiveHeight(BuildContext context, double value) {
  final screenHeight = MediaQuery.of(context).size.height;
  return value * (screenHeight / _baseHeight);
}

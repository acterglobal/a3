import 'package:flutter/material.dart';

class ColorModel {
  final Color color;
  final bool isSelected;

  const ColorModel({
    required this.color,
    this.isSelected = false,
  });
}

List<ColorModel> iconPickerColors = [
  const ColorModel(color: Colors.green),
  const ColorModel(color: Colors.red),
  const ColorModel(color: Colors.yellow),
  const ColorModel(color: Colors.blue, isSelected: true),
  const ColorModel(color: Colors.purple),
  const ColorModel(color: Colors.amber),
  const ColorModel(color: Colors.amber),
  const ColorModel(color: Colors.deepOrangeAccent),
  const ColorModel(color: Colors.brown),
  const ColorModel(color: Colors.blueGrey),
  const ColorModel(color: Colors.purpleAccent),
  const ColorModel(color: Colors.indigoAccent),
];

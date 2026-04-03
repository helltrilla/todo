import 'package:flutter/material.dart';

enum PriorityLevel {
  p1('1', Icons.priority_high, Colors.red),
  p2('2', Icons.trending_up, Colors.deepOrange),
  p3('3', Icons.flag, Colors.orange),
  p4('4', Icons.flag, Colors.amber),
  p5('5', Icons.flag, Colors.yellow),
  p6('6', Icons.flag, Colors.yellowAccent),
  p7('7', Icons.flag, Colors.lightGreen),
  p8('8', Icons.flag_outlined, Colors.green),
  p9('9', Icons.flag_outlined, Colors.teal),
  p10('10', Icons.flag_outlined, Colors.blueGrey),
  none('0', Icons.flag_outlined, Colors.grey);

  final String label;
  final IconData icon;
  final Color color;

  const PriorityLevel(this.label, this.icon, this.color);

  static PriorityLevel fromIndex(int index) {
    switch (index) {
      case 0: return PriorityLevel.p1;
      case 1: return PriorityLevel.p2;
      case 2: return PriorityLevel.p3;
      case 3: return PriorityLevel.p4;
      case 4: return PriorityLevel.p5;
      case 5: return PriorityLevel.p6;
      case 6: return PriorityLevel.p7;
      case 7: return PriorityLevel.p8;
      case 8: return PriorityLevel.p9;
      case 9: return PriorityLevel.p10;
      default: return PriorityLevel.none;
    }
  }
  
  int get value => int.parse(label);
  bool get hasPriority => this != PriorityLevel.none;
}
import 'package:flutter/material.dart';

// ты чет название перепутал
class TaskCard extends StatefulWidget {
  const TaskCard({super.key});

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool isActive = false;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isActive = !isActive;
          });
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.deepPurpleAccent
                : Color.fromARGB(255, 70, 70, 70),
            borderRadius: BorderRadiusDirectional.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(Icons.flag, color: Colors.white)],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:todo/core/app_theme/app_colors.dart';


class PriorityCard extends StatefulWidget {
  const PriorityCard({super.key});

  @override
  State<PriorityCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<PriorityCard> {
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
                ? AppColors.active
                : AppColors.unactive,
            borderRadius: BorderRadiusDirectional.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(Icons.flag, color: AppColors.white)],
          ),
        ),
      ),
    );
  }
}

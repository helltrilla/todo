import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/layers/view/shared/widgets/priority_card.dart';

class PriorityTaskCard extends StatefulWidget {
  const PriorityTaskCard({super.key});

  @override
  State<PriorityTaskCard> createState() => _PriorityTaskCardState();
}

class _PriorityTaskCardState extends State<PriorityTaskCard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AlertDialog(
        content: SizedBox(
          height: 260,
          width: 327,
          child:
              // тут через gridview нужно, желательно .builder так пизже для оптимизации
              GridView.builder(
                itemCount: 10,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                ),
                itemBuilder: (context, index) => PriorityCard(),
              ),
        ),
        title: Container(
          alignment: Alignment.center,
          child: Text(
            'Task Priority',
            style: TextStyle(color: AppColors.maintext, fontSize: 16),
          ),
        ),
        actions: <Widget>[
          Row(
            children: [
              TextButton(onPressed: () => context.pop(), child: Text('Cancel')),
              Spacer(),
              TextButton(onPressed: () => context.pop(), child: Text('Save')),
            ],
          ),
        ],
      ),
    );
  }
}

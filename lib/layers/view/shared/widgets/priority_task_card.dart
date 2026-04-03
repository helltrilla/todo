import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/layers/domain/entity/priority_level.dart';
import 'package:todo/layers/view/shared/widgets/priority_card.dart';

class PriorityTaskCard extends StatefulWidget {
  final int? initialPriorityIndex;
  const PriorityTaskCard({super.key, this.initialPriorityIndex});

  @override
  State<PriorityTaskCard> createState() => _PriorityTaskCardState();
}

class _PriorityTaskCardState extends State<PriorityTaskCard> {
  late int _activePriorityIndex;

  @override
  void initState() {
    super.initState();
    _activePriorityIndex = widget.initialPriorityIndex ?? -1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AlertDialog(
        content: SizedBox(
          height: 260,
          width: 327,
          child: GridView.builder(
            itemCount: 10,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final priority = PriorityLevel.fromIndex(index);
              
              return PriorityCard(
                isActive: _activePriorityIndex == index,
                priority: priority,
                onTap: () {
                  setState(() {
                    if (_activePriorityIndex == index) {
                      _activePriorityIndex = -1;
                    } else {
                      _activePriorityIndex = index;
                    }
                  });
                },
              );
            },
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
              TextButton(
                onPressed: () => context.pop(),
                child: Text('Cancel')
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  print('Save pressed, returning index: $_activePriorityIndex');
                  context.pop(_activePriorityIndex);
                }, 
                child: Text('Save')
              ),
            ],
          ),
        ],
      ),
    );
  }
}
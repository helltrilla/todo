import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/layers/domain/entity/task.dart';
import 'package:todo/layers/view/shared/widgets/priority_task_card.dart';
import 'package:todo/layers/view/shared/widgets/task_card.dart';

final today = DateUtils.dateOnly(DateTime.now());

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> tasks = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SharedPreferencesAsync().getStringList("tasks").then((e) {
        if (e != null) {
          tasks = e.map((e) => Task.fromJson(e)).toList();
        } else {
          tasks = [];
        }
        print(tasks);
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {},
          icon: Icon(Icons.sort, color: AppColors.white),
        ),
        title: Center(
          child: Text("Index", style: Theme.of(context).textTheme.titleMedium),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.panorama_fisheye_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Stack(
          alignment: AlignmentGeometry.bottomCenter,
          children: [
            ListView.separated(
              separatorBuilder: (context, index) => Container(
                width: double.infinity,
                color: Colors.white,
                height: 1,
              ),
              itemCount: tasks.length,
              itemBuilder: (context, index) => TaskCard(task: tasks[index]),
            ),
            Positioned(
              child: FloatingActionButton.large(
                backgroundColor: AppColors.active,
                child: Icon(CupertinoIcons.plus, color: AppColors.white),
                onPressed: () {
                  showModalBottomSheet(
                    backgroundColor: AppColors.bg,
                    context: context,
                    builder: (BuildContext context) {
                      return CustomCalendar();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomCalendar extends StatefulWidget {
  const CustomCalendar({super.key});

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  TextEditingController taskContr = TextEditingController();

  TextEditingController deskContr = TextEditingController();

  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(right: 280, top: 30),
            child: Text(
              'Add task',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.maintext,
              ),
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: 360,
            height: 43,
            child: TextField(
              controller: taskContr,
              obscureText: false,
              style: TextStyle(color: AppColors.maintext),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Task',
                labelStyle: TextStyle(color: AppColors.labeltext, fontSize: 12),
              ),
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: 360,
            height: 43,
            child: TextField(
              controller: deskContr,
              obscureText: false,
              style: TextStyle(color: AppColors.maintext),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Description',
                labelStyle: TextStyle(color: AppColors.labeltext, fontSize: 12),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 20),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.calendar_month),
                  color: AppColors.icons,
                  onPressed: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );

                    if (pickedDate != null) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                ),
                if (selectedDate != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgmain,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatDate(selectedDate!),
                          style: TextStyle(
                            color: AppColors.maintext,
                            fontSize: 10,
                          ),
                        )
                      ],
                    ),
                  ),
                SizedBox(width: 46),
                Icon(Icons.label, color: AppColors.white),
                SizedBox(width: 56),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => PriorityTaskCard(),
                    );
                  },
                  icon: Icon(Icons.flag, color: AppColors.icons,),
                ),
                Spacer(),
                IconButton(
                  onPressed: () async {
                    if (taskContr.text.isEmpty && deskContr.text.isEmpty) {
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('чет ебани хотя бы')),
                      );
                      return;
                    }
                    // ключ для хранения
                    final key = "tasks";
                    // получаем то что уже есть у нас
                    List<String> strList =
                        await SharedPreferencesAsync().getStringList(key) ?? [];
                    // добавляем в полученнй список новую таску
                    final newTask = Task(
                      id: DateTime.now().millisecondsSinceEpoch,
                      name: taskContr.text,
                      createAt: DateTime.now(),
                      value: deskContr.text,
                      duedate: selectedDate,
                    );
                    strList.add(newTask.toJson());
                    // меняем список на новый
                    await SharedPreferencesAsync().setStringList(key, strList);

                    print(strList);
                    context.pop();
                  },
                  icon: Icon(Icons.send),
                  color: AppColors.active,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

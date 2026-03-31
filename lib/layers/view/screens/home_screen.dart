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
        tasks = e!.map((e) => Task.fromJson(e)).toList();
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
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.panorama_fisheye_outlined),
          ),
        ],
        title: Text("index", style: Theme.of(context).textTheme.titleMedium),
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // и размеры хардкодить лучше не надо а то на других устройствах будут ошибки либо если данных будет больше чем нужно
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
                  icon: Icon(Icons.timer),
                  color: AppColors.icons,
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );

                    print(picked);
                  },
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
                  icon: Icon(Icons.flag),
                ),
                Spacer(),
                IconButton(
                  onPressed: () async {
                    if (taskContr.text.isEmpty && deskContr.text.isEmpty) {
                      context.pop();
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(' пусто')));
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
}

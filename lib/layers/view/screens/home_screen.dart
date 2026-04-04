import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/layers/domain/entity/priority_level.dart';
import 'package:todo/layers/domain/entity/task.dart';
import 'package:todo/layers/view/shared/widgets/priority_task_card.dart';
import 'package:todo/layers/view/shared/widgets/task_card.dart';

// теперь перенеси все методы по работе с данными в отдельный класс, например TaskRepository, который будет отвечать за загрузку, сохранение и удаление задач. Это поможет разделить логику и UI, а также упростит тестирование и поддержку кода.

// final today = DateUtils.dateOnly(DateTime.now());
// тут это нахуя?

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> tasks = [];

  Future<void> _loadTasks() async {
    final List<String>? taskStrings = await SharedPreferencesAsync()
        .getStringList("tasks");
    if (taskStrings != null) {
      setState(() {
        tasks = taskStrings.map((e) => Task.fromJson(e)).toList();
      });
    }
  }

  Future<void> _deleteTask(Task task, int index) async {
    // нужно разделять ui и логику

    //вызываем отдельно этот диолог и после если true то уже удаляем, а так получается что мы вызываем диалог и удаляем в одном методе, а это не правильно, нужно разделять логику и ui
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('удалить задачу ебаную'),
        content: Text('уверен что хочешь уебать эту?)"${tasks[index].name}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('АТМЕНА'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('да снести к хуям'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // удаляем таску из списка
      tasks.removeAt(index);
      const key = "tasks";
      List<String> strList = tasks.map((task) => task.toJson()).toList();
      await SharedPreferencesAsync().setStringList(key, strList);

      setState(() {});
    }
  }

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
            tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: AppColors.icons,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 100),
                    separatorBuilder: (context, index) => Container(
                      width: double.infinity,
                      color: Colors.white,
                      height: 1,
                    ),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return TaskCard(
                        task: tasks[index],
                        onDelete: () => _deleteTask(tasks[index], index),
                      );
                    },
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
                  _loadTasks();
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
  int _selectedPriorityIndex = -1;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 380,
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
          const SizedBox(height: 10),
          if (_selectedPriorityIndex != -1)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: PriorityLevel.fromIndex(
                  _selectedPriorityIndex,
                ).color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: PriorityLevel.fromIndex(_selectedPriorityIndex).color,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PriorityLevel.fromIndex(_selectedPriorityIndex).icon,
                    color: PriorityLevel.fromIndex(
                      _selectedPriorityIndex,
                    ).color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    PriorityLevel.fromIndex(_selectedPriorityIndex).label,
                    style: TextStyle(
                      color: PriorityLevel.fromIndex(
                        _selectedPriorityIndex,
                      ).color,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
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
                        ),
                      ],
                    ),
                  ),
                SizedBox(width: 46),
                Icon(Icons.label, color: AppColors.white),
                SizedBox(width: 56),
                IconButton(
                  onPressed: () async {
                    final result = await showDialog<int>(
                      context: context,
                      builder: (context) => const PriorityTaskCard(),
                    );
                    if (result != null) {
                      setState(() {
                        _selectedPriorityIndex = result;
                      });
                    }
                  },
                  icon: Icon(
                    Icons.flag,
                    color: _selectedPriorityIndex != -1
                        ? PriorityLevel.fromIndex(_selectedPriorityIndex).color
                        : AppColors.icons,
                  ),
                ),
                const Spacer(),
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
                    const key = "tasks";
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
                      priorityIndex: _selectedPriorityIndex,
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

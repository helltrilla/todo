import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart' hide Theme;
import 'package:flutter/cupertino.dart';
import 'package:todo/core/app_theme/app_theme.dart';
import 'package:todo/layers/view/shared/ui/priority_card.dart';

final today = DateUtils.dateOnly(DateTime.now());


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // используй padding в то хуйня получается
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    SizedBox(height: 70, width: 20),
                    const Icon(Icons.sort, color: Colors.white),
                    SizedBox(width: 130),
                    const Text(
                      'Index',
                      style: TextStyle(fontSize: 24, color: Colors.white),
                    ),
                    Spacer(),
                    const Icon(Icons.circle, size: 40, color: Colors.white),
                  ],
                ),
                SizedBox(height: 50),
                Column(
                  children: [
                    SizedBox(
                      width: 227,
                      height: 227,
                      child: Image.asset('assets/photo/homescreenpicture.png'),
                    ),
                    Text(
                      'What do you want to do today?',
                      style: TextStyle(fontSize: 24, color: Colors.white),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Tap + to add your tasks',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: 360),
                Positioned(
                  child: FloatingActionButton.large(
                    backgroundColor: Colors.deepPurpleAccent,
                    child: Icon(CupertinoIcons.plus, color: Colors.white),
                    onPressed: () {
                      showModalBottomSheet(
                        backgroundColor: Color.fromARGB(255, 54, 54, 54),
                        context: context,
                        builder: (BuildContext context) {
                          // это выносишь либо в отдельный виджет либо как _buildAddTask

                          // если прсто размер то лучше Sisedbox
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
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                SizedBox(
                                  width: 360,
                                  height: 43,
                                  child: TextField(
                                    obscureText: false,
                                    style: TextStyle(color: Colors.white),
                                    // InputDecoration можно тоже указать в AppTheme
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'Task',
                                      labelStyle: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                SizedBox(
                                  width: 360,
                                  height: 43,
                                  child: TextField(
                                    obscureText: false,
                                    style: TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'Description',
                                      labelStyle: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(left: 20),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.timer),
                                        color: Colors.white,
                                        onPressed: () {
                                          showCalendarDatePicker2Dialog(
                                            value: [],
                                            config:
                                                CalendarDatePicker2WithActionButtonsConfig(
                                                  firstDayOfWeek: 1,
                                                  calendarType:
                                                      CalendarDatePicker2Type
                                                          .single,
                                                  selectedDayTextStyle:
                                                      TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                  selectedDayHighlightColor:
                                                      Colors.purple[800],
                                                  centerAlignModePicker: true,
                                                  customModePickerIcon:
                                                      SizedBox(),
                                                ),
                                            context: context,
                                            dialogSize: const Size(11, 11),
                                          );
                                        },
                                      ),
                                      SizedBox(width: 46),
                                      Icon(Icons.label, color: Colors.white),
                                      SizedBox(width: 56),
                                      IconButton(
                                        icon: Icon(Icons.flag),
                                        color: Colors.white,
                                        onPressed: () => showDialog<String>(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              // тоже в отдельный виджет или метод
                                              AlertDialog(
                                                backgroundColor: Color.fromARGB(
                                                  255,
                                                  54,
                                                  54,
                                                  54,
                                                ),
                                                content: SizedBox(
                                                  height: 260,
                                                  width: 327,
                                                  child:
                                                      // тут через gridview нужно, желательно .builder так пизже для оптимизации
                                                      Column(
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child:
                                                                    PriorityCard(),
                                                              ),
                                                              Expanded(
                                                                child:
                                                                    PriorityCard(),
                                                              ),
                                                              Expanded(
                                                                child:
                                                                    PriorityCard(),
                                                              ),
                                                              Expanded(
                                                                child:
                                                                    PriorityCard(),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                ),
                                                title: Container(
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    'Task Priority',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                actions: <Widget>[
                                                  Row(
                                                    children: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            // бля ты используешь go_router надо context.pop()
                                                            Navigator.pop(
                                                              context,
                                                              'Cancel',
                                                            ),
                                                        child: const Text(
                                                          'Cancel',
                                                        ),
                                                      ),
                                                      Spacer(),
                                                      TextButton(
                                                        onPressed: () =>
                                                            //
                                                            Navigator.pop(
                                                              context,
                                                              'Save',
                                                            ),
                                                        child: const Text(
                                                          'Save',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                        ),
                                      ),
                                      // SizedBox(width: 115),
                                      // есть виджет spacer называется он занимет все пространство между виджетами и отделяет его в край
                                      Spacer(),
                                      IconButton(
                                        onPressed: () {},
                                        icon: Icon(Icons.send),
                                        color: Colors.deepPurpleAccent,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

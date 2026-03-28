import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart' hide Theme;
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:todo/core/app_router/app_router_names.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/layers/view/shared/ui/priority_card.dart';
import 'package:todo/layers/view/shared/ui/priority_task_card.dart';

final today = DateUtils.dateOnly(DateTime.now());

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    const Icon(Icons.sort, color: AppColors.white),
                    SizedBox(width: 130),
                    const Text(
                      'Index',
                      style: TextStyle(fontSize: 24, color: AppColors.white),
                    ),
                    Spacer(),
                    const Icon(Icons.circle, size: 40, color: AppColors.white),
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
                      style: TextStyle(fontSize: 24, color: AppColors.maintext),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Tap + to add your tasks',
                      style: TextStyle(fontSize: 16, color: AppColors.maintext),
                    ),
                  ],
                ),
                SizedBox(height: 360),
                Positioned(
                  child: FloatingActionButton.large(
                    backgroundColor: AppColors.active,
                    child: Icon(CupertinoIcons.plus, color: AppColors.white),
                    onPressed: () {
                      showModalBottomSheet(
                        backgroundColor: AppColors.bg,
                        context: context,
                        builder: (BuildContext context) {
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
                                    obscureText: false,
                                    style: TextStyle(color: AppColors.maintext),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'Task',
                                      labelStyle: TextStyle(
                                        color: AppColors.labeltext,
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
                                    style: TextStyle(color: AppColors.maintext),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'Description',
                                      labelStyle: TextStyle(
                                        color: AppColors.labeltext,
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
                                        color: AppColors.white,
                                        onPressed: () {
                                          showCalendarDatePicker2Dialog(
                                            dialogBackgroundColor: AppColors.bg,

                                            value: [],
                                            config:
                                                CalendarDatePicker2WithActionButtonsConfig(
                                                  dayTextStyle: TextStyle(
                                                    color: AppColors.maintext,
                                                  ),
                                                  yearTextStyle: TextStyle(
                                                    color: AppColors.maintext,
                                                  ),
                                                  monthTextStyle: TextStyle(
                                                    color: AppColors.maintext,
                                                  ),
                                                  weekdayLabelTextStyle:
                                                      TextStyle(
                                                        color:
                                                            AppColors.maintext,
                                                      ),
                                                  selectedMonthTextStyle:
                                                      TextStyle(
                                                        color:
                                                            AppColors.maintext,
                                                      ),
                                                  todayTextStyle: TextStyle(
                                                    color: AppColors.maintext,
                                                  ),
                                                  controlsTextStyle: TextStyle(
                                                    color: AppColors.maintext,
                                                  ),
                                                  firstDayOfWeek: 1,
                                                  calendarType:
                                                      CalendarDatePicker2Type
                                                          .single,
                                                  selectedDayTextStyle:
                                                      TextStyle(
                                                        color:
                                                            AppColors.maintext,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                  selectedDayHighlightColor:
                                                      AppColors.active,
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
                                      Icon(Icons.label, color: AppColors.white),
                                      SizedBox(width: 56),
                                      IconButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) =>
                                                PriorityTaskCard(),
                                          );
                                        },
                                        icon: Icon(Icons.flag),
                                      ),
                                      Spacer(),
                                      IconButton(
                                        onPressed: () {},
                                        icon: Icon(Icons.send),
                                        color: AppColors.active,
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

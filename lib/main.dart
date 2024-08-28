import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dbhelper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة المهام', // Task Manager in Arabic
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Changa', // Set default font family
      ),
      home: const TaskListPage(),
      debugShowCheckedModeBanner: false, // Disable the debug banner
    );
  }
}

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  _TaskListPageState createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Task> _tasks = [];
  List<DateTime> _completedDates = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() async {
    final tasks = await _dbHelper.getTasks();
    final today = DateTime.now();

    // Reset tasks if the completion date does not include today
    for (var task in tasks) {
      bool isCompletedToday =
          task.completionDates.any((date) => _isSameDay(date, today));
      if (isCompletedToday) {
        // Task was completed today, no need to reset
        continue;
      } else if (task.isCompleted) {
        // If task was completed but not today, reset it
        final updatedTask = Task(
          id: task.id,
          name: task.name,
          dueDate: task.dueDate,
          isCompleted: false,
          completionDates: task.completionDates,
        );
        await _dbHelper.updateTask(updatedTask);
      }
    }

    // After possible updates, reload the tasks
    final updatedTasks = await _dbHelper.getTasks();
    setState(() {
      _tasks = updatedTasks;
      _completedDates =
          updatedTasks.expand((task) => task.completionDates).toList();
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _addTask(String name, DateTime dueDate) async {
    final task = Task(name: name, dueDate: dueDate, isCompleted: false);
    await _dbHelper.insertTask(task);
    _loadTasks();
  }

  void _updateTask(Task task, bool isCompleted) async {
    final today = DateTime.now();
    final alreadyCompleted = task.completionDates.any((d) =>
        d.year == today.year && d.month == today.month && d.day == today.day);

    List<DateTime> updatedCompletionDates;

    if (isCompleted && !alreadyCompleted) {
      // Mark today's task as completed
      updatedCompletionDates = [...task.completionDates, today];
    } else if (!isCompleted && alreadyCompleted) {
      // Unmark today's task as completed
      updatedCompletionDates = task.completionDates
          .where((d) => !(d.year == today.year &&
              d.month == today.month &&
              d.day == today.day))
          .toList();
    } else {
      // No change needed
      updatedCompletionDates = task.completionDates;
      Checkbox(
        value: task.completionDates.any((d) =>
            d.year == DateTime.now().year &&
            d.month == DateTime.now().month &&
            d.day == DateTime.now().day),
        onChanged: (value) {
          _updateTask(task, value ?? false);
        },
        activeColor: const Color.fromARGB(255, 141, 94, 77),
      );
    }

    final updatedTask = Task(
      id: task.id,
      name: task.name,
      dueDate: task.dueDate,
      isCompleted: isCompleted && !alreadyCompleted,
      completionDates: updatedCompletionDates,
    );

    await _dbHelper.updateTask(updatedTask);
    _loadTasks();
  }

  void _deleteTask(int id) async {
    await _dbHelper.deleteTask(id);
    _loadTasks();
  }

  void _reorderTasks(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final task = _tasks.removeAt(oldIndex);
      _tasks.insert(newIndex, task);
    });

    // Optionally save the new order to the database here if needed
  }

  void _showEditDialog(Task task) {
    String taskName = task.name;
    DateTime dueDate = task.dueDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: const Text(
                'تعديل أو حذف المهمة'), // "Edit or Delete Task" in Arabic
          ),
          content: Directionality(
            textDirection: TextDirection.rtl, // Apply RTL direction
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                      labelText: 'اسم المهمة'), // "Task Name" in Arabic
                  onChanged: (value) {
                    taskName = value;
                  },
                  controller: TextEditingController(text: task.name),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('إلغاء'), // "Cancel" in Arabic
                      style: TextButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF9E7C6F), // Brown background
                        primary: Colors.white, // Text color
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextButton(
                      onPressed: () {
                        _deleteTask(task.id!);
                        Navigator.of(context).pop();
                      },
                      child: const Text('حذف'), // "Delete" in Arabic
                      style: TextButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF9E7C6F), // Brown background
                        primary: Colors.white, // Text color
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextButton(
                      onPressed: () {
                        if (taskName.isNotEmpty) {
                          _updateTask(
                            Task(
                              id: task.id,
                              name: taskName,
                              dueDate: dueDate,
                              isCompleted: task.isCompleted,
                              completionDates: task.completionDates,
                            ),
                            task.isCompleted,
                          );
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('تعديل'), // "Edit" in Arabic
                      style: TextButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF9E7C6F), // Brown background
                        primary: Colors.white, // Text color
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl, // Apply RTL direction
        child: Stack(
          children: [
            Image.asset(
              'assets/background.jpg', // Replace with the path to your background image
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            Column(
              children: [
                const SizedBox(height: 20), // Adds top margin
                Container(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40), // Adds top margin
                      Container(
                        padding: const EdgeInsets.all(15.0),
                        child: Center(
                          child: Text(
                            ' وَأَن لّيْسَ لِلْإِنسَانِ إِلّا مَا سَعَىٰ . وَأَنّ سَعْيَهُ سَوْفَ يُرَىٰ . ثُمّ يُجْزَاهُ الْجَزَاءَ الْأَوْفَىٰ  \n( سورة النجم )',
                            style: const TextStyle(
                              fontSize: 18, // Adjust font size as needed
                              fontWeight: FontWeight.bold,
                              color:
                                  Color(0xFF9E7C6F), // Adjust color as needed
                            ),
                            textDirection:
                                TextDirection.rtl, // Ensure text is RTL
                            textAlign:
                                TextAlign.center, // Center align the text
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        bottom: 120.0), // Add 20px padding at the bottom
                    child: _tasks.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد مهام حالياً', // "No tasks available" in Arabic
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black, // Adjust color as needed
                              ),
                              textDirection:
                                  TextDirection.rtl, // Ensure text is RTL
                            ),
                          )
                        : ReorderableListView(
                            onReorder: _reorderTasks,
                            children: _tasks.asMap().entries.map((entry) {
                              final index = entry.key;
                              final task = entry.value;
                              return GestureDetector(
                                key: ValueKey(task.id),
                                onTap: () => _showEditDialog(task),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: task.isCompleted
                                          ? Colors.black
                                          : const Color(
                                              0xFF9E7C6F), // Black border for completed tasks, brown for others
                                      width: 2.0, // Border width
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        8.0), // Rounded corners
                                    color: Colors
                                        .transparent, // Transparent background
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: task.isCompleted,
                                          onChanged: (value) {
                                            setState(() {
                                              _updateTask(task, value ?? false);
                                            });
                                          },
                                          activeColor: const Color.fromARGB(
                                              255, 141, 94, 77),
                                        ),
                                        Expanded(
                                          child: Text(
                                            task.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            textDirection: TextDirection.rtl,
                                          ),
                                        ),
                                        IconButton(
                                          icon:
                                              const Icon(Icons.calendar_today),
                                          onPressed: () {
                                            _showStreakBottomSheet(task);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) {
              String taskName = '';
              DateTime dueDate = DateTime.now();

              return AlertDialog(
                title: Center(
                  child: const Text('إضافة مهمة'), // "Add Task" in Arabic
                ),
                content: Directionality(
                  textDirection: TextDirection.rtl, // Apply RTL direction
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                            labelText: 'اسم المهمة'), // "Task Name" in Arabic
                        onChanged: (value) {
                          taskName = value;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('إلغاء'), // "Cancel" in Arabic
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF9E7C6F), // Brown background
                              primary: Colors.white, // Text color
                            ),
                          ),
                        ),
                        const SizedBox(
                            width: 8.0), // Small space between buttons
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              if (taskName.isNotEmpty) {
                                _addTask(taskName, dueDate);
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('إضافة'), // "Add" in Arabic
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF9E7C6F), // Brown background
                              primary: Colors.white, // Text color
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: const Color(0xFF9E7C6F),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showStreakBottomSheet(Task task) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          height: MediaQuery.of(context).size.height * 0.7, // Adjust height
          child: Column(
            children: [
              Text(
                'تقويم المتابعة ل ${task.name}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(height: 16), // Space between title and calendar
              Expanded(
                child: TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now(),
                  focusedDay: DateTime.now(),
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {
                    // Only show the monthly view
                    CalendarFormat.month: 'شهر', // "Month" in Arabic
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors
                          .brown[300], // Light brown color for selected day
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.brown[300], // Brown color for today's date
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(color: Colors.white),
                    defaultTextStyle: const TextStyle(color: Colors.black),
                    outsideTextStyle: const TextStyle(color: Colors.grey),
                    weekendTextStyle: const TextStyle(color: Colors.brown),
                    holidayTextStyle: const TextStyle(color: Colors.green),
                    rangeHighlightColor: Colors.brown.withOpacity(0.1),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      bool isCompleted = task.completionDates
                          .any((date) => isSameDay(date, day));
                      return Container(
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.black
                              : Colors.transparent, // Black for completed days
                          shape: BoxShape.circle, // Rounded corners
                        ),
                        margin: const EdgeInsets.all(
                            4.0), // Small margin around the day
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: isCompleted
                                  ? Colors.white
                                  : Colors
                                      .black, // White text for completed days
                            ),
                          ),
                        ),
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(
                              255, 27, 23, 19), // Brown color for today's date
                          shape: BoxShape.circle, // Rounded corners
                        ),
                        margin: const EdgeInsets.all(
                            4.0), // Small margin around the day
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                  selectedDayPredicate: (date) =>
                      task.completionDates.any((d) => isSameDay(d, date)),
                  eventLoader: (day) {
                    bool isCompleted = task.completionDates
                        .any((date) => isSameDay(date, day));
                    return isCompleted ? [day] : [];
                  },
                  rowHeight: 40, // Adjust row height to avoid extra weeks
                ),
              ),
              const SizedBox(height: 16), // Space at the bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              Colors.brown[300], // White text color
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(30), // Rounded corners
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
